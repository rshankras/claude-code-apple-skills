# Usage Insights Code Templates

Production-ready Swift templates for user-facing usage statistics and insights. All code targets iOS 17+ / macOS 14+ and uses SwiftData, @Observable, Swift Charts, and modern Swift concurrency.

## UsageEvent.swift

```swift
import Foundation
import SwiftData

/// A single user activity event recorded on-device.
///
/// Events are the raw data from which insights are computed.
/// All data stays on the user's device — never transmitted to a server.
///
/// Usage:
/// ```swift
/// let event = UsageEvent(
///     eventType: "taskCompleted",
///     metadata: ["category": "work"],
///     duration: 45.0
/// )
/// ```
@Model
final class UsageEvent {
    /// The type of event (e.g., "taskCompleted", "sessionStarted", "featureUsed").
    var eventType: String

    /// When the event occurred.
    var timestamp: Date

    /// Optional key-value metadata for categorization and filtering.
    /// Examples: ["category": "work"], ["screen": "editor"], ["feature": "darkMode"]
    var metadata: [String: String]

    /// Optional duration in seconds (for timed events like sessions).
    var duration: TimeInterval?

    init(
        eventType: String,
        timestamp: Date = .now,
        metadata: [String: String] = [:],
        duration: TimeInterval? = nil
    ) {
        self.eventType = eventType
        self.timestamp = timestamp
        self.metadata = metadata
        self.duration = duration
    }
}

// MARK: - Well-Known Event Types

extension UsageEvent {
    /// Predefined event type constants to avoid stringly-typed errors.
    enum EventType {
        static let sessionStarted = "sessionStarted"
        static let sessionCompleted = "sessionCompleted"
        static let taskCompleted = "taskCompleted"
        static let featureUsed = "featureUsed"
        static let screenViewed = "screenViewed"
        static let itemCreated = "itemCreated"
        static let itemDeleted = "itemDeleted"
        static let searchPerformed = "searchPerformed"
        static let shareAction = "shareAction"
        static let settingsChanged = "settingsChanged"

        /// Create a custom event type string.
        static func custom(_ name: String) -> String { name }
    }
}
```

## InsightResult.swift

```swift
import Foundation

/// A computed insight derived from usage events.
///
/// Represents a single stat card in the insights dashboard.
/// Each insight has a displayable value, an optional comparison
/// to the previous period, and a visualization hint.
struct InsightResult: Identifiable, Sendable {
    let id = UUID()

    /// Display title (e.g., "Total Tasks", "Most Active Day").
    let title: String

    /// The primary display value (e.g., "42", "Tuesday", "3h 20m").
    let value: String

    /// SF Symbol name for the card icon.
    let iconName: String

    /// Comparison to the previous period (e.g., +12%, -5%).
    /// Nil if no previous period data is available.
    let comparison: PeriodComparison?

    /// The trend direction for visual indicators.
    let trend: Trend

    /// Hint for how this insight should be visualized.
    let visualizationType: VisualizationType

    /// Optional sparkline data points for mini chart on the card.
    let sparklineData: [Double]?
}

// MARK: - Trend

extension InsightResult {
    /// Trend direction compared to the previous period.
    enum Trend: Sendable {
        case up
        case down
        case stable
        case newData  // First period, no comparison available

        /// SF Symbol name for the trend arrow.
        var iconName: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            case .newData: return "sparkles"
            }
        }

        /// Semantic color for the trend indicator.
        /// Note: "up" is not always good (e.g., errors up = bad).
        /// Use `isPositive` parameter to control color meaning.
        var defaultIsPositive: Bool {
            switch self {
            case .up: return true
            case .down: return false
            case .stable, .newData: return true
            }
        }
    }
}

// MARK: - Period Comparison

extension InsightResult {
    /// Comparison data between current and previous periods.
    struct PeriodComparison: Sendable {
        /// Percentage change from previous period (e.g., 0.12 = +12%).
        let percentageChange: Double

        /// Absolute change (e.g., +5 events).
        let absoluteChange: Int

        /// Formatted display string (e.g., "+12%", "-5%", "Same").
        var displayString: String {
            if absoluteChange == 0 { return "Same" }
            let sign = percentageChange > 0 ? "+" : ""
            return "\(sign)\(Int(percentageChange * 100))%"
        }
    }
}

// MARK: - Visualization Type

extension InsightResult {
    /// Hint for how the insight should be rendered.
    enum VisualizationType: Sendable {
        /// A large number or text value (e.g., "42 tasks").
        case number

        /// A bar or line chart.
        case chart

        /// A badge or achievement-style display.
        case badge

        /// A streak counter (e.g., "5-day streak").
        case streak
    }
}

// MARK: - Insight Period

/// The time period for which insights are calculated.
enum InsightPeriod: String, CaseIterable, Identifiable, Sendable {
    case day = "Today"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"

