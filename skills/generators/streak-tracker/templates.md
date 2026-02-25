# Streak Tracker Code Templates

Production-ready Swift templates for a streak tracking system. All code targets iOS 17+ / macOS 14+ and uses @Observable, SwiftData, and modern Swift concurrency.

## StreakRecord.swift

```swift
import SwiftData
import Foundation

/// A single recorded activity for streak tracking.
///
/// Each record represents one day of activity for a given type.
/// Dates are normalized to start-of-day for consistent comparison.
@Model
final class StreakRecord {
    /// The calendar day this activity belongs to (normalized to start of day).
    var activityDate: Date

    /// The type of activity (e.g., "workout", "lesson", "daily-check-in").
    /// Allows tracking multiple independent streaks.
    var activityType: String

    /// The exact timestamp when the activity was recorded.
    /// Preserved for debugging and clock-manipulation detection.
    var createdAt: Date

    /// Unique constraint: one record per (activityDate, activityType).
    #Unique<StreakRecord>([\.activityDate, \.activityType])

    init(activityType: String, date: Date = .now, calendar: Calendar = .current) {
        self.activityDate = calendar.startOfDay(for: date)
        self.activityType = activityType
        self.createdAt = .now
    }

    /// Check if this record is for the same calendar day as the given date.
    func isSameDay(as date: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(activityDate, inSameDayAs: date)
    }

    /// Number of calendar days between this record's date and another date.
    func daysBetween(_ date: Date, calendar: Calendar = .current) -> Int {
        let startOfOther = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: activityDate, to: startOfOther)
        return abs(components.day ?? 0)
    }
}
```

## StreakError.swift

```swift
import Foundation

/// Errors that can occur during streak operations.
enum StreakError: Error, LocalizedError {
    /// Failed to save the activity record.
    case saveFailed(underlying: Error)

    /// Activity for this type already recorded today (not a real error — idempotent).
    case alreadyRecordedToday(activityType: String)

    /// No streak freezes available.
    case noFreezesAvailable

    /// No gap to apply a freeze to (streak is unbroken).
    case noGapToFreeze

    /// The model context is unavailable.
    case modelContextUnavailable

    var errorDescription: String? {
        switch self {
        case .saveFailed(let underlying):
            return "Failed to save streak record: \(underlying.localizedDescription)"
        case .alreadyRecordedToday(let type):
            return "Activity '\(type)' already recorded for today"
        case .noFreezesAvailable:
            return "No streak freeze passes available"
        case .noGapToFreeze:
            return "No gap in the streak to apply a freeze to"
        case .modelContextUnavailable:
            return "Model context is not available"
        }
    }
}
```

## StreakManager.swift

```swift
import SwiftData
import Foundation
import Observation

/// Core streak calculation engine.
///
/// Tracks consecutive days of activity, manages streak freezes,
/// and determines streak-at-risk status. Uses `Calendar.current` for
/// timezone-aware day boundary calculations.
///
/// Usage:
/// ```swift
/// let manager = StreakManager(modelContext: context)
/// try await manager.recordActivity(type: "workout")
/// print(manager.currentStreak) // 1
/// ```
@Observable
final class StreakManager {
    // MARK: - Public State

    /// Number of consecutive days in the current streak (including today if active).
    private(set) var currentStreak: Int = 0

    /// All-time longest streak.
    private(set) var longestStreak: Int = 0

    /// True if the user has not recorded activity today and has an active streak.
    private(set) var isStreakAtRisk: Bool = false

    /// True if activity has been recorded today.
    private(set) var hasActivityToday: Bool = false

    /// Number of available streak freeze passes.
    private(set) var availableFreezes: Int = 0

    /// Timestamp of the last data refresh.
    private(set) var lastRefreshed: Date?

    // MARK: - Private

    private let modelContext: ModelContext
    private let calendar: Calendar

    // MARK: - Init

    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    // MARK: - Record Activity

