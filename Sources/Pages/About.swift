import Foundation
import Ignite

struct About: StaticPage {
    var title = "About"
    var path = "/about"

    var body: some HTML {
        Text("About me")
            .font(.title1)

        Text("Hi, I'm Manny. I write about software engineering, and about my experience moving abroad.")
    }
}
