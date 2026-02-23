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
    @State private var isFilterEnabled = false
    @State private var isShowingFilterSheet = false
    @AppStorage(AppPreferences.compactCardsEnabledKey) private var compactCardsEnabled = false
    @AppStorage(AppPreferences.showCourseCodesKey) private var showCourseCodes = true
    @AppStorage(AppPreferences.showTaskNotesPreviewKey) private var showTaskNotesPreview = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    tasksFilterHeader

                    if filteredTasks.isEmpty {
                        ContentUnavailableView(
                            "No Tasks",
                            systemImage: viewModel.searchText.isEmpty ? "checklist" : "magnifyingglass",
                            description: Text(emptyStateDescription)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 36)
                    } else {
                        LazyVStack(spacing: compactCardsEnabled ? 10 : 12) {
                            ForEach(filteredTasks) { task in
                                assignmentCard(task)
                                    .onTapGesture {
                                        startEditing(task)
                                    }
                                    .contextMenu {
                                        contextMenuItems(for: task)
                                    }
                            }
                        }
                    }
                }
                .padding(AppTheme.screenPadding)
            }
            .background(AppTheme.screenBackground)
            .navigationTitle("Tasks")
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search tasks or courses")
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
            .onAppear {
                viewModel.syncSelectedCourse(with: courses)
            }
            .onReceive(NotificationCenter.default.publisher(for: .tasksAccessoryOpenFilters)) { _ in
                isFilterEnabled = true
                isShowingFilterSheet = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .tasksAccessoryAddTask)) { _ in
                startCreating()
            }
        }
    }

    private var tasksFilterHeader: some View {
        HStack {
            FilterToggleButton(
                isFilterEnabled: $isFilterEnabled,
                isShowingSheet: $isShowingFilterSheet,
                filteredByText: filteredByText
            ) {
                TaskFilterOptionsView(
                    statusFilter: $viewModel.statusFilter,
                    selectedCourseID: $viewModel.selectedCourseID,
                    sortOption: $viewModel.sortOption,
                    focusModeEnabled: $viewModel.focusModeEnabled,
                    courses: courses,
                    onReset: { viewModel.resetFilters() }
                )
            }
            Spacer()
        }
    }

    private var filteredTasks: [AssignmentTask] {
        viewModel.filteredTasks(tasks, includeAdvancedFilters: isFilterEnabled)
    }

    private var filteredByText: String {
        var labels: [String] = []
        if viewModel.statusFilter != .all { labels.append(viewModel.statusFilter.title) }
        if let selectedCourseID = viewModel.selectedCourseID,
           let courseName = courses.first(where: { $0.id == selectedCourseID })?.name {
            labels.append(courseName)
        }
        if viewModel.focusModeEnabled { labels.append("Focus") }
        if viewModel.sortOption != .dueSoonest { labels.append(viewModel.sortOption.title) }
        return labels.isEmpty ? "All tasks" : labels.joined(separator: ", ")
    }

    private var emptyStateDescription: String {
        if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No tasks match your search."
        }
        if viewModel.focusModeEnabled {
            return "No active tasks due in the next 48 hours."
        }
        return "Try another filter or add a new task."
    }

    private func assignmentCard(_ task: AssignmentTask) -> some View {
        let cardPadding = compactCardsEnabled ? 12.0 : AppTheme.cardPadding
        let cornerRadius = compactCardsEnabled ? 18.0 : AppTheme.cardCornerRadius

        return VStack(alignment: .leading, spacing: compactCardsEnabled ? 10 : 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title)
                        .font(.system(size: compactCardsEnabled ? 19 : 22, weight: .semibold, design: .rounded))

                    Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.monospacedDigit().weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(taskDuePillText(task))
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 9)
                        .background(duePillColor(task).opacity(0.16))
                        .clipShape(Capsule())
                        .foregroundStyle(duePillColor(task))

                    Text(task.priority.displayName)
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 5)
                        .padding(.horizontal, 9)
                        .background(priorityChipColor(task.priority).opacity(0.16))
                        .clipShape(Capsule())
                        .foregroundStyle(priorityChipColor(task.priority))
                }
            }

            taskMetaRow(task)

            if showTaskNotesPreview {
                let trimmedNotes = task.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNotes.isEmpty {
                    Text(trimmedNotes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(compactCardsEnabled ? 2 : 3)
                }
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

                Menu {
                    ForEach(TaskStatus.allCases) { status in
                        Button {
                            Task { await setStatus(task, to: status) }
                        } label: {
                            HStack {
                                Text(status.displayName)
                                if task.status == status {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Button {
                        Task { await deferTaskOneDay(task) }
                    } label: {
                        Label("Defer 1 Day", systemImage: "calendar.badge.plus")
                    }

                    Button {
                        duplicateTask(task)
                    } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }

                    Button(role: .destructive) {
                        deleteTask(task)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
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

    @ViewBuilder
    private func taskMetaRow(_ task: AssignmentTask) -> some View {
        HStack(spacing: 8) {
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
    }

    @ViewBuilder
    private func contextMenuItems(for task: AssignmentTask) -> some View {
        Button {
            Task { await deferTaskOneDay(task) }
        } label: {
            Label("Defer 1 Day", systemImage: "calendar.badge.plus")
        }

        Button {
            duplicateTask(task)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }

        Button(role: .destructive) {
            deleteTask(task)
        } label: {
            Label("Delete", systemImage: "trash")
        }
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

    private func taskDuePillText(_ task: AssignmentTask) -> String {
        let calendar = Calendar.current
        if task.status.isCompleted { return "Done" }
        if task.dueDate < Date() { return "Overdue" }
        if calendar.isDateInToday(task.dueDate) { return "Today" }
        if calendar.isDateInTomorrow(task.dueDate) { return "Tomorrow" }
        return task.dueDate.formatted(.dateTime.weekday(.abbreviated))
    }

    private func duePillColor(_ task: AssignmentTask) -> Color {
        if task.status.isCompleted { return AppTheme.success }
        if task.dueDate < Date() { return .red }
        if Calendar.current.isDateInToday(task.dueDate) { return AppTheme.accent }
        return .secondary
    }

    private func startCreating() {
        var newDraft = TaskEditorView.Draft(selectedCourseID: courses.first?.id)
        newDraft.dueDate = recommendedNewTaskDueDate()
        draft = newDraft
        viewModel.startCreating()
    }

    private func recommendedNewTaskDueDate() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        if hour < 20 {
            return now.addingTimeInterval(4 * 3600)
        }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 9
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? tomorrow
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

    private func duplicateTask(_ task: AssignmentTask) {
        let duplicated = AssignmentTask(
            title: task.title,
            notes: task.notes,
            dueDate: task.dueDate,
            estimatedMinutes: task.estimatedMinutes,
            priority: task.priority,
            status: .notStarted,
            course: task.course,
            completedAt: nil
        )
        duplicated.courseID = task.courseID
        modelContext.insert(duplicated)

        let reminderLeadHours = profiles.first?.defaultReminderLeadHours ?? 24
        Task {
            try? await services.notificationScheduler.schedule(for: duplicated, leadHours: reminderLeadHours)
        }

        try? modelContext.save()
    }

    private func deferTaskOneDay(_ task: AssignmentTask) async {
        task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: task.dueDate) ?? task.dueDate

        if !task.status.isCompleted {
            let reminderLeadHours = profiles.first?.defaultReminderLeadHours ?? 24
            try? await services.notificationScheduler.schedule(for: task, leadHours: reminderLeadHours)
        }

        try? modelContext.save()
    }

    private func setStatus(_ task: AssignmentTask, to status: TaskStatus) async {
        task.status = status
        task.completedAt = status.isCompleted ? Date() : nil

        if status.isCompleted {
            await services.notificationScheduler.cancel(taskID: task.id)
        } else {
            let reminderLeadHours = profiles.first?.defaultReminderLeadHours ?? 24
            try? await services.notificationScheduler.schedule(for: task, leadHours: reminderLeadHours)
        }

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
