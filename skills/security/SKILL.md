---
name: security
description: Security review and guidance for iOS, macOS, and watchOS apps. Covers secure storage, biometric authentication, network security, and platform-specific patterns. Use when implementing security features or reviewing code for vulnerabilities.
allowed-tools: [Read, Glob, Grep]
---

# Security Review for Apple Platforms

Comprehensive security guidance for iOS, macOS, and watchOS applications. Reviews code for vulnerabilities and provides secure implementation patterns.

## When This Skill Activates

Use this skill when the user:
- Asks for "security review" or "security audit"
- Wants to implement "secure storage" or "Keychain"
- Needs "Face ID", "Touch ID", or "biometric authentication"
- Asks about "certificate pinning" or "network security"
- Mentions "Data Protection" or "encryption"
- Wants to store "sensitive data", "credentials", or "tokens"
- Asks about "Secure Enclave" or hardware security

## Review Process

### Phase 1: Project Discovery

Identify the app's security surface:

```bash
# Find security-related code
Grep: "SecItem|Keychain|kSecClass"
Grep: "LAContext|biometryType|evaluatePolicy"
Grep: "URLSession|ATS|NSAppTransportSecurity"
Grep: "CryptoKit|SecKey|CC_SHA"
```

Determine:
- Platform (iOS, macOS, watchOS, or multi-platform)
- Sensitive data types (credentials, health data, financial, PII)
- Authentication methods in use
- Network communication patterns

### Phase 2: Secure Storage Review

Load and apply: **secure-storage.md**

Key areas:
- Keychain usage patterns
- Data Protection classes
- Secure Enclave for keys
- Avoiding insecure storage (UserDefaults, files)

### Phase 3: Authentication Review

Load and apply: **biometric-auth.md**

Key areas:
- Face ID / Touch ID implementation
- Fallback mechanisms
- LAContext configuration
- Keychain integration with biometrics

### Phase 4: Network Security Review

Load and apply: **network-security.md**

Key areas:
- App Transport Security configuration
- Certificate pinning
- TLS best practices
- Secure API communication

### Phase 5: Platform-Specific Review

Load and apply: **platform-specifics.md**

Key areas:
- iOS: Data Protection, App Groups, Keychain sharing
- macOS: Sandbox, Hardened Runtime, Keychain access
- watchOS: Health data, Watch Connectivity security

## Output Format

Present findings in this structure:

```markdown
# Security Review: [App Name]

**Platform**: iOS / macOS / watchOS / Universal
**Review Date**: [Date]
**Risk Level**: Critical / High / Medium / Low

## Summary

| Category | Status | Issues |
|----------|--------|--------|
| Secure Storage | ✅/⚠️/❌ | X issues |
| Authentication | ✅/⚠️/❌ | X issues |
| Network Security | ✅/⚠️/❌ | X issues |
| Platform Security | ✅/⚠️/❌ | X issues |

---

## 🔴 Critical Vulnerabilities

Security issues that expose user data or enable attacks.

### [Issue Title]

**File**: `path/to/file.swift:123`
**Risk**: [What could happen if exploited]
**OWASP Category**: [If applicable]

**Vulnerable Code**:
```swift
// current insecure code
```

**Secure Implementation**:
```swift
// fixed secure code
```

---

## 🟠 High Priority Issues

Issues that weaken security posture.

[Same format as above]

---

## 🟡 Medium Priority Issues

Issues that should be addressed for defense in depth.

[Same format as above]

---

## 🟢 Recommendations

Security hardening suggestions.

[Same format as above]

---

## ✅ Security Strengths

What the app does well:
- [Strength 1]
- [Strength 2]

---

## Action Plan

1. **[Critical]** [First fix]
2. **[Critical]** [Second fix]
3. **[High]** [Third fix]
...
```

## Priority Classification

### 🔴 Critical
- Credentials stored in plain text or UserDefaults
- Disabled SSL/TLS validation
- Hardcoded secrets or API keys
- SQL injection or code injection vulnerabilities
- Missing authentication on sensitive operations

### 🟠 High
- Keychain without appropriate access controls
- Missing biometric authentication for sensitive data
- Weak cryptographic implementations
- Overly permissive entitlements
- Sensitive data in logs

### 🟡 Medium
- Missing certificate pinning
- Biometric fallback too permissive
- Data Protection class could be stronger
- Missing jailbreak/integrity detection

### 🟢 Low/Recommendations
- Additional hardening measures
- Defense in depth improvements
- Code organization for security clarity

## Quick Checks

### Insecure Storage Detection
```bash
Grep: "UserDefaults.*password|UserDefaults.*token|UserDefaults.*secret|UserDefaults.*apiKey"
Grep: "\.write\(.*credential|\.write\(.*password"
Grep: "let.*apiKey.*=.*\"|let.*secret.*=.*\""
```

### Insecure Network Detection
```bash
Grep: "http://(?!localhost|127\.0\.0\.1)"
Grep: "AllowsArbitraryLoads.*true"
Grep: "serverTrust|URLAuthenticationChallenge.*useCredential"
```

### Sensitive Data in Logs
```bash
Grep: "print\(.*password|print\(.*token|NSLog.*credential"
Grep: "Logger.*password|os_log.*secret"
```

## References

- **secure-storage.md** - Keychain, Data Protection, Secure Enclave
- **biometric-auth.md** - Face ID, Touch ID, LAContext
- **network-security.md** - ATS, certificate pinning, TLS
- **platform-specifics.md** - iOS vs macOS vs watchOS

## External Resources

- [Apple Security Documentation](https://developer.apple.com/documentation/security)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [App Transport Security](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity)
