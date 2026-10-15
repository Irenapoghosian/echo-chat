import UIKit
import XCTest
@testable import Echo

final class ChatFormatTests: XCTestCase {
    private let utc = Fixtures.calendar.timeZone

    func testTimeFollowsTheLocale() {
        XCTAssertEqual(ChatFormat.time(Fixtures.now, locale: Fixtures.locale, timeZone: utc), "14:05")
    }

    func testListTimestamps() {
        let calendar = Fixtures.calendar
        let now = Fixtures.now
        XCTAssertEqual(ChatFormat.listTimestamp(now, now: now, calendar: calendar, locale: Fixtures.locale), "14:05")
        XCTAssertEqual(
            ChatFormat.listTimestamp(now.addingTimeInterval(-24 * 3600), now: now, calendar: calendar, locale: Fixtures.locale),
            "Yesterday"
        )
        XCTAssertEqual(
            ChatFormat.listTimestamp(now.addingTimeInterval(-5 * 24 * 3600), now: now, calendar: calendar, locale: Fixtures.locale),
            "10/10/2026"
        )
    }

    func testPreviews() {
        XCTAssertEqual(ChatFormat.preview(of: nil), "No messages yet")
        XCTAssertEqual(ChatFormat.preview(of: Fixtures.text("Hi!")), "Hi!")
        XCTAssertEqual(ChatFormat.preview(of: Fixtures.text("See you", from: .currentUser)), "You: See you")

        let photo = Message(sender: .currentUser, content: .image(ImageAttachment(image: UIImage())), sentAt: Fixtures.now)
        XCTAssertEqual(ChatFormat.preview(of: photo), "You: 📷 Photo")
    }

    func testVoiceOverReadsWhoWhenAndWhat() {
        let label = ChatFormat.accessibilityLabel(
            for: Fixtures.text("Ready?"), contactName: "Arsen", locale: Fixtures.locale, timeZone: utc
        )
        XCTAssertEqual(label, "Arsen, 14:05, Ready?")
    }

    func testRepliesAreReadWithTheirQuote() {
        let original = Fixtures.text("Ready?")
        let reply = Message(sender: .currentUser, content: .text("Yes!"), sentAt: Fixtures.now, replyTo: original.quote)

        let label = ChatFormat.accessibilityLabel(for: reply, contactName: "Arsen", locale: Fixtures.locale, timeZone: utc)

        XCTAssertEqual(label, "You, 14:05, Yes!, in reply to Arsen: Ready?")
        XCTAssertEqual(ChatFormat.summary(of: .image(ImageAttachment(image: UIImage()))), "📷 Photo")
    }

    func testInitials() {
        XCTAssertEqual(Contact(name: "Arsen Petrosyan", colorIndex: 0).initials, "AP")
        XCTAssertEqual(Contact(name: "anna", colorIndex: 0).initials, "A")
        XCTAssertEqual(Contact(name: "iOS Team Yerevan", colorIndex: 0).initials, "IT")
    }

    func testPhotoBubblesKeepSensibleProportions() {
        XCTAssertEqual(MessageCell.photoHeight(fitting: CGSize(width: 100, height: 100)), MessageCell.photoSide)
        XCTAssertEqual(MessageCell.photoHeight(fitting: CGSize(width: 100, height: 1000)), (MessageCell.photoSide * 1.4).rounded())
        XCTAssertEqual(MessageCell.photoHeight(fitting: CGSize(width: 1000, height: 100)), (MessageCell.photoSide * 0.5).rounded())
        XCTAssertEqual(MessageCell.photoHeight(fitting: .zero), MessageCell.photoSide)
    }
}
