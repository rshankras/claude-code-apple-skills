---
name: privacy-manifests
description: Privacy manifest (PrivacyInfo.xcprivacy) implementation including required reason APIs, tracking domains, third-party SDK declarations, and App Tracking Transparency. Use when preparing apps for App Store privacy requirements.
allowed-tools: [Read, Glob, Grep]
---

# Privacy Manifests

Advisory skill for implementing Apple's privacy manifest requirements. Privacy manifests (PrivacyInfo.xcprivacy) became mandatory for App Store submissions in Spring 2024. This skill covers the manifest file format, required reason APIs, tracking declarations, third-party SDK privacy, and App Tracking Transparency.

## When This Skill Activates

Use this skill when the user:
- Asks about "privacy manifest" or "PrivacyInfo.xcprivacy"
- Mentions "required reason API" or App Store privacy rejection
- Needs to declare "tracking domains" or "NSPrivacyTracking"
- Asks about "App Tracking Transparency" or ATT
- Wants to audit third-party SDK privacy declarations
- Is preparing an app for App Store submission and mentions privacy
- Gets an App Store Connect warning about missing privacy manifests
- Asks about "privacy nutrition labels" or App Store privacy details

## Decision Tree

| Problem | Section |
|---------|---------|
| Creating PrivacyInfo.xcprivacy from scratch | Privacy Manifest File Format + Required Reason APIs |
| App Store rejection about required reason APIs | Required Reason APIs (match APIs in your code) |
| Declaring tracking domains | Tracking Domains and NSPrivacyTracking |
| Third-party SDK privacy | Third-Party SDK Declarations |
| Implementing ATT | App Tracking Transparency |
| Filling out App Store privacy labels | Privacy Nutrition Labels |
| Generating Xcode report | Xcode Privacy Report |

## Review Process

### 1. Scan the Project

```bash
Glob: **/PrivacyInfo.xcprivacy
Grep: "NSPrivacyAccessedAPITypes|NSPrivacyTracking|NSPrivacyTrackingDomains"
Grep: "NSFileCreationDate|NSFileModificationDate|NSURLCreationDateKey"
Grep: "systemUptime|ProcessInfo.*processInfo"
Grep: "volumeAvailableCapacity|URLResourceKey.*volume"
Grep: "UserDefaults"
Grep: "activeInputModes|UITextInputMode"
Grep: "ATTrackingManager|requestTrackingAuthorization"
```

### 2. Determine What Is Missing and Apply Fixes

Check: Does PrivacyInfo.xcprivacy exist? Are all required reason APIs declared? Is NSPrivacyTracking correct? Are tracking domains listed? Do third-party SDKs have their own manifests? Use the sections below to generate correct entries.

---

## Privacy Manifest File Format

