import Foundation
import Ignite

struct Tags: TagPage {
    var body: some HTML {
        Text(tag.name)
            .font(.title1)

        ForEach(tag.articles) { article in
            ArticlePreview(for: article)
                .articlePreviewStyle(DatedPreviewStyle())
                .margin(.bottom, .medium)
        }
    }
}
