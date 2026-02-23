import Foundation
import SwiftData

@Model
final class AssignmentTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var estimatedMinutes: Int
    var priority: PriorityLevel
    var status: TaskStatus
    var courseID: UUID?
    var createdAt: Date
    var completedAt: Date?

    var course: Course?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date,
        estimatedMinutes: Int = 60,
        priority: PriorityLevel = .medium,
        status: TaskStatus = .notStarted,
        course: Course? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.estimatedMinutes = estimatedMinutes
        self.priority = priority
        self.status = status
        self.course = course
        self.courseID = course?.id
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var isTitleValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isCompleted: Bool {
        status.isCompleted
    }
}
