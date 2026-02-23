//
//  PlannerRootViewController.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftData
import UIKit

final class PlannerRootViewController: UIViewController {
    // Toggle this to restore onboarding routing in future releases.
    private let onboardingEnabled = false

    private let modelContainer: ModelContainer
    private let services: AppServices
    private lazy var modelContext = ModelContext(modelContainer)

    private var currentRootController: UIViewController?

    init(modelContainer: ModelContainer, services: AppServices) {
        self.modelContainer = modelContainer
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        if onboardingEnabled {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onboardingCompleted),
                name: .onboardingCompleted,
                object: nil
            )
        }

        showAppropriateRoot(animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func reloadRootIfNeeded() {
        showAppropriateRoot(animated: false)
    }

    @objc
    private func onboardingCompleted() {
        showAppropriateRoot(animated: true)
    }

    private func showAppropriateRoot(animated: Bool) {
        let profile = fetchProfile()

        let nextController: UIViewController
        if onboardingEnabled, profile == nil {
            nextController = makeOnboardingController()
        } else {
            nextController = PlannerTabBarController(
                studentLevel: profile?.studentLevel ?? .college,
                modelContainer: modelContainer,
                services: services
            )
        }

        setRoot(nextController, animated: animated)
    }

    private func fetchProfile() -> StudentProfile? {
        let descriptor = FetchDescriptor<StudentProfile>(
            sortBy: [SortDescriptor(\StudentProfile.createdAt, order: .forward)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func makeOnboardingController() -> UIViewController {
        OnboardingViewController(modelContainer: modelContainer)
    }

    private func setRoot(_ newController: UIViewController, animated: Bool) {
        let previous = currentRootController

        guard previous?.isKind(of: type(of: newController)) != true else {
            return
        }

        addChild(newController)
        newController.view.frame = view.bounds
        newController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if let previous {
            if animated {
                transition(
                    from: previous,
                    to: newController,
                    duration: 0.25,
                    options: [.transitionCrossDissolve, .curveEaseInOut],
                    animations: nil
                ) { [weak self] _ in
                    previous.removeFromParent()
                    newController.didMove(toParent: self)
                    self?.currentRootController = newController
                }
            } else {
                previous.willMove(toParent: nil)
                transition(from: previous, to: newController, duration: 0, options: [], animations: nil) { [weak self] _ in
                    previous.removeFromParent()
                    newController.didMove(toParent: self)
                    self?.currentRootController = newController
                }
            }
        } else {
            view.addSubview(newController.view)
            newController.didMove(toParent: self)
            currentRootController = newController
        }
    }
}
