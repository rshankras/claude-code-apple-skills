# Consent Flow Patterns & Compliance Reference

## Regulation Comparison

| Aspect | GDPR (EU) | CCPA (California) | DPDP (India) |
|--------|-----------|-------------------|--------------|
| **Consent Model** | Opt-in required | Opt-out (right to say no) | Opt-in required |
| **Default State** | Not determined | Implied consent until opt-out | Not determined |
| **Age Threshold** | 16 (states can lower to 13) | 16 (13 for sale-of-data) | 18 |
| **Right to Access** | Yes (30 days) | Yes (45 days) | Yes |
| **Right to Delete** | Yes | Yes | Yes |
| **Data Portability** | Yes (machine-readable) | No (not required) | Yes |
| **Penalties** | Up to 4% global revenue or 20M EUR | $2,500–$7,500 per violation | Up to 250 crore INR |
| **Applies To** | Any company processing EU resident data | Businesses meeting CA thresholds | Processing of Indian citizens' data |
| **Consent Withdrawal** | Must be as easy as giving consent | Must provide opt-out mechanism | Must be as easy as giving consent |
| **Record Keeping** | Must demonstrate consent was given | Must record opt-out requests | Must maintain records |
| **Cross-Border** | Requires adequacy decisions or SCCs | No specific restriction | Government may restrict transfers |

### Practical Implementation Differences

```swift
/// Determine initial consent state based on applicable regulation.
func initialConsentStatus(
    for category: ConsentCategory,
    regulation: ConsentRegulation
) -> ConsentStatus {
    guard !category.isRequired else { return .granted }

    switch regulation {
    case .gdpr:
        return .notDetermined  // Must explicitly opt in
    case .ccpa:
        return .granted        // Opted in by default, user can opt out
    case .dpdp:
        return .notDetermined  // Must explicitly opt in
    }
}
```

## Apple's App Tracking Transparency (ATT)

### What ATT Covers

ATT controls access to the device's IDFA (Identifier for Advertisers). You must request ATT before:
- Accessing `ASIdentifierManager.shared().advertisingIdentifier`
- Using any SDK that reads the IDFA (Facebook SDK, Google Ads, etc.)
- Fingerprinting the device for tracking across apps/websites

### When to Request ATT

```
App Launch ──► Show Own Consent Banner ──► User Taps "Accept" ──► Request ATT ──► Enable Tracking
                                           │
                                           ├── User Taps "Reject" ──► No ATT Request ──► No Tracking
                                           │
                                           └── User Taps "Manage" ──► Preferences ──► Based on Choices
```

**Key rules:**
1. Never request ATT at cold launch — Apple may reject the app
2. Show your own explanation first, then call `requestTrackingAuthorization`
3. ATT dialog can only be shown once — subsequent calls return the cached status
4. If denied, you cannot re-prompt; guide users to Settings > Privacy > Tracking

### ATT and Consent Relationship

```swift
/// Map ATT authorization status to marketing consent.
func syncATTWithConsent(
    attStatus: ATTrackingManager.AuthorizationStatus,
    consentManager: ConsentManager
) {
    switch attStatus {
    case .authorized:
        // User allowed tracking at OS level — check app-level consent too
        // Both ATT AND app consent must be granted
        break
    case .denied:
        // User denied at OS level — must deny marketing regardless of app consent
        consentManager.updateConsent(for: .marketing, granted: false)
    case .restricted:
        // Device management or parental controls — cannot track
        consentManager.updateConsent(for: .marketing, granted: false)
    case .notDetermined:
        // Haven't asked yet
        break
    @unknown default:
        break
    }
}
```

### ATT and SKAdNetwork

SKAdNetwork provides privacy-preserving ad attribution without requiring ATT:
- Aggregated conversion data (not per-user)
- Delayed postbacks to prevent user identification
- No IDFA access needed

If ATT is denied, fall back to SKAdNetwork for attribution data.

### Resetting ATT in Simulator for Testing

ATT authorization persists per app install. To reset:
1. **Simulator:** Delete the app and reinstall, OR reset the simulator (Device > Erase All Content and Settings)
2. **Device:** Settings > General > Transfer or Reset > Reset > Reset Location & Privacy

