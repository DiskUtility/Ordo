import Foundation
import Testing
@testable import Planner

struct ModelValidationTests {
    @Test
    func taskTitleValidationRejectsWhitespaceOnly() {
        let task = AssignmentTask(title: "   ", dueDate: Date())
        #expect(task.isTitleValid == false)
    }

    @Test
    func termDateValidationRequiresStartBeforeOrEqualEnd() {
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 2_000)
        let validTerm = AcademicTerm(name: "Term", startDate: start, endDate: end, isActive: true)
        let invalidTerm = AcademicTerm(name: "Term", startDate: end, endDate: start, isActive: true)

        #expect(validTerm.isDateRangeValid)
        #expect(invalidTerm.isDateRangeValid == false)
    }
}
