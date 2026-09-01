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
    var name = "MannyC.Dev"
    var titleSuffix = " – MannyC.Dev"
    // User site: the GitHub repo is named YukiseKimi.github.io, so the site
    // serves at the domain root and root-relative links work everywhere.
    var url = URL(static: "https://yukisekimi.github.io")
    var author = "Manny C."
    var description = "Tech learnings and life abroad."

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
