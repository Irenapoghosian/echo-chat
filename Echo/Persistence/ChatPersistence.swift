import Foundation

/// Where conversations live between launches. `ChatStore` talks only to this protocol,
/// so the storage (Core Data today) can change without touching the screens.
protocol ChatPersistence {
    func loadConversations() throws -> [Conversation]
    func insert(_ conversations: [Conversation]) throws
    func insert(_ message: Message, into conversationID: Conversation.ID) throws
    func deleteMessage(_ id: Message.ID) throws
}

enum ChatBootstrap {
    /// Saved conversations, or the samples on the very first launch (which are then saved).
    static func conversations(
        from persistence: ChatPersistence?,
        sample: () -> [Conversation] = { SampleData.conversations() }
    ) -> [Conversation] {
        guard let persistence else { return sample() }
        if let saved = try? persistence.loadConversations(), !saved.isEmpty {
            return saved
        }
        let conversations = sample()
        try? persistence.insert(conversations)
        return conversations
    }
}
