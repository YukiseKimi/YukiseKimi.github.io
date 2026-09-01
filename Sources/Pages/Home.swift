import Foundation
import Ignite

struct Home: StaticPage {
    @Environment(\.articles) var articles
    var title = "Home"

    var body: some HTML {
        Text("Manny Chau")
            .font(.title1)

        Text("Writing about software engineering, and about building a life in a new country.")
            .font(.lead)
            .margin(.bottom, .large)

        Text("Recent posts")
            .font(.title2)

        ForEach(articles.all.prefix(5)) { article in
            ArticlePreview(for: article)
                .articlePreviewStyle(DatedPreviewStyle())
                .margin(.bottom, .medium)
        }
    }
}
