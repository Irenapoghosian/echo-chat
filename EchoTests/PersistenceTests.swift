import UIKit
import XCTest
@testable import Echo

final class PersistenceTests: XCTestCase {
    private func makePersistence() throws -> CoreDataChatPersistence {
        try CoreDataChatPersistence(inMemory: true)
    }

    private func photo() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1   // 4×4 pixels, so the size survives the JPEG round trip
        return UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }

    func testConversationsSurviveARoundTrip() throws {
        let persistence = try makePersistence()
        let conversation = Conversation(contact: Fixtures.contact, messages: [
            Fixtures.text("Hi"),
            Fixtures.text("Hello!", from: .currentUser),
        ])

        try persistence.insert([conversation])
        let loaded = try persistence.loadConversations()

        XCTAssertEqual(loaded, [conversation])
    }

    func testNewMessagesKeepTheirOrderEvenWithTheSameTimestamp() throws {
        let persistence = try makePersistence()
        let conversation = Conversation(contact: Fixtures.contact)
        try persistence.insert([conversation])

        let first = Fixtures.text("first")
        let second = Fixtures.text("second")
        try persistence.insert(first, into: conversation.id)
        try persistence.insert(second, into: conversation.id)

        XCTAssertEqual(try persistence.loadConversations().first?.messages, [first, second])
    }

    func testDeletedMessagesAreGone() throws {
        let persistence = try makePersistence()
        let keep = Fixtures.text("keep")
        let remove = Fixtures.text("remove")
        let conversation = Conversation(contact: Fixtures.contact, messages: [keep, remove])
        try persistence.insert([conversation])

        try persistence.deleteMessage(remove.id)

        XCTAssertEqual(try persistence.loadConversations().first?.messages, [keep])
    }

    func testPhotosAndRepliesAreSaved() throws {
        let persistence = try makePersistence()
        let original = Fixtures.text("Look at this")
        let reply = Message(
            sender: .currentUser,
            content: .image(ImageAttachment(image: photo())),
            sentAt: Fixtures.now,
            replyTo: original.quote
        )
        let conversation = Conversation(contact: Fixtures.contact, messages: [original, reply])
        try persistence.insert([conversation])

        let loaded = try XCTUnwrap(persistence.loadConversations().first?.messages.last)

        guard case .image(let attachment) = loaded.content else {
            return XCTFail("Expected the photo to come back")
        }
        XCTAssertEqual(attachment.image.size, CGSize(width: 4, height: 4))
        XCTAssertEqual(loaded.replyTo, QuotedMessage(id: original.id, sender: .contact, summary: "Look at this"))
    }

    func testTheFirstLaunchSavesTheSamplesOnce() throws {
        let persistence = try makePersistence()
        let sample = [Conversation(contact: Fixtures.contact, messages: [Fixtures.text("Welcome")])]

        let first = ChatBootstrap.conversations(from: persistence, sample: { sample })
        let second = ChatBootstrap.conversations(from: persistence, sample: { [] })

        XCTAssertEqual(first, sample)
        XCTAssertEqual(second, sample)
    }

    @MainActor
    func testTheStoreSavesWhatIsSentAndDeleted() async throws {
        let persistence = try makePersistence()
        let conversation = Conversation(contact: Fixtures.contact)
        try persistence.insert([conversation])
        let store = ChatStore(
            conversations: [conversation],
            replies: CannedReplyService(pick: { $0.first }),
            persistence: persistence,
            clock: { Fixtures.now },
            sleep: { _ in }
        )

        await store.send(.text("Hello"), in: conversation.id)?.value
        let saved = try persistence.loadConversations().first?.messages ?? []
        XCTAssertEqual(saved.map(\.sender), [.currentUser, .contact])

        store.deleteMessage(saved[0].id, in: conversation.id)
        XCTAssertEqual(try persistence.loadConversations().first?.messages.count, 1)
        XCTAssertEqual(store.conversation(with: conversation.id)?.messages.count, 1)
    }
}
