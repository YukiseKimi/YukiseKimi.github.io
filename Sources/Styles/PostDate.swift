import Foundation

extension Date {
    /// The date as shown on the site, e.g. "Sep 1, 2026".
    ///
    /// The locale and time zone are fixed so the build is identical on every
    /// machine: Linux CI containers default to a day-first locale ("1 Sep 2026"),
    /// and post dates are midnight UTC, so a local time zone west of UTC would
    /// show the previous day.
    var postDateString: String {
        formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted,
                             locale: Locale(identifier: "en_US"),
                             timeZone: TimeZone(identifier: "UTC")!)
        )
    }
}
