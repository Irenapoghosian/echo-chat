import Combine
import Foundation

/// One line in the chat list.
struct ConversationRow: Hashable, Identifiable {
    let id: Conversation.ID
    let name: String
    let initials: String
    let colorIndex: Int
    let preview: String
    let timestamp: String
    let isTyping: Bool
}

/// The chat list: newest conversation first, with a live "typing…" preview.
@MainActor
final class ConversationsViewModel {
    @Published private(set) var rows: [ConversationRow] = []

    let store: ChatStore
    private let now: () -> Date

    init(store: ChatStore, now: @escaping () -> Date = { Date() }) {
        self.store = store
        self.now = now
        store.$conversations
            .combineLatest(store.$typingIn)
            .map { [now] conversations, typing in
                Self.rows(for: conversations, typing: typing, now: now())
            }
            .assign(to: &$rows)
    }

    func makeChatViewModel(for id: Conversation.ID) -> ChatViewModel? {
        guard let conversation = store.conversation(with: id) else { return nil }
        return ChatViewModel(conversation: conversation, store: store, now: now)
    }

    nonisolated static func rows(
        for conversations: [Conversation],
        typing: Set<Conversation.ID>,
        now: Date,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> [ConversationRow] {
        conversations
            .sorted { ($0.lastMessage?.sentAt ?? .distantPast) > ($1.lastMessage?.sentAt ?? .distantPast) }
            .map { conversation in
                let isTyping = typing.contains(conversation.id)
                return ConversationRow(
                    id: conversation.id,
                    name: conversation.contact.name,
                    initials: conversation.contact.initials,
                    colorIndex: conversation.contact.colorIndex,
                    preview: isTyping ? "typing…" : ChatFormat.preview(of: conversation.lastMessage),
                    timestamp: conversation.lastMessage.map {
                        ChatFormat.listTimestamp($0.sentAt, now: now, calendar: calendar, locale: locale)
                    } ?? "",
                    isTyping: isTyping
                )
            }
    }
}
