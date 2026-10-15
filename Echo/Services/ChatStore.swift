import Combine
import Foundation
import os

/// The single source of truth for every conversation. Screens observe it through
/// their view models, so the list and an open chat always agree.
@MainActor
final class ChatStore {
    @Published private(set) var conversations: [Conversation]
    /// Conversations where the other person is "typing" a reply right now.
    @Published private(set) var typingIn: Set<Conversation.ID> = []

    private let replies: ReplyService
    private let persistence: ChatPersistence?
    private let replyDelay: Duration
    private let clock: () -> Date
    private let sleep: @MainActor (Duration) async -> Void

    init(
        conversations: [Conversation],
        replies: ReplyService,
        persistence: ChatPersistence? = nil,
        replyDelay: Duration = .seconds(1.5),
        clock: @escaping () -> Date = { Date() },
        sleep: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.conversations = conversations
        self.replies = replies
        self.persistence = persistence
        self.replyDelay = replyDelay
        self.clock = clock
        self.sleep = sleep
    }

    func conversation(with id: Conversation.ID) -> Conversation? {
        conversations.first { $0.id == id }
    }

    /// Adds my message right away, saves it and starts the reply. The returned task finishes
    /// when the reply has arrived; the app ignores it, tests await it.
    @discardableResult
    func send(
        _ content: MessageContent,
        replyingTo original: Message? = nil,
        in conversationID: Conversation.ID
    ) -> Task<Void, Never>? {
        guard conversation(with: conversationID) != nil else { return nil }
        let message = Message(sender: .currentUser, content: content, sentAt: clock(), replyTo: original?.quote)
        append(message, to: conversationID)
        return Task { await self.deliverReply(to: message, in: conversationID) }
    }

    func deleteMessage(_ id: Message.ID, in conversationID: Conversation.ID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].messages.removeAll { $0.id == id }
        do {
            try persistence?.deleteMessage(id)
        } catch {
            Self.log.error("Couldn't delete a message: \(error.localizedDescription)")
        }
    }

    private func append(_ message: Message, to conversationID: Conversation.ID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return }
        conversations[index].messages.append(message)
        do {
            try persistence?.insert(message, into: conversationID)
        } catch {
            // The message stays on screen; it just won't survive a relaunch.
            Self.log.error("Couldn't save a message: \(error.localizedDescription)")
        }
    }

    private static let log = Logger(subsystem: "com.irenapoghosyan.echo", category: "ChatStore")

    private func deliverReply(to message: Message, in conversationID: Conversation.ID) async {
        typingIn.insert(conversationID)
        await sleep(replyDelay)
        typingIn.remove(conversationID)

        let reply = Message(sender: .contact, content: replies.reply(to: message), sentAt: clock())
        append(reply, to: conversationID)
    }
}
