---
name: streak-tracker
description: Generates a streak tracking system with timezone-aware day boundaries, streak freeze protection, and streak-at-risk push notifications. Use when user wants daily/weekly engagement streaks, consecutive day tracking, or habit tracking.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Streak Tracker Generator

Generate a production streak tracking system that records consecutive days of user activity, calculates current and longest streaks, handles timezone-aware day boundaries, supports streak freeze/protection passes, and schedules streak-at-risk local notifications.

## When This Skill Activates

Use this skill when the user:
- Asks to "add streaks" or "daily streak" tracking
- Wants "streak tracking" or "consecutive days" counting
- Mentions "engagement streaks" or "habit tracking"
- Asks about "streak freeze" or "streak protection"
- Wants "streak-at-risk" notifications or reminders
- Mentions "login streak" or "activity streak"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 17+ / macOS 14+ for @Observable and SwiftData)
- [ ] Check for SwiftData availability and existing model container setup
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing streak or habit tracking:
```
Glob: **/*Streak*.swift, **/*Habit*.swift, **/*DailyTrack*.swift
Grep: "streak" or "consecutiveDays" or "habitTrack" or "dailyStreak"
```

If existing streak/habit system found:
- Ask if user wants to replace or extend it
- If extending, generate only the missing components

### 3. Platform Detection
Determine if generating for iOS (UNUserNotificationCenter) or macOS (UNUserNotificationCenter available on macOS 11+) or both.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Streak type?**
   - Daily (consecutive calendar days) -- recommended
   - Weekly (at least one activity per calendar week)
   - Custom interval (every N hours/days)

2. **Storage backend?**
   - SwiftData (recommended for iOS 17+ / macOS 14+)
   - UserDefaults (lightweight, no model container needed)

3. **Include streak freeze/protection?**
   - Yes — users get limited freeze passes to preserve streaks on missed days
   - No — strict consecutive tracking only

4. **Streak-at-risk notifications?**
   - Yes — schedule a local notification (e.g., 8 PM) if no activity recorded today
   - No — no notifications

5. **Additional features?** (multi-select)
   - Calendar heat map view (visual grid of activity days)
   - Streak badge view (compact count with animation)
   - Milestone celebrations (7-day, 30-day, 100-day, etc.)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `StreakRecord.swift` — SwiftData @Model for activity records
2. `StreakManager.swift` — @Observable class: record activity, calculate streaks, manage freezes
3. `StreakError.swift` — Error types for streak operations

### Step 3: Create UI Files
4. `StreakCalendarView.swift` — Grid showing days with/without activity
5. `StreakBadgeView.swift` — Compact badge with streak count and animation

### Step 4: Create Optional Files
Based on configuration:
- `StreakFreeze.swift` — If streak freeze selected
- `StreakNotificationScheduler.swift` — If notifications selected

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/StreakTracking/`
- If `App/` exists -> `App/StreakTracking/`
- Otherwise -> `StreakTracking/`

## Output Format

After generation, provide:

### Files Created
```
StreakTracking/
├── StreakRecord.swift               # SwiftData model for activity records
├── StreakManager.swift              # Core streak calculation engine
├── StreakError.swift                # Error types
├── StreakCalendarView.swift         # Calendar heat map view
├── StreakBadgeView.swift            # Compact animated badge
├── StreakFreeze.swift               # Freeze/protection passes (optional)
└── StreakNotificationScheduler.swift # Streak-at-risk reminders (optional)
```

### Integration Steps

**Set up the model container (SwiftData):**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [StreakRecord.self, StreakFreeze.self])
    }
}
```

**Record activity on user action:**
```swift
struct LessonCompleteView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var streakManager: StreakManager?

    var body: some View {
        Button("Complete Lesson") {
            Task {
                try await streakManager?.recordActivity(type: "lesson")
            }
        }
        .onAppear {
            streakManager = StreakManager(modelContext: modelContext)
        }
    }
}
```

**Display the current streak:**
```swift
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var streakManager: StreakManager?

    var body: some View {
        VStack {
            if let manager = streakManager {
                StreakBadgeView(streak: manager.currentStreak)
                Text("Longest: \(manager.longestStreak) days")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            streakManager = StreakManager(modelContext: modelContext)
            Task { await streakManager?.refresh() }
        }
    }
}
```

**Show the calendar heat map:**
```swift
struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var streakManager: StreakManager?

    var body: some View {
        if let manager = streakManager {
            StreakCalendarView(manager: manager)
        }
    }
}
```

**Use a streak freeze:**
```swift
Button("Use Streak Freeze") {
    if streakManager.useStreakFreeze() {
        // Freeze applied — streak preserved
    } else {
        // No freezes available
    }
}
```

### Testing