    var id: String { rawValue }

    /// Calendar component for date arithmetic.
    var calendarComponent: Calendar.Component {
        switch self {
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }

    /// Number of data points for charts.
    var chartDataPointCount: Int {
        switch self {
        case .day: return 24     // Hours
        case .week: return 7     // Days
        case .month: return 30   // Days
        case .year: return 12    // Months
        }
    }
}
```

## InsightCalculator.swift

```swift
import Foundation

/// Pure computation engine that aggregates UsageEvents into InsightResults.
///
/// All methods are pure functions with no side effects — easy to test.
/// Uses Calendar for correct period grouping that respects the user's
/// locale, first-day-of-week, and timezone settings.
///
/// Usage:
/// ```swift
/// let calculator = InsightCalculator()
/// let insights = calculator.weeklySummary(from: events, referenceDate: .now)
/// ```
struct InsightCalculator: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Public API

    /// Compute insights for the given period.
    func summary(
        from events: [UsageEvent],
        period: InsightPeriod,
        referenceDate: Date = .now
    ) -> [InsightResult] {
        switch period {
        case .day:
            return dailySummary(from: events, referenceDate: referenceDate)
        case .week:
            return weeklySummary(from: events, referenceDate: referenceDate)
        case .month:
            return monthlySummary(from: events, referenceDate: referenceDate)
        case .year:
            return yearlySummary(from: events, referenceDate: referenceDate)
        }
    }

    // MARK: - Weekly Summary

    /// Compute weekly insights from events.
    func weeklySummary(
        from events: [UsageEvent],
        referenceDate: Date = .now
    ) -> [InsightResult] {
        let currentWeekEvents = eventsInPeriod(.weekOfYear, of: referenceDate, from: events)
        let previousWeekEvents = eventsInPreviousPeriod(.weekOfYear, of: referenceDate, from: events)

        var insights: [InsightResult] = []

        // Total events
        let totalCount = currentWeekEvents.count
        let previousCount = previousWeekEvents.count
        let comparison = makeComparison(current: totalCount, previous: previousCount)

        insights.append(InsightResult(
            title: "Total Events",
            value: "\(totalCount)",
            iconName: "chart.bar.fill",
            comparison: comparison,
            trend: trend(current: totalCount, previous: previousCount),
            visualizationType: .number,
            sparklineData: dailyCounts(for: currentWeekEvents, days: 7, referenceDate: referenceDate)
        ))

        // Most active day
        let mostActive = mostActiveDay(in: currentWeekEvents)
        insights.append(InsightResult(
            title: "Most Active Day",
            value: mostActive ?? "—",
            iconName: "calendar.badge.clock",
            comparison: nil,
            trend: mostActive != nil ? .stable : .newData,
            visualizationType: .badge,
            sparklineData: nil
        ))

        // Daily average
        let avgPerDay = totalCount > 0 ? Double(totalCount) / 7.0 : 0
        let prevAvg = previousCount > 0 ? Double(previousCount) / 7.0 : 0
        insights.append(InsightResult(
            title: "Daily Average",
            value: String(format: "%.1f", avgPerDay),
            iconName: "divide.circle.fill",
            comparison: makeComparison(current: Int(avgPerDay * 10), previous: Int(prevAvg * 10)),
            trend: trend(current: Int(avgPerDay * 100), previous: Int(prevAvg * 100)),
            visualizationType: .number,
            sparklineData: nil
        ))

        // Current streak
        let streakDays = currentStreak(from: events, referenceDate: referenceDate)
        insights.append(InsightResult(
            title: "Current Streak",
            value: "\(streakDays) day\(streakDays == 1 ? "" : "s")",
            iconName: "flame.fill",
            comparison: nil,
            trend: streakDays > 0 ? .up : .stable,
            visualizationType: .streak,
            sparklineData: nil
        ))

        // Top categories (from metadata)
        let topCategory = topCategory(in: currentWeekEvents)
        if let topCategory {
            insights.append(InsightResult(
                title: "Top Category",
                value: topCategory,
                iconName: "tag.fill",
                comparison: nil,
                trend: .stable,
                visualizationType: .badge,
                sparklineData: nil
            ))
        }

        // Total duration (if any events have duration)
        let totalDuration = currentWeekEvents.compactMap(\.duration).reduce(0, +)
        if totalDuration > 0 {
            let prevDuration = previousWeekEvents.compactMap(\.duration).reduce(0, +)
            insights.append(InsightResult(
                title: "Total Time",
                value: formattedDuration(totalDuration),
                iconName: "clock.fill",
                comparison: makeComparison(current: Int(totalDuration), previous: Int(prevDuration)),
                trend: trend(current: Int(totalDuration), previous: Int(prevDuration)),
                visualizationType: .number,
                sparklineData: nil
            ))
        }

        return insights
    }

    // MARK: - Daily Summary

