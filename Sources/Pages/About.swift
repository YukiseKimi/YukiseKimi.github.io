import Foundation
import Ignite

struct About: StaticPage {
    var title = "About"
    var description = "Manny Chau, a software engineer writing about engineering practice and the experience of moving abroad. A little about me and what I write here."
    var path = "/about"

    var body: some HTML {
        Text("About me")
            .font(.title1)

        Text("Hi, I'm Manny. I'm a software engineer based abroad, and I write here about two things:")

        List {
            ListItem {
                Text("Software engineering: how I write and ship code, tools I reach for, and the occasional lesson from a project gone wrong.")
            }
            ListItem {
                Text("Life abroad: notes on living and working in a new country — the practical stuff, the small surprises, and the identity shifts that come with both.")
            }
        }

        Text("Posts are in the Tech and Life sections; the Tags page is a good way to find posts by topic.")
            .margin(.top, .medium)

        Text("Contact")
            .font(.title2)
            .margin(.top, .large)

        Text("I'm happy to talk shop — GitHub and LinkedIn are the usual places to find me:")

        Section {
            Link("GitHub", target: "https://github.com/YukiseKimi")
                .target(.newWindow)
                .relationship(.noOpener, .noReferrer)
            Link("LinkedIn", target: "https://www.linkedin.com/in/mannyc25/")
                .target(.newWindow)
                .relationship(.noOpener, .noReferrer)
        }
        .class("about-contact")
    }
}
