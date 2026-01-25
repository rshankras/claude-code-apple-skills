# Platform-Specific Security

Security considerations unique to iOS, macOS, and watchOS.

## iOS Security

### Data Protection Classes

iOS encrypts files using the device passcode. Choose the right class:

| Class | Constant | Accessible When |
|-------|----------|-----------------|
| Complete Protection | `.complete` | Device unlocked only |
| Protected Unless Open | `.completeUnlessOpen` | Can finish write when locked |
| Protected Until First Auth | `.completeUntilFirstUserAuthentication` | After first unlock |
| No Protection | `.none` | Always (avoid for sensitive data) |

```swift
// Set file protection
let sensitiveURL = documentsURL.appendingPathComponent("secrets.json")
try sensitiveData.write(to: sensitiveURL, options: [.completeFileProtection])

// Core Data with protection
let storeDescription = NSPersistentStoreDescription()
storeDescription.setOption(
    FileProtectionType.complete as NSObject,
    forKey: NSPersistentStoreFileProtectionKey
)
```

### App Groups and Keychain Sharing

Sharing data between apps and extensions requires careful security:

```swift
// Keychain sharing between app and extension
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccessGroup as String: "TEAM_ID.com.company.shared",
    kSecAttrService as String: "SharedCredentials",
    kSecAttrAccount as String: "user_token",
    kSecValueData as String: tokenData,
    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
]
```

**Security considerations:**
- [ ] Only share what's necessary between app and extensions
- [ ] Use `ThisDeviceOnly` accessibility for shared items
- [ ] Validate data received from shared containers
- [ ] Don't store highly sensitive data in App Groups (use Keychain)

### Jailbreak Detection

For high-security apps (banking, enterprise):

```swift
func isDeviceCompromised() -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    // Check for common jailbreak artifacts
    let suspiciousPaths = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt/"
    ]

    for path in suspiciousPaths {
        if FileManager.default.fileExists(atPath: path) {
            return true
        }
    }

    // Check if app can write outside sandbox
    let testPath = "/private/jailbreak_test.txt"
    do {
        try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
        try FileManager.default.removeItem(atPath: testPath)
        return true
    } catch {
        // Expected - can't write outside sandbox
    }

    // Check for suspicious URL schemes
    if let url = URL(string: "cydia://package/com.example.package"),
       UIApplication.shared.canOpenURL(url) {
        return true
    }

    return false
    #endif
}
```

**Warning:** Determined attackers can bypass jailbreak detection. Use as defense-in-depth, not sole protection.

### iOS Background Security

```swift
// Blur sensitive content when app enters background
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private var blurView: UIVisualEffectView?

    func sceneWillResignActive(_ scene: UIScene) {
        guard let window = (scene as? UIWindowScene)?.windows.first else { return }

        let blur = UIBlurEffect(style: .regular)
        blurView = UIVisualEffectView(effect: blur)
        blurView?.frame = window.bounds
        blurView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(blurView!)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        blurView?.removeFromSuperview()
        blurView = nil
    }
}
```

### Export Compliance

If your app uses encryption, declare it in App Store Connect:

| Encryption Use | Export Compliance |
|----------------|-------------------|
| HTTPS only (URLSession) | Exempt |
| Standard iOS encryption APIs | Exempt (usually) |
| Custom cryptography | May require documentation |
| Strong encryption for non-exempt purposes | ERN required |

## macOS Security

### Sandboxing

macOS apps should be sandboxed when possible:

```xml
<!-- Entitlements.plist -->
<key>com.apple.security.app-sandbox</key>
<true/>

<!-- Only request what you need -->
<key>com.apple.security.network.client</key>
<true/>

<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

**Sandbox entitlements to audit:**

| Entitlement | Risk Level | Justification Needed |
|-------------|------------|----------------------|
| `files.user-selected.read-write` | Low | User grants access |
| `files.downloads.read-write` | Medium | Document why |
| `network.client` | Low | Common for apps |
| `network.server` | Medium | Document why |
| `files.all` | High | Strong justification |
| `temporary-exception.*` | High | Migration plan needed |

### Hardened Runtime

Required for notarization:

```xml
<!-- Entitlements.plist -->
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<false/>

<key>com.apple.security.cs.allow-jit</key>
<false/>

<key>com.apple.security.cs.disable-library-validation</key>
<false/>
```

**Avoid these unless absolutely necessary:**
- `allow-unsigned-executable-memory` - JIT compilers only
- `disable-library-validation` - Loading third-party plugins
- `allow-dyld-environment-variables` - Rarely needed

### XPC Service Security

Secure helper processes with XPC:

```swift
// In XPC service
import Foundation

@objc protocol SecureServiceProtocol {
    func performSensitiveOperation(completion: @escaping (Bool, Error?) -> Void)
}

class SecureService: NSObject, SecureServiceProtocol {

    func performSensitiveOperation(completion: @escaping (Bool, Error?) -> Void) {
        // Validate the calling app
        guard validateCaller() else {
            completion(false, ServiceError.unauthorized)
            return
        }

        // Perform operation
        completion(true, nil)
    }

