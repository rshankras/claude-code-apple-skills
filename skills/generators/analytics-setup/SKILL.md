---
name: analytics-setup
description: Generates protocol-based analytics infrastructure with swappable providers (TelemetryDeck, Firebase, Mixpanel). Use when user wants to add analytics, track events, or set up telemetry.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Analytics Setup Generator

Generate a protocol-based analytics infrastructure that makes it easy to swap providers without changing app code.

## When This Skill Activates

Use this skill when the user:
- Asks to "add analytics" or "set up analytics"
- Mentions "TelemetryDeck", "Firebase Analytics", "Mixpanel"
- Wants to "track events" or "add telemetry"
- Asks about "privacy-friendly analytics"
- Wants to swap analytics providers

## Key Feature: Swappable Providers

The generated code uses a protocol-based architecture:

```swift
// Your app uses the protocol
analytics.track(.buttonTapped("subscribe"))

// Swap providers by changing ONE line:
let analytics: AnalyticsService = TelemetryDeckAnalytics() // or FirebaseAnalytics()
```

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing analytics implementations
- [ ] Look for TelemetryDeck/Firebase/Mixpanel in Package.swift or Podfile
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing analytics:
```
Glob: **/*Analytics*.swift, **/*Telemetry*.swift
Grep: "protocol.*Analytics" or "TelemetryDeck" or "Firebase"
```

If found, ask user:
- Extend existing analytics?
- Replace with new implementation?
- Add new provider to existing setup?

## Configuration Questions

Ask user via AskUserQuestion:

1. **Which provider(s)?**
   - TelemetryDeck (privacy-friendly, recommended)
   - Firebase Analytics
   - Mixpanel
   - None (NoOp for now, add later)

2. **What events to track?**
   - App lifecycle (launch, background, foreground)
   - Screen views
   - User actions (buttons, features used)
   - Errors
   - Custom events

3. **User properties?**
   - App version
   - Subscription status
   - Custom properties

## Generation Process

### Step 1: Create Core Files

Always generate these files:
1. `AnalyticsService.swift` - Protocol (never changes)
2. `AnalyticsEvent.swift` - Event definitions (app-specific)
3. `NoOpAnalytics.swift` - For testing/privacy mode

### Step 2: Create Selected Provider(s)

Based on user selection:
- `TelemetryDeckAnalytics.swift`
- `FirebaseAnalytics.swift`
- `MixpanelAnalytics.swift`

### Step 3: Create Environment Integration

For SwiftUI apps:
- `AnalyticsServiceKey.swift` - Environment key for dependency injection

### Step 4: Determine File Location

Check project structure:
- If `Sources/` exists → `Sources/Analytics/`
- If `App/` exists → `App/Analytics/`
- Otherwise → `Analytics/`

## Output Format

After generation, provide:

### Files Created
```
Sources/Analytics/
├── AnalyticsService.swift          # Protocol (stable interface)
├── AnalyticsEvent.swift            # Your app's events
├── Providers/
│   ├── NoOpAnalytics.swift         # Testing/privacy
│   └── [Provider]Analytics.swift   # Selected provider(s)
└── AnalyticsServiceKey.swift       # SwiftUI Environment (optional)
```

### Integration Steps

**App Entry Point:**
```swift
@main
struct MyApp: App {
    // Choose your provider
    private let analytics: AnalyticsService = TelemetryDeckAnalytics(appID: "YOUR-APP-ID")

    init() {
        analytics.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.analytics, analytics)
        }
    }
}
```

**Tracking Events:**
```swift
struct ContentView: View {
    @Environment(\.analytics) private var analytics

    var body: some View {
        Button("Subscribe") {
            analytics.track(.buttonTapped("subscribe"))
        }
    }
}
```

### Required Dependencies

**TelemetryDeck:**
```swift
// Package.swift
.package(url: "https://github.com/TelemetryDeck/SwiftClient", from: "1.0.0")
```

**Firebase:**
```swift
// Package.swift
.package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
// Also requires GoogleService-Info.plist
```

### Swapping Providers Later

To switch providers:
1. Add new provider file (or generate with this skill)
2. Change ONE line in App.swift:
```swift
// Before
private let analytics: AnalyticsService = TelemetryDeckAnalytics(...)

// After
private let analytics: AnalyticsService = FirebaseAnalytics()
```

### Testing
- Use `NoOpAnalytics()` in tests and previews
- All tracking calls become no-ops
- No external dependencies in tests

## References

- **analytics-patterns.md** - Protocol architecture and best practices
- **templates/** - All template files
