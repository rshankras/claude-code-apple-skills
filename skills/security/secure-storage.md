# Secure Storage

Patterns for securely storing sensitive data on Apple platforms.

## Storage Decision Matrix

| Data Type | Recommended Storage | Data Protection Class |
|-----------|--------------------|-----------------------|
| API tokens, passwords | Keychain | N/A (Keychain handles) |
| Encryption keys | Keychain + Secure Enclave | N/A |
| User preferences (non-sensitive) | UserDefaults | N/A |
| Sensitive files | Files + Data Protection | `.complete` |
| Cached sensitive data | Files + Data Protection | `.completeUnlessOpen` |
| Health/financial data | Keychain or encrypted files | `.complete` |

## Keychain

### Basic Keychain Operations

#### ✅ Secure Pattern: KeychainManager

```swift
import Foundation
import Security

enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case unexpectedStatus(OSStatus)
    case invalidData
}

final class KeychainManager {
    static let shared = KeychainManager()

    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.app.keychain") {
        self.service = service
    }

    // MARK: - Save

    func save(_ data: Data, for account: String, accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try update(data, for: account)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func save(_ string: String, for account: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, for: account)
    }

    // MARK: - Read

    func read(account: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
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

    func readString(account: String) throws -> String {
        let data = try read(account: account)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }

    // MARK: - Update

    private func update(_ data: Data, for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Delete

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
```

### Keychain Accessibility Options

| Constant | When Accessible | Survives Backup |
|----------|-----------------|-----------------|
| `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | Device unlocked | No (recommended) |
| `kSecAttrAccessibleWhenUnlocked` | Device unlocked | Yes |
| `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` | After first unlock | No |
| `kSecAttrAccessibleAfterFirstUnlock` | After first unlock | Yes |
| `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` | Passcode set + unlocked | No |

#### ✅ Recommended for Most Cases
```swift
kSecAttrAccessibleWhenUnlockedThisDeviceOnly
```
- Only accessible when device is unlocked
- Not included in backups (device-specific)
- Good balance of security and usability

#### ✅ For Background Operations
```swift
kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
```
- Accessible after device unlocked once since boot
- Needed for background refresh, push notifications
- Still device-specific

### ❌ Anti-patterns

```swift
// NEVER store sensitive data in UserDefaults
UserDefaults.standard.set(password, forKey: "password")
UserDefaults.standard.set(apiToken, forKey: "token")

// NEVER hardcode secrets
let apiKey = "sk-ant-api03-xxxxx"
private let secret = "my-secret-key"

// NEVER store in plain text files
try password.write(to: credentialsURL, atomically: true, encoding: .utf8)

// NEVER use kSecAttrAccessibleAlways (deprecated and insecure)
kSecAttrAccessible as String: kSecAttrAccessibleAlways
```

## Data Protection

iOS encrypts files using Data Protection classes. Set the appropriate class based on when data needs to be accessible.

### Data Protection Classes

| Class | File Accessible | Use Case |
|-------|-----------------|----------|
| `.complete` | Only when unlocked | Most sensitive data |
| `.completeUnlessOpen` | Can finish writes when locked | Active downloads |
| `.completeUntilFirstUserAuthentication` | After first unlock | Background operations |
| `.none` | Always | Non-sensitive cached data |

### Setting Data Protection on Files

```swift
import Foundation

// When creating a file
func writeSecureFile(data: Data, to url: URL) throws {
    try data.write(to: url, options: [.completeFileProtection])
}

// For existing files
func setFileProtection(for url: URL) throws {
    try FileManager.default.setAttributes(
        [.protectionKey: FileProtectionType.complete],
        ofItemAtPath: url.path
    )
}

// Check current protection
func checkProtection(for url: URL) -> FileProtectionType? {
    let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
    return attributes?[.protectionKey] as? FileProtectionType
}
```

### Data Protection in Info.plist

Set default protection for all app files:

```xml
<key>NSFileProtectionComplete</key>
<true/>
```

### Core Data with Data Protection

```swift
let container = NSPersistentContainer(name: "Model")

