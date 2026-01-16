# Widget Generator

Generate WidgetKit widgets for iOS/macOS home screen and lock screen.

## When to Use

- User wants to add widgets to their app
- User mentions WidgetKit or home screen widgets
- User wants lock screen widgets (iOS 16+)
- User asks about widget timelines or updates

## Pre-Generation Checks

```bash
# Check for existing widget extension
find . -name "*Widget*" -type d | head -5
grep -r "WidgetKit\|TimelineProvider" --include="*.swift" | head -5
```

## Configuration Questions

### 1. Widget Sizes
- **Small** - Compact info display
- **Medium** - More detail, horizontal
- **Large** - Full content area
- **All** - Support all sizes

### 2. Widget Type
- **Static** - Content updated on schedule
- **Interactive** (iOS 17+) - Buttons and toggles
- **Live Activity** (iOS 16+) - Real-time updates

### 3. Lock Screen Support (iOS 16+)
- **Yes** - accessoryCircular, accessoryRectangular, accessoryInline
- **No** - Home screen only

## Generated Files

```
WidgetExtension/
├── MyWidget.swift           # Widget definition
├── TimelineProvider.swift   # Timeline logic
├── WidgetViews.swift        # Size-specific views
└── Intent.swift             # Configuration intent (optional)
```

## Basic Widget Structure

```swift
import WidgetKit
import SwiftUI

struct MyWidget: Widget {
    let kind = "MyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MyTimelineProvider()
        ) { entry in
            MyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("Shows important information.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

## Timeline Provider

```swift
struct MyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MyEntry {
        MyEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MyEntry) -> Void) {
        let entry = MyEntry(date: .now, data: .snapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MyEntry>) -> Void) {
        Task {
            let data = await fetchData()
            let entry = MyEntry(date: .now, data: data)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}
```

## Interactive Widgets (iOS 17+)

```swift
struct ToggleButton: View {
    var body: some View {
        Button(intent: ToggleIntent()) {
            Label("Toggle", systemImage: "checkmark.circle")
        }
    }
}

struct ToggleIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Item"

    func perform() async throws -> some IntentResult {
        // Perform action
        return .result()
    }
}
```

## Lock Screen Widgets

```swift
.supportedFamilies([
    .accessoryCircular,
    .accessoryRectangular,
    .accessoryInline,
    .systemSmall,
    .systemMedium
])

struct AccessoryCircularView: View {
    var body: some View {
        Gauge(value: 0.75) {
            Text("75%")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}
```

## Integration Steps

1. File > New > Target > Widget Extension
2. Configure app groups for shared data
3. Implement TimelineProvider
4. Create size-specific views
5. Add widget to WidgetBundle

## Updating Widgets

```swift
import WidgetKit

// From main app
WidgetCenter.shared.reloadAllTimelines()

// Specific widget
WidgetCenter.shared.reloadTimelines(ofKind: "MyWidget")
```

## References

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Creating a Widget Extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
