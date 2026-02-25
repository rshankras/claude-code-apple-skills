---
name: whats-new
description: Generates a "What's New" / changelog screen shown after app updates with version tracking, feature highlights, and one-time display per version. Use when user wants release notes UI, update notifications, or feature announcements.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# What's New Generator

Generate a complete "What's New" screen that displays after app updates — highlights new features, changes, and improvements with version tracking to ensure it only shows once per update.

## When This Skill Activates

Use this skill when the user:
- Asks to "add a what's new screen" or "show what's new"
- Mentions "changelog" or "changelog UI"
- Wants an "app update screen" or "update notification"
- Asks about "new features screen" or "feature announcements"
- Mentions "release notes UI" or "release notes screen"
- Wants a "version update notification" or "post-update screen"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (iOS 16+ / macOS 13+ minimum; iOS 17+ / macOS 14+ for @Observable)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Identify source file locations and project structure
- [ ] Determine how app version is accessed (`Bundle.main.infoDictionary`, custom build config, etc.)

### 2. Conflict Detection
Search for existing what's new or changelog implementations:
```
Glob: **/*WhatsNew*.swift, **/*Changelog*.swift, **/*ReleaseNotes*.swift, **/*VersionTracker*.swift
Grep: "WhatsNew" or "whatsNew" or "lastShownVersion" or "changelog"
```

If found, ask user:
- Replace existing implementation?
- Keep existing, integrate alongside?

### 3. Version Access Pattern
Detect how the app reads its version:
```
Grep: "CFBundleShortVersionString" or "Bundle.main.infoDictionary" or "appVersion"
```

Use whichever pattern the project already employs. If none found, default to `Bundle.main.infoDictionary?["CFBundleShortVersionString"]`.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Presentation style?**
   - Sheet (recommended — `.sheet(item:)` auto-dismiss)
   - Full-screen cover (`.fullScreenCover`)
   - Inline (embedded in a view hierarchy)

2. **Content source?**
   - Hardcoded in Swift (simplest, no network needed)
   - Local JSON file bundled in app
   - Remote JSON endpoint (fetched on launch)

3. **Dismiss behavior?**
   - "Continue" button (explicit acknowledgment)
   - Swipe to dismiss (sheet default)
   - Both (button + swipe)

4. **Page indicators?**
   - Dot indicators (TabView page style)
   - Page count label ("1 of 3")
   - None (single scrollable view)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `WhatsNewFeature.swift` — Model for a single feature (title, description, SF Symbol, tint color)
2. `WhatsNewRelease.swift` — Groups features by version string with date
3. `VersionTracker.swift` — Tracks last-shown version in UserDefaults, compares against current bundle version
4. `WhatsNewProvider.swift` — Protocol + local implementation (optional remote)

### Step 3: Create UI Files
5. `WhatsNewView.swift` — Paged view with TabView(.page) showing features
6. `WhatsNewSheet.swift` — Wrapper that auto-presents via `.sheet(item:)` when new version detected

### Step 4: Create Optional Files
Based on configuration:
- `RemoteWhatsNewProvider.swift` — If remote content source selected
- `WhatsNewJSON.swift` — If local JSON source selected

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/WhatsNew/`
- If `App/` exists -> `App/WhatsNew/`
- Otherwise -> `WhatsNew/`

## Output Format

After generation, provide:

### Files Created
```
WhatsNew/
├── WhatsNewFeature.swift       # Single feature model
├── WhatsNewRelease.swift       # Version-grouped features
├── VersionTracker.swift        # Version persistence & comparison
├── WhatsNewProvider.swift      # Content provider protocol + local impl
├── WhatsNewView.swift          # Paged feature display
├── WhatsNewSheet.swift         # Auto-presenting sheet wrapper
└── RemoteWhatsNewProvider.swift # Remote content (optional)
```

### Integration Steps

**Option 1: View Modifier Style (Recommended)**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .whatsNewSheet()  // Automatically shows after updates
        }
    }
}
```

**Option 2: Manual Control in Root View**
```swift
@main
struct MyApp: App {
    @State private var whatsNewRelease: WhatsNewRelease?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(item: $whatsNewRelease) { release in
                    WhatsNewView(release: release)
                }
                .task {
                    let tracker = VersionTracker()
                    if tracker.shouldShowWhatsNew() {
                        whatsNewRelease = WhatsNewProvider.local.latestRelease()
                    }
                }
        }
    }
}
```

**Option 3: Inline Embedding**
```swift
struct HomeView: View {
    @State private var tracker = VersionTracker()

    var body: some View {
        VStack {
            if tracker.shouldShowWhatsNew(),
               let release = WhatsNewProvider.local.latestRelease() {
                WhatsNewView(release: release) {
                    tracker.markVersionAsShown()
                }
            }
            // Rest of home content...
        }
    }
}
```

### Adding New Releases

