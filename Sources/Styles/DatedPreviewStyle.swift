import Foundation
import Ignite

/// The default preview card omits dates, which makes a list of posts hard to
/// read chronologically. This adds the publication date under the title.
struct DatedPreviewStyle: ArticlePreviewStyle {
    func body(content article: Article) -> any HTML {
        Card(imageName: article.image) {
            Text(article.description)
                .margin(.bottom, .none)
        } header: {
            Text {
                Link(article)
            }
            .font(.title2)
            .margin(.bottom, .none)

            Text {
                Time(article.date.formatted(date: .abbreviated, time: .omitted), dateTime: article.date)
            }
            .font(.small)
            .foregroundStyle(.secondary)
        } footer: {
            if let tagLinks = article.tagLinks() {
                Section {
                    ForEach(tagLinks) { link in
                        link
                    }
                }
                .style(.marginTop, "-5px")
            }
        }
    }
}
