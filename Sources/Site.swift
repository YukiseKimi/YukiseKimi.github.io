import Foundation
import Ignite

@main
struct IgniteWebsite {
    static func main() async {
        var site = PersonalBlog()

        do {
            try await site.publish()
        } catch {
            // Exit non-zero so CI fails instead of deploying a broken site.
            FileHandle.standardError.write(Data("Publish failed: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }
}

struct PersonalBlog: Site {
    var name = "Manny.Dev"
    var titleSuffix = " | Manny.Dev"
    // Custom domain, served at the root so root-relative links work everywhere.
    // Assets/CNAME tells GitHub Pages to keep serving this domain.
    var url = URL(static: "https://mannychau.com")
    var author = "Manny Chau"
    // `String?`, not `String`: Ignite declares `description` as an optional
    // with a `nil` default, and a non-optional cannot witness it — the default
    // would win and the feed would ship an empty <description>.
    var description: String? = "Tech learnings and life abroad."

    var favicon = URL(string: "/images/favicon.png")

    var homePage = Home()
    var layout = MainLayout()

    var staticPages: [any StaticPage] {
        TechIndex()
        LifeIndex()
        About()
        Search()
    }

    var articlePages: [any ArticlePage] {
        BlogPost()
    }

    var tagPage = Tags()

    var errorPage: NotFoundPage = NotFoundPage()
}
