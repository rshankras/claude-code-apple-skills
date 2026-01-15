---
name: release-review
description: Senior developer-level release review for macOS/iOS apps. Identifies security, privacy, UX, and distribution issues with actionable fixes. Use when preparing an app for release, want a critical review, or before App Store submission.
allowed-tools: [Read, Glob, Grep]
---

# Release Review for Apple Platforms

Performs a comprehensive pre-release audit of macOS and iOS applications from a senior developer's perspective. Identifies critical issues that could cause rejection, security vulnerabilities, privacy concerns, and UX problems—with actionable fixes.

## When This Skill Activates

Use this skill when the user:
- Says "review for release", "release review", or "pre-release audit"
- Asks for "senior developer review" or "critical review"
- Mentions preparing for "App Store", "TestFlight", or "notarization"
- Wants to know what "power users might complain about"
- Asks to "review before shipping" or "check before release"

## Review Process

### Phase 1: Project Discovery

First, understand the project:

```bash
# Find project type
Glob: **/*.xcodeproj or **/*.xcworkspace
Glob: **/Info.plist
Glob: **/project.pbxproj
```

Identify:
- Platform (macOS, iOS, or both)
- App type (standard app, menu bar app, widget, extension)
- Distribution method (App Store, direct download, TestFlight)

### Phase 2: Security Review

Load and apply: **security-checklist.md**

Key areas:
- Credential storage (Keychain patterns, no hardcoded secrets)
- Data transmission (HTTPS, certificate validation)
- Input validation (injection prevention)
- Entitlements audit
- Hardened runtime (macOS)

### Phase 3: Privacy Review

Load and apply: **privacy-checklist.md**

Key areas:
- Data collection transparency
- Privacy manifest (iOS 17+)
- User consent flows
- Third-party SDK disclosure
- GDPR compliance basics

### Phase 4: UX Polish Review

Load and apply: **ux-polish-checklist.md**

Key areas:
- First launch / onboarding
- Empty states and error handling
- Loading states
- Text truncation and accessibility
- Platform-specific UX patterns

### Phase 5: Distribution Review

Load and apply: **distribution-checklist.md**

Key areas:
- Bundle identifier format
- Code signing configuration
- Info.plist completeness
- App icons
- Platform-specific requirements (notarization, App Store)

### Phase 6: API Design Review

Load and apply: **api-design-checklist.md**

Key areas:
- User-Agent headers (honest identification)
- Error handling patterns
- Token expiration handling
- Rate limiting
- Offline handling

## Output Format

Present findings in this structure:

```markdown
# Release Review: [App Name]

**Platform**: macOS / iOS / Universal
**Distribution**: App Store / Direct Download / TestFlight
**Review Date**: [Date]

## Summary

| Priority | Count |
|----------|-------|
| Critical | X |
| High | X |
| Medium | X |
| Low | X |

---

## 🔴 Critical Issues (Must Fix)

Issues that will cause rejection, crashes, or security vulnerabilities.

### [Category]: [Issue Title]

**File**: `path/to/file.swift:123`
**Impact**: [Why this matters]

**Current Code**:
```swift
// problematic code
```

**Suggested Fix**:
```swift
// fixed code
```

---

## 🟠 High Priority (Should Fix)

Issues that significantly impact user experience or trust.

[Same format as above]

---

## 🟡 Medium Priority (Fix Soon)

Issues that should be addressed but won't block release.

[Same format as above]

---

## 🟢 Low Priority / Suggestions

Nice-to-have improvements and polish.

[Same format as above]

---

## ✅ Strengths

What the app does well:
- [Strength 1]
- [Strength 2]
- [Strength 3]

---

## Recommended Action Plan

1. **[Critical]** [First thing to fix]
2. **[Critical]** [Second thing to fix]
3. **[High]** [Third thing to fix]
...
```

## Priority Classification

### 🔴 Critical
- Security vulnerabilities (credential exposure, injection)
- Crashes or data loss scenarios
- App Store rejection causes
- Privacy violations
- Hardcoded secrets or spoofed identifiers

### 🟠 High
- Poor error handling (silent failures)
- Missing user consent or transparency
- Accessibility blockers
- Missing required Info.plist keys
- Broken functionality

### 🟡 Medium
- Incomplete onboarding
- Suboptimal UX patterns
- Missing empty states
- Performance concerns
- Minor accessibility issues

### 🟢 Low
- Code style improvements
- Additional features
- Polish and refinement
- Documentation improvements

## Platform-Specific Considerations

### macOS
- Menu bar app window activation (`NSApp.activate`)
- Sandbox exceptions justification
- Notarization requirements
- Hardened runtime
- Developer ID signing
- DMG/installer considerations

### iOS
- App Tracking Transparency
- Privacy nutrition labels
- Launch screen requirements
- Export compliance
- In-app purchase requirements
- TestFlight configuration

## References

- **security-checklist.md** - Detailed security review items
- **privacy-checklist.md** - Privacy and data handling
- **ux-polish-checklist.md** - User experience review
- **distribution-checklist.md** - Release and distribution
- **api-design-checklist.md** - Network and API patterns
