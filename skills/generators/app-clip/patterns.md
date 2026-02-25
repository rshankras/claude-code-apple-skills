# App Clip Patterns & Constraints

## App Clip Size Budget

### The 10 MB Limit

App Clips must be under **10 MB** after App Thinning. This is a hard limit enforced by the system — if exceeded, the App Clip will not launch.

### Strategies to Stay Under 10 MB

| Strategy | Savings | How |
|----------|---------|-----|
| Use SF Symbols | ~2-5 MB | Replace custom icons with system symbols |
| Lazy-load images | ~3-10 MB | Download images from network instead of bundling |
| Minimize dependencies | ~1-5 MB | No SPM packages if possible; inline small utilities |
| Asset catalog optimization | ~1-3 MB | Use vector PDFs, remove unused assets |
| Share code via framework | Varies | Reference shared framework instead of duplicating |
| Remove unused localizations | ~0.5-2 MB | Include only essential languages |

### Checking App Clip Size

```bash
# Build and export archive to check thinned size
xcodebuild archive \
    -scheme "MyAppClip" \
    -archivePath ./build/MyAppClip.xcarchive

xcodebuild -exportArchive \
    -archivePath ./build/MyAppClip.xcarchive \
    -exportPath ./build/export \
    -exportOptionsPlist ExportOptions.plist

# Check the App Thinning Size Report
cat ./build/export/App\ Thinning\ Size\ Report.txt
```

### Xcode Size Monitoring

Add a Run Script build phase to warn when approaching the limit:

```bash
# Warn if App Clip exceeds 8 MB (leaving 2 MB buffer)
APP_CLIP_SIZE=$(stat -f%z "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_PATH}")
LIMIT=$((8 * 1024 * 1024))
if [ "$APP_CLIP_SIZE" -gt "$LIMIT" ]; then
    echo "warning: App Clip binary is $(($APP_CLIP_SIZE / 1024 / 1024)) MB — approaching 10 MB limit"
fi
```

## Available vs Unavailable Frameworks

### Available in App Clips

| Framework | Notes |
|-----------|-------|
| SwiftUI | Full support |
| UIKit | Full support |
| CoreLocation | Location confirmation only (no continuous tracking) |
| MapKit | Display maps |
| StoreKit | SKOverlay for full app promotion |
| WebKit | Limited web views |
| AVFoundation | Media playback |
| CoreImage | Image processing |
| CoreML | On-device ML (watch binary size) |
| AuthenticationServices | Sign in with Apple |
| PassKit | Apple Pay |

### NOT Available in App Clips

| Framework | Alternative |
|-----------|-------------|
| CallKit | Not available — prompt full app download |
| HealthKit | Not available — prompt full app download |
| CareKit | Not available — prompt full app download |
| HomeKit | Not available — prompt full app download |
| ResearchKit | Not available — prompt full app download |
| SensorKit | Not available — prompt full app download |

### Limited in App Clips

| Capability | Limitation |
|------------|------------|
| Background modes | No background fetch, no silent push |
| Push notifications | Ephemeral notifications only (8-hour window) |
| Keychain | Data cleared when App Clip data is deleted |
| File system | Sandbox is temporary — data deleted after inactivity |

## Data Lifecycle

### The 8-Hour Rule

```
User invokes App Clip
    ↓
App Clip launches, creates data
    ↓
User uses App Clip, then leaves
    ↓
8 hours of inactivity
    ↓
System deletes ALL App Clip data:
    - UserDefaults
    - Documents directory
    - Caches directory
    - Keychain items
    ↓
Only App Group data persists (for full app migration)
```

### Data Persistence Strategy

```swift
// ❌ Wrong — data will be lost after 8 hours
UserDefaults.standard.set(orderID, forKey: "lastOrder")

// ✅ Right — persist in App Group for full app to access
let shared = UserDefaults(suiteName: "group.com.yourapp")
shared?.set(orderID, forKey: "lastOrder")
```

### Ephemeral-to-Persistent Migration

When the user installs the full app, migrate data from the App Group:

