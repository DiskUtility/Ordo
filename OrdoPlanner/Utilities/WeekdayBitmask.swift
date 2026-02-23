import Foundation

enum Weekday: Int, CaseIterable, Identifiable {
    case monday = 0
    case tuesday = 1
    case wednesday = 2
    case thursday = 3
    case friday = 4
    case saturday = 5
    case sunday = 6

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .monday:
            return "M"
        case .tuesday:
            return "T"
        case .wednesday:
            return "W"
        case .thursday:
            return "Th"
        case .friday:
            return "F"
        case .saturday:
            return "Sa"
        case .sunday:
            return "Su"
        }
    }
}

enum WeekdayBitmask {
    static func contains(_ day: Weekday, in mask: Int) -> Bool {
        mask & (1 << day.rawValue) != 0
    }

    static func toggle(_ day: Weekday, in mask: Int) -> Int {
        mask ^ (1 << day.rawValue)
    }

    static func days(from mask: Int) -> [Weekday] {
        Weekday.allCases.filter { contains($0, in: mask) }
    }
}
