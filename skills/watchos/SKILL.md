---
name: watchOS
description: watchOS development guidance including SwiftUI for Watch, Watch Connectivity, complications, and watch-specific UI patterns. Use for watchOS code review, best practices, or Watch app development.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# watchOS Development

Comprehensive guidance for watchOS app development with SwiftUI, Watch Connectivity, and complications.

## When This Skill Activates

Use this skill when the user:
- Is building a watchOS app or Watch extension
- Asks about Watch Connectivity (iPhone ↔ Watch sync)
- Needs help with complications or ClockKit
- Wants to implement watch-specific UI patterns

## Key Principles

### 1. Watch-First Design
- Glanceable content - users look for seconds, not minutes
- Quick interactions - 2 seconds or less
- Essential information only - no scrolling walls of text
- Large touch targets - minimum 38pt height

### 2. Independent vs Companion
- Prefer independent Watch apps when possible
- Use Watch Connectivity for data sync, not as dependency
- Cache data locally for offline access
- Handle connectivity failures gracefully

### 3. Performance
- Minimize background work (battery)
- Use complication updates sparingly
- Prefer timeline-based content over live updates
- Keep views lightweight

## Architecture Patterns

### App Structure

```swift
@main
struct MyWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Navigation

```swift
// Use NavigationStack (watchOS 9+)
NavigationStack {
    List {
        NavigationLink("Item 1", value: Item.one)
        NavigationLink("Item 2", value: Item.two)
    }
    .navigationDestination(for: Item.self) { item in
        ItemDetailView(item: item)
    }
}

// TabView for main sections
TabView {
    HomeView()
    ActivityView()
    SettingsView()
}
.tabViewStyle(.verticalPage)
```

### List Design

```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
    }
    .onDelete(perform: delete)
}
.listStyle(.carousel)  // For focused content
.listStyle(.elliptical)  // For browsing
```

## Watch Connectivity

### Session Setup

```swift
import WatchConnectivity

@Observable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    private(set) var isReachable = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // Required delegate methods
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        isReachable = session.isReachable
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
```

### Data Transfer Methods

| Method | Use Case | Delivery |
|--------|----------|----------|
| `updateApplicationContext` | Latest state (settings) | Overwrites previous |
| `sendMessage` | Real-time, both apps active | Immediate |
| `transferUserInfo` | Queued data | Guaranteed, in order |
| `transferFile` | Large data | Background transfer |

```swift
// Application Context (most common)
func updateContext(_ data: [String: Any]) throws {
    try WCSession.default.updateApplicationContext(data)
}

// Real-time messaging
func sendMessage(_ message: [String: Any]) {
    guard WCSession.default.isReachable else { return }
    WCSession.default.sendMessage(message, replyHandler: nil)
}

// Receiving data
func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
    Task { @MainActor in
        // Update UI with received data
    }
}
```

## Complications

### Timeline Provider

```swift
import ClockKit

struct ComplicationController: CLKComplicationDataSource {

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptor = CLKComplicationDescriptor(
            identifier: "myComplication",
            displayName: "My App",
            supportedFamilies: [.circularSmall, .modularSmall, .graphicCircular]
        )
        handler([descriptor])
    }

    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        let template = makeTemplate(for: complication.family)
        let entry = CLKComplicationTimelineEntry(date: .now, complicationTemplate: template)
        handler(entry)
    }
}
```

### WidgetKit Complications (watchOS 9+)

```swift
import WidgetKit
import SwiftUI

struct MyComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "MyComplication",
            provider: ComplicationProvider()
        ) { entry in
            ComplicationView(entry: entry)
        }
        .configurationDisplayName("My Complication")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}
```

## UI Components

### Digital Crown

```swift
@State private var crownValue = 0.0

ScrollView {
    // Content
}
.focusable()
.digitalCrownRotation($crownValue)
```

### Haptic Feedback

```swift
WKInterfaceDevice.current().play(.click)
WKInterfaceDevice.current().play(.success)
WKInterfaceDevice.current().play(.failure)
```

### Now Playing

```swift
import WatchKit

NowPlayingView()  // Built-in now playing controls
```

## Workout Apps

```swift
import HealthKit

@Observable
class WorkoutManager {
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?

    func startWorkout(type: HKWorkoutActivityType) async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = type
        config.locationType = .outdoor

        session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        builder = session?.associatedWorkoutBuilder()

        session?.startActivity(with: .now)
        try await builder?.beginCollection(at: .now)
    }
}
```

## Best Practices

### Performance
- Use `@Observable` over `ObservableObject` (watchOS 10+)
- Limit background refreshes
- Cache images locally
- Use lazy loading for lists

### Battery
- Minimize location updates
- Use scheduled background tasks
- Prefer complications over frequent refreshes
- Batch network requests

### User Experience
- Always show loading states
- Provide haptic feedback
- Support keyboard input
- Use clear iconography

## Testing

### Simulator
- Test with different watch sizes
- Verify complications in all families
- Test Watch Connectivity with paired iPhone simulator

### On Device
- Test battery impact
- Verify haptics feel appropriate
- Test in different lighting conditions

## References

- [watchOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos)
- [Watch Connectivity](https://developer.apple.com/documentation/watchconnectivity)
- [ClockKit](https://developer.apple.com/documentation/clockkit)
- [HealthKit Workouts](https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings)
