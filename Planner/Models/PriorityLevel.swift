import Foundation

enum PriorityLevel: Int, Codable, CaseIterable, Identifiable {
    case low = 1
    case medium = 2
    case high = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }
}
