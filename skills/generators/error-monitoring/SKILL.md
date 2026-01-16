---
name: error-monitoring
description: Generates protocol-based error/crash monitoring with swappable providers (Sentry, Crashlytics). Use when user wants to add crash reporting, error tracking, or production monitoring.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Error Monitoring Generator

Generates a production-ready error monitoring infrastructure with protocol-based architecture for easy provider swapping.

## When This Skill Activates

- User asks to "add crash reporting" or "error monitoring"
- User mentions "Sentry", "Crashlytics", or "crash analytics"
- User wants to "track errors in production"
- User asks about "debugging production issues"

## Pre-Generation Checks (CRITICAL)

### 1. Project Context Detection

Before generating, ALWAYS check:

```bash
# Check for existing crash reporting
rg -l "Sentry|Crashlytics|CrashReporter" --type swift

# Check Package.swift for existing SDKs
cat Package.swift | grep -i "sentry\|firebase\|crashlytics"

# Check for existing error handling patterns
rg "captureError|recordError|logError" --type swift | head -5
```

### 2. Conflict Detection

If existing crash reporting found:
- Ask: Replace, wrap existing, or create parallel system?

## Configuration Questions

Ask user via AskUserQuestion:

1. **Initial provider?**
   - Sentry (recommended for indie devs)
   - Firebase Crashlytics (if already using Firebase)
   - None (set up infrastructure only)

2. **Include breadcrumbs?**
   - Yes (track navigation, user actions)
   - No (errors only)

3. **Include user context?**
   - Yes (anonymized user ID, app state)
   - No (minimal data collection)

## Generation Process

### Step 1: Create Core Files

**Always generate:**
```
Sources/ErrorMonitoring/
├── ErrorMonitoringService.swift     # Protocol
├── ErrorContext.swift               # Breadcrumbs, user info
└── NoOpErrorMonitoring.swift        # Testing/privacy
```

**Based on provider selection:**
```
Sources/ErrorMonitoring/Providers/
├── SentryErrorMonitoring.swift      # If Sentry selected
└── CrashlyticsErrorMonitoring.swift # If Crashlytics selected
```

### Step 2: Read Templates

Read templates from this skill:
- `templates/ErrorMonitoringService.swift`
- `templates/ErrorContext.swift`
- `templates/NoOpErrorMonitoring.swift`
- `templates/SentryErrorMonitoring.swift` (if selected)
- `templates/CrashlyticsErrorMonitoring.swift` (if selected)

### Step 3: Customize for Project

Adapt templates to match:
- Project naming conventions
- Existing error types
- Bundle identifier for Sentry DSN

### Step 4: Integration

**In App.swift:**
```swift
import SwiftUI

@main
struct MyApp: App {
    init() {
        // Configure error monitoring
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

**Capturing errors:**
```swift
do {
    try await riskyOperation()
} catch {
    ErrorMonitoring.shared.service.captureError(error)
}
```

**Adding breadcrumbs:**
```swift
ErrorMonitoring.shared.service.addBreadcrumb(
    Breadcrumb(category: "navigation", message: "Opened settings")
)
```

## Provider Setup

### Sentry

1. **Create account** at [sentry.io](https://sentry.io)
2. **Create project** for iOS/macOS
3. **Get DSN** from Project Settings > Client Keys
4. **Add to Package.swift:**
```swift
.package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0")
```

### Firebase Crashlytics

1. **Add Firebase** to your project via [console.firebase.google.com](https://console.firebase.google.com)
2. **Download** GoogleService-Info.plist
3. **Add Firebase SDK** via SPM or CocoaPods
4. **Enable Crashlytics** in Firebase console

## Generated Code Patterns

### Protocol (Stable Interface)
```swift
protocol ErrorMonitoringService: Sendable {
    func configure()
    func captureError(_ error: Error, context: ErrorContext?)
    func captureMessage(_ message: String, level: ErrorLevel)
    func addBreadcrumb(_ breadcrumb: Breadcrumb)
    func setUser(_ user: MonitoringUser?)
    func reset()
}
```

### Swapping Providers
```swift
// In ErrorMonitoring.swift
final class ErrorMonitoring {
    static let shared = ErrorMonitoring()

