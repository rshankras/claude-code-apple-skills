# Claude Code Skills for Apple Platform Development

A collection of Claude Code skills for iOS, macOS, watchOS, visionOS, and Apple platform development. These skills help you plan and build apps, maintain code quality, ensure HIG compliance, and guide you from idea to App Store.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What's Included

| Category | Skills | Purpose |
|----------|--------|---------|
| **Generators** | 21 | Production-ready code for common features |
| **Product** | 11 | Idea discovery to App Store workflow |
| **macOS** | 8 | Tahoe APIs, SwiftData, AppKit bridge |
| **iOS** | 7 | Code review, UI review, navigation, iPad, migration, accessibility |
| **SwiftUI** | 5 | AlarmKit, WebKit, text editing, toolbars, Charts 3D |
| **App Store** | 4 | ASO, descriptions, keywords, reviews |
| **Swift** | 3 | Concurrency patterns, Swift 6.2, InlineArray/Span |
| **Apple Intelligence** | 3 | Foundation Models, Visual Intelligence, App Intents |
| **Design** | 2 | Liquid Glass (SwiftUI/AppKit/UIKit/WidgetKit), animation patterns |
| **Performance** | 2 | Instruments profiling, SwiftUI debugging |
| **Security** | 2 | Secure storage, biometrics, privacy manifests |
| **watchOS** | 1 | Watch apps, complications, health/fitness, widgets |
| **SwiftData** | 1 | Class inheritance patterns |
| **MapKit** | 1 | GeoToolbox, place descriptors |
| **Foundation** | 1 | AttributedString updates |
| **visionOS** | 1 | Widget development |
| **Release Review** | 1 | Pre-release audit checklists |

**Total: 74 skills**

## Quick Start

### How to Use

**No idea yet?** Say: *"I don't know what to build"*

**New app?** Say: *"I have an idea for a macOS app that does X. Should I build it?"*

**Existing app?** Say: *"Review my code"* or *"Add [feature]"*

See **[docs/USAGE.md](docs/USAGE.md)** for complete guide.

### Installation

```bash
# Clone
git clone https://github.com/rshankras/claude-code-apple-skills.git

# Copy to your project
cp -r claude-code-apple-skills/skills your-project/.claude/skills/

# Or install globally
cp -r claude-code-apple-skills/skills ~/.claude/skills/
```

## Directory Structure

```
skills/
├── ios/                    # iOS code review, UI review, planning, navigation, iPad, migration, accessibility
├── macos/                  # macOS patterns, Tahoe APIs, SwiftData
├── product/                # Idea to App Store workflow (11 skills)
├── generators/             # Code generators (21 skills)
│   ├── logging-setup/
│   ├── analytics-setup/
│   ├── networking-layer/
│   ├── auth-flow/
│   ├── paywall-generator/
│   ├── live-activity-generator/
│   ├── tipkit-generator/
│   ├── cloudkit-sync/
│   └── ...
├── swiftui/                # AlarmKit, WebKit, text editing, toolbars, Charts 3D
├── apple-intelligence/     # Foundation Models, Visual Intelligence, App Intents
├── design/                 # Liquid Glass, animation patterns
├── performance/            # Instruments profiling, SwiftUI debugging
├── security/               # Keychain, biometrics, network security, privacy manifests
├── swift/                  # Concurrency patterns, Swift 6.2, InlineArray/Span
├── swiftdata/              # Class inheritance patterns
├── mapkit/                 # GeoToolbox, place descriptors
├── foundation/             # AttributedString updates
├── visionos/               # visionOS widgets
├── app-store/              # ASO, descriptions, screenshots, reviews
├── watchos/                # Watch apps, complications, health/fitness, widgets
├── release-review/         # Security, privacy, UX, distribution audits
└── shared/                 # Skill creation templates
```

## Documentation

| Doc | Description |
|-----|-------------|
| [docs/USAGE.md](docs/USAGE.md) | How to use for new vs existing apps |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Skills roadmap and status |
| [skills/product/WORKFLOW.md](skills/product/WORKFLOW.md) | Full idea to App Store workflow |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |

## Generator Skills

Generate production-ready Swift code that adapts to your project:

| Generator | What It Creates |
|-----------|-----------------|
| `logging-setup` | Apple Logger infrastructure |
| `analytics-setup` | Protocol-based analytics (TelemetryDeck, Firebase) |
| `networking-layer` | Async/await API client |
| `auth-flow` | Sign in with Apple + biometrics |
| `paywall-generator` | StoreKit 2 subscriptions |
| `settings-screen` | Complete preferences UI |
| `persistence-setup` | SwiftData + optional iCloud |
| `onboarding-generator` | Multi-step welcome flow |
| `review-prompt` | Smart App Store review requests |
| `error-monitoring` | Crash reporting (Sentry/Crashlytics) |
| `ci-cd-setup` | GitHub Actions / Xcode Cloud |
| `localization-setup` | String catalogs, i18n |
| `push-notifications` | APNs setup |
| `deep-linking` | URL schemes, universal links |
| `test-generator` | Unit/UI tests (Swift Testing + XCTest) |
| `accessibility-generator` | VoiceOver, Dynamic Type |
| `widget-generator` | WidgetKit widgets with templates |
| `feature-flags` | Local/remote feature flags with templates |
| `app-icon-generator` | Programmatic app icons via CoreGraphics |
| `live-activity-generator` | ActivityKit Live Activities + Dynamic Island |
| `tipkit-generator` | TipKit inline/popover tips |
| `cloudkit-sync` | CKSyncEngine CloudKit sync |

## SwiftUI Skills

| Skill | What It Covers |
|-------|----------------|
| `swiftui/alarmkit` | AlarmKit alarms and timers with Live Activities |
| `swiftui/webkit` | WebView and WebPage integration |
| `swiftui/text-editing` | AttributedString, TextEditor, rich text formatting |
| `swiftui/toolbars` | Customizable toolbars, search integration, transitions |
| `swiftui/charts-3d` | 3D chart visualization |

## Performance Skills

| Skill | What It Covers |
|-------|----------------|
| `performance/profiling` | Instruments workflows, Time Profiler, Allocations, hangs |
| `performance/swiftui-debugging` | View identity, body re-evaluation, lazy loading, `_printChanges()` |

## App Store Optimization (ASO) Skills

| Skill | What It Does |
|-------|--------------|
| `keyword-optimizer` | Find high-traffic, low-competition keywords |
| `app-description-writer` | Compelling descriptions that convert |
| `screenshot-planner` | Screenshot sequences with keyword-rich captions |
| `review-response-writer` | Professional review responses |

## Security Skills

| Skill | What's Covered |
|-------|----------------|
| `security` | Keychain, Data Protection, Secure Enclave, biometrics, network security |
| `security/privacy-manifests` | Privacy manifest format, required reason APIs, App Tracking Transparency |

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

## Disclaimer

Skills in this repository were generated with the assistance of [Claude Code](https://claude.ai/code). Content may contain inaccuracies -- contributions and corrections are welcome.

## License

MIT License - see [LICENSE](LICENSE).
