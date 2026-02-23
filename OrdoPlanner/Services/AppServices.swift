import Foundation
import Combine
import SwiftUI

@MainActor
final class AppServices: ObservableObject {
    let triageScorer: TriageScoring
    let notificationScheduler: LocalNotificationScheduler

    init(processInfo: ProcessInfo = .processInfo) {
        let forcedAuthorizationResult: Bool? = processInfo.arguments.contains("-uiTestNotificationsDenied") ? false : nil
        self.triageScorer = DefaultTriageScorer()
        self.notificationScheduler = LocalNotificationScheduler(
            calculator: ReminderDateCalculator(),
            forcedAuthorizationResult: forcedAuthorizationResult
        )
    }
}
