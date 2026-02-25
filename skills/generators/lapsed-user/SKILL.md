---
name: lapsed-user
description: Generates lapsed user detection and re-engagement screens with personalized return experiences, win-back offers, and inactivity tracking. Use when user wants to re-engage inactive users, detect lapsed users, or build return flows.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Lapsed User Re-Engagement Generator

Generate production infrastructure for detecting users who haven't opened the app in X days, showing personalized return screens that highlight what they missed, and optionally presenting win-back incentives to recover churned or lapsing users.

## When This Skill Activates

Use this skill when the user:
- Asks about "lapsed user" detection or re-engagement
- Wants to handle "returning user" or "inactive user" scenarios
- Mentions "re-engagement" screens or flows
- Asks about "win-back" offers for churned users
- Wants to detect when a "user hasn't opened app" in a while
- Asks about "user retention" or "come back" experiences

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 17+ / macOS 14+ for @Observable)
- [ ] Identify source file locations and project structure

### 2. Existing Engagement Tracking
Search for existing engagement or analytics infrastructure:
```
Glob: **/*Analytics*.swift, **/*Engagement*.swift, **/*Tracker*.swift, **/*Activity*.swift
Grep: "lastActiveDate" or "UserDefaults" or "scenePhase" or "applicationDidBecomeActive"
```

If existing tracking found:
- Ask if user wants to integrate with it or build standalone
- If integrating, adapt templates to use existing storage/events

### 3. Push Notification Setup
Search for existing push notification configuration:
```
Glob: **/*Notification*.swift, **/*Push*.swift
Grep: "UNUserNotificationCenter" or "UNNotification" or "registerForRemoteNotifications"
```

If push notifications are configured, offer push-based re-engagement as an option.

### 4. Conflict Detection
Search for existing lapsed user handling:
```
Glob: **/*LapsedUser*.swift, **/*WinBack*.swift, **/*ReturnExperience*.swift, **/*Reengag*.swift
Grep: "lapsedUser" or "winBack" or "returnExperience" or "daysInactive"
```

If existing implementation found:
- Ask if user wants to replace or extend it
- If extending, generate only the missing pieces

## Configuration Questions

Ask user via AskUserQuestion:

1. **Inactivity threshold?**
   - 7 days (light engagement apps — social, news)
   - 14 days (moderate engagement — productivity, fitness) — recommended
   - 30 days (low-frequency apps — finance, travel)
   - Custom (user specifies days)

2. **Re-engagement strategy?**
   - What-You-Missed (highlight new content, features, or activity since last visit)
   - Special Offer (discount or extended trial for lapsed subscribers)
   - Fresh Start (reset onboarding highlights, re-introduce key features)
   - All of the above (tiered by lapse duration)

3. **Trigger mechanism?**
   - Show on app return (present sheet when user opens app after inactivity)
   - Via push notification (schedule local notification after X days inactive)
   - Both — recommended

4. **Include analytics events?**
   - Yes (track lapse detection, return screen shown, CTA tapped, offer redeemed) — recommended
   - No (skip analytics, just UI)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `InactivityTracker.swift` — Tracks last active date, calculates days since last use
2. `LapsedUserDetector.swift` — Evaluates inactivity against thresholds, returns lapse category
3. `LapsedUserManager.swift` — Orchestrator combining detection + experience selection + analytics

### Step 3: Create UI Files
4. `ReturnExperienceView.swift` — Personalized "Welcome back" screen with what-you-missed
5. `WinBackOfferView.swift` — Special offer screen for lapsed subscribers

### Step 4: Create Integration File
6. `LapsedUserModifier.swift` — SwiftUI ViewModifier for root view auto-detection and presentation

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists → `Sources/LapsedUser/`
- If `App/` exists → `App/LapsedUser/`
- Otherwise → `LapsedUser/`

## Output Format

After generation, provide:

### Files Created
```
LapsedUser/
├── InactivityTracker.swift       # Tracks last active date in UserDefaults
├── LapsedUserDetector.swift      # Evaluates inactivity thresholds
├── LapsedUserManager.swift       # Orchestrator for detection + experience
├── ReturnExperienceView.swift    # Welcome back screen with highlights
├── WinBackOfferView.swift        # Special offer for lapsed subscribers
└── LapsedUserModifier.swift      # ViewModifier for auto-detection
```

### Integration at App Launch

**Attach to root view:**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .lapsedUserDetection()
        }
    }
}
```

**Manual detection (if you need control over presentation):**
```swift
struct ContentView: View {
    @State private var manager = LapsedUserManager()

