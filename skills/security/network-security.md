# Network Security

Securing network communication on Apple platforms with ATS, TLS, and certificate pinning.

## App Transport Security (ATS)

ATS enforces secure connections by default on iOS 9+ and macOS 10.11+.

### Default Behavior

By default, ATS requires:
- HTTPS (TLS 1.2 or later)
- Forward secrecy ciphers
- Valid certificates from trusted CAs

### ✅ Good: Trust Default ATS

```xml
<!-- No ATS configuration needed - defaults are secure -->
<!-- Just use https:// URLs in your code -->
```

```swift
// ATS will enforce HTTPS automatically
let url = URL(string: "https://api.example.com/data")!
```

### ⚠️ Exception: Specific Domain Needs HTTP

Only use when connecting to legacy servers you don't control:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>legacy-server.example.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.0</string>
        </dict>
    </dict>
</dict>
```

### ❌ Never Do This in Production

```xml
<!-- DANGEROUS: Disables ATS entirely -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

This will likely cause App Store rejection and exposes users to MITM attacks.

### ATS for Local Development

Allow localhost during development only:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

Better approach - use build configurations:

```xml
<!-- In Debug.xcconfig -->
ATS_LOCALHOST_EXCEPTION = true

<!-- In Release.xcconfig -->
ATS_LOCALHOST_EXCEPTION = false
```

## Certificate Pinning

Pin certificates or public keys to prevent MITM attacks even with compromised CAs.

### When to Use Certificate Pinning

