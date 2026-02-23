import SwiftUI

struct TaskEditorView: View {
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
}