    /// Record an activity for the given type and date.
    ///
    /// Idempotent: calling multiple times on the same calendar day
    /// for the same type creates only one record.
    ///
    /// - Parameters:
    ///   - type: The activity type identifier (default: "default").
    ///   - date: The date to record activity for (default: now).
    @discardableResult
    func recordActivity(type: String = "default", date: Date = .now) async throws -> StreakRecord {
        let startOfDay = calendar.startOfDay(for: date)

        // Check for existing record on this day for this type
        let descriptor = FetchDescriptor<StreakRecord>(
            predicate: #Predicate<StreakRecord> { record in
                record.activityDate == startOfDay && record.activityType == type
            }
        )

        let existing = try modelContext.fetch(descriptor)
        if let existingRecord = existing.first {
            return existingRecord
        }

        // Create new record
        let record = StreakRecord(activityType: type, date: date, calendar: calendar)
        modelContext.insert(record)

        do {
            try modelContext.save()
        } catch {
            throw StreakError.saveFailed(underlying: error)
        }

        await refresh()
        return record
    }

    // MARK: - Refresh / Calculate

    /// Recalculate all streak values from stored records.
    func refresh(for activityType: String = "default") async {
        let descriptor = FetchDescriptor<StreakRecord>(
            predicate: #Predicate<StreakRecord> { record in
                record.activityType == activityType
            },
            sortBy: [SortDescriptor(\.activityDate, order: .reverse)]
        )

        guard let records = try? modelContext.fetch(descriptor) else {
            currentStreak = 0
            longestStreak = 0
            isStreakAtRisk = false
            hasActivityToday = false
            lastRefreshed = .now
            return
        }

        // Get unique days sorted descending
        let uniqueDays = uniqueSortedDays(from: records)

        // Load freezes
        let freezeDescriptor = FetchDescriptor<StreakFreeze>(
            predicate: #Predicate<StreakFreeze> { freeze in
                freeze.isUsed == true
            }
        )
        let usedFreezes = (try? modelContext.fetch(freezeDescriptor)) ?? []
        let frozenDays = Set(usedFreezes.map { calendar.startOfDay(for: $0.appliedDate ?? .distantPast) })

        // Calculate current streak
        currentStreak = calculateCurrentStreak(uniqueDays: uniqueDays, frozenDays: frozenDays)

        // Calculate longest streak
        longestStreak = calculateLongestStreak(uniqueDays: uniqueDays, frozenDays: frozenDays)

        // Check today's activity
        let today = calendar.startOfDay(for: .now)
        hasActivityToday = uniqueDays.contains(today)
        isStreakAtRisk = !hasActivityToday && currentStreak > 0

        // Update available freezes
        let availableDescriptor = FetchDescriptor<StreakFreeze>(
            predicate: #Predicate<StreakFreeze> { freeze in
                freeze.isUsed == false
            }
        )
        availableFreezes = (try? modelContext.fetchCount(availableDescriptor)) ?? 0

        lastRefreshed = .now
    }

    // MARK: - Streak Freeze

    /// Add streak freeze passes.
    func addStreakFreeze(count: Int = 1) {
        for _ in 0..<count {
            let freeze = StreakFreeze()
            modelContext.insert(freeze)
        }
        try? modelContext.save()
        availableFreezes += count
    }

    /// Use a streak freeze to cover yesterday's gap.
    ///
    /// - Returns: `true` if the freeze was successfully applied, `false` otherwise.
    @discardableResult
    func useStreakFreeze() -> Bool {
        // Find an unused freeze
        let descriptor = FetchDescriptor<StreakFreeze>(
            predicate: #Predicate<StreakFreeze> { freeze in
                freeze.isUsed == false
            },
            sortBy: [SortDescriptor(\.grantedAt, order: .forward)]
        )

        guard let freezes = try? modelContext.fetch(descriptor),
              let freeze = freezes.first else {
            return false
        }

        // Apply the freeze to yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now))!
        freeze.use(for: yesterday)

        do {
            try modelContext.save()
            availableFreezes = max(0, availableFreezes - 1)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Query Helpers

    /// Get all activity dates for a given month.
    func activityDates(in month: Date, for activityType: String = "default") -> Set<Date> {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return []
        }

        let descriptor = FetchDescriptor<StreakRecord>(
            predicate: #Predicate<StreakRecord> { record in
                record.activityType == activityType &&
                record.activityDate >= startOfMonth &&
                record.activityDate < endOfMonth
            }
        )

        guard let records = try? modelContext.fetch(descriptor) else { return [] }
        return Set(records.map { calendar.startOfDay(for: $0.activityDate) })
    }

    // MARK: - Private Calculations

    private func uniqueSortedDays(from records: [StreakRecord]) -> [Date] {
        let days = Set(records.map { calendar.startOfDay(for: $0.activityDate) })
        return days.sorted(by: >)
    }

    private func calculateCurrentStreak(uniqueDays: [Date], frozenDays: Set<Date>) -> Int {
        guard !uniqueDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Current streak must include today or yesterday
        guard uniqueDays.first == today || uniqueDays.first == yesterday ||
              frozenDays.contains(today) || frozenDays.contains(yesterday) else {
            // If most recent activity is older than yesterday, streak is broken
            return 0
        }

        var streak = 0
        var checkDate = today

        // Walk backwards day by day
        while true {
            if uniqueDays.contains(checkDate) {
                streak += 1
            } else if frozenDays.contains(checkDate) {
                streak += 1 // Frozen day counts toward streak
            } else if checkDate == today {
                // Today hasn't been recorded yet — skip but continue checking
                // (streak is "at risk" but not broken until end of day)
            } else {
                break // Gap found — streak ends
            }

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        return streak
    }

    private func calculateLongestStreak(uniqueDays: [Date], frozenDays: Set<Date>) -> Int {
        guard !uniqueDays.isEmpty else { return 0 }

        // Combine activity days and frozen days, sorted ascending
        let allDays = uniqueDays.union(frozenDays).sorted()

        var longest = 1
        var current = 1

        for i in 1..<allDays.count {
            let daysBetween = calendar.dateComponents([.day], from: allDays[i - 1], to: allDays[i]).day ?? 0

            if daysBetween == 1 {
                current += 1
                longest = max(longest, current)
            } else if daysBetween > 1 {
                current = 1
            }
            // daysBetween == 0: duplicate day (frozen + activity), skip
        }

        return longest
    }
}

