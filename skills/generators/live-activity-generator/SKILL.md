---
name: live-activity-generator
description: Generate ActivityKit Live Activity infrastructure with Dynamic Island layouts, Lock Screen presentation, and push-to-update support. Use when adding Live Activities to an iOS app.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Live Activity Generator

Generate a complete ActivityKit Live Activity implementation with Dynamic Island layouts, Lock Screen presentation, activity lifecycle management, and push-to-update support.

## When This Skill Activates

Use this skill when the user:
- Asks to "add Live Activities" or "add a Live Activity"
- Mentions "Dynamic Island" layouts
- Wants real-time status updates on the Lock Screen
- Asks about "ActivityKit" or "ActivityAttributes"
- Mentions "push-to-update" for live activities
- Wants to show ongoing progress (delivery tracking, sports scores, timers, workouts)

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing ActivityKit implementations
- [ ] Check for an existing widget extension target
- [ ] Verify deployment target is iOS 16.1+
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing Live Activity code:
```
Glob: **/*Activity*.swift, **/*LiveActivity*.swift
Grep: "ActivityKit" or "ActivityAttributes" or "ActivityConfiguration"
```

If an existing widget extension is found:
- Ask if the Live Activity should be added to the existing widget bundle
- Check for existing `WidgetBundle` to extend

If Live Activity code already exists:
- Ask user whether to replace or extend

### 3. Required Capabilities

**Live Activities require:**
- iOS 16.1+ deployment target
- `NSSupportsLiveActivities` set to `YES` in Info.plist
- A widget extension target (can share with existing WidgetKit widgets)
- For push updates: `NSSupportsLiveActivitiesFrequentUpdates` (optional, iOS 16.2+)

## Configuration Questions

Ask user via AskUserQuestion:

1. **What is the Live Activity for?** (freeform)
   - Examples: delivery tracking, sports score, workout timer, ride-sharing, food order
   - This determines the attribute fields and content state

2. **What data should appear on the Lock Screen?** (freeform)
   - Static data (set at start, does not change): e.g., restaurant name, order number
   - Dynamic data (updated over time): e.g., ETA, driver location, score

3. **Dynamic Island layout needs?**
   - Compact (leading + trailing) only
   - Expanded (leading, trailing, center, bottom) only
   - Both compact and expanded (recommended)

4. **Push-to-update support?**
   - Yes -- server can update the activity remotely via APNs
   - No -- updates only from the app process

5. **Alert configuration when ending?**
   - Yes -- show a final alert on the Lock Screen when the activity ends
   - No -- dismiss silently

## Generation Process

### Step 1: Determine File Locations

Check project structure:
- If a widget extension target exists, add files there
- Otherwise, instruct user to create a Widget Extension target first

For the activity manager (lives in the main app target):
- If `Sources/` exists --> `Sources/LiveActivity/`
- If `App/` exists --> `App/LiveActivity/`
- Otherwise --> `LiveActivity/`

For the widget extension views:
- Place inside the existing widget extension directory (e.g., `MyAppWidgets/`)

### Step 2: Create Core Files

Generate these files based on configuration answers:

1. **`{Name}ActivityAttributes.swift`** -- Shared between app and widget extension
   - `ActivityAttributes` struct with static properties
   - Nested `ContentState` with dynamic properties
2. **`{Name}LiveActivityView.swift`** -- Widget extension file
   - `ActivityConfiguration` with Lock Screen, Dynamic Island layouts
3. **`{Name}ActivityManager.swift`** -- Main app target file
   - Protocol-based manager for start, update, end, and push token handling

### Step 3: Generate Code from Templates

Use the templates in **templates.md** and customize based on user answers:
- Replace placeholder attribute names with real fields
- Configure Dynamic Island regions based on layout choice
- Include or exclude push-to-update code
- Include or exclude alert configuration

## Info.plist Required

### Main App Target
```xml
<key>NSSupportsLiveActivities</key>
<true/>

<!-- Optional: for frequent push updates (iOS 16.2+) -->
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

## Output Format

After generation, provide:

### Files Created

```
Sources/LiveActivity/
├── {Name}ActivityAttributes.swift     # Shared: attributes + content state
└── {Name}ActivityManager.swift        # Main app: lifecycle management

MyAppWidgets/
├── {Name}LiveActivityView.swift       # Widget ext: all Live Activity UI
└── (update WidgetBundle if needed)
```

### Integration Steps

**1. Add the widget extension target (if not present):**
- File > New > Target > Widget Extension
- Ensure "Include Live Activity" is checked

**2. Share the attributes file between targets:**
The `{Name}ActivityAttributes.swift` file must be included in both the main app target and the widget extension target. Select the file in Xcode, open the File Inspector, and check both targets under "Target Membership".

**3. Add Info.plist entries in the main app target:**
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

**4. Register the Live Activity configuration in the widget bundle:**
```swift
@main
struct MyAppWidgets: WidgetBundle {
    var body: some Widget {
        // Existing widgets...
        MyAppLiveActivity()
    }
}
```

**5. Start a Live Activity from your app:**
```swift
let attributes = DeliveryActivityAttributes(
    orderNumber: "1234",
    restaurantName: "Pizza Place"
)

let initialState = DeliveryActivityAttributes.ContentState(
    status: .preparing,
    estimatedDelivery: Date().addingTimeInterval(30 * 60),
    driverName: nil
)

let manager = LiveActivityManager()
try await manager.startActivity(attributes: attributes, state: initialState)
```

**6. Update the activity when state changes:**
```swift
let updatedState = DeliveryActivityAttributes.ContentState(
    status: .enRoute,
    estimatedDelivery: Date().addingTimeInterval(15 * 60),
    driverName: "Alex"
)

