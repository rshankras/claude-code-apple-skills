# Watch Complications

Detailed guide for building watch face complications, covering the ClockKit to WidgetKit migration and modern complication patterns.

## ClockKit vs WidgetKit Complications

| Feature | ClockKit (Legacy) | WidgetKit (Modern) |
|---------|------------------|--------------------|
| Minimum target | watchOS 2 | watchOS 9 |
| Language | Swift/ObjC templates | SwiftUI views |
| Families | `CLKComplicationFamily` | `WidgetFamily` (accessory*) |
| Data source | `CLKComplicationDataSource` | `TimelineProvider` |
| Deprecated | watchOS 9 | Current |
| Removal | watchOS 11 | N/A |

**Rule:** All new complications must use WidgetKit. ClockKit is deprecated and removed in watchOS 11.

## Migration: ClockKit to WidgetKit

### Before (ClockKit)

```swift
import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {

    func getComplicationDescriptors(
        handler: @escaping ([CLKComplicationDescriptor]) -> Void
    ) {
        let descriptor = CLKComplicationDescriptor(
            identifier: "steps",
            displayName: "Steps",
            supportedFamilies: [.graphicCircular, .graphicRectangular]
        )
        handler([descriptor])
    }

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        let template: CLKComplicationTemplate
        switch complication.family {
        case .graphicCircular:
            let t = CLKComplicationTemplateGraphicCircularStackText()
            t.line1TextProvider = CLKSimpleTextProvider(text: "Steps")
            t.line2TextProvider = CLKSimpleTextProvider(text: "8,432")
            template = t
        default:
            handler(nil)
            return
        }
        handler(CLKComplicationTimelineEntry(date: .now, complicationTemplate: template))
    }
}
```

### After (WidgetKit)

```swift
import WidgetKit
import SwiftUI

struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Int
}

struct StepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: .now, steps: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        completion(StepsEntry(date: .now, steps: 8432))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        let entry = StepsEntry(date: .now, steps: DataStore.shared.todaySteps)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct StepsComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Steps", provider: StepsProvider()) { entry in
            StepsComplicationView(entry: entry)
        }
        .configurationDisplayName("Steps")
        .description("Today's step count.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}
```

### Migration Checklist

1. Replace `CLKComplicationDataSource` with `TimelineProvider`
2. Replace `CLKComplicationTemplate` with SwiftUI views
3. Replace `CLKTextProvider` with SwiftUI `Text`
4. Replace `CLKComplicationDescriptor` with `Widget` struct
5. Replace `CLKComplicationServer.reloadTimeline(for:)` with `WidgetCenter.shared.reloadTimelines(ofKind:)`
6. Remove `CLKComplicationDataSource` from `Info.plist`
7. Add widget extension target if not present

## Complication Families

### `.accessoryCircular`
Small circular complication. Use for single metrics with gauges or icons.

```swift
struct CircularView: View {
    let entry: StepsEntry

    var body: some View {
        Gauge(value: Double(entry.steps), in: 0...10000) {
            Text("Steps")
        } currentValueLabel: {
            Text("\(entry.steps)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}
```

### `.accessoryRectangular`
Multi-line rectangular area. Best for text-heavy content or small charts.

```swift
struct RectangularView: View {
    let entry: StepsEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Steps")
                .font(.headline)
                .widgetAccentable()
            Text("\(entry.steps)")
                .font(.title2)
            ProgressView(value: Double(entry.steps), total: 10000)
        }
    }
}
```

### `.accessoryCorner`
Corner position with curved text or gauge. Available on specific watch faces.

```swift
struct CornerView: View {
    let entry: StepsEntry

    var body: some View {
        Text("\(entry.steps)")
            .font(.title3)
            .widgetCurvesContent()
            .widgetLabel {
                Gauge(value: Double(entry.steps), in: 0...10000) {
                    Text("Steps")
                }
                .gaugeStyle(.accessoryLinearCapacity)
            }
    }
}
```

### `.accessoryInline`
Single line of text, appears on the watch face. Text only, no images.

```swift
struct InlineView: View {
    let entry: StepsEntry

    var body: some View {
        Text("\(entry.steps) steps today")
    }
}
```

### Switching by Family

```swift
struct StepsComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: StepsEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryCorner:
            CornerView(entry: entry)
        case .accessoryInline:
            InlineView(entry: entry)
        default:
            Text("\(entry.steps)")
        }
    }
}
```

## Timeline Providers

### StaticConfiguration (No User Configuration)

