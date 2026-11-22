#!/usr/bin/env python3
"""Import an Obsidian note into this Ignite site.

Obsidian and Ignite both use YAML-ish front matter and Markdown, but they
disagree in four places. This script translates between them:

  1. Tags. Ignite's parser keeps only `key: value` lines, so Obsidian's
     block list (`tags:` followed by `  - swift`) is dropped outright and
     the post publishes with no tags at all. Rewritten to `tags: a, b, c`.
  2. Wikilinks. `[[Note]]` is not Markdown and renders literally. Resolved
     against Content/ where possible, otherwise flattened to plain text.
  3. Embeds. `![[photo.png]]` renders literally and the file is never
     copied. Rewritten to `![](/images/photo.png)` and the image copied
     into Assets/images/.
  4. Callouts. `> [!note]` degrades to a quote containing a literal
     `[!note]`. Rewritten to a bold lead-in inside the quote.

Body rewriting skips fenced code blocks and inline code spans, so a post
that documents Obsidian syntax keeps its examples intact.

Values are never quoted: Ignite only trims whitespace, so `title: "x"`
would keep its quotation marks in the page title.

Usage:
    Scripts/import-obsidian.py NOTE.md --category tech
    Scripts/import-obsidian.py NOTE.md --category life --vault ~/Vault --dry-run
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
import unicodedata
from pathlib import Path
from typing import Callable

REPO = Path(__file__).resolve().parent.parent
CONTENT = REPO / "Content"
IMAGES = REPO / "Assets" / "images"
CATEGORIES = ("tech", "life")
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".avif"}

# Obsidian bookkeeping that means nothing to the site.
DROP_KEYS = {"aliases", "cssclass", "cssclasses", "obsidianuimode", "permalink"}
# Front matter keys this script derives itself, so a copy from the source
# note would be a duplicate. Compared case-insensitively.
CONSUMED_KEYS = {"title", "tags", "date", "created", "published"}
# Emitted first, in this order; anything else is preserved after them.
KEY_ORDER = ("title", "date", "tags", "published", "description")

warnings: list[str] = []


def warn(message: str) -> None:
    warnings.append(message)


def slugify(value: str) -> str:
    """Lowercase ASCII slug: 'My Post: Part 2' -> 'my-post-part-2'."""
    value = value.replace("/", "-")
    value = unicodedata.normalize("NFKD", value)
    value = value.encode("ascii", "ignore").decode("ascii")
    value = re.sub(r"[^\w\s-]", "", value).strip().lower()
    value = re.sub(r"[\s_]+", "-", value)
    return re.sub(r"-{2,}", "-", value).strip("-")


# --------------------------------------------------------------------------
# Front matter
# --------------------------------------------------------------------------

def split_front_matter(text: str) -> tuple[dict, str]:
    """Return (metadata, body). Supports the YAML subset Obsidian writes."""
    if not text.startswith("---"):
        return {}, text

    lines = text.split("\n")
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        sys.exit("error: front matter opens with --- but is never closed")

    data: dict[str, object] = {}
    current: str | None = None

    for raw in lines[1:end]:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue

        # A block-list item belonging to the previous key. Indentation is
        # optional: Obsidian's property editor indents, hand-written notes
        # often do not, and both are valid YAML. The key must already be
        # holding a list, so a stray dash elsewhere is still an error.
        stripped = raw.strip()
        if (current is not None
                and isinstance(data.get(current), list)
                and (stripped == "-" or stripped.startswith("- "))):
            data[current].append(unquote(stripped[1:].strip()))  # type: ignore[union-attr]
            continue

        match = re.match(r"^([\w.-]+)\s*:\s*(.*)$", raw)
        if not match:
            sys.exit(f"error: cannot parse front matter line: {raw!r}")

        current, value = match.group(1), match.group(2).strip()
        if value == "":
            data[current] = []            # a block list probably follows
        elif value.startswith("[") and value.endswith("]"):
            inner = value[1:-1]
            data[current] = [unquote(v.strip()) for v in inner.split(",") if v.strip()]
        else:
            data[current] = unquote(value)

    return data, "\n".join(lines[end + 1:]).lstrip("\n")


def unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def normalise_tags(value: object) -> list[str]:
    if value is None:
        return []
    items = value if isinstance(value, list) else re.split(r"[,\n]", str(value))
    tags: list[str] = []
    for item in items:
        tag = slugify(str(item).strip().lstrip("#"))
        if tag and tag not in tags:
            tags.append(tag)
    return tags


def normalise_date(meta: dict) -> str:
    """The post date, from `date` or Obsidian's `created`, else today."""
    today = dt.date.today().isoformat()
    # Obsidian writes `created`, templates sometimes `Created`.
    lowered = {key.lower(): value for key, value in meta.items()}

    for key in ("date", "created"):
        raw = lowered.get(key)
        if not isinstance(raw, str) or not raw.strip():
            continue
        text = raw.strip()
        match = re.match(r"(\d{4})-(\d{2})-(\d{2})", text)
        if match:
            try:
                dt.date.fromisoformat(match.group(0))
                return match.group(0)
            except ValueError:
                pass            # a real-looking but impossible date
        warn(f"could not read a date from {key}: {text!r}; using today ({today})")
        return today

    warn(f"no usable date in front matter; using today ({today})")
    return today


