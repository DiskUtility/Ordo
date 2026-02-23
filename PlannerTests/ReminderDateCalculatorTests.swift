import Foundation
import Testing
@testable import Planner

struct ReminderDateCalculatorTests {
    @Test
    func triggerDateReturnsNilWhenReminderWouldBeInPast() {
        let calculator = ReminderDateCalculator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let dueDate = now.addingTimeInterval(1_800)

        let triggerDate = calculator.triggerDate(for: dueDate, leadHours: 1, now: now)

        #expect(triggerDate == nil)
    }

    @Test
    func triggerDateReturnsFutureDateWhenValid() {
        let calculator = ReminderDateCalculator()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let dueDate = now.addingTimeInterval(10 * 3600)

        let triggerDate = calculator.triggerDate(for: dueDate, leadHours: 2, now: now)

        #expect(triggerDate == dueDate.addingTimeInterval(-2 * 3600))
    }
}
