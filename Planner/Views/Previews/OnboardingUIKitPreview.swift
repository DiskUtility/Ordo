import SwiftData
import SwiftUI
import UIKit

#if DEBUG
private struct OnboardingUIKitPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        OnboardingViewController(modelContainer: Self.previewContainer)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private static var previewContainer: ModelContainer = {
        let schema = Schema([StudentProfile.self, AcademicTerm.self, Course.self, AssignmentTask.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}

#Preview("Onboarding UIKit") {
    OnboardingUIKitPreview()
}
#endif