    func dailySummary(
        from events: [UsageEvent],
        referenceDate: Date = .now
    ) -> [InsightResult] {
        let todayEvents = eventsInPeriod(.day, of: referenceDate, from: events)
        let yesterdayEvents = eventsInPreviousPeriod(.day, of: referenceDate, from: events)

        let totalCount = todayEvents.count
        let previousCount = yesterdayEvents.count
        let comparison = makeComparison(current: totalCount, previous: previousCount)

        var insights: [InsightResult] = []

        insights.append(InsightResult(
            title: "Total Events",
            value: "\(totalCount)",
            iconName: "chart.bar.fill",
            comparison: comparison,
            trend: trend(current: totalCount, previous: previousCount),
            visualizationType: .number,
            sparklineData: hourlyCounts(for: todayEvents, referenceDate: referenceDate)
        ))

        // Most active hour
        let peakHour = mostActiveHour(in: todayEvents)
        if let peakHour {
            insights.append(InsightResult(
                title: "Peak Hour",
                value: formattedHour(peakHour),
                iconName: "clock.badge.fill",
                comparison: nil,
                trend: .stable,
                visualizationType: .badge,
                sparklineData: nil
            ))
        }

        // Total duration
        let totalDuration = todayEvents.compactMap(\.duration).reduce(0, +)
        if totalDuration > 0 {
            let prevDuration = yesterdayEvents.compactMap(\.duration).reduce(0, +)
            insights.append(InsightResult(
                title: "Total Time",
                value: formattedDuration(totalDuration),
                iconName: "clock.fill",
                comparison: makeComparison(current: Int(totalDuration), previous: Int(prevDuration)),
                trend: trend(current: Int(totalDuration), previous: Int(prevDuration)),
                visualizationType: .number,
                sparklineData: nil
            ))
        }

        return insights
    }

    // MARK: - Monthly Summary

    func monthlySummary(
        from events: [UsageEvent],
        referenceDate: Date = .now
    ) -> [InsightResult] {
        let currentEvents = eventsInPeriod(.month, of: referenceDate, from: events)
        let previousEvents = eventsInPreviousPeriod(.month, of: referenceDate, from: events)

        var insights: [InsightResult] = []

        let totalCount = currentEvents.count
        let previousCount = previousEvents.count

        insights.append(InsightResult(
            title: "Total Events",
            value: "\(totalCount)",
            iconName: "chart.bar.fill",
            comparison: makeComparison(current: totalCount, previous: previousCount),
            trend: trend(current: totalCount, previous: previousCount),
            visualizationType: .number,
            sparklineData: dailyCounts(for: currentEvents, days: 30, referenceDate: referenceDate)
        ))

        let mostActive = mostActiveDay(in: currentEvents)
        insights.append(InsightResult(
            title: "Most Active Day",
            value: mostActive ?? "—",
            iconName: "calendar.badge.clock",
            comparison: nil,
            trend: mostActive != nil ? .stable : .newData,
            visualizationType: .badge,
            sparklineData: nil
        ))

        let avgPerDay = totalCount > 0 ? Double(totalCount) / 30.0 : 0
        insights.append(InsightResult(
            title: "Daily Average",
            value: String(format: "%.1f", avgPerDay),
            iconName: "divide.circle.fill",
            comparison: nil,
            trend: .stable,
            visualizationType: .number,
            sparklineData: nil
        ))

        let streakDays = currentStreak(from: events, referenceDate: referenceDate)
        insights.append(InsightResult(
            title: "Current Streak",
            value: "\(streakDays) day\(streakDays == 1 ? "" : "s")",
            iconName: "flame.fill",
            comparison: nil,
            trend: streakDays > 0 ? .up : .stable,
            visualizationType: .streak,
            sparklineData: nil
        ))

        return insights
    }

    // MARK: - Yearly Summary

