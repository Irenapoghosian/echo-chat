import UIKit

enum Sender: Hashable {
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

struct Message: Hashable, Identifiable {
    let id: UUID
    let sender: Sender
    let content: MessageContent
    let sentAt: Date

    init(id: UUID = UUID(), sender: Sender, content: MessageContent, sentAt: Date) {
        self.id = id
        self.sender = sender
        self.content = content
        self.sentAt = sentAt
    }

    var isFromMe: Bool { sender == .currentUser }
}