// MARK: - Set Extension for Convenience

private extension Array where Element == Date {
    func union(_ other: Set<Date>) -> Set<Date> {
        var result = Set(self)
        result.formUnion(other)
        return result
    }

    func contains(_ date: Date) -> Bool {
        self.contains(where: { $0 == date })
    }
}
```

## StreakFreeze.swift

```swift
import SwiftData
import Foundation

/// A streak freeze pass that can preserve a streak across a missed day.
///
/// Users receive freeze passes as rewards or purchases. Each freeze
/// covers one missed calendar day, preventing the streak from breaking.
@Model
final class StreakFreeze {
    /// When this freeze pass was granted.
    var grantedAt: Date

    /// Whether this freeze has been used.
    var isUsed: Bool

    /// The date this freeze was applied to (nil if unused).
    var appliedDate: Date?

    /// When this freeze was consumed.
    var usedAt: Date?

    /// Optional cooldown: earliest date this freeze can be used.
    /// Prevents stacking multiple freezes back-to-back.
    var availableAfter: Date?

    init(availableAfter: Date? = nil) {
        self.grantedAt = .now
        self.isUsed = false
        self.appliedDate = nil
        self.usedAt = nil
        self.availableAfter = availableAfter
    }

    /// Mark this freeze as used for the given date.
    func use(for date: Date) {
        isUsed = true
        appliedDate = Calendar.current.startOfDay(for: date)
        usedAt = .now
    }

    /// Whether this freeze is currently available for use.
    var isAvailable: Bool {
        guard !isUsed else { return false }
        if let availableAfter {
            return Date.now >= availableAfter
        }
        return true
    }
}
```

## StreakCalendarView.swift

```swift
import SwiftUI

