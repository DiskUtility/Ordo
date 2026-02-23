import Foundation

enum LaunchOptions {
    private static let arguments = ProcessInfo.processInfo.arguments

    static var skipOnboarding: Bool {
        arguments.contains("-skipOnboarding") || (isRunningInSimulator && arguments.contains("-skipOnboardingForSimulator"))
    }

    static var seedSampleData: Bool {
        arguments.contains("-seedSampleData") || (isRunningInSimulator && arguments.contains("-seedSampleDataForSimulator"))
    }

    private static var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}
