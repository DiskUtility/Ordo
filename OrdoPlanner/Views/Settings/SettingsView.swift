//
//  SettingsView.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    private struct MockCourseTemplate {
        let name: String
        let code: String
        let colorHex: String
        let days: [Weekday]
        let startHour: Int
        let startMinute: Int
        let durationMinutes: Int
        let location: String
    }

    private static let mockTaskTag = "[MOCK]"
    private static let mockCodePrefix = "MOCK-"

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var services: AppServices

    @Query(sort: \StudentProfile.createdAt) private var profiles: [StudentProfile]
    @Query private var terms: [AcademicTerm]
    @Query private var courses: [Course]
    @Query private var tasks: [AssignmentTask]

    @StateObject private var viewModel = SettingsViewModel()
    @State private var fallbackDisplayName: String = AppPreferences.fallbackDisplayName
    @AppStorage(AppPreferences.compactCardsEnabledKey) private var compactCardsEnabled = false
    @AppStorage(AppPreferences.showCourseCodesKey) private var showCourseCodes = true
    @AppStorage(AppPreferences.showTaskNotesPreviewKey) private var showTaskNotesPreview = true
    @AppStorage(AppPreferences.useVibrantCourseCardsKey) private var useVibrantCourseCards = true
    @AppStorage(AppPreferences.showGreetingNudgesKey) private var showGreetingNudges = true
    @AppStorage(AppPreferences.dashboardTaskPreviewCountKey) private var dashboardTaskPreviewCount = 3

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profiles.first {
                    Section("Student") {
                        TextField("Display name", text: displayNameBinding(profile))
                        Picker("Student level", selection: profileBinding(profile, keyPath: \.studentLevel)) {
                            ForEach(StudentLevel.allCases) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                    }

                    Section("Reminders") {
                        Stepper(value: profileBinding(profile, keyPath: \.defaultReminderLeadHours), in: 1...72) {
                            Text("Default lead time: \(profile.defaultReminderLeadHours) hours")
                        }
                    }
                } else {
                    Section("Student") {
                        // Keeps greeting personalization available when no profile exists.
                        TextField("Display name", text: fallbackDisplayNameBinding)
                        Text("Name is remembered and shown on Today.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Display") {
                    Toggle("Compact cards", isOn: $compactCardsEnabled)
                    Toggle("Show course codes", isOn: $showCourseCodes)
                    Toggle("Show task notes preview", isOn: $showTaskNotesPreview)

                    Button("Reset display preferences") {
                        compactCardsEnabled = false
                        showCourseCodes = true
                        showTaskNotesPreview = true
                    }
                }

                Section("Today Screen") {
                    Toggle("Vibrant course cards", isOn: $useVibrantCourseCards)
                    Toggle("Show greeting nudge", isOn: $showGreetingNudges)
                    Stepper(value: $dashboardTaskPreviewCount, in: 1...6) {
                        Text("Upcoming preview count: \(dashboardTaskPreviewCount)")
                    }
                }

                Section("Tasks") {
                    Button(role: .destructive) {
                        clearCompletedTasks()
                    } label: {
                        Text("Clear Completed Tasks (\(completedTaskCount))")
                    }
                    .disabled(completedTaskCount == 0)
                }

                Section("Data Summary") {
                    LabeledContent("Active term", value: activeTermName)
                    LabeledContent("Courses", value: "\(courses.count)")
                    LabeledContent("Tasks", value: "\(tasks.count)")
                    LabeledContent("Completed", value: "\(completedTaskCount)")
                }

                Section("About") {
                    Text("Ordo: Planner")
                    Text("Local-first student planner for classes, tasks, and reminders.")
                        .foregroundStyle(.secondary)
                }

                #if DEBUG
                Section("Debug") {
                    Button("Add Mock Data") {
                        addMockData()
                    }

                    Button(role: .destructive) {
                        removeMockData()
                    } label: {
                        Text("Remove Mock Data")
                    }

                    Button(role: .destructive) {
                        viewModel.showingResetAlert = true
                    } label: {
                        Text("Reset Local Data")
                    }
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.screenBackground)
            .navigationTitle("Settings")
            .alert("Reset all local data?", isPresented: $viewModel.showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetData()
                }
            } message: {
                Text("This removes profiles, terms, courses, and tasks from this device.")
            }
            .onAppear {
                if let profile = profiles.first {
                    // Mirror profile name into fallback storage so both app modes stay in sync.
                    let clean = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                    AppPreferences.fallbackDisplayName = clean
                    fallbackDisplayName = clean
                }
            }
        }
    }

    private func profileBinding<Value>(_ profile: StudentProfile, keyPath: ReferenceWritableKeyPath<StudentProfile, Value>) -> Binding<Value> {
        Binding(
            get: { profile[keyPath: keyPath] },
            set: { newValue in
                profile[keyPath: keyPath] = newValue
                try? modelContext.save()
            }
        )
    }

    private func displayNameBinding(_ profile: StudentProfile) -> Binding<String> {
        Binding(
            get: { profile.displayName },
            set: { newValue in
                profile.displayName = newValue
                // Update fallback name too so dashboard greeting still works without profile later.
                let clean = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                AppPreferences.fallbackDisplayName = clean
                fallbackDisplayName = clean
                try? modelContext.save()
            }
        )
    }

    private var fallbackDisplayNameBinding: Binding<String> {
        Binding(
            get: { fallbackDisplayName },
            set: { newValue in
                fallbackDisplayName = newValue
                // Persist immediately for root modes that bypass onboarding/profile creation.
                AppPreferences.fallbackDisplayName = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        )
    }

    private func resetData() {
        for task in tasks {
            modelContext.delete(task)
        }
        for course in courses {
            modelContext.delete(course)
        }
        for term in terms {
            modelContext.delete(term)
        }
        for profile in profiles {
            modelContext.delete(profile)
        }
        try? modelContext.save()
    }

    private var completedTaskCount: Int {
        tasks.filter { $0.status.isCompleted }.count
    }

    private var activeTermName: String {
        terms.first(where: { $0.isActive })?.name ?? "None"
    }

    private func clearCompletedTasks() {
        for task in tasks where task.status.isCompleted {
            Task {
                await services.notificationScheduler.cancel(taskID: task.id)
            }
            modelContext.delete(task)
        }
        try? modelContext.save()
    }

    private func addMockData() {
        let activeTerm = ensureActiveTerm()
        ensureProfileIfNeeded()

        let templates: [MockCourseTemplate] = [
            .init(name: "Physics", code: "\(Self.mockCodePrefix)PHY101", colorHex: "#C35A16", days: [.monday, .wednesday], startHour: 8, startMinute: 10, durationMinutes: 60, location: "A-104"),
            .init(name: "Algebra II", code: "\(Self.mockCodePrefix)MTH210", colorHex: "#2B66C0", days: [.tuesday, .thursday], startHour: 9, startMinute: 20, durationMinutes: 75, location: "B-212"),
            .init(name: "English Lit", code: "\(Self.mockCodePrefix)ENG115", colorHex: "#7D4AB5", days: [.friday], startHour: 10, startMinute: 0, durationMinutes: 60, location: "Library")
        ]

        var insertedCourses: [Course] = []

        for template in templates where !courses.contains(where: { $0.code == template.code }) {
            let start = dateToday(hour: template.startHour, minute: template.startMinute)
            let end = Calendar.current.date(byAdding: .minute, value: template.durationMinutes, to: start) ?? start

            let course = Course(
                name: template.name,
                code: template.code,
                colorHex: template.colorHex,
                studentLevel: profiles.first?.studentLevel ?? .college,
                meetingDaysBitmask: bitmask(for: template.days),
                startTime: start,
                endTime: end,
                location: template.location,
                term: activeTerm
            )
            course.termID = activeTerm.id
            modelContext.insert(course)
            insertedCourses.append(course)
        }

        for course in insertedCourses {
            let task = AssignmentTask(
                title: "Review \(course.name) notes",
                notes: "\(Self.mockTaskTag) Generated from Debug settings.",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                estimatedMinutes: 40,
                priority: .medium,
                status: .notStarted,
                course: course
            )
            task.courseID = course.id
            modelContext.insert(task)
        }

        try? modelContext.save()
    }

    private func removeMockData() {
        let mockCourses = courses.filter { $0.code.hasPrefix(Self.mockCodePrefix) }
        let mockCourseIDs = Set(mockCourses.map(\.id))

        for task in tasks {
            let linkedToMockCourse = task.courseID.map { mockCourseIDs.contains($0) } ?? false
            let taggedMockTask = task.notes.contains(Self.mockTaskTag)
            if linkedToMockCourse || taggedMockTask {
                modelContext.delete(task)
            }
        }

        for course in mockCourses {
            modelContext.delete(course)
        }

        try? modelContext.save()
    }

    @discardableResult
    private func ensureActiveTerm() -> AcademicTerm {
        if let active = terms.first(where: { $0.isActive }) {
            return active
        }

        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .month, value: 4, to: startDate) ?? startDate
        let term = AcademicTerm(name: "Current Term", startDate: startDate, endDate: endDate, isActive: true)
        modelContext.insert(term)
        return term
    }

    private func ensureProfileIfNeeded() {
        guard profiles.first == nil else { return }

        let fallbackName = AppPreferences.fallbackDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = fallbackName.isEmpty ? "Student" : fallbackName
        let profile = StudentProfile(displayName: displayName, studentLevel: .college, defaultReminderLeadHours: 24)
        modelContext.insert(profile)
    }

    private func dateToday(hour: Int, minute: Int) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func bitmask(for days: [Weekday]) -> Int {
        days.reduce(into: 0) { mask, day in
            mask = WeekdayBitmask.toggle(day, in: mask)
        }
    }
}