```swift
// Check current ATT status without prompting
let currentStatus = ATTrackingManager.trackingAuthorizationStatus
print("ATT Status: \(currentStatus.rawValue)")
// 0 = notDetermined, 1 = restricted, 2 = denied, 3 = authorized
```

## Consent UX Best Practices

### Progressive Disclosure

Show a brief banner first. Detailed preferences are one tap away:

```
┌─────────────────────────────────────────────┐
│ 🛡️ Your Privacy Matters                     │
│                                              │
│ We use data processing to improve your       │
│ experience. You choose what's allowed.       │
│                                              │
│ [  Accept All  ]  (prominent, but not only)  │
│ [Manage] [Reject Non-Essential]              │
│                                              │
│ Privacy Policy                               │
└─────────────────────────────────────────────┘
```

### No Dark Patterns

These practices violate GDPR and lead to App Store rejection:

| Dark Pattern | Problem | Correct Approach |
|-------------|---------|-----------------|
| Pre-checked consent boxes | Not valid consent under GDPR | All non-essential default to off |
| Consent wall (block app until accept) | Coerced consent is not freely given | Allow "Reject" and still use app |
| "Accept" is prominent, "Reject" is hidden | Unequal treatment of choices | Equal visual prominence for all options |
| "Accept" is one tap, "Reject" requires 5 steps | Withdrawal must be as easy as granting | Same number of taps for both |
| Misleading category names | Must be clear and specific | Plain language descriptions |
| Auto-dismissing banner | User didn't make a choice | Banner persists until action taken |
| Re-prompting after rejection | Nagging violates GDPR | Respect the decision, offer settings link |

### Equal Prominence for Accept/Reject

```swift
// ❌ Wrong — "Accept" is prominent, "Reject" is a text link
Button("Accept All") { acceptAll() }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)

Button("Reject") { rejectAll() }
    .font(.caption)
    .foregroundStyle(.secondary)

// ✅ Right — Both actions have clear, tappable buttons
Button("Accept All") { acceptAll() }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)

HStack(spacing: 10) {
    Button("Manage Preferences") { showPreferences() }
        .buttonStyle(.bordered)
        .controlSize(.regular)

    Button("Reject Non-Essential") { rejectAll() }
        .buttonStyle(.bordered)
        .controlSize(.regular)
}
```

### Consent Language

```swift
// ❌ Wrong — Vague, manipulative
"We need your data to give you the best experience. Please accept to continue."

// ✅ Right — Specific, neutral
"We use analytics to understand how the app is used and improve it.
Marketing data helps show relevant ads. You can change these choices anytime in Settings."
```

## Data Rights Implementation

### Right to Access (GDPR Art. 15, CCPA, DPDP)

```swift
/// Compile all user data for a data subject access request.
struct DataAccessReport: Codable {
    let generatedAt: Date
    let consentHistory: [ConsentAuditLog.Entry]
    let currentPreferences: [String: String]
    let dataCategories: [DataCategoryReport]

    struct DataCategoryReport: Codable {
        let category: String
        let description: String
        let dataPoints: [String]
        let retentionPeriod: String
    }
}

func generateAccessReport(
    consentManager: ConsentManager,
    auditLog: ConsentAuditLog
) throws -> Data {
    let report = DataAccessReport(
        generatedAt: Date(),
        consentHistory: auditLog.allEntries(),
        currentPreferences: Dictionary(
            uniqueKeysWithValues: ConsentCategory.allCases.map {
                ($0.displayName, consentManager.hasConsent(for: $0) ? "Granted" : "Denied")
            }
        ),
        dataCategories: [] // App-specific: populate with actual data categories
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(report)
}
```

### Right to Delete (GDPR Art. 17, CCPA, DPDP)

```swift
/// Delete all user data associated with consent categories.
func handleDeletionRequest(consentManager: ConsentManager) async {
    // 1. Reset all consent
    consentManager.resetAllConsent()

    // 2. Delete analytics data
    AnalyticsService.shared.deleteAllData()

    // 3. Delete marketing/ad data
    MarketingService.shared.deleteUserProfile()

    // 4. Delete personalization data
    RecommendationEngine.shared.clearUserModel()

    // 5. Notify backend to delete server-side data
    try? await APIClient.shared.requestDataDeletion()

    // Note: Keep the audit log — it proves you had consent and then deleted data
}
```

