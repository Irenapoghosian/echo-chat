import CoreData
import UIKit

/// Saves conversations with Core Data on the main context. The data is small and
/// every write is a single message, so there is no need for background contexts.
final class CoreDataChatPersistence: ChatPersistence {
    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }

    /// - Parameter inMemory: Keeps everything in memory, for tests and previews.
    init(inMemory: Bool = false) throws {
        container = NSPersistentContainer(name: "Echo", managedObjectModel: CoreDataModel.shared)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - ChatPersistence

    func loadConversations() throws -> [Conversation] {
        let request = NSFetchRequest<ConversationRecord>(entityName: "ConversationRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "contactName", ascending: true)]
        return try context.fetch(request).map(Self.conversation(from:))
    }

    func insert(_ conversations: [Conversation]) throws {
        for conversation in conversations {
            let record = ConversationRecord(context: context)
            record.id = conversation.id
            record.contactID = conversation.contact.id
            record.contactName = conversation.contact.name
            record.colorIndex = Int16(conversation.contact.colorIndex)
            for (position, message) in conversation.messages.enumerated() {
                Self.makeRecord(for: message, position: Int64(position), in: record, context: context)
            }
        }
        try saveIfNeeded()
    }

    func insert(_ message: Message, into conversationID: Conversation.ID) throws {
        let request = NSFetchRequest<ConversationRecord>(entityName: "ConversationRecord")
        request.predicate = NSPredicate(format: "id == %@", conversationID as CVarArg)
        request.fetchLimit = 1
        guard let record = try context.fetch(request).first else { return }
        let next = (record.messages.map(\.position).max() ?? -1) + 1
        Self.makeRecord(for: message, position: next, in: record, context: context)
        try saveIfNeeded()
    }

    func deleteMessage(_ id: Message.ID) throws {
        let request = NSFetchRequest<MessageRecord>(entityName: "MessageRecord")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        for record in try context.fetch(request) {
            context.delete(record)
        }
        try saveIfNeeded()
    }

    // MARK: - Mapping

    private func saveIfNeeded() throws {
        if context.hasChanges { try context.save() }
    }

    private static func makeRecord(
        for message: Message,
        position: Int64,
        in conversation: ConversationRecord,
        context: NSManagedObjectContext
    ) {
        let record = MessageRecord(context: context)
        record.id = message.id
        record.sender = message.sender.rawValue
        record.sentAt = message.sentAt
        record.position = position
        switch message.content {
        case .text(let text):
            record.text = text
        case .image(let attachment):
            record.imageData = attachment.image.jpegData(compressionQuality: 0.85)
        }
        record.replyID = message.replyTo?.id
        record.replySender = message.replyTo?.sender.rawValue
        record.replySummary = message.replyTo?.summary
        record.conversation = conversation
    }

    private static func conversation(from record: ConversationRecord) -> Conversation {
        Conversation(
            id: record.id,
            contact: Contact(id: record.contactID, name: record.contactName, colorIndex: Int(record.colorIndex)),
            messages: record.messages
                .sorted { $0.position < $1.position }
                .compactMap(message(from:))
        )
    }

    /// `nil` for a row that can't be read (an unknown sender or a corrupt photo) instead of crashing.
    private static func message(from record: MessageRecord) -> Message? {
        guard let sender = Sender(rawValue: record.sender) else { return nil }
        let content: MessageContent
        if let text = record.text {
            content = .text(text)
        } else if let data = record.imageData, let image = UIImage(data: data) {
            content = .image(ImageAttachment(id: record.id, image: image))
        } else {
            return nil
        }

        var quote: QuotedMessage?
        if let id = record.replyID, let raw = record.replySender, let quotedSender = Sender(rawValue: raw) {
            quote = QuotedMessage(id: id, sender: quotedSender, summary: record.replySummary ?? "")
        }
        return Message(id: record.id, sender: sender, content: content, sentAt: record.sentAt, replyTo: quote)
    }
}
