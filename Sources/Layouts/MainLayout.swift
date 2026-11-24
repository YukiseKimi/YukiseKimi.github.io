import Foundation
import Ignite

struct MainLayout: Layout {
    var body: some Document {
        // Ignite's Head includes standardHeaders() and socialSharingTags()
        // automatically, which already cover description, author, og: and
        // twitter: tags. Only site-specific additions belong here.
        Head {
            MetaLink(href: "/css/custom.css", rel: .stylesheet)
            // Privacy-friendly analytics; no cookies, no personal data.
            Analytics(.plausible(domain: "mannychau.com"))
        }

        Body {
            // Skip link: first thing in the tab order, so keyboard users can
            // jump past the navigation. Hidden until focused (see custom.css).
            Link("Skip to content", target: "#main-content")
                .class("skip-link")

            NavigationBar(logo: "Manny.Dev") {
                Link("Home", target: "/")
                Link("Tech", target: "/tech")
                Link("Life", target: "/life")
                Link("Tags", target: "/tags")
                Link("Search", target: "/search")
                Link("About", target: "/about")
            }

            Section {
                content
            }
            .class("reading-column")
            .id("main-content")

            SiteFooter()
                .class("reading-column")
        }
    }
}
