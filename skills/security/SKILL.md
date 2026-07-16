---
name: security
description: Security category index for Apple platforms. Routes to the privacy-manifests skill. General secure-storage/biometrics/ATS guidance was retired in the 2026 blind-test audit — current models cover it natively.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# Security (category index)

General security guidance (Keychain patterns, biometric auth, certificate
pinning, ATS) was removed from this library after the 2026-07 blind-test
audit confirmed current models answer it correctly without a skill
(`tools/skill-audit/`, Fable-verified coverage 0.86). What remains here is
the material models get wrong or can't know.

## Available Skills

### privacy-manifests/
Privacy manifest audit — PrivacyInfo.xcprivacy format, required-reason APIs,
App Tracking Transparency declarations, and App Store submission requirements.
