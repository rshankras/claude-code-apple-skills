# Live Activities Integration

Displaying alarms and countdown timers on the Dynamic Island and Lock Screen using a widget extension.

## Why You Need a Widget Extension

AlarmKit countdown and paused presentations appear on the Lock Screen and Dynamic Island through Live Activities. To render custom UI for these states, you must implement a widget extension with an `ActivityConfiguration` for `AlarmAttributes`.

Without the widget extension, the system cannot display countdown or paused presentations. Alert presentations work without a widget extension, but the countdown and paused states will not appear.

## Setting Up the Widget Extension

### 1. Add a Widget Extension Target

In Xcode, add a new target: File > New > Target > Widget Extension. This creates a widget bundle where you add the alarm activity configuration.

### 2. Implement ActivityConfiguration

```swift
import WidgetKit
import SwiftUI
import AlarmKit

struct AlarmActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes.self) { context in
            // Lock Screen presentation
            AlarmLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.presentation.title)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Show countdown or paused state
                    AlarmExpandedView(context: context)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
            } compactTrailing: {
                Text("Timer")
                    .font(.caption)
            } minimal: {
                Image(systemName: "alarm.fill")
            }
        }
    }
}
```

### 3. Register in Widget Bundle

```swift
@main
struct MyAppWidgets: WidgetBundle {
    var body: some Widget {
        // Your other widgets...
        AlarmActivityWidget()
    }
}
```

## AlarmAttributes

`AlarmAttributes` is the type that conforms to `ActivityAttributes` and carries all the information needed to render alarm UI in Live Activities. AlarmKit provides this type -- you do not define it yourself.

Key properties available in the activity context:
- Presentation information (title, buttons)
- Metadata (if you conform to `AlarmMetadata`)
- Tint color

## Custom AlarmMetadata

To pass app-specific data to your widget extension, conform a type to the `AlarmMetadata` protocol. This allows you to include custom information that your Live Activity views can use.

```swift
import AlarmKit

struct MyAlarmMetadata: AlarmMetadata {
    let category: String
    let iconName: String
    let note: String
}
```

Use it when scheduling:

```swift
try await AlarmManager.shared.schedule(id: alarmID) {
    CountdownDuration(preAlert: 600, postAlert: 30)

    AlarmPresentation.Countdown(
        title: "Workout",
        pauseButton: AlarmButton(label: "Pause")
    )

    AlarmPresentation.Alert(
        title: "Workout Complete!",
        stopButton: AlarmButton(label: "Done")
    )

    AlarmPresentation.Paused(
        title: "Workout Paused",
        resumeButton: AlarmButton(label: "Resume")
    )

    MyAlarmMetadata(
        category: "fitness",
        iconName: "figure.run",
        note: "30-minute HIIT session"
    )

    AlarmAttributes(tintColor: .orange)
}
```

## Lock Screen View Example

```swift
struct AlarmLockScreenView: View {
    let context: ActivityViewContext<AlarmAttributes>

    var body: some View {
        HStack {
            Image(systemName: "alarm.fill")
                .foregroundStyle(context.attributes.tintColor ?? .primary)

            VStack(alignment: .leading) {
                Text(context.attributes.presentation.title)
                    .font(.headline)
            }

            Spacer()
        }
        .padding()
    }
}
```

## Common Patterns

### Minimal Setup for Timer Apps

If you only need basic countdown display, the widget extension can be straightforward:

```swift
struct AlarmActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes.self) { context in
            // Lock Screen -- simple layout
            HStack {
                Image(systemName: "timer")
                Text(context.attributes.presentation.title)
                    .font(.headline)
                Spacer()
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.presentation.title)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text(context.attributes.presentation.title)
                    .font(.caption)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}
```

### Anti-Patterns

```swift
// ❌ WRONG: Defining your own AlarmAttributes type
// AlarmKit provides AlarmAttributes -- do not create a custom struct with the same name
struct AlarmAttributes: ActivityAttributes {
    // ...
}
// ✅ Import AlarmKit and use the framework-provided AlarmAttributes

// ❌ WRONG: Using countdown presentations without a widget extension
// The countdown/paused UI simply will not appear
// ✅ Always add a widget extension with ActivityConfiguration(for: AlarmAttributes.self)
```

## Checklist for Live Activities

- [ ] Widget extension target added to the Xcode project
- [ ] `ActivityConfiguration(for: AlarmAttributes.self)` implemented
- [ ] Widget registered in the `WidgetBundle`
- [ ] Lock Screen layout tested on real device
- [ ] Dynamic Island compact, expanded, and minimal views implemented
- [ ] Tint color applied via `AlarmAttributes(tintColor:)` if desired
- [ ] Custom `AlarmMetadata` conformance if passing app-specific data
