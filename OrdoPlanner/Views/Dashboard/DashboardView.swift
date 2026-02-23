import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var services: AppServices

    var body: some View {
        DashboardUIKitHostView(modelContainer: modelContext.container, services: services)
            .ignoresSafeArea(edges: .top)
    }
}

private struct DashboardUIKitHostView: UIViewControllerRepresentable {
    let modelContainer: ModelContainer
    let services: AppServices

    func makeUIViewController(context: Context) -> DashboardViewController {
        DashboardViewController(modelContainer: modelContainer, services: services)
    }

    func updateUIViewController(_ uiViewController: DashboardViewController, context: Context) {
        // No-op: controller refreshes on appearance.
    }
}
