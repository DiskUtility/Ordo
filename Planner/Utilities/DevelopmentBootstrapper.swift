import Foundation
import SwiftData

enum DevelopmentBootstrapper {
    @MainActor
    static func bootstrapIfNeeded(modelContext: ModelContext, existingProfiles: [StudentProfile]) {
        guard existingProfiles.isEmpty, LaunchOptions.skipOnboarding else { return }

        let profile = StudentProfile(displayName: "Student", studentLevel: .college, defaultReminderLeadHours: 24)
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .month, value: 4, to: startDate) ?? startDate
        let term = AcademicTerm(name: "Current Term", startDate: startDate, endDate: endDate, isActive: true)

        modelContext.insert(profile)
        modelContext.insert(term)

        if LaunchOptions.seedSampleData {
            let course = Course(
                name: "Orientation 101",
                code: "ORI-101",
                colorHex: "#2B66C0",
                studentLevel: .college,
                meetingDaysBitmask: WeekdayBitmask.toggle(.monday, in: 0),
                startTime: Date(),
                endTime: Calendar.current.date(byAdding: .minute, value: 60, to: Date()) ?? Date(),
                location: "Room A",
                term: term
            )
            course.termID = term.id
            modelContext.insert(course)

            let sampleTask = AssignmentTask(
                title: "Read syllabus",
                notes: "Auto-generated sample task.",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                estimatedMinutes: 45,
                priority: .medium,
                status: .notStarted,
                course: course
            )
            sampleTask.courseID = course.id
            modelContext.insert(sampleTask)
        }

        try? modelContext.save()
    }
}
