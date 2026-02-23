import SwiftUI

struct TaskEditorView: View {
    private enum DuePreset: String, CaseIterable, Identifiable {
        case fourHours = "In 4h"
        case tonight = "Tonight"
        case tomorrowMorning = "Tomorrow"
        case nextWeek = "Next Week"

        var id: String { rawValue }
    }

    struct Draft {
        var title: String = ""
        var notes: String = ""
        var dueDate: Date = Date().addingTimeInterval(3600)
        var estimatedMinutes: Int = 60
        var priority: PriorityLevel = .medium
        var status: TaskStatus = .notStarted
        var selectedCourseID: UUID?
    }

    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var draft: Draft
    let courses: [Course]
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $draft.title)
                        .accessibilityIdentifier(AccessibilityID.Tasks.editorTitleField)
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Schedule") {
                    DatePicker("Due", selection: $draft.dueDate)

                    // Quick presets reduce repeated date-picker interaction.
                    duePresetsRow

                    Stepper("Estimated time: \(draft.estimatedMinutes) min", value: $draft.estimatedMinutes, in: 15...600, step: 15)
                }

                Section("Status") {
                    Picker("Priority", selection: $draft.priority) {
                        ForEach(PriorityLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                    Picker("Progress", selection: $draft.status) {
                        ForEach(TaskStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }

                    Picker("Course", selection: $draft.selectedCourseID) {
                        Text("No course").tag(Optional<UUID>.none)
                        ForEach(courses) { course in
                            Text(course.name).tag(Optional(course.id))
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier(AccessibilityID.Tasks.editorSaveButton)
                }
            }
        }
        .onAppear {
            if draft.selectedCourseID == nil {
                draft.selectedCourseID = courses.first?.id
            }
        }
    }

    private var duePresetsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick picks")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DuePreset.allCases) { preset in
                        Button {
                            apply(preset)
                        } label: {
                            Text(preset.rawValue)
                                .font(.footnote.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(AppTheme.accent.opacity(0.12))
                                .foregroundStyle(AppTheme.accent)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func apply(_ preset: DuePreset) {
        let calendar = Calendar.current
        let now = Date()

        switch preset {
        case .fourHours:
            draft.dueDate = now.addingTimeInterval(4 * 3600)
        case .tonight:
            draft.dueDate = date(hour: 21, minute: 0, from: now, calendar: calendar)
            // If "Tonight" has already passed, use tomorrow morning instead.
            if draft.dueDate <= now {
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
                draft.dueDate = date(hour: 9, minute: 0, from: tomorrow, calendar: calendar)
            }
        case .tomorrowMorning:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            draft.dueDate = date(hour: 8, minute: 0, from: tomorrow, calendar: calendar)
        case .nextWeek:
            let base = calendar.date(byAdding: .day, value: 7, to: now) ?? now
            draft.dueDate = date(hour: 17, minute: 0, from: base, calendar: calendar)
        }
    }

    private func date(hour: Int, minute: Int, from base: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: base)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? base
    }
}
