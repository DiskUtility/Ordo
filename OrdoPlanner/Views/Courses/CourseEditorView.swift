import SwiftUI

struct CourseEditorView: View {
    struct Draft {
        var name: String = ""
        var code: String = ""
        var colorHex: String = "#2B66C0"
        var studentLevel: StudentLevel = .college
        var meetingDaysBitmask: Int = 0
        var startTime: Date = Date()
        var endTime: Date = Calendar.current.date(byAdding: .minute, value: 60, to: Date()) ?? Date()
        var location: String = ""
    }

    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var draft: Draft
    let onSave: () -> Void

    private let colorChoices = ["#2B66C0", "#198754", "#C35A16", "#7D4AB5", "#A1283A"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Course") {
                    TextField("Name", text: $draft.name)
                        .accessibilityIdentifier(AccessibilityID.Courses.editorNameField)
                    TextField("Code", text: $draft.code)
                    TextField("Location", text: $draft.location)

                    Picker("Student level", selection: $draft.studentLevel) {
                        ForEach(StudentLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Start time", selection: $draft.startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End time", selection: $draft.endTime, displayedComponents: .hourAndMinute)

                    HStack {
                        ForEach(Weekday.allCases) { day in
                            let selected = WeekdayBitmask.contains(day, in: draft.meetingDaysBitmask)
                            Button(day.shortLabel) {
                                draft.meetingDaysBitmask = WeekdayBitmask.toggle(day, in: draft.meetingDaysBitmask)
                            }
                            .buttonStyle(.bordered)
                            .tint(selected ? AppTheme.accent : .gray)
                        }
                    }
                }

                Section("Color") {
                    HStack {
                        ForEach(colorChoices, id: \.self) { color in
                            Button {
                                draft.colorHex = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 26, height: 26)
                                    .overlay {
                                        if draft.colorHex == color {
                                            Circle().stroke(.white, lineWidth: 2)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier(AccessibilityID.Courses.editorSaveButton)
                }
            }
        }
    }
}
