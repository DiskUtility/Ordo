import Foundation
import Combine
import SwiftUI

@MainActor
final class TasksViewModel: ObservableObject {
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all
        case active
        case completed

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return "All"
            case .active:
                return "Active"
            case .completed:
                return "Completed"
            }
        }
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case dueSoonest
        case dueLatest
        case priorityHigh
        case recentlyCreated

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dueSoonest:
                return "Due Soonest"
            case .dueLatest:
                return "Due Latest"
            case .priorityHigh:
                return "Priority"
            case .recentlyCreated:
                return "Recently Added"
            }
        }
    }

    // Persist user filter choices so the task list feels consistent between launches.
    @Published var statusFilter: StatusFilter = .all {
        didSet { UserDefaults.standard.set(statusFilter.rawValue, forKey: AppPreferences.tasksStatusFilterKey) }
    }

    // Keep the selected course filter stable unless the course is deleted.
    @Published var selectedCourseID: UUID? {
        didSet {
            if let selectedCourseID {
                UserDefaults.standard.set(selectedCourseID.uuidString, forKey: AppPreferences.tasksSelectedCourseIDKey)
            } else {
                UserDefaults.standard.removeObject(forKey: AppPreferences.tasksSelectedCourseIDKey)
            }
        }
    }

    @Published var sortOption: SortOption = .dueSoonest {
        didSet { UserDefaults.standard.set(sortOption.rawValue, forKey: AppPreferences.tasksSortOptionKey) }
    }

    @Published var searchText = ""

    // Focus mode narrows to urgent active work in the next 48 hours.
    @Published var focusModeEnabled = false {
        didSet { UserDefaults.standard.set(focusModeEnabled, forKey: AppPreferences.tasksFocusModeEnabledKey) }
    }

    @Published var showingEditor = false
    @Published var editingTask: AssignmentTask?

    init() {
        if let storedStatus = UserDefaults.standard.string(forKey: AppPreferences.tasksStatusFilterKey),
           let status = StatusFilter(rawValue: storedStatus) {
            statusFilter = status
        }

        if let storedSort = UserDefaults.standard.string(forKey: AppPreferences.tasksSortOptionKey),
           let sort = SortOption(rawValue: storedSort) {
            sortOption = sort
        }

        if UserDefaults.standard.object(forKey: AppPreferences.tasksFocusModeEnabledKey) != nil {
            focusModeEnabled = UserDefaults.standard.bool(forKey: AppPreferences.tasksFocusModeEnabledKey)
        }

        if let rawID = UserDefaults.standard.string(forKey: AppPreferences.tasksSelectedCourseIDKey),
           let uuid = UUID(uuidString: rawID) {
            selectedCourseID = uuid
        }
    }

    func syncSelectedCourse(with courses: [Course]) {
        guard let selectedCourseID else { return }
        guard courses.contains(where: { $0.id == selectedCourseID }) else {
            self.selectedCourseID = nil
            return
        }
    }

    func resetFilters() {
        statusFilter = .all
        selectedCourseID = nil
        sortOption = .dueSoonest
        searchText = ""
        focusModeEnabled = false
    }

    func filteredTasks(
        _ tasks: [AssignmentTask],
        now: Date = Date(),
        includeAdvancedFilters: Bool = true
    ) -> [AssignmentTask] {
        let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return tasks
            .filter { task in
                if includeAdvancedFilters {
                    if let selectedCourseID, task.courseID != selectedCourseID {
                        return false
                    }

                    switch statusFilter {
                    case .all:
                        break
                    case .active:
                        if task.status.isCompleted { return false }
                    case .completed:
                        if !task.status.isCompleted { return false }
                    }

                    if focusModeEnabled {
                        let focusCutoff = now.addingTimeInterval(48 * 3600)
                        if task.status.isCompleted || task.dueDate > focusCutoff {
                            return false
                        }
                    }
                }

                if normalizedQuery.isEmpty {
                    return true
                }

                // Search title, notes, and course metadata in one normalized string.
                let haystack = [
                    task.title,
                    task.notes,
                    task.course?.name ?? "",
                    task.course?.code ?? ""
                ]
                    .joined(separator: " ")
                    .lowercased()

                return haystack.contains(normalizedQuery)
            }
            .sorted(by: sortComparator)
    }

    func startCreating() {
        editingTask = nil
        showingEditor = true
    }

    func startEditing(_ task: AssignmentTask) {
        editingTask = task
        showingEditor = true
    }

    private func sortComparator(lhs: AssignmentTask, rhs: AssignmentTask) -> Bool {
        switch sortOption {
        case .dueSoonest:
            if lhs.dueDate != rhs.dueDate { return lhs.dueDate < rhs.dueDate }
            return lhs.priority.rawValue > rhs.priority.rawValue
        case .dueLatest:
            if lhs.dueDate != rhs.dueDate { return lhs.dueDate > rhs.dueDate }
            return lhs.priority.rawValue > rhs.priority.rawValue
        case .priorityHigh:
            if lhs.priority.rawValue != rhs.priority.rawValue { return lhs.priority.rawValue > rhs.priority.rawValue }
            return lhs.dueDate < rhs.dueDate
        case .recentlyCreated:
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            return lhs.dueDate < rhs.dueDate
        }
    }
}
