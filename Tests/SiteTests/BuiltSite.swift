import Foundation

/// Read-only access to the site that `swift run` generated in Build/.
enum BuiltSite {
    /// The production domain. Absolute links to it count as internal links.
    static let domain = "https://mannychau.com"

    static let root: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // SiteTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // package root
        .appendingPathComponent("Build")

    static let contentRoot: URL = root
        .deletingLastPathComponent()
        .appendingPathComponent("Content")

    static var exists: Bool {
        FileManager.default.fileExists(atPath: root.appendingPathComponent("index.html").path)
    }

    /// Every generated HTML page, as paths relative to Build/ (e.g. "tech/index.html").
    static func htmlPages() -> [String] {
        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        var pages: [String] = []
        while let url = enumerator?.nextObject() as? URL {
            if url.pathExtension == "html" {
                pages.append(String(url.path.dropFirst(root.path.count + 1)))
            }
        }
        return pages.sorted()
    }

    static func read(_ relativePath: String) throws -> String {
        try String(contentsOf: root.appendingPathComponent(relativePath), encoding: .utf8)
    }

    /// Whether a site path such as "/tech/" or "/css/custom.css" maps to a file in Build/.
    static func resolves(_ sitePath: String) -> Bool {
        var path = sitePath
        if let cut = path.firstIndex(where: { $0 == "#" || $0 == "?" }) {
            path = String(path[..<cut])
        }
        path = path.removingPercentEncoding ?? path
        let fileManager = FileManager.default
        let target = root.appendingPathComponent(path)
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: target.path, isDirectory: &isDirectory) {
            return !isDirectory.boolValue
                || fileManager.fileExists(atPath: target.appendingPathComponent("index.html").path)
        }
        return false
    }

    /// Site path (e.g. "/tech/") for a page path relative to Build/.
    static func sitePath(forPage page: String) -> String {
        if page == "index.html" { return "/" }
        let dir = (page as NSString).deletingLastPathComponent
        return "/" + (dir.isEmpty ? "" : dir + "/")
    }

    /// Whether the data parses as XML.
    static func isValidXML(_ data: Data) -> Bool {
        (try? XMLParser(data: data).parse()) ?? false
    }

    /// All href and src values in a page.
    static func links(in html: String) -> [String] {
        let pattern = #/(?:href|src)="([^"]*)"/#
        return html.matches(of: pattern).map { String($0.output.1) }
    }

    struct Post {
        /// Folder under Content/ ("tech", "life"), or "" for a file directly in Content/.
        var type: String
        var slug: String
        var text: String
        var isPublished: Bool { BuiltSite.isPublished(text) }
        var tags: [String] { BuiltSite.tags(in: text) }
        var path: String { type.isEmpty ? "Content/\(slug).md" : "Content/\(type)/\(slug).md" }
    }

    /// Every Markdown post in Content/, drafts included.
    static func posts() throws -> [Post] {
        let enumerator = FileManager.default.enumerator(at: contentRoot, includingPropertiesForKeys: nil)
        var posts: [Post] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "md" else { continue }
            let folder = url.deletingLastPathComponent().standardizedFileURL
            let type = folder == contentRoot.standardizedFileURL ? "" : folder.lastPathComponent
            let text = try String(contentsOf: url, encoding: .utf8)
            posts.append(Post(type: type, slug: url.deletingPathExtension().lastPathComponent, text: text))
        }
        return posts.sorted { $0.path < $1.path }
    }

    static func publishedPosts() throws -> [Post] {
        try posts().filter(\.isPublished)
    }

    /// Mirrors Ignite's rule: only the front matter counts, and only an exact
    /// `false` hides a post (Ignite uses `Bool(value) ?? true`, so `False` publishes).
    static func isPublished(_ markdown: String) -> Bool {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return true }
        for line in lines.dropFirst() {
            if line.trimmingCharacters(in: .whitespaces) == "---" { break }
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2,
                  parts[0].trimmingCharacters(in: .whitespaces) == "published" else { continue }
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            return Bool(value) ?? true
        }
        return true
    }

    /// Tags from the front matter (comma-separated), mirroring Ignite's splitAndTrim.
    static func tags(in markdown: String) -> [String] {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return [] }
        for line in lines.dropFirst() {
            if line.trimmingCharacters(in: .whitespaces) == "---" { break }
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2,
                  parts[0].trimmingCharacters(in: .whitespaces) == "tags" else { continue }
            return parts[1].split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return []
    }

    /// The text of a page's first `<h1>`, with HTML entities decoded.
    ///
    /// A tag page prints the tag's own name there, which is what the tests match
    /// on. Deriving the name this way avoids reimplementing Ignite's slug rules:
    /// `convertedToSlug()` dash-cases camelCase and transliterates Unicode, so a
    /// naive lowercase-and-dash disagrees on tags such as "SwiftUI" or "Café".
    static func heading(in html: String) -> String? {
        guard let match = html.firstMatch(of: #/<h1[^>]*>(.*?)</h1>/#) else { return nil }
        var text = String(match.output.1)
        for (entity, character) in [("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
                                    ("&#39;", "'"), ("&amp;", "&")] {
            text = text.replacingOccurrences(of: entity, with: character)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
