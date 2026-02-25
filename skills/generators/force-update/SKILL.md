---
name: force-update
description: Generates a minimum version enforcement system with hard-block and soft-prompt update flows, App Store redirect, and remote config or App Store lookup for version checks. Use when user wants force update, mandatory update, or minimum version check.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Force Update Generator

Generate a minimum version check system that blocks app usage when a critical update is required, or shows a dismissible prompt for recommended updates. Checks the current app version against a remote configuration endpoint or the App Store lookup API and presents the appropriate UI.

## When This Skill Activates

Use this skill when the user:
- Asks to "add force update" or "force update screen"
- Wants "minimum version check" or "minimum version enforcement"
- Mentions "required update" or "mandatory update"
- Asks about "version check" or "app version check"
- Wants an "app update prompt" or "update dialog"
- Mentions "block old versions" or "deprecate old versions"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing version check code:
```
Glob: **/*ForceUpdate*.swift, **/*VersionCheck*.swift, **/*UpdateManager*.swift, **/*AppVersion*.swift
Grep: "ForceUpdate" or "minimumVersion" or "mandatoryUpdate" or "CFBundleShortVersionString"
```

If an existing update mechanism is found:
- Ask if user wants to replace or extend it
- If extending, integrate with the existing check flow

### 3. Network Layer Detection
Search for existing networking code:
```
Glob: **/*API*.swift, **/*Client*.swift, **/*Network*.swift
Grep: "APIClient" or "URLSession" or "NetworkService"
```

If a networking layer exists, generate the version checker to use it rather than raw URLSession.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Update check source?**
   - Remote JSON endpoint (your own server hosts a JSON config) — recommended
   - App Store lookup API (uses iTunes Search API, no server needed)
   - Firebase Remote Config (requires Firebase SDK)

2. **Update types to support?**
   - Hard block only (always force update)
   - Soft prompt only (always dismissible)
   - Both hard block and soft prompt — recommended

3. **Check frequency?**
   - Every app launch
   - Once per day — recommended
   - Once per week

4. **Include skip option for soft updates?**
   - Yes — user can skip a specific version and won't be prompted again until a newer version is available
   - No — prompt shows every time (respecting check frequency)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `AppVersion.swift` — Semantic version model (major.minor.patch) with Comparable
2. `UpdateRequirement.swift` — Enum: none, softUpdate, hardUpdate with message and store URL
3. `VersionChecker.swift` — Protocol + implementation based on chosen source

### Step 3: Create Manager
4. `UpdateManager.swift` — @Observable manager that coordinates checks, caches timing, exposes state

### Step 4: Create UI Files
5. `ForceUpdateView.swift` — Full-screen blocking view with App Store button
6. `SoftUpdateBannerView.swift` — Dismissible banner with Update and Later buttons

### Step 5: Create Integration
7. `UpdateCheckModifier.swift` — ViewModifier that auto-checks on appear and presents UI

### Step 6: Determine File Location
Check project structure:
- If `Sources/` exists → `Sources/ForceUpdate/`
- If `App/` exists → `App/ForceUpdate/`
- Otherwise → `ForceUpdate/`

## Output Format

After generation, provide:

### Files Created
```
ForceUpdate/
├── AppVersion.swift           # Semantic version model with Comparable
├── UpdateRequirement.swift    # none / softUpdate / hardUpdate enum
├── VersionChecker.swift       # Protocol + remote/App Store implementation
├── UpdateManager.swift        # @Observable coordinator
├── ForceUpdateView.swift      # Full-screen blocking UI
├── SoftUpdateBannerView.swift # Dismissible banner UI
└── UpdateCheckModifier.swift  # ViewModifier for auto-check
```

### Integration Steps

**Add the modifier to your root view:**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .checkForUpdates()
        }
    }
}
```

**Custom configuration:**
```swift
ContentView()
    .checkForUpdates(
        checker: RemoteJSONVersionChecker(
            url: URL(string: "https://api.example.com/app-config")!
        ),
        frequency: .daily
    )
