import Foundation

/// One day of a conversation, with its header title.
struct MessageSection: Hashable {
    let day: Date
    let title: String
    let messages: [Message]
}

/// Splits a conversation into days: "Today", "Yesterday", then dates.
enum MessageGrouping {

    static func sections(
        for messages: [Message],
        now: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> [MessageSection] {
        // Grouping keeps each day's messages in the order they were sent.
        let byDay = Dictionary(grouping: messages) { calendar.startOfDay(for: $0.sentAt) }
        return byDay.keys.sorted().map { day in
            MessageSection(
                day: day,
                title: title(for: day, now: now, calendar: calendar, locale: locale),
                messages: byDay[day, default: []]
            )
        }
    }

    /// "Today", "Yesterday", "Mon 12 Oct" this year, "12 Oct 2025" before that.
    static func title(for day: Date, now: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        let sameYear = calendar.isDate(day, equalTo: now, toGranularity: .year)
        formatter.setLocalizedDateFormatFromTemplate(sameYear ? "EEEdMMM" : "dMMMy")
        return formatter.string(from: day)
    }
}