```swift
import Testing
import SwiftData

@Test
func recordingActivityIncrementsStreak() async throws {
    let container = try ModelContainer(
        for: StreakRecord.self, StreakFreeze.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let manager = StreakManager(modelContext: context)

    // Record activity for today
    try await manager.recordActivity(type: "workout")
    await manager.refresh()

    #expect(manager.currentStreak == 1)
}

@Test
func consecutiveDaysBuildStreak() async throws {
    let container = try ModelContainer(
        for: StreakRecord.self, StreakFreeze.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let manager = StreakManager(modelContext: context)

    // Simulate 3 consecutive days
    let calendar = Calendar.current
    for daysAgo in (0...2).reversed() {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
        try await manager.recordActivity(type: "workout", date: date)
    }
    await manager.refresh()

    #expect(manager.currentStreak == 3)
    #expect(manager.longestStreak == 3)
}

@Test
func missedDayBreaksStreak() async throws {
    let container = try ModelContainer(
        for: StreakRecord.self, StreakFreeze.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let manager = StreakManager(modelContext: context)

    let calendar = Calendar.current
    // Day 3 ago and Day 2 ago (streak of 2), then skip Day 1, record today
    let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: .now)!
    let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: .now)!
    try await manager.recordActivity(type: "workout", date: threeDaysAgo)
    try await manager.recordActivity(type: "workout", date: twoDaysAgo)
    try await manager.recordActivity(type: "workout", date: .now)
    await manager.refresh()

    #expect(manager.currentStreak == 1) // Gap broke the streak
    #expect(manager.longestStreak == 2) // Previous streak preserved
}

@Test
func streakFreezePreservesStreak() async throws {
    let container = try ModelContainer(
        for: StreakRecord.self, StreakFreeze.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let manager = StreakManager(modelContext: context)

    let calendar = Calendar.current
    // Record 2 days ago and today — gap of 1 day
    let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: .now)!
    try await manager.recordActivity(type: "workout", date: twoDaysAgo)
    manager.addStreakFreeze(count: 1)
    let used = manager.useStreakFreeze()
    try await manager.recordActivity(type: "workout", date: .now)
    await manager.refresh()

    #expect(used == true)
    #expect(manager.currentStreak == 3) // 2 days ago + freeze + today
}
```

## Common Patterns

### Check In for Today
```swift
// Record a single check-in per day (idempotent)
try await streakManager.recordActivity(type: "daily-check-in")
// StreakManager deduplicates — calling twice on the same day is safe
```

### Query Streak State
```swift
let current = streakManager.currentStreak    // Consecutive days up to today
let longest = streakManager.longestStreak    // All-time best
let atRisk = streakManager.isStreakAtRisk    // No activity today yet
let hasActivity = streakManager.hasActivityToday
```

### Streak Freeze
```swift
// Grant freeze passes (e.g., as a reward or purchase)
streakManager.addStreakFreeze(count: 2)

// Use a freeze to cover a missed day
let success = streakManager.useStreakFreeze()
// Returns false if no freezes remaining or no gap to fill
```

## Gotchas & Edge Cases

### Timezone and Day Boundary Handling
Always use `Calendar.current.startOfDay(for:)` to normalize dates. Never compare raw `Date` values for "same day" checks — a user active at 11:59 PM and 12:01 AM has activity on two different calendar days but should not get a gap. The `StreakManager` uses the user's local calendar for all day boundary calculations.

### Midnight Edge Cases
If a user completes an activity exactly at midnight, `startOfDay(for:)` may place it on the new day. The templates handle this by recording the timestamp as well as the normalized date, so the raw data is preserved for debugging.

### Device Clock Manipulation
Users can change their device clock to fake streak activity. Mitigations:
- Store `createdAt` timestamps alongside `activityDate` and flag anomalies (e.g., `createdAt` is before a previously recorded `createdAt`)
- For server-synced apps, validate streaks server-side
- For local-only apps, accept that determined users can game it — focus on honest users

### Calendar vs Gregorian Day Changes
Different calendars (Islamic, Hebrew, Japanese) have different day boundaries and week structures. The templates use `Calendar.current` which respects the user's locale. If your app requires a fixed calendar (e.g., Gregorian for global leaderboards), pass an explicit `Calendar(identifier: .gregorian)` to `StreakManager`.

### Duplicate Activity on Same Day
`StreakManager.recordActivity` is idempotent per calendar day per activity type. Calling it multiple times on the same day creates only one `StreakRecord`. This prevents accidental double-counting.

### App Reinstall / Data Loss
SwiftData stores persist across app updates but are lost on reinstall. For critical streak data, consider syncing to CloudKit or a backend. The templates include a `lastSyncDate` hook in `StreakManager` for this purpose.

## References

- **templates.md** — All production Swift templates for streak tracking
- Related: `generators/push-notifications` — Push notification setup for streak reminders
- Related: `generators/milestone-celebration` — Celebrate streak milestones with animations
