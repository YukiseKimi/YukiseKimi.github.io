import Foundation
import Testing

@Suite("Generated site")
struct SiteTests {
    init() throws {
        try #require(BuiltSite.exists, "Build/ is missing. Run `swift run` before `swift test`.")
    }

    @Test("Key pages and files exist", arguments: [
        "index.html",
        "tech/index.html",
        "life/index.html",
        "about/index.html",
        "tags/index.html",
        "feed.rss",
        "sitemap.xml",
        "CNAME",
        "images/favicon.png",
        "css/custom.css",
    ])
    func keyFileExists(_ path: String) {
        #expect(FileManager.default.fileExists(atPath: BuiltSite.root.appendingPathComponent(path).path))
    }

    @Test("CNAME keeps the custom domain")
    func cname() throws {
        let cname = try BuiltSite.read("CNAME").trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(cname == "mannychau.com")
    }

    @Test("Every published post has a page")
    func everyPostHasAPage() throws {
        let posts = try BuiltSite.publishedPosts()
        #expect(!posts.isEmpty)
        for post in posts {
            let page = "\(post.type)/\(post.slug)/index.html"
            #expect(
                FileManager.default.fileExists(atPath: BuiltSite.root.appendingPathComponent(page).path),
                "Missing page for \(post.path)"
            )
        }
    }

    @Test("Drafts (published: false) have no page")
    func draftsAreHidden() throws {
        for post in try BuiltSite.posts() where !post.isPublished {
            let page = "\(post.type)/\(post.slug)/index.html"
            #expect(
                !FileManager.default.fileExists(atPath: BuiltSite.root.appendingPathComponent(page).path),
                "Draft \(post.path) was published"
            )
        }
    }

    @Test("Every post is in Content/tech/ or Content/life/")
    func postsAreInKnownCategories() throws {
        for post in try BuiltSite.posts() {
            #expect(["tech", "life"].contains(post.type), "\(post.path) is not in tech/ or life/")
        }
    }

    @Test("No published post contains PLACEHOLDER text")
    func noPlaceholders() throws {
        for post in try BuiltSite.publishedPosts() {
            #expect(!post.text.contains("PLACEHOLDER"), "\(post.path) still contains PLACEHOLDER")
        }
    }

    @Test("Starter template files are not published", arguments: [
        "Assets.txt", "images/Images.txt",
    ])
    func noStarterFiles(_ path: String) {
        #expect(!FileManager.default.fileExists(atPath: BuiltSite.root.appendingPathComponent(path).path))
    }

    @Test("Every page title ends with '| Manny.Dev'")
    func pageTitles() throws {
        for page in BuiltSite.htmlPages() {
            let html = try BuiltSite.read(page)
            let title = html.firstMatch(of: #/<title>([^<]*)</title>/#)?.output.1
            #expect(title?.hasSuffix(" | Manny.Dev") == true, "\(page) has title \(title.map(String.init) ?? "none")")
        }
    }

    @Test("Every page uses the shared layout (navbar, footer, favicon)")
    func sharedLayout() throws {
        for page in BuiltSite.htmlPages() {
            let html = try BuiltSite.read(page)
            #expect(html.contains("<nav"), "\(page) has no navbar")
            #expect(html.contains("site-footer"), "\(page) has no footer")
            #expect(html.contains(#"href="/images/favicon.png" rel="icon""#), "\(page) has no favicon")
        }
    }

    @Test("Social links open in a new tab", arguments: [
        "https://github.com/YukiseKimi",
        "https://www.linkedin.com/in/mannyc25/",
    ])
    func socialLinksOpenInNewTab(_ url: String) throws {
        for page in BuiltSite.htmlPages() {
            let html = try BuiltSite.read(page)
            let anchors = html.matches(of: #/<a [^>]*>/#).map(\.output).filter { $0.contains(#"href="\#(url)""#) }
            #expect(!anchors.isEmpty, "\(page) has no link to \(url)")
            for anchor in anchors {
                #expect(anchor.contains(#"target="_blank""#), "\(page): \(anchor)")
            }
        }
    }

    @Test("No broken internal links")
    func internalLinks() throws {
        var broken: [String] = []
        for page in BuiltSite.htmlPages() {
            let pageDirectory = "/" + (page as NSString).deletingLastPathComponent
            for link in BuiltSite.links(in: try BuiltSite.read(page)) {
                let path: String
                if link.hasPrefix(BuiltSite.domain) {
                    path = String(link.dropFirst(BuiltSite.domain.count))
                } else if link.hasPrefix("/") && !link.hasPrefix("//") {
                    path = link
                } else if link.isEmpty || link.hasPrefix("#") || link.contains(":") || link.hasPrefix("//") {
                    continue  // anchors, external sites, mailto:, javascript:
                } else {
                    path = (pageDirectory as NSString).appendingPathComponent(link)
                }
                if !BuiltSite.resolves(path.isEmpty ? "/" : path) {
                    broken.append("\(page) → \(link)")
                }
            }
        }
        #expect(broken.isEmpty, "Broken links:\n\(broken.joined(separator: "\n"))")
    }

    @Test("Dates use the 'Sep 1, 2026' format on every page")
    func dateFormat() throws {
        // Guards against locale-dependent formatting: Linux defaults to "1 Sep 2026".
        var checked = 0
        for page in BuiltSite.htmlPages() {
            for match in try BuiltSite.read(page).matches(of: #/<time datetime="[^"]*">([^<]*)</time>/#) {
                let text = String(match.output.1)
                #expect(text.wholeMatch(of: #/[A-Z][a-z]{2} \d{1,2}, \d{4}/#) != nil, "\(page) shows date '\(text)'")
                checked += 1
            }
        }
        #expect(checked > 0, "No <time> elements found")
    }

    @Test("Home page links to both section indexes")
    func homeLinksToAllPosts() throws {
        let html = try BuiltSite.read("index.html")
        #expect(html.contains("browse-links"), "Home page has no browse-all-posts section")
        #expect(html.contains(#"href="/tech/""#), "Home page has no link to /tech/")
        #expect(html.contains(#"href="/life/""#), "Home page has no link to /life/")
    }

    @Test("Tag pages render a post card per article")
    func tagPagesRenderCards() throws {
        let posts = try BuiltSite.publishedPosts()
        var expected: [String: Int] = [:]
        for post in posts {
            for tag in post.tags {
                expected[tag, default: 0] += 1
            }
        }
        let tagPages = BuiltSite.htmlPages().filter { $0.hasPrefix("tags/") && $0 != "tags/index.html" }
        #expect(!tagPages.isEmpty)
        for page in tagPages {
            let html = try BuiltSite.read(page)
            // Match on the tag name the page prints, not on a slug recomputed
            // here: only Ignite knows how it turns a tag into a URL.
            guard let tag = BuiltSite.heading(in: html) else {
                Issue.record("\(page) has no <h1> naming its tag")
                continue
            }
            let cards = html.matches(of: #/class="post-card[ "]/#).count
            let want = expected[tag] ?? 0
            #expect(cards == want, "\(page) (tag \(tag)) shows \(cards) cards, expected \(want)")
            for post in posts where post.tags.contains(tag) {
                #expect(
                    html.contains("href=\"/\(post.type)/\(post.slug)/\""),
                    "\(page) is missing the card for \(post.path)"
                )
            }
        }
    }

    @Test("Active nav link on the current page")
    func activeNavLink() throws {
        // The framework marks the current page's nav link active on home and static
        // pages. Article, tag, and error pages never match a navbar link, so they
        // render no active nav link.
        for page in BuiltSite.htmlPages() {
            if page == "404.html" || page.hasPrefix("tags/") { continue }
            let html = try BuiltSite.read(page)
            let sitePath = BuiltSite.sitePath(forPage: page)
            let anchors = html.matches(of: #/<a [^>]*>/#).map(\.output).filter { $0.contains("nav-link") && $0.contains(#"href="\#(sitePath)""#) }
            if anchors.isEmpty {
                // Article pages: no navbar link points at the article, so no active link.
                let active = html.matches(of: #/<a [^>]*class="[^"]*active[^"]*"[^>]*>/#)
                #expect(active.isEmpty, "\(page): unexpected active nav link: \(active.first?.output ?? "")")
                continue
            }
            for anchor in anchors {
                #expect(anchor.contains("active"), "\(page): active link missing 'active' class: \(anchor)")
                #expect(anchor.contains(#"aria-current="page""#), "\(page): active link missing aria-current: \(anchor)")
            }
        }
    }

    @Test("Tag and 404 pages render no active nav link (framework limitation)")
    func noActiveNavLinkOnGeneratedPages() throws {
        // Derived, not listed: a new tag must be covered without editing this test.
        let pages = BuiltSite.htmlPages().filter { $0.hasPrefix("tags/") || $0 == "404.html" }
        #expect(pages.contains("404.html"), "404.html was not generated")
        #expect(pages.contains { $0.hasPrefix("tags/") }, "no tag pages were generated")
        for page in pages {
            let html = try BuiltSite.read(page)
            let active = html.matches(of: #/<a [^>]*class="[^"]*active[^"]*"[^>]*>/#)
            #expect(active.isEmpty, "\(page): unexpected active nav link: \(active.first?.output ?? "")")
        }
    }

    @Test("404 page exists and renders the error")
    func notFoundPage() throws {
        let html = try BuiltSite.read("404.html")
        #expect(html.contains("<title>Page Not Found | Manny.Dev</title>"))
        #expect(html.contains("Page Not Found"))
        #expect(html.contains("could not be found"))
        #expect(html.contains(#"href="/""#))
    }

    @Test("sitemap.xml is valid XML and lists only published content")
    func sitemap() throws {
        let data = try Data(contentsOf: BuiltSite.root.appendingPathComponent("sitemap.xml"))
        #expect(BuiltSite.isValidXML(data), "sitemap.xml is not valid XML")
        let html = String(decoding: data, as: UTF8.self)
        let locs = html.matches(of: #/<loc>([^<]+)</loc>/#).map { String($0.output.1) }
        #expect(!locs.isEmpty)
        let published = try BuiltSite.publishedPosts()
        let publishedPaths = Set(published.map { "/\($0.type)/\($0.slug)/" })
        for loc in locs {
            let path = String(loc.dropFirst(BuiltSite.domain.count))
            let lastPart = path.split(separator: "/").last.map(String.init) ?? ""
            if path == "/" || ["tech", "life", "about", "search", "tags"].contains(lastPart) {
                continue  // static pages
            }
            if path.hasPrefix("/tags/") {
                continue  // tag pages are derived from published posts
            }
            #expect(publishedPaths.contains(path), "sitemap lists unpublished or unknown path \(path)")
        }
        for post in published {
            let path = "/\(post.type)/\(post.slug)/"
            #expect(locs.contains(BuiltSite.domain + path), "sitemap is missing \(path)")
        }
    }

    @Test("feed.rss is valid XML and contains only published posts")
    func feed() throws {
        let data = try Data(contentsOf: BuiltSite.root.appendingPathComponent("feed.rss"))
        #expect(BuiltSite.isValidXML(data), "feed.rss is not valid XML")
        let html = String(decoding: data, as: UTF8.self)
        let published = try BuiltSite.publishedPosts()
        let publishedLinks = Set(published.map { BuiltSite.domain + "/\($0.type)/\($0.slug)" })
        let links = html.matches(of: #/<link>([^<]+)</link>/#).map { String($0.output.1) }
        #expect(!links.isEmpty)
        for link in links {
            if link == BuiltSite.domain { continue }  // channel link
            #expect(publishedLinks.contains(link), "feed lists unpublished or unknown link \(link)")
        }
        for post in published {
            #expect(links.contains(BuiltSite.domain + "/\(post.type)/\(post.slug)"), "feed is missing \(post.path)")
        }
    }

    @Test("robots.txt references the sitemap")
    func robots() throws {
        let text = try BuiltSite.read("robots.txt")
        #expect(text.contains("User-agent:"))
        #expect(text.contains("Sitemap: \(BuiltSite.domain)/sitemap.xml"))
    }

    @Test("Plausible analytics snippet is present")
    func analytics() throws {
        for page in ["index.html", "about/index.html"] {
            let html = try BuiltSite.read(page)
            #expect(html.contains("plausible.io/js/script"), "\(page) has no Plausible snippet")
            #expect(html.contains(#"data-domain="mannychau.com""#), "\(page) has no data-domain")
        }
    }

    @Test("Search page embeds a valid JSON index of published posts")
    func searchIndex() throws {
        let html = try BuiltSite.read("search/index.html")
        #expect(html.contains(#"id="search-index""#))
        #expect(html.contains(#"type="search""#))
        #expect(html.contains("getElementById('search-index')"))
        let json = try #require(html.firstMatch(of: #/<script id="search-index" type="application/json">(.*?)</script>/#)?.output.1)
        let data = Data(String(json).utf8)
        let objects = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(objects != nil, "search index is not valid JSON")
        let posts = try BuiltSite.publishedPosts()
        let publishedPaths = Set(posts.map { "/\($0.type)/\($0.slug)" })
        for obj in objects ?? [] {
            #expect(obj["title"] is String, "search index entry missing title")
            #expect(obj["path"] is String, "search index entry missing path")
            #expect(obj["tags"] is [String], "search index entry missing tags")
            #expect(obj["date"] is String, "search index entry missing date")
            #expect(publishedPaths.contains(obj["path"] as? String ?? ""), "search index lists unknown path \(obj["path"] ?? "")")
        }
        #expect(objects?.count == posts.count, "search index has \(objects?.count ?? 0) entries, expected \(posts.count)")
    }
}
