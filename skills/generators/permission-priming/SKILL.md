---
name: permission-priming
description: Generates pre-permission priming screens that explain benefits before showing iOS system permission dialogs. Use when user wants to increase permission grant rates, add pre-permission screens, or explain why the app needs access.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Permission Priming Generator

Generate pre-permission priming screens — shown before iOS system permission dialogs to explain WHY the app needs access. Dramatically increases permission grant rates vs. cold-prompting users with the system alert.

## When This Skill Activates

Use this skill when the user:
- Asks to "add permission priming" or "pre-permission screen"
- Mentions "explain permissions" or "permission request screen"
- Wants to "ask for camera permission" or "notification permission"
- Asks about "location permission explanation" or "permission grant rate"
- Wants to "prime before requesting access" or "improve opt-in rates"
- Mentions "permission dialog" or "permission flow"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Existing Permission Code
Search for existing permission handling:
```
Glob: **/*Permission*.swift, **/*Authorization*.swift
Grep: "requestAuthorization" or "AVCaptureDevice" or "UNUserNotificationCenter" or "CLLocationManager" or "PHPhotoLibrary"
```

If existing permission code found:
- Ask if user wants to wrap existing calls with priming screens or replace entirely
- If wrapping, integrate priming views upstream of existing request calls

### 3. Info.plist Usage Description Strings
Search for required usage description keys:
```
Grep: "NSCameraUsageDescription" or "NSMicrophoneUsageDescription" or "NSLocationWhenInUseUsageDescription" or "NSPhotoLibraryUsageDescription" or "NSContactsUsageDescription" or "NSHealthShareUsageDescription"
```

If missing keys found for requested permissions:
- Warn user that the app will crash without the corresponding Info.plist entry
- Provide the required key and a suggested description string

## Configuration Questions

Ask user via AskUserQuestion:

1. **Which permissions to prime?** (multi-select)
   - Push Notifications
   - Camera
   - Photo Library
   - Location (When In Use)
   - Location (Always)
   - Microphone
   - Contacts
   - Health (HealthKit)
   - App Tracking Transparency (ATT)

2. **Priming style?**
   - Full-screen (dedicated view with illustration, title, benefits, CTA) — recommended
   - Alert-style (compact alert-like overlay before system prompt)
   - Inline (embedded card within existing content)

3. **Include "Not Now" option?**
   - Yes (recommended — reduces user frustration, can re-prompt later)
   - No (only "Enable" button — more aggressive)

4. **Show benefits illustration?**
   - SF Symbol (simple, matches system style)
   - Custom illustration area (placeholder for designer asset)
   - None (text only)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `PermissionType.swift` — Enum of all permission types with metadata
2. `PermissionStatus.swift` — Unified status enum wrapping platform-specific statuses
3. `PermissionManager.swift` — @Observable class that checks, requests, and opens Settings

### Step 3: Create UI Files
4. `PermissionPrimingView.swift` — Pre-permission screen with benefits and CTA
5. `PermissionStatusTracker.swift` — Monitors status changes from Settings

### Step 4: Create Modifier Files
6. `PermissionGatedModifier.swift` — ViewModifier that gates content behind permission check

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/Permissions/`
- If `App/` exists -> `App/Permissions/`
- Otherwise -> `Permissions/`

## Output Format

After generation, provide:

### Files Created
```
Permissions/
├── PermissionType.swift            # Permission enum with metadata
├── PermissionStatus.swift          # Unified status wrapper
├── PermissionManager.swift         # Check, request, open Settings
├── PermissionPrimingView.swift     # Pre-permission priming screen
├── PermissionStatusTracker.swift   # Monitor status changes
└── PermissionGatedModifier.swift   # Gate content behind permission
```

### Integration Steps

**Basic priming before system prompt:**
```swift
// Show priming screen, then request system permission on tap
PermissionPrimingView(permissionType: .notifications) {
    // User granted — proceed with feature
    startSendingNotifications()
} onDenied: {
    // User denied or tapped "Not Now"
    showLaterPrompt()
}
```

**Gate a feature behind permission:**
```swift
// Camera feature gated behind permission
CameraView()
    .permissionGated(.camera) {
        // Priming screen shown automatically if not yet authorized
    }
