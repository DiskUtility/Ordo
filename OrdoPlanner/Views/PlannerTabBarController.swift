//
//  PlannerTabBarController.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftData
import SwiftUI
import UIKit

final class PlannerTabBarController: UITabBarController, UITabBarControllerDelegate {
    private let studentLevel: StudentLevel
    private let modelContainer: ModelContainer
    private let services: AppServices
    private lazy var modelContext = ModelContext(modelContainer)

    private let tasksAccessoryView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let tasksAccessoryLabel = UILabel()
    private let filterAccessoryButton = UIButton(type: .system)
    private let addAccessoryButton = UIButton(type: .system)

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

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureTasksAccessory()
        updateTasksAccessory(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTasksAccessoryCounts()
    }

    private func configureTabs() {
        let dashboard = makeUIKitNavController(
            root: DashboardViewController(modelContainer: modelContainer, services: services),
            title: "Today",
            imageName: "square.grid.2x2"
        )

        let courses = makeNavController(
            root: CoursesView(defaultStudentLevel: studentLevel),
            title: "Schedule",
            imageName: "books.vertical"
        )

        let tasks = makeNavController(
            root: TasksView(),
            title: "Tasks",
            imageName: "checklist"
        )

        let settings = makeNavController(
            root: SettingsView(),
            title: "Prefs",
            imageName: "gearshape"
        )

        viewControllers = [dashboard, courses, tasks, settings]
        tabBar.tintColor = UIColor(AppTheme.accent)
        tabBar.unselectedItemTintColor = .secondaryLabel
        tabBar.layer.cornerRadius = 18
        tabBar.layer.masksToBounds = true

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func configureTasksAccessory() {
        tasksAccessoryView.translatesAutoresizingMaskIntoConstraints = false
        tasksAccessoryView.layer.cornerRadius = 14
        tasksAccessoryView.layer.masksToBounds = true
        tasksAccessoryView.isHidden = true
        tasksAccessoryView.alpha = 0

        view.addSubview(tasksAccessoryView)
        NSLayoutConstraint.activate([
            tasksAccessoryView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            tasksAccessoryView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            tasksAccessoryView.bottomAnchor.constraint(equalTo: tabBar.topAnchor, constant: -8),
            tasksAccessoryView.heightAnchor.constraint(equalToConstant: 44)
        ])

        let contentStack = UIStackView()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .horizontal
        contentStack.spacing = 10
        contentStack.alignment = .center
        tasksAccessoryView.contentView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: tasksAccessoryView.contentView.leadingAnchor, constant: 12),
            contentStack.trailingAnchor.constraint(equalTo: tasksAccessoryView.contentView.trailingAnchor, constant: -12),
            contentStack.topAnchor.constraint(equalTo: tasksAccessoryView.contentView.topAnchor, constant: 8),
            contentStack.bottomAnchor.constraint(equalTo: tasksAccessoryView.contentView.bottomAnchor, constant: -8)
        ])

        tasksAccessoryLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        tasksAccessoryLabel.textColor = .secondaryLabel
        tasksAccessoryLabel.text = "0 active · 0 overdue"

        filterAccessoryButton.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
        filterAccessoryButton.addAction(UIAction { _ in
            NotificationCenter.default.post(name: .tasksAccessoryOpenFilters, object: nil)
        }, for: .touchUpInside)

        addAccessoryButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addAccessoryButton.tintColor = UIColor(AppTheme.accent)
        addAccessoryButton.addAction(UIAction { _ in
            NotificationCenter.default.post(name: .tasksAccessoryAddTask, object: nil)
        }, for: .touchUpInside)

        contentStack.addArrangedSubview(tasksAccessoryLabel)
        contentStack.addArrangedSubview(UIView())
        contentStack.addArrangedSubview(filterAccessoryButton)
        contentStack.addArrangedSubview(addAccessoryButton)
    }

    private func refreshTasksAccessoryCounts() {
        let descriptor = FetchDescriptor<AssignmentTask>()
        let fetchedTasks = (try? modelContext.fetch(descriptor)) ?? []
        let activeTasks = fetchedTasks.filter { !$0.status.isCompleted }
        let overdueCount = activeTasks.filter { $0.dueDate < Date() }.count
        tasksAccessoryLabel.text = "\(activeTasks.count) active · \(overdueCount) overdue"
    }

    private var shouldShowTasksAccessory: Bool {
        selectedIndex == 2
    }

    private func updateTasksAccessory(animated: Bool) {
        let visible = shouldShowTasksAccessory

        if visible {
            refreshTasksAccessoryCounts()
            tasksAccessoryView.isHidden = false
        }

        let animations = {
            self.tasksAccessoryView.alpha = visible ? 1 : 0
            self.tasksAccessoryView.transform = visible ? .identity : CGAffineTransform(translationX: 0, y: 8)
        }

        let completion: (Bool) -> Void = { _ in
            self.tasksAccessoryView.isHidden = !visible
        }

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut], animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
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

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateTasksAccessory(animated: true)
    }
}
