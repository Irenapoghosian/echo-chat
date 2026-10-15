import Foundation

/// Text shown around messages: times, list previews and VoiceOver labels.
enum ChatFormat {

    /// "14:05" or "2:05 PM", following the user's region.
    static func time(_ date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, timeZone: timeZone))
    }

    /// The right-hand timestamp in the chat list: a time today, "Yesterday", then a short date.
    static func listTimestamp(
        _ date: Date,
        now: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return time(date, locale: locale, timeZone: calendar.timeZone)
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        return date.formatted(Date.FormatStyle(date: .numeric, time: .omitted, locale: locale, timeZone: calendar.timeZone))
    }

    /// The second line in the chat list: "You: See you at 12!", "📷 Photo".
    static func preview(of message: Message?) -> String {
        guard let message else { return "No messages yet" }
        let body: String
        switch message.content {
        case .text(let text): body = text
        case .image: body = "📷 Photo"
        }
        return message.isFromMe ? "You: \(body)" : body
    }

    /// What VoiceOver reads for a bubble: "You, 14:05, See you at 12!".
    static func accessibilityLabel(
        for message: Message,
        contactName: String,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        let who = message.isFromMe ? "You" : contactName
        let what: String
        switch message.content {
        case .text(let text): what = text
        case .image: what = "Photo"
        }
        return "\(who), \(time(message.sentAt, locale: locale, timeZone: timeZone)), \(what)"
    }
}
