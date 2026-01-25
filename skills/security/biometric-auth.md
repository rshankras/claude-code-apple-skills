# Biometric Authentication

Implementing Face ID, Touch ID, and Optic ID across Apple platforms.

## Overview

| Platform | Biometric Types |
|----------|-----------------|
| iOS | Face ID, Touch ID |
| macOS | Touch ID (on supported Macs) |
| watchOS | Wrist detection (not LAContext) |
| visionOS | Optic ID |

## Required Setup

### Info.plist

You **must** include a usage description for Face ID:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Unlock your data securely with Face ID</string>
```

Without this, the app will crash when requesting Face ID.

## LAContext Basics

### Checking Biometric Availability

```swift
import LocalAuthentication

final class BiometricAuthManager {

    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID

        var displayName: String {
            switch self {
            case .none: return "Passcode"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .opticID: return "Optic ID"
            }
        }
    }

    enum AuthError: Error {
        case biometryNotAvailable
        case biometryNotEnrolled
        case biometryLockout
        case userCancel
        case userFallback
        case systemCancel
        case authenticationFailed
        case unknown(Error)
    }

    static let shared = BiometricAuthManager()

    private let context = LAContext()

    // MARK: - Availability

    var biometricType: BiometricType {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }

    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var canUseBiometricOrPasscode: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func checkBiometricStatus() -> Result<BiometricType, AuthError> {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            return .success(biometricType)
        }

        guard let laError = error as? LAError else {
            return .failure(.unknown(error ?? NSError()))
        }

        switch laError.code {
        case .biometryNotAvailable:
            return .failure(.biometryNotAvailable)
        case .biometryNotEnrolled:
            return .failure(.biometryNotEnrolled)
        case .biometryLockout:
            return .failure(.biometryLockout)
        default:
            return .failure(.unknown(laError))
        }
    }
}
```

## Authentication Patterns

### Basic Biometric Authentication

```swift
extension BiometricAuthManager {

    /// Authenticate with biometrics only (no passcode fallback shown)
    func authenticateWithBiometrics(reason: String) async -> Result<Void, AuthError> {
        let context = LAContext()

        // Disable fallback button
        context.localizedFallbackTitle = ""

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .failure(mapError(error))
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success ? .success(()) : .failure(.authenticationFailed)
        } catch {
            return .failure(mapError(error))
        }
    }

    /// Authenticate with biometrics, falling back to device passcode
    func authenticateWithBiometricsOrPasscode(reason: String) async -> Result<Void, AuthError> {
        let context = LAContext()

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .failure(mapError(error))
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success ? .success(()) : .failure(.authenticationFailed)
        } catch {
            return .failure(mapError(error))
        }
    }

    private func mapError(_ error: Error?) -> AuthError {
        guard let laError = error as? LAError else {
            return .unknown(error ?? NSError())
        }

        switch laError.code {
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockout
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .authenticationFailed:
            return .authenticationFailed
        default:
            return .unknown(laError)
        }
    }
}
```

### Biometric-Protected Keychain Items

The most secure pattern: store data in Keychain with biometric access control.

```swift
extension KeychainManager {

    /// Save data that requires biometric authentication to access
    func saveBiometricProtected(
        _ data: Data,
        for account: String,
        requireBiometry: Bool = true
    ) throws {
        var error: Unmanaged<CFError>?

        // Create access control
        var flags: SecAccessControlCreateFlags = [.privateKeyUsage]
        if requireBiometry {
            flags.insert(.biometryCurrentSet) // Invalidates if biometry changes
        }

        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            flags,
            &error
        ) else {
            throw error!.takeRetainedValue()
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: accessControl
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Read data that requires biometric authentication
    func readBiometricProtected(account: String, prompt: String) throws -> Data {
        let context = LAContext()
        context.localizedReason = prompt

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        return data
    }
}
```

## SwiftUI Integration

### Biometric Auth View Modifier

```swift
import SwiftUI

struct BiometricLockModifier: ViewModifier {
    @State private var isUnlocked = false
    @State private var showError = false
    @State private var errorMessage = ""

    let reason: String
    let onUnlock: () -> Void

