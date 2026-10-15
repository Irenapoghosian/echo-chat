import UIKit
import XCTest
@testable import Echo

@MainActor
final class ChatStoreTests: XCTestCase {
    private let clock = TestClock()

    private func makeStore(
        replies: ReplyService = CannedReplyService(pick: { $0.first }),
        sleep: @escaping @MainActor (Duration) async -> Void = { _ in }
    ) -> (ChatStore, Conversation.ID) {
        let conversation = Conversation(contact: Fixtures.contact)
        let clock = self.clock
        let store = ChatStore(conversations: [conversation], replies: replies, clock: { clock.now }, sleep: sleep)
        return (store, conversation.id)
    }

    func testSendingAddsMyMessageRightAway() {
        let (store, id) = makeStore()

        store.send(.text("Hello"), in: id)

        let messages = store.conversation(with: id)?.messages ?? []
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages.first?.sender, .currentUser)
        XCTAssertEqual(messages.first?.sentAt, Fixtures.now)
    }

    func testTheContactRepliesAfterTyping() async {
        var typingWhileWaiting = false
        var store: ChatStore?
        let (created, id) = makeStore(sleep: { _ in typingWhileWaiting = store?.typingIn.isEmpty == false })
        store = created

        await created.send(.text("Hello"), in: id)?.value

        XCTAssertTrue(typingWhileWaiting)
        XCTAssertTrue(created.typingIn.isEmpty)
        let messages = created.conversation(with: id)?.messages ?? []
        XCTAssertEqual(messages.map(\.sender), [.currentUser, .contact])
        XCTAssertEqual(messages.last?.content, .text(CannedReplyService.defaultReplies[0]))
    }

    func testPhotosGetAPhotoReply() async {
        let (store, id) = makeStore()
        await store.send(.image(ImageAttachment(image: UIImage())), in: id)?.value
        XCTAssertEqual(store.conversation(with: id)?.messages.last?.content, .text("Wow, nice photo! 📸"))
    }

    func testSendingToAnUnknownConversationDoesNothing() {
        let (store, _) = makeStore()
        XCTAssertNil(store.send(.text("Hello"), in: UUID()))
    }
}
