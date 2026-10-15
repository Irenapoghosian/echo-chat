import UIKit

/// Raw values are stored on disk, so they must not change.
enum Sender: String, Hashable {
    case currentUser
    case contact
}

/// A picked photo. Compared by `id`, so the image itself never has to be hashed.
struct ImageAttachment: Hashable {
    let id: UUID
    let image: UIImage

    init(id: UUID = UUID(), image: UIImage) {
        self.id = id
        self.image = image
    }

    static func == (lhs: ImageAttachment, rhs: ImageAttachment) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum MessageContent: Hashable {
    case text(String)
    case image(ImageAttachment)
}

/// A snapshot of the message being replied to, shown above the reply.
/// It is copied, not linked, so it still reads correctly if the original is deleted.
struct QuotedMessage: Hashable {
    let id: UUID
    let sender: Sender
    let summary: String
}

struct Message: Hashable, Identifiable {
    let id: UUID
    let sender: Sender
    let content: MessageContent
    let sentAt: Date
    let replyTo: QuotedMessage?

    init(id: UUID = UUID(), sender: Sender, content: MessageContent, sentAt: Date, replyTo: QuotedMessage? = nil) {
        self.id = id
        self.sender = sender
        self.content = content
        self.sentAt = sentAt
        self.replyTo = replyTo
    }

    var isFromMe: Bool { sender == .currentUser }

    /// This message as a quote for a reply.
    var quote: QuotedMessage {
        QuotedMessage(id: id, sender: sender, summary: ChatFormat.summary(of: content))
    }
}