    var body: some View {
        NavigationStack {
            MainView()
        }
        .task {
            await manager.checkOnReturn()
        }
        .sheet(item: $manager.returnExperience) { experience in
            ReturnExperienceView(experience: experience)
        }
        .sheet(item: $manager.winBackOffer) { offer in
            WinBackOfferView(offer: offer)
        }
    }
}
```

**With custom thresholds:**
```swift
let detector = LapsedUserDetector(
    recentThreshold: 7,     // 1-7 days: recently inactive
    moderateThreshold: 21,  // 8-21 days: moderately lapsed
    longTermThreshold: 60   // 22-60 days: long-term lapsed
)
```

**Win-back offer for lapsed subscribers:**
```swift
WinBackOfferView(offer: WinBackOffer(
    headline: "We missed you!",
    discount: .percentage(30),
    originalPrice: "$9.99/mo",
    offerPrice: "$6.99/mo",
    expiresIn: .days(7),
    productID: "com.app.premium.monthly"
))
```

### Testing

```swift
@Test
func detectsRecentlyInactiveUser() async {
    let tracker = InactivityTracker(store: MockUserDefaults())
    tracker.recordActivity()

    // Simulate 5 days of inactivity
    tracker.override(lastActiveDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!)

    let detector = LapsedUserDetector(tracker: tracker)
    let category = detector.evaluate()
    #expect(category == .recentlyInactive)
}

@Test
func longTermLapsedUserGetsWinBackOffer() async {
    let tracker = InactivityTracker(store: MockUserDefaults())
    tracker.override(lastActiveDate: Calendar.current.date(byAdding: .day, value: -45, to: Date())!)

    let manager = LapsedUserManager(tracker: tracker, isSubscriber: true)
    await manager.checkOnReturn()

    #expect(manager.winBackOffer != nil)
    #expect(manager.returnExperience != nil)
}

@Test
func activeUserSeesNothing() async {
    let tracker = InactivityTracker(store: MockUserDefaults())
    tracker.recordActivity() // Just opened the app

    let manager = LapsedUserManager(tracker: tracker)
    await manager.checkOnReturn()

    #expect(manager.returnExperience == nil)
    #expect(manager.winBackOffer == nil)
}
```

## Common Patterns

### Detect on App Become Active
```swift
// In your App struct or root view
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        inactivityTracker.recordActivity()
    }
}
```

### Show Return Screen
```swift
// LapsedUserManager determines what to show based on:
// 1. How long the user has been away
// 2. Whether they are/were a subscriber
// 3. What changed in the app since their last visit
let experience = manager.buildReturnExperience(
    category: .moderatelyLapsed,
    changelog: appChangelog.since(tracker.lastActiveDate)
)
```

### Trigger Win-Back Offer
```swift
// Only show win-back to users who previously had a subscription
if detector.category.isLapsed && subscriptionStatus == .expired {
    manager.presentWinBackOffer(
        discount: .percentage(30),
        duration: .days(7)
    )
}
```

## Gotchas

### Background App Refresh vs Actual Absence
Background app refresh triggers `applicationDidBecomeActive` without user interaction. Use `scenePhase` changes to `.active` paired with the app being in `.background` (not `.inactive`) to avoid false positives. Track whether the user actually interacted (foreground time > threshold).

### Timezone-Aware Date Math
Always use `Calendar.current` for day calculations, not raw `TimeInterval` division. A user who opened the app at 11pm and returns at 1am the next day has been away for 2 hours, not 1 day.

```swift
// Wrong - raw seconds
let daysAway = Date().timeIntervalSince(lastActive) / 86400

// Right - calendar-aware
let daysAway = Calendar.current.dateComponents([.day], from: lastActive, to: Date()).day ?? 0
```

### Don't Annoy Deliberate Break-Takers
Provide a "Don't show again" option on the return screen. Respect user preferences — if they dismiss the return experience, increase the threshold before showing again. Store dismissal count and back off exponentially.

### Avoid Stacking with Other Modals
If your app has onboarding, what's-new, or review prompts, coordinate with them. Don't show a return screen AND a review prompt AND a what's-new modal on the same launch. Use a presentation queue.

### Testing Date-Dependent Logic
Inject the date source so tests can control "now":
```swift
let tracker = InactivityTracker(
    store: mockDefaults,
    currentDate: { Date(timeIntervalSince1970: 1700000000) }
)
```

## References

- **templates.md** — All production Swift templates
- Related: `generators/subscription-lifecycle` — Subscription state management
- Related: `generators/whats-new` — What's New screen generation
