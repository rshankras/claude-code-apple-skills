# Logger Patterns and Best Practices

## Log Levels

Use appropriate log levels for different situations:

| Level | Use Case | Release Behavior |
|-------|----------|------------------|
| `.debug` | Development only, verbose | Compiled out |
| `.info` | General information | Visible |
| `.notice` | Important events | Visible, persisted |
| `.warning` | Potential issues | Visible, persisted |
| `.error` | Errors that need attention | Visible, persisted |
| `.fault` | Critical failures | Visible, persisted, highlighted |

## Privacy Annotations

### .public
Data safe to log in production:
```swift
AppLogger.network.info("Request ID: \(requestId, privacy: .public)")
AppLogger.data.info("Items count: \(items.count, privacy: .public)")
```

### .private (default)
Redacted in release builds, visible in debug:
```swift
AppLogger.auth.info("User: \(email, privacy: .private)")
AppLogger.network.debug("Response: \(responseBody, privacy: .private)")
```

### .sensitive
Always redacted, even in debug:
```swift
AppLogger.auth.info("Token: \(token, privacy: .sensitive)")
```

### .hash
Shows hash of value (useful for correlation without exposing data):
```swift
AppLogger.auth.info("User hash: \(userId, privacy: .private(mask: .hash))")
```

## Category Organization

### Recommended Categories

```swift
enum AppLogger {
    // Core
    static let general = Logger(subsystem: subsystem, category: "General")

    // Networking
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let api = Logger(subsystem: subsystem, category: "API")

    // User
    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let user = Logger(subsystem: subsystem, category: "User")

    // Data
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let cache = Logger(subsystem: subsystem, category: "Cache")

    // UI
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let navigation = Logger(subsystem: subsystem, category: "Navigation")

    // System
    static let performance = Logger(subsystem: subsystem, category: "Performance")
    static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")
}
```

## Common Patterns

### Network Request Logging
```swift
func fetch(_ endpoint: Endpoint) async throws -> Data {
    AppLogger.network.debug("Request: \(endpoint.method) \(endpoint.path)")

    do {
        let (data, response) = try await session.data(for: endpoint.request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        AppLogger.network.info("Response: \(statusCode, privacy: .public) for \(endpoint.path)")
        return data
    } catch {
        AppLogger.network.error("Request failed: \(error.localizedDescription)")
        throw error
    }
}
```

### Authentication Logging
```swift
func signIn(email: String, password: String) async throws {
    AppLogger.auth.info("Sign in attempt for: \(email, privacy: .private)")

    do {
        let user = try await authService.signIn(email: email, password: password)
        AppLogger.auth.notice("Sign in successful for user: \(user.id, privacy: .private(mask: .hash))")
    } catch {
        AppLogger.auth.warning("Sign in failed: \(error.localizedDescription)")
        throw error
    }
}
```

### Data Operations Logging
```swift
func save(_ items: [Item]) throws {
    AppLogger.data.debug("Saving \(items.count, privacy: .public) items")

    let start = CFAbsoluteTimeGetCurrent()
    try context.save()
    let duration = CFAbsoluteTimeGetCurrent() - start

    AppLogger.data.info("Saved \(items.count, privacy: .public) items in \(duration, format: .fixed(precision: 3))s")
}
```

### Error Logging
```swift
func handleError(_ error: Error, context: String) {
    if let appError = error as? AppError {
        switch appError {
        case .networkError(let underlying):
            AppLogger.network.error("\(context): \(underlying.localizedDescription)")
        case .authError(let reason):
            AppLogger.auth.error("\(context): \(reason)")
        case .dataError(let underlying):
            AppLogger.data.error("\(context): \(underlying.localizedDescription)")
        }
    } else {
        AppLogger.general.fault("Unexpected error in \(context): \(error)")
    }
}
```

## Anti-Patterns to Avoid

### Don't Log Sensitive Data as Public
```swift
// Bad
AppLogger.auth.info("Password: \(password, privacy: .public)")

// Good
AppLogger.auth.debug("Password provided: \(password.isEmpty ? "no" : "yes", privacy: .public)")
```

### Don't Use Wrong Log Levels
```swift
// Bad - Using debug for errors
AppLogger.network.debug("Critical error: \(error)")

// Good
AppLogger.network.error("Request failed: \(error)")
```

### Don't Skip Privacy for User Data
```swift
// Bad - No privacy annotation for email
AppLogger.auth.info("User email: \(email)")

// Good
AppLogger.auth.info("User email: \(email, privacy: .private)")
```

### Don't Log Excessively in Loops
```swift
// Bad
for item in items {
    AppLogger.data.debug("Processing: \(item)")
}

// Good
AppLogger.data.debug("Processing \(items.count, privacy: .public) items")
// Log individual items only at trace level or when debugging specific issues
```

## Performance Considerations

### Deferred String Interpolation
Logger uses deferred interpolation - the string is only constructed if the log will be emitted:
```swift
// This is efficient - string only built if debug logs enabled
AppLogger.data.debug("Complex object: \(expensiveDescription())")
```

### Signposts for Performance
For performance profiling, use OSSignposter:
```swift
import OSLog

let signposter = OSSignposter(logger: AppLogger.performance)

func loadData() async {
    let signpostID = signposter.makeSignpostID()
    let state = signposter.beginInterval("LoadData", id: signpostID)

    // ... perform work ...

    signposter.endInterval("LoadData", state)
}
```

## Console.app Tips

### Filtering
- By subsystem: `subsystem:com.yourapp`
- By category: `category:Network`
- By level: `type:error`
- Combined: `subsystem:com.yourapp AND category:Auth AND type:error`

### Streaming Logs
```bash
# Terminal command to stream logs
log stream --predicate 'subsystem == "com.yourapp"' --level debug
```

### Exporting Logs
```bash
# Export logs to file
log collect --device --output ~/Desktop/app-logs.logarchive
```
