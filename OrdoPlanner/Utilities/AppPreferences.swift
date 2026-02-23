//
//  AppPreferences.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import Foundation

enum AppPreferences {
    // Used when onboarding/profile is unavailable but we still want to remember student name.
    private static let fallbackDisplayNameKey = "planner.fallbackDisplayName"
    static let compactCardsEnabledKey = "planner.compactCardsEnabled"
    static let showCourseCodesKey = "planner.showCourseCodes"
    static let showTaskNotesPreviewKey = "planner.showTaskNotesPreview"
    static let useVibrantCourseCardsKey = "planner.useVibrantCourseCards"
    static let showGreetingNudgesKey = "planner.showGreetingNudges"
    static let dashboardTaskPreviewCountKey = "planner.dashboardTaskPreviewCount"

    // Persist task browsing state between launches.
    static let tasksStatusFilterKey = "planner.tasks.statusFilter"
    static let tasksSortOptionKey = "planner.tasks.sortOption"
    static let tasksFocusModeEnabledKey = "planner.tasks.focusModeEnabled"
    static let tasksSelectedCourseIDKey = "planner.tasks.selectedCourseID"

    static let timelineSelectedWeekdayKey = "planner.timeline.selectedWeekday"

    static var fallbackDisplayName: String {
        get { UserDefaults.standard.string(forKey: fallbackDisplayNameKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: fallbackDisplayNameKey) }
    }

    static var compactCardsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: compactCardsEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: compactCardsEnabledKey) }
    }

    static var showCourseCodes: Bool {
        get {
            if UserDefaults.standard.object(forKey: showCourseCodesKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: showCourseCodesKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: showCourseCodesKey) }
    }

    static var showTaskNotesPreview: Bool {
        get {
            if UserDefaults.standard.object(forKey: showTaskNotesPreviewKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: showTaskNotesPreviewKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: showTaskNotesPreviewKey) }
    }

    static var useVibrantCourseCards: Bool {
        get {
            if UserDefaults.standard.object(forKey: useVibrantCourseCardsKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: useVibrantCourseCardsKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: useVibrantCourseCardsKey) }
    }

    static var showGreetingNudges: Bool {
        get {
            if UserDefaults.standard.object(forKey: showGreetingNudgesKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: showGreetingNudgesKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: showGreetingNudgesKey) }
    }

    static var dashboardTaskPreviewCount: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: dashboardTaskPreviewCountKey)
            if value == 0 { return 3 }
            return min(max(value, 1), 6)
        }
        set { UserDefaults.standard.set(min(max(newValue, 1), 6), forKey: dashboardTaskPreviewCountKey) }
    }
}
