---
name: usage-insights
description: Generates user-facing usage statistics, activity summaries, and personalized insights dashboards (weekly recaps, year-in-review, Spotify Wrapped-style). Use when user wants to show usage stats, activity insights, or shareable recap screens. Different from analytics-setup which sends data to a backend — this shows insights to the USER on-device.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Usage Insights Generator

Generate a production usage insights system that records user activity events with SwiftData, computes personalized insights (streaks, most active day, top categories), and displays them in a dashboard with insight cards, period pickers, trend indicators, and optional shareable recap screens.

## When This Skill Activates

Use this skill when the user:
- Asks to "show usage statistics" or "add usage stats"
- Wants "user insights" or "activity insights"
- Mentions "activity summary" or "weekly summary"
- Asks about a "usage dashboard" or "insights dashboard"
- Wants a "weekly recap" or "monthly recap"
- Mentions "year in review" or "year-in-review"
- Asks for "Spotify Wrapped style" or "Wrapped-style recap"
- Wants to "show the user their activity" or "personalized stats"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 17+ / macOS 14+ for @Observable and SwiftData)
- [ ] Identify source file locations
- [ ] Check for Swift Charts availability (iOS 16+ / macOS 13+, but recommend iOS 17+)

### 2. Conflict Detection
Search for existing usage tracking or insights code:
```
Glob: **/*UsageEvent*.swift, **/*Insight*.swift, **/*Recap*.swift, **/*ActivityLog*.swift
Grep: "UsageEvent" or "InsightCalculator" or "activitySummary" or "SwiftData" and "event"
```

If existing analytics/tracking found:
- Ask if user wants to build insights on top of existing event data
- If yes, adapt `InsightCalculator` to work with existing models
- If no, generate fresh event recording alongside existing code

### 3. Data Layer Detection
Check for SwiftData usage:
```
Grep: "import SwiftData" or "@Model" or "ModelContainer"
```

If SwiftData already in use:
- Integrate `UsageEvent` into existing `ModelContainer`
- Use existing schema migration strategy

If no SwiftData:
- Generate full setup including `ModelContainer` configuration

## Configuration Questions

Ask user via AskUserQuestion:

1. **Insight period?**
   - Daily (today's activity breakdown)
   - Weekly (7-day recap with day-by-day comparison) — recommended
   - Monthly (30-day trends with weekly rollups)
   - Yearly (year-in-review with monthly highlights)
   - All of the above (period picker lets user switch)

2. **Visualization style?**
   - Cards only (simple stat cards with trend indicators)
   - Charts only (Swift Charts bar/line graphs)
   - Both cards and charts — recommended

3. **Include shareable recap card?**
   - Yes (generates a recap view that can be rendered to an image and shared)
   - No (dashboard only, no sharing)

4. **Data source?**
   - SwiftData (generate `UsageEvent` model and recorder) — recommended
   - Custom (user provides their own event data; generate calculator and views only)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Data Files
Generate these files:
1. `UsageEvent.swift` — SwiftData `@Model` for recording user activity events
2. `InsightResult.swift` — Model for computed insights (title, value, trend, visualization type)

### Step 3: Create Calculation Engine
3. `InsightCalculator.swift` — Pure functions that aggregate events into insights

### Step 4: Create UI Files
4. `InsightsDashboardView.swift` — Main dashboard with grid of insight cards and period picker
5. `InsightCardView.swift` — Individual insight card with icon, value, trend indicator, sparkline

### Step 5: Create Optional Files
Based on configuration:
- `UsageRecapView.swift` — If shareable recap selected (paged summary with share card generation)
- `UsageEventRecorder.swift` — If SwiftData data source selected (convenience class for recording events)

### Step 6: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/UsageInsights/`
- If `App/` exists -> `App/UsageInsights/`
- Otherwise -> `UsageInsights/`

## Output Format

After generation, provide:

### Files Created
```
UsageInsights/
├── UsageEvent.swift           # SwiftData @Model for activity events
├── InsightResult.swift        # Computed insight model
├── InsightCalculator.swift    # Aggregation engine
├── InsightsDashboardView.swift # Dashboard with period picker
├── InsightCardView.swift      # Individual insight card
├── UsageRecapView.swift       # Shareable recap (optional)
└── UsageEventRecorder.swift   # Event recording helper (optional)
```

### Integration Steps

**Add ModelContainer (if not already present):**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UsageEvent.self])
    }
}
```

**Record events from anywhere in the app:**
```swift
struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var recorder: UsageEventRecorder?

    var body: some View {
        Button("Complete Task") {
            completeTask()
            recorder?.record(
                .taskCompleted,
                metadata: ["category": "work", "priority": "high"]
            )
        }
        .onAppear {
            recorder = UsageEventRecorder(modelContext: modelContext)
        }
    }
}
```

**Show the insights dashboard:**
```swift
NavigationLink("My Insights") {
    InsightsDashboardView()
}
```

**Show a weekly recap:**
```swift
struct WeeklyRecapSheet: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showRecap = false

    var body: some View {
        Button("View Weekly Recap") {
            showRecap = true
        }
        .sheet(isPresented: $showRecap) {
            UsageRecapView(period: .week)
        }
    }
}
```

**Record events with duration tracking:**
```swift
// Start a timed session
let sessionStart = Date()

