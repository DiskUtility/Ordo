import Foundation

enum StudentLevel: String, Codable, CaseIterable, Identifiable {
    case highSchool
    case college

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .highSchool:
            return "High School"
        case .college:
            return "College / University"
        }
    }
}
