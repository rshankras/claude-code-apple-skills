# Security Checklist

Comprehensive security review for macOS and iOS applications.

## Credential Storage

### Keychain Usage

#### ✅ Good Patterns
```swift
// Store sensitive data in Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: "com.app.credentials",
    kSecAttrAccount as String: account,
    kSecValueData as String: data
]
SecItemAdd(query as CFDictionary, nil)
```

#### ❌ Anti-patterns
```swift
// Never store credentials in UserDefaults
UserDefaults.standard.set(apiKey, forKey: "apiKey")

// Never hardcode secrets
let apiKey = "sk-ant-api03-xxxxx"

// Never store in plain text files
try apiKey.write(to: credentialsFile, atomically: true, encoding: .utf8)
```

### Checklist
- [ ] API keys stored in Keychain, not UserDefaults
- [ ] No hardcoded secrets in source code
- [ ] No secrets in Info.plist
- [ ] Keychain items have appropriate access controls
- [ ] Credentials cleared on logout/sign-out

### Search Patterns
```
Grep: "UserDefaults.*password|UserDefaults.*token|UserDefaults.*key|UserDefaults.*secret"
Grep: "sk-ant-|api-key-|Bearer [A-Za-z0-9]"
Grep: "hardcoded|TODO.*key|FIXME.*secret"
```

## Data Transmission

### Network Security

#### ✅ Good Patterns
```swift
// Use HTTPS
let url = URL(string: "https://api.example.com")

// Validate SSL certificates (default behavior)
let session = URLSession.shared

// Set appropriate timeouts
var request = URLRequest(url: url)
request.timeoutInterval = 30
```

#### ❌ Anti-patterns
```swift
// Never disable SSL validation in production
class InsecureDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // DANGEROUS: Accepts any certificate
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

// Never use HTTP for sensitive data
let url = URL(string: "http://api.example.com/login")
```

### Checklist
- [ ] All API calls use HTTPS
- [ ] No disabled SSL certificate validation
- [ ] Sensitive data not logged to console
- [ ] Request/response bodies not logged in production
- [ ] Appropriate request timeouts set

### Search Patterns
```
Grep: "http://" (excluding localhost/127.0.0.1)
Grep: "URLAuthenticationChallenge|serverTrust"
Grep: "print.*token|print.*password|NSLog.*credential"
```

## Input Validation

### User Input

#### ✅ Good Patterns
```swift
// Validate and sanitize user input
func validateEmail(_ email: String) -> Bool {
    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
}

// Use parameterized queries for database
let query = "SELECT * FROM users WHERE id = ?"
```

#### ❌ Anti-patterns
```swift
// String interpolation in queries = SQL injection risk
let query = "SELECT * FROM users WHERE name = '\(userInput)'"

// Unsanitized HTML rendering = XSS risk
webView.loadHTMLString("<div>\(userInput)</div>", baseURL: nil)
```

### Checklist
- [ ] User input validated before use
- [ ] No string interpolation in database queries
- [ ] HTML content sanitized before rendering
- [ ] File paths validated (no path traversal)
- [ ] URL schemes validated

## Entitlements & Sandboxing

### macOS Sandbox

#### Checklist
- [ ] App is sandboxed (unless justified exception)
- [ ] Only necessary entitlements requested
- [ ] Sandbox exceptions documented and justified
- [ ] Temporary exception entitlements have migration plan

#### Common Entitlements to Review
```xml
<!-- Justify each of these -->
<key>com.apple.security.files.user-selected.read-write</key>
<key>com.apple.security.files.downloads.read-write</key>
<key>com.apple.security.network.client</key>
<key>com.apple.security.network.server</key>
```

### iOS Capabilities

#### Checklist
- [ ] Only necessary capabilities enabled
- [ ] Background modes justified
- [ ] Push notification entitlement if using push
- [ ] Keychain sharing groups appropriate

## Hardened Runtime (macOS)

### Checklist
- [ ] Hardened Runtime enabled for notarization
- [ ] Runtime exceptions minimized
- [ ] JIT exceptions only if absolutely necessary
- [ ] Unsigned executable memory exceptions justified

### Search in project.pbxproj
```
Grep: "ENABLE_HARDENED_RUNTIME"
Grep: "CODE_SIGN_INJECT_BASE_ENTITLEMENTS"
```

## Platform-Specific Security

### macOS
- [ ] Keychain access properly scoped
- [ ] App Groups used appropriately
- [ ] XPC services secured
- [ ] Helper tools signed and validated

### iOS
- [ ] Keychain access groups configured
- [ ] App Transport Security not disabled globally
- [ ] Jailbreak detection considered (if needed)
- [ ] Data Protection class appropriate for sensitive data

## Common Vulnerabilities

### Checklist
- [ ] No force unwrapping of security-critical optionals
- [ ] Cryptographic operations use Security framework
- [ ] Random numbers use SecRandomCopyBytes for security
- [ ] Sensitive data cleared from memory when done
- [ ] Debug code removed from release builds

### Search Patterns
```
Grep: "print.*debug|#if DEBUG.*secret"
Grep: "arc4random|rand\(\)" (should use SecRandomCopyBytes)
```

## References

- [Apple Security Guidelines](https://developer.apple.com/documentation/security)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
