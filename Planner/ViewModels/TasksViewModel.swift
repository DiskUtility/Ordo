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

    @Published var statusFilter: StatusFilter = .all
    @Published var selectedCourseID: UUID?
    @Published var showingEditor = false
    @Published var editingTask: AssignmentTask?

    func filteredTasks(_ tasks: [AssignmentTask]) -> [AssignmentTask] {
        tasks.filter { task in
            if let selectedCourseID, task.courseID != selectedCourseID {
                return false
            }
            switch statusFilter {
            case .all:
                return true
            case .active:
                return !task.status.isCompleted
            case .completed:
                return task.status.isCompleted
            }
        }
    }

    func startCreating() {
        editingTask = nil
        showingEditor = true
    }

    func startEditing(_ task: AssignmentTask) {
        editingTask = task
        showingEditor = true
    }
}
