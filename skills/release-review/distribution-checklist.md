# Distribution Checklist

Release and distribution review for macOS and iOS applications.

## Bundle Configuration

### Bundle Identifier

#### ✅ Good Pattern
```
com.companyname.appname
com.yourname.AppName
```

#### ❌ Anti-patterns
```
// Generic or placeholder identifiers
com.example.app
org.cocoapods.demo
com.apple.product-type.application

// Missing reverse-domain format
MyApp
app.mycompany
```

### Checklist
- [ ] Bundle identifier uses reverse-domain format
- [ ] Bundle identifier matches App Store Connect (if applicable)
- [ ] Bundle identifier is unique (not copied from template)
- [ ] Team ID configured correctly

### Search Pattern
```
Grep in project.pbxproj: "PRODUCT_BUNDLE_IDENTIFIER"
```

## Version Numbers

### Guidelines

- **Version** (CFBundleShortVersionString): User-facing, semantic versioning (1.0.0)
- **Build** (CFBundleVersion): Internal, incremented each build

#### ✅ Good Pattern
```xml
<key>CFBundleShortVersionString</key>
<string>1.2.0</string>
<key>CFBundleVersion</key>
<string>42</string>
```

### Checklist
- [ ] Version number follows semantic versioning
- [ ] Build number increments with each release
- [ ] Version matches marketing expectations
- [ ] Build number is higher than previous releases

## Info.plist

### Required Keys (Universal)

```xml
<!-- Always required -->
<key>CFBundleDisplayName</key>
<string>App Name</string>

<key>CFBundleIdentifier</key>
<string>com.company.app</string>

<key>CFBundleShortVersionString</key>
<string>1.0.0</string>

<key>CFBundleVersion</key>
<string>1</string>
```

### Permission Usage Descriptions

If your app requests permissions, these keys are **required** or App Store will reject:

```xml
<!-- Camera -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes.</string>

<!-- Photos -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo access to let you choose a profile picture.</string>

<!-- Location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby stores.</string>

<!-- Microphone -->
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice messages.</string>

<!-- Contacts -->
<key>NSContactsUsageDescription</key>
<string>We need contacts access to help you invite friends.</string>

<!-- Calendars -->
<key>NSCalendarsUsageDescription</key>
<string>We need calendar access to add event reminders.</string>
```

### Checklist
- [ ] All required Info.plist keys present
- [ ] Usage descriptions for all requested permissions
- [ ] Usage descriptions are user-friendly (not technical)
- [ ] No placeholder text in descriptions

## Code Signing

### macOS

#### Developer ID (Direct Distribution)
```
CODE_SIGN_IDENTITY = "Developer ID Application: Your Name (TEAM_ID)"
```

#### App Store
```
CODE_SIGN_IDENTITY = "Apple Distribution: Your Name (TEAM_ID)"
```

### iOS

#### Development
```
CODE_SIGN_IDENTITY = "iPhone Developer"
```

#### Distribution
```
CODE_SIGN_IDENTITY = "iPhone Distribution"
```

### Checklist
- [ ] Signing certificate valid and not expired
- [ ] Provisioning profile matches bundle ID
- [ ] Provisioning profile includes required capabilities
- [ ] Team selected in Xcode project

### Search Pattern
```
Grep in project.pbxproj: "CODE_SIGN_IDENTITY|PROVISIONING_PROFILE"
```

## App Icons

### macOS Requirements

| Size | Scale | Filename |
|------|-------|----------|
| 16x16 | 1x, 2x | icon_16x16.png, icon_16x16@2x.png |
| 32x32 | 1x, 2x | icon_32x32.png, icon_32x32@2x.png |
| 128x128 | 1x, 2x | icon_128x128.png, icon_128x128@2x.png |
| 256x256 | 1x, 2x | icon_256x256.png, icon_256x256@2x.png |
| 512x512 | 1x, 2x | icon_512x512.png, icon_512x512@2x.png |

### iOS Requirements

| Size | Usage |
|------|-------|
| 1024x1024 | App Store |
| 180x180 | iPhone @3x |
| 120x120 | iPhone @2x |
| 167x167 | iPad Pro @2x |
| 152x152 | iPad @2x |

