import Foundation
import Ignite

struct BlogPost: ArticlePage {
    var body: some HTML {
        Text(article.title)
            .font(.title1)

        Text {
            Time(article.date.formatted(date: .abbreviated, time: .omitted), dateTime: article.date)
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
