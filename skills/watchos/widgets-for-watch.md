# Widgets for watchOS

watchOS-specific widget patterns for Smart Stack, relevance, and cross-platform widget sharing.

## watchOS Widget Families

| Family | Shape | Size | Best For |
|--------|-------|------|----------|
| `.accessoryCircular` | Circle | Small | Single metric, gauge, icon |
| `.accessoryRectangular` | Rectangle | Medium | Multi-line text, small charts |
| `.accessoryCorner` | Curved | Small | Corner gauge with label |
| `.accessoryInline` | Line | Text only | Single line of text |

These families are shared with iOS Lock Screen widgets. Code can be reused across platforms.

## Smart Stack Widgets (watchOS 10+)

Smart Stack is a scrollable stack of widgets accessible from the watch face by turning the Digital Crown. Widgets here can be larger than complications.

### Smart Stack Configuration

```swift
import WidgetKit
import SwiftUI

struct DailyProgressEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let calories: Int
    let exerciseMinutes: Int
}

struct DailyProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyProgressEntry {
        DailyProgressEntry(date: .now, steps: 0, calories: 0, exerciseMinutes: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyProgressEntry) -> Void) {
        completion(DailyProgressEntry(date: .now, steps: 6500, calories: 280, exerciseMinutes: 22))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyProgressEntry>) -> Void) {
        let entry = DailyProgressEntry(
            date: .now,
            steps: DataStore.shared.todaySteps,
            calories: DataStore.shared.todayCalories,
            exerciseMinutes: DataStore.shared.todayExerciseMinutes
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct DailyProgressWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "DailyProgress",
            provider: DailyProgressProvider()
        ) { entry in
            DailyProgressView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Progress")
        .description("Track your daily activity goals.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}
```

### Smart Stack View

```swift
struct DailyProgressView: View {
    @Environment(\.widgetFamily) var family
    let entry: DailyProgressEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            RectangularProgressView(entry: entry)
        case .accessoryCircular:
            CircularProgressView(entry: entry)
        case .accessoryInline:
            Text("\(entry.steps) steps - \(entry.calories) cal")
        default:
            Text("\(entry.steps)")
        }
    }
}

struct RectangularProgressView: View {
    let entry: DailyProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("\(entry.steps)", systemImage: "figure.walk")
                Spacer()
                Label("\(entry.calories)", systemImage: "flame.fill")
            }
            .font(.caption2)

            ProgressView(value: Double(entry.exerciseMinutes), total: 30) {
                Text("\(entry.exerciseMinutes)/30 min")
                    .font(.caption2)
            }
        }
    }
}

struct CircularProgressView: View {
    let entry: DailyProgressEntry

    var body: some View {
        Gauge(value: Double(entry.steps), in: 0...10000) {
            Image(systemName: "figure.walk")
        } currentValueLabel: {
            Text("\(entry.steps / 1000)k")
                .font(.system(.body, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}
```

## Widget Relevance

Relevance determines when your widget appears at the top of the Smart Stack. Higher relevance scores surface the widget more prominently.

### TimelineEntryRelevance

```swift
struct RelevantEntry: TimelineEntry {
    let date: Date
    let value: Int
    let relevance: TimelineEntryRelevance?
}

struct RelevantProvider: TimelineProvider {
    func placeholder(in context: Context) -> RelevantEntry {
        RelevantEntry(date: .now, value: 0, relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RelevantEntry) -> Void) {
        completion(RelevantEntry(date: .now, value: 42, relevance: nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RelevantEntry>) -> Void) {
        var entries: [RelevantEntry] = []

        // Morning: high relevance for weather
        let morning = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now)!
        entries.append(RelevantEntry(
            date: morning,
            value: 72,
            relevance: TimelineEntryRelevance(score: 80)
        ))

        // Midday: lower relevance
        let midday = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        entries.append(RelevantEntry(
            date: midday,
            value: 85,
            relevance: TimelineEntryRelevance(score: 30)
        ))

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
```

### Relevance Score Guidelines

| Score Range | When to Use |
|-------------|------------|
| 0 | Default/no special relevance |
| 1-25 | Background information |
| 25-50 | Mildly relevant (routine data) |
| 50-75 | Relevant (approaching goal, upcoming event) |
| 75-100 | Highly relevant (active workout, imminent event) |

**Tip:** Assign high relevance during active moments (workout in progress, flight boarding soon) and low relevance during idle periods.

## Widget Suggestions (watchOS 10+)

Proactively suggest widgets to users who haven't added them yet.

```swift
import WidgetKit

// Suggest your widget for Smart Stack
func suggestWidget() {
    let suggestion = WidgetRecommendation(
        kind: "DailyProgress",
        description: "Track your daily activity."
    )
    WidgetCenter.shared.setRecommendations([suggestion])
}
```

## watchOS Design Considerations

### Dark Background
watchOS widgets always render on a dark background. Design accordingly.

