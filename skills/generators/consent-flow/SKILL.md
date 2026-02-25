---
name: consent-flow
description: Generates GDPR/CCPA/DPDP privacy consent flows with granular category preferences, consent state persistence, audit logging, and ATT (App Tracking Transparency) integration. Use when user needs privacy consent UI, cookie/tracking consent, or compliance management.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Consent Flow Generator

Generate a production privacy consent system with granular category-based consent, persistent state management, a consent banner and preferences UI, audit logging for compliance, and App Tracking Transparency integration.

## When This Skill Activates

Use this skill when the user:
- Asks about "privacy consent" or "consent management"
- Mentions "GDPR consent" or "GDPR compliance"
- Wants "cookie consent" or "tracking consent"
- Mentions "ATT prompt" or "App Tracking Transparency"
- Asks for "privacy preferences" or "consent preferences"
- Mentions "CCPA compliance" or "DPDP compliance"
- Wants to "manage user consent" or "consent banner"
- Asks about "consent audit log" or "consent records"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing consent or privacy code:
```
Glob: **/*Consent*.swift, **/*Privacy*.swift, **/*Tracking*.swift, **/*GDPR*.swift
Grep: "ATTrackingManager" or "ConsentManager" or "trackingAuthorizationStatus"
```

If third-party library found (OneTrust, Usercentrics, CookieBot):
- Ask if user wants to replace or keep it
- If keeping, don't generate — advise on integration best practices instead

### 3. ATT Framework Availability
Check for App Tracking Transparency framework:
```
Grep: "AppTrackingTransparency" in project files
Grep: "NSUserTrackingUsageDescription" in Info.plist
```

If `NSUserTrackingUsageDescription` is missing from Info.plist, warn the user that ATT requires this key and offer to add it.

### 4. Platform Detection
Determine if generating for iOS (primary ATT target) or macOS (ATT not applicable) or both.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Target regulations?**
   - GDPR only (EU — opt-in model)
   - CCPA only (California — opt-out model)
   - DPDP only (India — consent-based)
   - All regulations (recommended for global apps)

2. **Consent categories?** (multi-select)
   - Essential (always on, cannot be disabled)
   - Analytics (usage tracking, crash reporting)
   - Marketing (advertising, attribution)
   - Personalization (recommendations, content tailoring)
   - Functional (preferences, saved settings beyond essential)

3. **Include ATT integration?**
   - Yes — request ATT permission before any tracking (recommended for iOS)
   - No — handle consent without ATT (macOS, or no IDFA usage)

4. **Consent UI style?**
   - Bottom banner with manage preferences (recommended)
   - Full-screen consent view (for first launch)
   - Settings-embedded (preferences in app settings, no banner)
   - Banner + Settings (banner on first launch, preferences in settings)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.
Read `patterns.md` for compliance rules, regulation differences, and UX guidance.

### Step 2: Create Core Files
Generate these files:
1. `ConsentCategory.swift` — Enum of consent categories with metadata
2. `ConsentDecision.swift` — Per-category consent state with timestamp
3. `ConsentManager.swift` — @Observable manager with persistence and ATT integration
4. `ConsentAuditLog.swift` — Compliance audit trail with JSON export

### Step 3: Create UI Files
5. `ConsentBannerView.swift` — Animated slide-up consent banner
6. `ConsentPreferencesView.swift` — Detailed toggle list for each category

### Step 4: Create Optional Files
Based on configuration:
- `ConsentRegulationConfig.swift` — If multiple regulations selected
- `ConsentATTBridge.swift` — If ATT integration selected (extracted for testability)

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists → `Sources/Consent/`
- If `App/` exists → `App/Consent/`
- Otherwise → `Consent/`

## Output Format

After generation, provide:

### Files Created
```
Consent/
├── ConsentCategory.swift        # Consent category enum with metadata
├── ConsentDecision.swift         # Per-category decision with timestamp
├── ConsentManager.swift          # @Observable manager with persistence
├── ConsentAuditLog.swift         # Compliance audit trail
├── ConsentBannerView.swift       # Animated consent banner
├── ConsentPreferencesView.swift  # Granular preferences UI
├── ConsentRegulationConfig.swift # Multi-regulation rules (optional)
└── ConsentATTBridge.swift        # ATT integration bridge (optional)
```

### Integration Steps

**Show consent on first launch:**
```swift
@main
struct MyApp: App {
    @State private var consentManager = ConsentManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(consentManager)
                .overlay(alignment: .bottom) {
                    if consentManager.needsConsent {
                        ConsentBannerView()
                            .environment(consentManager)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: consentManager.needsConsent)
        }
    }
}
```

