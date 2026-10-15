import Foundation

/// The conversations the app starts with, dated relative to `now` so "Today" and
/// "Yesterday" always read naturally.
enum SampleData {
    static func conversations(now: Date = Date(), calendar: Calendar = .current) -> [Conversation] {
        let today = calendar.startOfDay(for: now)
        let yesterdayEvening = today.addingTimeInterval(-3 * 3600)
        let lastWeek = calendar.date(byAdding: .day, value: -4, to: today)?.addingTimeInterval(11 * 3600) ?? today

        func message(_ sender: Sender, _ text: String, at date: Date) -> Message {
            Message(sender: sender, content: .text(text), sentAt: date)
        }

        let arsen = Conversation(
            contact: Contact(name: "Arsen Petrosyan", colorIndex: 0),
            messages: [
                message(.contact, "Hey! Did you see the new design for the app?", at: yesterdayEvening),
                message(.currentUser, "Yes, I love the colors 😍", at: yesterdayEvening.addingTimeInterval(60)),
                message(.contact, "Let's ship it tomorrow then", at: yesterdayEvening.addingTimeInterval(180)),
                message(.contact, "Good morning! Ready for the release?", at: now.addingTimeInterval(-25 * 60)),
                message(.currentUser, "Almost, finishing the last screen", at: now.addingTimeInterval(-20 * 60)),
            ]
        )
        let anna = Conversation(
            contact: Contact(name: "Anna Grigoryan", colorIndex: 1),
            messages: [
                message(.contact, "Are we still meeting on Saturday?", at: lastWeek),
                message(.currentUser, "Of course, see you at 12!", at: lastWeek.addingTimeInterval(300)),
            ]
        )
        let team = Conversation(
            contact: Contact(name: "iOS Team", colorIndex: 3),
            messages: [
                message(.contact, "Standup moved to 10:30 today", at: now.addingTimeInterval(-3 * 3600)),
            ]
        )
        return [arsen, team, anna]
    }
}
