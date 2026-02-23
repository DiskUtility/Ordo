import SwiftData
import SwiftUI

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var moveForward = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    pageIndicators

                    if viewModel.step != .welcome {
                        stepHeader
                        stepExplanationCard
                    }

                    stepContent
                        .id(viewModel.step.rawValue)
                        .transition(stepTransition)
                        .contentShape(Rectangle())
                        .gesture(stepSwipeGesture)
                        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: viewModel.step)
                }
                .padding()
                .padding(.bottom, viewModel.step == .welcome ? 24 : 92)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if viewModel.step != .welcome {
                    VStack(spacing: 10) {
                        swipeHintBar
                        navigationButtons
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .overlay(alignment: .top) {
                        Divider()
                    }
                }
            }
            .navigationTitle("Onboarding")
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .welcome:
            welcomeStep
        case .profile:
            profileStep.plannerCard()
        case .term:
            termStep.plannerCard()
        case .course:
            courseStep.plannerCard()
        case .preferences:
            preferencesStep.plannerCard()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(12)
                    .background(AppTheme.accent.opacity(0.14))
                    .clipShape(Circle())

                Text("Welcome to Planner")
                    .font(.title2.weight(.semibold))

                Text("A clean setup for classes, tasks, and reminders.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            }

            appExplainSection

            Button("Tap to begin") {
                goForward()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(AccessibilityID.Onboarding.beginButton)

            #if targetEnvironment(simulator)
            Button("Skip Onboarding") {
                completeOnboardingNow()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier(AccessibilityID.Onboarding.skipSimulatorButton)
            #endif
        }
        .plannerCard()
    }

    private var appExplainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What this app helps with")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            onboardingFeatureRow(symbol: "calendar", title: "Plan your classes and term dates")
            onboardingFeatureRow(symbol: "checklist", title: "Track assignments and due dates")
            onboardingFeatureRow(symbol: "bell.badge", title: "Get reminders before deadlines")
        }
        .plannerCard()
    }

    private func onboardingFeatureRow(symbol: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24, height: 24)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private var swipeHintBar: some View {
        Text(viewModel.isLastStep ? "Swipe left to finish setup. Swipe right to review." : "Swipe left to continue. Swipe right to go back.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var navigationButtons: some View {
        HStack {
            if !viewModel.isFirstStep {
                Button("Back") {
                    goBack()
                }
                .accessibilityIdentifier(AccessibilityID.Onboarding.backButton)
            } else {
                Spacer()
            }

            Spacer()

            #if targetEnvironment(simulator)
            Button("Skip") {
                completeOnboardingNow()
            }
            .accessibilityIdentifier(AccessibilityID.Onboarding.skipSimulatorButton)

            Spacer(minLength: 12)
            #endif

            if viewModel.isLastStep {
                Button("Finish") {
                    completeOnboardingNow()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canContinue)
                .accessibilityIdentifier(AccessibilityID.Onboarding.finishButton)
            } else {
                Button("Next") {
                    goForward()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canContinue)
                .accessibilityIdentifier(AccessibilityID.Onboarding.nextButton)
            }
        }
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step == viewModel.step ? AppTheme.accent : Color.secondary.opacity(0.25))
                    .frame(width: step == viewModel.step ? 22 : 8, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.step)
            }
        }
    }

    private var stepHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: currentStepSymbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24, height: 24)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(currentStepTitle)
                    .font(.headline.weight(.semibold))
                Text("Step \(viewModel.step.rawValue + 1) of \(OnboardingViewModel.Step.allCases.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 2)
    }

    private var stepExplanationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(AppTheme.accent)
                Text(stepExplanationTitle)
                    .font(.subheadline.weight(.semibold))
            }

            Text(stepExplanationBody)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .plannerCard()
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

    private var currentStepSymbol: String {
        switch viewModel.step {
        case .welcome:
            return "sparkles"
        case .profile:
            return "person.crop.circle"
        case .term:
            return "calendar.badge.clock"
        case .course:
            return "books.vertical"
        case .preferences:
            return "slider.horizontal.3"
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

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: moveForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: moveForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var stepSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) else { return }

                if horizontal < -60 {
                    if viewModel.isLastStep {
                        completeOnboardingNow()
                    } else {
                        goForward()
                    }
                } else if horizontal > 60 {
                    goBack()
                }
            }
    }

    private func goForward() {
        moveForward = true
        withAnimation {
            viewModel.goForward()
        }
    }

    private func goBack() {
        moveForward = false
        withAnimation {
            viewModel.goBack()
        }
    }

    private func completeOnboardingNow() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            viewModel.completeOnboardingForSimulatorSkip(using: modelContext)
        }
    }

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tell us about you.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            TextField("Name (optional)", text: $viewModel.displayName)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(AccessibilityID.Onboarding.nameField)

            Picker("Student level", selection: $viewModel.studentLevel) {
                ForEach(StudentLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.studentLevel) {
                viewModel.enforceCompatibleSetup()
            }
        }
    }

    private var termStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set your active term details.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Semester option")
                    .font(.subheadline.weight(.medium))

                if viewModel.supportsSemesterSplitOption {
                    Toggle("Split into 2 semesters (6 months + 6 months)", isOn: $viewModel.isSemesterModeEnabled)
                        .onChange(of: viewModel.isSemesterModeEnabled) {
                            viewModel.syncDatesForSelectedSetup()
                        }

                    if viewModel.isSemesterModeEnabled {
                        Stepper(value: $viewModel.semesterBreakWeeks, in: 0...8) {
                            Text("Break between semesters: \(viewModel.semesterBreakWeeks) week(s)")
                        }
                        .onChange(of: viewModel.semesterBreakWeeks) {
                            viewModel.syncDatesForSelectedSetup()
                        }
                    }
                } else {
                    Text("Single Term")
                        .font(.body.weight(.medium))
                    Text("Semester split option is available only for high school profiles.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(viewModel.setupDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            TextField(viewModel.isSemesterModeEnabled ? "School year name" : "Term name", text: $viewModel.termName)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(AccessibilityID.Onboarding.termNameField)

            DatePicker(
                viewModel.isSemesterModeEnabled ? "Semester 1 start date" : "Start date",
                selection: $viewModel.termStartDate,
                displayedComponents: .date
            )
            .onChange(of: viewModel.termStartDate) {
                if viewModel.isSemesterModeEnabled {
                    viewModel.syncDatesForSelectedSetup()
                }
            }

            if !viewModel.isSemesterModeEnabled {
                DatePicker("End date", selection: $viewModel.termEndDate, displayedComponents: .date)
            } else {
                Text("Each semester is 6 months. Adjust break weeks for your local schedule.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.isSemesterModeEnabled, viewModel.termStartDate > viewModel.termEndDate {
                Text("End date must be on or after start date.")
                    .foregroundStyle(AppTheme.warning)
                    .font(.footnote)
            }
        }
    }

    private var courseStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add your first course now, or skip.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Toggle("Add first course now", isOn: $viewModel.addInitialCourse)
                .accessibilityIdentifier(AccessibilityID.Onboarding.addCourseToggle)

            if viewModel.addInitialCourse {
                TextField("Course name", text: $viewModel.courseName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(AccessibilityID.Onboarding.courseNameField)

                TextField("Course code", text: $viewModel.courseCode)
                    .textFieldStyle(.roundedBorder)

                TextField("Location", text: $viewModel.courseLocation)
                    .textFieldStyle(.roundedBorder)

                DatePicker("Start time", selection: $viewModel.courseStartTime, displayedComponents: .hourAndMinute)
                DatePicker("End time", selection: $viewModel.courseEndTime, displayedComponents: .hourAndMinute)

                VStack(alignment: .leading) {
                    Text("Meeting days")
                        .font(.subheadline.weight(.medium))

                    HStack {
                        ForEach(Weekday.allCases) { day in
                            let selected = WeekdayBitmask.contains(day, in: viewModel.courseMeetingDaysBitmask)
                            Button(day.shortLabel) {
                                viewModel.courseMeetingDaysBitmask = WeekdayBitmask.toggle(day, in: viewModel.courseMeetingDaysBitmask)
                            }
                            .buttonStyle(.bordered)
                            .tint(selected ? AppTheme.accent : .gray)
                        }
                    }
                }
            }
        }
    }

    private var preferencesStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set reminder defaults.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text("Set how early you want deadline reminders.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Stepper(value: $viewModel.defaultReminderLeadHours, in: 1...72) {
                Text("Reminder lead time: \(viewModel.defaultReminderLeadHours) hours")
                    .font(.body.weight(.medium))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Setup summary")
                    .font(.subheadline.weight(.medium))
                Text("Level: \(viewModel.studentLevel.displayName)")
                Text("Term: \(viewModel.termName)")
                Text("Setup: \(viewModel.setupDescription)")
                Text(viewModel.addInitialCourse ? "First course will be added." : "You can add courses later.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
