# Error Monitoring Patterns

Best practices for implementing error monitoring in iOS and macOS apps.

## Protocol-Based Architecture

### Why Protocols?

1. **Testability** - Use `NoOpErrorMonitoring` in tests
2. **Privacy** - Swap to NoOp for users who opt out
3. **Flexibility** - Change providers without code changes
4. **Gradual adoption** - Start with NoOp, add provider later

### Core Protocol

```swift
protocol ErrorMonitoringService: Sendable {
    /// Configure the service (call once at app launch)
    func configure()

    /// Capture an error with optional context
    func captureError(_ error: Error, context: ErrorContext?)

    /// Capture a message with severity level
    func captureMessage(_ message: String, level: ErrorLevel)

    /// Add a breadcrumb for debugging context
    func addBreadcrumb(_ breadcrumb: Breadcrumb)

    /// Set the current user (anonymized)
    func setUser(_ user: MonitoringUser?)

    /// Clear user and session data (on logout)
    func reset()
}
```

### Provider Pattern

```swift
// Central access point
final class ErrorMonitoring {
    static let shared = ErrorMonitoring()

    // Swap providers by changing this line
    #if DEBUG
    let service: ErrorMonitoringService = NoOpErrorMonitoring()
    #else
    let service: ErrorMonitoringService = SentryErrorMonitoring()
    #endif

    private init() {}

    func configure() {
        service.configure()
    }
}
```

## Error Context

### Breadcrumbs

Breadcrumbs provide a trail of events leading to an error:

```swift
struct Breadcrumb: Sendable {
    let timestamp: Date
    let category: String      // "navigation", "ui", "network", "user"
    let message: String
    let level: ErrorLevel
    let data: [String: String]?

    init(
        category: String,
        message: String,
        level: ErrorLevel = .info,
        data: [String: String]? = nil
    ) {
        self.timestamp = .now
        self.category = category
        self.message = message
        self.level = level
        self.data = data
    }
}
```

### Automatic Breadcrumbs

```swift
// Navigation breadcrumbs
extension View {
    func trackNavigation(_ screenName: String) -> some View {
        onAppear {
            ErrorMonitoring.shared.service.addBreadcrumb(
                Breadcrumb(
                    category: "navigation",
                    message: "Viewed \(screenName)"
                )
            )
        }
    }
}

// Usage
struct SettingsView: View {
    var body: some View {
        Form { ... }
            .trackNavigation("Settings")
    }
}
```

### User Context

```swift
struct MonitoringUser: Sendable {
    let id: String          // Anonymized user ID (not email!)
    let username: String?   // Optional display name
    let segment: String?    // User segment (free, premium)

    // Never include PII like email, phone, real name
}

// Set on login
func userDidLogin(_ user: AppUser) {
    let monitoringUser = MonitoringUser(
        id: user.anonymizedID,  // Hash of real ID
        username: nil,
        segment: user.subscriptionTier
    )
    ErrorMonitoring.shared.service.setUser(monitoringUser)
}

// Clear on logout
func userDidLogout() {
    ErrorMonitoring.shared.service.reset()
}
```

### Error Tags and Extra Data

```swift
struct ErrorContext: Sendable {
    var tags: [String: String]       // Indexed, searchable
    var extra: [String: Any]         // Additional data
    var fingerprint: [String]?       // Custom grouping

    init(
        tags: [String: String] = [:],
        extra: [String: Any] = [:],
        fingerprint: [String]? = nil
    ) {
        self.tags = tags
        self.extra = extra
        self.fingerprint = fingerprint
    }
}

// Usage
let context = ErrorContext(
    tags: [
        "feature": "checkout",
        "payment_method": "apple_pay"
    ],
    extra: [
        "cart_items": cartItems.count,
        "total_amount": cart.total
    ]
)
errorMonitoring.captureError(error, context: context)
```

## Error Levels

```swift
enum ErrorLevel: String, Sendable {
    case debug      // Debugging info, not captured in production
    case info       // Informational, low priority
    case warning    // Something unexpected but not critical
    case error      // Error that affected user experience
    case fatal      // App crash or critical failure
}
```

## Capturing Errors

### Basic Error Capture

```swift
do {
    try await performOperation()
} catch {
    ErrorMonitoring.shared.service.captureError(error)
    // Show user-friendly error message
    showErrorAlert(error)
}
```

### With Context

```swift
func purchaseProduct(_ product: Product) async {
    let breadcrumb = Breadcrumb(
        category: "purchase",
        message: "Starting purchase",
        data: ["product_id": product.id]
    )
    ErrorMonitoring.shared.service.addBreadcrumb(breadcrumb)

    do {
        try await storeManager.purchase(product)
    } catch {
        let context = ErrorContext(
            tags: ["feature": "iap", "product": product.id],
            extra: ["price": product.price.description]
        )
        ErrorMonitoring.shared.service.captureError(error, context: context)
    }
}
```

### Capturing Messages

```swift
// For non-exception issues
ErrorMonitoring.shared.service.captureMessage(
    "User attempted to access premium feature without subscription",
    level: .warning
)
```

## Integration Patterns

### App Lifecycle

```swift
@main
struct MyApp: App {
    init() {
        ErrorMonitoring.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.errorMonitoring, ErrorMonitoring.shared.service)
        }
    }
}
```

### Environment Key