    func yearlySummary(
        from events: [UsageEvent],
        referenceDate: Date = .now
    ) -> [InsightResult] {
        let currentEvents = eventsInPeriod(.year, of: referenceDate, from: events)
        let previousEvents = eventsInPreviousPeriod(.year, of: referenceDate, from: events)

        var insights: [InsightResult] = []

        let totalCount = currentEvents.count
        let previousCount = previousEvents.count

        insights.append(InsightResult(
            title: "Total Events",
            value: "\(totalCount)",
            iconName: "chart.bar.fill",
            comparison: makeComparison(current: totalCount, previous: previousCount),
            trend: trend(current: totalCount, previous: previousCount),
            visualizationType: .number,
            sparklineData: monthlyCounts(for: currentEvents, referenceDate: referenceDate)
        ))

        // Best month
        let bestMonth = mostActiveMonth(in: currentEvents)
        if let bestMonth {
            insights.append(InsightResult(
                title: "Best Month",
                value: bestMonth,
                iconName: "trophy.fill",
                comparison: nil,
                trend: .stable,
                visualizationType: .badge,
                sparklineData: nil
            ))
        }

        // Longest streak in the year
        let longestStreak = longestStreak(from: currentEvents)
        insights.append(InsightResult(
            title: "Longest Streak",
            value: "\(longestStreak) day\(longestStreak == 1 ? "" : "s")",
            iconName: "flame.fill",
            comparison: nil,
            trend: longestStreak > 0 ? .up : .stable,
            visualizationType: .streak,
            sparklineData: nil
        ))

        // Unique active days
        let activeDays = uniqueActiveDays(in: currentEvents)
        insights.append(InsightResult(
            title: "Active Days",
            value: "\(activeDays)",
            iconName: "calendar.badge.checkmark",
            comparison: nil,
            trend: .stable,
            visualizationType: .number,
            sparklineData: nil
        ))

        // Top event type
        let topType = topEventType(in: currentEvents)
        if let topType {
            insights.append(InsightResult(
                title: "Top Activity",
                value: topType,
                iconName: "star.fill",
                comparison: nil,
                trend: .stable,
                visualizationType: .badge,
                sparklineData: nil
            ))
        }

        return insights
    }

    // MARK: - Period Filtering

    private func eventsInPeriod(
        _ component: Calendar.Component,
        of date: Date,
        from events: [UsageEvent]
    ) -> [UsageEvent] {
        guard let interval = calendar.dateInterval(of: component, for: date) else { return [] }
        return events.filter { interval.contains($0.timestamp) }
    }

    private func eventsInPreviousPeriod(
        _ component: Calendar.Component,
        of date: Date,
        from events: [UsageEvent]
    ) -> [UsageEvent] {
        guard let previousDate = calendar.date(byAdding: component, value: -1, to: date) else {
            return []
        }
        return eventsInPeriod(component, of: previousDate, from: events)
    }

    // MARK: - Aggregation Helpers

    private func mostActiveDay(in events: [UsageEvent]) -> String? {
        guard !events.isEmpty else { return nil }

        let grouped = Dictionary(grouping: events) { event in
            calendar.component(.weekday, from: event.timestamp)
        }

        guard let (weekday, _) = grouped.max(by: { $0.value.count < $1.value.count }) else {
            return nil
        }

        return calendar.weekdaySymbols[weekday - 1]
    }

    private func mostActiveHour(in events: [UsageEvent]) -> Int? {
        guard !events.isEmpty else { return nil }

        let grouped = Dictionary(grouping: events) { event in
            calendar.component(.hour, from: event.timestamp)
        }

        return grouped.max(by: { $0.value.count < $1.value.count })?.key
    }

    private func mostActiveMonth(in events: [UsageEvent]) -> String? {
        guard !events.isEmpty else { return nil }

        let grouped = Dictionary(grouping: events) { event in
            calendar.component(.month, from: event.timestamp)
        }

        guard let (month, _) = grouped.max(by: { $0.value.count < $1.value.count }) else {
            return nil
        }

        return calendar.monthSymbols[month - 1]
    }

    private func topCategory(in events: [UsageEvent]) -> String? {
        let categories = events.compactMap { $0.metadata["category"] }
        guard !categories.isEmpty else { return nil }

        let counts = Dictionary(grouping: categories) { $0 }
        return counts.max(by: { $0.value.count < $1.value.count })?.key.capitalized
    }

    private func topEventType(in events: [UsageEvent]) -> String? {
        guard !events.isEmpty else { return nil }

        let counts = Dictionary(grouping: events) { $0.eventType }
        return counts.max(by: { $0.value.count < $1.value.count })?.key
            .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .capitalized
            .trimmingCharacters(in: .whitespaces)
    }