The privacy manifest is a property list named `PrivacyInfo.xcprivacy`. Add it via File > New > File > App Privacy in Xcode. Four required top-level keys:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array/>
</dict>
</plist>
```

### Where to Place the File

- **App targets**: Add PrivacyInfo.xcprivacy to the root of the app bundle. In Xcode, ensure it is included in the target's "Copy Bundle Resources" build phase.
- **Frameworks/SDKs**: Place PrivacyInfo.xcprivacy in the root of the framework bundle.
- **Swift packages**: Place PrivacyInfo.xcprivacy in the package's resource bundle and declare it in Package.swift:

```swift
// Package.swift
.target(
    name: "MyLibrary",
    resources: [
        .copy("PrivacyInfo.xcprivacy")
    ]
)
```

---

## Required Reason APIs

Apple requires you to declare why your app uses certain system APIs. You must include at least one valid reason code for each API category your app uses.

### File Timestamp APIs (NSPrivacyAccessedAPICategoryFileTimestamp)

APIs that access file creation or modification dates.

| Reason Code | Description |
|-------------|-------------|
| DDA9.1 | Display file timestamps to the user |
| C617.1 | Access timestamps inside the app container, app group container, or CloudKit container |
| 3B52.1 | Access timestamps of files or directories the user specifically granted access to (document picker, drag and drop) |
| 0A2A.1 | Access timestamps for files managed by the app itself (third-party SDK only) |

Common triggers: `NSFileCreationDate`, `NSFileModificationDate`, `NSURLContentModificationDateKey`, `NSURLCreationDateKey`, `getattrlist`, `stat`, `fstat`.

### System Boot Time APIs (NSPrivacyAccessedAPICategorySystemBootTime)

APIs that read how long the system has been running.

| Reason Code | Description |
|-------------|-------------|
| 35F9.1 | Measure elapsed time between events within the app |
| 8FFB.1 | Calculate absolute timestamps for events (e.g., events that occurred before app launch) |
| 3D61.1 | Access system boot time for the purposes of user-facing functionality |

Common triggers: `systemUptime`, `ProcessInfo.processInfo.systemUptime`, `mach_absolute_time`, `clock_gettime(CLOCK_MONOTONIC)`.

### Disk Space APIs (NSPrivacyAccessedAPICategoryDiskSpace)

APIs that query available or total disk space.

| Reason Code | Description |
|-------------|-------------|
| E174.1 | Display disk space to the user |
| 85F4.1 | Check whether there is sufficient disk space to write files |
| AB6B.1 | Query disk space for the app's own functionality, do not send off device |
| 7D9E.1 | Query disk space for the app's own functionality, results sent off device (e.g., analytics) |

Common triggers: `volumeAvailableCapacityKey`, `volumeAvailableCapacityForImportantUsageKey`, `volumeAvailableCapacityForOpportunisticUsageKey`, `volumeTotalCapacityKey`, `statfs`, `statvfs`.

### User Defaults APIs (NSPrivacyAccessedAPICategoryUserDefaults)

APIs that read or write to UserDefaults.

| Reason Code | Description |
|-------------|-------------|
| CA92.1 | Read/write data accessible only to the app itself |
| 1C8F.1 | Read/write data accessible to app groups (shared UserDefaults) |
| C56D.1 | Read/write data from a third-party SDK for the SDK's own functionality |
| AC6B.1 | Read data from UserDefaults to retrieve a configuration set by an MDM (managed device) |

Common triggers: `UserDefaults`, `NSUserDefaults`, `standardUserDefaults`.

### Active Keyboards API (NSPrivacyAccessedAPICategoryActiveKeyboards)

APIs that enumerate installed keyboards.

| Reason Code | Description |
|-------------|-------------|
| 3EC4.1 | Customize the app's UI based on active keyboards (e.g., supporting specific languages) |
| 54BD.1 | A custom keyboard app accessing active keyboards to implement its functionality |

Common triggers: `UITextInputMode.activeInputModes`, `activeInputModes`.

### Declaring Required Reason APIs in the Manifest

Each entry has the category identifier and an array of reason codes. See "Common Patterns" below for a full XML example.

---

## Tracking Domains and NSPrivacyTracking

`NSPrivacyTracking` declares whether your app tracks users. Apple defines tracking as: linking user/device data from your app with data from other companies' apps, websites, or offline properties for advertising, or sharing data with data brokers.

Apple does **not** consider these to be tracking: on-device-only data linking, fraud detection, security, or compliance.

If NSPrivacyTracking is true:
- You must implement App Tracking Transparency (ATT) before any tracking occurs
- List all tracking domains in `NSPrivacyTrackingDomains` (the system blocks them until ATT is granted)

```xml
<key>NSPrivacyTracking</key>
<true/>
<key>NSPrivacyTrackingDomains</key>
<array>
    <string>analytics.example.com</string>
    <string>tracker.adnetwork.com</string>
</array>
```

If your app does not track users, set NSPrivacyTracking to false and leave the domains array empty.

---

## Third-Party SDK Declarations

### SDK Privacy Manifests

Starting Spring 2024, apps that include commonly used third-party SDKs must ensure those SDKs provide their own PrivacyInfo.xcprivacy files. Apple publishes a list of SDKs that require privacy manifests and signatures, including Alamofire, FBSDKCoreKit, Firebase, Google Analytics, Kingfisher, Lottie, Realm, SDWebImage, and many others. See [Apple's full list](https://developer.apple.com/support/third-party-SDK-requirements/).

### SDK Signatures

Third-party XCFrameworks should be signed by their developer. Prefer SDKs distributed through Swift Package Manager (signatures verified automatically). For XCFrameworks, verify the signature matches the expected developer.

### Auditing Third-Party SDKs

```bash
Glob: **/Pods/**/PrivacyInfo.xcprivacy
Glob: **/.build/**/PrivacyInfo.xcprivacy
Glob: **/Carthage/**/PrivacyInfo.xcprivacy
Grep: "pod '|.package(url:"
```

If a third-party SDK lacks a privacy manifest and uses required reason APIs, contact the SDK maintainer. As a temporary workaround, declare the SDK's API usage in your app's manifest, but this is not a long-term solution.

---

## App Tracking Transparency

### When ATT Is Required

You must present the ATT prompt if:
- NSPrivacyTracking is true in your privacy manifest
- Your app links user data with third-party data for advertising
- You use advertising identifiers (IDFA) for tracking purposes

You do not need ATT for:
- First-party analytics that stay on-device or on your own servers without linking to third-party data
- SKAdNetwork attribution (privacy-preserving, no user-level data)
- Fraud detection or security purposes

### Implementation

Request permission after the app becomes active (not during app launch):

```swift
import AppTrackingTransparency

