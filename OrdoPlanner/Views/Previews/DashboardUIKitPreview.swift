import SwiftData
import SwiftUI
import UIKit

#if DEBUG
private struct DashboardUIKitPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        DashboardViewController(modelContainer: Self.previewContainer, services: AppServices())
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private static var previewContainer: ModelContainer = {
        let schema = Schema([StudentProfile.self, AcademicTerm.self, Course.self, AssignmentTask.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let profile = StudentProfile(displayName: "Avery", studentLevel: .college, defaultReminderLeadHours: 24)
        let term = AcademicTerm(name: "Spring Term", startDate: .now, endDate: Calendar.current.date(byAdding: .month, value: 4, to: .now) ?? .now, isActive: true)
        let course = Course(
            name: "Calculus",
            code: "MATH-101",
            colorHex: "#2B66C0",
            studentLevel: .college,
            meetingDaysBitmask: WeekdayBitmask.toggle(.monday, in: 0),
            startTime: .now,
            endTime: Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now,
            location: "Room 201",
            term: term
        )
        let task = AssignmentTask(
            title: "Problem Set 3",
            notes: "",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
            estimatedMinutes: 90,
            priority: .high,
            status: .notStarted,
            course: course
        )

        context.insert(profile)
        context.insert(term)
        context.insert(course)
        context.insert(task)
        try? context.save()
        return container
    }()
}

#Preview("Dashboard UIKit") {
    DashboardUIKitPreview()
}
#endif
