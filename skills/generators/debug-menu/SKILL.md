---
name: debug-menu
description: Generates a developer debug menu with feature flag toggles, environment switching, network log viewer, cache clearing, crash trigger, and diagnostic info export. Only included in DEBUG builds. Use when user wants a debug panel, dev tools menu, or shake-to-debug functionality.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Debug Menu Generator

Generate a comprehensive developer debug menu accessible via shake gesture or hidden tap. Includes feature flag toggles, environment switching, network log viewer, cache clearing, crash trigger, and diagnostic info export. All code is wrapped in `#if DEBUG` so it never ships to production.

## When This Skill Activates

Use this skill when the user:
- Asks for a "debug menu" or "developer menu"
- Wants "dev tools" or a "debug panel"
- Mentions "shake to debug" or "diagnostic menu"
- Wants to "toggle feature flags" from the app
- Asks about "environment switching" (dev/staging/production)
- Wants a "network log viewer" in the app

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (iOS 17+ / macOS 14+ required for @Observable)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Identify source file locations and project structure

### 2. Conflict Detection
Search for existing debug/dev menu code:
```
Glob: **/*Debug*Menu*.swift, **/*DevMenu*.swift, **/*DevTools*.swift, **/*DebugPanel*.swift
Grep: "DebugMenu" or "DevMenu" or "motionEnded" or "shake" in *.swift
```

If existing debug menu found:
- Ask if user wants to replace or extend it
- If extending, integrate new sections into existing structure

### 3. Feature Flags Detection
Search for existing feature flag setup:
```
Glob: **/*FeatureFlag*.swift, **/*Feature*Toggle*.swift
Grep: "FeatureFlag" or "featureFlag" or "isFeatureEnabled"
```

If found, integrate debug menu toggles with existing feature flag system rather than creating a new one.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Access method?**
   - Shake gesture (shake device to open)
   - Hidden tap (5-tap on a hidden area)
   - Both (shake + hidden tap) -- recommended

2. **Sections to include?** (multi-select)
   - Feature flags (toggle flags on/off at runtime)
   - Environment switcher (dev / staging / production)
   - Network logs (recent requests with status codes and timing)
   - Cache tools (clear image cache, HTTP cache, all caches)
   - Crash trigger (force crash for Crashlytics testing)
   - Diagnostics (device info, memory, disk, app version)

3. **Include push notification testing?**
   - Yes (simulate local push notifications for testing)
   - No

4. **Include export diagnostics?**
   - Yes (share sheet with full diagnostic report)
   - No

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code wrapped in `#if DEBUG`.

### Step 2: Create Core Files
Generate these files (all wrapped in `#if DEBUG`):
1. `DebugMenuView.swift` -- Main NavigationStack with all sections
2. `DebugSection.swift` -- Enum defining available debug sections

### Step 3: Create Section Files
Based on configuration:
3. `DebugEnvironmentSwitcher.swift` -- If environment switcher selected
4. `DebugNetworkLogger.swift` -- If network logs selected
5. `DiagnosticInfo.swift` -- If diagnostics or export selected

### Step 4: Create Trigger Files
6. `DebugMenuTrigger.swift` -- ShakeDetector + hidden tap gesture + ViewModifier

### Step 5: Create Action Files
7. `DebugActions.swift` -- Collection of debug utility actions

### Step 6: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/DebugMenu/`
- If `App/` exists -> `App/DebugMenu/`
- Otherwise -> `DebugMenu/`

Entire folder is `#if DEBUG` and should be excluded from release builds.

## Output Format

After generation, provide:

### Files Created
```
DebugMenu/
├── DebugMenuView.swift            # Main NavigationStack with all sections
├── DebugSection.swift             # Enum of available sections
├── DebugEnvironmentSwitcher.swift # Environment switching (optional)
├── DebugNetworkLogger.swift       # Network request logger (optional)
├── DiagnosticInfo.swift           # Device and app diagnostics (optional)
├── DebugMenuTrigger.swift         # Shake gesture + hidden tap trigger
└── DebugActions.swift             # Utility actions (reset, clear, crash)
```

### Integration Steps

**Add the debug trigger to your root view:**
```swift
#if DEBUG
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .debugMenuTrigger()  // Adds shake + tap to open debug menu
        }
    }
}
#endif
```