    // Change this ONE line to swap providers:
    let service: ErrorMonitoringService = SentryErrorMonitoring()
    // let service: ErrorMonitoringService = CrashlyticsErrorMonitoring()
    // let service: ErrorMonitoringService = NoOpErrorMonitoring()
}
```

### Breadcrumb Tracking
```swift
// Automatic navigation breadcrumbs
struct ContentView: View {
    @Environment(\.errorMonitoring) var errorMonitoring

    var body: some View {
        Button("Open Details") {
            errorMonitoring.addBreadcrumb(
                Breadcrumb(category: "ui", message: "Tapped details button")
            )
            showDetails = true
        }
    }
}
```

## Verification Checklist

After generation, verify:

- [ ] App compiles without errors
- [ ] Provider SDK added (if applicable)
- [ ] DSN/config set correctly
- [ ] Test error appears in dashboard
- [ ] Breadcrumbs captured correctly
- [ ] User context (if enabled) shows in reports
- [ ] NoOp mode works for debug/testing

## Privacy Considerations

### GDPR Compliance
- Use `NoOpErrorMonitoring` for EU users who opt out
- Don't capture PII in error messages
- Anonymize user IDs

### App Store Guidelines
- Disclose crash reporting in privacy policy
- Use App Tracking Transparency if combining with analytics
- Don't capture unnecessary device identifiers

### Privacy Manifest (iOS 17+)
Add to PrivacyInfo.xcprivacy if using Sentry/Crashlytics:
```xml
<key>NSPrivacyCollectedDataTypes</key>
<array>
    <dict>
        <key>NSPrivacyCollectedDataType</key>
        <string>NSPrivacyCollectedDataTypeCrashData</string>
        <key>NSPrivacyCollectedDataTypeLinked</key>
        <false/>
        <key>NSPrivacyCollectedDataTypeTracking</key>
        <false/>
        <key>NSPrivacyCollectedDataTypePurposes</key>
        <array>
            <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
        </array>
    </dict>
</array>
```

## Common Customizations

### Custom Error Types
```swift
enum AppError: Error {
    case networkFailure(URLError)
    case decodingFailure(DecodingError)
    case authenticationRequired

    var context: ErrorContext {
        ErrorContext(
            tags: ["error_type": String(describing: self)],
            extra: ["recoverable": isRecoverable]
        )
    }
}

// Capture with context
errorMonitoring.captureError(error, context: error.context)
```

### Performance Monitoring
```swift
// Sentry supports performance monitoring
let transaction = SentrySDK.startTransaction(name: "Load Data", operation: "http")
defer { transaction.finish() }

let data = try await fetchData()
```

### Release Tracking
```swift
// Include version info
SentrySDK.start { options in
    options.dsn = "YOUR_DSN"
    options.releaseName = "\(Bundle.main.appVersion)-\(Bundle.main.buildNumber)"
}
```

## Troubleshooting

### Errors Not Appearing in Dashboard

1. **Check DSN** is correct and not expired
2. **Verify** network connectivity
3. **Check** debug mode isn't suppressing uploads
4. **Look** for SDK initialization errors in console

### Symbolication Not Working

1. **Upload dSYMs** to Sentry/Firebase
2. **Enable** "Upload Debug Symbols" build phase
3. **Check** build settings include debug info

### High Volume / Costs

1. **Filter** common/expected errors
2. **Sample** errors (e.g., capture 10%)
3. **Group** similar errors

## Related Skills

- `analytics-setup` - Often combined with error monitoring
- `logging-setup` - Use Logger for debug, error monitoring for production

## References

- [Sentry iOS Documentation](https://docs.sentry.io/platforms/apple/)
- [Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)
- [Apple Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
