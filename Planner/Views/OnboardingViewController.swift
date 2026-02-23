import SwiftData
import SwiftUI
import UIKit

final class OnboardingViewController: UIViewController {
    private let modelContainer: ModelContainer
    private lazy var modelContext = ModelContext(modelContainer)
    private let viewModel = OnboardingViewModel()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let pageControl = UIPageControl()
    private let stepTitleLabel = UILabel()
    private let stepCountLabel = UILabel()
    private let stepExplanationTitleLabel = UILabel()
    private let stepExplanationBodyLabel = UILabel()

    private let stepCardView = UIView()
    private let stepCardStack = UIStackView()

    private let bottomContainer = UIView()
    private let hintLabel = UILabel()
    private let backButton = UIButton(type: .system)
    private let primaryButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Onboarding"

        configureLayout()
        configureStaticStyling()
        configureActions()
        configureGestures()
        render()
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill

        view.addSubview(scrollView)
        view.addSubview(bottomContainer)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16)
        ])

        let stepHeader = UIStackView(arrangedSubviews: [stepTitleLabel, stepCountLabel])
        stepHeader.axis = .vertical
        stepHeader.spacing = 2

        let explanationRow = UIStackView(arrangedSubviews: [makeIcon("info.circle", tint: .accent), stepExplanationTitleLabel])
        explanationRow.axis = .horizontal
        explanationRow.spacing = 8
        explanationRow.alignment = .center

        let explanationStack = UIStackView(arrangedSubviews: [explanationRow, stepExplanationBodyLabel])
        explanationStack.axis = .vertical
        explanationStack.spacing = 6

        let explanationCard = makeCardView(content: explanationStack)

        stepCardStack.axis = .vertical
        stepCardStack.spacing = 10
        stepCardStack.alignment = .fill

        stepCardView.backgroundColor = UIColor.secondarySystemGroupedBackground
        stepCardView.layer.cornerRadius = 12
        stepCardView.translatesAutoresizingMaskIntoConstraints = false
        stepCardStack.translatesAutoresizingMaskIntoConstraints = false
        stepCardView.addSubview(stepCardStack)
        NSLayoutConstraint.activate([
            stepCardStack.topAnchor.constraint(equalTo: stepCardView.topAnchor, constant: 12),
            stepCardStack.leadingAnchor.constraint(equalTo: stepCardView.leadingAnchor, constant: 12),
            stepCardStack.trailingAnchor.constraint(equalTo: stepCardView.trailingAnchor, constant: -12),
            stepCardStack.bottomAnchor.constraint(equalTo: stepCardView.bottomAnchor, constant: -12)
        ])

        contentStack.addArrangedSubview(pageControl)
        contentStack.addArrangedSubview(stepHeader)
        contentStack.addArrangedSubview(explanationCard)
        contentStack.addArrangedSubview(stepCardView)

        let hintAndButtons = UIStackView()
        hintAndButtons.axis = .vertical
        hintAndButtons.spacing = 10
        hintAndButtons.translatesAutoresizingMaskIntoConstraints = false

        let buttonsRow = UIStackView(arrangedSubviews: [backButton, UIView(), skipButton, primaryButton])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 10

        hintAndButtons.addArrangedSubview(hintLabel)
        hintAndButtons.addArrangedSubview(buttonsRow)

        bottomContainer.addSubview(hintAndButtons)
        NSLayoutConstraint.activate([
            hintAndButtons.topAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: 10),
            hintAndButtons.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 14),
            hintAndButtons.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -14),
            hintAndButtons.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor, constant: -8)
        ])

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: bottomContainer.topAnchor),
            separator.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        bottomContainer.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.95)
    }

    private func configureStaticStyling() {
        pageControl.numberOfPages = OnboardingViewModel.Step.allCases.count
        pageControl.currentPageIndicatorTintColor = UIColor(AppTheme.accent)
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.isUserInteractionEnabled = false

        stepTitleLabel.font = .preferredFont(forTextStyle: .headline)
        stepTitleLabel.textColor = .label

        stepCountLabel.font = .preferredFont(forTextStyle: .caption1)
        stepCountLabel.textColor = .secondaryLabel

        stepExplanationTitleLabel.font = .preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
        stepExplanationBodyLabel.font = .preferredFont(forTextStyle: .footnote)
        stepExplanationBodyLabel.textColor = .secondaryLabel
        stepExplanationBodyLabel.numberOfLines = 0

        hintLabel.font = .preferredFont(forTextStyle: .footnote)
        hintLabel.textColor = .secondaryLabel
        hintLabel.numberOfLines = 2

        backButton.setTitle("Back", for: .normal)
        backButton.accessibilityIdentifier = AccessibilityID.Onboarding.backButton

        skipButton.setTitle("Skip", for: .normal)
        skipButton.accessibilityIdentifier = AccessibilityID.Onboarding.skipSimulatorButton

        var primaryConfig = UIButton.Configuration.filled()
        primaryConfig.cornerStyle = .capsule
        primaryConfig.baseBackgroundColor = UIColor(AppTheme.accent)
        primaryButton.configuration = primaryConfig
    }

    private func configureActions() {
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        primaryButton.addTarget(self, action: #selector(didTapPrimary), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(didTapSkip), for: .touchUpInside)
    }

    private func configureGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right

        view.addGestureRecognizer(swipeLeft)
        view.addGestureRecognizer(swipeRight)
    }

    private func render() {
        pageControl.currentPage = viewModel.step.rawValue

        stepTitleLabel.text = currentStepTitle
        stepCountLabel.text = "Step \(viewModel.step.rawValue + 1) of \(OnboardingViewModel.Step.allCases.count)"
        stepExplanationTitleLabel.text = stepExplanationTitle
        stepExplanationBodyLabel.text = stepExplanationBody

        rebuildStepCard()
        configureBottomControls()
    }

    private func configureBottomControls() {
        let isWelcome = viewModel.step == .welcome

        stepTitleLabel.isHidden = isWelcome
        stepCountLabel.isHidden = isWelcome
        stepExplanationTitleLabel.superview?.superview?.isHidden = isWelcome

        bottomContainer.isHidden = isWelcome

        hintLabel.text = viewModel.isLastStep ? "Swipe left to finish setup. Swipe right to review." : "Swipe left to continue. Swipe right to go back."

        backButton.isHidden = viewModel.isFirstStep
        skipButton.isHidden = !isRunningInSimulator

        primaryButton.configuration?.title = viewModel.isLastStep ? "Finish" : "Next"
        primaryButton.accessibilityIdentifier = viewModel.isLastStep ? AccessibilityID.Onboarding.finishButton : AccessibilityID.Onboarding.nextButton
        primaryButton.isEnabled = viewModel.canContinue
    }

    private func rebuildStepCard() {
        clearStack(stepCardStack)

        switch viewModel.step {
        case .welcome:
            buildWelcomeStep()
        case .profile:
            buildProfileStep()
        case .term:
            buildTermStep()
        case .course:
            buildCourseStep()
        case .preferences:
            buildPreferencesStep()
        }
    }

    private func buildWelcomeStep() {
        let icon = makeIcon("graduationcap.fill", tint: .accent, size: 26, padded: true)
        let title = makeLabel("Welcome to Planner", style: .title2, weight: .semibold, alignment: .center)
        let subtitle = makeSecondaryLabel("A clean setup for classes, tasks, and reminders.", style: .subheadline, alignment: .center)

        let features = UIStackView(arrangedSubviews: [
            featureRow("calendar", "Plan your classes and term dates"),
            featureRow("checklist", "Track assignments and due dates"),
            featureRow("bell.badge", "Get reminders before deadlines")
        ])
        features.axis = .vertical
        features.spacing = 10

        let featuresCard = makeCardView(content: features)

        let beginButton = UIButton(type: .system)
        var beginConfig = UIButton.Configuration.filled()
        beginConfig.cornerStyle = .capsule
        beginConfig.baseBackgroundColor = UIColor(AppTheme.accent)
        beginConfig.title = "Tap to begin"
        beginButton.configuration = beginConfig
        beginButton.accessibilityIdentifier = AccessibilityID.Onboarding.beginButton
        beginButton.addAction(UIAction { [weak self] _ in self?.goForward() }, for: .touchUpInside)

        stepCardStack.addArrangedSubview(icon)
        stepCardStack.setCustomSpacing(12, after: icon)
        stepCardStack.addArrangedSubview(title)
        stepCardStack.addArrangedSubview(subtitle)
        stepCardStack.addArrangedSubview(featuresCard)
        stepCardStack.addArrangedSubview(beginButton)

        #if targetEnvironment(simulator)
        let skipTextButton = UIButton(type: .system)
        skipTextButton.setTitle("Skip Onboarding", for: .normal)
        skipTextButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        skipTextButton.accessibilityIdentifier = AccessibilityID.Onboarding.skipSimulatorButton
        skipTextButton.addAction(UIAction { [weak self] _ in self?.completeOnboardingNow() }, for: .touchUpInside)
        stepCardStack.addArrangedSubview(skipTextButton)
        #endif
    }

    private func buildProfileStep() {
        stepCardStack.addArrangedSubview(makeSecondaryLabel("Tell us about you.", style: .subheadline, alignment: .left))

        let nameField = makeTextField(placeholder: "Name (optional)", text: viewModel.displayName)
        nameField.accessibilityIdentifier = AccessibilityID.Onboarding.nameField
        nameField.addAction(UIAction { [weak self, weak nameField] _ in
            self?.viewModel.displayName = nameField?.text ?? ""
        }, for: .editingChanged)
        stepCardStack.addArrangedSubview(nameField)

        let levelControl = UISegmentedControl(items: StudentLevel.allCases.map(\.displayName))
        levelControl.selectedSegmentIndex = viewModel.studentLevel == .highSchool ? 0 : 1
        levelControl.addAction(UIAction { [weak self, weak levelControl] _ in
            guard let self, let index = levelControl?.selectedSegmentIndex else { return }
            self.viewModel.studentLevel = index == 0 ? .highSchool : .college
            self.viewModel.enforceCompatibleSetup()
            self.render()
        }, for: .valueChanged)
        stepCardStack.addArrangedSubview(levelControl)
    }

    private func buildTermStep() {
        stepCardStack.addArrangedSubview(makeSecondaryLabel("Set your active term details.", style: .subheadline, alignment: .left))

        let semesterHeader = makeLabel("Semester option", style: .subheadline, weight: .semibold, alignment: .left)
        stepCardStack.addArrangedSubview(semesterHeader)

        if viewModel.supportsSemesterSplitOption {
            let row = UIStackView(arrangedSubviews: [makeLabel("Split into 2 semesters (6 months + 6 months)", style: .body, weight: .regular, alignment: .left), UIView()])
            row.axis = .horizontal
            row.spacing = 8

            let splitSwitch = UISwitch()
            splitSwitch.isOn = viewModel.isSemesterModeEnabled
            splitSwitch.addAction(UIAction { [weak self, weak splitSwitch] _ in
                guard let self, let splitSwitch else { return }
                self.viewModel.isSemesterModeEnabled = splitSwitch.isOn
                self.viewModel.syncDatesForSelectedSetup()
                self.render()
            }, for: .valueChanged)
            row.addArrangedSubview(splitSwitch)
            stepCardStack.addArrangedSubview(row)

            if viewModel.isSemesterModeEnabled {
                let breakRow = UIStackView(arrangedSubviews: [makeLabel("Break between semesters", style: .body, weight: .regular, alignment: .left), UIView()])
                breakRow.axis = .horizontal
                breakRow.spacing = 8

                let breakValue = makeLabel("\(viewModel.semesterBreakWeeks) week(s)", style: .body, weight: .semibold, alignment: .right)
                let stepper = UIStepper()
                stepper.minimumValue = 0
                stepper.maximumValue = 8
                stepper.stepValue = 1
                stepper.value = Double(viewModel.semesterBreakWeeks)
                stepper.addAction(UIAction { [weak self] action in
                    guard let self, let stepper = action.sender as? UIStepper else { return }
                    self.viewModel.semesterBreakWeeks = Int(stepper.value)
                    self.viewModel.syncDatesForSelectedSetup()
                    self.render()
                }, for: .valueChanged)

                let right = UIStackView(arrangedSubviews: [breakValue, stepper])
                right.axis = .horizontal
                right.spacing = 8
                breakRow.addArrangedSubview(right)
                stepCardStack.addArrangedSubview(breakRow)
            }
        } else {
            stepCardStack.addArrangedSubview(makeLabel("Single Term", style: .body, weight: .semibold, alignment: .left))
            stepCardStack.addArrangedSubview(makeSecondaryLabel("Semester split option is available only for high school profiles.", style: .footnote, alignment: .left))
        }

        stepCardStack.addArrangedSubview(makeSecondaryLabel(viewModel.setupDescription, style: .footnote, alignment: .left))

        let termField = makeTextField(
            placeholder: viewModel.isSemesterModeEnabled ? "School year name" : "Term name",
            text: viewModel.termName
        )
        termField.accessibilityIdentifier = AccessibilityID.Onboarding.termNameField
        termField.addAction(UIAction { [weak self, weak termField] _ in
            self?.viewModel.termName = termField?.text ?? ""
            self?.primaryButton.isEnabled = self?.viewModel.canContinue ?? false
        }, for: .editingChanged)
        stepCardStack.addArrangedSubview(termField)

        let startPicker = UIDatePicker()
        startPicker.datePickerMode = .date
        startPicker.preferredDatePickerStyle = .compact
        startPicker.date = viewModel.termStartDate
        startPicker.addAction(UIAction { [weak self, weak startPicker] _ in
            guard let self, let startPicker else { return }
            self.viewModel.termStartDate = startPicker.date
            if self.viewModel.isSemesterModeEnabled {
                self.viewModel.syncDatesForSelectedSetup()
            }
            self.render()
        }, for: .valueChanged)
        stepCardStack.addArrangedSubview(labeledControl(viewModel.isSemesterModeEnabled ? "Semester 1 start date" : "Start date", control: startPicker))

        if !viewModel.isSemesterModeEnabled {
            let endPicker = UIDatePicker()
            endPicker.datePickerMode = .date
            endPicker.preferredDatePickerStyle = .compact
            endPicker.date = viewModel.termEndDate
            endPicker.addAction(UIAction { [weak self, weak endPicker] _ in
                guard let self, let endPicker else { return }
                self.viewModel.termEndDate = endPicker.date
                self.primaryButton.isEnabled = self.viewModel.canContinue
                self.render()
            }, for: .valueChanged)
            stepCardStack.addArrangedSubview(labeledControl("End date", control: endPicker))

            if viewModel.termStartDate > viewModel.termEndDate {
                let warning = makeLabel("End date must be on or after start date.", style: .footnote, weight: .regular, alignment: .left)
                warning.textColor = UIColor(AppTheme.warning)
                stepCardStack.addArrangedSubview(warning)
            }
        } else {
            stepCardStack.addArrangedSubview(makeSecondaryLabel("Each semester is 6 months. Adjust break weeks for your local schedule.", style: .footnote, alignment: .left))
        }
    }

    private func buildCourseStep() {
        stepCardStack.addArrangedSubview(makeSecondaryLabel("Add your first course now, or skip.", style: .subheadline, alignment: .left))

        let addRow = UIStackView(arrangedSubviews: [makeLabel("Add first course now", style: .body, weight: .regular, alignment: .left), UIView()])
        addRow.axis = .horizontal
        addRow.spacing = 8

        let addSwitch = UISwitch()
        addSwitch.isOn = viewModel.addInitialCourse
        addSwitch.accessibilityIdentifier = AccessibilityID.Onboarding.addCourseToggle
        addSwitch.addAction(UIAction { [weak self, weak addSwitch] _ in
            guard let self, let addSwitch else { return }
            self.viewModel.addInitialCourse = addSwitch.isOn
            self.render()
        }, for: .valueChanged)
        addRow.addArrangedSubview(addSwitch)
        stepCardStack.addArrangedSubview(addRow)

        guard viewModel.addInitialCourse else { return }

        let courseNameField = makeTextField(placeholder: "Course name", text: viewModel.courseName)
        courseNameField.accessibilityIdentifier = AccessibilityID.Onboarding.courseNameField
        courseNameField.addAction(UIAction { [weak self, weak courseNameField] _ in
            self?.viewModel.courseName = courseNameField?.text ?? ""
            self?.primaryButton.isEnabled = self?.viewModel.canContinue ?? false
        }, for: .editingChanged)

        let courseCodeField = makeTextField(placeholder: "Course code", text: viewModel.courseCode)
        courseCodeField.addAction(UIAction { [weak self, weak courseCodeField] _ in
            self?.viewModel.courseCode = courseCodeField?.text ?? ""
        }, for: .editingChanged)

        let locationField = makeTextField(placeholder: "Location", text: viewModel.courseLocation)
        locationField.addAction(UIAction { [weak self, weak locationField] _ in
            self?.viewModel.courseLocation = locationField?.text ?? ""
        }, for: .editingChanged)

        stepCardStack.addArrangedSubview(courseNameField)
        stepCardStack.addArrangedSubview(courseCodeField)
        stepCardStack.addArrangedSubview(locationField)

        let startPicker = UIDatePicker()
        startPicker.datePickerMode = .time
        startPicker.preferredDatePickerStyle = .compact
        startPicker.date = viewModel.courseStartTime
        startPicker.addAction(UIAction { [weak self, weak startPicker] _ in
            self?.viewModel.courseStartTime = startPicker?.date ?? Date()
        }, for: .valueChanged)

        let endPicker = UIDatePicker()
        endPicker.datePickerMode = .time
        endPicker.preferredDatePickerStyle = .compact
        endPicker.date = viewModel.courseEndTime
        endPicker.addAction(UIAction { [weak self, weak endPicker] _ in
            self?.viewModel.courseEndTime = endPicker?.date ?? Date()
        }, for: .valueChanged)

        stepCardStack.addArrangedSubview(labeledControl("Start time", control: startPicker))
        stepCardStack.addArrangedSubview(labeledControl("End time", control: endPicker))

        let dayStack = UIStackView()
        dayStack.axis = .horizontal
        dayStack.spacing = 6
        dayStack.distribution = .fillEqually

        for day in Weekday.allCases {
            let selected = WeekdayBitmask.contains(day, in: viewModel.courseMeetingDaysBitmask)
            var config = UIButton.Configuration.bordered()
            config.title = day.shortLabel
            let button = UIButton(configuration: config)
            button.tintColor = selected ? UIColor(AppTheme.accent) : .systemGray3
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.viewModel.courseMeetingDaysBitmask = WeekdayBitmask.toggle(day, in: self.viewModel.courseMeetingDaysBitmask)
                self.render()
            }, for: .touchUpInside)
            dayStack.addArrangedSubview(button)
        }

        stepCardStack.addArrangedSubview(makeLabel("Meeting days", style: .subheadline, weight: .semibold, alignment: .left))
        stepCardStack.addArrangedSubview(dayStack)
    }

    private func buildPreferencesStep() {
        stepCardStack.addArrangedSubview(makeSecondaryLabel("Set reminder defaults.", style: .subheadline, alignment: .left))

        let reminderRow = UIStackView(arrangedSubviews: [makeLabel("Reminder lead time", style: .body, weight: .regular, alignment: .left), UIView()])
        reminderRow.axis = .horizontal
        reminderRow.spacing = 8

        let valueLabel = makeLabel("\(viewModel.defaultReminderLeadHours)h", style: .body, weight: .semibold, alignment: .right)
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.maximumValue = 72
        stepper.value = Double(viewModel.defaultReminderLeadHours)
        stepper.addAction(UIAction { [weak self] action in
            guard let self, let stepper = action.sender as? UIStepper else { return }
            self.viewModel.defaultReminderLeadHours = Int(stepper.value)
            self.render()
        }, for: .valueChanged)

        let right = UIStackView(arrangedSubviews: [valueLabel, stepper])
        right.axis = .horizontal
        right.spacing = 8
        reminderRow.addArrangedSubview(right)

        stepCardStack.addArrangedSubview(reminderRow)

        stepCardStack.addArrangedSubview(makeSecondaryLabel("Level: \(viewModel.studentLevel.displayName)", style: .footnote, alignment: .left))
        stepCardStack.addArrangedSubview(makeSecondaryLabel("Term: \(viewModel.termName)", style: .footnote, alignment: .left))
        stepCardStack.addArrangedSubview(makeSecondaryLabel("Setup: \(viewModel.setupDescription)", style: .footnote, alignment: .left))
    }

    @objc
    private func didTapBack() {
        goBack()
    }

    @objc
    private func didTapPrimary() {
        if viewModel.isLastStep {
            completeOnboardingNow()
        } else {
            goForward()
        }
    }

    @objc
    private func didTapSkip() {
        completeOnboardingNow()
    }

    @objc
    private func handleSwipeLeft() {
        if viewModel.step == .welcome {
            goForward()
        } else if viewModel.isLastStep {
            completeOnboardingNow()
        } else {
            goForward()
        }
    }

    @objc
    private func handleSwipeRight() {
        goBack()
    }

    private func goForward() {
        guard viewModel.canContinue else { return }
        viewModel.goForward()
        render()
    }

    private func goBack() {
        guard !viewModel.isFirstStep else { return }
        viewModel.goBack()
        render()
    }

    private func completeOnboardingNow() {
        viewModel.completeOnboardingForSimulatorSkip(using: modelContext)
    }

    private var currentStepTitle: String {
        switch viewModel.step {
        case .welcome:
            return "Welcome"
        case .profile:
            return "Profile"
        case .term:
            return "Active term"
        case .course:
            return "Course (optional)"
        case .preferences:
            return "Preferences"
        }
    }

    private var stepExplanationTitle: String {
        switch viewModel.step {
        case .welcome:
            return "Let's get started"
        case .profile:
            return "Start with identity"
        case .term:
            return "Build your timeline"
        case .course:
            return "Attach tasks to classes"
        case .preferences:
            return "Tune reminders"
        }
    }

    private var stepExplanationBody: String {
        switch viewModel.step {
        case .welcome:
            return "Tap to begin and we will walk through each setup step."
        case .profile:
            return "Your name and school level personalize defaults and make the dashboard greeting feel personal."
        case .term:
            return "Your active term controls which classes and deadlines appear first. If you enable semester split, the app automatically creates both 6-month terms."
        case .course:
            return "Courses help group tasks, show clearer priorities, and keep your schedule organized. You can skip now and add courses anytime."
        case .preferences:
            return "Reminder lead time sets how early you get deadline alerts. You can always edit this later in Settings."
        }
    }

    private func makeTextField(placeholder: String, text: String) -> UITextField {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = placeholder
        field.text = text
        return field
    }

    private func labeledControl(_ title: String, control: UIView) -> UIView {
        let label = makeLabel(title, style: .body, weight: .regular, alignment: .left)
        let row = UIStackView(arrangedSubviews: [label, UIView(), control])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    private func featureRow(_ symbol: String, _ text: String) -> UIView {
        let icon = makeIcon(symbol, tint: .accent)
        let label = makeLabel(text, style: .subheadline, weight: .regular, alignment: .left)
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        return row
    }

    private func makeIcon(_ symbol: String, tint: UIColor, size: CGFloat = 14, padded: Bool = false) -> UIView {
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = tint.withAlphaComponent(0.12)
        container.layer.cornerRadius = padded ? 20 : 7

        container.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: size),
            icon.heightAnchor.constraint(equalToConstant: size),
            container.widthAnchor.constraint(equalToConstant: padded ? 40 : 24),
            container.heightAnchor.constraint(equalToConstant: padded ? 40 : 24)
        ])
        return container
    }

    private func makeCardView(content: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.secondarySystemGroupedBackground
        card.layer.cornerRadius = 12

        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        return card
    }

    private func makeLabel(_ text: String, style: UIFont.TextStyle, weight: UIFont.Weight, alignment: NSTextAlignment) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .label
        label.font = UIFont.preferredFont(forTextStyle: style).withWeight(weight)
        label.numberOfLines = 0
        label.textAlignment = alignment
        return label
    }

    private func makeSecondaryLabel(_ text: String, style: UIFont.TextStyle, alignment: NSTextAlignment) -> UILabel {
        let label = makeLabel(text, style: style, weight: .regular, alignment: alignment)
        label.textColor = .secondaryLabel
        return label
    }

    private func clearStack(_ stack: UIStackView) {
        stack.arrangedSubviews.forEach { view in
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

private extension UIColor {
    static let accent = UIColor(AppTheme.accent)
}