// ... user does work ...

// Record when session ends
recorder?.record(
    .sessionCompleted,
    metadata: ["screen": "editor"],
    duration: Date().timeIntervalSince(sessionStart)
)
```

### Testing

```swift
@Test
func calculatesWeeklySummaryCorrectly() async throws {
    let calendar = Calendar.current
    let now = Date()
    let events: [UsageEvent] = (0..<7).flatMap { dayOffset in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
        return (0..<(dayOffset == 2 ? 5 : 2)).map { _ in
            UsageEvent(eventType: "taskCompleted", timestamp: date)
        }
    }

    let calculator = InsightCalculator()
    let insights = calculator.weeklySummary(from: events, referenceDate: now)

    let totalInsight = insights.first { $0.title == "Total Events" }
    #expect(totalInsight != nil)
    #expect(totalInsight?.value == "19") // 5 + (6 * 2)
}

@Test
func identifiesMostActiveDay() async throws {
    let calendar = Calendar.current
    let now = Date()

    // Create 5 events on Wednesday, 2 on other days
    var events: [UsageEvent] = []
    for dayOffset in 0..<7 {
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
        let count = calendar.component(.weekday, from: date) == 4 ? 5 : 1
        for _ in 0..<count {
            events.append(UsageEvent(eventType: "action", timestamp: date))
        }
    }

    let calculator = InsightCalculator()
    let insights = calculator.weeklySummary(from: events, referenceDate: now)
    let mostActive = insights.first { $0.title == "Most Active Day" }
    #expect(mostActive?.value == "Wednesday")
}

@Test
func handlesEmptyEventList() async throws {
    let calculator = InsightCalculator()
    let insights = calculator.weeklySummary(from: [], referenceDate: Date())

    #expect(!insights.isEmpty) // Should still return cards with zero values
    let totalInsight = insights.first { $0.title == "Total Events" }
    #expect(totalInsight?.value == "0")
}

@Test
func recorderBatchesWritesForPerformance() async throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: UsageEvent.self, configurations: config)
    let context = ModelContext(container)
    let recorder = UsageEventRecorder(modelContext: context)

    // Record 100 events rapidly
    for i in 0..<100 {
        recorder.record(.custom("event_\(i)"))
    }

    // Flush pending writes
    recorder.flush()

    let descriptor = FetchDescriptor<UsageEvent>()
    let count = try context.fetchCount(descriptor)
    #expect(count == 100)
}
```

## Common Patterns

### Record an Event
```swift
recorder?.record(.featureUsed, metadata: ["feature": "darkMode"])
```

### Calculate a Weekly Summary
```swift
let calculator = InsightCalculator()
let events = try modelContext.fetch(FetchDescriptor<UsageEvent>())
let insights = calculator.weeklySummary(from: events, referenceDate: Date())
```

### Render Insight Cards in a Grid
```swift
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
    ForEach(insights) { insight in
        InsightCardView(insight: insight)
    }
}
```

### Generate and Share a Recap Image
```swift
let renderer = ImageRenderer(content: UsageRecapView(period: .week))
renderer.scale = 2.0
if let image = renderer.uiImage {
    // Use with ShareLink or UIActivityViewController
}
```

## Gotchas

### Privacy: All Data Stays On-Device
- Usage events are stored in SwiftData on the user's device only
- Never transmit usage data to a server (that's what `analytics-setup` is for)
- Clearly communicate to users that insights are computed locally
- Consider adding a "Delete My Data" option in settings

### Performance with Large Datasets
- Fetch only the events needed for the current period (use `#Predicate` with date range)
- For yearly summaries, pre-aggregate monthly totals instead of scanning all events
- Batch event recording to avoid excessive SwiftData writes (use `UsageEventRecorder`)
- Set a retention policy — auto-delete events older than 1-2 years

### Calendar-Based Period Calculations
- Always use `Calendar.current` for date math — never assume 7 days = 1 week
- Respect the user's first-day-of-week setting (`calendar.firstWeekday`)
- Use `calendar.dateInterval(of: .weekOfYear, for: date)` for accurate week boundaries
- Handle timezone changes gracefully — store timestamps in UTC, display in local time

### Swift Charts Considerations
- Swift Charts is iOS 16+ / macOS 13+, but works best with iOS 17+ for latest features
- Keep chart data points reasonable (7 for weekly, 30 for monthly, 12 for yearly)
- Use `.chartYScale(domain:)` to prevent axis from starting at a misleading value
- Provide VoiceOver descriptions with `.accessibilityLabel` on chart marks

### Trend Comparison Edge Cases
- First week of use has no "previous period" — show "New!" instead of a trend arrow
- Handle periods with zero events gracefully (don't divide by zero for averages)
- Percentage changes can be misleading for small numbers (1 -> 2 = +100%)

## References

- **templates.md** — All production Swift templates
- Related: `generators/share-card` — Render recap views as shareable images
- Related: `generators/analytics-setup` — Backend analytics (complements on-device insights)
- Related: `generators/streak-tracker` — Streak tracking pairs well with usage insights
- Related: `generators/milestone-celebration` — Celebrate milestones surfaced by insights