await manager.updateActivity(state: updatedState)
```

**7. End the activity when complete:**
```swift
let finalState = DeliveryActivityAttributes.ContentState(
    status: .delivered,
    estimatedDelivery: Date(),
    driverName: "Alex"
)

await manager.endActivity(state: finalState, dismissalPolicy: .default)
```

### Push-to-Update Setup (if enabled)

**1. Observe push tokens:**
The generated `{Name}ActivityManager` automatically observes push token updates. Send the token to your server when it changes.

**2. Server-side APNs request:**
```bash
curl -v \
  --header "authorization: bearer $JWT_TOKEN" \
  --header "apns-topic: com.yourcompany.yourapp.push-type.liveactivity" \
  --header "apns-push-type: liveactivity" \
  --http2 \
  --data '{"aps":{"timestamp":1234567890,"event":"update","content-state":{"status":"enRoute","estimatedDelivery":1234568000,"driverName":"Alex"}}}' \
  https://api.push.apple.com/3/device/$PUSH_TOKEN
```

Note: The `apns-topic` must be your app bundle ID with `.push-type.liveactivity` appended.

**3. Ending via push:**
```json
{
  "aps": {
    "timestamp": 1234567890,
    "event": "end",
    "dismissal-date": 1234568000,
    "content-state": {
      "status": "delivered",
      "estimatedDelivery": 1234567890,
      "driverName": "Alex"
    }
  }
}
```

### Testing Instructions

1. **Verify on a physical device:** Live Activities run in the Simulator in current Xcode releases, but Lock Screen, StandBy, and Dynamic Island presentation is only authoritative on hardware. Test on a device with iOS 16.1+ before shipping.
2. **Dynamic Island:** Requires iPhone 14 Pro or later (devices with the Dynamic Island hardware).
3. **Push-to-update testing:** Use a tool like `apnspush` or `curl` with an APNs auth key (.p8 file) to send test payloads.
4. **Debug tips:**
   - Use `Activity<Attributes>.activities` to list all running activities
   - Check Console.app for ActivityKit logs filtered by your app bundle ID
   - Activities are limited to a maximum of 5 concurrent per app

## Design Rules

Apply when generating the Lock Screen and Dynamic Island views.

**Lock Screen presentation (WWDC23):**
- **14pt margins on all edges** — matches the notification layout the activity sits among.
- Keep height compact, and **change it dynamically between moments** — collapse sections that are no longer relevant (e.g., drop the "preparing" row once the driver is en route).
- Transitions: **numeric content transition** for counting values (scores, timers), **content-replace** when swapping graphics, and when reordering a list animate **only the row that moves**.
- Provide explicit **background and foreground colors** — the system derives the dismiss button's appearance from them.
- **Remove the activity shortly after it ends** — don't let a finished state linger; use a tight dismissal policy rather than the 4-hour default window.
- **StandBy scales the presentation to 200% and won't draw under the sensor region** — verify the layout survives both.

**Dynamic Island presentation:**
- Shapes **concentric with the island's corner radius**, with even margins all around.
- **Compact view: as narrow as possible**, content snug against the sensor housing on both sides.
- **Expanded view preserves the compact view's relative element placement** — leading stays leading, trailing stays trailing, so the transition reads as growth, not rearrangement.
- Avoid a **"forehead"** — an empty band above the sensor. Wrap content around the sensor region instead.
- **Never draw UI that points at or interacts with the island** (arrows toward the cutout, faux hardware jokes).

**Apple Watch (Smart Stack):**
- iPhone Live Activities automatically appear at the top of the watch Smart Stack, auto-generated by re-compositing the Dynamic Island compact-state assets. Adopting the Apple Watch size class — `.supplementalActivityFamilies([.small])` plus a switch on `@Environment(\.activityFamily)` — makes "a significant difference in quality".
- Show only the most critical information: "just the information you need, and nothing more."
- Surface only significant states: progress (time until landing), action required (car arriving), high care (score change).
- Stick to **exactly one control**.
- While the user is actively using the watch, updates appear as a **compact view at the bottom of the display**; pulling it up expands the full widget — design both states.
- The Smart Stack stays visible on wrist-down, so the Activity must stay legible alongside the time.
- Prefer the existing Smart Stack layouts; custom layouts must use standard margins and text styles.

## Common Patterns

### Delivery Tracking
Static: order number, restaurant name
Dynamic: status enum, ETA, driver name

### Sports Score
Static: home team, away team, sport type
Dynamic: home score, away score, period/quarter, game clock

### Workout / Timer
Static: workout type, goal
Dynamic: elapsed time, calories, heart rate, distance

### Ride-Sharing
Static: pickup location, destination
Dynamic: driver name, ETA, vehicle info, status

## Gotchas and Limits

- **Size limit:** `ActivityAttributes` + `ContentState` combined must be under 4KB
- **Concurrent limit:** Maximum 5 active Live Activities per app
- **Duration:** Activities automatically end after 8 hours (can remain on Lock Screen for up to 4 more hours in ended state)
- **Push token changes:** The push token can change during the lifetime of an activity; always observe `pushTokenUpdates`
- **Stale state:** Always set `staleDate` on content to let the system show stale indicators
- **Background updates:** The app can update activities from the background, but not start new ones

## References

- **templates.md** -- Code templates for attributes, widget views, and manager
- [ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Updating and ending your Live Activity with ActivityKit push notifications](https://developer.apple.com/documentation/activitykit/updating-and-ending-your-live-activity-with-activitykit-push-notifications)
