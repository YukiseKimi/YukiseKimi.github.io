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
                // noopener/noreferrer: a new tab must not reach back through
                // window.opener. `relationship` is Ignite's public rel API.
                Link("Ignite", target: "https://github.com/twostraws/Ignite")
                    .target(.newWindow)
                    .relationship(.noOpener, .noReferrer)
            }
            .font(.small)
            .foregroundStyle(.secondary)
            .margin(.bottom, .none)

            Section {
                // The icon carries its own description, but the <a> needs its
                // own label so screen readers announce the new-tab behaviour.
                Link(Image(systemName: "github", description: "GitHub"),
                     target: "https://github.com/YukiseKimi")
                    .target(.newWindow)
                    .relationship(.noOpener, .noReferrer)
                    .aria(.label, "GitHub (opens in new tab)")
                Link(Image(systemName: "linkedin", description: "LinkedIn"),
                     target: "https://www.linkedin.com/in/mannyc25/")
                    .target(.newWindow)
                    .relationship(.noOpener, .noReferrer)
                    .aria(.label, "LinkedIn (opens in new tab)")
            }
            .class("footer-icons")
        }
        .class("d-flex", "flex-column", "flex-sm-row", "justify-content-between", "align-items-center", "gap-2")
        .padding(.vertical, .large)
        .margin(.top, .xLarge)
        .class("site-footer")
    }
}