# --------------------------------------------------------------------------
# Body rewriting
# --------------------------------------------------------------------------

WIKILINK = re.compile(r"(!?)\[\[([^\]\|#]+?)(?:#([^\]\|]+?))?(?:\|([^\]]+?))?\]\]")
CALLOUT = re.compile(r"^(\s*>+\s*)\[!(\w+)\]([+-]?)\s*(.*)$")
# A fence opens with three or more backticks or tildes, indented at most 3.
FENCE = re.compile(r"^\s{0,3}(`{3,}|~{3,})(.*)$")
INLINE_CODE = re.compile(r"`+[^`]*`+")

# Attachments already copied this run, so a dry run reports the same
# filenames a real run would write.
claimed: dict[Path, bytes] = {}


def existing_posts() -> dict[str, tuple[str, bool]]:
    """Map slug and lowercased title -> (site path, is published)."""
    index: dict[str, tuple[str, bool]] = {}
    for path in CONTENT.rglob("*.md"):
        category = path.parent.name
        if category not in CATEGORIES:
            continue
        meta, _ = split_front_matter(path.read_text(encoding="utf-8"))
        # Ignite's rule is `Bool(published) ?? true`, which accepts only the
        # exact strings "true" and "false" — `False` or `no` means published.
        published = str(meta.get("published", "")).strip() != "false"
        entry = (f"/{category}/{path.stem}/", published)
        index[path.stem.lower()] = entry
        title = meta.get("title")
        if isinstance(title, str) and title:
            index[title.strip().lower()] = entry
            index[slugify(title)] = entry
    return index


def find_attachment(name: str, vault: Path) -> Path | None:
    direct = vault / name
    if direct.is_file():
        return direct
    matches = sorted(p for p in vault.rglob(Path(name).name) if p.is_file())
    if not matches:
        return None
    if len(matches) > 1:
        warn(f"{len(matches)} files in the vault are named {Path(name).name!r}; "
             f"used {matches[0]}")
    return matches[0]


def copy_image(source: Path, dry_run: bool) -> str:
    """Copy an attachment into Assets/images/, returning its site path."""
    base = slugify(source.stem) or "image"
    suffix = source.suffix.lower()
    data = source.read_bytes()

    # Find a free name, reusing it when the same bytes are already there.
    index = 0
    while True:
        name = f"{base}{suffix}" if index == 0 else f"{base}-{index}{suffix}"
        target = IMAGES / name
        if target in claimed:
            if claimed[target] == data:
                return f"/images/{name}"
        elif not target.exists():
            break
        elif target.read_bytes() == data:
            return f"/images/{name}"
        index += 1

    claimed[target] = data
    if dry_run:
        print(f"  would copy image  {source} -> {target.relative_to(REPO)}")
    else:
        IMAGES.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        print(f"  copied image      {target.relative_to(REPO)}")
    return f"/images/{target.name}"


def outside_code(text: str, transform: Callable[[str], str]) -> str:
    """Apply `transform` to the parts of `text` outside inline code spans."""
    parts: list[str] = []
    end = 0
    for span in INLINE_CODE.finditer(text):
        parts.append(transform(text[end:span.start()]))
        parts.append(span.group(0))
        end = span.end()
    parts.append(transform(text[end:]))
    return "".join(parts)


def rewrite_body(body: str, vault: Path, dry_run: bool) -> str:
    index = existing_posts()

    def replace_link(match: re.Match) -> str:
        embed, target, heading, alias = match.groups()
        label = (alias or target).strip()
        target = target.strip()

        if embed:
            suffix = Path(target).suffix.lower()
            if suffix in IMAGE_SUFFIXES:
                found = find_attachment(target, vault)
                if found is None:
                    warn(f"embedded image not found in the vault: {target!r} "
                         f"(searched {vault})")
                    return f"![{label}]({target})"
                return f"![{alias or Path(target).stem}]({copy_image(found, dry_run)})"
            warn(f"note embed ![[{target}]] cannot be transcluded; left as plain text")
            return label

        entry = index.get(target.lower()) or index.get(slugify(target))
        if entry is None:
            warn(f"wikilink [[{target}]] matches no post in Content/; "
                 f"flattened to plain text")
            return label

        url, published = entry
        if not published:
            # Ignite builds no page for a draft, so the link would 404. Kept
            # rather than flattened: the imported post is itself a draft by
            # default, so nothing breaks until both are published.
            warn(f"wikilink [[{target}]] points at a draft; {url} will 404 "
                 f"until that post has published: true")
        if heading:
            warn(f"heading anchor #{heading} on [[{target}]] was dropped; "
                 f"the link goes to the top of the post")
        return f"[{label}]({url})"

    out: list[str] = []
    fence_char: str | None = None
    fence_length = 0

    for line in body.split("\n"):
        marker = FENCE.match(line)

        # Inside a fenced block nothing is rewritten; only a matching
        # closing marker of the same character and length ends it.
        if fence_char is not None:
            if (marker and marker.group(1)[0] == fence_char
                    and len(marker.group(1)) >= fence_length
                    and not marker.group(2).strip()):
                fence_char = None
            out.append(line)
            continue

        if marker:
            fence_char = marker.group(1)[0]
            fence_length = len(marker.group(1))
            out.append(line)
            continue

        line = outside_code(line, lambda text: WIKILINK.sub(replace_link, text))

        callout = CALLOUT.match(line)
        if callout:
            prefix, kind, _fold, title = callout.groups()
            heading = f"**{kind.capitalize()}**"
            if title.strip():
                heading += f" — {title.strip()}"
            line = f"{prefix}{heading}"
        out.append(line)

    if fence_char is not None:
        warn("a fenced code block is never closed; "
             "everything after it was left untouched")
    return "\n".join(out)