```swift
private struct ErrorMonitoringKey: EnvironmentKey {
    static let defaultValue: ErrorMonitoringService = NoOpErrorMonitoring()
}

extension EnvironmentValues {
    var errorMonitoring: ErrorMonitoringService {
        get { self[ErrorMonitoringKey.self] }
        set { self[ErrorMonitoringKey.self] = newValue }
    }
}

// In views
struct FeatureView: View {
    @Environment(\.errorMonitoring) var errorMonitoring

    func handleError(_ error: Error) {
        errorMonitoring.captureError(error)
    }
}
```

### Global Error Handler

```swift
// Catch unhandled errors
func setupGlobalErrorHandling() {
    // Swift errors (non-crashing)
    NSSetUncaughtExceptionHandler { exception in
        ErrorMonitoring.shared.service.captureMessage(
            "Uncaught exception: \(exception.reason ?? "unknown")",
            level: .fatal
        )
    }

    // Note: Sentry/Crashlytics handle actual crashes automatically
}
```

## Testing

### Mock for Unit Tests

```swift
final class MockErrorMonitoring: ErrorMonitoringService {
    var capturedErrors: [Error] = []
    var capturedMessages: [(String, ErrorLevel)] = []
    var breadcrumbs: [Breadcrumb] = []

    func configure() {}

    func captureError(_ error: Error, context: ErrorContext?) {
        capturedErrors.append(error)
    }

    func captureMessage(_ message: String, level: ErrorLevel) {
        capturedMessages.append((message, level))
    }

    func addBreadcrumb(_ breadcrumb: Breadcrumb) {
        breadcrumbs.append(breadcrumb)
    }

    func setUser(_ user: MonitoringUser?) {}
    func reset() {
        capturedErrors.removeAll()
        capturedMessages.removeAll()
        breadcrumbs.removeAll()
    }
}

// In tests
func testErrorCapture() {
    let mock = MockErrorMonitoring()
    let viewModel = ViewModel(errorMonitoring: mock)

    viewModel.performFailingOperation()

    XCTAssertEqual(mock.capturedErrors.count, 1)
}
```

### Debug Mode

```swift
#if DEBUG
final class DebugErrorMonitoring: ErrorMonitoringService {
    func captureError(_ error: Error, context: ErrorContext?) {
        print("🔴 ERROR: \(error)")
        if let context {
            print("   Tags: \(context.tags)")
            print("   Extra: \(context.extra)")
        }
    }

    func captureMessage(_ message: String, level: ErrorLevel) {
        let emoji: String = switch level {
        case .debug: "🔍"
        case .info: "ℹ️"
        case .warning: "⚠️"
        case .error: "🔴"
        case .fatal: "💀"
        }
        print("\(emoji) \(level.rawValue.uppercased()): \(message)")
    }

    // ... other methods print to console
}
#endif
```

## Performance Considerations

### Sampling

For high-traffic apps, sample errors:

```swift
final class SampledErrorMonitoring: ErrorMonitoringService {
    private let wrapped: ErrorMonitoringService
    private let sampleRate: Double  // 0.0 to 1.0

    init(wrapped: ErrorMonitoringService, sampleRate: Double = 0.1) {
        self.wrapped = wrapped
        self.sampleRate = sampleRate
    }

    func captureError(_ error: Error, context: ErrorContext?) {
        guard Double.random(in: 0...1) < sampleRate else { return }
        wrapped.captureError(error, context: context)
    }

    // ... pass through other methods
}
```

### Filtering Known Errors

```swift
extension ErrorMonitoringService {
    func captureErrorIfNotExpected(_ error: Error, context: ErrorContext? = nil) {
        // Don't report expected/handled errors
        guard !isExpectedError(error) else { return }
        captureError(error, context: context)
    }

    private func isExpectedError(_ error: Error) -> Bool {
        switch error {
        case is CancellationError:
            return true
        case let urlError as URLError where urlError.code == .cancelled:
            return true
        case let storeError as StoreKitError where storeError == .userCancelled:
            return true
        default:
            return false
        }
    }
}
```

### Breadcrumb Limits

```swift
final class BoundedBreadcrumbBuffer {
    private var breadcrumbs: [Breadcrumb] = []
    private let maxCount: Int = 100

    func add(_ breadcrumb: Breadcrumb) {
        breadcrumbs.append(breadcrumb)
        if breadcrumbs.count > maxCount {
            breadcrumbs.removeFirst()
        }
    }

    var all: [Breadcrumb] { breadcrumbs }
}
```

## Privacy Best Practices

### Never Capture

- Email addresses
- Phone numbers
- Real names
- Passwords or tokens
- Location data (unless essential)
- Financial information

### Always Anonymize

```swift
extension String {
    var anonymized: String {
        // Hash for consistent anonymization
        let hash = SHA256.hash(data: Data(self.utf8))
        return hash.prefix(16).map { String(format: "%02x", $0) }.joined()
    }
}

// Usage
let monitoringUser = MonitoringUser(
    id: user.email.anonymized,  // Hash, not real email
    username: nil,
    segment: user.tier
)
```

### Respect User Preferences

```swift
final class ConsentAwareErrorMonitoring: ErrorMonitoringService {
    private let realService: ErrorMonitoringService
    private let consentManager: ConsentManager

    var activeService: ErrorMonitoringService {
        consentManager.hasConsent ? realService : NoOpErrorMonitoring()
    }

    func captureError(_ error: Error, context: ErrorContext?) {
        activeService.captureError(error, context: context)
    }

    // ... delegate other methods to activeService
}
```