    private func currentStreak(from events: [UsageEvent], referenceDate: Date) -> Int {
        let startOfToday = calendar.startOfDay(for: referenceDate)

        // Get unique active days sorted descending
        let activeDays = Set(events.map { calendar.startOfDay(for: $0.timestamp) })
            .sorted(by: >)

        guard !activeDays.isEmpty else { return 0 }

        // Check if today or yesterday is active (streak must be current)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        guard activeDays.first == startOfToday || activeDays.first == yesterday else { return 0 }

        var streak = 0
        var expectedDate = activeDays.first!

        for day in activeDays {
            if day == expectedDate {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if day < expectedDate {
                break
            }
        }

        return streak
    }

    private func longestStreak(from events: [UsageEvent]) -> Int {
        let activeDays = Set(events.map { calendar.startOfDay(for: $0.timestamp) })
            .sorted()

        guard !activeDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<activeDays.count {
            let expected = calendar.date(byAdding: .day, value: 1, to: activeDays[i - 1])!
            if calendar.isDate(activeDays[i], inSameDayAs: expected) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    private func uniqueActiveDays(in events: [UsageEvent]) -> Int {
        Set(events.map { calendar.startOfDay(for: $0.timestamp) }).count
    }

    // MARK: - Sparkline Data

    private func dailyCounts(
        for events: [UsageEvent],
        days: Int,
        referenceDate: Date
    ) -> [Double] {
        let startOfToday = calendar.startOfDay(for: referenceDate)

        return (0..<days).reversed().map { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else {
                return 0
            }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
            return Double(events.filter { $0.timestamp >= day && $0.timestamp < nextDay }.count)
        }
    }

    private func hourlyCounts(for events: [UsageEvent], referenceDate: Date) -> [Double] {
        let startOfDay = calendar.startOfDay(for: referenceDate)

        return (0..<24).map { hour in
            guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay),
                  let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) else {
                return 0
            }
            return Double(events.filter { $0.timestamp >= hourStart && $0.timestamp < hourEnd }.count)
        }
    }

    private func monthlyCounts(for events: [UsageEvent], referenceDate: Date) -> [Double] {
        guard let yearInterval = calendar.dateInterval(of: .year, for: referenceDate) else {
            return []
        }

        return (0..<12).map { month in
            guard let monthStart = calendar.date(byAdding: .month, value: month, to: yearInterval.start),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
                return 0
            }
            return Double(events.filter { monthInterval.contains($0.timestamp) }.count)
        }
    }

    // MARK: - Formatting

    private func makeComparison(current: Int, previous: Int) -> InsightResult.PeriodComparison? {
        guard previous > 0 else {
            if current > 0 {
                return nil  // No previous data, show as "New!"
            }
            return nil
        }

        let change = Double(current - previous) / Double(previous)
        return InsightResult.PeriodComparison(
            percentageChange: change,
            absoluteChange: current - previous
        )
    }

    private func trend(current: Int, previous: Int) -> InsightResult.Trend {
        guard previous > 0 else { return .newData }
        if current > previous { return .up }
        if current < previous { return .down }
        return .stable
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func formattedHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(from: DateComponents(hour: hour)) ?? Date()
        return formatter.string(from: date).lowercased()
    }
}
```

## InsightsDashboardView.swift

```swift
import SwiftUI
import SwiftData
import Charts

/// Main insights dashboard showing a grid of insight cards with a period picker.
///
/// Fetches usage events from SwiftData and computes insights on the fly.
/// Supports switching between daily, weekly, monthly, and yearly views.
///
/// Usage:
/// ```swift
/// NavigationLink("My Insights") {
///     InsightsDashboardView()
/// }
/// ```
struct InsightsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPeriod: InsightPeriod = .week
    @State private var insights: [InsightResult] = []
    @State private var chartData: [ChartDataPoint] = []
    @State private var isLoading = true

    private let calculator = InsightCalculator()
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                periodPicker

                if isLoading {
                    loadingView
                } else if insights.isEmpty {
                    emptyStateView
                } else {
                    if !chartData.isEmpty {
                        activityChart
                    }

                    insightsGrid
                }
            }
            .padding()
        }
        .navigationTitle("Insights")
        .task(id: selectedPeriod) {
            await loadInsights()
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(InsightPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Activity Chart

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(.headline)

            Chart(chartData) { point in
                BarMark(
                    x: .value("Period", point.label),
                    y: .value("Count", point.value)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...(chartData.map(\.value).max() ?? 1) * 1.1)
            .frame(height: 200)
            .accessibilityLabel("Activity chart showing \(selectedPeriod.rawValue.lowercased()) breakdown")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    // MARK: - Insights Grid

    private var insightsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(insights) { insight in
                InsightCardView(insight: insight)
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Calculating insights...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Activity Yet", systemImage: "chart.bar.doc.horizontal")
        } description: {
            Text("Start using the app and your insights will appear here.")
        }
    }

    // MARK: - Data Loading

    private func loadInsights() async {
        isLoading = true

        let referenceDate = Date.now
        let fetchDescriptor = fetchDescriptor(for: selectedPeriod, referenceDate: referenceDate)

        do {
            let events = try modelContext.fetch(fetchDescriptor)
            insights = calculator.summary(from: events, period: selectedPeriod, referenceDate: referenceDate)
            chartData = buildChartData(from: events, period: selectedPeriod, referenceDate: referenceDate)
        } catch {
            insights = []
            chartData = []
        }

        isLoading = false
    }

    /// Build a FetchDescriptor that only loads events relevant to the selected period.
    /// This avoids loading the entire event history into memory.
    private func fetchDescriptor(
        for period: InsightPeriod,
        referenceDate: Date
    ) -> FetchDescriptor<UsageEvent> {
        let calendar = Calendar.current

        // Fetch events for current period plus previous period (for comparison)
        let periodsBack: Int
        switch period {
        case .day: periodsBack = 2
        case .week: periodsBack = 2
        case .month: periodsBack = 2
        case .year: periodsBack = 2
        }

        let startDate = calendar.date(
            byAdding: period.calendarComponent,
            value: -periodsBack,
            to: referenceDate
        ) ?? referenceDate

        var descriptor = FetchDescriptor<UsageEvent>(
            predicate: #Predicate<UsageEvent> { event in
                event.timestamp >= startDate
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 10_000  // Safety limit
        return descriptor
    }

    /// Build chart data points from events for the selected period.
    private func buildChartData(
        from events: [UsageEvent],
        period: InsightPeriod,
        referenceDate: Date
    ) -> [ChartDataPoint] {
        let calendar = Calendar.current

        switch period {
        case .day:
            let startOfDay = calendar.startOfDay(for: referenceDate)
            return (0..<24).map { hour in
                let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfDay)!
                let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
                let count = events.filter { $0.timestamp >= hourStart && $0.timestamp < hourEnd }.count
                let formatter = DateFormatter()
                formatter.dateFormat = "ha"
                let label = formatter.string(from: hourStart).lowercased()
                return ChartDataPoint(label: label, value: Double(count))
            }

        case .week:
            let startOfToday = calendar.startOfDay(for: referenceDate)
            return (0..<7).reversed().map { dayOffset in
                let day = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday)!
                let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
                let count = events.filter { $0.timestamp >= day && $0.timestamp < nextDay }.count
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
                return ChartDataPoint(label: formatter.string(from: day), value: Double(count))
            }

        case .month:
            let startOfToday = calendar.startOfDay(for: referenceDate)
            return stride(from: 29, through: 0, by: -1).map { dayOffset in
                let day = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday)!
                let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
                let count = events.filter { $0.timestamp >= day && $0.timestamp < nextDay }.count
                let formatter = DateFormatter()
                formatter.dateFormat = "d"
                return ChartDataPoint(label: formatter.string(from: day), value: Double(count))
            }

        case .year:
            guard let yearStart = calendar.dateInterval(of: .year, for: referenceDate)?.start else {
                return []
            }
            return (0..<12).map { month in
                let monthStart = calendar.date(byAdding: .month, value: month, to: yearStart)!
                guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
                    return ChartDataPoint(label: "", value: 0)
                }
                let count = events.filter { monthInterval.contains($0.timestamp) }.count
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return ChartDataPoint(label: formatter.string(from: monthStart), value: Double(count))
            }
        }
    }
}

