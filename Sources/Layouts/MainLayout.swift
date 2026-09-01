import Foundation
import Ignite

struct MainLayout: Layout {
    var body: some Document {
        Body {
            NavigationBar(logo: "Manny Chau") {
                Link("Home", target: "/")
                Link("Tech", target: "/tech")
                Link("Life", target: "/life")
                Link("Tags", target: "/tags")
                Link("About", target: "/about")
            }

            content

            IgniteFooter()
        }
    }
}
