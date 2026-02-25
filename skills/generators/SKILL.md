---
name: generators
description: Code generator skills that produce production-ready Swift code for common app components. Use when user wants to add logging, analytics, onboarding, review prompts, networking, authentication, paywalls, settings, persistence, error monitoring, CI/CD pipelines, localization, push notifications, deep linking, testing, accessibility, widgets, feature flags, app icons, image caching, pagination, HTTP caching, share cards, social export, subscription lifecycle, referral systems, watermarks, streak tracking, milestone celebrations, what's new screens, lapsed user re-engagement, usage insights, variable rewards, consent flows, account deletion, permission priming, force updates, state restoration, debug menus, offline queues, feedback forms, announcement banners, quick win sessions, Spotlight indexing, App Clips, or screenshot automation.
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

### http-cache/
HTTP caching layer with Cache-Control, ETag, and offline fallback.
- Cache-Control header parsing
- ETag/Last-Modified conditional requests (304)
- Stale-while-revalidate pattern
- Decorator pattern wrapping existing APIClient
- Network reachability for offline fallback

### pagination/
Pagination infrastructure with offset and cursor patterns.
- Offset-based and cursor-based response models
- State machine (idle, loading, loaded, error, exhausted)
- @Observable PaginationManager with prefetch threshold
- Searchable pagination with debounced query
- Infinite scroll, load-more button, and state views

### image-loading/
Image loading pipeline with caching and CachedAsyncImage view.
- NSCache memory cache with auto-eviction
- LRU disk cache with expiration
- Actor-based downloader with request deduplication
- ImageIO thumbnail generation
- Drop-in CachedAsyncImage SwiftUI replacement
- Collection prefetching

### share-card/
Shareable image cards for social media sharing.
- ShareCardContent protocol with achievement, statistics, and quote types
- ImageRenderer-based card generation
- Configurable styles (minimal, branded, statistics)
- ShareLink integration and QR code overlay

### social-export/
Export content to social platforms with correct formats.
- Platform-specific formatting (Instagram, TikTok, X)
- Aspect ratio and resolution handling per platform
- Branding overlay and caption support
- URL scheme-based and share sheet export

### subscription-lifecycle/
StoreKit 2 subscription lifecycle management.
- Grace period and billing retry handling
- Win-back and promotional offer management
- Subscription status monitoring with Transaction.updates
- Upgrade/downgrade path handling
- Dashboard UI for subscription management

### referral-system/
Referral and invite system with viral growth mechanics.
- Unique code generation with fraud prevention
- Deep link-based sharing and redemption
- Reward tracking for referrer and invitee
- Dashboard with referral statistics

### watermark-engine/
Watermark overlays for images with paywall integration.
- Text, image, and tiled watermark styles
- CoreGraphics-based rendering with Retina support
- Subscription-gated watermark removal
- SwiftUI overlay and ViewModifier

### streak-tracker/
Daily/weekly streak tracking with engagement mechanics.
- SwiftData-based activity recording
- Timezone-aware day boundary calculations
- Streak freeze/protection passes
- Calendar heat map and badge views
- Streak-at-risk notifications

### milestone-celebration/
Achievement celebrations with confetti and badges.
- CAEmitterLayer confetti with Reduce Motion support
- Milestone tracking with threshold detection
- Badge collection grid with progress rings
- Haptic feedback integration

### whats-new/
What's New screen shown after app updates.
- Version tracking with UserDefaults persistence
- Paged TabView feature highlights
- Local and remote content providers
- Auto-present as sheet on version change

### lapsed-user/
Lapsed user detection and re-engagement.
- Configurable inactivity thresholds (7/14/30 days)
- Personalized return experience by lapse category
- Win-back offer screen for lapsed subscribers
- ViewModifier for auto-detection on app launch

### usage-insights/
User-facing usage statistics and activity summaries.
- SwiftData event recording with batch writes
- Insight calculation (streaks, top categories, trends)
- Dashboard with Swift Charts integration
- Shareable recap cards (Spotify Wrapped-style)

### variable-rewards/
Variable reward system with gamification mechanics.
- Weighted probability reward pools with rarity tiers
- Daily spin wheel and mystery box animations
- Daily/weekly caps for ethical engagement
- Reward history and notification views

### consent-flow/
GDPR/CCPA/DPDP privacy consent management.
- Granular per-category consent (analytics, marketing, etc.)
- ATT (App Tracking Transparency) integration
- Consent audit logging for compliance
- Banner and preferences UI with equal prominence

### account-deletion/
Apple-compliant account deletion flow.
- Multi-step confirmation with re-authentication
- Data export before deletion
- Grace period with cancellation option
- Keychain cleanup and Sign in with Apple revocation

### permission-priming/
Pre-permission priming screens for higher grant rates.
- Unified permission manager (notifications, camera, location, etc.)
- Benefit-focused priming UI before system prompt
- Permission status tracking with Settings redirect
- Gated content ViewModifier

### force-update/
Minimum version enforcement with update prompts.
- Remote JSON and App Store lookup version checking
- Hard block (required) and soft prompt (recommended)
- Configurable check frequency
- Skip tracking for soft updates

### state-restoration/
State preservation and restoration across app launches.
- NavigationPath, tab selection, scroll position persistence
- Codable AppState with debounced auto-save
- Form draft manager with auto-save
- @SceneStorage and file-based storage options

### debug-menu/
Developer debug menu (DEBUG builds only).
- Feature flag toggles and environment switcher
- Network request logger with circular buffer
- Cache clearing and diagnostic info export
- Shake gesture and hidden tap triggers

### offline-queue/
Offline operation queue with automatic retry.
- Actor-based queue manager with FIFO + priority
- File-based persistence for queued operations
- Exponential backoff with jitter retry policy
- NWPathMonitor connectivity detection
- Offline status banner ViewModifier

### feedback-form/
In-app feedback collection with smart routing.
- Category-based feedback (bug, feature, praise)
- Screenshot capture and annotation
- Sentiment routing (happy → App Store, unhappy → support)
- Email and webhook submission

### announcement-banner/
In-app announcement banners with remote configuration.
- Priority-based banner display (info, warning, promotion)
- Local and remote announcement providers
- Deep link and URL action handling
- Scheduled display with date ranges

### quick-win-session/
Guided first-action flows for fast time-to-value.
- Step-by-step task guidance
- Spotlight hint overlays with cutout circles
- Completion celebration with timing stats
- ViewModifier for new user detection

### spotlight-indexing/
Core Spotlight indexing for system search integration.
- SpotlightIndexable protocol for any model
- Actor-based batch index manager
- Fluent attribute builder API
- Search continuation and Siri suggestions

### app-clip/
App Clip target with invocation and upgrade flow.
- Invocation URL parsing and routing
- Experience protocol with concrete implementations
- Location confirmation for physical invocations
- SKOverlay full app upgrade prompt
- App Group data sharing

### screenshot-automation/
Automated App Store screenshot generation.
- XCUITest-based screen capture with navigation
- Localized caption overlays with CoreText
- Device frame compositing
- Multi-locale, multi-device batch export

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
