import Foundation
import Combine
import SwiftData
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome
        case profile
        case term
        case course
        case preferences
    }

    @Published var step: Step = .welcome

    @Published var displayName: String = ""
    @Published var studentLevel: StudentLevel = .college

    @Published var termName: String = "Spring Term"
    @Published var termStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @Published var termEndDate: Date = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()

    @Published var addInitialCourse: Bool = false
    @Published var courseName: String = ""
    @Published var courseCode: String = ""
    @Published var courseLocation: String = ""
    @Published var courseColorHex: String = "#2B66C0"
    @Published var courseMeetingDaysBitmask: Int = 0
    @Published var courseStartTime: Date = Date()
    @Published var courseEndTime: Date = Calendar.current.date(byAdding: .minute, value: 60, to: Date()) ?? Date()
    @Published var defaultReminderLeadHours: Int = 24
    @Published var isSemesterModeEnabled: Bool = false
    @Published var semesterBreakWeeks: Int = 2

    var supportsSemesterSplitOption: Bool {
        studentLevel == .highSchool
    }

    var setupDescription: String {
        if !isSemesterModeEnabled {
            return "One active term"
        }
        return "Creates Semester 1 + Semester 2 (6 months each) with a \(semesterBreakWeeks)-week break"
    }

    var canContinue: Bool {
        switch step {
        case .welcome:
            return true
        case .profile:
            return true
        case .term:
            let hasName = !termName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if !isSemesterModeEnabled {
                return hasName && termStartDate <= termEndDate
            }
            return hasName
        case .course:
            if !addInitialCourse {
                return true
            }
            return !courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .preferences:
            return true
        }
    }

    var isFirstStep: Bool {
        step == .welcome
    }

    var isLastStep: Bool {
        step == .preferences
    }

    func goForward() {
        guard canContinue else { return }
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    func goBack() {
        if let previous = Step(rawValue: step.rawValue - 1) {
            step = previous
        }
    }

    func enforceCompatibleSetup() {
        if studentLevel != .highSchool {
            isSemesterModeEnabled = false
        }
    }

    func syncDatesForSelectedSetup() {
        let calendar = Calendar.current
        if !isSemesterModeEnabled {
            if termStartDate > termEndDate {
                termEndDate = calendar.date(byAdding: .month, value: 4, to: termStartDate) ?? termStartDate
            }
            return
        }

        let firstSemesterEnd = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: 6, to: termStartDate) ?? termStartDate) ?? termStartDate
        let semester2Start = calendar.date(byAdding: .day, value: semesterBreakWeeks * 7 + 1, to: firstSemesterEnd) ?? firstSemesterEnd
        let semester2EndCandidate = calendar.date(byAdding: .month, value: 6, to: semester2Start) ?? semester2Start
        termEndDate = calendar.date(byAdding: .day, value: -1, to: semester2EndCandidate) ?? semester2EndCandidate
    }

    func completeOnboarding(using modelContext: ModelContext) {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = StudentProfile(
            displayName: trimmedName,
            studentLevel: studentLevel,
            defaultReminderLeadHours: defaultReminderLeadHours
        )

        modelContext.insert(profile)

        let terms = buildTerms()
        for term in terms {
            modelContext.insert(term)
        }

        let primaryTerm = terms.first

        if addInitialCourse {
            let trimmedCourseName = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedCourseName.isEmpty {
                let course = Course(
                    name: trimmedCourseName,
                    code: courseCode.trimmingCharacters(in: .whitespacesAndNewlines),
                    colorHex: courseColorHex,
                    studentLevel: studentLevel,
                    meetingDaysBitmask: courseMeetingDaysBitmask,
                    startTime: courseStartTime,
                    endTime: courseEndTime,
                    location: courseLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                    term: primaryTerm
                )
                modelContext.insert(course)
            }
        }

        if (try? modelContext.save()) != nil {
            NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
        }
    }

    func completeOnboardingForSimulatorSkip(using modelContext: ModelContext) {
        if termName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            termName = "Current Term"
        }

        if termStartDate > termEndDate {
            termEndDate = Calendar.current.date(byAdding: .month, value: 4, to: termStartDate) ?? termStartDate
        }

        enforceCompatibleSetup()
        syncDatesForSelectedSetup()
        completeOnboarding(using: modelContext)
    }

    private func buildTerms() -> [AcademicTerm] {
        let cleanName = termName.trimmingCharacters(in: .whitespacesAndNewlines)
        let calendar = Calendar.current

        guard studentLevel == .highSchool, isSemesterModeEnabled else {
            let fallbackName = cleanName.isEmpty ? "Current Term" : cleanName
            let term = AcademicTerm(
                name: fallbackName,
                startDate: termStartDate,
                endDate: termEndDate,
                isActive: true
            )
            return [term]
        }

        let semester1EndCandidate = calendar.date(byAdding: .month, value: 6, to: termStartDate) ?? termStartDate
        let semester1End = calendar.date(byAdding: .day, value: -1, to: semester1EndCandidate) ?? semester1EndCandidate
        let semester2Start = calendar.date(byAdding: .day, value: semesterBreakWeeks * 7 + 1, to: semester1End) ?? semester1End
        let semester2EndCandidate = calendar.date(byAdding: .month, value: 6, to: semester2Start) ?? semester2Start
        let semester2End = calendar.date(byAdding: .day, value: -1, to: semester2EndCandidate) ?? semester2EndCandidate

        let base = cleanName.isEmpty ? "School Year" : cleanName

        let semester1 = AcademicTerm(
            name: "\(base) - Semester 1",
            startDate: termStartDate,
            endDate: semester1End,
            isActive: true
        )
        let semester2 = AcademicTerm(
            name: "\(base) - Semester 2",
            startDate: semester2Start,
            endDate: semester2End,
            isActive: false
        )
        return [semester1, semester2]
    }
}
