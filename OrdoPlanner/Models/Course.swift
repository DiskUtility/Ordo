import Foundation
import SwiftData

@Model
final class Course {
    @Attribute(.unique) var id: UUID
    var name: String
    var code: String
    var colorHex: String
    var studentLevel: StudentLevel
    var meetingDaysBitmask: Int
    var startTime: Date
    var endTime: Date
    var location: String
    var termID: UUID?

    var term: AcademicTerm?

    var tasks: [AssignmentTask]

    init(
        id: UUID = UUID(),
        name: String,
        code: String = "",
        colorHex: String = "#2B66C0",
        studentLevel: StudentLevel,
        meetingDaysBitmask: Int = 0,
        startTime: Date,
        endTime: Date,
        location: String = "",
        term: AcademicTerm? = nil,
        tasks: [AssignmentTask] = []
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.colorHex = colorHex
        self.studentLevel = studentLevel
        self.meetingDaysBitmask = meetingDaysBitmask
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.term = term
        self.termID = term?.id
        self.tasks = tasks
    }
}
