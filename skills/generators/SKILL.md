---
name: generators
description: Code generator skills that produce production-ready Swift code for common app components. Use when user wants to add logging, analytics, onboarding, review prompts, networking, authentication, paywalls, settings, persistence, error monitoring, CI/CD pipelines, localization, push notifications, deep linking, testing, accessibility, widgets, feature flags, or app icons.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Code Generators

Production-ready code generators for iOS and macOS apps. Unlike advisory skills (review, audit), these skills generate working code tailored to your project.

## When This Skill Activates

Use this skill when the user:
- Wants to add a common app component (logging, analytics, onboarding, etc.)
- Asks to "set up" or "add" infrastructure code
- Mentions replacing print() with proper logging
- Wants to add App Store review prompts
- Needs analytics or crash reporting setup

## Key Principles

### 1. Context-Aware Generation
Before generating code, skills will:
- Read existing project structure and patterns
- Detect deployment targets and Swift version
- Identify architecture patterns (MVVM, TCA, etc.)
- Check for existing implementations to avoid conflicts

### 2. Protocol-Based Architecture
Provider-dependent code uses protocols for easy swapping:
```swift
protocol AnalyticsService { ... }
class TelemetryDeckAnalytics: AnalyticsService { ... }
class FirebaseAnalytics: AnalyticsService { ... }
// Change provider by swapping ONE line
```

### 3. Platform Detection
Skills detect iOS vs macOS and App Store vs direct distribution to generate appropriate code.

## Available Generators

Read relevant module files based on the user's needs:

### logging-setup/
Replace print() statements with structured os.log/Logger.
- Audit existing print() usage
- Generate AppLogger infrastructure
- Migrate print → Logger with proper privacy levels

### analytics-setup/
Protocol-based analytics with swappable providers.
- TelemetryDeck, Firebase, Mixpanel support
- NoOp implementation for testing/privacy
- Easy provider switching

### onboarding-generator/
Multi-step onboarding flow with persistence.
- Paged or stepped navigation
- @AppStorage persistence
- Skip option configuration
- Accessibility support

### review-prompt/
Smart App Store review prompts.
- Platform detection (skips for non-App Store macOS)
- Configurable trigger conditions
- Smart timing logic
- Debug override for testing

### networking-layer/
Protocol-based API client with async/await.
- Clean APIClient protocol for mocking/swapping
- Type-safe endpoint definitions
- Comprehensive error handling
- Environment-based configuration

### auth-flow/
Complete authentication flow.
- Sign in with Apple integration
- Biometric authentication (Face ID/Touch ID)
- Secure Keychain storage
- Credential state monitoring

### paywall-generator/
StoreKit 2 subscription paywall.
- Full StoreKit 2 implementation
- Product loading, purchasing, restoring
- Subscription status with Environment
- Beautiful paywall UI

### settings-screen/
Complete settings screen with modular sections.
- Centralized AppSettings with @AppStorage
- Appearance, Notifications, Account, About, Legal sections
- Cross-platform (iOS/macOS)
- Reusable row components

### persistence-setup/
SwiftData persistence with optional iCloud sync.
- SwiftData container configuration
- Repository pattern for testability
- Optional CloudKit/iCloud sync
- Sync status monitoring
- Migration support

### error-monitoring/
Protocol-based crash/error reporting.
- Sentry and Firebase Crashlytics support
- NoOp implementation for testing/privacy
- Breadcrumbs for debugging context
- User context (anonymized)
- Easy provider swapping

### ci-cd-setup/
CI/CD configuration for automated builds and deployment.
- GitHub Actions workflows (build, test, TestFlight, App Store)
- Xcode Cloud scripts and setup guide
- fastlane lanes for advanced automation
- Code signing and secrets management
- macOS notarization support

### localization-setup/
Internationalization (i18n) infrastructure for multi-language apps.
- String Catalogs (iOS 16+, recommended)
- Type-safe L10n enum for compile-time safety
- Pluralization and interpolation patterns
- RTL layout support
- SwiftUI preview helpers for testing locales

### push-notifications/
Push notification infrastructure with APNs setup.
- Registration and authorization flow
- UNUserNotificationCenterDelegate implementation
- Notification categories with action buttons
- Type-safe payload parsing
- Rich notifications and silent notifications

### deep-linking/
Deep linking with URL schemes, Universal Links, and App Intents.
- Custom URL scheme handling
- Universal Links with AASA file
- App Intents for Siri and Shortcuts
- Type-safe route definitions and navigation
- Spotlight indexing support

### test-generator/
Test templates for unit, integration, and UI tests.
- Swift Testing (modern, iOS 16+) and XCTest patterns
- Mock object generation
- ViewModel and service testing patterns
- UI testing with page object pattern

### accessibility-generator/
Accessibility infrastructure for inclusive apps.
- VoiceOver labels, hints, and traits
- Dynamic Type support with scaling
- Reduce Motion handling
- Accessibility audit checklist

### widget-generator/
WidgetKit widgets for home screen and lock screen.
- Static and interactive widgets (iOS 17+)
- Timeline providers
- Lock screen complications
- Widget intents for configuration

### app-icon-generator/
Programmatic app icon generation using CoreGraphics.
- Apple HIG compliant icon design
- Category-aware design recipes (productivity, media, dev tools, etc.)
- 3 variant generation for user selection
- Automatic resizing to all required sizes (macOS + iOS)
- Asset catalog installation with correct Contents.json
- No external dependencies — pure CoreGraphics

### feature-flags/
Feature flag infrastructure with local and remote support.
- Protocol-based service with swappable providers
- Local defaults with remote override (composite provider)
- @Observable manager for SwiftUI integration
- Debug menu for toggling flags

### live-activity-generator/
ActivityKit Live Activity with Dynamic Island and Lock Screen.
- ActivityAttributes and ContentState definitions
- Dynamic Island layouts (compact and expanded)
- Lock Screen presentation
- Push-to-update support via APNs
- Activity lifecycle management (start, update, end)

### tipkit-generator/
TipKit inline and popover tips with rules and testing.
- Inline and popover tip definitions
- Rule-based display logic (parameter and event rules)
- Display frequency and invalidation
- Testing and preview support

### cloudkit-sync/
CKSyncEngine-based CloudKit sync (iOS 17+).
- CKSyncEngine setup and delegate
- Record zone management
- Conflict resolution strategies
- Sharing and collaboration support

## How to Use

1. User requests a component (e.g., "add logging to my app")
2. Read the relevant skill's SKILL.md
3. Run pre-generation checks (conflicts, deployment target, etc.)
4. Ask configuration questions via AskUserQuestion
5. Generate code from templates, adapting to project context
6. Provide integration instructions

## Output Format

After generation, always provide:
- **Files created** (with full paths)
- **Integration steps** (how to wire into existing code)
- **Required capabilities** (entitlements, dependencies)
- **Testing instructions** (how to verify it works)