    func body(content: Content) -> some View {
        Group {
            if isUnlocked {
                content
            } else {
                lockedView
            }
        }
        .task {
            await authenticate()
        }
        .alert("Authentication Failed", isPresented: $showError) {
            Button("Try Again") {
                Task { await authenticate() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var lockedView: some View {
        VStack(spacing: 20) {
            Image(systemName: biometricIcon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Authentication Required")
                .font(.headline)

            Button("Unlock with \(biometricName)") {
                Task { await authenticate() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var biometricIcon: String {
        switch BiometricAuthManager.shared.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock"
        }
    }

    private var biometricName: String {
        BiometricAuthManager.shared.biometricType.displayName
    }

    private func authenticate() async {
        let result = await BiometricAuthManager.shared.authenticateWithBiometricsOrPasscode(reason: reason)

        await MainActor.run {
            switch result {
            case .success:
                isUnlocked = true
                onUnlock()
            case .failure(let error):
                switch error {
                case .userCancel, .systemCancel:
                    break // Don't show error for user cancellation
                default:
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

extension View {
    func biometricLock(reason: String, onUnlock: @escaping () -> Void = {}) -> some View {
        modifier(BiometricLockModifier(reason: reason, onUnlock: onUnlock))
    }
}

// Usage
struct SecureContentView: View {
    var body: some View {
        Text("Secret Content")
            .biometricLock(reason: "Access your secure notes")
    }
}
```

### Re-authentication on App Become Active

```swift
import SwiftUI

@Observable
final class AppLockManager {
    var isLocked = false
    private var backgroundTime: Date?
    private let lockTimeout: TimeInterval = 60 // Lock after 60 seconds in background

    func handleBackgroundTransition() {
        backgroundTime = Date()
    }

    func handleForegroundTransition() {
        guard let backgroundTime else { return }

        let elapsed = Date().timeIntervalSince(backgroundTime)
        if elapsed > lockTimeout {
            isLocked = true
        }
        self.backgroundTime = nil
    }
}

struct ContentView: View {
    @Environment(AppLockManager.self) private var lockManager

    var body: some View {
        Group {
            if lockManager.isLocked {
                LockScreenView()
            } else {
                MainAppView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            lockManager.handleBackgroundTransition()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            lockManager.handleForegroundTransition()
        }
    }
}
```

## Access Control Flags

### Common Patterns

| Flag | Meaning |
|------|---------|
| `.biometryAny` | Any enrolled biometric works |
| `.biometryCurrentSet` | Only current biometric enrollment (more secure) |
| `.devicePasscode` | Device passcode required |
| `.userPresence` | Biometric OR passcode |
| `.privateKeyUsage` | For Secure Enclave keys |

### ✅ Recommended Combinations

```swift
// Require current biometric (re-enrollment invalidates)
[.biometryCurrentSet]

// Biometric with passcode fallback
[.userPresence]

// Secure Enclave key with biometric protection
[.privateKeyUsage, .biometryCurrentSet]
```

### ❌ Avoid

```swift
// Too permissive - any biometric works, even if user adds new fingerprint
[.biometryAny]
```

## Error Handling Best Practices

### User-Friendly Error Messages

```swift
extension BiometricAuthManager.AuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .biometryNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometryNotEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
        case .biometryLockout:
            return "Biometric authentication is locked due to too many failed attempts. Please use your passcode."
        case .userCancel:
            return "Authentication was cancelled."
        case .userFallback:
            return "Passcode authentication requested."
        case .systemCancel:
            return "Authentication was cancelled by the system."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
```

### Handling Lockout

```swift
func handleBiometricLockout() async {
    // After lockout, user must authenticate with passcode first
    let result = await BiometricAuthManager.shared.authenticateWithBiometricsOrPasscode(
        reason: "Unlock with passcode to reset biometric"
    )

    if case .success = result {
        // Biometric is now reset, can try again
    }
}
```

## macOS Considerations

### Touch ID on Mac

```swift
#if os(macOS)
extension BiometricAuthManager {
    var hasTouchID: Bool {
        var error: NSError?
        let context = LAContext()
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate && context.biometryType == .touchID
    }
}
#endif
```

### Apple Watch Unlock (macOS)

```swift
// Check if Apple Watch can be used for authentication
let context = LAContext()
context.localizedReason = "Authenticate with Apple Watch"

// This will show Apple Watch as an option if available
try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
```

## Checklist

### Setup
- [ ] `NSFaceIDUsageDescription` in Info.plist
- [ ] Clear, user-friendly reason strings
- [ ] Biometric availability check before showing options

### Implementation
- [ ] Using `.biometryCurrentSet` for high-security items
- [ ] Proper fallback to passcode when appropriate
- [ ] Error handling for all LAError cases
- [ ] User-friendly error messages

### Security
- [ ] Keychain items with biometric access control for sensitive data
- [ ] Re-authentication after app returns from background
- [ ] No storing biometric results (always re-authenticate)
- [ ] Handling biometric lockout gracefully

### UX
- [ ] Showing appropriate biometric icon (Face ID vs Touch ID)
- [ ] Explaining why biometric is needed
- [ ] Providing alternative authentication methods
- [ ] Not forcing biometric if user prefers passcode
