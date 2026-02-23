import SwiftData
import SwiftUI

@main
struct PlannerApp: App {
    @StateObject private var services = AppServices()

    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudentProfile.self,
            AcademicTerm.self,
            Course.self,
            AssignmentTask.self,
        ])

        if ProcessInfo.processInfo.arguments.contains("-uiTestResetData") {
            AppStorePaths.removeKnownStores()
        }

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Pre-release safety fallback: reset local store when schema migrations fail.
            AppStorePaths.removeKnownStores()
            do {
                let cleanConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [cleanConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            PlannerRootView(modelContainer: sharedModelContainer, services: services)
        }
    }
}
