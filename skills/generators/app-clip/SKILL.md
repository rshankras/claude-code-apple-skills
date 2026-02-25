---
name: app-clip
description: Generates App Clip targets with invocation URL handling, lightweight experiences, and full app upgrade prompts. Use when user wants NFC/QR/Safari banner invocation, instant app experiences, or App Clip Card setup.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# App Clip Generator

Generate production App Clip infrastructure — a lightweight version of your app invoked from NFC tags, QR codes, Safari banners, or Messages. Includes App Clip target setup, invocation URL handling, experience routing, location confirmation, and full app upgrade flow.

## When This Skill Activates

Use this skill when the user:
- Asks to "add an app clip" or "create an app clip target"
- Mentions "instant app" or "lightweight app experience"
- Wants to set up "App Clip Card" metadata
- Mentions "NFC tag" invocation or "QR code" launching an app
- Asks about "app clip invocation" or "invocation URL handling"
- Wants a "lightweight app experience" for a physical location

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (iOS 14+ required for App Clips, iOS 16+ recommended)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify Xcode project structure (.xcodeproj or .xcworkspace)

### 2. Conflict Detection
Search for existing App Clip targets:
```
Glob: **/*AppClip*/*.swift, **/*Clip*/*.swift
Grep: "NSUserActivityTypeBrowsingWeb" or "AppClipExperience" or "SKOverlay"
```

If existing App Clip target found:
- Ask if user wants to replace or extend it
- If extending, identify which components are missing

### 3. Project Structure
Identify where the main app target lives and where to place the App Clip target alongside it.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Invocation method?**
   - NFC tag only
   - QR code only
   - Safari banner (Smart App Banner)
   - Messages
   - All of the above — recommended

2. **Primary experience?**
   - Order food (restaurant/cafe)
   - Reserve (booking/reservation)
   - Check in (event/location)
   - Preview content (article/product)

3. **Include location confirmation?**
   - Yes — verifies user is physically at the expected location (recommended for physical-world invocations)
   - No — skip location verification

4. **Include full app upgrade prompt?**
   - Yes — show SKOverlay banner to download full app (recommended)
   - No — App Clip only, no upgrade path

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.
Read `patterns.md` for constraints, testing, and best practices.

### Step 2: Create Core Files
Generate these files:
1. `AppClipApp.swift` — @main App struct handling invocation via `.onContinueUserActivity`
2. `InvocationHandler.swift` — Parses invocation URL, extracts parameters, validates against registered experiences
3. `AppClipExperience.swift` — Protocol and concrete experience implementations

### Step 3: Create Location Files (if selected)
4. `LocationConfirmationView.swift` — CLLocationManager-based location verification for physical invocations

### Step 4: Create Upgrade Files (if selected)
5. `FullAppUpgradeView.swift` — SKOverlay-based banner prompting full app download
6. `SharedDataManager.swift` — App Group data sharing between App Clip and full app

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/AppClip/`
- If main app target folder exists -> `AppClip/` at the same level
- Otherwise -> `AppClip/`

## Output Format

After generation, provide:

### Files Created
```
AppClip/
├── AppClipApp.swift              # @main entry point with invocation handling
├── InvocationHandler.swift       # URL parsing and parameter extraction
├── AppClipExperience.swift       # Experience protocol and implementations
├── LocationConfirmationView.swift # Location verification (optional)
├── FullAppUpgradeView.swift      # SKOverlay upgrade prompt (optional)
└── SharedDataManager.swift       # App Group data sharing (optional)
```

### Xcode Target Setup Instructions

1. **Add App Clip Target:**
   - File > New > Target > App Clip
   - Set bundle ID to `{main-app-bundle-id}.Clip`
   - Set deployment target to iOS 16.0

2. **Configure Associated Domains:**
   - Add `appclips:{your-domain.com}` to both main app and App Clip entitlements

3. **Set Up App Group:**
   - Add `group.{your-bundle-id}` to both targets for shared data

4. **Apple-App-Site-Association (AASA) file:**
   - Host at `https://{your-domain.com}/.well-known/apple-app-site-association`