```

**Manual check from a settings screen:**
```swift
struct SettingsView: View {
    @Environment(UpdateManager.self) private var updateManager

    var body: some View {
        Section("App") {
            if case .softUpdate(_, let message) = updateManager.requirement {
                Button("Update Available") {
                    updateManager.openAppStore()
                }
            }

            Button("Check for Updates") {
                Task { await updateManager.checkNow() }
            }
        }
    }
}
```

### Testing

```swift
@Test
func hardUpdateBlocksWhenBelowMinimum() async throws {
    let checker = MockVersionChecker(
        requirement: .hardUpdate(
            version: AppVersion(major: 2, minor: 0, patch: 0),
            message: "Critical security fix"
        )
    )
    let manager = UpdateManager(
        checker: checker,
        currentVersion: AppVersion(major: 1, minor: 0, patch: 0)
    )

    await manager.checkNow()

    guard case .hardUpdate = manager.requirement else {
        Issue.record("Expected hard update requirement")
        return
    }
}

@Test
func softUpdateAllowsSkip() async throws {
    let checker = MockVersionChecker(
        requirement: .softUpdate(
            version: AppVersion(major: 1, minor: 5, patch: 0),
            message: "New features available"
        )
    )
    let manager = UpdateManager(
        checker: checker,
        currentVersion: AppVersion(major: 1, minor: 0, patch: 0)
    )

    await manager.checkNow()
    manager.skipCurrentUpdate()

    #expect(manager.requirement == .none)
}

@Test
func respectsCheckFrequency() async throws {
    let checker = MockVersionChecker(requirement: .none)
    let manager = UpdateManager(checker: checker, frequency: .daily)

    await manager.checkNow()
    #expect(checker.checkCount == 1)

    // Second check within frequency window should skip
    await manager.checkIfNeeded()
    #expect(checker.checkCount == 1)
}
```

## Common Patterns

### Check on Every Launch
```swift
// In your App's root view
ContentView()
    .checkForUpdates(frequency: .everyLaunch)
```

### Hard Block for Critical Security Updates
The remote JSON should differentiate between hard and soft:
```json
{
    "minimumVersion": "2.0.0",
    "minimumVersionMessage": "This version is no longer supported. Please update for security fixes.",
    "recommendedVersion": "2.1.0",
    "recommendedVersionMessage": "Update for new features and improvements.",
    "storeURL": "https://apps.apple.com/app/id123456789"
}
```

### Soft Prompt with Skip
```swift
SoftUpdateBannerView(
    message: "A new version is available",
    onUpdate: { updateManager.openAppStore() },
    onSkip: { updateManager.skipCurrentUpdate() }
)
```

## Gotchas

### App Store Lookup API Rate Limits
The iTunes Search API (`itunes.apple.com/lookup?bundleId=...`) has undocumented rate limits. For high-volume apps, prefer a remote JSON endpoint you control. Cache the response and avoid calling on every cold launch.

### Version String Comparison
Never compare version strings lexicographically — `"9.0.0" > "10.0.0"` evaluates to `true`. Always parse into semantic version components (major, minor, patch) and compare numerically.

### Don't Block During Onboarding
If the user hasn't completed onboarding, defer the force update check until after. Blocking a first-launch user with an update screen creates confusion.

### Offline Handling
If the version check network request fails, do **not** block the user. Default to `.none` (allow usage). Only block when you have a confirmed response that the version is below minimum.

### TestFlight and Debug Builds
Skip force update checks for TestFlight and debug builds. TestFlight builds always have a higher build number but may have a lower marketing version during development:
```swift
#if DEBUG
// Skip version check
#else
// Check version
#endif
```

### App Review Rejection Risk
Apple may reject apps that show an update prompt during review if the current App Store version is the one under review. Consider disabling the check when the app is running in a sandbox/review environment.

## References

- **templates.md** — All production Swift code templates
- Related: `generators/networking-layer` — Base networking layer for API calls
- Related: `generators/feature-flags` — Feature flags can control update enforcement
- Related: `generators/whats-new` — Show what's new after an update completes
