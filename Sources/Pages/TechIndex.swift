import Foundation
import Ignite

struct TechIndex: StaticPage {
    @Environment(\.articles) var articles
    var title = "Tech"
    var path = "/tech"

    var body: some HTML {
        Text("Tech")
            .font(.title1)

        Text("About my experience using technologies")
            .font(.lead)
            .margin(.bottom, .large)

        ForEach(articles.typed("tech")) { article in
            ArticlePreview(for: article)
                .articlePreviewStyle(DatedPreviewStyle())
                .margin(.bottom, .medium)
        }
    }
}