### Data Portability (GDPR Art. 20)

```swift
/// Export user data in a machine-readable format (JSON).
func exportUserData() throws -> Data {
    // Must be in a commonly used, machine-readable format
    // JSON or CSV are acceptable
    let userData = UserDataExport(
        exportDate: Date(),
        consent: consentAuditLog.allEntries(),
        // Include other personal data categories
        profile: userProfile,
        activityHistory: activityLog
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted]
    return try encoder.encode(userData)
}
```

## Audit Trail Requirements

### What to Log

Every consent event must record:

| Field | Purpose | Example |
|-------|---------|---------|
| Timestamp | When the decision was made | 2025-03-15T14:30:00Z |
| Category | Which processing category | analytics |
| Decision | Granted or denied | granted |
| Regulation | Which regulation applied | GDPR |
| App Version | For traceability | 2.1.0 |
| OS Version | Environment context | iOS 17.4 |
| Entry ID | Unique identifier | UUID |

### Retention Period

- **GDPR:** Keep consent records for as long as the processing occurs + reasonable period after
- **Recommended:** 3 years minimum — matches many statute of limitations periods
- **Pruning:** Periodically remove entries older than retention period

### Export Format

Use ISO 8601 dates, JSON structure, and include all fields:

```json
[
    {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "category": "analytics",
        "status": "granted",
        "regulation": "gdpr",
        "timestamp": "2025-03-15T14:30:00Z",
        "appVersion": "2.1.0",
        "osVersion": "Version 17.4 (Build 21E219)"
    }
]
```

## Common Anti-Patterns

### Pre-Checked Consent Boxes
```swift
// ❌ Wrong — Pre-checked violates GDPR
@State private var analyticsEnabled = true   // Default to true
@State private var marketingEnabled = true   // Default to true

// ✅ Right — Default to not determined
// ConsentManager initializes non-essential categories as .notDetermined
```

### Consent Wall (Blocking App Usage)
```swift
// ❌ Wrong — App is unusable without consent
if !consentManager.hasConsent(for: .analytics) {
    ConsentRequiredView() // Blocks all functionality
}

// ✅ Right — App works without consent, features degrade gracefully
ContentView()
    .overlay(alignment: .bottom) {
        if consentManager.needsConsent {
            ConsentBannerView() // Non-blocking overlay
        }
    }
```

### Nagging After Rejection
```swift
// ❌ Wrong — Re-showing consent banner every launch after rejection
.onAppear {
    showConsentBanner = true // Always shows, even after explicit rejection
}

// ✅ Right — Only show when not yet determined
.onAppear {
    // needsConsent is false once user has made a decision (grant or deny)
}
```

### Ignoring ATT Denial
```swift
// ❌ Wrong — Tracking despite ATT denial
func trackEvent(_ event: Event) {
    // No ATT check — Apple will reject this
    analyticsSDK.track(event)
}

// ✅ Right — Check both ATT and app consent
func trackEvent(_ event: Event) {
    #if os(iOS)
    guard ATTrackingManager.trackingAuthorizationStatus == .authorized else { return }
    #endif
    guard consentManager.hasConsent(for: .analytics) else { return }
    analyticsSDK.track(event)
}
```

### Storing Consent Without Audit Trail
```swift
// ❌ Wrong — Only stores current state, no history
UserDefaults.standard.set(true, forKey: "analyticsConsent")

// ✅ Right — Records decision with full audit metadata
consentManager.updateConsent(for: .analytics, granted: true)
// Internally logs to ConsentAuditLog with timestamp, regulation, app version
```

## Testing Consent Flows

### Unit Testing ConsentManager

```swift
@Test
func newManagerNeedsConsent() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let manager = ConsentManager(defaults: defaults)
    #expect(manager.needsConsent == true)
}

@Test
func grantAllResolvesNeedsConsent() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let manager = ConsentManager(defaults: defaults)
    manager.grantAll()
    #expect(manager.needsConsent == false)
}

@Test
func consentPersistsAcrossInstances() {
    let suiteName = UUID().uuidString
    let defaults1 = UserDefaults(suiteName: suiteName)!
    let manager1 = ConsentManager(defaults: defaults1)
    manager1.updateConsent(for: .analytics, granted: true)

    let defaults2 = UserDefaults(suiteName: suiteName)!
    let manager2 = ConsentManager(defaults: defaults2)
    #expect(manager2.hasConsent(for: .analytics) == true)
}

@Test
func resetReturnsToNotDetermined() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let manager = ConsentManager(defaults: defaults)
    manager.grantAll()
    manager.resetAllConsent()
    #expect(manager.needsConsent == true)
    #expect(manager.hasConsent(for: .analytics) == false)
}
```

