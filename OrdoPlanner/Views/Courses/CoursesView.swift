//
//  CoursesView.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftData
import SwiftUI

struct CoursesView: View {
    private struct TimelineItem: Identifiable {
        let id: String
        let course: Course
        let weekday: Weekday?
        let startsAt: Date
    }

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Course.name) private var courses: [Course]
    @Query(filter: #Predicate<AcademicTerm> { $0.isActive }, sort: \AcademicTerm.startDate)
    private var activeTerms: [AcademicTerm]

    @StateObject private var viewModel = CoursesViewModel()
    @State private var draft = CourseEditorView.Draft()
    @State private var selectedWeekday: Weekday?
    @AppStorage(AppPreferences.timelineSelectedWeekdayKey) private var persistedSelectedWeekdayRaw = -1
    @AppStorage(AppPreferences.compactCardsEnabledKey) private var compactCardsEnabled = false
    @AppStorage(AppPreferences.showCourseCodesKey) private var showCourseCodes = true

    let defaultStudentLevel: StudentLevel

    var body: some View {
        NavigationStack {
            Group {
                if visibleTimelineItems.isEmpty {
                    ContentUnavailableView("No Courses", systemImage: "calendar", description: Text("Add courses to build your timeline."))
                } else {
                    ScrollView {
                        VStack(spacing: compactCardsEnabled ? 8 : 10) {
                            summaryStrip

                            ForEach(Array(visibleTimelineItems.enumerated()), id: \.element.id) { index, item in
                                timelineRow(item: item, isLast: index == visibleTimelineItems.count - 1)
                            }
                        }
                        .padding(AppTheme.screenPadding)
                    }
                    .background(AppTheme.screenBackground)
                }
            }
            .navigationTitle("Timeline")
            .safeAreaInset(edge: .top, spacing: 0) {
                weekdayFilterStrip
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                    .background(.ultraThinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startCreating()
                    } label: {
                        Label("Add Course", systemImage: "plus")
                    }
                    .accessibilityIdentifier(AccessibilityID.Courses.addButton)
                }
            }
            .sheet(isPresented: $viewModel.showingEditor) {
                CourseEditorView(
                    title: viewModel.editingCourse == nil ? "New Course" : "Edit Course",
                    draft: $draft,
                    onSave: saveCourse
                )
            }
            .onAppear {
                hydrateSelectedWeekdayIfNeeded()
                setSmartInitialDayIfNeeded()
            }
            .onChange(of: selectedWeekday) { _, newValue in
                // Persist selected timeline day to keep continuity across launches.
                persistedSelectedWeekdayRaw = newValue?.rawValue ?? -1
            }
            .onChange(of: courses.count) { _, _ in
                // Re-evaluate default day when schedule data changes.
                setSmartInitialDayIfNeeded()
            }
        }
    }

    private var timelineItems: [TimelineItem] {
        courses
            .flatMap { course -> [TimelineItem] in
                let days = WeekdayBitmask.days(from: course.meetingDaysBitmask)
                let activeDays = days.isEmpty ? [nil] : days.map(Optional.some)

                return activeDays.map { day in
                    let startsAt = dayStartDate(for: day, timeSource: course.startTime)
                    let dayPart = day.map { String($0.rawValue) } ?? "unscheduled"
                    return TimelineItem(id: "\(course.id.uuidString)-\(dayPart)", course: course, weekday: day, startsAt: startsAt)
                }
            }
            .sorted { lhs, rhs in
                if lhs.startsAt != rhs.startsAt { return lhs.startsAt < rhs.startsAt }
                return lhs.course.name < rhs.course.name
            }
    }

    private var visibleTimelineItems: [TimelineItem] {
        guard let selectedWeekday else {
            return timelineItems
        }
        return timelineItems.filter { $0.weekday == selectedWeekday }
    }

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            summaryPill(title: "Visible", value: "\(visibleTimelineItems.count)")
            summaryPill(title: "This Week", value: weeklyHoursText)
            summaryPill(title: "Term", value: activeTerms.first?.name ?? "None")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .plannerSurfaceCard(padding: 0, cornerRadius: 18)
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weekdayFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                weekdayChip(title: "All", selected: selectedWeekday == nil) {
                    setSelectedWeekday(nil)
                }

                weekdayChip(title: "Today", selected: selectedWeekday == currentWeekday()) {
                    setSelectedWeekday(currentWeekday())
                }

                ForEach(Weekday.allCases) { weekday in
                    weekdayChip(title: dayTitle(weekday), selected: selectedWeekday == weekday) {
                        setSelectedWeekday(weekday)
                    }
                }
            }
        }
    }

    private func weekdayChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(selected ? AppTheme.accent.opacity(0.16) : Color.secondary.opacity(0.12))
                .foregroundStyle(selected ? AppTheme.accent : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func setSelectedWeekday(_ weekday: Weekday?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedWeekday = weekday
        }
    }

    private func hydrateSelectedWeekdayIfNeeded() {
        guard selectedWeekday == nil else { return }
        selectedWeekday = Weekday(rawValue: persistedSelectedWeekdayRaw)
    }

    private func setSmartInitialDayIfNeeded() {
        guard !timelineItems.isEmpty else {
            selectedWeekday = nil
            return
        }

        // Keep existing selection if it still maps to at least one row.
        if let selectedWeekday,
           timelineItems.contains(where: { $0.weekday == selectedWeekday }) {
            return
        }

        let availableDays = Set(timelineItems.compactMap(\.weekday))
        guard !availableDays.isEmpty else {
            selectedWeekday = nil
            return
        }

        let today = currentWeekday()
        if availableDays.contains(today) {
            selectedWeekday = today
            return
        }

        // If today has no classes, jump to the next nearest scheduled day.
        let next = availableDays.min { lhs, rhs in
            weekdayDistance(from: today, to: lhs) < weekdayDistance(from: today, to: rhs)
        }
        selectedWeekday = next
    }

    private func weekdayDistance(from start: Weekday, to target: Weekday) -> Int {
        (target.rawValue - start.rawValue + 7) % 7
    }

    private func currentWeekday() -> Weekday {
        switch Calendar.current.component(.weekday, from: Date()) {
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }

    private var weeklyHoursText: String {
        let courseIDs = Set(visibleTimelineItems.map { $0.course.id })
        let total = courses
            .filter { courseIDs.contains($0.id) }
            .reduce(0.0) { partial, course in
                partial + max(0, course.endTime.timeIntervalSince(course.startTime))
            }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: total) ?? "0m"
    }

    @ViewBuilder
    private func timelineRow(item: TimelineItem, isLast: Bool) -> some View {
        let markerSize: CGFloat = compactCardsEnabled ? 38 : 46
        let symbolSize: CGFloat = compactCardsEnabled ? 16 : 20
        let lineWidth: CGFloat = compactCardsEnabled ? 3 : 4
        let titleSize: CGFloat = compactCardsEnabled ? 20 : 24
        let detailSize: CGFloat = compactCardsEnabled ? 15 : 17
        let metaSize: CGFloat = compactCardsEnabled ? 13 : 14
        let cardPadding: CGFloat = compactCardsEnabled ? 10 : AppTheme.cardPadding
        let cornerRadius: CGFloat = compactCardsEnabled ? 18 : AppTheme.cardCornerRadius

        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(hex: item.course.colorHex))
                    .frame(width: markerSize, height: markerSize)
                    .overlay {
                        Image(systemName: courseSymbol(for: item.course))
                            .font(.system(size: symbolSize, weight: .regular))
                            .foregroundStyle(.white)
                    }

                if !isLast {
                    Rectangle()
                        .fill(Color(hex: item.course.colorHex).opacity(0.45))
                        .frame(width: lineWidth)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: markerSize)

            VStack(alignment: .leading, spacing: 10) {
                Text(item.course.name)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(Color(hex: item.course.colorHex))

                Text(timeLineText(for: item.course))
                    .font(.system(size: detailSize, weight: .semibold))
                    .foregroundStyle(Color(hex: item.course.colorHex).opacity(0.95))

                Text(locationLineText(for: item))
                    .font(.system(size: detailSize - 2, weight: .regular))
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    if let weekday = item.weekday {
                        Text(dayTitle(weekday))
                            .font(.system(size: metaSize, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Unscheduled")
                            .font(.system(size: metaSize, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        startEditing(item.course)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 22, weight: .semibold))
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        deleteCourse(item.course)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 22, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                }
            }
            .plannerSurfaceCard(padding: cardPadding, cornerRadius: cornerRadius)
        }
        .padding(.vertical, 2)
    }

    private func dayStartDate(for day: Weekday?, timeSource: Date) -> Date {
        let order = day?.rawValue ?? 7
        let base = Calendar.current.startOfDay(for: Date())
        let dayOffset = Calendar.current.date(byAdding: .day, value: order, to: base) ?? base

        let components = Calendar.current.dateComponents([.hour, .minute], from: timeSource)
        var dayComponents = Calendar.current.dateComponents([.year, .month, .day], from: dayOffset)
        dayComponents.hour = components.hour
        dayComponents.minute = components.minute
        dayComponents.second = 0
        return Calendar.current.date(from: dayComponents) ?? dayOffset
    }

    private func dayTitle(_ day: Weekday) -> String {
        switch day {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }

    private func timeLineText(for course: Course) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: course.startTime)) - \(formatter.string(from: course.endTime))"
    }

    private func locationLineText(for item: TimelineItem) -> String {
        let location = item.course.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = showCourseCodes ? item.course.code.trimmingCharacters(in: .whitespacesAndNewlines) : ""

        if !location.isEmpty && !code.isEmpty { return "\(code)  ·  \(location)" }
        if !location.isEmpty { return location }
        if !code.isEmpty { return code }
        return "No location"
    }

    private func courseSymbol(for course: Course) -> String {
        let text = "\(course.name) \(course.code)".lowercased()
        if text.contains("physics") { return "atom" }
        if text.contains("history") { return "book.closed" }
        if text.contains("english") { return "textformat.abc" }
        if text.contains("math") { return "function" }
        if text.contains("bio") { return "leaf" }
        return "briefcase"
    }

    private func startCreating() {
        draft = CourseEditorView.Draft(studentLevel: defaultStudentLevel)
        viewModel.startCreating()
    }

    private func startEditing(_ course: Course) {
        draft = CourseEditorView.Draft(
            name: course.name,
            code: course.code,
            colorHex: course.colorHex,
            studentLevel: course.studentLevel,
            meetingDaysBitmask: course.meetingDaysBitmask,
            startTime: course.startTime,
            endTime: course.endTime,
            location: course.location
        )
        viewModel.startEditing(course)
    }

    private func saveCourse() {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let course = viewModel.editingCourse {
            course.name = trimmedName
            course.code = draft.code.trimmingCharacters(in: .whitespacesAndNewlines)
            course.colorHex = draft.colorHex
            course.studentLevel = draft.studentLevel
            course.meetingDaysBitmask = draft.meetingDaysBitmask
            course.startTime = draft.startTime
            course.endTime = draft.endTime
            course.location = draft.location.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let activeTerm = activeTerms.first
            let newCourse = Course(
                name: trimmedName,
                code: draft.code.trimmingCharacters(in: .whitespacesAndNewlines),
                colorHex: draft.colorHex,
                studentLevel: draft.studentLevel,
                meetingDaysBitmask: draft.meetingDaysBitmask,
                startTime: draft.startTime,
                endTime: draft.endTime,
                location: draft.location.trimmingCharacters(in: .whitespacesAndNewlines),
                term: activeTerm
            )
            newCourse.termID = activeTerm?.id
            modelContext.insert(newCourse)
        }

        try? modelContext.save()
    }

    private func deleteCourse(_ course: Course) {
        modelContext.delete(course)
        try? modelContext.save()
    }
}

private extension CourseEditorView.Draft {
    init(studentLevel: StudentLevel) {
        self.init()
        self.studentLevel = studentLevel
    }
}