```

**In onboarding flow:**
```swift
struct OnboardingPermissionsView: View {
    @State private var permissionManager = PermissionManager()

    var body: some View {
        VStack(spacing: 32) {
            PermissionPrimingView(permissionType: .notifications) {
                // Move to next permission
            } onDenied: {
                // Skip, ask later
            }
        }
    }
}
```

**Check status and re-prompt after denial:**
```swift
struct SettingsView: View {
    @State private var permissionManager = PermissionManager()

    var body: some View {
        Section("Permissions") {
            ForEach(PermissionType.allCases, id: \.self) { type in
                PermissionRow(
                    type: type,
                    status: permissionManager.status(for: type),
                    onRequest: { permissionManager.openSettings() }
                )
            }
        }
    }
}
```

### Testing

```swift
@Test
func primingViewShowsBeforeSystemPrompt() async throws {
    let manager = PermissionManager()
    let status = await manager.status(for: .notifications)
    #expect(status == .notDetermined)
    // Priming view should appear before system dialog
}

@Test
func deniedPermissionDirectsToSettings() async throws {
    let manager = PermissionManager()
    // After denial, tapping "Enable" should open Settings
    let settingsURL = manager.settingsURL
    #expect(settingsURL != nil)
}

@Test
func permissionGatedModifierShowsPrimingWhenNotAuthorized() async throws {
    // ViewModifier should show priming screen when permission is .notDetermined
    // and show content when .authorized
}
```

## Common Patterns

### Prime Before First Use
Show priming screen at the natural moment the user first needs the feature, not during onboarding:
```swift
// User taps "Take Photo" -> show camera priming -> then system prompt
Button("Take Photo") {
    showCameraPriming = true
}
.sheet(isPresented: $showCameraPriming) {
    PermissionPrimingView(permissionType: .camera,
                          onGranted: { openCamera() },
                          onDenied: { showCameraPriming = false })
}
```

### Contextual Priming
Explain the benefit in context of what the user is trying to do:
```swift
PermissionPrimingView(
    permissionType: .location(.whenInUse),
    customTitle: "Find Nearby Restaurants",
    customDescription: "We use your location to show restaurants within walking distance."
) { ... }
```

### Re-Request After Denial
After denial, the system prompt cannot be shown again. Direct to Settings:
```swift
if permissionManager.status(for: .camera) == .denied {
    // Show explanation + "Open Settings" button
    PermissionDeniedView(permissionType: .camera) {
        permissionManager.openSettings()
    }
}
```

## Gotchas

- **Cannot re-show system prompt after denial.** Once the user denies a permission, iOS will never show the system dialog again. You must direct the user to Settings > Privacy to re-enable. Always handle the `.denied` state gracefully.
- **App Tracking Transparency (ATT) has special requirements.** ATT must be requested before tracking begins. The priming screen must NOT use misleading language. Apple reviews ATT implementations closely — avoid incentivizing users to allow tracking.
- **Health permissions have unique two-column UI.** HealthKit authorization uses its own system sheet with read/write toggles per data type. You cannot customize it. Your priming screen should explain which health data you need and why before presenting the HealthKit sheet.
- **Location "Always" requires progressive authorization.** You must first request `.whenInUse`, then separately request `.always`. iOS shows a follow-up prompt only after the user has used the app with When In Use access. Do not request Always upfront.
- **Provisional notifications (iOS 12+) bypass the prompt entirely.** With `.provisional`, notifications are delivered silently to Notification Center without asking. Consider whether quiet delivery is acceptable before building a priming screen.
- **Info.plist keys are mandatory.** If you call a permission API without the corresponding `NS*UsageDescription` key in Info.plist, the app will crash immediately. Always verify these keys exist.

## References

- **templates.md** — All production Swift templates for permission priming
- Related: `generators/push-notifications` — Push notification setup and handling
- Related: `generators/consent-flow` — GDPR/privacy consent flows
