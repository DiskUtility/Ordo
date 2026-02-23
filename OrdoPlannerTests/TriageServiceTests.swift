import Foundation
import Testing
@testable import Planner

struct TriageServiceTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func bucketizeSplitsOverdueTodayAndUpcoming() {
        let scorer = DefaultTriageScorer()
        let now = Date(timeIntervalSince1970: 1_710_000_000)

        let startOfToday = calendar.startOfDay(for: now)
        let overdueDate = calendar.date(byAdding: .hour, value: -2, to: startOfToday)!
        let todayDate = calendar.date(byAdding: .hour, value: 8, to: startOfToday)!
        let upcomingDate = calendar.date(byAdding: .day, value: 3, to: startOfToday)!

        let overdue = AssignmentTask(title: "Overdue", dueDate: overdueDate)
        let today = AssignmentTask(title: "Today", dueDate: todayDate)
        let upcoming = AssignmentTask(title: "Upcoming", dueDate: upcomingDate)

        let bucket = scorer.bucketize(tasks: [upcoming, overdue, today], now: now, calendar: calendar)

        #expect(bucket.overdue.map(\.title) == ["Overdue"])
        #expect(bucket.today.map(\.title) == ["Today"])
        #expect(bucket.upcoming.map(\.title) == ["Upcoming"])
    }

    @Test
    func bucketSortingUsesDueDateThenPriorityThenDuration() {
        let scorer = DefaultTriageScorer()
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let startOfToday = calendar.startOfDay(for: now)
        let todayDate = calendar.date(byAdding: .hour, value: 10, to: startOfToday)!

        let highPriority = AssignmentTask(title: "High", dueDate: todayDate, estimatedMinutes: 30, priority: .high)
        let mediumLong = AssignmentTask(title: "Medium long", dueDate: todayDate, estimatedMinutes: 120, priority: .medium)
        let mediumShort = AssignmentTask(title: "Medium short", dueDate: todayDate, estimatedMinutes: 60, priority: .medium)

        let bucket = scorer.bucketize(tasks: [mediumShort, highPriority, mediumLong], now: now, calendar: calendar)

        #expect(bucket.today.map(\.title) == ["High", "Medium long", "Medium short"])
    }
}
