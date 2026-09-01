import Foundation
import Ignite

struct Home: StaticPage {
    @Environment(\.articles) var articles
    var title = "Home"

    var body: some HTML {
        Text("MannyC.Dev")
            .font(.title1)

        Text("Writing about software to solidify what I learn, and about building a life in a new country.")
            .font(.lead)
            .margin(.bottom, .large)

        Text("Recent posts")
            .font(.title2)

        ForEach(articles.all.prefix(5)) { article in
            ArticlePreview(for: article)
                .margin(.bottom, .medium)
        }
    }
}
