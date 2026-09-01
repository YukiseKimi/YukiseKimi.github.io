import Foundation
import Ignite

struct LifeIndex: StaticPage {
    @Environment(\.articles) var articles
    var title = "Life"
    var path = "/life"

    var body: some HTML {
        Text("Life")
            .font(.title1)

        Text("Notes and stories from my experience moving abroad.")
            .font(.lead)
            .margin(.bottom, .large)

        ForEach(articles.typed("life")) { article in
            ArticlePreview(for: article)
                .margin(.bottom, .medium)
        }
    }
}
