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

## Project structure

```
Sources/
  Site.swift              Site settings (name, URL, author) and the list of pages
  Layouts/MainLayout.swift  Navbar, reading column, and footer used by every page
  Layouts/SiteFooter.swift  Footer: ©, Ignite credit, GitHub and LinkedIn links
  Pages/                  Home, Tech, Life, About, Tags, and the post page
  Styles/                 Post card style and shared date formatting
Content/                  Blog posts (Markdown)
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
- no internal link or asset path is broken

## CI/CD

Workflows live in `.github/workflows/`:

- **`ci.yml`** runs on every pull request and every push to `main`. It builds the site and runs the tests. On `main`, it then deploys to GitHub Pages, but only if every test passed.
- **`external-links.yml`** checks links to other websites every Monday. You can also start it from the Actions tab. It never blocks a deploy.

Builds run in a `swift:6.4-noble` container on Linux. Their output is the same as a macOS build.

## Hosting notes

- The site must be served from the root of a domain. Ignite doesn't add a subpath to internal links, so hosting under `/repo-name/` would break navigation.
- The custom domain is set in two places: `url` in `Sources/Site.swift` and `Assets/CNAME`. If the domain changes, update both.

## License

[MIT](LICENSE). © 2026 Manny Chau. Started from the [IgniteStarter](https://github.com/twostraws/IgniteStarter) template (© 2024 Paul Hudson and other authors), whose notice is kept in `LICENSE`.
