import XCTest
@testable import Echo

final class MessageGroupingTests: XCTestCase {
    private let now = Fixtures.now
    private let calendar = Fixtures.calendar
    private let locale = Fixtures.locale

    func testMessagesAreGroupedByDayInOrder() {
        let yesterday = now.addingTimeInterval(-24 * 3600)
        let messages = [
            Fixtures.text("first", at: yesterday),
            Fixtures.text("second", at: yesterday.addingTimeInterval(60)),
            Fixtures.text("third", at: now),
        ]

        let sections = MessageGrouping.sections(for: messages, now: now, calendar: calendar, locale: locale)

        XCTAssertEqual(sections.map(\.title), ["Yesterday", "Today"])
        XCTAssertEqual(sections[0].messages.map(\.content), [.text("first"), .text("second")])
        XCTAssertEqual(sections[1].messages.count, 1)
    }

    func testOlderDaysShowTheDate() {
        let lastWeek = now.addingTimeInterval(-5 * 24 * 3600)
        let lastYear = now.addingTimeInterval(-370 * 24 * 3600)

        XCTAssertEqual(MessageGrouping.title(for: lastWeek, now: now, calendar: calendar, locale: locale), "Sat 10 Oct")
        XCTAssertEqual(MessageGrouping.title(for: lastYear, now: now, calendar: calendar, locale: locale), "10 Oct 2025")
    }

    func testNoMessagesMeansNoSections() {
        XCTAssertTrue(MessageGrouping.sections(for: [], now: now, calendar: calendar, locale: locale).isEmpty)
    }
}