| Scenario | Recommendation |
|----------|----------------|
| Banking/financial apps | Required |
| Healthcare apps | Required |
| Apps handling PII | Strongly recommended |
| General consumer apps | Recommended |
| Apps using third-party APIs | Optional (can't pin their certs) |

### Public Key Pinning (Recommended)

Public key pinning survives certificate rotation better than certificate pinning.

```swift
import Foundation
import CryptoKit

final class CertificatePinningDelegate: NSObject, URLSessionDelegate {

    // SHA256 hashes of your server's public key(s)
    // Include backup pins for key rotation
    private let pinnedKeyHashes: Set<String> = [
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", // Primary
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=", // Backup
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Validate the certificate chain
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)

        guard isValid else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Check if any certificate in the chain matches our pins
        let certificateCount = SecTrustGetCertificateCount(serverTrust)

        for index in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, index) else {
                continue
            }

            if let publicKeyHash = publicKeyHash(for: certificate),
               pinnedKeyHashes.contains(publicKeyHash) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }

        // No matching pin found
        completionHandler(.cancelAuthenticationChallenge, nil)
    }

    private func publicKeyHash(for certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        // Add ASN.1 header for RSA 2048 or EC P-256 public key
        let hash = SHA256.hash(data: publicKeyData)
        return Data(hash).base64EncodedString()
    }
}

// Usage
let pinningDelegate = CertificatePinningDelegate()
let session = URLSession(configuration: .default, delegate: pinningDelegate, delegateQueue: nil)
```

### Extracting Public Key Hash

Get the SHA256 hash of your server's public key:

```bash
# From a certificate file
openssl x509 -in server.crt -pubkey -noout | \
    openssl pkey -pubin -outform DER | \
    openssl dgst -sha256 -binary | \
    base64

# From a live server
echo | openssl s_client -connect api.example.com:443 2>/dev/null | \
    openssl x509 -pubkey -noout | \
    openssl pkey -pubin -outform DER | \
    openssl dgst -sha256 -binary | \
    base64
```

### Certificate Pinning with TrustKit

For production apps, consider using TrustKit (open source library):

```swift
// Package.swift dependency
.package(url: "https://github.com/datatheorem/TrustKit.git", from: "3.0.0")
```

```swift
import TrustKit

// Configure at app launch
let trustKitConfig: [String: Any] = [
    kTSKPinnedDomains: [
        "api.example.com": [
            kTSKPublicKeyHashes: [
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
            ],
            kTSKEnforcePinning: true,
            kTSKIncludeSubdomains: true
        ]
    ]
]

TrustKit.initSharedInstance(withConfiguration: trustKitConfig)
```

## Secure URLSession Configuration

### Production Configuration

```swift
final class SecureNetworkClient {

    static let shared = SecureNetworkClient()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default

        // Timeouts
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300

        // Disable caching for sensitive requests
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil

        // Require modern TLS
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12

        // Disable cookies if not needed
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false

        session = URLSession(configuration: configuration)
    }

    func request(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        return data
    }
}
```

### Sensitive Request Headers

```swift
extension URLRequest {

    mutating func addSecureHeaders(token: String) {
        // Authentication
        setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Prevent caching
        setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control")
        setValue("no-cache", forHTTPHeaderField: "Pragma")
        setValue("0", forHTTPHeaderField: "Expires")

        // Content type
        setValue("application/json", forHTTPHeaderField: "Content-Type")
        setValue("application/json", forHTTPHeaderField: "Accept")
    }
}
```

## ❌ Anti-patterns

### Disabling Certificate Validation

```swift
// NEVER DO THIS IN PRODUCTION
class InsecureDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // DANGEROUS: Accepts any certificate, enables MITM attacks
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        }
    }
}
```

### Logging Sensitive Data

```swift
// NEVER log tokens, passwords, or sensitive request/response data
print("Auth token: \(token)")  // ❌
print("Request body: \(requestBody)")  // ❌
print("Response: \(responseData)")  // ❌

// OK: Log non-sensitive metadata
print("Request to: \(url.host ?? "unknown")")  // ✅
print("Status code: \(statusCode)")  // ✅
```

### Hardcoded API Keys

```swift
// NEVER hardcode API keys in source
let apiKey = "sk-ant-api03-xxxxx"  // ❌

// Store in Keychain or use environment/config
let apiKey = try KeychainManager.shared.readString(account: "api_key")  // ✅
```

## Secure Data Transmission

### Encrypting Request Bodies

For extremely sensitive data, encrypt before transmission:

```swift
import CryptoKit

func encryptPayload(_ data: Data, using key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.seal(data, using: key)
    return sealedBox.combined!
}

func decryptPayload(_ data: Data, using key: SymmetricKey) throws -> Data {
    let sealedBox = try AES.GCM.SealedBox(combined: data)
    return try AES.GCM.open(sealedBox, using: key)
}
```

### Preventing Replay Attacks

```swift
struct SecureRequest {
    let payload: Data
    let timestamp: TimeInterval
    let nonce: String

    init(payload: Data) {
        self.payload = payload
        self.timestamp = Date().timeIntervalSince1970
        self.nonce = UUID().uuidString
    }

    var isExpired: Bool {
        let age = Date().timeIntervalSince1970 - timestamp
        return age > 300 // 5 minute window
    }

    func sign(with key: SymmetricKey) -> Data {
        let message = payload + String(timestamp).data(using: .utf8)! + nonce.data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: message, using: key)
        return Data(signature)
    }
}
```

## Background Session Security

```swift
// Background sessions need careful security consideration
let backgroundConfig = URLSessionConfiguration.background(withIdentifier: "com.app.background")

// Discretionary allows system to optimize for battery/network
backgroundConfig.isDiscretionary = true

// Require wifi for large downloads (optional)
backgroundConfig.allowsCellularAccess = false

// Sessions survive app termination - be careful with sensitive data
backgroundConfig.sessionSendsLaunchEvents = true
```

## WebSocket Security

```swift
import Foundation

let wsURL = URL(string: "wss://api.example.com/socket")! // Always use wss://

let webSocketTask = URLSession.shared.webSocketTask(with: wsURL)

// Ping to keep connection alive and detect disconnects
func schedulePing() {
    webSocketTask.sendPing { error in
        if let error = error {
            print("Ping failed: \(error)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            schedulePing()
        }
    }
}
```

## Checklist

### App Transport Security
- [ ] No `NSAllowsArbitraryLoads` in production
- [ ] Domain exceptions are documented and justified
- [ ] All API endpoints use HTTPS
- [ ] TLS 1.2 or higher required

### Certificate Pinning
- [ ] Pinning implemented for high-security apps
- [ ] Backup pins configured for key rotation
- [ ] Pin validation happens for entire certificate chain
- [ ] Graceful handling of pin validation failures

### URLSession Configuration
- [ ] Appropriate timeouts configured
- [ ] Caching disabled for sensitive requests
- [ ] Cookies disabled if not needed
- [ ] Modern TLS version enforced

### General
- [ ] No sensitive data in request logs
- [ ] No hardcoded API keys or tokens
- [ ] SSL validation never disabled in production
- [ ] Error messages don't leak sensitive info