```swift
// In LocalWhatsNewProvider.swift — add a new entry per release
static let releases: [WhatsNewRelease] = [
    WhatsNewRelease(
        version: "2.1.0",
        date: Date(timeIntervalSince1970: 1_700_000_000),
        features: [
            WhatsNewFeature(
                title: "Dark Mode Support",
                description: "Full dark mode across all screens.",
                systemImage: "moon.fill",
                tintColor: .indigo
            ),
            WhatsNewFeature(
                title: "Faster Search",
                description: "Search results now appear instantly.",
                systemImage: "magnifyingglass",
                tintColor: .orange
            ),
        ]
    ),
    // Previous releases...
]
```

### Testing

```swift
@Test
func showsWhatsNewForNewVersion() {
    let defaults = UserDefaults(suiteName: "TestWhatsNew")!
    defaults.removePersistentDomain(forName: "TestWhatsNew")

    let tracker = VersionTracker(
        defaults: defaults,
        currentVersion: "2.0.0"
    )

    // First launch — no previous version stored
    #expect(tracker.shouldShowWhatsNew() == true)

    tracker.markVersionAsShown()
    #expect(tracker.shouldShowWhatsNew() == false)
}

@Test
func skipsWhatsNewWhenVersionUnchanged() {
    let defaults = UserDefaults(suiteName: "TestWhatsNew2")!
    defaults.removePersistentDomain(forName: "TestWhatsNew2")

    let tracker = VersionTracker(
        defaults: defaults,
        currentVersion: "1.5.0"
    )
    tracker.markVersionAsShown()

    // Same version — should not show
    let tracker2 = VersionTracker(
        defaults: defaults,
        currentVersion: "1.5.0"
    )
    #expect(tracker2.shouldShowWhatsNew() == false)
}

@Test
func showsWhatsNewAfterUpdate() {
    let defaults = UserDefaults(suiteName: "TestWhatsNew3")!
    defaults.removePersistentDomain(forName: "TestWhatsNew3")

    let tracker = VersionTracker(
        defaults: defaults,
        currentVersion: "1.0.0"
    )
    tracker.markVersionAsShown()

    // Simulate update
    let trackerAfterUpdate = VersionTracker(
        defaults: defaults,
        currentVersion: "2.0.0"
    )
    #expect(trackerAfterUpdate.shouldShowWhatsNew() == true)
}
```

## Common Patterns

### Define Features Per Version
Group features by release version so older users who skipped updates still see relevant changes:
```swift
// Show features for all versions newer than lastShownVersion
func featuresSinceLastShown() -> [WhatsNewFeature] {
    let lastShown = tracker.lastShownVersion ?? "0.0.0"
    return releases
        .filter { $0.version.compare(lastShown, options: .numeric) == .orderedDescending }
        .flatMap(\.features)
}
```

### Conditional Display
Only show if there are actually features to display for the current version:
```swift
if let release = provider.release(for: currentVersion),
   tracker.shouldShowWhatsNew() {
    // Present What's New
}
```

### Remote Content Loading
Fetch features from a server to update without app releases:
```swift
let provider = RemoteWhatsNewProvider(
    endpoint: URL(string: "https://api.example.com/whats-new")!,
    fallback: LocalWhatsNewProvider()  // Offline fallback
)
let release = try await provider.latestRelease()
```

## Gotchas

### CFBundleShortVersionString vs CFBundleVersion
- `CFBundleShortVersionString` = marketing version (e.g., "2.1.0") — use this for What's New
- `CFBundleVersion` = build number (e.g., "47") — changes every build, NOT suitable for What's New tracking
- Always compare the marketing version, never the build number

### First Install vs Update Detection
- On first install, `lastShownVersion` is `nil`
- Decide whether first-time users should see What's New (usually NO — show onboarding instead)
- If `lastShownVersion` is `nil`, either skip What's New or set the current version without showing:
```swift
func shouldShowWhatsNew() -> Bool {
    guard let lastShown = lastShownVersion else {
        // First install — mark current version, don't show
        markVersionAsShown()
        return false
    }
    return currentVersion.compare(lastShown, options: .numeric) == .orderedDescending
}
```

### TestFlight vs App Store Versions
- TestFlight builds may have the same marketing version but different build numbers
- If using TestFlight for beta testing, consider including build number in tracking key for testers
- For production, always track by marketing version only

### Version String Comparison
- Use `.numeric` option in `String.compare(_:options:)` so "2.0.0" > "1.10.0" (not lexicographic)
- Never compare version strings with `<` or `>` operators directly — "9.0" would sort after "10.0" lexicographically

### Accessibility
- Ensure all feature images have accessibility labels
- Support Dynamic Type in feature descriptions
- VoiceOver should read features sequentially — use `.accessibilityElement(children: .combine)` on feature cards

## References

- **templates.md** — All production Swift templates
- Related: `generators/onboarding-generator` — First-launch onboarding (complementary — onboarding for first install, What's New for updates)
