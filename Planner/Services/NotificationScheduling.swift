import Foundation

@MainActor
protocol NotificationScheduling {
    func requestAuthorization() async -> Bool
    func schedule(for task: AssignmentTask, leadHours: Int) async throws
    func cancel(taskID: UUID) async
}
