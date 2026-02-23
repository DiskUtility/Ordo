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
}