    private func validateCaller() -> Bool {
        // Check code signature of calling process
        // Implementation depends on your security requirements
        return true
    }
}
```

### Keychain Access on macOS

macOS Keychain has different behavior:

```swift
// macOS may prompt user for Keychain access
// Use kSecUseDataProtectionKeychain for iOS-like behavior (macOS 10.15+)
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account,
    kSecValueData as String: data,
    kSecUseDataProtectionKeychain as String: true  // iOS-compatible keychain
]
```

### Code Signing Validation

Validate code signatures of helper tools:

```swift
import Security

func validateCodeSignature(at url: URL, expectedTeamID: String) -> Bool {
    var staticCode: SecStaticCode?
    let status = SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode)

    guard status == errSecSuccess, let code = staticCode else {
        return false
    }

    var requirement: SecRequirement?
    let requirementString = "anchor apple generic and identifier \"com.company.helper\" and certificate leaf[subject.OU] = \"\(expectedTeamID)\""

    guard SecRequirementCreateWithString(requirementString as CFString, [], &requirement) == errSecSuccess,
          let req = requirement else {
        return false
    }

    return SecStaticCodeCheckValidity(code, [], req) == errSecSuccess
}
```

## watchOS Security

### HealthKit Data Protection

Health data is extremely sensitive:

```swift
import HealthKit

let healthStore = HKHealthStore()

// Request only what you need
let readTypes: Set<HKObjectType> = [
    HKObjectType.quantityType(forIdentifier: .heartRate)!
]

healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
    // Handle authorization
}

// Never log health data
// Never transmit without user consent
// Always explain why health data is needed
```

### Watch Connectivity Security

Data synced between iPhone and Watch:

```swift
import WatchConnectivity

// Sensitive data should be transferred securely
func sendCredentialsToWatch(_ credentials: Credentials) {
    guard WCSession.default.isReachable else { return }

    // Encrypt before sending
    let encryptedData = try? encrypt(credentials.encoded())

    WCSession.default.sendMessageData(encryptedData ?? Data(), replyHandler: nil) { error in
        print("Failed to send: \(error)")
    }
}
```

**Security considerations:**
- [ ] Encrypt sensitive data before Watch Connectivity transfer
- [ ] Use `transferUserInfo` for guaranteed delivery of sensitive data
- [ ] Don't store plaintext credentials on Watch
- [ ] Consider if Watch really needs sensitive data

### watchOS Keychain

watchOS has its own Keychain:

```swift
// Keychain items are NOT automatically shared with iPhone
// Use Watch Connectivity to sync credentials if needed

let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.app.watch",
    kSecAttrAccount as String: "token",
    kSecValueData as String: tokenData,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]
```

### Wrist Detection

Watch locks when removed from wrist:

```swift
import WatchKit

// Check if wrist detection is enabled
if WKInterfaceDevice.current().wristLocation == .left ||
   WKInterfaceDevice.current().wristLocation == .right {
    // Wrist detection is working
}

// For sensitive operations, verify device is on wrist
// Note: This is handled automatically by watchOS for Keychain access
```

## Cross-Platform Considerations

### Keychain Accessibility Comparison

| Accessibility | iOS | macOS | watchOS |
|--------------|-----|-------|---------|
| `WhenUnlocked` | Unlocked | Login session | On wrist |
| `AfterFirstUnlock` | After first unlock | After login | After unlock |
| `ThisDeviceOnly` | Not in backup | Not synced | Watch only |

### Shared Keychain Between Devices

iCloud Keychain syncs across devices:

```swift
// To prevent iCloud sync, use ThisDeviceOnly variants
kSecAttrAccessibleWhenUnlockedThisDeviceOnly

// Or explicitly disable sync
kSecAttrSynchronizable as String: false
```

### Platform Detection for Security Features

```swift
var securityCapabilities: [String] {
    var capabilities: [String] = []

    #if os(iOS)
    capabilities.append("Data Protection")
    if SecureEnclave.isAvailable {
        capabilities.append("Secure Enclave")
    }
    #endif

    #if os(macOS)
    capabilities.append("Hardened Runtime")
    capabilities.append("Sandbox")
    #endif

    #if os(watchOS)
    capabilities.append("Wrist Detection")
    #endif

    return capabilities
}
```

## Checklist by Platform

### iOS
- [ ] Appropriate Data Protection class for files
- [ ] Keychain with `ThisDeviceOnly` for sensitive data
- [ ] Content blurred when app backgrounds
- [ ] Jailbreak detection for high-security apps
- [ ] Export compliance declared correctly
- [ ] App Groups used securely

### macOS
- [ ] Sandbox enabled with minimal entitlements
- [ ] Hardened Runtime enabled
- [ ] No temporary exception entitlements (or migration plan)
- [ ] XPC services validated
- [ ] Helper tools code-signed and validated
- [ ] Notarization configured

### watchOS
- [ ] HealthKit data handled with care
- [ ] Watch Connectivity data encrypted
- [ ] Minimal data stored on Watch
- [ ] Keychain used for credentials
- [ ] Sensitive operations respect wrist detection
