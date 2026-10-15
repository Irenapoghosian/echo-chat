import Foundation
@testable import Echo

enum Fixtures {
    /// UTC and en_GB, so dates and times read the same on every machine.
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }

    static let locale = Locale(identifier: "en_GB")

    /// Thursday 15 October 2026, 14:05 UTC.
    static let now = Date(timeIntervalSince1970: 1_792_073_100)

    static let contact = Contact(name: "Arsen Petrosyan", colorIndex: 0)

    static func text(_ text: String, from sender: Sender = .contact, at date: Date = now) -> Message {
        Message(sender: sender, content: .text(text), sentAt: date)
    }
}

/// A clock tests can move by hand.
final class TestClock {
    var now = Fixtures.now
}
