//
//  TasksView.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftData
import SwiftUI

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var services: AppServices

    @Query(sort: \AssignmentTask.dueDate) private var tasks: [AssignmentTask]
    @Query(sort: \Course.name) private var courses: [Course]
    @Query(sort: \StudentProfile.createdAt) private var profiles: [StudentProfile]

    @StateObject private var viewModel = TasksViewModel()
    @State private var draft = TaskEditorView.Draft()
    @State private var isFilterExpanded = false
    @AppStorage(AppPreferences.compactCardsEnabledKey) private var compactCardsEnabled = false
    @AppStorage(AppPreferences.showCourseCodesKey) private var showCourseCodes = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    filterToggleSection

                    if filteredTasks.isEmpty {
                        ContentUnavailableView("No Tasks", systemImage: "checklist", description: Text("Try another filter or add a new task."))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 36)
                    } else {
                        ForEach(filteredTasks) { task in
                            assignmentCard(task)
                                .onTapGesture {
                                    startEditing(task)
                                }
                        }
                    }
                }
                .padding(AppTheme.screenPadding)
            }
            .background(AppTheme.screenBackground)
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startCreating()
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                    .accessibilityIdentifier(AccessibilityID.Tasks.addButton)
                }
            }
            .sheet(isPresented: $viewModel.showingEditor) {
                TaskEditorView(
                    title: viewModel.editingTask == nil ? "New Task" : "Edit Task",
                    draft: $draft,
                    courses: courses,
                    onSave: saveTask
                )
            }
        }
    }

    private var filteredTasks: [AssignmentTask] {
        viewModel.filteredTasks(tasks)
    }

    private var hasCustomFilters: Bool {
        viewModel.statusFilter != .all || viewModel.selectedCourseID != nil
    }

    private var filterSummary: String {
        let status = viewModel.statusFilter.title
        let course = courses.first(where: { $0.id == viewModel.selectedCourseID })?.name ?? "All courses"
        return "\(status) • \(course)"
    }

    private var filterToggleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                        isFilterExpanded.toggle()
                    }
                } label: {
                    Label(isFilterExpanded ? "Hide Filters" : "Filters", systemImage: isFilterExpanded ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                if hasCustomFilters {
                    Text(filterSummary)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if isFilterExpanded {
                filterCard
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Status", selection: $viewModel.statusFilter) {
                ForEach(TasksViewModel.StatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Picker("Course", selection: $viewModel.selectedCourseID) {
                Text("All courses").tag(Optional<UUID>.none)
                ForEach(courses) { course in
                    Text(course.name).tag(Optional(course.id))
                }
            }
        }
        .plannerSurfaceCard(cornerRadius: AppTheme.cardCornerRadius)
    }

    private func assignmentCard(_ task: AssignmentTask) -> some View {
        let cardPadding = compactCardsEnabled ? 12.0 : AppTheme.cardPadding
        let cornerRadius = compactCardsEnabled ? 18.0 : AppTheme.cardCornerRadius

        return VStack(alignment: .leading, spacing: compactCardsEnabled ? 10 : 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title)
                        .font(.system(size: compactCardsEnabled ? 20 : 24, weight: .bold, design: .rounded))

                    Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(task.priority.displayName)
                    .font(.footnote.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(priorityChipColor(task.priority).opacity(0.16))
                    .clipShape(Capsule())
                    .foregroundStyle(priorityChipColor(task.priority))
            }

            HStack(spacing: 10) {
                Text(task.status.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(task.status.isCompleted ? AppTheme.success : .secondary)

                if let course = task.course {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(showCourseCodes && !course.code.isEmpty ? "\(course.name) \(course.code)" : course.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: course.colorHex))
                }

                Spacer()

                Text("\(task.estimatedMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    Task { await toggleCompletion(for: task) }
                } label: {
                    Label(task.status.isCompleted ? "Reopen" : "Complete", systemImage: task.status.isCompleted ? "arrow.uturn.backward" : "checkmark.circle.fill")
                        .font((compactCardsEnabled ? Font.footnote : .subheadline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(task.status.isCompleted ? .orange : .green)

                Button(role: .destructive) {
                    deleteTask(task)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font((compactCardsEnabled ? Font.footnote : .subheadline).weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .plannerSurfaceCard(padding: 0, cornerRadius: cornerRadius)
    }

    private func priorityChipColor(_ priority: PriorityLevel) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }

    private func startCreating() {
        draft = TaskEditorView.Draft(selectedCourseID: courses.first?.id)
        viewModel.startCreating()
    }

    private func startEditing(_ task: AssignmentTask) {
        draft = TaskEditorView.Draft(
            title: task.title,
            notes: task.notes,
            dueDate: task.dueDate,
            estimatedMinutes: task.estimatedMinutes,
            priority: task.priority,
            status: task.status,
            selectedCourseID: task.courseID
        )
        viewModel.startEditing(task)
    }

    private func saveTask() {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let reminderLeadHours = profiles.first?.defaultReminderLeadHours ?? 24
        let isCreating = viewModel.editingTask == nil

        let selectedCourse = courses.first(where: { $0.id == draft.selectedCourseID })

        if let task = viewModel.editingTask {
            task.title = trimmedTitle
            task.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            task.dueDate = draft.dueDate
            task.estimatedMinutes = draft.estimatedMinutes
            task.priority = draft.priority
            task.status = draft.status
            task.course = selectedCourse
            task.courseID = selectedCourse?.id
            task.completedAt = draft.status.isCompleted ? (task.completedAt ?? Date()) : nil

            Task {
                if task.status.isCompleted {
                    await services.notificationScheduler.cancel(taskID: task.id)
                } else {
                    try? await services.notificationScheduler.schedule(for: task, leadHours: reminderLeadHours)
                }
            }
        } else {
            let newTask = AssignmentTask(
                title: trimmedTitle,
                notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: draft.dueDate,
                estimatedMinutes: draft.estimatedMinutes,
                priority: draft.priority,
                status: draft.status,
                course: selectedCourse,
                completedAt: draft.status.isCompleted ? Date() : nil
            )
            newTask.courseID = selectedCourse?.id
            modelContext.insert(newTask)

            Task {
                if isCreating && tasks.isEmpty {
                    _ = await services.notificationScheduler.requestAuthorization()
                }
                if !newTask.status.isCompleted {
                    try? await services.notificationScheduler.schedule(for: newTask, leadHours: reminderLeadHours)
                }
            }
        }

        try? modelContext.save()
    }

    private func deleteTask(_ task: AssignmentTask) {
        Task {
            await services.notificationScheduler.cancel(taskID: task.id)
        }
        modelContext.delete(task)
        try? modelContext.save()
    }

    private func toggleCompletion(for task: AssignmentTask) async {
        task.status = task.status.isCompleted ? .inProgress : .completed
        task.completedAt = task.status.isCompleted ? Date() : nil

        if task.status.isCompleted {
            await services.notificationScheduler.cancel(taskID: task.id)
        } else {
            let reminderLeadHours = profiles.first?.defaultReminderLeadHours ?? 24
            try? await services.notificationScheduler.schedule(for: task, leadHours: reminderLeadHours)
        }

        try? modelContext.save()
    }
}

private extension TaskEditorView.Draft {
    init(selectedCourseID: UUID?) {
        self.init()
        self.selectedCourseID = selectedCourseID
    }
}
