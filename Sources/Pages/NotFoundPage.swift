import Foundation
import Ignite

/// The 404 page. Uses the site's main layout, with the error's title and
/// description plus a link back home.
struct NotFoundPage: ErrorPage {
    /// Always a 404, regardless of the ambient environment.
    var error: HTTPError { PageNotFoundError() }

    var body: some HTML {
        Section {
            Text(error.title)
                .font(.title1)
            Text(error.description)
            Link("Go back to the homepage", target: "/")
                .linkStyle(.button)
        }
    }
}
