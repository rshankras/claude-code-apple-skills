---
name: widget-generator
description: Generate WidgetKit widgets for iOS/macOS home screen and lock screen with timeline providers, interactive elements, and App Intent configuration. Use when adding widgets to an app.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Widget Generator

Generate a complete WidgetKit widget implementation with timeline providers, size-specific views, lock screen accessory widgets, interactive elements (iOS 17+), and App Intent configuration.

## When This Skill Activates

Use this skill when the user:
- Asks to "add widgets" or "add a widget" to their app
- Mentions "WidgetKit" or "home screen widgets"
- Wants "lock screen widgets" or "accessory widgets"
- Asks about "widget timelines" or "timeline providers"
- Wants "interactive widgets" with buttons or toggles
- Mentions "widget configuration" or "configurable widgets"
- Asks about "App Intent widgets" or "AppIntentConfiguration"
- Wants to show data on the home screen or lock screen

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing widget extension target
- [ ] Check for an existing `WidgetBundle`
- [ ] Verify deployment target (iOS 17+ recommended for interactive widgets)
- [ ] Identify source file locations and project structure

### 2. Conflict Detection

Search for existing widget code:
```
Glob: **/*Widget*.swift, **/*TimelineProvider*.swift
Grep: "WidgetKit" or "TimelineProvider" or "WidgetBundle" or "WidgetConfiguration"
```

If an existing widget extension is found:
- Ask if the new widget should be added to the existing widget extension
- Check for an existing `WidgetBundle` to extend

If a `WidgetBundle` already exists:
- Add the new widget to the existing bundle instead of creating a new one
- Do NOT create a second `@main` entry point

If widget code with the same name exists:
- Ask user whether to replace or rename

### 3. Required Capabilities

**Widgets require:**
- A widget extension target (File > New > Target > Widget Extension)
- App Groups capability if sharing data between the main app and widget
- iOS 14+ for basic widgets, iOS 16+ for lock screen, iOS 17+ for interactive widgets

## Configuration Questions

Ask user via AskUserQuestion:

1. **What is this widget for?** (freeform)
   - Examples: weather forecast, task list, fitness stats, quick actions, countdown timer
   - This determines the data model and timeline update strategy

2. **Which widget sizes should be supported?**
   - Home screen: systemSmall, systemMedium, systemLarge, systemExtraLarge (iPad only)
   - Lock screen: accessoryCircular, accessoryRectangular, accessoryInline
   - All home screen sizes
   - All home screen + lock screen sizes (recommended)

3. **What type of widget?**
   - **Static** (`StaticConfiguration`) -- content updated on a schedule, no user configuration
   - **Configurable** (`AppIntentConfiguration`, iOS 17+) -- user can choose what the widget displays via long-press edit
   - **Interactive** (`AppIntentConfiguration` + `Button`/`Toggle`, iOS 17+) -- user can tap buttons or toggles directly on the widget

4. **What is the data source?**
   - Local data (UserDefaults, SwiftData, Core Data)
   - Shared data via App Groups (main app writes, widget reads)
   - Network API (fetched during timeline refresh)
   - Combination of local and network

5. **How often should the widget update?**
   - Every 15 minutes (minimum practical interval)
   - Every 30 minutes
   - Every hour (recommended default)
   - A few times per day
   - Based on specific times (e.g., calendar events)
   - On-demand from the main app via `WidgetCenter.shared.reloadTimelines(ofKind:)`

## Generation Process

### Step 1: Determine File Locations

Check project structure:
- If a widget extension target directory exists, add view and provider files there
- Otherwise, instruct user to create a Widget Extension target first

For widget extension files:
- Place inside the existing widget extension directory (e.g., `MyAppWidgets/`)

For shared data models (if using App Groups):
- If `Sources/` or `Shared/` exists --> place there
- Otherwise --> create alongside existing models

### Step 2: Create Core Files

Generate these files based on configuration answers:

1. **`{Name}Widget.swift`** -- Widget definition with configuration
   - `Widget` struct with `StaticConfiguration` or `AppIntentConfiguration`
   - Supported families declaration
   - Display name and description
2. **`{Name}TimelineProvider.swift`** -- Timeline logic
   - `TimelineProvider` (static) or `AppIntentTimelineProvider` (configurable)
   - Placeholder, snapshot, and timeline methods
3. **`{Name}Entry.swift`** -- Timeline entry model
   - `TimelineEntry` struct with date and display data
4. **`{Name}WidgetViews.swift`** -- Size-specific views
   - Separate view struct for each supported family
   - Uses `containerBackground` for iOS 17+ removable backgrounds
5. **`{Name}AppIntent.swift`** (if interactive or configurable)
   - `WidgetConfigurationIntent` for configurable widgets
   - `AppIntent` for interactive widget buttons/toggles
6. **WidgetBundle update** -- Register the new widget
   - Add to existing bundle or create new one

### Step 3: Generate Code from Templates

Use the templates in **templates.md** and customize based on user answers:
- Replace placeholder names with the actual widget name
- Configure supported families based on size selection
- Include or exclude interactive elements
- Include or exclude lock screen accessory views
- Set up App Group shared data access if needed
- Configure timeline refresh policy based on update frequency

## Output Format

After generation, provide:

### Files Created

```
MyAppWidgets/
├── {Name}Widget.swift              # Widget definition + configuration
├── {Name}TimelineProvider.swift     # Timeline provider with placeholder/snapshot/timeline
├── {Name}Entry.swift               # TimelineEntry data model
├── {Name}WidgetViews.swift         # Size-specific views for each family
├── {Name}AppIntent.swift           # (if configurable/interactive) App Intent
└── (update WidgetBundle if needed)

Shared/
└── {Name}DataProvider.swift        # (if App Groups) Shared data access
```

