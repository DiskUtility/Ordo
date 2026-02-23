import Foundation

enum AccessibilityID {
    enum Onboarding {
        static let beginButton = "onboarding.beginButton"
        static let nameField = "onboarding.nameField"
        static let nextButton = "onboarding.nextButton"
        static let backButton = "onboarding.backButton"
        static let termNameField = "onboarding.termNameField"
        static let finishButton = "onboarding.finishButton"
        static let skipSimulatorButton = "onboarding.skipSimulatorButton"
        static let addCourseToggle = "onboarding.addCourseToggle"
        static let courseNameField = "onboarding.courseNameField"
    }

    enum Dashboard {
        static let addTaskButton = "dashboard.addTaskButton"
        static let completeButton = "dashboard.completeButton"
        static let snoozeButton = "dashboard.snoozeButton"
    }

    enum Courses {
        static let addButton = "courses.addButton"
        static let editorNameField = "courses.editor.nameField"
        static let editorSaveButton = "courses.editor.saveButton"
    }

    enum Tasks {
        static let addButton = "tasks.addButton"
        static let editorTitleField = "tasks.editor.titleField"
        static let editorSaveButton = "tasks.editor.saveButton"
    }
}
