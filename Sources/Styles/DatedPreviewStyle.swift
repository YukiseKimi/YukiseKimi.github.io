import Foundation
import Ignite

/// A soft card for post lists: title, date and reading time, summary, and
/// plain #hashtag tags. Border and hover lift come from `.post-card` in
/// Assets/css/custom.css.
struct DatedPreviewStyle: ArticlePreviewStyle {
    func body(content article: Article) -> any HTML {
        Section {
            Text {
                Link(article)
            }
            .font(.title2)
            .class("post-card-title")
            .margin(.bottom, .none)

            Text {
                Time(article.date.postDateString, dateTime: article.date)
                " · \(article.estimatedReadingMinutes) min read"
            }
            .font(.small)
            .foregroundStyle(.secondary)
            .margin(.bottom, .small)

            Text(article.description)
                .margin(.bottom, .small)

            if let tags = article.tags, !tags.isEmpty {
                Section {
                    ForEach(tags) { tag in
                        Link("#\(tag)", target: "/tags/\(tag.convertedToSlug())")
                            .relationship(.tag)
                    }
                }
                .class("post-tags", "small")
                .margin(.bottom, .none)
            }
        }
        .class("post-card")
    }
}
