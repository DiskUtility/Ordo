import Foundation
import UserNotifications

enum NotificationSchedulingError: Error {
    case schedulingFailed
}

@MainActor
final class LocalNotificationScheduler: NotificationScheduling {
    private let center: UNUserNotificationCenter
    private let calculator: ReminderDateCalculator
    private let forcedAuthorizationResult: Bool?

    init(
        center: UNUserNotificationCenter? = nil,
        calculator: ReminderDateCalculator,
        forcedAuthorizationResult: Bool? = nil
    ) {
        self.center = center ?? .current()
        self.calculator = calculator
        self.forcedAuthorizationResult = forcedAuthorizationResult
    }

    func requestAuthorization() async -> Bool {
        if let forcedAuthorizationResult {
            return forcedAuthorizationResult
        }

        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func schedule(for task: AssignmentTask, leadHours: Int) async throws {
        guard !task.status.isCompleted else {
            await cancel(taskID: task.id)
            return
        }

        guard let triggerDate = calculator.triggerDate(for: task.dueDate, leadHours: leadHours) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming deadline"
        content.body = "\(task.title) is due at \(task.dueDate.formatted(date: .abbreviated, time: .shortened))."
        content.sound = .default
        content.userInfo = ["taskID": task.id.uuidString]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: Self.taskIdentifier(for: task.id), content: content, trigger: trigger)

        try await addRequest(request)
    }

    func cancel(taskID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.taskIdentifier(for: taskID), Self.snoozeIdentifier(for: taskID)])
        center.removeDeliveredNotifications(withIdentifiers: [Self.taskIdentifier(for: taskID), Self.snoozeIdentifier(for: taskID)])
    }

    func scheduleSnooze(task: AssignmentTask, afterMinutes: Int = 60) async throws {
        guard afterMinutes > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Snoozed reminder"
        content.body = "\(task.title) is still due at \(task.dueDate.formatted(date: .abbreviated, time: .shortened))."
        content.sound = .default
        content.userInfo = ["taskID": task.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(afterMinutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: Self.snoozeIdentifier(for: task.id), content: content, trigger: trigger)

        try await addRequest(request)
    }

    private func addRequest(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private static func taskIdentifier(for id: UUID) -> String {
        "planner.task.\(id.uuidString)"
    }

    private static func snoozeIdentifier(for id: UUID) -> String {
        "planner.task.snooze.\(id.uuidString)"
    }
}