### Checklist
- [ ] All required icon sizes present
- [ ] Icons are square with no transparency (iOS)
- [ ] Icons match brand guidelines
- [ ] No placeholder or default icons

## Platform-Specific: macOS

### Notarization

Required for apps distributed outside App Store (macOS 10.15+).

#### Prerequisites
- [ ] Hardened Runtime enabled
- [ ] Developer ID certificate
- [ ] App-specific password for notarytool

#### Notarization Script
```bash
#!/bin/bash
APP_PATH="$1"
BUNDLE_ID="com.company.app"
APPLE_ID="developer@email.com"
TEAM_ID="XXXXXXXXXX"

# Create ZIP
ditto -c -k --keepParent "$APP_PATH" "app.zip"

# Submit for notarization
xcrun notarytool submit "app.zip" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "@keychain:AC_PASSWORD" \
    --wait

# Staple ticket
xcrun stapler staple "$APP_PATH"
```

#### Checklist
- [ ] Hardened Runtime enabled
- [ ] All binaries signed with Developer ID
- [ ] App submitted to notarization service
- [ ] Notarization ticket stapled to app
- [ ] Gatekeeper accepts app (`spctl -a -v App.app`)

### DMG Creation

For professional distribution:

```bash
# Create DMG with Applications symlink
hdiutil create -volname "AppName" \
    -srcfolder build/ \
    -ov -format UDZO \
    AppName.dmg
```

#### Checklist
- [ ] DMG contains app and Applications alias
- [ ] DMG is signed and notarized
- [ ] DMG opens cleanly with drag-to-install
- [ ] Background image (optional but professional)

### Sandbox Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <!-- Required for sandboxing -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- Network access -->
    <key>com.apple.security.network.client</key>
    <true/>

    <!-- User-selected files -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

#### Checklist
- [ ] Only necessary entitlements requested
- [ ] Each entitlement justified
- [ ] Temporary exceptions have migration plan

## Platform-Specific: iOS

### App Store Connect

#### Required Information
- [ ] App name (30 characters max)
- [ ] Subtitle (30 characters max)
- [ ] Privacy Policy URL
- [ ] Support URL
- [ ] Marketing URL (optional)
- [ ] App category selected
- [ ] Age rating questionnaire completed

#### Screenshots
| Device | Size | Required |
|--------|------|----------|
| iPhone 6.7" | 1290 x 2796 | Yes |
| iPhone 6.5" | 1242 x 2688 | Yes |
| iPhone 5.5" | 1242 x 2208 | Optional |
| iPad Pro 12.9" | 2048 x 2732 | If universal |

#### Checklist
- [ ] All required screenshots uploaded
- [ ] Screenshots show actual app (not mockups)
- [ ] App preview video (optional but recommended)
- [ ] Promotional text (170 characters)
- [ ] Description (4000 characters max)
- [ ] Keywords (100 characters max)

### TestFlight

#### Checklist
- [ ] Beta App Description provided
- [ ] What to Test notes included
- [ ] Test Information contact email
- [ ] Beta App Review Information (if using restricted features)
- [ ] External testers invited (if needed)

### Export Compliance

If your app uses encryption:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>  <!-- or true if using custom encryption -->
```

#### Checklist
- [ ] Export compliance question answered in App Store Connect
- [ ] ITSAppUsesNonExemptEncryption key set correctly
- [ ] Encryption registration filed (if required)

### In-App Purchases (if applicable)

#### Checklist
- [ ] Products created in App Store Connect
- [ ] Products submitted for review
- [ ] Restore purchases implemented
- [ ] Receipt validation implemented
- [ ] Sandbox testing completed

## Launch Preparation

### Final Checklist

#### Universal
- [ ] All debug code removed
- [ ] No test/placeholder content
- [ ] Crash reporting configured
- [ ] Analytics configured (if any)
- [ ] Version/build numbers correct

#### macOS
- [ ] App launches correctly
- [ ] Menu bar items work
- [ ] Preferences accessible (Cmd+,)
- [ ] About window shows correct info
- [ ] App quits cleanly (Cmd+Q)

#### iOS
- [ ] App launches on all supported devices
- [ ] Launch screen matches initial UI
- [ ] All orientations work (if supported)
- [ ] Background modes work correctly
- [ ] Push notifications work (if applicable)

## References

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
- [Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
