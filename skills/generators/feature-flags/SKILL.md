---
name: feature-flags
description: Generate feature flag infrastructure with local defaults, remote configuration, SwiftUI integration, and debug menu. Use when adding feature flags or A/B testing to iOS/macOS apps.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Feature Flags Generator

Generate a complete feature flag infrastructure with typed flag definitions, protocol-based providers (local, remote, composite), SwiftUI environment integration, an `@Observable` manager, and a debug menu for toggling flags at runtime.

## When This Skill Activates

Use this skill when the user:
- Asks to "add feature flags" or "add feature toggles"
- Mentions A/B testing or gradual rollouts
- Asks about Firebase Remote Config or similar remote configuration
- Wants to disable features without shipping an app update
- Mentions "kill switches" or "feature gates"
- Wants to control features remotely for a subset of users
- Asks for a debug menu to toggle features during development

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing feature flag implementations
- [ ] Check for Firebase Remote Config or third-party flag SDKs
- [ ] Identify source file locations (Sources/, App/, or root)
- [ ] Verify minimum deployment target (iOS 17+ / macOS 14+ for @Observable)

### 2. Conflict Detection

Search for existing feature flag code:
```
Glob: **/*FeatureFlag*.swift, **/*FeatureToggle*.swift, **/*RemoteConfig*.swift
Grep: "FeatureFlag" or "FeatureToggle" or "RemoteConfig" or "isFeatureEnabled"
```

If existing feature flag code is found:
- Ask whether to replace or extend the existing implementation
- Check for flag names or enum cases that could conflict

If a third-party SDK (Firebase, LaunchDarkly, etc.) is detected:
- Ask if the user wants a standalone implementation or a wrapper around the SDK

### 3. Required Capabilities

**Feature flags require:**
- iOS 17+ / macOS 14+ deployment target (for @Observable manager)
- Network access entitlement if using remote flags
- No special Info.plist entries needed

## Configuration Questions

Ask user via AskUserQuestion:

1. **What features do you want to flag?** (freeform)
   - Examples: new onboarding, premium paywall, experimental UI, dark mode v2
   - This determines the flag enum cases and their default values

2. **What flag value types do you need?**
   - Boolean only (feature on/off)
   - Boolean + String (on/off plus string configuration)
   - Boolean + String + Integer (full typed support)
   - Boolean + String + Integer + JSON (for complex configurations)

3. **What provider architecture?**
   - **Local only** -- UserDefaults-based with compile-time defaults
   - **Remote only** -- JSON endpoint with local caching
   - **Composite (recommended)** -- Local defaults with remote override; remote wins when available

4. **Include debug menu?**
   - Yes -- SwiftUI view for toggling flags at runtime (DEBUG builds only)
   - No -- Skip the debug view

5. **Include SwiftUI environment integration?**
   - Yes (recommended) -- Inject the flag manager via SwiftUI Environment
   - No -- Use the manager directly

## Generation Process

### Step 1: Determine File Locations

Check project structure:
- If `Sources/` exists --> `Sources/FeatureFlags/`
- If `App/` exists --> `App/FeatureFlags/`
- Otherwise --> `FeatureFlags/`

### Step 2: Create Core Files

Generate these files based on configuration answers:

1. **`FeatureFlag.swift`** -- Flag enum with typed default values
2. **`FeatureFlagService.swift`** -- Protocol defining provider interface
3. **`LocalFeatureFlagProvider.swift`** -- UserDefaults-based provider with debug overrides
4. **`RemoteFeatureFlagProvider.swift`** -- URL-based provider with disk caching (if remote or composite)
5. **`CompositeFeatureFlagProvider.swift`** -- Combines local + remote; remote overrides local (if composite)
6. **`FeatureFlagManager.swift`** -- @Observable manager for SwiftUI
7. **`FeatureFlagEnvironmentKey.swift`** -- SwiftUI Environment integration (if requested)
8. **`FeatureFlagDebugView.swift`** -- Debug toggle view (if requested)

### Step 3: Generate Code from Templates

Use the templates in **templates.md** and customize based on user answers:
- Replace placeholder flag cases with real feature names
- Set appropriate default values per flag
- Include or exclude remote/composite providers based on architecture choice
- Include or exclude typed value methods (string, int, JSON) based on type selection
- Include or exclude environment key and debug view

## Output Format

After generation, provide:

### Files Created

```
Sources/FeatureFlags/
├── FeatureFlag.swift                    # Flag enum with typed defaults
├── FeatureFlagService.swift             # Provider protocol
├── LocalFeatureFlagProvider.swift       # UserDefaults-based provider
├── RemoteFeatureFlagProvider.swift      # URL-based provider (if remote/composite)
├── CompositeFeatureFlagProvider.swift   # Local + remote combiner (if composite)
├── FeatureFlagManager.swift             # @Observable manager for SwiftUI
├── FeatureFlagEnvironmentKey.swift      # SwiftUI Environment key (if requested)
└── FeatureFlagDebugView.swift           # Debug toggle menu (if requested)
```

