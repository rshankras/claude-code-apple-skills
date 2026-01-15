# Privacy Checklist

Privacy and data handling review for macOS and iOS applications.

## Data Collection Transparency

### What to Document

Users should understand:
1. **What** data is collected
2. **Why** it's collected
3. **Where** it's stored (local vs. cloud)
4. **Who** has access (first-party only vs. third parties)
5. **How long** it's retained

### In-App Transparency

#### ✅ Good Pattern
```swift
// Privacy section in Settings
Section("Privacy & Data") {
    DisclosureGroup {
        VStack(alignment: .leading, spacing: 12) {
            Label("What we access", systemImage: "folder")
            Text("Local session files for usage calculation")
                .font(.caption)

            Label("What we send", systemImage: "arrow.up.circle")
            Text("Only your token to fetch YOUR quota data")
                .font(.caption)

            Label("What stays local", systemImage: "lock.shield")
            Text("All calculations happen on your Mac")
                .font(.caption)
        }
    } label: {
        Label("What data does this app access?", systemImage: "hand.raised")
    }
}
```

### Checklist
- [ ] App explains what data it collects (in Settings or onboarding)
- [ ] Data usage is justified and proportionate
- [ ] Users can see what data is stored
- [ ] Clear distinction between local and cloud data

## Privacy Manifest (iOS 17+)

### Required APIs

If your app uses these APIs, you need a Privacy Manifest:

```xml
<!-- PrivacyInfo.xcprivacy -->
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>CA92.1</string> <!-- App functionality -->
        </array>
    </dict>
</array>
```

### APIs Requiring Declaration
- UserDefaults
- File timestamp APIs
- System boot time APIs
- Disk space APIs
- Active keyboard APIs

### Checklist
- [ ] Privacy Manifest created if using required APIs
- [ ] All required API reasons documented
- [ ] Third-party SDK privacy manifests included

## User Consent

### Permission Requests

#### ✅ Good Patterns
```swift
// Request permission with context
Button("Enable Notifications") {
    // User initiated - good UX
    requestNotificationPermission()
}

// Explain before requesting
Alert("Location Access",
      message: "We use your location to show nearby stores. Your location is never shared.")
```

#### ❌ Anti-patterns
```swift
// Don't request on launch without context
func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
    // BAD: Immediate permission request
    CLLocationManager().requestWhenInUseAuthorization()
}
```

### Checklist
- [ ] Permissions requested in context (not on first launch)
- [ ] Clear explanation before each permission request
- [ ] App works (with reduced functionality) if permission denied
- [ ] No repeated permission requests after denial

## Data Retention & Deletion

### User Control

#### ✅ Good Pattern
```swift
// Clear data option in Settings
Button("Delete All Data", role: .destructive) {
    DataManager.shared.deleteAllData()
    // Also clear Keychain if applicable
    KeychainHelper.clearCredentials()
}

// Export before delete option
Button("Export My Data") {
    ExportManager.exportUserData()
}
```

### Checklist
- [ ] Users can delete their data
- [ ] Data deletion is complete (including Keychain, caches)
- [ ] Users can export their data
- [ ] Uninstall removes all user data (document if not)

## Third-Party SDKs

### Audit Checklist
- [ ] List all third-party SDKs used
- [ ] Understand what data each SDK collects
- [ ] SDK privacy policies reviewed
- [ ] SDKs included in privacy manifest (iOS)
- [ ] No unnecessary analytics SDKs

### Common SDKs to Review
- Analytics (Firebase, Mixpanel, Amplitude)
- Crash reporting (Crashlytics, Sentry)
- Advertising (AdMob, Facebook)
- Social login (Sign in with Apple, Google, Facebook)

## Platform-Specific Privacy

### macOS

#### Checklist
- [ ] App doesn't access files outside sandbox without permission
- [ ] Keychain access explained to users
- [ ] No silent background data collection
- [ ] Menu bar apps explain their persistent presence

#### Keychain Access Dialog
When accessing another app's Keychain item:
```swift
// Users will see: "[App] wants to access [Item] in your keychain"
// Prepare users in onboarding:
Text("On first launch, macOS will ask to access credentials from your Keychain. Click 'Always Allow' for permanent access.")
```

### iOS

#### App Tracking Transparency (ATT)
```swift
// Required if tracking users across apps
import AppTrackingTransparency

ATTrackingManager.requestTrackingAuthorization { status in
    // Handle response
}
```

#### Privacy Nutrition Labels
Checklist for App Store Connect:
- [ ] Data types collected documented
- [ ] Data linked to user identity marked
- [ ] Data used for tracking marked
- [ ] Third-party data collection included

## GDPR Compliance Basics

### Checklist
- [ ] Privacy policy accessible in app
- [ ] Consent obtained before data collection
- [ ] Users can access their data
- [ ] Users can request data deletion
- [ ] Data processing purposes documented

### Privacy Policy Link
```swift
Link("Privacy Policy", destination: URL(string: "https://yourapp.com/privacy")!)
```

## Search Patterns

```
// Find potential privacy issues
Grep: "CLLocationManager|locationManager"
Grep: "ATTrackingManager|advertisingIdentifier"
Grep: "UNUserNotificationCenter|requestAuthorization"
Grep: "PHPhotoLibrary|AVCaptureDevice"
Grep: "CNContactStore|EventKit"
```

## References

- [Apple Privacy Guidelines](https://developer.apple.com/app-store/app-privacy-details/)
- [Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