```swift
// In full app's AppDelegate or root view
func migrateAppClipData() {
    let shared = UserDefaults(suiteName: "group.com.yourapp")

    if let pendingOrderData = shared?.data(forKey: "pendingOrder") {
        let order = try? JSONDecoder().decode(Order.self, from: pendingOrderData)
        // Import into full app's persistent store (Core Data, SwiftData, etc.)
        if let order {
            persistentStore.save(order)
        }
        // Clean up shared data
        shared?.removeObject(forKey: "pendingOrder")
    }
}
```

## Invocation URL Configuration

### App Store Connect Setup

1. Navigate to your app in App Store Connect
2. Go to **App Clip** section
3. Add **App Clip Experiences**:
   - **URL**: The invocation URL prefix (e.g., `https://example.com/clip/`)
   - **Card Image**: 3000 x 2000 px (1.5:1 ratio)
   - **Title**: Up to 30 characters
   - **Subtitle**: Brief description of the experience
   - **Call-to-Action**: Button text (Open, View, Play, etc.)

### Associated Domains Entitlement

Both the main app and the App Clip must include:

```xml
<!-- Main App and App Clip .entitlements -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>appclips:example.com</string>
</array>
```

### Apple-App-Site-Association (AASA) File

Host at `https://example.com/.well-known/apple-app-site-association`:

```json
{
    "appclips": {
        "apps": [
            "TEAM_ID.com.yourapp.Clip"
        ]
    },
    "applinks": {
        "apps": [],
        "details": [
            {
                "appIDs": [
                    "TEAM_ID.com.yourapp",
                    "TEAM_ID.com.yourapp.Clip"
                ],
                "components": [
                    {
                        "/": "/clip/*",
                        "comment": "App Clip invocation URLs"
                    }
                ]
            }
        ]
    }
}
```

### URL Pattern Registration

Register specific URL patterns for different experiences:

```
https://example.com/clip/order?location=*     → Order experience
https://example.com/clip/reserve?venue=*       → Reserve experience
https://example.com/clip/checkin?event=*       → Check-in experience
https://example.com/clip/product/*             → Product preview
```

## Physical Invocation

### NFC Tag Programming

Program NFC tags with your App Clip URL:

```swift
import CoreNFC

func writeAppClipURL(to tag: NFCNDEFTag, locationID: String) async throws {
    let urlString = "https://example.com/clip/order?location=\(locationID)"
    guard let url = URL(string: urlString) else { return }

    let payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url)!
    let message = NFCNDEFMessage(records: [payload])

    try await tag.writeNDEF(message)
}
```

### QR Code Generation

Generate QR codes that invoke the App Clip:

```swift
import CoreImage

func generateAppClipQRCode(for locationID: String, size: CGFloat = 200) -> UIImage? {
    let urlString = "https://example.com/clip/order?location=\(locationID)"

    guard let data = urlString.data(using: .utf8),
          let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }

    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

    guard let ciImage = filter.outputImage else { return nil }

    let scale = size / ciImage.extent.size.width
    let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

    return UIImage(ciImage: scaledImage)
}
```

### App Clip Code Design

App Clip Codes are Apple-designed visual codes (similar to QR codes but with the App Clip logo). Generate them in App Store Connect:

1. Go to your App Clip experience in App Store Connect
2. Select **Create App Clip Code**
3. Choose style: **NFC-integrated** (NFC + visual) or **Scan-only** (visual only)
4. Download SVG for print

## Testing

### Local Testing with Xcode

Set the `_XCAppClipURL` environment variable in the App Clip scheme:

1. Edit Scheme > Run > Arguments > Environment Variables
2. Add: `_XCAppClipURL` = `https://example.com/clip/order?location=store-42`
3. Run the App Clip target — it will receive the URL on launch

### TestFlight Testing

1. Archive and upload the main app (which includes the App Clip)
2. In TestFlight, add testers
3. Provide test invocation URLs to testers
4. Testers can invoke the App Clip from Safari, QR code, or NFC

### Unit Testing the Invocation Handler

