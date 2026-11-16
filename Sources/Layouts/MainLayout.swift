import Foundation
import Ignite

struct MainLayout: Layout {
    var body: some Document {
        Head {
            MetaLink(href: "/css/custom.css", rel: .stylesheet)
        }

        Body {
            NavigationBar(logo: "Manny.Dev") {
                Link("Home", target: "/")
                Link("Tech", target: "/tech")
                Link("Life", target: "/life")
                Link("Tags", target: "/tags")
                Link("About", target: "/about")
            }

            Section {
                content
            }
            .class("reading-column")

            SiteFooter()
                .class("reading-column")
        }
    }
}
