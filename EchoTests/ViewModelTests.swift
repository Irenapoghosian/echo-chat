import UIKit
import XCTest
@testable import Echo

@MainActor
final class ChatViewModelTests: XCTestCase {
    private func makeModel(messages: [Message] = []) -> (ChatViewModel, ChatStore) {
        let conversation = Conversation(contact: Fixtures.contact, messages: messages)
        let store = ChatStore(
            conversations: [conversation],
            replies: CannedReplyService(pick: { $0.first }),
            clock: { Fixtures.now },
            sleep: { _ in }
        )
        return (ChatViewModel(conversation: conversation, store: store, now: { Fixtures.now }), store)
    }

    func testHistoryIsGroupedAndLookedUpByID() {
        let message = Fixtures.text("Hi")
        let (model, _) = makeModel(messages: [message])

        XCTAssertEqual(model.sections.count, 1)
        XCTAssertEqual(model.message(with: message.id), message)
        XCTAssertEqual(model.title(forSectionOn: model.sections[0].day), model.sections[0].title)
    }

    func testTextIsTrimmedAndBlankTextIgnored() {
        let (model, _) = makeModel()

        XCTAssertNil(model.send(text: "   \n "))
        XCTAssertTrue(model.sections.isEmpty)

        model.send(text: "  Hello  ")
        XCTAssertEqual(model.sections.first?.messages.first?.content, .text("Hello"))
    }

    func testTypingShowsWhileTheReplyIsOnItsWay() async {
        let (model, _) = makeModel()
        XCTAssertFalse(model.isContactTyping)

        await model.send(text: "Hello")?.value

        XCTAssertFalse(model.isContactTyping)
        XCTAssertEqual(model.sections.first?.messages.count, 2)
    }

    func testPhotosAreSent() {
        let (model, _) = makeModel()
        model.send(image: UIImage())
        guard case .image? = model.sections.first?.messages.first?.content else {
            return XCTFail("Expected a photo message")
        }
    }
}

@MainActor
final class ConversationsViewModelTests: XCTestCase {
    func testNewestConversationComesFirst() {
        let old = Conversation(contact: Contact(name: "Anna", colorIndex: 1), messages: [
            Fixtures.text("Old news", at: Fixtures.now.addingTimeInterval(-3600)),
        ])
        let recent = Conversation(contact: Fixtures.contact, messages: [Fixtures.text("Hot off the press")])
        let empty = Conversation(contact: Contact(name: "Nobody", colorIndex: 2))

        let rows = ConversationsViewModel.rows(
            for: [old, empty, recent], typing: [], now: Fixtures.now,
            calendar: Fixtures.calendar, locale: Fixtures.locale
        )

        XCTAssertEqual(rows.map(\.name), ["Arsen Petrosyan", "Anna", "Nobody"])
        XCTAssertEqual(rows[0].timestamp, "14:05")
        XCTAssertEqual(rows[2].preview, "No messages yet")
        XCTAssertEqual(rows[2].timestamp, "")
    }

    func testTypingReplacesThePreview() {
        let conversation = Conversation(contact: Fixtures.contact, messages: [Fixtures.text("Hi")])
        let rows = ConversationsViewModel.rows(for: [conversation], typing: [conversation.id], now: Fixtures.now)
        XCTAssertEqual(rows.first?.preview, "typing…")
        XCTAssertEqual(rows.first?.isTyping, true)
    }

    func testRowsFollowTheStore() async {
        let conversation = Conversation(contact: Fixtures.contact)
        let store = ChatStore(conversations: [conversation], replies: CannedReplyService(pick: { $0.first }), sleep: { _ in })
        let model = ConversationsViewModel(store: store)

        await store.send(.text("Hello"), in: conversation.id)?.value

        XCTAssertEqual(model.rows.first?.preview, CannedReplyService.defaultReplies[0])
        XCTAssertNotNil(model.makeChatViewModel(for: conversation.id))
        XCTAssertNil(model.makeChatViewModel(for: UUID()))
    }

    func testSampleDataIsReadyToShow() {
        let conversations = SampleData.conversations(now: Fixtures.now, calendar: Fixtures.calendar)
        XCTAssertEqual(conversations.count, 3)
        XCTAssertTrue(conversations.allSatisfy { !$0.messages.isEmpty })
    }
}