func requestTrackingPermission() {
    ATTrackingManager.requestTrackingAuthorization { status in
        switch status {
        case .authorized:
            // IDFA available via ASIdentifierManager.shared().advertisingIdentifier
            break
        case .denied, .restricted:
            // Do not track
            break
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
```

### Info.plist Requirement

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use this identifier to show you relevant ads and measure ad performance.</string>
```

### SKAdNetwork for Attribution

SKAdNetwork provides privacy-preserving install attribution without user-level data. It does not require ATT permission. Register ad network identifiers in Info.plist:

```xml
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>example123.skadnetwork</string>
    </dict>
</array>
```

---

## Privacy Nutrition Labels

The privacy manifest feeds into the App Store privacy labels ("nutrition labels") displayed on your app's product page. The connection works as follows:

| Manifest Key | App Store Privacy Label |
|-------------|-------------------------|
| NSPrivacyCollectedDataTypes | "Data Used to Track You" and "Data Linked to You" sections |
| NSPrivacyTracking | Determines if "Data Used to Track You" section appears |
| NSPrivacyAccessedAPITypes | Not directly shown, but required for submission |

### NSPrivacyCollectedDataTypes Format

Each entry declares: data type, whether it is linked to user identity, whether it is used for tracking, and purposes.

```xml
<key>NSPrivacyCollectedDataTypes</key>
<array>
    <dict>
        <key>NSPrivacyCollectedDataType</key>
        <string>NSPrivacyCollectedDataTypeEmailAddress</string>
        <key>NSPrivacyCollectedDataTypeLinked</key>  <!-- linked to user identity? -->
        <true/>
        <key>NSPrivacyCollectedDataTypeTracking</key>  <!-- used for tracking? -->
        <false/>
        <key>NSPrivacyCollectedDataTypePurposes</key>
        <array>
            <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
        </array>
    </dict>
</array>
```

Common data types: `EmailAddress`, `Name`, `PhoneNumber`, `Location`, `DeviceID`, `CrashData`, `PerformanceData`, `ProductInteraction`, `PurchaseHistory` (prefix each with `NSPrivacyCollectedDataType`).

Common purposes: `AppFunctionality`, `Analytics`, `ThirdPartyAdvertising`, `ProductPersonalization` (prefix each with `NSPrivacyCollectedDataTypePurpose`).

The App Store privacy label must match your manifest declarations. Inconsistencies trigger review delays or rejections.

---

## Xcode Privacy Report

Generate a consolidated report via Product > Generate Privacy Report (or from the Organizer after archiving). Xcode produces a PDF listing all privacy manifest entries from the app and every embedded framework/SDK. Use this to verify all required reason APIs are declared, confirm third-party SDKs include their own manifests, and cross-check collected data types before filling out App Store Connect privacy labels.

---

## Top Mistakes

1. **Missing PrivacyInfo.xcprivacy entirely** -- Every App Store submission requires a privacy manifest. Without one, expect a warning or rejection.

2. **Using UserDefaults without declaring it** -- Almost every app uses UserDefaults. Declare `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`.
   - ❌ `UserDefaults.standard.set(true, forKey: "onboardingComplete")` with no manifest entry
   - ✅ Add CA92.1 declaration for data accessible only to the app

3. **Wrong reason code** -- Each code has a specific allowed use. Using DDA9.1 (display to user) when you never show timestamps in the UI will cause rejection. Use C617.1 for app container access instead.

4. **Forgetting third-party SDK manifests** -- Your app's manifest does not cover SDKs. Each must provide its own. SDKs on Apple's list without manifests will flag your submission.

5. **NSPrivacyTracking true without ATT** -- If you declare tracking, you must implement the ATT prompt before any tracking occurs. Missing this causes rejection.

6. **Stale privacy nutrition labels** -- After updating your manifest, also update the App Store Connect privacy labels. Inconsistencies trigger review issues.

---

## Review Checklist

- [ ] PrivacyInfo.xcprivacy exists in the app target's bundle resources
- [ ] NSPrivacyTracking set correctly (true only if the app tracks users)
- [ ] NSPrivacyTrackingDomains lists all tracking domains (if tracking is true)
- [ ] All required reason APIs declared with valid reason codes (file timestamps, boot time, disk space, UserDefaults, active keyboards)
- [ ] Reason codes match actual API usage (not just any valid code)
- [ ] NSPrivacyCollectedDataTypes lists all collected data
- [ ] Third-party SDKs include their own PrivacyInfo.xcprivacy and are signed
- [ ] ATT prompt implemented if NSPrivacyTracking is true
- [ ] NSUserTrackingUsageDescription in Info.plist if ATT is used
- [ ] App Store Connect privacy labels match manifest declarations
- [ ] Xcode privacy report generated and reviewed (Product > Generate Privacy Report)
- [ ] Swift packages declare PrivacyInfo.xcprivacy in their resource bundle

## Common Patterns

### Typical App (No Tracking)

Most apps need at minimum UserDefaults declared. Start from the minimal manifest structure above and populate `NSPrivacyAccessedAPITypes`:

```xml
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>CA92.1</string>
        </array>
    </dict>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>C617.1</string>
        </array>
    </dict>
</array>
```

### App with Tracking and Ad Attribution

Add to the template above: set `NSPrivacyTracking` to `true`, list tracking domains, add `NSPrivacyCollectedDataTypes` entries (see "Privacy Nutrition Labels" for format), implement ATT, and add `NSPrivacyAccessedAPICategoryDiskSpace` with reason `7D9E.1` if sending disk metrics off-device.

---

## References

- [Apple: Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Apple: Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)
- [Apple: Third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/)
- [Apple: App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
- [Apple: SKAdNetwork](https://developer.apple.com/documentation/storekit/skadnetwork)
- [Apple: App privacy details on the App Store](https://developer.apple.com/app-store/app-privacy-details/)