# --------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------

def format_value(value: object) -> str:
    """One front matter value. Lists become `a, b, c`, which is how Ignite
    reads multi-value keys such as tags (it splits them on commas)."""
    if isinstance(value, list):
        return ", ".join(str(item).strip() for item in value if str(item).strip())
    return str(value).strip()


def render_front_matter(meta: dict) -> str:
    lines = ["---"]
    ordered = [key for key in KEY_ORDER if key in meta]
    ordered += [key for key in meta if key not in KEY_ORDER]
    for key in ordered:
        value = format_value(meta[key])
        if value == "":
            continue        # an empty Obsidian property means unset
        lines.append(f"{key}: {value}")
    lines.append("---")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Import an Obsidian note into the Ignite site.")
    parser.add_argument("source", type=Path, help="the Obsidian .md file")
    parser.add_argument("--category", required=True, choices=CATEGORIES,
                        help="which Content/ folder the post belongs in")
    parser.add_argument("--vault", type=Path,
                        help="vault root, for finding embedded images "
                             "(default: the note's own folder)")
    parser.add_argument("--slug", help="override the output filename")
    parser.add_argument("--publish", action="store_true",
                        help="set published: true (default is false)")
    parser.add_argument("--force", action="store_true",
                        help="overwrite an existing post")
    parser.add_argument("--dry-run", action="store_true",
                        help="print what would happen, write nothing")
    args = parser.parse_args()

    # Expand ~ ourselves: a quoted "~/Vault/Note.md" is not expanded by the shell.
    source = args.source.expanduser()
    if not source.is_file():
        sys.exit(f"error: no such file: {source}")

    vault = (args.vault.expanduser() if args.vault else source.parent).resolve()
    raw = source.read_text(encoding="utf-8")
    meta, body = split_front_matter(raw)

    for key in list(meta):
        if key.lower() in DROP_KEYS:
            del meta[key]

    title = meta.get("title")
    if not isinstance(title, str) or not title.strip():
        heading = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
        title = heading.group(1).strip() if heading else source.stem
        warn(f"no title in front matter; using {title!r}")

    tags = normalise_tags(meta.get("tags"))
    date = normalise_date(meta)
    published = args.publish

    out_meta = {k: v for k, v in meta.items() if k.lower() not in CONSUMED_KEYS}
    out_meta = {
        "title": title.strip(),
        "date": date,
        **({"tags": ", ".join(tags)} if tags else {}),
        "published": "true" if published else "false",
        **out_meta,
    }

    body = rewrite_body(body, vault, args.dry_run)

    if "PLACEHOLDER" in body and published:
        warn("body still contains PLACEHOLDER and you passed --publish; "
             "the 'No published post contains PLACEHOLDER text' test will fail")

    # Prefer the title: this repo's filenames are slugified titles, and a
    # vault filename is often a working name rather than the real one.
    # --slug is slugified too, so it cannot escape Content/<category>/.
    if args.slug:
        slug = slugify(args.slug)
        if slug != args.slug:
            warn(f"--slug {args.slug!r} was slugified to {slug!r}")
    else:
        slug = slugify(title) or slugify(source.stem)
    if not slug:
        sys.exit("error: could not build a filename; pass --slug")

    target = CONTENT / args.category / f"{slug}.md"
    if target.exists() and not args.force:
        sys.exit(f"error: {target.relative_to(REPO)} already exists (use --force)")

    document = render_front_matter(out_meta) + "\n\n" + body.strip() + "\n"

    if args.dry_run:
        print(f"  would write       {target.relative_to(REPO)}\n")
        print(document)
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(document, encoding="utf-8")
        print(f"  wrote             {target.relative_to(REPO)}")

    for message in warnings:
        print(f"  warning: {message}", file=sys.stderr)

    print(f"\n  url               /{args.category}/{slug}/")
    print(f"  published         {'true' if published else 'false'}")
    if not args.dry_run:
        print("\n  next: swift run && swift test")
    return 0


if __name__ == "__main__":
    sys.exit(main())
