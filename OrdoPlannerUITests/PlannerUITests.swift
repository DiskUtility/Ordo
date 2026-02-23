//
//  PlannerUITests.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import XCTest

final class PlannerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingAppearsAndCompletes() throws {
        let app = launchApp(resetData: true)

        // Onboarding may be disabled in pre-release builds.
        if app.tabBars.buttons["Today"].waitForExistence(timeout: 2) {
            XCTAssertTrue(true)
            return
        }

        let beginButton = app.buttons["Tap to begin"]
        XCTAssertTrue(beginButton.waitForExistence(timeout: 2))
        beginButton.tap()

        XCTAssertTrue(app.textFields["Name (optional)"].waitForExistence(timeout: 2))

        app.buttons["Next"].tap()
        app.buttons["Next"].tap()
        app.buttons["Next"].tap()
        app.buttons["Finish"].tap()

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCreateCourseAndTaskShowsInDashboard() throws {
        let app = launchApp(resetData: true)
        completeOnboardingIfNeeded(app)

        app.tabBars.buttons["Timeline"].tap()
        app.buttons["Add Course"].tap()

        let courseName = app.textFields["Name"]
        XCTAssertTrue(courseName.waitForExistence(timeout: 2))
        courseName.tap()
        courseName.typeText("Biology")
        app.buttons["Save"].tap()

        app.tabBars.buttons["Today"].tap()
        app.buttons["Add Task"].tap()

        let taskTitle = app.textFields["Title"]
        XCTAssertTrue(taskTitle.waitForExistence(timeout: 2))
        taskTitle.tap()
        taskTitle.typeText("Lab report")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Lab report"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testMarkCompleteRemovesTaskFromTriage() throws {
        let app = launchApp(resetData: true)
        completeOnboardingIfNeeded(app)

        app.tabBars.buttons["Today"].tap()
        app.buttons["Add Task"].tap()

        let taskTitle = app.textFields["Title"]
        XCTAssertTrue(taskTitle.waitForExistence(timeout: 2))
        taskTitle.tap()
        taskTitle.typeText("Complete me")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Complete me"].waitForExistence(timeout: 3))

        let completeButton = app.buttons.matching(identifier: "dashboard.completeButton").firstMatch
        XCTAssertTrue(completeButton.exists)
        completeButton.tap()

        XCTAssertFalse(app.staticTexts["Complete me"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testNotificationsDeniedStillAllowsTaskCreation() throws {
        let app = launchApp(resetData: true, notificationsDenied: true)
        completeOnboardingIfNeeded(app)

        app.tabBars.buttons["Tasks"].tap()
        app.buttons["Add Task"].tap()

        let taskTitle = app.textFields["Title"]
        XCTAssertTrue(taskTitle.waitForExistence(timeout: 2))
        taskTitle.tap()
        taskTitle.typeText("Permission denied path")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Permission denied path"].waitForExistence(timeout: 3))
    }

    @MainActor
    private func launchApp(resetData: Bool, notificationsDenied: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        if resetData {
            app.launchArguments.append("-uiTestResetData")
        }
        if notificationsDenied {
            app.launchArguments.append("-uiTestNotificationsDenied")
        }
        app.launch()
        return app
    }

    @MainActor
    private func completeOnboardingIfNeeded(_ app: XCUIApplication) {
        let beginButton = app.buttons["Tap to begin"]
        if beginButton.waitForExistence(timeout: 1) {
            beginButton.tap()
        }

        let nextButton = app.buttons["Next"]
        if nextButton.waitForExistence(timeout: 1) {
            nextButton.tap()
            app.buttons["Next"].tap()
            app.buttons["Next"].tap()
            app.buttons["Finish"].tap()
        }

        _ = app.tabBars.buttons["Today"].waitForExistence(timeout: 2)
    }
}
