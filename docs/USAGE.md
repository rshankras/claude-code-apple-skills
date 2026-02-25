# How to Use These Skills

## New App: Idea to App Store

### Phase 1: Validate
**Say:** "I have an idea for a [iOS/macOS] app that does X. Should I build it?"

Claude checks if it's worth building and gives you a BUILD / DON'T BUILD recommendation.

### Phase 2: Research (Optional)
**Say:** "Analyze competitors" and "Do market research"

### Phase 3: Generate Specs
**Say:** "Generate implementation specifications"

Creates 7 docs: PRD, Architecture, UX, Design System, Implementation Guide, Test Spec, Release Spec.

### Phase 4: Build
Follow the Implementation Guide, or ask Claude to generate specific features.

### Phase 5: Review & Release
**Say:** "Review for release" then follow the Release Spec to submit.

---

## Existing App: Quick Reference

| I want to... | Say this... |
|--------------|-------------|
| Generate app ideas | "I don't know what to build" or "Give me app ideas" |
| Fix code issues | "Review my code for best practices" |
| Check UI compliance | "Review my UI for HIG" |
| Add logging | "Add logging to my app" |
| Add analytics | "Add analytics with TelemetryDeck" |
| Add settings | "Add settings screen" |
| Add auth | "Add Sign in with Apple" |
| Add payments | "Add subscription paywall" |
| Add onboarding | "Add onboarding flow" |
| Add notifications | "Add push notifications" |
| Add deep links | "Add deep linking" |
| Add crash reporting | "Add error monitoring" |
| Set up CI/CD | "Set up GitHub Actions" |
| Add localization | "Add localization to my app" |
| Add persistence | "Add SwiftData persistence" |
| Add tests | "Generate tests for my app" |
| Add accessibility | "Add VoiceOver support" |
| Add widgets | "Add a home screen widget" |
| Add feature flags | "Add feature flags" |
| Generate app icon | "Generate an app icon" |
| Add Live Activities | "Add a Live Activity with Dynamic Island" |
| Add tips | "Add TipKit tips to my app" |
| Add CloudKit sync | "Add CloudKit sync with CKSyncEngine" |
| Fix animation code | "Review my animation code" or "Add a spring animation" |
| Modernize UI | "Update to Liquid Glass design" |
| Add AI features | "Add on-device LLM features" |
| Add Siri/Shortcuts | "Add App Intents for Siri" |
| Review security | "Review security in my app" |
| Add privacy manifest | "Add a privacy manifest" |
| Prepare for release | "Review for release" |
| Improve App Store listing | "Optimize my App Store keywords" |
| Respond to review | "Help respond to this review: [text]" |
| Debug SwiftUI perf | "My SwiftUI views are slow" or "Why does my view keep re-rendering?" |
| Profile performance | "Profile my app for hangs" |
| Plan monetization | "Should I monetize my app?" or "Help me choose a pricing model" |
| TDD a new feature | "TDD this feature" or "Build test-first" |
| Fix bug with TDD | "Fix this bug and add a regression test" |
| Safe refactoring | "I need to refactor this safely" or "Add tests before refactoring" |
| Snapshot tests | "Add visual regression tests" or "Set up snapshot testing" |
| Test factories | "Generate test data factories" |
| Integration tests | "Add integration test infrastructure" |
| Contract tests | "Test this protocol contract" |
| Cache API responses | "Add HTTP caching" or "Add offline support" |
| Add pagination | "Add pagination" or "Add infinite scroll" |
| Add image caching | "Add image caching" or "Replace AsyncImage with caching" |
| Add share cards | "Add shareable image cards" or "Generate social share cards" |
| Export to social | "Export to Instagram Stories" or "Add social media export" |
| Manage subscriptions | "Add subscription lifecycle management" or "Handle grace periods" |
| Add referrals | "Add referral system" or "Add invite friends" |
| Add watermarks | "Add watermark to images" or "Add free tier watermark" |
| Add streaks | "Add daily streak tracking" or "Add engagement streaks" |
| Add celebrations | "Add confetti animation" or "Add achievement celebrations" |
| Add What's New | "Add What's New screen" or "Show changelog after update" |
| Re-engage users | "Add lapsed user detection" or "Add returning user screen" |
| Show usage stats | "Add usage insights dashboard" or "Add weekly recap" |
| Add rewards | "Add daily rewards" or "Add mystery box rewards" |
| Add consent flow | "Add GDPR consent" or "Add privacy consent flow" |
| Add account deletion | "Add account deletion" or "Apple account deletion requirement" |
| Add permission priming | "Add permission priming screen" or "Explain permissions before asking" |
| Add force update | "Add minimum version check" or "Add force update prompt" |
| Add state restoration | "Save and restore app state" or "Remember navigation position" |
| Add debug menu | "Add debug menu" or "Add developer tools menu" |
| Add offline queue | "Add offline support" or "Queue requests when offline" |
| Add feedback form | "Add in-app feedback" or "Add bug report form" |
| Add announcements | "Add announcement banner" or "Add in-app notifications" |
| Add quick win flow | "Add guided first action" or "Add quick win onboarding" |
| Add Spotlight search | "Add Spotlight indexing" or "Make content searchable" |
| Add App Clip | "Add an App Clip" or "Create a lightweight app experience" |
| Automate screenshots | "Automate App Store screenshots" or "Generate screenshots" |
| Add alarms/timers | "Add AlarmKit alarms" |
| Add web content | "Embed a web view in SwiftUI" |
| Add rich text editor | "Add a rich text editor with formatting" |
| Customize toolbars | "Add a customizable toolbar" |
| Add 3D charts | "Add a 3D chart visualization" |
| Migrate to SwiftData | "Migrate from CoreData to SwiftData" |
| Migrate to SwiftUI | "Migrate from UIKit to SwiftUI" |
| Migrate to @Observable | "Migrate from ObservableObject to @Observable" |
| Fix concurrency issues | "Fix Swift 6 concurrency warnings" |
| Add iPad support | "Add iPad multitasking and drag & drop" |
| Add watch features | "Add a watchOS companion app" |
| Add complications | "Add a watch complication" |
| Add health tracking | "Add HealthKit workout tracking" |
| Add visionOS widgets | "Add widgets for visionOS" |
| Add map features | "Add MapKit with place descriptors" |

