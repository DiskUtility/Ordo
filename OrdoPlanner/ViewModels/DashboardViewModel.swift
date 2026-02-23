import Foundation
import Combine
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var showingTaskEditor = false
    @Published var editingTask: AssignmentTask?

    func startCreatingTask() {
        editingTask = nil
        showingTaskEditor = true
    }

    func startEditingTask(_ task: AssignmentTask) {
        editingTask = task
        showingTaskEditor = true
    }
}
