import Foundation
import Ignite

/// Footer: © and Ignite credit on the left, social icons on the right.
/// Stacks vertically on narrow screens.
struct SiteFooter: HTML {
    /// The year the site was built, so the © updates on every publish.
    private var year: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some HTML {
        Section {
            Text {
                "© \(year) Manny Chau · Built with "
                Link("Ignite", target: "https://github.com/twostraws/Ignite")
            }
            .font(.small)
            .foregroundStyle(.secondary)
            .margin(.bottom, .none)

            Section {
                Link(Image(systemName: "github", description: "GitHub"),
                     target: "https://github.com/YukiseKimi")
                Link(Image(systemName: "linkedin", description: "LinkedIn"),
                     target: "https://www.linkedin.com/in/mannyc25/")
            }
            .class("footer-icons")
        }
        .class("d-flex", "flex-column", "flex-sm-row", "justify-content-between", "align-items-center", "gap-2")
        .padding(.vertical, .large)
        .margin(.top, .xLarge)
        .class("site-footer")
    }
}