### Integration Steps

**1. Add the widget extension target (if not present):**
- File > New > Target > Widget Extension
- Choose "Include Configuration App Intent" if configurable
- Ensure the widget extension embeds in the main app

**2. Enable App Groups (if sharing data with the main app):**
- Select the main app target > Signing & Capabilities > + Capability > App Groups
- Select the widget extension target > Signing & Capabilities > + Capability > App Groups
- Use the same group identifier (e.g., `group.com.yourcompany.yourapp`)

**3. Register the widget in the WidgetBundle:**
```swift
@main
struct MyAppWidgets: WidgetBundle {
    var body: some Widget {
        // Existing widgets...
        {Name}Widget()
    }
}
```

**4. Trigger widget updates from the main app when data changes:**
```swift
import WidgetKit

// Reload a specific widget
WidgetCenter.shared.reloadTimelines(ofKind: "{Name}Widget")

// Or reload all widgets
WidgetCenter.shared.reloadAllTimelines()
```

**5. For App Group data sharing, write from the main app:**
```swift
let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.yourapp")
sharedDefaults?.set(encodedData, forKey: "widgetData")

// Then trigger reload
WidgetCenter.shared.reloadTimelines(ofKind: "{Name}Widget")
```

### Testing Instructions

1. **Simulator support:** Widgets can be previewed in Xcode Canvas and tested in Simulator.
2. **Add to home screen:** Long-press the home screen > tap "+" > find your app > select the widget size.
3. **Lock screen widgets:** Long-press the lock screen > "Customize" > select the widget area.
4. **Preview in Xcode:** Use `#Preview` with timeline entry data for rapid iteration.
5. **Timeline debugging:** Use `WidgetCenter.shared.getCurrentConfigurations` to verify registered widgets.
6. **Interactive widget testing (iOS 17+):** Tap buttons/toggles directly on the widget in Simulator or device.
7. **Memory profiling:** Widgets have a 40MB memory limit. Profile in Instruments if loading images or large datasets.

## Common Widget Patterns

### Weather Widget
- **Data:** Temperature, condition icon, hourly forecast
- **Sizes:** systemSmall (current temp), systemMedium (hourly), accessoryCircular (temp gauge)
- **Update:** Every 30 minutes via network API
- **Timeline:** Generate entries for next few hours with forecast data

### Calendar / Events Widget
- **Data:** Upcoming events, times, locations
- **Sizes:** systemSmall (next event), systemMedium (next 3 events), accessoryRectangular (next event)
- **Update:** Based on event start times using `.after(nextEventDate)` policy
- **Timeline:** One entry per upcoming event transition

### Fitness / Health Widget
- **Data:** Steps, calories, activity rings
- **Sizes:** systemSmall (ring summary), accessoryCircular (ring gauge), accessoryRectangular (stats)
- **Update:** Every 15-30 minutes from HealthKit via App Groups
- **Interactive:** None (read-only data display)

### Quick Actions Widget
- **Data:** Action buttons (start timer, toggle light, log water)
- **Sizes:** systemSmall (single action), systemMedium (2-4 actions)
- **Update:** Infrequent (actions are static, only state changes)
- **Interactive:** `Button(intent:)` for each action (iOS 17+)

### Countdown Widget
- **Data:** Target date, label, time remaining
- **Sizes:** systemSmall (days remaining), accessoryCircular (days number), accessoryInline (text countdown)
- **Update:** Daily or use `Text(date, style: .timer)` / `Text(date, style: .relative)` for automatic live updates
- **Timeline:** SwiftUI date styles update automatically without timeline refreshes

## Gotchas and Limits

- **Timeline budget:** The system limits how often your timeline provider runs. Typically ~40-70 refreshes per day. Do not rely on exact timing.
- **40MB memory limit:** Widget extensions are killed if they exceed 40MB. Avoid loading large images or datasets. Use thumbnails and minimal data.
- **`containerBackground` required (iOS 17+):** All widget views must use `.containerBackground(for: .widget)` to support the system's removable background feature. Without this, widgets show a default placeholder background.
- **Accessory family rendering:** Lock screen widgets render in a limited color space. Use `AccessoryWidgetBackground()` for backgrounds and keep designs simple with high contrast.
- **No animation:** Widgets do not support explicit animations. Use `Text(date, style: .timer)` for countdowns; the system animates these for you.
- **No scrolling:** Widgets cannot scroll. Design for fixed, visible content.
- **No video or maps:** MapKit and AVKit are not available in widget extensions.
- **Networking in timeline provider:** Network requests in `getTimeline` must complete quickly. The system may terminate long-running providers.
- **`@main` conflict:** Only one `@main` per widget extension. If you have multiple widgets, use a `WidgetBundle` as the single `@main` entry point.
- **Configurable widget data persistence:** `AppIntent` parameter values are stored by the system. Do not rely on UserDefaults for configuration state.
- **Xcode previews:** Use `#Preview(as: .systemSmall)` for family-specific widget previews.
- **Shared code with main app:** Timeline entries and data models referenced by both targets must have target membership in both the main app and the widget extension.

## References

- **templates.md** -- Production-ready code templates for widget definition, timeline provider, views, and App Intents
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Creating a Widget Extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- [Making a Configurable Widget](https://developer.apple.com/documentation/widgetkit/making-a-configurable-widget)
- [Adding Interactivity to Widgets](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)
- [WidgetKit Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/widgets)
