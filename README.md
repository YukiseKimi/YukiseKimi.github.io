# Manny.Dev

Source for **[mannychau.com](https://mannychau.com)**, Manny Chau's personal blog about tech and life abroad.

The site is written in Swift with [Ignite](https://github.com/twostraws/Ignite), a static site generator with a SwiftUI-like syntax. Each push to `main` is tested and then deployed to GitHub Pages.

## Requirements

- Swift 6 or later (`Package.swift` and Ignite both require tools version 6.0; CI uses Swift 6.4)
- Optional: the [Ignite CLI](https://github.com/twostraws/Ignite#getting-started) for a local preview server

## Build and preview locally

```sh
swift run                # generates the site into Build/
ignite run --preview     # serves Build/ and opens it in your browser
```

Run `swift run` again after each change. `ignite run` serves whatever is in `Build/` and does not rebuild.

## Writing a post

Posts are Markdown files in `Content/`. The folder sets the category:

| Folder | Category | Listed at |
|---|---|---|
| `Content/tech/` | Tech | `/tech` |
| `Content/life/` | Life | `/life` |

Every post must be inside one of these folders. A Markdown file directly in `Content/` makes `swift run` crash with `Fatal error: Unable to retrieve type for article`. A post in any other folder, such as `Content/travel/`, would publish without a listing page or menu entry, so the tests reject it.

Front matter:

```markdown
---
title: First 6 months in Lithuania
date: 2026-09-01
tags: moving-abroad, life, lithuania
modified: 2026-10-01      # optional: shows "Updated <date>" on the post
published: false          # optional: hides the post (must be lowercase "false")
---

The first paragraph becomes the summary on post cards, in the RSS feed,
and in the page description, so make it a good one.
```

The filename becomes the URL: `Content/life/first-6-months-in-lithuania.md` is published at `/life/first-6-months-in-lithuania/`.

### Importing from Obsidian

`Scripts/import-obsidian.py` converts an Obsidian note into a post:

```bash
Scripts/import-obsidian.py "~/Vault/My Note.md" --category tech --vault ~/Vault
```

It writes `published: false` unless you pass `--publish`, so an import is
never live until you say so. Use `--dry-run` to see the result without
writing anything.

It exists because four Obsidian habits do not survive the trip:

| Obsidian | Problem | Result |
|---|---|---|
| `tags:` as a block list | Ignite keeps only `key: value` lines, so the list is skipped and the post gets **no tags at all** | rewritten to `tags: a, b, c` |
| `[[Note]]` | not Markdown; renders literally | resolved against `Content/`, or flattened to plain text with a warning |
| `![[photo.png]]` | renders literally and the file is never copied | rewritten to `![](/images/photo.png)`, image copied into `Assets/images/` |
| `> [!note]` | becomes a quote containing a literal `[!note]` | rewritten to a bold lead-in |

It also drops `aliases` and `cssclasses`, takes `date` from `created` when
`date` is missing, and slugifies the title into the filename. Nested tags
(`learning/swift`) become `learning-swift`. Block lists are read whether or
not they are indented, since Obsidian indents them but hand-edited notes
often do not.

Rewriting skips fenced code blocks and inline code spans, so a post that
documents Obsidian syntax keeps its examples intact.

Values are never quoted, because Ignite only trims whitespace around them:
`title: "x"` would keep its quotation marks in the page title. A `---` rule
in the body is left alone — it is safe, since only the first one is treated
as the front matter fence.

Warnings go to stderr; read them. An unresolved wikilink becomes plain text,
and a wikilink to a draft keeps its link but will 404 until that post is
published.

## Project structure

```
Sources/
  Site.swift              Site settings (name, URL, author) and the list of pages
  Layouts/MainLayout.swift  Navbar, reading column, and footer used by every page
  Layouts/SiteFooter.swift  Footer: ©, Ignite credit, GitHub and LinkedIn links
  Pages/                  Home, Tech, Life, About, Search, Tags, and the post page
  Styles/                 Post card style and shared date formatting
Content/                  Blog posts (Markdown)
Scripts/                  import-obsidian.py, for importing notes from a vault
Assets/                   Copied into the site as-is: CSS, images, favicon, CNAME
Tests/SiteTests/          Checks on the generated site in Build/
```

`Assets/css/custom.css` contains the site's own styles on top of Ignite's Bootstrap themes (reading column, post cards, footer).

## Tests

The tests check the generated site, so build it first:

```sh
swift run && swift test
```

They check that:

- key pages and files exist, and `CNAME` still points to `mannychau.com`
- every published post has a page, and drafts (`published: false` in the front matter) don't
- every post is in `Content/tech/` or `Content/life/`
- no published post still contains `PLACEHOLDER` text
- the starter template's `Assets.txt` and `Images.txt` aren't published
- every page uses the shared layout and has a `… | Manny.Dev` title
- dates use the `Sep 1, 2026` format
- the home page links to both section indexes
- tag pages render a post card per article (matching the index pages)
- no internal link or asset path is broken
- the nav link for the current page is active (`aria-current="page"`) on home and static pages
- the 404 page exists and renders the "Page Not Found" error
- `sitemap.xml` and `feed.rss` are valid XML and list only published posts; `robots.txt` references the sitemap
- the Plausible analytics snippet is present in pages
- the search page embeds a valid JSON index of published posts

Tag pages and the 404 page render no active nav link — the framework does not set
`currentRenderingPath` for them, so the tests assert that explicitly.

## CI/CD

Workflows live in `.github/workflows/`:

- **`ci.yml`** runs on every pull request and every push to `main`. It builds the site and runs the tests. On `main`, it then deploys to GitHub Pages, but only if every test passed.
- **`external-links.yml`** checks links to other websites every Monday. You can also start it from the Actions tab. It never blocks a deploy. Both workflows cancel a stale run in the same group.

Every job has a `timeout-minutes` cap (build/test 20, deploy 10), and `.github/dependabot.yml` keeps GitHub Actions and the Swift package up to date.

Builds run in a `swift:6.4-noble` container on Linux. Their output is the same as a macOS build.

## Pages

- **Home** (`/`) shows the five most recent posts, then links to the Tech and Life sections
- **Search** (`/search`) filters a JSON index of published posts by title, tag, or date — no server needed
- **Tags** (`/tags`) lists every tag with post cards, same as the index pages
- **About** (`/about`) has a short bio, what the blog covers, and contact links
- **404** (`404.html`) renders the "Page Not Found" error with a link home

## Hosting notes

- The site must be served from the root of a domain. Ignite doesn't add a subpath to internal links, so hosting under `/repo-name/` would break navigation.
- The custom domain is set in two places: `url` in `Sources/Site.swift` and `Assets/CNAME`. If the domain changes, update both.

## License

[MIT](LICENSE). © 2026 Manny Chau. Started from the [IgniteStarter](https://github.com/twostraws/IgniteStarter) template (© 2024 Paul Hudson and other authors), whose notice is kept in `LICENSE`.
