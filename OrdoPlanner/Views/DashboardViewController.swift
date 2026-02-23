//
//  DashboardViewController.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftData
import UIKit

final class DashboardViewController: UIViewController {
    // Dashboard clock display mode is user-toggleable with long press on the time label.
    private enum ClockPreference: String {
        case twelveHour
        case twentyFourHour
    }

    private enum Layout {
        static let horizontalPadding: CGFloat = 18
        static let contentTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 20
        static let cardCornerRadius: CGFloat = 22
        static let cardBorderOpacity: CGFloat = 0.08
        static let cardShadowOpacity: Float = 0.05
    }

    private static let clockPreferenceKey = "dashboard.clockPreference"
    private static let twelveHourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    private static let twentyFourHourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private let modelContainer: ModelContainer
    private let services: AppServices
    private lazy var modelContext = ModelContext(modelContainer)

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroStack = UIStackView()

    private let greetingLabel = UILabel()
    private let greetingNameLabel = UILabel()
    private let greetingNudgeLabel = UILabel()
    private let timeLabel = UILabel()
    private let weekdayLabel = UILabel()

    private let upcomingTitleLabel = UILabel()
    private let upcomingHeaderRow = UIStackView()
    private let addTaskButton = UIButton(type: .system)
    private let upcomingCardView = UIView()
    private let upcomingCardStack = UIStackView()

    private let plannerTitleLabel = UILabel()
    private let plannerCardsStack = UIStackView()
    private let refreshControl = UIRefreshControl()

    private var tasks: [AssignmentTask] = []
    private var courses: [Course] = []
    private var profiles: [StudentProfile] = []

    private var compactCardsEnabled: Bool { AppPreferences.compactCardsEnabled }
    private var showCourseCodes: Bool { AppPreferences.showCourseCodes }
    private var useVibrantCourseCards: Bool { AppPreferences.useVibrantCourseCards }
    private var showGreetingNudges: Bool { AppPreferences.showGreetingNudges }
    private var dashboardTaskPreviewCount: Int { AppPreferences.dashboardTaskPreviewCount }

    private var clockTimer: Timer?
    private var hasAnimatedEntry = false
    private var clockPreference: ClockPreference = .twelveHour
    // Debounces repeated long-press triggers to avoid visual jitter.
    private var lastClockToggleAt: Date = .distantPast

