import Foundation
import Ignite

struct About: StaticPage {
    var title = "About"
    var description = "Manny Chau, a software engineer writing about engineering practice and the experience of moving abroad. A little about me and what I write here."
    var path = "/about"

    var body: some HTML {
        Text("About me")
            .font(.title1)

        Text("Hi, I'm Manny. I write about software engineering, and about my experience moving abroad.")
    }
}
