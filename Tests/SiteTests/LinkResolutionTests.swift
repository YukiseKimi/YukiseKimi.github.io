import Foundation
import Testing

/// Guards the link checker itself, so a bug in it can't hide broken links.
@Suite("Link checker")
struct LinkResolutionTests {
    init() throws {
        try #require(BuiltSite.exists, "Build/ is missing. Run `swift run` before `swift test`.")
    }

    @Test func resolvesDirectoryWithIndex() {
        #expect(BuiltSite.resolves("/tech/"))
        #expect(BuiltSite.resolves("/tech"))
        #expect(BuiltSite.resolves("/"))
    }

    @Test func resolvesFilesAndIgnoresFragments() {
        #expect(BuiltSite.resolves("/css/custom.css"))
        #expect(BuiltSite.resolves("/about/#contact"))
    }

    @Test func rejectsMissingPaths() {
        #expect(!BuiltSite.resolves("/does-not-exist/"))
        #expect(!BuiltSite.resolves("/css/missing.css"))
        #expect(!BuiltSite.resolves("/images/"))  // directory without index.html
    }

    @Test func extractsHrefAndSrc() {
        let html = #"<a href="/a/">x</a><img src="/b.png"><link href="https://x.com">"#
        #expect(BuiltSite.links(in: html) == ["/a/", "/b.png", "https://x.com"])
    }
}