### Integration

**Handle invocation in the App Clip:**
```swift
@main
struct MyAppClip: App {
    @State private var handler = InvocationHandler()

    var body: some Scene {
        WindowGroup {
            ContentView(experience: handler.currentExperience)
                .onContinueUserActivity(
                    NSUserActivityTypeBrowsingWeb
                ) { activity in
                    handler.handle(activity)
                }
        }
    }
}
```

**Route to the correct experience:**
```swift
struct ContentView: View {
    let experience: (any AppClipExperience)?

    var body: some View {
        if let experience {
            AnyView(experience.makeView())
        } else {
            DefaultExperienceView()
        }
    }
}
```

**Share data with the full app:**
```swift
// In App Clip — save order before user upgrades
SharedDataManager.shared.save(order, forKey: "pendingOrder")

// In Full App — restore after install
if let order: Order = SharedDataManager.shared.load(forKey: "pendingOrder") {
    showOrder(order)
}
```

**Prompt full app download:**
```swift
FullAppUpgradeView(
    appStoreID: "123456789",
    benefits: [
        "Order history and favorites",
        "Loyalty rewards program",
        "Push notification for order updates"
    ]
)
```

### Testing

```swift
@Test
func invocationHandlerParsesProductURL() {
    let handler = InvocationHandler()
    let url = URL(string: "https://example.com/clip/product/abc123")!

    let experience = handler.parseURL(url)

    #expect(experience != nil)
    #expect(experience?.experienceType == .previewContent)
    #expect(experience?.parameters["productID"] == "abc123")
}

@Test
func invocationHandlerRejectsInvalidURL() {
    let handler = InvocationHandler()
    let url = URL(string: "https://other-domain.com/something")!

    let experience = handler.parseURL(url)

    #expect(experience == nil)
}

@Test
func sharedDataManagerRoundTrips() {
    let manager = SharedDataManager(suiteName: "group.test")
    let order = Order(id: "order-1", items: ["Latte", "Muffin"])

    manager.save(order, forKey: "testOrder")
    let loaded: Order? = manager.load(forKey: "testOrder")

    #expect(loaded?.id == "order-1")
    #expect(loaded?.items.count == 2)
}
```

## Common Patterns

### Handle Invocation URL
Every App Clip starts from a URL. Parse it to determine what experience to show:
```swift
// URL: https://example.com/clip/order?location=store-42
// -> Route to OrderExperience with locationID = "store-42"
```

### Present Experience Immediately
Users expect instant value. Show the relevant experience within 1-2 seconds, no sign-in required.

### Prompt Full App Install
After the user completes the primary task, show an SKOverlay banner with clear benefits of the full app.

## Gotchas

- **10 MB size limit** — App Clip binary must be under 10 MB. Use SF Symbols, avoid large assets, lazy-load images from network.
- **8-hour data retention** — App Clip data is deleted after 8 hours of inactivity. Use App Group to persist data accessible to the full app.
- **Limited frameworks** — No CallKit, no HealthKit, no CareKit. Limited background processing. Check Apple's framework availability list.
- **No background processing** — App Clips cannot run background tasks, background fetch, or silent push notifications.
- **Must work without sign-in** — App Clips should provide value immediately. Defer sign-in until the full app upgrade.
- **App Clip Card metadata** — Configure in App Store Connect: card image (3000x2000 px), title, subtitle, call-to-action button text.
- **Associated Domains required** — Both the main app and App Clip must have the `appclips:` associated domain configured, and the AASA file must be hosted on the domain.
- **Size budgeting** — Regularly check App Clip size during development with `xcodebuild -exportArchive` or the App Thinning Size Report.

## References

- **templates.md** — All production Swift templates for App Clip infrastructure
- **patterns.md** — Constraints, data lifecycle, testing, and best practices
- Related: `generators/deep-linking` — Universal link and deep link handling
- Related: `generators/onboarding-generator` — Onboarding flow for full app upgrade
