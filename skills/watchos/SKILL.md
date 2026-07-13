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
- Asks about **WidgetKit complications** or migrating from ClockKit to WidgetKit
- Wants to build **watch face complications** (accessoryCircular, accessoryRectangular, accessoryCorner, accessoryInline)
- Asks about **HealthKit on watchOS**, workout sessions, heart rate, or fitness tracking
- Needs **Extended Runtime sessions** for background workout tracking
- Wants to build **watchOS widgets** or Smart Stack widgets
- Asks about **widget relevance**, Smart Stack ordering, or widget suggestions
- Needs to share widgets **cross-platform** between iOS and watchOS
- Asks about **watchOS accessibility** — VoiceOver, AssistiveTouch, or Dynamic Type on the Watch

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

## watchOS Design Rules (WWDC20/23)

### The Ten-Second Test
Design for roughly ten seconds of attention: "if you had ten seconds of someone's attention, which information would you surface?" Launch directly into that detail view — chosen by location, recency, or frequency — and make it so unmistakable it needs no title.

### Three Foundational Layouts
| Layout | Use For | Notes |
|--------|---------|-------|
| **Dial** | Dense at-a-glance status | Up to 4 corner controls; `.scenePadding(.horizontal)` to align with the bezel |
| **Infographic** | Charts + metrics | One chart with supporting numbers |
| **List** | Scrollable finding | When the user must locate an item |

### Navigation Model
- Prefer **vertical pagination** via the Digital Crown between purposeful, single-screen-height pages — horizontal paging is "more difficult to navigate".
- Prefer the two-level **Source List** pattern with `NavigationSplitView`: always initialize the selection so the app launches straight to detail, and leave the source list untitled.
- Reach for `NavigationStack` only when neither fits — and hierarchical navigation should remember the last destination across launches.
- The Digital Crown anchors navigation, scrolling, and precision input, but ALWAYS back it up with touch.

```swift
// Source List: launch to detail, not the list
NavigationSplitView {
    List(rooms, selection: $selectedRoom) { room in  // source list stays untitled
        Text(room.name)
    }
} detail: {
    RoomView(room: selectedRoom)
}
// Initialize selectedRoom (last used / most relevant) so launch lands on detail
```

### Backgrounds and Materials
- Backgrounds must carry utility — recognition or information (a solar gradient tracking the sun, a state change from black to orange) — never mere flourish.
- Four vibrant full-screen materials (Ultra Thin → Thick) pair with Primary–Quaternary vibrant foreground styles and vibrant semantic colors to keep content legible over any background.

### Toolbars and Action Buttons
- Toolbar placements: `.topBarLeading`, `.topBarTrailing` (moves the time to the center), and `.bottomBar`.
- Bottom-of-detail action buttons are the most discoverable pattern. A red label signals destructive — add a confirmation if the data isn't recoverable.
- The More button (ellipsis in a circular container: white at 85% opacity with a 1pt black outer glow at 50%) holds ONLY secondary actions — never a primary action.
- Toolbar-revealed buttons belong only in scrolling views — scrolling is what makes them discoverable.

## Accessibility on watchOS (WWDC21 10223)

### Dynamic Type on the Watch
- watchOS has 11 text styles; a fixed `.font(.system(size: 24))` never scales — use `.font(.title3)` and friends.
- Let text wrap: `lineLimit(1)` truncates at accessibility sizes — set the real maximum you support (`.lineLimit(3)`) or remove the limit.
- Watch setup defaults text size to the closest match to the paired iPhone's setting — expect real users at accessibility sizes (WWDC21 10223).
- Swap layout when wrapping gets crowded:

```swift
@Environment(\.sizeCategory) var sizeCategory

var body: some View {
    if sizeCategory < .extraExtraLarge {
        PlantViewHorizontal(plant: $plant)   // default layout
    } else {
        PlantViewVertical(plant: $plant)     // stacked layout for large sizes
    }
}
```

