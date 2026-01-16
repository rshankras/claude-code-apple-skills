# Feature Flags Generator

Generate feature flag infrastructure with local and remote configuration support.

## When to Use

- User wants to control features remotely
- User mentions A/B testing or gradual rollouts
- User asks about Firebase Remote Config or similar
- User wants to disable features without app update

## Pre-Generation Checks

```bash
# Check for existing feature flag code
grep -r "FeatureFlag\|RemoteConfig\|isEnabled" --include="*.swift" | head -5
```

## Configuration Questions

### 1. Feature Flag Source
- **Local Only** - Build-time flags, UserDefaults
- **Remote** - Firebase Remote Config, custom server
- **Hybrid** - Local defaults with remote override

### 2. Provider
- **Firebase Remote Config** - Full-featured, free tier
- **Custom Server** - Self-hosted JSON endpoint
- **None** - Local only

## Generated Files

```
Sources/FeatureFlags/
├── FeatureFlagService.swift    # Protocol
├── LocalFeatureFlags.swift     # Local implementation
├── RemoteFeatureFlags.swift    # Remote implementation
└── FeatureFlag.swift           # Flag definitions
```

## Feature Flag Service

```swift
protocol FeatureFlagService: Sendable {
    func isEnabled(_ flag: FeatureFlag) -> Bool
    func value<T>(_ flag: FeatureFlag, default: T) -> T
    func refresh() async throws
}

enum FeatureFlag: String, CaseIterable {
    case newOnboarding = "new_onboarding"
    case darkModeV2 = "dark_mode_v2"
    case premiumFeatures = "premium_features"
    case experimentalUI = "experimental_ui"
}
```

## Local Implementation

```swift
final class LocalFeatureFlags: FeatureFlagService {
    private let defaults: UserDefaults

    private let defaultValues: [FeatureFlag: Bool] = [
        .newOnboarding: false,
        .darkModeV2: true,
        .premiumFeatures: false,
        .experimentalUI: false
    ]

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        #if DEBUG
        // Allow override in debug
        if let override = defaults.object(forKey: "ff_\(flag.rawValue)") as? Bool {
            return override
        }
        #endif
        return defaultValues[flag] ?? false
    }
}
```

## Remote Implementation

```swift
final class RemoteFeatureFlags: FeatureFlagService {
    private var flags: [String: Any] = [:]
    private let endpoint: URL

    func refresh() async throws {
        let (data, _) = try await URLSession.shared.data(from: endpoint)
        flags = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        flags[flag.rawValue] as? Bool ?? false
    }
}
```

## Usage in Views

```swift
struct FeatureView: View {
    @Environment(\.featureFlags) private var flags

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

## Debug Menu

```swift
#if DEBUG
struct FeatureFlagDebugView: View {
    var body: some View {
        List(FeatureFlag.allCases, id: \.self) { flag in
            Toggle(flag.rawValue, isOn: binding(for: flag))
        }
        .navigationTitle("Feature Flags")
    }
}
#endif
```

## Best Practices

1. **Default to safe** - Features off by default
2. **Clean up old flags** - Remove after full rollout
3. **Log flag state** - Track which flags are active
4. **Cache remote values** - Don't block on network
5. **Provide fallbacks** - Handle fetch failures

## References

- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)
- [Feature Toggles (Martin Fowler)](https://martinfowler.com/articles/feature-toggles.html)
