import Foundation

struct Conversation: Hashable, Identifiable {
    let id: UUID
    let contact: Contact
    var messages: [Message]

    init(id: UUID = UUID(), contact: Contact, messages: [Message] = []) {
        self.id = id
        self.contact = contact
        self.messages = messages
    }

    var lastMessage: Message? { messages.last }
}
