import Foundation

struct GreetingContent {
    let headline: String
    let subheadline: String
}

enum GreetingComposer {
    static func content(for date: Date, name: String, calendar: Calendar = .current) -> GreetingContent {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = cleanName.isEmpty ? "Student" : cleanName

        let weekdayIndex = (calendar.component(.weekday, from: date) + 5) % 7
        let dayName = weekdayName(for: date)
        let timeGreeting = timeOfDayGreeting(for: date, calendar: calendar)

        let multilingualGreetings = [
            "Ciao",      // Monday
            "Hola",      // Tuesday
            "Bonjour",   // Wednesday
            "Hello",     // Thursday
            "Konnichiwa",// Friday
            "Ola",       // Saturday
            "Guten Tag"  // Sunday
        ]

        let dayNudges = [
            "Kick off the week strong.",
            "Stay steady and keep building momentum.",
            "Midweek focus mode is on.",
            "Push through and finish key tasks.",
            "Wrap up the week with clarity.",
            "Use the weekend to get ahead.",
            "Plan your week with intention."
        ]

        let multilingual = multilingualGreetings[weekdayIndex]
        let dayNudge = dayNudges[weekdayIndex]

        return GreetingContent(
            headline: "\(multilingual), \(displayName)! \(timeGreeting)",
            subheadline: "\(dayName): \(dayNudge)"
        )
    }

    private static func timeOfDayGreeting(for date: Date, calendar: Calendar) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }

    private static func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