### Integration Steps

**1. Initialize the manager in your App struct or entry point:**

```swift
import SwiftUI

@main
struct MyApp: App {
    @State private var featureFlagManager: FeatureFlagManager

    init() {
        // Local only
        let provider = LocalFeatureFlagProvider()

        // Or composite (remote overrides local)
        // let provider = CompositeFeatureFlagProvider(
        //     local: LocalFeatureFlagProvider(),
        //     remote: RemoteFeatureFlagProvider(
        //         endpoint: URL(string: "https://api.example.com/flags")!
        //     )
        // )

        _featureFlagManager = State(initialValue: FeatureFlagManager(provider: provider))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(featureFlagManager)
        }
    }
}
```

**2. Use flags in your views:**

```swift
struct ContentView: View {
    @Environment(FeatureFlagManager.self) private var flags

    var body: some View {
        VStack {
            if flags.isEnabled(.newOnboarding) {
                NewOnboardingView()
            } else {
                LegacyOnboardingView()
            }
        }
    }
}
```

**3. Refresh remote flags (if using remote or composite):**

```swift
// Refresh on app launch or periodically
Task {
    try await featureFlagManager.refresh()
}
```

**4. Add debug menu (if generated, DEBUG builds only):**

```swift
#if DEBUG
NavigationLink("Feature Flags") {
    FeatureFlagDebugView()
        .environment(featureFlagManager)
}
#endif
```

### Testing Instructions

1. **Unit test providers independently:** Each provider conforms to `FeatureFlagService` and can be tested in isolation.
2. **Mock provider for previews and tests:**
   ```swift
   final class MockFeatureFlagProvider: FeatureFlagService {
       var overrides: [FeatureFlag: Bool] = [:]

       func isEnabled(_ flag: FeatureFlag) -> Bool {
           overrides[flag] ?? flag.defaultValue
       }
       // ... implement remaining protocol methods
   }
   ```
3. **Debug menu:** Run in DEBUG builds, navigate to the debug menu, and toggle flags to verify behavior.
4. **Remote provider:** Use a local JSON file served via a test server or mock URLProtocol to test remote fetching.

## Common Patterns

### Boolean Flags (Kill Switches)
The most common pattern. Enable or disable a feature entirely.

```swift
if flags.isEnabled(.premiumPaywall) {
    PremiumPaywallView()
}
```

### String Flags (Copy Variants / A/B Testing)
Use string values to serve different text or configuration strings remotely.

```swift
let welcomeMessage = flags.stringValue(.welcomeMessage) ?? "Welcome!"
Text(welcomeMessage)
```

### Integer Flags (Thresholds / Limits)
Control numeric parameters like retry counts, page sizes, or rate limits.

```swift
let maxRetries = flags.intValue(.maxRetries) ?? 3
```

### JSON Flags (Complex Configuration)
For structured configuration that changes server-side.

```swift
struct PaywallConfig: Codable {
    let title: String
    let trialDays: Int
    let showTestimonials: Bool
}

if let config: PaywallConfig = flags.jsonValue(.paywallConfig) {
    PaywallView(config: config)
}
```

### Gradual Rollout
Combine feature flags with user segmentation.

```swift
// Server returns different flag values per user segment
// The flag is simply on/off from the client perspective
if flags.isEnabled(.newCheckoutFlow) {
    NewCheckoutView()
} else {
    LegacyCheckoutView()
}
```

## Gotchas

- **Stale flags:** Always provide sensible local defaults. If the remote fetch fails, the app must still function correctly with local values.
- **Flag cleanup:** After a feature is fully rolled out, remove the flag enum case, delete related conditional code, and clean up remote configuration. Stale flags accumulate technical debt.
- **Thread safety:** The generated `FeatureFlagManager` is `@MainActor`-isolated. Access it on the main thread or via `@Environment` in SwiftUI views. The providers use `Sendable`-conforming storage.
- **Testing both paths:** When a flag controls a UI branch, write tests (or at least manual test plans) for both the enabled and disabled paths. It is easy to forget the disabled path once a flag has been on for weeks.
- **Debug overrides in production:** The debug override mechanism uses `#if DEBUG` guards. Double-check that debug toggles never leak into release builds.
- **Cache invalidation:** The remote provider caches to disk. Set an appropriate `cacheDuration` (default 5 minutes). For time-sensitive flags, call `refresh()` explicitly.
- **UserDefaults key collisions:** All flag keys are prefixed with `ff_` to avoid collisions with other UserDefaults entries in the app.

## References

- **templates.md** -- Production-ready Swift templates for all generated files
- [Feature Toggles (Martin Fowler)](https://martinfowler.com/articles/feature-toggles.html)
- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)
