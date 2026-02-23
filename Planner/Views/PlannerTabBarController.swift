//
//  PlannerTabBarController.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftData
import SwiftUI
import UIKit

final class PlannerTabBarController: UITabBarController {
    private let studentLevel: StudentLevel
    private let modelContainer: ModelContainer
    private let services: AppServices

    init(studentLevel: StudentLevel, modelContainer: ModelContainer, services: AppServices) {
        self.studentLevel = studentLevel
        self.modelContainer = modelContainer
        self.services = services
        super.init(nibName: nil, bundle: nil)
        configureTabs()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureTabs() {
        let dashboard = makeUIKitNavController(
            root: DashboardViewController(modelContainer: modelContainer, services: services),
            title: "Today",
            imageName: "square.grid.2x2"
        )

        let courses = makeNavController(
            root: CoursesView(defaultStudentLevel: studentLevel),
            title: "Timeline",
            imageName: "books.vertical"
        )

        let tasks = makeNavController(
            root: TasksView(),
            title: "Tasks",
            imageName: "checklist"
        )

        let settings = makeNavController(
            root: SettingsView(),
            title: "Settings",
            imageName: "gearshape"
        )

        viewControllers = [dashboard, courses, tasks, settings]
        tabBar.tintColor = UIColor(AppTheme.accent)
    }

    private func makeUIKitNavController(root: UIViewController, title: String, imageName: String) -> UINavigationController {
        root.title = title
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: imageName), selectedImage: nil)
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }

    private func makeNavController<Content: View>(root: Content, title: String, imageName: String) -> UINavigationController {
        let hosted = root
            .environmentObject(services)
            .modelContainer(modelContainer)

        let host = UIHostingController(rootView: hosted)
        host.title = title

        let nav = UINavigationController(rootViewController: host)
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: imageName), selectedImage: nil)
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }
}
