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
    // The /Renho-Federation path prefix must match the repo name exactly.
    // For local previews, temporarily drop the path (links carry the prefix otherwise).
    var url = URL(static: "https://yukisekimi.github.io/Renho-Federation")
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
