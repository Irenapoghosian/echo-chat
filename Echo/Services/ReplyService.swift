import Foundation

/// Decides what the other person answers. A real app would receive this from a server;
/// keeping it behind a protocol means the screens never know the difference.
protocol ReplyService {
    func reply(to message: Message) -> MessageContent
}

/// Friendly canned answers, so the app is fun to try without a backend.
struct CannedReplyService: ReplyService {
    static let defaultReplies = [
        "Sounds great!",
        "Really? That's very interesting!",
        "Could you tell me more about it?",
        "I see, thanks for letting me know!",
        "I'm a bit busy right now, I'll message you later! 😊",
    ]

    private let replies: [String]
    private let pick: ([String]) -> String?

    /// - Parameter pick: Chooses one reply; tests pass a deterministic one.
    init(replies: [String] = Self.defaultReplies, pick: @escaping ([String]) -> String? = { $0.randomElement() }) {
        self.replies = replies
        self.pick = pick
    }

    func reply(to message: Message) -> MessageContent {
        if case .image = message.content {
            return .text("Wow, nice photo! 📸")
        }
        return .text(pick(replies) ?? "👍")
    }
}