/// A calendar heat map showing days with and without activity.
///
/// Displays the current month with colored cells for active days,
/// the current streak range highlighted, and navigation between months.
///
/// Usage:
/// ```swift
/// StreakCalendarView(manager: streakManager)
/// ```
struct StreakCalendarView: View {
    let manager: StreakManager
    let activityType: String

    @State private var displayedMonth: Date = .now

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let daySymbols = Calendar.current.shortWeekdaySymbols

    init(manager: StreakManager, activityType: String = "default") {
        self.manager = manager
        self.activityType = activityType
    }

    var body: some View {
        VStack(spacing: 16) {
            monthHeader
            weekdayHeader
            daysGrid
        }
        .padding()
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()

            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)

            Spacer()

            Button {
                withAnimation {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .disabled(calendar.isDate(displayedMonth, equalTo: .now, toGranularity: .month))
        }
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(daySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Days Grid

    private var daysGrid: some View {
        let activityDates = manager.activityDates(in: displayedMonth, for: activityType)
        let days = daysInMonth()
        let today = calendar.startOfDay(for: .now)

        return LazyVGrid(columns: columns, spacing: 8) {
            // Leading empty cells for offset
            ForEach(0..<leadingEmptyCells(), id: \.self) { _ in
                Color.clear
                    .frame(height: 36)
            }

            // Day cells
            ForEach(days, id: \.self) { date in
                let isActive = activityDates.contains(calendar.startOfDay(for: date))
                let isToday = calendar.isDate(date, inSameDayAs: today)
                let isFuture = date > today

                DayCellView(
                    day: calendar.component(.day, from: date),
                    isActive: isActive,
                    isToday: isToday,
                    isFuture: isFuture
                )
            }
        }
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    private func leadingEmptyCells() -> Int {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return 0
        }
        let weekday = calendar.component(.weekday, from: startOfMonth)
        return weekday - calendar.firstWeekday
    }
}

// MARK: - Day Cell

private struct DayCellView: View {
    let day: Int
    let isActive: Bool
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        ZStack {
            if isActive {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green.opacity(0.7))
            } else if isToday {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.primary.opacity(0.3), lineWidth: 1)
            }

            Text("\(day)")
                .font(.callout)
                .foregroundStyle(foregroundColor)
        }
        .frame(height: 36)
    }

    private var foregroundColor: Color {
        if isFuture {
            return .secondary.opacity(0.3)
        } else if isActive {
            return .white
        } else {
            return .primary
        }
    }
}
```

## StreakBadgeView.swift

```swift
import SwiftUI

/// A compact badge showing the current streak count with animation.
///
/// Displays a fire icon with the streak number. Animates with a scale
/// bounce when the streak increments.
///
/// Usage:
/// ```swift
/// StreakBadgeView(streak: manager.currentStreak)
/// StreakBadgeView(streak: manager.currentStreak, style: .expanded)
/// ```
struct StreakBadgeView: View {
    let streak: Int
    var style: BadgeStyle = .compact

    @State private var animateScale: Bool = false

    enum BadgeStyle {
        /// Icon and number only.
        case compact
        /// Icon, number, and "day streak" label.
        case expanded
    }

    var body: some View {
        Group {
            switch style {
            case .compact:
                compactBadge
            case .expanded:
                expandedBadge
            }
        }
        .scaleEffect(animateScale ? 1.2 : 1.0)
        .onChange(of: streak) { oldValue, newValue in
            guard newValue > oldValue else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                animateScale = true
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.2)) {
                animateScale = false
            }
        }
    }

    // MARK: - Compact

    private var compactBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: streakIcon)
                .foregroundStyle(streakColor)
            Text("\(streak)")
                .font(.headline.monospacedDigit())
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(streakColor.opacity(0.15))
        }
    }

    // MARK: - Expanded

    private var expandedBadge: some View {
        VStack(spacing: 4) {
            Image(systemName: streakIcon)
                .font(.title)
                .foregroundStyle(streakColor)

            Text("\(streak)")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .contentTransition(.numericText())

            Text(streak == 1 ? "day" : "days")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(streakColor.opacity(0.1))
        }
    }

    // MARK: - Helpers

    private var streakIcon: String {
        if streak >= 100 {
            return "flame.fill"
        } else if streak >= 7 {
            return "flame"
        } else {
            return "flame"
        }
    }

    private var streakColor: Color {
        if streak >= 100 {
            return .red
        } else if streak >= 30 {
            return .orange
        } else if streak >= 7 {
            return .yellow
        } else {
            return .orange
        }
    }
}
```

## StreakNotificationScheduler.swift

```swift
import UserNotifications
import Foundation

