import Foundation
import Ignite

struct BlogPost: ArticlePage {
    /// The update date, but only when the post actually declares one.
    /// Ignite falls back to the file's modification time when `modified:` is
    /// absent, and CI checkouts rewrite that to the build time — so an
    /// unconditional `article.lastModified` would mark every post as updated today.
    private var updatedDate: Date? {
        guard article.metadata["modified"] != nil else { return nil }
        return article.lastModified
    }

    var body: some HTML {
        Text(article.title)
            .font(.title1)

        Text {
            "Posted "
            Time(article.date.formatted(date: .abbreviated, time: .omitted), dateTime: article.date)

            if let updatedDate {
                " • Updated "
                Time(updatedDate.formatted(date: .abbreviated, time: .omitted), dateTime: updatedDate)
            }

            " • \(article.estimatedReadingMinutes) min read"
        }
        .font(.small)
        .foregroundStyle(.secondary)

        if let tagLinks = article.tagLinks() {
            Section {
                ForEach(tagLinks) { link in
                    link.margin(.trailing, .small)
                }
            }
            .margin(.bottom, .medium)
        }

        article.text
    }
}
