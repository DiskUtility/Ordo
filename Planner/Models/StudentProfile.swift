import Foundation
import SwiftData

@Model
final class StudentProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var studentLevel: StudentLevel
    var defaultReminderLeadHours: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        displayName: String = "",
        studentLevel: StudentLevel,
        defaultReminderLeadHours: Int = 24,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.studentLevel = studentLevel
        self.defaultReminderLeadHours = defaultReminderLeadHours
        self.createdAt = createdAt
    }
}