/// Schedules local notifications for streak-at-risk reminders.
///
/// If the user has not recorded activity by the configured reminder time,
/// a notification fires to encourage them before the day ends.
///
/// Usage:
/// ```swift
/// let scheduler = StreakNotificationScheduler()
/// await scheduler.scheduleStreakReminder(currentStreak: 15)
/// ```
struct StreakNotificationScheduler: Sendable {
    /// The hour (in 24h format) to send the streak-at-risk reminder.
    let reminderHour: Int

    /// The minute to send the reminder.
    let reminderMinute: Int

    private let notificationCenter = UNUserNotificationCenter.current()
    private static let streakReminderIdentifier = "streak-at-risk-reminder"

    init(reminderHour: Int = 20, reminderMinute: Int = 0) {
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    // MARK: - Authorization

    /// Request notification permission if not already granted.
    func requestAuthorization() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Schedule

    /// Schedule a streak-at-risk notification for today.
    ///
    /// Call this when the app launches or after refreshing streak state.
    /// If the user has already recorded activity today, call `cancelStreakReminder()` instead.
    ///
    /// - Parameter currentStreak: The user's current streak count (used in the message).
    func scheduleStreakReminder(currentStreak: Int) async {
        // Remove any existing reminder first
        cancelStreakReminder()

        let content = UNMutableNotificationContent()
        content.title = "Your streak is at risk!"
        content.body = streakMessage(for: currentStreak)
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: Self.streakReminderIdentifier,
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    /// Cancel any pending streak reminder.
    ///
    /// Call this after the user records activity for today.
    func cancelStreakReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [Self.streakReminderIdentifier]
        )
    }

    // MARK: - Message Templates

    private func streakMessage(for streak: Int) -> String {
        switch streak {
        case 0:
            return "Start a new streak today! Every journey begins with day one."
        case 1...6:
            return "You have a \(streak)-day streak going. Don't lose it — check in before midnight!"
        case 7...29:
            return "Impressive! \(streak) days in a row. Keep the momentum going today!"
        case 30...99:
            return "Amazing \(streak)-day streak! You're in the top tier. Don't break it now!"
        default:
            return "Incredible \(streak)-day streak! You're on fire. One quick check-in keeps it alive!"
        }
    }
}
```

## Environment Integration

```swift
import SwiftUI

/// Environment key for injecting StreakManager in SwiftUI previews and tests.
private struct StreakManagerKey: EnvironmentKey {
    static let defaultValue: StreakManager? = nil
}

extension EnvironmentValues {
    var streakManager: StreakManager? {
        get { self[StreakManagerKey.self] }
        set { self[StreakManagerKey.self] = newValue }
    }
}
```

## App Setup Example

```swift
import SwiftUI
import SwiftData

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [StreakRecord.self, StreakFreeze.self])
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var streakManager: StreakManager?

    var body: some View {
        NavigationStack {
            if let manager = streakManager {
                VStack(spacing: 24) {
                    StreakBadgeView(streak: manager.currentStreak, style: .expanded)

                    if manager.isStreakAtRisk {
                        Label("Check in today to keep your streak!", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }

                    Button("Record Activity") {
                        Task {
                            try? await manager.recordActivity()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    StreakCalendarView(manager: manager)
                }
                .padding()
                .navigationTitle("My Streaks")
            } else {
                ProgressView()
            }
        }
        .task {
            let manager = StreakManager(modelContext: modelContext)
            await manager.refresh()
            streakManager = manager
        }
    }
}
```