```swift
struct WatchWidgetView: View {
    var body: some View {
        VStack {
            Text("Steps")
                .foregroundStyle(.secondary)  // Automatically lighter on dark
            Text("8,432")
                .font(.title3.bold())
                .foregroundStyle(.white)  // High contrast on dark
        }
    }
}
```

### Screen Size Constraints
Apple Watch screens are 40-49mm. Keep content minimal.

- **Circular:** 1 number or icon, optionally with gauge
- **Rectangular:** 2-3 lines maximum
- **Inline:** Under 20 characters
- **Corner:** Short label + gauge arc

### Widget Container Background

```swift
// watchOS 10+ requires containerBackground
struct MyWidgetView: View {
    let entry: MyEntry

    var body: some View {
        Text("\(entry.value)")
            .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

### Rendering Modes

```swift
struct AdaptiveView: View {
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        switch renderingMode {
        case .fullColor:
            // Full color rendering (Modular Duo face, Smart Stack)
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
        case .accented:
            // Two-tone: accented elements + desaturated rest
            Image(systemName: "heart.fill")
                .widgetAccentable()
        case .vibrant:
            // Desaturated, system applies vibrancy
            Image(systemName: "heart.fill")
        @unknown default:
            Image(systemName: "heart.fill")
        }
    }
}
```

## Cross-Platform Widget Sharing

Share widget code between iOS Lock Screen and watchOS by using the same accessory families.

### Shared WidgetBundle

```swift
@main
struct MyWidgets: WidgetBundle {
    var body: some Widget {
        StepsWidget()
        CaloriesWidget()
        #if os(iOS)
        HomeScreenWidget()  // iOS home screen only (systemSmall, systemMedium)
        #endif
    }
}
```

### Conditional Families

```swift
struct StepsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Steps", provider: StepsProvider()) { entry in
            StepsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies(supportedFamilies)
        .configurationDisplayName("Steps")
    }

    private var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ]

        #if os(watchOS)
        families.append(.accessoryCorner)
        #endif

        #if os(iOS)
        families.append(contentsOf: [.systemSmall, .systemMedium])
        #endif

        return families
    }
}
```

### Platform-Adaptive Views

```swift
struct StepsWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: StepsEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            // Shared between iOS Lock Screen and watchOS
            CircularStepsView(steps: entry.steps)
        case .accessoryRectangular:
            RectangularStepsView(steps: entry.steps)
        case .accessoryInline:
            Text("\(entry.steps) steps")
        case .accessoryCorner:
            // watchOS only
            CornerStepsView(steps: entry.steps)
        #if os(iOS)
        case .systemSmall:
            SmallStepsView(steps: entry.steps)
        case .systemMedium:
            MediumStepsView(steps: entry.steps)
        #endif
        default:
            Text("\(entry.steps)")
        }
    }
}
```

### Shared Widget Extension Target

For maximum code reuse, create a single widget extension with multi-platform support:

1. In Xcode, add watchOS as a destination to your widget extension target
2. Use `#if os(watchOS)` / `#if os(iOS)` for platform-specific code
3. Share the `TimelineProvider`, `TimelineEntry`, and common views
4. Use conditional compilation only for platform-specific families and views

## Data Sharing Between App and Widget

### App Groups

```swift
// Shared container for app and widget extension
let sharedDefaults = UserDefaults(suiteName: "group.com.example.myapp")

// Main app writes
sharedDefaults?.set(stepCount, forKey: "todaySteps")
WidgetCenter.shared.reloadTimelines(ofKind: "Steps")

// Widget reads
func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
    let defaults = UserDefaults(suiteName: "group.com.example.myapp")
    let steps = defaults?.integer(forKey: "todaySteps") ?? 0
    let entry = StepsEntry(date: .now, steps: steps)
    completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900))))
}
```

### SwiftData / CoreData Shared Container

```swift
// Use the shared App Group container for the database
let container = try ModelContainer(
    for: ActivityRecord.self,
    configurations: ModelConfiguration(
        url: FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.myapp")!
            .appendingPathComponent("ActivityData.store")
    )
)
```

## Best Practices

1. **Budget timeline reloads** -- watchOS limits background execution. Request reloads no more than 4 times per hour.

2. **Use relevance scores** -- Set appropriate `TimelineEntryRelevance` scores so your widget surfaces at the right time in Smart Stack.

3. **Design for glanceability** -- Users glance at widgets for 1-2 seconds. Show the most important number or status prominently.

4. **Test all rendering modes** -- Preview your widget in `.fullColor`, `.accented`, and `.vibrant` modes using Xcode previews.

5. **Provide meaningful placeholders** -- Placeholders appear while the widget loads. Use realistic shapes and placeholder text, not empty views.

6. **Keep timeline entries small** -- Each entry is stored in memory. Don't embed large images or data in timeline entries.

7. **Use `.containerBackground`** -- Required on watchOS 10+. Omitting it causes a runtime warning and default background.

8. **Support `.widgetAccentable()`** -- Mark key visual elements so they adopt the watch face accent color in accented rendering mode.