    init(modelContainer: ModelContainer, services: AppServices) {
        self.modelContainer = modelContainer
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        clockTimer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 1)
            }
            return UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1)
        }
        loadClockPreference()
        configureLayout()
        configureStyling()
        configureInteractions()
        reloadContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reloadContent()
        startClockTimerIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        stopClockTimer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateContentIfNeeded()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.spacing = Layout.sectionSpacing

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Layout.contentTopPadding),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: Layout.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -Layout.horizontalPadding),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Layout.contentBottomPadding)
        ])

        heroStack.addArrangedSubview(greetingLabel)
        heroStack.addArrangedSubview(greetingNameLabel)
        heroStack.addArrangedSubview(greetingNudgeLabel)
        heroStack.addArrangedSubview(timeLabel)
        heroStack.addArrangedSubview(weekdayLabel)
        heroStack.axis = .vertical
        heroStack.spacing = 0
        heroStack.setCustomSpacing(2, after: greetingLabel)
        heroStack.setCustomSpacing(2, after: greetingNameLabel)
        heroStack.setCustomSpacing(10, after: greetingNudgeLabel)
        heroStack.setCustomSpacing(8, after: timeLabel)

        contentStack.addArrangedSubview(heroStack)

        upcomingCardView.translatesAutoresizingMaskIntoConstraints = false
        upcomingCardStack.translatesAutoresizingMaskIntoConstraints = false
        upcomingCardStack.axis = .vertical
        upcomingCardStack.spacing = 10

        upcomingCardView.addSubview(upcomingCardStack)
        NSLayoutConstraint.activate([
            upcomingCardStack.topAnchor.constraint(equalTo: upcomingCardView.topAnchor, constant: 14),
            upcomingCardStack.leadingAnchor.constraint(equalTo: upcomingCardView.leadingAnchor, constant: 14),
            upcomingCardStack.trailingAnchor.constraint(equalTo: upcomingCardView.trailingAnchor, constant: -14),
            upcomingCardStack.bottomAnchor.constraint(equalTo: upcomingCardView.bottomAnchor, constant: -14),
            upcomingCardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 66)
        ])

        upcomingHeaderRow.axis = .horizontal
        upcomingHeaderRow.alignment = .center
        upcomingHeaderRow.spacing = 10
        upcomingHeaderRow.addArrangedSubview(upcomingTitleLabel)
        upcomingHeaderRow.addArrangedSubview(UIView())
        upcomingHeaderRow.addArrangedSubview(addTaskButton)

        contentStack.addArrangedSubview(upcomingHeaderRow)
        contentStack.addArrangedSubview(upcomingCardView)
        contentStack.addArrangedSubview(plannerTitleLabel)
        contentStack.addArrangedSubview(plannerCardsStack)

        contentStack.setCustomSpacing(22, after: heroStack)
        contentStack.setCustomSpacing(10, after: upcomingHeaderRow)
        contentStack.setCustomSpacing(10, after: plannerTitleLabel)
    }

    private func configureStyling() {
        greetingLabel.font = .systemFont(ofSize: 50, weight: .regular)
        greetingLabel.textColor = .label
        greetingLabel.numberOfLines = 1

        greetingNameLabel.font = .systemFont(ofSize: 46, weight: .regular)
        greetingNameLabel.textColor = .secondaryLabel
        greetingNameLabel.numberOfLines = 1

        greetingNudgeLabel.font = .systemFont(ofSize: 17, weight: .medium)
        greetingNudgeLabel.textColor = .secondaryLabel
        greetingNudgeLabel.numberOfLines = 1

        timeLabel.font = .systemFont(ofSize: 84, weight: .regular)
        timeLabel.textColor = .label
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.72

        weekdayLabel.font = .systemFont(ofSize: 60, weight: .regular)
        weekdayLabel.textColor = .secondaryLabel
        weekdayLabel.adjustsFontSizeToFitWidth = true
        weekdayLabel.minimumScaleFactor = 0.7

        upcomingTitleLabel.text = "Upcoming Tasks"
        upcomingTitleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        upcomingTitleLabel.textColor = .label

        var addConfig = UIButton.Configuration.filled()
        addConfig.title = "Add Task"
        addConfig.image = UIImage(systemName: "plus")
        addConfig.imagePadding = 6
        addConfig.cornerStyle = .capsule
        addConfig.baseBackgroundColor = .systemBlue
        addConfig.baseForegroundColor = .white
        addTaskButton.configuration = addConfig
        addTaskButton.accessibilityIdentifier = AccessibilityID.Dashboard.addTaskButton
        addTaskButton.addTarget(self, action: #selector(didTapAddTask), for: .touchUpInside)

        upcomingCardView.backgroundColor = UIColor.secondarySystemBackground
        upcomingCardView.layer.cornerRadius = Layout.cardCornerRadius
        upcomingCardView.layer.borderWidth = 1
        upcomingCardView.layer.borderColor = UIColor.separator.withAlphaComponent(Layout.cardBorderOpacity).cgColor
        upcomingCardView.layer.shadowColor = UIColor.black.cgColor
        upcomingCardView.layer.shadowOpacity = Layout.cardShadowOpacity
        upcomingCardView.layer.shadowRadius = 10
        upcomingCardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        upcomingCardView.layer.masksToBounds = false

        plannerTitleLabel.text = "Planner"
        plannerTitleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        plannerTitleLabel.textColor = .label

        plannerCardsStack.axis = .vertical
        plannerCardsStack.spacing = 14
    }

    private func configureInteractions() {
        // Pull-to-refresh lets users manually refresh task/course state quickly.
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        timeLabel.isUserInteractionEnabled = true
        timeLabel.accessibilityHint = "Long press to toggle 24-hour clock"

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleClockLongPress(_:)))
        longPress.minimumPressDuration = 0.45
        timeLabel.addGestureRecognizer(longPress)
    }

    private func reloadContent() {
        let now = Date()
        profiles = fetchProfiles()
        courses = fetchCourses()
        tasks = fetchTasks()

        updateHeroText(for: now)
        renderUpcomingTasks()
        renderPlannerCards()
        refreshControl.endRefreshing()
    }

    private func updateHeroText(for now: Date) {
        let displayName = normalizedDisplayName
        let greeting = GreetingComposer.content(for: now, name: displayName)
        greetingLabel.text = greeting.subheadline
        greetingNameLabel.text = displayName
        greetingNudgeLabel.isHidden = !showGreetingNudges
        greetingNudgeLabel.text = showGreetingNudges ? greeting.headline : nil
        timeLabel.attributedText = NSAttributedString(
            string: timeString(from: now),
            attributes: [.kern: -1.8]
        )
        weekdayLabel.attributedText = NSAttributedString(
            string: weekdayString(from: now),
            attributes: [.kern: -0.8]
        )
    }

    private func renderUpcomingTasks() {
        clearStack(upcomingCardStack)

        let triage = services.triageScorer.bucketize(tasks: tasks, now: Date(), calendar: .current)
        let todayTasks = triage.today

        guard !todayTasks.isEmpty else {
            let emptyLabel = UILabel()
            emptyLabel.text = "No Tasks Today"
            emptyLabel.font = .systemFont(ofSize: 17, weight: .medium)
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.textAlignment = .center
            upcomingCardStack.addArrangedSubview(emptyLabel)
            return
        }

        if !triage.overdue.isEmpty {
            let overdueLabel = UILabel()
            overdueLabel.text = "\(triage.overdue.count) overdue"
            overdueLabel.font = .systemFont(ofSize: 13, weight: .semibold)
            overdueLabel.textColor = .systemRed
            upcomingCardStack.addArrangedSubview(overdueLabel)
        }

        let displayTasks = Array(todayTasks.prefix(dashboardTaskPreviewCount))
        for (index, task) in displayTasks.enumerated() {
            upcomingCardStack.addArrangedSubview(makeUpcomingTaskRow(task))
            if index < displayTasks.count - 1 {
                upcomingCardStack.addArrangedSubview(makeSeparator())
            }
        }
    }

    private func makeUpcomingTaskRow(_ task: AssignmentTask) -> UIView {
        let titleFontSize: CGFloat = compactCardsEnabled ? 14 : 15
        let secondaryFontSize: CGFloat = compactCardsEnabled ? 11 : 12
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = task.title
        titleLabel.font = .systemFont(ofSize: titleFontSize, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        let dueLabel = UILabel()
        dueLabel.text = dueTimeString(from: task.dueDate)
        dueLabel.font = .systemFont(ofSize: secondaryFontSize, weight: .medium)
        dueLabel.textColor = .secondaryLabel

        let courseLabel = UILabel()
        let linkedCourseName: String = {
            guard let course = task.course else { return "" }
            if showCourseCodes, !course.code.isEmpty {
                return "\(course.name) \(course.code)"
            }
            return course.name
        }()
        courseLabel.text = linkedCourseName.isEmpty ? "Unlinked" : linkedCourseName
        courseLabel.font = .systemFont(ofSize: secondaryFontSize, weight: .regular)
        courseLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dueLabel, courseLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let completeButton = UIButton(type: .system)
        completeButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        completeButton.tintColor = .systemGreen
        completeButton.accessibilityIdentifier = AccessibilityID.Dashboard.completeButton
        completeButton.addAction(UIAction { [weak self] _ in
            self?.completeTask(task)
        }, for: .touchUpInside)

        let snoozeButton = UIButton(type: .system)
        snoozeButton.setImage(UIImage(systemName: "clock.badge"), for: .normal)
        snoozeButton.tintColor = .systemOrange
        snoozeButton.accessibilityIdentifier = AccessibilityID.Dashboard.snoozeButton
        snoozeButton.addAction(UIAction { [weak self] _ in
            self?.snoozeTask(task)
        }, for: .touchUpInside)

        let actionsStack = UIStackView(arrangedSubviews: [completeButton, snoozeButton])
        actionsStack.axis = .horizontal
        actionsStack.spacing = 8

        let row = UIStackView(arrangedSubviews: [textStack, UIView(), actionsStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func renderPlannerCards() {
        clearStack(plannerCardsStack)
        plannerCardsStack.spacing = compactCardsEnabled ? 10 : 14

        let today = weekdayForDate(Date())
        let todaysCourses = courses
            .filter { WeekdayBitmask.contains(today, in: $0.meetingDaysBitmask) }
            .sorted { $0.startTime < $1.startTime }

        let visibleCourses = todaysCourses.isEmpty ? courses.sorted { $0.startTime < $1.startTime }.prefix(3) : todaysCourses.prefix(3)

        if visibleCourses.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No classes scheduled"
            emptyLabel.font = .systemFont(ofSize: 15, weight: .regular)
            emptyLabel.textColor = .secondaryLabel
            plannerCardsStack.addArrangedSubview(emptyLabel)
            return
        }

        for course in visibleCourses {
            plannerCardsStack.addArrangedSubview(makePlannerCard(for: course))
        }
    }

    private func makePlannerCard(for course: Course) -> UIView {
        let cardMinHeight: CGFloat = compactCardsEnabled ? 104 : 124
        let titleFontSize: CGFloat = compactCardsEnabled ? 24 : 30
        let bodyFontSize: CGFloat = compactCardsEnabled ? 13 : 14
        let durationFontSize: CGFloat = compactCardsEnabled ? 13 : 15
        let cardCornerRadius: CGFloat = compactCardsEnabled ? 18 : 22
        let iconBubbleSize: CGFloat = compactCardsEnabled ? 28 : 32
        let iconSize: CGFloat = compactCardsEnabled ? 15 : 18

        let baseColor = plannerBaseColor(for: course)
        let card = DashboardGradientCardView(
            startColor: baseColor.withAlphaComponent(0.95),
            endColor: baseColor.darker(by: 0.14)
        )
        card.layer.cornerRadius = cardCornerRadius
        card.layer.masksToBounds = true

        let symbol = UIImageView(image: UIImage(systemName: plannerIconName(for: course)))
        symbol.tintColor = .white.withAlphaComponent(0.9)
        symbol.contentMode = .scaleAspectFit
        symbol.translatesAutoresizingMaskIntoConstraints = false

        let symbolBubble = UIView()
        symbolBubble.backgroundColor = .white.withAlphaComponent(0.16)
        symbolBubble.layer.cornerRadius = 16
        symbolBubble.translatesAutoresizingMaskIntoConstraints = false
        symbolBubble.addSubview(symbol)

        let nameLabel = UILabel()
        nameLabel.text = course.name
        nameLabel.font = .systemFont(ofSize: titleFontSize, weight: .bold)
        nameLabel.textColor = .white

        let detailsLabel = UILabel()
        detailsLabel.text = "\(timeRangeString(start: course.startTime, end: course.endTime))\(course.location.isEmpty ? "" : "  ·  \(course.location)")"
        detailsLabel.font = .systemFont(ofSize: bodyFontSize, weight: .medium)
        detailsLabel.textColor = .white.withAlphaComponent(0.88)

        let courseCodeLabel = UILabel()
        courseCodeLabel.text = course.code.isEmpty ? "Course" : course.code
        courseCodeLabel.font = .systemFont(ofSize: bodyFontSize, weight: .regular)
        courseCodeLabel.textColor = .white.withAlphaComponent(0.82)
        courseCodeLabel.isHidden = !showCourseCodes

        let durationLabel = UILabel()
        durationLabel.text = durationString(start: course.startTime, end: course.endTime)
        durationLabel.font = .systemFont(ofSize: durationFontSize, weight: .semibold)
        durationLabel.textColor = .white.withAlphaComponent(0.9)

        let leftInfo = UIStackView(arrangedSubviews: [nameLabel, detailsLabel, courseCodeLabel])
        leftInfo.axis = .vertical
        leftInfo.spacing = 4

        let iconAndInfo = UIStackView(arrangedSubviews: [symbolBubble, leftInfo])
        iconAndInfo.axis = .horizontal
        iconAndInfo.spacing = 10
        iconAndInfo.alignment = .top

        NSLayoutConstraint.activate([
            symbolBubble.widthAnchor.constraint(equalToConstant: iconBubbleSize),
            symbolBubble.heightAnchor.constraint(equalToConstant: iconBubbleSize),
            symbol.centerXAnchor.constraint(equalTo: symbolBubble.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: symbolBubble.centerYAnchor),
            symbol.widthAnchor.constraint(equalToConstant: iconSize),
            symbol.heightAnchor.constraint(equalToConstant: iconSize),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: cardMinHeight)
        ])

        let row = UIStackView(arrangedSubviews: [iconAndInfo, UIView(), durationLabel])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 10
        row.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    @objc
    private func didTapAddTask() {
        let alert = UIAlertController(title: "New Task", message: "Quick add to your planner.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Task title"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self, weak alert] _ in
            guard let self else { return }
            let title = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty else { return }
            self.createQuickTask(title: title)
        }))

        present(alert, animated: true)
    }

    private func createQuickTask(title: String) {
        let selectedCourse = courses.first
        let dueDate = recommendedQuickTaskDueDate()

        let task = AssignmentTask(
            title: title,
            notes: "",
            dueDate: dueDate,
            estimatedMinutes: 60,
            priority: .medium,
            status: .notStarted,
            course: selectedCourse
        )
        task.courseID = selectedCourse?.id

        let shouldRequestPermissions = tasks.isEmpty

        modelContext.insert(task)
        try? modelContext.save()

        Task {
            if shouldRequestPermissions {
                _ = await services.notificationScheduler.requestAuthorization()
            }
            let leadHours = profiles.first?.defaultReminderLeadHours ?? 24
            try? await services.notificationScheduler.schedule(for: task, leadHours: leadHours)
        }

        reloadContent()
    }

    private func recommendedQuickTaskDueDate() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        if hour < 20 {
            return now.addingTimeInterval(4 * 3600)
        }

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 9
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? tomorrow
    }

    private func completeTask(_ task: AssignmentTask) {
        task.status = .completed
        task.completedAt = Date()

        Task {
            await services.notificationScheduler.cancel(taskID: task.id)
        }

        try? modelContext.save()
        reloadContent()
    }

    private func snoozeTask(_ task: AssignmentTask) {
        Task {
            try? await services.notificationScheduler.scheduleSnooze(task: task, afterMinutes: 60)
        }
    }

    private func startClockTimerIfNeeded() {
        guard clockTimer == nil else { return }
        clockTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateHeroText(for: Date())
        }
    }

    private func stopClockTimer() {
        clockTimer?.invalidate()
        clockTimer = nil
    }

    private var normalizedDisplayName: String {
        let trimmed = profiles.first?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            return trimmed
        }

        // With onboarding disabled, fall back to the Settings-persisted name.
        let fallback = AppPreferences.fallbackDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return fallback.isEmpty ? "Student" : fallback
    }

    private func timeOfDayGreeting(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private func weekdayForDate(_ date: Date) -> Weekday {
        switch Calendar.current.component(.weekday, from: date) {
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = clockPreference == .twentyFourHour ? Self.twentyFourHourFormatter : Self.twelveHourFormatter
        return formatter.string(from: date)
    }

    private func weekdayString(from date: Date) -> String {
        Self.weekdayFormatter.string(from: date)
    }

    private func dueTimeString(from date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today · \(date.formatted(date: .omitted, time: .shortened))"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func timeRangeString(start: Date, end: Date) -> String {
        "\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))"
    }

    private func durationString(start: Date, end: Date) -> String {
        let interval = max(0, end.timeIntervalSince(start))
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = interval >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }

    private func plannerBaseColor(for course: Course) -> UIColor {
        if useVibrantCourseCards, let parsedColor = UIColor(hexString: course.colorHex) {
            return parsedColor
        }
        return UIColor(red: 0.95, green: 0.60, blue: 0.28, alpha: 1)
    }

    private func plannerIconName(for course: Course) -> String {
        let text = "\(course.name) \(course.code)".lowercased()
        if text.contains("physics") { return "atom" }
        if text.contains("math") { return "sum" }
        if text.contains("chem") { return "flask.fill" }
        if text.contains("bio") { return "leaf.fill" }
        if text.contains("history") { return "book.pages.fill" }
        return "book.closed.fill"
    }

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.separator.withAlphaComponent(0.25)
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        return separator
    }

    private func loadClockPreference() {
        let raw = UserDefaults.standard.string(forKey: Self.clockPreferenceKey)
        clockPreference = ClockPreference(rawValue: raw ?? "") ?? .twelveHour
    }

    private func saveClockPreference() {
        UserDefaults.standard.set(clockPreference.rawValue, forKey: Self.clockPreferenceKey)
    }

    @objc
    private func handleClockLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let now = Date()
        // Ignore accidental rapid re-fires from repeated presses.
        guard now.timeIntervalSince(lastClockToggleAt) > 0.45 else { return }
        lastClockToggleAt = now

        clockPreference = (clockPreference == .twentyFourHour) ? .twelveHour : .twentyFourHour
        saveClockPreference()

        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        updateHeroText(for: now)
    }

    @objc
    private func handlePullToRefresh() {
        reloadContent()
    }

    private func animateContentIfNeeded() {
        guard !hasAnimatedEntry else { return }
        hasAnimatedEntry = true

        [greetingLabel, greetingNameLabel, greetingNudgeLabel, timeLabel, weekdayLabel, upcomingTitleLabel, upcomingCardView, plannerTitleLabel, plannerCardsStack].forEach {
            $0.alpha = 0
            $0.transform = CGAffineTransform(translationX: 0, y: 10)
        }

        let views = [greetingLabel, greetingNameLabel, greetingNudgeLabel, timeLabel, weekdayLabel, upcomingTitleLabel, upcomingCardView, plannerTitleLabel, plannerCardsStack]
        for (index, view) in views.enumerated() {
            UIView.animate(
                withDuration: 0.38,
                delay: Double(index) * 0.045,
                options: [.curveEaseOut],
                animations: {
                    view.alpha = 1
                    view.transform = .identity
                }
            )
        }
    }

    private func fetchProfiles() -> [StudentProfile] {
        let descriptor = FetchDescriptor<StudentProfile>(sortBy: [SortDescriptor(\StudentProfile.createdAt, order: .forward)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchCourses() -> [Course] {
        let descriptor = FetchDescriptor<Course>(sortBy: [SortDescriptor(\Course.name, order: .forward)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchTasks() -> [AssignmentTask] {
        let descriptor = FetchDescriptor<AssignmentTask>(sortBy: [SortDescriptor(\AssignmentTask.dueDate, order: .forward)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func clearStack(_ stack: UIStackView) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
}

private extension UIColor {
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard hex.count == 6, let value = Int(hex, radix: 16) else { return nil }

        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    func darker(by amount: CGFloat) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return self
        }

        return UIColor(
            red: max(red - amount, 0),
            green: max(green - amount, 0),
            blue: max(blue - amount, 0),
            alpha: alpha
        )
    }
}

private final class DashboardGradientCardView: UIView {
    private let gradientLayer = CAGradientLayer()

    init(startColor: UIColor, endColor: UIColor) {
        super.init(frame: .zero)
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
