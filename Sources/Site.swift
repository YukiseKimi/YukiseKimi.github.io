import Foundation
import Ignite

@main
struct IgniteWebsite {
    static func main() async {
        var site = PersonalBlog()

        do {
            try await site.publish()
        } catch {
            print(error.localizedDescription)
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
    var description = "Tech learnings and life abroad."

    var favicon = URL(string: "/images/favicon.png")

    var homePage = Home()
    var layout = MainLayout()

    var staticPages: [any StaticPage] {
        TechIndex()
        LifeIndex()
        About()
    }

    var articlePages: [any ArticlePage] {
        BlogPost()
    }

    var tagPage = Tags()
}
