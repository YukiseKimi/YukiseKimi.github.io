import Foundation
import Ignite

struct About: StaticPage {
    var title = "About"
    var path = "/about"

    var body: some HTML {
        Text("About me")
            .font(.title1)

        Text("Hi, I'm Manny. I write about software engineering to solidify what I learn, and about my experience moving abroad.")

        Text("You can subscribe to everything I write via the RSS feed at /feed.rss.")
    }
}
