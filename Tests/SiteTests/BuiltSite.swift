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

    /// All href and src values in a page.
    static func links(in html: String) -> [String] {
        let pattern = #/(?:href|src)="([^"]*)"/#
        return html.matches(of: pattern).map { String($0.output.1) }
    }

    /// Markdown posts in Content/, excluding ones marked `published: false`.
    static func publishedPosts() throws -> [(type: String, slug: String, text: String)] {
        let enumerator = FileManager.default.enumerator(at: contentRoot, includingPropertiesForKeys: nil)
        var posts: [(String, String, String)] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "md" else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            if text.contains("published: false") { continue }
            let type = url.deletingLastPathComponent().lastPathComponent
            posts.append((type, url.deletingPathExtension().lastPathComponent, text))
        }
        return posts
    }
}