```swift
import Testing

@Suite("InvocationHandler")
struct InvocationHandlerTests {

    @Test("Parses order URL with location parameter")
    func parseOrderURL() {
        let handler = InvocationHandler()
        let url = URL(string: "https://example.com/clip/order?location=store-42")!

        let experience = handler.parseURL(url)

        #expect(experience != nil)
        #expect(experience?.experienceType == .orderFood)
        #expect(experience?.parameters["locationID"] == "store-42")
    }

    @Test("Parses reservation URL with venue parameter")
    func parseReserveURL() {
        let handler = InvocationHandler()
        let url = URL(string: "https://example.com/clip/reserve?venue=restaurant-7")!

        let experience = handler.parseURL(url)

        #expect(experience != nil)
        #expect(experience?.experienceType == .reserve)
        #expect(experience?.parameters["venueID"] == "restaurant-7")
    }

    @Test("Parses check-in URL with event parameter")
    func parseCheckInURL() {
        let handler = InvocationHandler()
        let url = URL(string: "https://example.com/clip/checkin?event=concert-123")!

        let experience = handler.parseURL(url)

        #expect(experience != nil)
        #expect(experience?.experienceType == .checkIn)
        #expect(experience?.parameters["eventID"] == "concert-123")
    }

    @Test("Parses product URL with path parameter")
    func parseProductURL() {
        let handler = InvocationHandler()
        let url = URL(string: "https://example.com/clip/product/abc123")!

        let experience = handler.parseURL(url)

        #expect(experience != nil)
        #expect(experience?.experienceType == .previewContent)
        #expect(experience?.parameters["productID"] == "abc123")
    }

    @Test("Rejects URL from unregistered domain")
    func rejectUnregisteredDomain() {
        let handler = InvocationHandler()
        let url = URL(string: "https://other-domain.com/clip/order?location=store-1")!

        let experience = handler.parseURL(url)

        #expect(experience == nil)
    }

    @Test("Rejects URL without clip path prefix")
    func rejectMissingClipPrefix() {
        let handler = InvocationHandler()
        let url = URL(string: "https://example.com/order?location=store-1")!

        let experience = handler.parseURL(url)

        #expect(experience == nil)
    }

    @Test("Rejects URL with unknown action")
    func rejectUnknownAction() {
        let handler = InvocationHandler()
        let url = URL(string: "https://example.com/clip/unknown?param=value")!

        let experience = handler.parseURL(url)

        #expect(experience == nil)
    }

    @Test("Rejects order URL missing required location parameter")
    func rejectMissingLocationParam() {
        let handler = InvocationHandler()
        let url = URL(string: "https://example.com/clip/order")!

        let experience = handler.parseURL(url)

        #expect(experience == nil)
    }
}
```

### Testing Shared Data Manager

```swift
@Suite("SharedDataManager")
struct SharedDataManagerTests {

    struct TestOrder: Codable, Equatable {
        let id: String
        let items: [String]
        let total: Double
    }

    @Test("Round-trips Codable data")
    func roundTrip() {
        let manager = SharedDataManager(suiteName: "group.test.appclip")
        let order = TestOrder(id: "order-1", items: ["Latte", "Muffin"], total: 9.48)

        manager.save(order, forKey: "testOrder")
        let loaded: TestOrder? = manager.load(forKey: "testOrder")

        #expect(loaded == order)

        // Cleanup
        manager.remove(forKey: "testOrder")
    }

    @Test("Returns nil for missing key")
    func missingKey() {
        let manager = SharedDataManager(suiteName: "group.test.appclip")

        let result: TestOrder? = manager.load(forKey: "nonexistent")

        #expect(result == nil)
    }

    @Test("Stores timestamp alongside data")
    func timestampStorage() {
        let manager = SharedDataManager(suiteName: "group.test.appclip")
        let order = TestOrder(id: "order-2", items: ["Espresso"], total: 3.50)

        let before = Date()
        manager.save(order, forKey: "timestampTest")
        let after = Date()

        let timestamp = manager.timestamp(forKey: "timestampTest")
        #expect(timestamp != nil)
        #expect(timestamp! >= before)
        #expect(timestamp! <= after)

        // Cleanup
        manager.remove(forKey: "timestampTest")
    }

    @Test("Detects pending migration keys")
    func pendingMigration() {
        let manager = SharedDataManager(suiteName: "group.test.appclip")
        let order = TestOrder(id: "order-3", items: ["Tea"], total: 2.50)

        manager.save(order, forKey: "pendingOrder")

        let pending = manager.pendingMigrationKeys(from: ["pendingOrder", "otherKey"])
        #expect(pending == ["pendingOrder"])

        // Cleanup
        manager.remove(forKey: "pendingOrder")
    }

    @Test("Clears migrated data")
    func clearMigrated() {
        let manager = SharedDataManager(suiteName: "group.test.appclip")
        let order = TestOrder(id: "order-4", items: ["Cookie"], total: 1.99)

        manager.save(order, forKey: "migrateTest")
        manager.clearMigratedData(keys: ["migrateTest"])

        let loaded: TestOrder? = manager.load(forKey: "migrateTest")
        #expect(loaded == nil)
        #expect(manager.timestamp(forKey: "migrateTest") == nil)
    }
}
```

