import Foundation
import Ignite

struct Tags: TagPage {
    var body: some HTML {
        Text(tag.name)
            .font(.title1)

        List(tag.articles) { article in
            Link(article)
        }
    }
}
