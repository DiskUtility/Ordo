import Foundation
import Combine
import SwiftUI

@MainActor
final class CoursesViewModel: ObservableObject {
    @Published var showingEditor = false
    @Published var editingCourse: Course?

    func startCreating() {
        editingCourse = nil
        showingEditor = true
    }

    func startEditing(_ course: Course) {
        editingCourse = course
        showingEditor = true
    }
}
