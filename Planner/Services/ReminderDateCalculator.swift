import Foundation

struct ReminderDateCalculator {
    func triggerDate(for dueDate: Date, leadHours: Int, now: Date = Date()) -> Date? {
        guard leadHours >= 0 else { return nil }
        let triggerDate = dueDate.addingTimeInterval(TimeInterval(-leadHours * 3600))
        return triggerDate > now ? triggerDate : nil
    }
}
