import Foundation

enum TaskStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case completed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        }
    }

    var isCompleted: Bool {
        self == .completed
    }
}
