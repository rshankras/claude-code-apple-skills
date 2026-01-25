# Claude Code Skills for Apple Platform Development

A comprehensive collection of Claude Code skills for iOS, macOS, and Apple platform development. These skills help you **plan and build apps**, **maintain code quality**, **ensure HIG compliance**, and guide you from **idea to App Store**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What's Included

| Category | Skills | Purpose |
|----------|--------|---------|
| **iOS** | 3 | Code review, UI review, app planning |
| **macOS** | 8 | Tahoe APIs, SwiftData, AppKit bridge |
| **Product** | 10 | Idea validation → App Store workflow |
| **Generators** | 18 | Production-ready code for common features |
| **Apple Intelligence** | 2 | Foundation Models, Visual Intelligence |
| **Design** | 1 | Liquid Glass design system |
| **Security** | 1 | Secure storage, biometrics, network security |
| **App Store** | 4 | ASO, descriptions, keywords, reviews |
| **Release Review** | 1 | Pre-release audit checklists |

**Total: 49 skills**

## Quick Start

### How to Use

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
├── ios/                    # iOS code review, UI review, planning
├── macos/                  # macOS patterns, Tahoe APIs, SwiftData
├── product/                # Idea → App Store workflow (10 phases)
├── generators/             # Code generators (18 skills)
│   ├── logging-setup/
│   ├── analytics-setup/
│   ├── networking-layer/
│   ├── auth-flow/
│   ├── paywall-generator/
│   ├── settings-screen/
│   ├── persistence-setup/
│   ├── push-notifications/
│   ├── deep-linking/
│   └── ...
├── apple-intelligence/     # Foundation Models, Visual Intelligence
├── design/                 # Liquid Glass (.glassEffect API)
├── security/               # Keychain, biometrics, network security
├── app-store/              # ASO, descriptions, screenshots, reviews
│   ├── keyword-optimizer/  # + advanced-tactics, existing-app-strategy
│   ├── app-description-writer/
│   ├── screenshot-planner/
│   └── review-response-writer/
├── release-review/         # Security, privacy, UX, distribution audits
└── shared/                 # Skill creation templates
```

## Documentation

| Doc | Description |
|-----|-------------|
| [docs/USAGE.md](docs/USAGE.md) | How to use for new vs existing apps |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Planned future skills |
| [skills/product/WORKFLOW.md](skills/product/WORKFLOW.md) | Full idea → App Store workflow |
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
| `test-generator` | Unit/UI test templates |
| `accessibility-generator` | VoiceOver, Dynamic Type |
| `widget-generator` | WidgetKit boilerplate |
| `feature-flags` | Local/remote feature flags |

## App Store Optimization (ASO) Skills

Comprehensive ASO toolkit based on real indie developer strategies:

| Skill | What It Does |
|-------|--------------|
| `keyword-optimizer` | Find high-traffic, low-competition keywords |
| `app-description-writer` | Compelling descriptions that convert |
| `screenshot-planner` | Screenshot sequences with keyword-rich captions |
| `review-response-writer` | Professional review responses |

### Keyword Optimizer Features

- **Keyword Criteria** - Pop >20, Diff <60 sweet spot scoring
- **Advanced Tactics** - Cross-localization (2x keywords), screenshot text indexing (June 2025), velocity boost
- **Existing App Strategy** - Safe optimization without losing traffic
- **Opportunity Scoring** - Grade keywords A+ to F

**Example:** *"Help me optimize ASO for my expense splitting app"*

## Security Skill

Comprehensive security guidance for iOS, macOS, and watchOS:

| Topic | What's Covered |
|-------|----------------|
| **Secure Storage** | Keychain patterns, Data Protection classes, Secure Enclave |
| **Biometric Auth** | Face ID, Touch ID, LAContext, SwiftUI integration |
| **Network Security** | App Transport Security, certificate pinning, TLS |
| **Platform Specifics** | iOS jailbreak detection, macOS sandbox/hardened runtime, watchOS HealthKit |

**Example:** *"Review security in my app"* or *"How do I store API tokens securely?"*

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License - see [LICENSE](LICENSE).

## Author

**Ravishankar** - [@rshankras](https://github.com/rshankras)
