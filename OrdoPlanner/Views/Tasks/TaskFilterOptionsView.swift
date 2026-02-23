//
//  TaskFilterOptionsView.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftUI

struct TaskFilterOptionsView: View {
    @Binding var statusFilter: TasksViewModel.StatusFilter
    @Binding var selectedCourseID: UUID?
    @Binding var sortOption: TasksViewModel.SortOption
    @Binding var focusModeEnabled: Bool

    let courses: [Course]
    let onReset: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Status", selection: $statusFilter) {
                        ForEach(TasksViewModel.StatusFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Course") {
                    Button {
                        selectedCourseID = nil
                    } label: {
                        HStack {
                            Text("All courses")
                            Spacer()
                            if selectedCourseID == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }

                    ForEach(courses) { course in
                        Button {
                            selectedCourseID = course.id
                        } label: {
                            HStack {
                                Text(course.name)
                                Spacer()
                                if selectedCourseID == course.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }

                Section("Sort") {
                    Picker("Sort by", selection: $sortOption) {
                        ForEach(TasksViewModel.SortOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Focus") {
                    Toggle("Only next 48h", isOn: $focusModeEnabled)
                }

                Section {
                    Button("Reset Filters") {
                        onReset()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
