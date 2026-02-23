import Foundation
import SwiftData

@Model
final class AcademicTerm {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var isActive: Bool

    var courses: [Course]

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        isActive: Bool,
        courses: [Course] = []
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.courses = courses
    }

    var isDateRangeValid: Bool {
        startDate <= endDate
    }
}
