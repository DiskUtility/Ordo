import SwiftData
import SwiftUI

struct PlannerRootView: UIViewControllerRepresentable {
    let modelContainer: ModelContainer
    let services: AppServices

    func makeUIViewController(context: Context) -> PlannerRootViewController {
        PlannerRootViewController(modelContainer: modelContainer, services: services)
    }

    func updateUIViewController(_ uiViewController: PlannerRootViewController, context: Context) {
        uiViewController.reloadRootIfNeeded()
    }
}