**Or add only to specific views:**
```swift
struct SettingsView: View {
    var body: some View {
        Form {
            // ... your settings
        }
        #if DEBUG
        .debugMenuTrigger(method: .hiddenTap)
        #endif
    }
}
```

**Hook up the network logger to your API client:**
```swift
#if DEBUG
func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
    let start = Date()
    let (data, response) = try await session.data(for: request)
    DebugNetworkLogger.shared.log(request: request, response: response, data: data, duration: Date().timeIntervalSince(start))
    return (data, response)
}
#endif
```

**Register your feature flags:**
```swift
#if DEBUG
extension DebugMenuView {
    static let featureFlags: [FeatureFlag] = [
        FeatureFlag(key: "new_onboarding", title: "New Onboarding Flow", defaultValue: false),
        FeatureFlag(key: "dark_mode_v2", title: "Dark Mode V2", defaultValue: false),
        FeatureFlag(key: "premium_paywall", title: "Premium Paywall", defaultValue: true),
    ]
}
#endif
```

### Testing

```swift
#if DEBUG
@Test
func debugMenuSectionsRender() {
    let view = DebugMenuView()
    // Verify all sections are present
    #expect(DebugSection.allCases.count > 0)
}

@Test
func environmentSwitcherChangesBaseURL() {
    let switcher = DebugEnvironmentSwitcher()
    switcher.current = .staging
    #expect(switcher.baseURL.absoluteString.contains("staging"))

    switcher.current = .production
    #expect(switcher.baseURL.absoluteString.contains("api."))
}

@Test
func networkLoggerRecordsRequests() async {
    let logger = DebugNetworkLogger.shared
    await logger.clear()

    let request = URLRequest(url: URL(string: "https://api.example.com/users")!)
    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    await logger.log(request: request, response: response, data: Data(), duration: 0.25)

    let entries = await logger.entries
    #expect(entries.count == 1)
    #expect(entries.first?.statusCode == 200)
}

@Test
func diagnosticInfoCollectsDeviceData() {
    let info = DiagnosticInfo.collect()
    #expect(!info.appVersion.isEmpty)
    #expect(!info.osVersion.isEmpty)
    #expect(!info.deviceModel.isEmpty)
    #expect(info.memoryUsageMB > 0)
}
#endif
```

## Common Patterns

### Shake Gesture Trigger
```swift
#if DEBUG
// In your app's UIWindow subclass or scene delegate:
ContentView()
    .debugMenuTrigger(method: .shakeGesture)
#endif
```

### Toggle a Feature Flag at Runtime
```swift
#if DEBUG
// In DebugMenuView, toggle persists to UserDefaults:
Toggle(flag.title, isOn: binding(for: flag))
    .onChange(of: flag.isEnabled) {
        NotificationCenter.default.post(name: .featureFlagChanged, object: flag.key)
    }
#endif
```

### Switch API Environment
```swift
#if DEBUG
DebugEnvironmentSwitcher.shared.current = .staging
// All subsequent API calls use staging base URL
// App restarts recommended for full effect
#endif
```

### Clear All Caches
```swift
#if DEBUG
Button("Clear All Caches", role: .destructive) {
    DebugActions.clearAllCaches()
}
#endif
```

## Gotchas

- **MUST be `#if DEBUG` only** -- every file, every type, every extension must be wrapped. Never let debug menu code ship to production.
- **Never ship debug menu to production** -- verify your release scheme does not define the DEBUG flag. Check Build Settings > Swift Compiler > Active Compilation Conditions.
- **Shake gesture conflicts** -- UIKit's `motionEnded` may conflict with other shake handlers (e.g., "shake to undo"). Disable the system shake-to-undo if using shake for debug: `UIApplication.shared.applicationSupportsShakeToEdit = false`.
- **Sensitive data in logs** -- Network logger captures request/response bodies. Strip authorization headers and redact sensitive fields before logging.
- **UserDefaults pollution** -- Feature flag overrides stored in UserDefaults persist across launches. Prefix all debug keys (e.g., `debug_flag_`) and provide a "Reset All" button.
- **Environment switching requires restart** -- Some services cache their base URL at init. Show an alert recommending app restart after environment change.
- **Thread safety** -- Use actors or `@MainActor` for shared debug state. The network logger must be an actor since it is written to from URLSession callbacks.

## References

- **templates.md** -- All production Swift templates for debug menu components
- Related: `generators/feature-flags` -- Full feature flag system with remote config
- Related: `generators/logging-setup` -- Structured logging infrastructure