### VoiceOver
- `NavigationLink` combines its children's accessibility automatically — don't add extra grouping inside one; the whole row becomes a single element (WWDC21 10223).
- Label icon+text rows so they read as meaning, not parts: `.accessibilityLabel("Watering in five days")` instead of "Drop, image. Five days." Label icon-only buttons too: `.accessibilityLabel("Log \(task.name)")` → "Log watering, button".
- Steppers/counters: collapse [minus, value, plus] into one adjustable element. Put the changing number in the **value** — it is re-spoken on every change; the label is spoken only on navigation:

```swift
CustomCounter(value: value, increment: increment, decrement: decrement)
    .accessibilityElement()               // drops the +/- buttons as separate stops
    .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment: increment()      // swipe up
        case .decrement: decrement()      // swipe down
        default: break
        }
    }
    .accessibilityLabel("\(task.name) frequency")
    .accessibilityValue("\(value) days")
```

- Complications and dynamic notifications need the same treatment — they're extra content paths out of your app. Expand abbreviations ("Wednesday, March 9th", not "Wednesday Mar 9"), and label image complications or VoiceOver speaks the asset name (WWDC21 10223).

### AssistiveTouch
Hand gestures drive the watch with zero screen touches: **clench = tap, double-clench = action menu, pinch = next element, double-pinch = previous** (WWDC21 10223). A cursor focuses only interactive elements — Button, Toggle, NavigationLink, views with tap gestures, accessibility actions, or actionable traits; static text and disabled elements are skipped.

```swift
// ✅ static text whose parent owns the tap gesture — make it a cursor stop
FreeDrinkInfoView()
    .accessibilityRespondsToUserInteraction(true)

// ✅ cursor frame == tappable area; enlarge tiny hit targets
NavigationLink(destination: EditView()) {
    Image(systemName: "ellipsis").symbolVariant(.circle)
}
.contentShape(Circle().scale(1.5))
```

VoiceOver custom actions appear in the AssistiveTouch action menu automatically. Supply a real icon via the `Label` form of `.accessibilityAction { } label: { Label("Edit", systemImage: "ellipsis.circle") }` — otherwise the menu falls back to the first letter of the action name (WWDC21 10223).

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

## Decision Tree

Choose the right reference file based on what the user needs:

```
What are you building?
|
+- iPhone <-> Watch data sync
|  -> watch-connectivity.md
|     +- Session management, application context, real-time messaging
|     +- File transfers, offline caching, complication push updates
|
+- Watch face complications
|  -> complications.md
|     +- ClockKit (legacy) vs WidgetKit (modern) complications
|     +- Migration from ClockKit to WidgetKit
|     +- Complication families (circular, rectangular, corner, inline)
|     +- Timeline providers, reload strategies, gauges
|
+- Health / fitness / workout tracking
|  -> health-fitness.md
|     +- HealthKit authorization and data types
|     +- HKWorkoutSession and HKLiveWorkoutBuilder
|     +- Real-time heart rate, calories, distance
|     +- Extended Runtime sessions, route tracking
|
+- watchOS widgets / Smart Stack
|  -> widgets-for-watch.md
|     +- Smart Stack configuration and relevance
|     +- Cross-platform widget sharing (iOS + watchOS)
|     +- watchOS-specific design (dark background, small screen)
|
+- General watchOS app development
   -> This file (SKILL.md)
      +- Design rules: ten-second test, layouts, navigation model, action buttons
      +- App structure, navigation, lists
      +- Digital Crown, haptics, Now Playing
```

## Reference Files

| File | Content |
|------|---------|
| [watch-connectivity.md](watch-connectivity.md) | iPhone <-> Watch sync, session management, data transfer, offline caching |
| [complications.md](complications.md) | ClockKit to WidgetKit migration, complication families, timeline providers, gauges |
| [health-fitness.md](health-fitness.md) | HealthKit, workout sessions, heart rate, Extended Runtime, route tracking, privacy |
| [widgets-for-watch.md](widgets-for-watch.md) | Smart Stack widgets, relevance, cross-platform sharing, watchOS design |

## External References

- [watchOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos)
- [Watch Connectivity](https://developer.apple.com/documentation/watchconnectivity)
- [ClockKit](https://developer.apple.com/documentation/clockkit)
- [WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [HealthKit Workouts](https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings)