// Set protection on store file
let storeURL = container.persistentStoreDescriptions.first?.url
if let url = storeURL {
    try? FileManager.default.setAttributes(
        [.protectionKey: FileProtectionType.complete],
        ofItemAtPath: url.path
    )
}
```

## Secure Enclave

The Secure Enclave is a hardware security module for cryptographic key operations. Keys never leave the Secure Enclave.

### When to Use Secure Enclave

- Signing operations (authentication tokens)
- Key agreement (establishing shared secrets)
- Protecting high-value encryption keys

### Creating Secure Enclave Keys

```swift
import Security
import CryptoKit

enum SecureEnclaveError: Error {
    case notAvailable
    case keyGenerationFailed(OSStatus)
    case signingFailed
}

final class SecureEnclaveManager {

    static let shared = SecureEnclaveManager()

    private let tag = "com.app.secureenclave.signing"

    var isAvailable: Bool {
        SecureEnclave.isAvailable
    }

    // MARK: - Key Management

    func createKey() throws -> SecKey {
        guard isAvailable else {
            throw SecureEnclaveError.notAvailable
        }

        // Delete existing key if present
        deleteKey()

        var error: Unmanaged<CFError>?

        // Access control: require biometric or passcode
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryCurrentSet],
            &error
        ) else {
            throw error!.takeRetainedValue()
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
                kSecAttrAccessControl as String: accessControl
            ]
        ]

        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue()
        }

        return privateKey
    }

    func getKey() -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag.data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return (result as! SecKey)
    }

    func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag.data(using: .utf8)!
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Signing

    func sign(data: Data, with key: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?

        guard let signature = SecKeyCreateSignature(
            key,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            &error
        ) else {
            throw error!.takeRetainedValue()
        }

        return signature as Data
    }

    // MARK: - Verification

    func verify(signature: Data, for data: Data, with key: SecKey) -> Bool {
        guard let publicKey = SecKeyCopyPublicKey(key) else {
            return false
        }

        var error: Unmanaged<CFError>?

        return SecKeyVerifySignature(
            publicKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            signature as CFData,
            &error
        )
    }
}
```

### CryptoKit with Secure Enclave (Simpler API)

```swift
import CryptoKit

// Check availability
guard SecureEnclave.isAvailable else {
    // Fall back to software key
    return
}

// Create key with biometric protection
let key = try SecureEnclave.P256.Signing.PrivateKey(
    accessControl: SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        [.privateKeyUsage, .biometryCurrentSet],
        nil
    )!
)

// Sign data
let dataToSign = "Important message".data(using: .utf8)!
let signature = try key.signature(for: dataToSign)

// Verify
let isValid = key.publicKey.isValidSignature(signature, for: dataToSign)
```

## Clearing Sensitive Data

### Clear Memory After Use

```swift
// For sensitive strings, overwrite memory
func clearSensitiveString(_ string: inout String) {
    string = String(repeating: "\0", count: string.count)
    string = ""
}

// For Data
func clearSensitiveData(_ data: inout Data) {
    data.resetBytes(in: 0..<data.count)
    data = Data()
}

// Use pattern
var password = "secret"
defer { clearSensitiveString(&password) }
// Use password...
```

### Clear on Logout

```swift
func logout() {
    // Clear Keychain
    try? KeychainManager.shared.deleteAll()

    // Clear cached files
    let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("sensitive"))

    // Clear in-memory state
    currentUser = nil
    authToken = nil
}
```

## Checklist

### Keychain
- [ ] All credentials stored in Keychain, not UserDefaults
- [ ] Appropriate accessibility level set
- [ ] Using `ThisDeviceOnly` variants when possible
- [ ] Keychain items deleted on logout
- [ ] Error handling for all Keychain operations

### Data Protection
- [ ] Sensitive files use `.complete` protection
- [ ] Background-accessible files use `.completeUntilFirstUserAuthentication`
- [ ] Core Data stores have appropriate protection

### Secure Enclave
- [ ] High-value keys stored in Secure Enclave
- [ ] Fallback for devices without Secure Enclave
- [ ] Biometric protection where appropriate

### General
- [ ] No hardcoded secrets in source code
- [ ] No secrets in Info.plist
- [ ] Sensitive data cleared from memory when done
- [ ] No sensitive data in logs or crash reports