// MARK: - Chart Data Point

/// A single data point for the activity chart.
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}
```

## InsightCardView.swift

```swift
import SwiftUI
import Charts

/// Individual insight card displaying a single statistic.
///
/// Shows an icon, title, large value, trend indicator, and optional
/// mini sparkline chart. Matches system card styling with adaptive colors.
///
/// Usage:
/// ```swift
/// InsightCardView(insight: InsightResult(
///     title: "Total Tasks",
///     value: "42",
///     iconName: "checkmark.circle.fill",
///     comparison: nil,
///     trend: .up,
///     visualizationType: .number,
///     sparklineData: [3, 5, 2, 8, 6, 7, 4]
/// ))
/// ```
struct InsightCardView: View {
    let insight: InsightResult

    /// Controls whether "up" trend is shown as positive (green) or negative (red).
    /// Default: true (up = good). Set to false for metrics where increase is bad (e.g., errors).
    var upIsPositive: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            valueSection
            bottomSection
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Image(systemName: insight.iconName)
                .font(.title3)
                .foregroundStyle(iconColor)

            Spacer()

            trendBadge
        }
    }

    // MARK: - Value

    private var valueSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(insight.value)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(insight.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Bottom Section (Sparkline or Comparison)

    @ViewBuilder
    private var bottomSection: some View {
        if let sparklineData = insight.sparklineData, !sparklineData.isEmpty {
            sparklineChart(data: sparklineData)
        } else if let comparison = insight.comparison {
            comparisonLabel(comparison)
        }
    }

    // MARK: - Trend Badge

    @ViewBuilder
    private var trendBadge: some View {
        switch insight.trend {
        case .newData:
            Text("New!")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(.blue.opacity(0.15))
                )

        case .up, .down, .stable:
            Image(systemName: insight.trend.iconName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(trendColor)
        }
    }

    // MARK: - Sparkline

    private func sparklineChart(data: [Double]) -> some View {
        Chart(Array(data.enumerated()), id: \.offset) { index, value in
            LineMark(
                x: .value("Index", index),
                y: .value("Value", value)
            )
            .foregroundStyle(iconColor.gradient)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Index", index),
                y: .value("Value", value)
            )
            .foregroundStyle(iconColor.opacity(0.1).gradient)
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 40)
    }

    // MARK: - Comparison Label

    private func comparisonLabel(_ comparison: InsightResult.PeriodComparison) -> some View {
        Text("vs last period: \(comparison.displayString)")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    // MARK: - Colors

    private var iconColor: Color {
        switch insight.visualizationType {
        case .number: return .blue
        case .chart: return .green
        case .badge: return .orange
        case .streak: return .red
        }
    }

    private var trendColor: Color {
        switch insight.trend {
        case .up:
            return upIsPositive ? .green : .red
        case .down:
            return upIsPositive ? .red : .green
        case .stable:
            return .secondary
        case .newData:
            return .blue
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var description = "\(insight.title): \(insight.value)"
        if let comparison = insight.comparison {
            description += ", \(comparison.displayString) compared to last period"
        }
        switch insight.trend {
        case .up: description += ", trending up"
        case .down: description += ", trending down"
        case .stable: description += ", stable"
        case .newData: description += ", new data"
        }
        return description
    }
}
```

## UsageRecapView.swift

```swift
import SwiftUI
import SwiftData

/// A "Year in Review" or "Weekly Recap" paged summary with shareable card generation.
///
/// Displays key insights in a paged, visually rich format inspired by
/// Spotify Wrapped and Apple's year-in-review screens.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showRecap) {
///     UsageRecapView(period: .week)
/// }
/// ```
struct UsageRecapView: View {
    let period: InsightPeriod

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var insights: [InsightResult] = []
    @State private var currentPage = 0
    @State private var isSharePresented = false
    @State private var shareImage: Image?

    private let calculator = InsightCalculator()

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                if insights.isEmpty {
                    ContentUnavailableView {
                        Label("No Data", systemImage: "chart.bar.xaxis")
                    } description: {
                        Text("Not enough activity to generate a recap.")
                    }
                } else {
                    pagedContent
                }
            }
            .navigationTitle(period == .year ? "Year in Review" : "\(period.rawValue) Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !insights.isEmpty {
                        shareButton
                    }
                }
            }
            .task {
                await loadInsights()
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var gradientColors: [Color] {
        switch period {
        case .day: return [.blue.opacity(0.3), .cyan.opacity(0.2)]
        case .week: return [.purple.opacity(0.3), .blue.opacity(0.2)]
        case .month: return [.orange.opacity(0.3), .red.opacity(0.2)]
        case .year: return [.indigo.opacity(0.4), .purple.opacity(0.3)]
        }
    }

    // MARK: - Paged Content

    private var pagedContent: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                recapCard(insight: insight, index: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }

    private func recapCard(insight: InsightResult, index: Int) -> some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: insight.iconName)
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.9))

            VStack(spacing: 12) {
                Text(insight.title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.8))

                Text(insight.value)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if let comparison = insight.comparison {
                    Text(comparison.displayString + " vs last \(period.rawValue.lowercased().replacingOccurrences(of: "this ", with: ""))")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()

            // Page indicator text
            Text("\(index + 1) of \(insights.count)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Share

    @ViewBuilder
    private var shareButton: some View {
        if let shareImage {
            ShareLink(
                item: shareImage,
                preview: SharePreview("My \(period.rawValue) Recap", image: shareImage)
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } else {
            Button {
                Task { await generateShareImage() }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - Data Loading

    private func loadInsights() async {
        let referenceDate = Date.now

        let startDate = Calendar.current.date(
            byAdding: period.calendarComponent,
            value: -2,
            to: referenceDate
        ) ?? referenceDate

        var descriptor = FetchDescriptor<UsageEvent>(
            predicate: #Predicate<UsageEvent> { event in
                event.timestamp >= startDate
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 10_000

        do {
            let events = try modelContext.fetch(descriptor)
            insights = calculator.summary(from: events, period: period, referenceDate: referenceDate)
        } catch {
            insights = []
        }
    }

    // MARK: - Share Image Generation

    @MainActor
    private func generateShareImage() async {
        let shareView = RecapShareCard(insights: insights, period: period)
        let renderer = ImageRenderer(content: shareView.frame(width: 390, height: 690))
        renderer.scale = 2.0

        #if canImport(UIKit)
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
        #elseif canImport(AppKit)
        if let nsImage = renderer.nsImage {
            shareImage = Image(nsImage: nsImage)
        }
        #endif
    }
}

// MARK: - Recap Share Card (Rendered to Image)

/// A self-contained view designed to be rendered to an image for sharing.
/// Fixed dimensions, no interactivity, optimized for image export.
private struct RecapShareCard: View {
    let insights: [InsightResult]
    let period: InsightPeriod

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text(period == .year ? "Year in Review" : "\(period.rawValue) Recap")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Date.now.formatted(.dateTime.month(.wide).year()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            // Top insights (max 4)
            VStack(spacing: 16) {
                ForEach(Array(insights.prefix(4))) { insight in
                    HStack {
                        Image(systemName: insight.iconName)
                            .frame(width: 32)
                            .foregroundStyle(.blue)

                        Text(insight.title)
                            .font(.subheadline)

                        Spacer()

                        Text(insight.value)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)

                    if insight.id != insights.prefix(4).last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondary.opacity(0.1))
            )
            .padding(.horizontal, 24)

            Spacer()

            // Branding
            Text("Generated with MyApp")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.99))
    }
}
```

## UsageEventRecorder.swift

```swift
import Foundation
import SwiftData

/// Convenience class for recording usage events from anywhere in the app.
///
/// Batches writes for performance — instead of saving after every event,
/// accumulates events and flushes periodically or when a threshold is reached.
///
/// Usage:
/// ```swift
/// struct ContentView: View {
///     @Environment(\.modelContext) private var modelContext
///     @State private var recorder: UsageEventRecorder?
///
///     var body: some View {
///         Button("Do Something") {
///             recorder?.record(.featureUsed, metadata: ["feature": "export"])
///         }
///         .onAppear {
///             recorder = UsageEventRecorder(modelContext: modelContext)
///         }
///     }
/// }
/// ```
@Observable
@MainActor
final class UsageEventRecorder {
    private let modelContext: ModelContext
    private var pendingEvents: [UsageEvent] = []
    private let batchSize: Int
    private var flushTask: Task<Void, Never>?

    /// Create a recorder with the given model context.
    /// - Parameters:
    ///   - modelContext: The SwiftData model context for persisting events.
    ///   - batchSize: Number of events to accumulate before auto-flushing. Default: 10.
    init(modelContext: ModelContext, batchSize: Int = 10) {
        self.modelContext = modelContext
        self.batchSize = batchSize
    }

    // MARK: - Recording

    /// Record a usage event with a predefined event type.
    func record(
        _ eventType: String,
        metadata: [String: String] = [:],
        duration: TimeInterval? = nil
    ) {
        let event = UsageEvent(
            eventType: eventType,
            timestamp: .now,
            metadata: metadata,
            duration: duration
        )

        pendingEvents.append(event)

        if pendingEvents.count >= batchSize {
            flush()
        } else {
            scheduleDelayedFlush()
        }
    }

    /// Record using the well-known event type constants.
    func record(
        _ eventType: UsageEvent.EventType.Type = UsageEvent.EventType.self,
        type: String,
        metadata: [String: String] = [:],
        duration: TimeInterval? = nil
    ) {
        record(type, metadata: metadata, duration: duration)
    }

    // MARK: - Convenience Methods

    /// Record a screen view event.
    func recordScreenView(_ screenName: String) {
        record(UsageEvent.EventType.screenViewed, metadata: ["screen": screenName])
    }

    /// Record a feature usage event.
    func recordFeatureUsed(_ featureName: String) {
        record(UsageEvent.EventType.featureUsed, metadata: ["feature": featureName])
    }

    /// Record a task completion event.
    func recordTaskCompleted(category: String? = nil, metadata: [String: String] = [:]) {
        var allMetadata = metadata
        if let category {
            allMetadata["category"] = category
        }
        record(UsageEvent.EventType.taskCompleted, metadata: allMetadata)
    }

    /// Record a session with duration.
    func recordSession(duration: TimeInterval, metadata: [String: String] = [:]) {
        record(
            UsageEvent.EventType.sessionCompleted,
            metadata: metadata,
            duration: duration
        )
    }

    // MARK: - Flushing

    /// Immediately persist all pending events to SwiftData.
    func flush() {
        flushTask?.cancel()
        flushTask = nil

        guard !pendingEvents.isEmpty else { return }

        let eventsToSave = pendingEvents
        pendingEvents.removeAll()

        for event in eventsToSave {
            modelContext.insert(event)
        }

        do {
            try modelContext.save()
        } catch {
            // Re-add failed events to retry on next flush
            pendingEvents.append(contentsOf: eventsToSave)
        }
    }

    /// Schedule a delayed flush to catch any remaining events.
    private func scheduleDelayedFlush() {
        flushTask?.cancel()
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self?.flush()
        }
    }

    // MARK: - Cleanup

    /// Delete all events older than the specified number of days.
    /// Call periodically to prevent unbounded storage growth.
    func pruneEvents(olderThanDays days: Int = 365) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now

        do {
            try modelContext.delete(
                model: UsageEvent.self,
                where: #Predicate<UsageEvent> { event in
                    event.timestamp < cutoffDate
                }
            )
            try modelContext.save()
        } catch {
            // Log error but don't crash — pruning is best-effort
        }
    }

    deinit {
        flushTask?.cancel()
    }
}

// MARK: - SwiftUI Environment Integration

private struct UsageEventRecorderKey: EnvironmentKey {
    static let defaultValue: UsageEventRecorder? = nil
}

extension EnvironmentValues {
    var usageRecorder: UsageEventRecorder? {
        get { self[UsageEventRecorderKey.self] }
        set { self[UsageEventRecorderKey.self] = newValue }
    }
}
```
