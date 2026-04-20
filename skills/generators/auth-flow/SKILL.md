---
name: auth-flow
description: Generates authentication infrastructure with Sign in with Apple, biometrics, and Keychain storage. Use when user wants to add authentication, login, or Sign in with Apple.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Auth Flow Generator

Generate a complete authentication flow with Sign in with Apple, biometric authentication (Face ID/Touch ID), and secure Keychain storage.

## When This Skill Activates

Use this skill when the user:
- Asks to "add authentication" or "add login"
- Mentions "Sign in with Apple" or "SIWA"
- Wants "Face ID login" or "biometric auth"
- Asks about "Keychain" or "secure storage"
- Mentions "user session" or "auth token"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing auth implementations
- [ ] Check for AuthenticationServices framework usage
- [ ] Verify entitlements file exists
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing auth:
```
Glob: **/*Auth*.swift, **/*Keychain*.swift
Grep: "ASAuthorizationController" or "LAContext"
```

If found, ask user:
- Replace existing implementation?
- Extend with additional methods?

### 3. Required Capabilities

**Sign in with Apple requires:**
- Add "Sign in with Apple" capability in Xcode
- Configure in App Store Connect
- Add entitlement: `com.apple.developer.applesignin`

## Configuration Questions

Ask user via AskUserQuestion:

1. **Authentication methods?** (multi-select)
   - Sign in with Apple
   - Biometrics (Face ID/Touch ID)
   - Both

2. **Session storage?**
   - Keychain (secure, persists reinstall)
   - UserDefaults (simple, cleared on reinstall)

3. **Session management?**
   - Auto-refresh tokens
   - Manual refresh
   - No token refresh needed

## Generation Process

### Step 1: Create Core Files

Generate these files:
1. `AuthenticationManager.swift` - Core auth orchestration
2. `KeychainManager.swift` - Secure storage
3. `SignInWithAppleManager.swift` - SIWA handling
4. `BiometricAuthManager.swift` - Face ID/Touch ID

### Step 2: Create SwiftUI Components

Based on configuration:
- `SignInWithAppleButton.swift` - SwiftUI button wrapper
- `AuthenticationView.swift` - Complete auth UI

### Step 3: Determine File Location

Check project structure:
- If `Sources/` exists → `Sources/Auth/`
- If `App/` exists → `App/Auth/`
- Otherwise → `Auth/`

## Entitlements Required

### Sign in with Apple
```xml
<!-- YourApp.entitlements -->
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

### Keychain Sharing (optional)
```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.yourcompany.shared</string>
</array>
```

## Info.plist Required

### Face ID Usage Description
```xml
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to securely sign in to your account</string>
```

## Output Format

After generation, provide:

### Files Created
```
Sources/Auth/
├── AuthenticationManager.swift      # Core orchestration
├── KeychainManager.swift            # Secure storage
├── SignInWithAppleManager.swift     # SIWA delegate
├── BiometricAuthManager.swift       # Face ID/Touch ID
├── AuthenticationState.swift        # Auth state model
└── Views/
    ├── SignInWithAppleButton.swift  # SwiftUI button
    └── AuthenticationView.swift     # Complete UI
```

### Integration Steps

**App Entry Point:**
```swift
@main
struct MyApp: App {
    @State private var authManager = AuthenticationManager()  // AuthenticationManager is @Observable

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
            } else {
                AuthenticationView()
            }
        }
        .environment(authManager)
    }
}
```

**Sign in with Apple Button:**
```swift
SignInWithAppleButtonView { result in
    switch result {
    case .success(let user):
        print("Signed in: \(user.id)")
    case .failure(let error):
        print("Failed: \(error)")
    }
}
```

**Biometric Auth:**
```swift
Button("Unlock with Face ID") {
    Task {
        if await BiometricAuthManager.shared.authenticate() {
            // Authenticated
        }
    }
}
```

### Required Setup

1. **Xcode Capabilities:**
   - Add "Sign in with Apple" capability
   - Enable Keychain Sharing (if needed)

2. **App Store Connect:**
   - Configure Sign in with Apple for your App ID

3. **Info.plist:**
   - Add `NSFaceIDUsageDescription`

### Testing Instructions

**Sign in with Apple:**
- Use Simulator for basic testing
- Test on device for full flow
- Use sandbox Apple ID for testing

**Biometrics:**
- Simulator: Features > Face ID > Enrolled
- Test enrolled/not enrolled states
- Test failed authentication

## References

- **auth-patterns.md** - Security best practices
- **templates/** - All template files
- Apple Docs: Authentication Services, LocalAuthentication