**Check consent before tracking:**
```swift
func trackEvent(_ event: AnalyticsEvent) {
    guard consentManager.hasConsent(for: .analytics) else { return }
    analyticsService.track(event)
}

func showPersonalizedAd() {
    guard consentManager.hasConsent(for: .marketing) else {
        showGenericAd()
        return
    }
    adService.showPersonalized()
}
```

**Open preferences from settings:**
```swift
NavigationLink("Privacy Preferences") {
    ConsentPreferencesView()
        .environment(consentManager)
}
```

**Export audit log for data requests:**
```swift
func handleDataRequest() async throws -> Data {
    let auditLog = ConsentAuditLog.shared
    return try auditLog.exportJSON()
}
```

### Testing

```swift
@Test
func consentGrantedPersistsAcrossLaunches() async {
    let defaults = UserDefaults(suiteName: "test")!
    defaults.removePersistentDomain(forName: "test")
    let manager = ConsentManager(defaults: defaults)

    manager.updateConsent(for: .analytics, granted: true)

    let manager2 = ConsentManager(defaults: defaults)
    #expect(manager2.hasConsent(for: .analytics) == true)
}

@Test
func essentialConsentCannotBeRevoked() {
    let manager = ConsentManager()
    manager.updateConsent(for: .essential, granted: false)
    #expect(manager.hasConsent(for: .essential) == true) // Always granted
}

@Test
func auditLogRecordsDecisions() {
    let log = ConsentAuditLog(directory: tempDirectory)
    log.record(category: .analytics, granted: true, regulation: .gdpr)

    let entries = log.allEntries()
    #expect(entries.count == 1)
    #expect(entries[0].category == .analytics)
    #expect(entries[0].granted == true)
}

@Test
func denyAllRevokesNonEssentialCategories() {
    let manager = ConsentManager()
    manager.grantAll()
    manager.denyAllNonEssential()

    #expect(manager.hasConsent(for: .essential) == true)
    #expect(manager.hasConsent(for: .analytics) == false)
    #expect(manager.hasConsent(for: .marketing) == false)
}
```

## Common Patterns

### Show Consent on First Launch
```swift
.onAppear {
    if consentManager.needsConsent {
        // Banner auto-shows via overlay
    }
}
```

### Update Preferences Later
```swift
Button("Privacy Settings") {
    showPreferences = true
}
.sheet(isPresented: $showPreferences) {
    ConsentPreferencesView()
        .environment(consentManager)
}
```

### Check Consent Before Any Tracking Call
```swift
extension ConsentManager {
    func executeIfConsented(
        category: ConsentCategory,
        action: () -> Void
    ) {
        guard hasConsent(for: category) else { return }
        action()
    }
}
```

### Export Audit Log for Data Subject Requests
```swift
let jsonData = try consentManager.auditLog.exportJSON()
// Attach to email or upload to compliance endpoint
```

## Gotchas

### ATT Must Be Requested Before Any Tracking
Apple rejects apps that access IDFA before calling `ATTrackingManager.requestTrackingAuthorization`. Always request ATT first, then enable tracking SDKs based on the result.

### GDPR Requires Opt-In (Not Opt-Out)
Under GDPR, all non-essential tracking requires explicit opt-in consent. Pre-checked boxes or implied consent are not valid. The default state for all non-essential categories must be `.notDetermined`, not `.granted`.

### Consent Must Be As Easy to Withdraw As to Grant
GDPR Article 7(3): "It shall be as easy to withdraw as to give consent." If consent is granted with one tap on a banner, it must be revocable with equal ease — not buried 5 screens deep in settings.

### Different Regulations Have Different Age Thresholds
- GDPR: 16 years (member states can lower to 13)
- CCPA: 16 years for sale of data, 13 for minors
- DPDP: 18 years (parental consent required below)

If your app serves minors, you need age verification before consent collection.

### Don't Block the UI on ATT
`ATTrackingManager.requestTrackingAuthorization` is async and shows a system dialog. Never call it during app launch or in a way that blocks the main UI. Show your own consent banner first, then request ATT as a secondary step.

### Consent State Must Survive App Reinstall (GDPR)
For GDPR compliance, consider syncing consent state to a server. UserDefaults is deleted on app uninstall. If a user reinstalls, you must re-request consent — never assume prior consent.

## References

- **templates.md** — All production Swift templates for consent flow
- **patterns.md** — Regulation comparison, ATT details, UX best practices, anti-patterns
- Related: `generators/permission-priming` — Pre-permission UI patterns (ATT priming)
- Related: `generators/analytics-setup` — Analytics that respects consent state
- Related: `generators/settings-screen` — Embedding consent preferences in settings
