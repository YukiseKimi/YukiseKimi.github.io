import Foundation
import Ignite

struct Home: StaticPage {
    @Environment(\.articles) var articles
    var title = "Home"
    var description = "Manny Chau writes from abroad about software engineering and personal development: tech learnings and notes on life in a new country."

    var body: some HTML {
        Text("Tech & Life Abroad")
            .font(.title1)

        Text("Writing from abroad about Tech & Personal development")
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
