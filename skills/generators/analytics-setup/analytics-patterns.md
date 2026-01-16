# Analytics Patterns and Best Practices

## Protocol-Based Architecture

### Why Protocols?

1. **Testability** - Use NoOpAnalytics in tests
2. **Flexibility** - Swap providers without code changes
3. **Privacy** - Easy to disable analytics per user preference
4. **Gradual Migration** - Add new provider, switch when ready

### The Core Protocol

```swift
protocol AnalyticsService: Sendable {
    func configure()
    func track(_ event: AnalyticsEvent)
    func track(_ event: AnalyticsEvent, properties: [String: String])
    func setUserProperty(_ key: String, value: String)
    func setUserID(_ id: String?)
    func reset()
}
```

### Default Implementations

Provide defaults for optional methods:

```swift
extension AnalyticsService {
    func track(_ event: AnalyticsEvent) {
        track(event, properties: [:])
    }

    func setUserID(_ id: String?) {
        // Optional - not all providers support this
    }

    func reset() {
        // Called on logout - reset user properties
    }
}
```

## Event Design

### Enum-Based Events

Use enums for type-safe event tracking:

```swift
enum AnalyticsEvent: Sendable {
    // Lifecycle
    case appLaunched
    case appBackgrounded
    case appForegrounded

    // Screens
    case screenViewed(name: String)

    // User Actions
    case buttonTapped(name: String)
    case featureUsed(name: String)

    // Errors
    case errorOccurred(domain: String, code: Int)

    // Custom
    case custom(name: String, properties: [String: String])
}
```

### Event Naming Conventions

| Pattern | Example | Notes |
|---------|---------|-------|
| `noun_verbed` | `button_tapped` | Past tense for completed actions |
| `screen_viewed` | `settings_screen_viewed` | For navigation |
| `feature_used` | `dark_mode_enabled` | For feature adoption |

### Event Properties

Add context without bloating the enum:

```swift
// Good - properties in track call
analytics.track(.buttonTapped("subscribe"), properties: [
    "screen": "paywall",
    "variant": "annual"
])

// Avoid - too many enum cases
case subscribeButtonTappedOnPaywallAnnual // Don't do this
```

## Provider Implementations

### TelemetryDeck (Recommended)

Privacy-friendly, no user consent required in most jurisdictions:

```swift
final class TelemetryDeckAnalytics: AnalyticsService {
    private let appID: String

    init(appID: String) {
        self.appID = appID
    }

    func configure() {
        TelemetryManager.initialize(with: .init(appID: appID))
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        var allProperties = properties
        allProperties["event_name"] = event.name

        TelemetryManager.send(event.signalName, with: allProperties)
    }
}
```

### Firebase Analytics

Full-featured but requires consent in EU:

```swift
final class FirebaseAnalytics: AnalyticsService {
    func configure() {
        FirebaseApp.configure()
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        Analytics.logEvent(event.firebaseName, parameters: properties)
    }

    func setUserProperty(_ key: String, value: String) {
        Analytics.setUserProperty(value, forName: key)
    }

    func setUserID(_ id: String?) {
        Analytics.setUserID(id)
    }
}
```

### NoOp Implementation

Essential for testing and privacy:

```swift
final class NoOpAnalytics: AnalyticsService {
    func configure() {}
    func track(_ event: AnalyticsEvent, properties: [String: String]) {}
    func setUserProperty(_ key: String, value: String) {}
    func setUserID(_ id: String?) {}
    func reset() {}
}
```

## SwiftUI Integration

### Environment Key

```swift
private struct AnalyticsServiceKey: EnvironmentKey {
    static let defaultValue: AnalyticsService = NoOpAnalytics()
}

extension EnvironmentValues {
    var analytics: AnalyticsService {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}
```

### Usage in Views

```swift
struct SettingsView: View {
    @Environment(\.analytics) private var analytics

    var body: some View {
        List {
            Button("Reset") {
                analytics.track(.buttonTapped("reset_settings"))
                // ... reset logic
            }
        }
        .onAppear {
            analytics.track(.screenViewed(name: "Settings"))
        }
    }
}
```

### View Modifier for Screen Tracking

```swift
struct AnalyticsScreenModifier: ViewModifier {
    let screenName: String
    @Environment(\.analytics) private var analytics

    func body(content: Content) -> some View {
        content.onAppear {
            analytics.track(.screenViewed(name: screenName))
        }
    }
}

extension View {
    func trackScreen(_ name: String) -> some View {
        modifier(AnalyticsScreenModifier(screenName: name))
    }
}

// Usage
SettingsView()
    .trackScreen("Settings")
```

## Privacy Considerations

### User Consent

```swift
final class ConsentAwareAnalytics: AnalyticsService {
    private let wrapped: AnalyticsService
    private let consentProvider: () -> Bool

    init(wrapped: AnalyticsService, consentProvider: @escaping () -> Bool) {
        self.wrapped = wrapped
        self.consentProvider = consentProvider
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        guard consentProvider() else { return }
        wrapped.track(event, properties: properties)
    }
}

// Usage
let analytics = ConsentAwareAnalytics(
    wrapped: FirebaseAnalytics(),
    consentProvider: { UserDefaults.standard.bool(forKey: "analyticsConsent") }
)
```

### What NOT to Track

- Personal identifiable information (PII)
- Exact timestamps (use day/hour granularity)
- Precise location (use region/country)
- Content of user-generated text
- Financial details

### What's Safe to Track

- Feature usage (which features are used)
- App version and OS version
- Error types (not full stack traces)
- Session duration (rounded)
- Screen flow (which screens visited)

## Testing

### Unit Tests

```swift
class FeatureViewModelTests: XCTestCase {
    func testButtonTracksEvent() {
        let mockAnalytics = MockAnalytics()
        let viewModel = FeatureViewModel(analytics: mockAnalytics)

        viewModel.didTapButton()

        XCTAssertEqual(mockAnalytics.trackedEvents.count, 1)
        XCTAssertEqual(mockAnalytics.trackedEvents.first?.name, "button_tapped")
    }
}

class MockAnalytics: AnalyticsService {
    var trackedEvents: [AnalyticsEvent] = []

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        trackedEvents.append(event)
    }
}
```

### SwiftUI Previews

```swift
#Preview {
    ContentView()
        .environment(\.analytics, NoOpAnalytics())
}
```

## Migration Strategy

### Adding Analytics to Existing App

1. Add protocol and NoOp implementation
2. Wire up Environment
3. Add tracking calls with NoOp (verify builds)
4. Add real provider
5. Switch from NoOp to real provider

### Switching Providers

1. Add new provider implementation
2. Test with subset of users (feature flag)
3. Monitor for issues
4. Switch all users
5. Remove old provider (optional)
