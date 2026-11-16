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
                "Missing page for Content/\(post.type)/\(post.slug).md"
            )
        }
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
}