```swift
struct SimpleProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, value: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: .now, value: 42))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        var entries: [SimpleEntry] = []
        let now = Date.now

        // Create entries for the next 4 hours
        for hourOffset in 0..<4 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: now)!
            let value = fetchValue(for: entryDate)
            entries.append(SimpleEntry(date: entryDate, value: value))
        }

        completion(Timeline(entries: entries, policy: .after(entries.last!.date)))
    }
}
```

### AppIntentConfiguration (User-Configurable, watchOS 10+)

```swift
import AppIntents

struct MetricIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Metric"

    @Parameter(title: "Metric")
    var metric: MetricType

    enum MetricType: String, AppEnum {
        case steps, calories, distance

        static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Metric")
        static var caseDisplayRepresentations: [MetricType: DisplayRepresentation] = [
            .steps: "Steps",
            .calories: "Calories",
            .distance: "Distance"
        ]
    }
}

struct ConfigurableProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MetricEntry {
        MetricEntry(date: .now, value: 0, metric: .steps)
    }

    func snapshot(for configuration: MetricIntent, in context: Context) async -> MetricEntry {
        MetricEntry(date: .now, value: 42, metric: configuration.metric)
    }

    func timeline(for configuration: MetricIntent, in context: Context) async -> Timeline<MetricEntry> {
        let value = await fetchMetric(configuration.metric)
        let entry = MetricEntry(date: .now, value: value, metric: configuration.metric)
        return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900)))
    }
}
```

## Timeline Reload Strategies

### Reload Policies

| Policy | When to Use |
|--------|------------|
| `.atEnd` | Reload when the last entry's date passes |
| `.after(Date)` | Reload at a specific future date |
| `.never` | Only reload on explicit request |

### Triggering Reloads

```swift
import WidgetKit

// Reload a specific complication
WidgetCenter.shared.reloadTimelines(ofKind: "Steps")

// Reload all complications
WidgetCenter.shared.reloadAllTimelines()

// From iPhone via Watch Connectivity
func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
    if userInfo["complicationUpdate"] != nil {
        WidgetCenter.shared.reloadTimelines(ofKind: "Steps")
    }
}
```

## Complication Data Patterns

### Gauge Styles

```swift
// Circular capacity gauge
Gauge(value: 0.7) { Text("HR") }
    .gaugeStyle(.accessoryCircularCapacity)

// Linear capacity gauge (for corner/rectangular)
Gauge(value: 0.7) { Text("HR") }
    .gaugeStyle(.accessoryLinearCapacity)

// Circular open gauge with tint
Gauge(value: heartRate, in: 60...200) {
    Image(systemName: "heart.fill")
} currentValueLabel: {
    Text("\(Int(heartRate))")
}
.gaugeStyle(.accessoryCircular)
.tint(.red)
```

### Date and Timer Display

```swift
// Relative date (e.g., "2 hours ago")
Text(entry.lastUpdated, style: .relative)

// Timer countdown
Text(entry.targetDate, style: .timer)

// Specific date format
Text(entry.date, format: .dateTime.hour().minute())
```

### Accent and Tint

```swift
VStack {
    Image(systemName: "flame.fill")
        .widgetAccentable()  // Tinted by watch face color
    Text("\(calories)")
}

// Full-color rendering for Modular Duo, X-Large
.widgetRenderingMode(.fullColor)
```

## Best Practices

1. **Budget-aware updates** -- Complications get limited background execution time. Batch data fetches and minimize network calls in the timeline provider.

2. **Lightweight timelines** -- Provide 4-8 timeline entries maximum. Avoid creating entries for every minute.

3. **Meaningful placeholders** -- The placeholder is shown while the complication loads. Use realistic but static data, never zeros or empty strings.

4. **Handle stale data** -- Show the last-known value with a timestamp rather than showing nothing when data is unavailable.

5. **Respect rendering mode** -- Use `@Environment(\.widgetRenderingMode)` to adapt between `.fullColor`, `.accented`, and `.vibrant`.

6. **Test all families** -- Each family has different space constraints. Preview every supported family in Xcode.

7. **Minimal text in circular** -- Circular complications have very limited space. Use gauges, icons, or single numbers.

8. **Use `.widgetAccentable()`** -- Mark elements that should adopt the watch face accent color.

9. **Shared data via App Groups** -- Use a shared App Group container to pass data between the main app and the widget extension.

```swift
// In both main app and widget extension
let sharedDefaults = UserDefaults(suiteName: "group.com.example.myapp")
sharedDefaults?.set(stepCount, forKey: "todaySteps")
```

10. **Complication reload limits** -- `reloadTimelines` is budget-limited. Don't call it more than 4 times per hour. Use timeline entries with future dates instead.