## Best Practices

### Instant Value
The user tapped an NFC tag or scanned a QR code — they expect immediate results. Every second of delay increases abandonment.

```swift
// ✅ Show UI immediately, load data in background
struct OrderExperienceView: View {
    @State private var isLoading = true

    var body: some View {
        // Skeleton UI appears instantly
        if isLoading {
            OrderSkeletonView()
        } else {
            OrderContentView()
        }
    }
}

// ❌ Blank screen while loading
struct OrderExperienceView: View {
    var body: some View {
        ProgressView() // User sees spinner, no context
    }
}
```

### No Sign-In Required
App Clips must provide value without authentication. Defer sign-in to the full app.

```swift
// ✅ Allow anonymous ordering, collect identity later
struct OrderFlow {
    func placeOrder(items: [MenuItem]) async {
        // Create order without requiring account
        let order = Order(items: items, guestID: UUID().uuidString)
        await submitOrder(order)
    }
}

// ❌ Block the experience with a login screen
struct OrderFlow {
    func placeOrder() {
        showLoginSheet() // User leaves immediately
    }
}
```

### Clear Upgrade Path
After the user completes their task, show the value of the full app:

```swift
// ✅ Show upgrade after task completion
struct OrderConfirmationView: View {
    var body: some View {
        VStack {
            // Order confirmation content
            OrderReceiptView(order: order)

            Spacer()

            // Contextual upgrade prompt
            UpgradeBanner(appStoreID: "123456789")
        }
    }
}
```

### Minimal Permissions
Request only what is absolutely necessary. Every permission prompt is friction.

```swift
// ✅ Only request location for physical-location experiences
// ✅ Use Sign in with Apple (minimal friction) if auth is needed
// ✅ Use Apple Pay (no form filling)

// ❌ Don't request notification permission in App Clip
// ❌ Don't request camera unless core to the experience
// ❌ Don't request contacts, calendar, etc.
```

## Anti-Patterns to Avoid

### Don't Bundle Large Assets
```swift
// ❌ 5 MB image bundled in asset catalog
Image("hero-background") // Eats half the size budget

// ✅ Use SF Symbols or load from network
Image(systemName: "fork.knife.circle.fill")
    .font(.system(size: 60))
```

### Don't Use Heavy Dependencies
```swift
// ❌ Adding Alamofire, SDWebImage, etc. bloats the binary
// Each SPM dependency can add 0.5-2 MB

// ✅ Use URLSession directly — it's already available
let (data, response) = try await URLSession.shared.data(from: url)
```

### Don't Persist Sensitive Data in App Clip Sandbox
```swift
// ❌ Keychain data is deleted with App Clip data
try keychain.set(token, forKey: "authToken")

// ✅ Store in App Group if full app needs it
SharedDataManager.shared.save(token, forKey: "authToken")
```

### Don't Ignore the Size Budget During Development
```swift
// ❌ "We'll optimize later" — then you're 15 MB at submission

// ✅ Check size on every PR
// Add a CI step that builds the App Clip and checks the thinned size
```
