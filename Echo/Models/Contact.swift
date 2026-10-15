import Foundation

/// The person on the other side of a conversation.
struct Contact: Hashable, Identifiable {
    let id: UUID
    let name: String
    /// Index into `Theme.avatarColors`, so a contact keeps the same color everywhere.
    let colorIndex: Int

    init(id: UUID = UUID(), name: String, colorIndex: Int) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
    }

    /// "Arsen Petrosyan" → "AP", "Anna" → "A".
    var initials: String {
        String(name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased()
    }
}
