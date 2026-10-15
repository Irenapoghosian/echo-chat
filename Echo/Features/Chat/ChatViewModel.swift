import Combine
import UIKit

/// One open conversation: its messages grouped by day, the "typing…" state and sending.
@MainActor
final class ChatViewModel {
    @Published private(set) var sections: [MessageSection] = []
    @Published private(set) var isContactTyping = false
    /// The message the next one will answer, shown above the composer.
    @Published private(set) var replyingTo: Message?

    let contact: Contact
    private let conversationID: Conversation.ID
    private let store: ChatStore
    private let now: () -> Date
    private var messagesByID: [Message.ID: Message] = [:]
    private var cancellables = Set<AnyCancellable>()

    init(conversation: Conversation, store: ChatStore, now: @escaping () -> Date = { Date() }) {
        self.contact = conversation.contact
        self.conversationID = conversation.id
        self.store = store
        self.now = now

        let id = conversation.id
        store.$conversations
            .map { conversations in conversations.first(where: { $0.id == id })?.messages ?? [] }
            .removeDuplicates()
            .sink { [weak self] messages in self?.apply(messages) }
            .store(in: &cancellables)

        store.$typingIn
            .map { $0.contains(id) }
            .removeDuplicates()
            .assign(to: &$isContactTyping)
    }

    /// The table only stores message IDs; cells look the message up here.
    func message(with id: Message.ID) -> Message? {
        messagesByID[id]
    }

    func title(forSectionOn day: Date) -> String? {
        sections.first { $0.day == day }?.title
    }

    /// "You" or the contact's name, for quotes.
    func author(of sender: Sender) -> String {
        ChatFormat.author(of: sender, contactName: contact.name)
    }

    // MARK: - Actions

    /// Sends trimmed text, as a reply when one is in progress; blank messages are ignored.
    @discardableResult
    func send(text: String) -> Task<Void, Never>? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return send(.text(trimmed))
    }

    @discardableResult
    func send(image: UIImage) -> Task<Void, Never>? {
        send(.image(ImageAttachment(image: image)))
    }

    func startReply(to id: Message.ID) {
        replyingTo = messagesByID[id]
    }

    func cancelReply() {
        replyingTo = nil
    }

    func delete(_ id: Message.ID) {
        if replyingTo?.id == id { replyingTo = nil }
        store.deleteMessage(id, in: conversationID)
    }

    private func send(_ content: MessageContent) -> Task<Void, Never>? {
        let original = replyingTo
        replyingTo = nil
        return store.send(content, replyingTo: original, in: conversationID)
    }

    private func apply(_ messages: [Message]) {
        // Update the lookup first: setting `sections` makes the table ask for cells right away.
        messagesByID = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        sections = MessageGrouping.sections(for: messages, now: now())
    }
}
