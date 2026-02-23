import Foundation

struct TriageBucket {
    var overdue: [AssignmentTask]
    var today: [AssignmentTask]
    var upcoming: [AssignmentTask]
}

protocol TriageScoring {
    func bucketize(tasks: [AssignmentTask], now: Date, calendar: Calendar) -> TriageBucket
}

struct DefaultTriageScorer: TriageScoring {
    func bucketize(tasks: [AssignmentTask], now: Date, calendar: Calendar) -> TriageBucket {
        let startOfToday = calendar.startOfDay(for: now)
        guard
            let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday),
            let endOfUpcomingWindow = calendar.date(byAdding: .day, value: 8, to: startOfToday)
        else {
            return TriageBucket(overdue: [], today: [], upcoming: [])
        }

        let activeTasks = tasks.filter { !$0.status.isCompleted }

        let overdue = sort(activeTasks.filter { $0.dueDate < startOfToday })
        let today = sort(activeTasks.filter { $0.dueDate >= startOfToday && $0.dueDate < startOfTomorrow })
        let upcoming = sort(activeTasks.filter { $0.dueDate >= startOfTomorrow && $0.dueDate < endOfUpcomingWindow })

        return TriageBucket(overdue: overdue, today: today, upcoming: upcoming)
    }

    private func sort(_ tasks: [AssignmentTask]) -> [AssignmentTask] {
        tasks.sorted {
            if $0.dueDate != $1.dueDate {
                return $0.dueDate < $1.dueDate
            }
            if $0.priority.rawValue != $1.priority.rawValue {
                return $0.priority.rawValue > $1.priority.rawValue
            }
            if $0.estimatedMinutes != $1.estimatedMinutes {
                return $0.estimatedMinutes > $1.estimatedMinutes
            }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }
}