### Testing Different Regulation Scenarios

```swift
@Test
func gdprDefaultsToNotDetermined() {
    let manager = ConsentManager(regulation: .gdpr)
    for category in ConsentCategory.consentable {
        #expect(manager.hasConsent(for: category) == false)
    }
}

@Test
func ccpaDefaultsToGranted() {
    let manager = ConsentManager(regulation: .ccpa)
    for category in ConsentCategory.consentable {
        // CCPA is opt-out: default state should be granted
        #expect(manager.hasConsent(for: category) == true)
    }
}
```

### Testing Audit Log

```swift
@Test
func auditLogRecordsAllDecisions() {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let log = ConsentAuditLog(directory: tempDir)
    log.record(category: .analytics, granted: true, regulation: .gdpr)
    log.record(category: .analytics, granted: false, regulation: .gdpr)

    // Allow async write to complete
    Thread.sleep(forTimeInterval: 0.1)

    let entries = log.allEntries()
    #expect(entries.count == 2)
    #expect(entries[0].status == .denied)  // Most recent first
    #expect(entries[1].status == .granted)
}

@Test
func auditLogExportsValidJSON() throws {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    let log = ConsentAuditLog(directory: tempDir)
    log.record(category: .marketing, granted: true, regulation: .ccpa)

    Thread.sleep(forTimeInterval: 0.1)

    let jsonData = try log.exportJSON()
    let decoded = try JSONDecoder().decode(
        [ConsentAuditLog.Entry].self,
        from: jsonData
    )
    #expect(decoded.count == 1)
    #expect(decoded[0].category == .marketing)
}
```

### Resetting ATT in Simulator

```swift
// In test setup, note that ATT always returns .notDetermined in the simulator.
// For device testing:
// 1. Delete and reinstall the app to reset ATT state
// 2. Or reset all privacy settings: Settings > General > Transfer or Reset > Reset Location & Privacy

#if DEBUG
extension ConsentManager {
    /// Reset consent state for testing. Only available in debug builds.
    func resetForTesting() {
        resetAllConsent()
        // ATT cannot be programmatically reset — requires app reinstall
    }
}
#endif
```

### UI Testing Consent Banner

```swift
func testConsentBannerAppearsOnFirstLaunch() {
    let app = XCUIApplication()
    app.launchArguments.append("--reset-consent")
    app.launch()

    // Banner should be visible
    let banner = app.otherElements["consentBanner"]
    XCTAssertTrue(banner.waitForExistence(timeout: 3))

    // All three buttons should exist
    XCTAssertTrue(app.buttons["Accept All"].exists)
    XCTAssertTrue(app.buttons["Manage Preferences"].exists)
    XCTAssertTrue(app.buttons["Reject Non-Essential"].exists)
}

func testAcceptAllDismissesBanner() {
    let app = XCUIApplication()
    app.launchArguments.append("--reset-consent")
    app.launch()

    app.buttons["Accept All"].tap()

    let banner = app.otherElements["consentBanner"]
    XCTAssertFalse(banner.waitForExistence(timeout: 2))
}

func testManagePreferencesShowsAllCategories() {
    let app = XCUIApplication()
    app.launchArguments.append("--reset-consent")
    app.launch()

    app.buttons["Manage Preferences"].tap()

    // All categories should be visible
    XCTAssertTrue(app.staticTexts["Essential"].exists)
    XCTAssertTrue(app.staticTexts["Analytics"].exists)
    XCTAssertTrue(app.staticTexts["Marketing"].exists)
    XCTAssertTrue(app.staticTexts["Personalization"].exists)
    XCTAssertTrue(app.staticTexts["Functional"].exists)

    // Essential toggle should be disabled (always on)
    let essentialToggle = app.switches["Essential"]
    XCTAssertFalse(essentialToggle.isEnabled)
}
```