---

## Multi-Platform (iOS + macOS)

**Same workflow** - just say "iOS and macOS app" when describing your idea.

Differences:
- Architecture includes shared code + platform-specific UI layers
- UI review checks both iOS HIG and macOS HIG
- Two App Store submissions (one per platform)
- Screenshots needed for both platforms

---

## Skill Categories

| Category | Count | Purpose | When to Use |
|----------|-------|---------|-------------|
| `generators/` | 49 | Generate code | Add features to any app |
| `product/` | 11 | Idea to specs | New app planning, full workflow |
| `macos/` | 8 | macOS development | Code review, UI review, Tahoe APIs |
| `ios/` | 7 | iOS development | Code review, navigation, iPad, migration |
| `swiftui/` | 5 | SwiftUI features | AlarmKit, WebKit, text editing, toolbars, Charts 3D |
| `app-store/` | 4 | ASO | Descriptions, keywords, screenshots |
| `swift/` | 3 | Swift language | Concurrency, Swift 6.2, memory (InlineArray/Span) |
| `apple-intelligence/` | 3 | AI features | Foundation Models, Visual Intelligence, App Intents |
| `design/` | 2 | Modern UI | Liquid Glass (SwiftUI/AppKit/UIKit/WidgetKit), animations |
| `performance/` | 2 | Performance | Instruments profiling, SwiftUI debugging |
| `security/` | 2 | Security | Keychain, biometrics, privacy manifests |
| `swiftdata/` | 1 | Data persistence | Class inheritance patterns |
| `mapkit/` | 1 | Maps & location | GeoToolbox, place descriptors |
| `foundation/` | 1 | Foundation | AttributedString updates |
| `visionos/` | 1 | visionOS | Widget development |
| `watchos/` | 1 | watchOS | Watch apps, complications, health/fitness, widgets |
| `testing/` | 8 | TDD & testing | TDD workflows, snapshots, test infrastructure |
| `monetization/` | 1 | Revenue strategy | Pricing models, tiers, free trials |
| `release-review/` | 1 | Pre-release | Security, privacy, UX audit |
| `shared/` | 1 | Skill creation | Templates for creating new skills |

**Total: 110 skills**

---

## FAQ

### Can I skip phases for a new app?
Yes, but not recommended. Specs build on each other. Skipping means less structured implementation.

### Do I need to invoke skills manually?
No. Just describe what you want. Claude picks the right skill automatically.

### How do generators work with existing code?
Claude reads your project first, then generates code that matches your patterns and structure.

### What if a generator doesn't fit my architecture?
Generator output is a starting point. Modify it to fit your needs, or ask Claude to adjust.

### iOS vs macOS - what's different?
Just the platform-specific review skills. Everything else (generators, product workflow, App Store skills) works the same.

### Can I use this for watchOS/visionOS?
watchOS: Yes, there's a dedicated `watchos/` skill covering Watch apps, complications, health/fitness, and widgets.
visionOS: There's a `visionos/widgets` skill for widget development. More visionOS skills may be added in the future.

### Where are the detailed skill docs?
Each skill has a `SKILL.md` with full documentation. Browse `skills/` directory.
