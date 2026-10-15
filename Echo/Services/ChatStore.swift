import Combine
import Foundation

/// The single source of truth for every conversation. Screens observe it through
/// their view models, so the list and an open chat always agree.
@MainActor
final class ChatStore {
    @Published private(set) var conversations: [Conversation]
    /// Conversations where the other person is "typing" a reply right now.
    @Published private(set) var typingIn: Set<Conversation.ID> = []

    private let replies: ReplyService
    private let replyDelay: Duration
    private let clock: () -> Date
    private let sleep: @MainActor (Duration) async -> Void

    init(
        conversations: [Conversation],
        replies: ReplyService,
        replyDelay: Duration = .seconds(1.5),
        clock: @escaping () -> Date = { Date() },
        sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.conversations = conversations
        self.replies = replies
        self.replyDelay = replyDelay
        self.clock = clock
        self.sleep = sleep
    }

    func conversation(with id: Conversation.ID) -> Conversation? {
        conversations.first { $0.id == id }
    }

    /// Adds my message right away and starts the reply. The returned task finishes
    /// when the reply has arrived; the app ignores it, tests await it.
    @discardableResult
    func send(_ content: MessageContent, in conversationID: Conversation.ID) -> Task<Void, Never>? {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return nil }
        let message = Message(sender: .currentUser, content: content, sentAt: clock())
        conversations[index].messages.append(message)
        return Task { await self.deliverReply(to: message, in: conversationID) }
    }

    private func deliverReply(to message: Message, in conversationID: Conversation.ID) async {
        typingIn.insert(conversationID)
        await sleep(replyDelay)
        typingIn.remove(conversationID)

        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        let reply = Message(sender: .contact, content: replies.reply(to: message), sentAt: clock())
        conversations[index].messages.append(reply)
    }
}
