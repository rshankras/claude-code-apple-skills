# Claude Code Skills for Apple Platform Development

A collection of Claude Code skills for iOS, macOS, watchOS, visionOS, and Apple platform development. These skills help you plan and build apps, maintain code quality, ensure HIG compliance, and guide you from idea to App Store.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Part of the indie Apple developer stack

Four repos, four layers — use one or all:

| Layer | Repo | What it is |
|---|---|---|
| Knowledge | **claude-code-apple-skills** ← you are here | 160 skills — how to build right |
| Workflow | [SwiftShip](https://github.com/rshankras/SwiftShip) | 51 /apple:* commands — spec-driven idea → App Store |
| Action | [indie-app-autopilot](https://github.com/rshankras/indie-app-autopilot) | 7 agents — GitHub issue → App Store |
| Integration | [asc-metadata-mcp](https://github.com/rshankras/asc-metadata-mcp) | 65+ MCP tools — live App Store Connect API |

## What's Included

| Category | Skills | Purpose |
|----------|--------|---------|
| **Generators** | 63 | Production-ready code for common features |
| **Product** | 14 | Idea discovery to App Store workflow |
| **iOS** | 9 | Code review, UI review, navigation, iPad, migration, accessibility, simulator/device runs |
| **Testing** | 9 | TDD workflows, test infrastructure, snapshot tests, flow walkthrough |
| **macOS** | 8 | Tahoe APIs, SwiftData, AppKit bridge |
| **App Store** | 12 | ASO, descriptions, keywords, reviews, search ads, ad attribution, rejections, originality, IAP finalize, ratings mechanics, web presence |
| **SwiftUI** | 7 | Data flow, layout & containers, AlarmKit, WebKit, text editing, toolbars, Charts 3D |
| **Growth** | 6 | Analytics, store signals, growth audit, press/media, community, indie business |
| **Swift** | 3 | Concurrency patterns, Swift 6.2, InlineArray/Span |
| **Apple Intelligence** | 3 | Foundation Models, Visual Intelligence, App Intents |
| **Design** | 7 | Liquid Glass, animation patterns, UI prototyping, design principles, UX writing, SF Symbols, typography |
| **Performance** | 2 | Instruments profiling, SwiftUI debugging |
| **Security** | 2 | Secure storage, biometrics, privacy manifests |
| **Core ML** | 1 | Vision, NaturalLanguage, model integration |
| **Legal** | 2 | Privacy policies, terms of service, EULAs, publish + set ASC URLs |
| **Monetization** | 3 | Pricing strategy, tiers, free trials, external purchases, bundles & licensing |
| **watchOS** | 1 | Watch apps, complications, health/fitness, widgets |
| **SwiftData** | 1 | Class inheritance patterns |
| **MapKit** | 1 | GeoToolbox, place descriptors |
| **Foundation** | 1 | AttributedString updates |
| **visionOS** | 2 | Spatial design, widget development |
| **Release Review** | 1 | Pre-release audit checklists |
| **Shared** | 2 | Meta-skills for creating (`skill-creator`) and auditing (`skill-auditor`) skills |

**Total: 160 skills across 23 categories** (single-skill categories count their category file; other index files aren't counted — enforced by `scripts/check-counts.sh` in CI)

## Quick Start

### How to Use

**No idea yet?** Say: *"I don't know what to build"*

**New app?** Say: *"I have an idea for a macOS app that does X. Should I build it?"*

**Existing app?** Say: *"Review my code"* or *"Add [feature]"*

See **[docs/USAGE.md](docs/USAGE.md)** for complete guide.

### Install as a Plugin (recommended)

In Claude Code:

```
/plugin marketplace add rshankras/claude-code-apple-skills
/plugin install apple-skills@indie-apple-stack
```

This surfaces the library as 23 category skills (`/apple-skills:generators`,
`/apple-skills:testing`, ...); each category skill routes to its sub-skills on
demand, so only 23 short descriptions sit in context. Update any time with
`/plugin marketplace update indie-apple-stack` — no version pinning, you
always track `main`.

Want the full workflow too? The same marketplace carries
[SwiftShip](https://github.com/rshankras/SwiftShip)'s 49 `/apple:*` commands:

```
/plugin install apple@indie-apple-stack
```

### Manual Install (copy)

```bash
# Clone
git clone https://github.com/rshankras/claude-code-apple-skills.git

# Copy to your project
cp -r claude-code-apple-skills/skills your-project/.claude/skills/

# Or install globally
cp -r claude-code-apple-skills/skills ~/.claude/skills/
```

### Pinning and rollback

Plugin installs track `main` with no version pinning. If you need a stable
snapshot, annotated era tags mark each WWDC content boundary (see
[CHANGELOG.md](CHANGELOG.md)): `git clone --branch wwdc25-era-final https://github.com/rshankras/claude-code-apple-skills.git` and copy `skills/` manually as above.

## Directory Structure

```
skills/
├── ios/                    # iOS code review, UI review, planning, navigation, iPad, migration, accessibility, device runs (CLI)
├── macos/                  # macOS patterns, Tahoe APIs, SwiftData
├── product/                # Idea to App Store workflow (14 skills)
├── generators/             # Code generators (63 skills)
│   ├── logging-setup/
│   ├── analytics-setup/
│   ├── networking-layer/
│   ├── auth-flow/
│   ├── paywall-generator/
│   ├── background-processing/
│   ├── app-extensions/
│   ├── data-export/
│   └── ... (63 total)
├── growth/                 # Growth audit, analytics, store signals, press/media, community, indie business (6 skills)
├── legal/                  # Privacy policies, terms of service, EULAs
├── core-ml/                # Vision, NaturalLanguage, model integration
├── swiftui/                # Data flow, layout & containers, AlarmKit, WebKit, text editing, toolbars, Charts 3D (7 skills)
├── apple-intelligence/     # Foundation Models, Visual Intelligence, App Intents
├── design/                 # Liquid Glass, animation patterns, UI prototyping, design principles, UX writing, SF Symbols, typography (7 skills)
├── performance/            # Instruments profiling, SwiftUI debugging
├── security/               # Keychain, biometrics, network security, privacy manifests
├── swift/                  # Concurrency patterns, Swift 6.2, InlineArray/Span
├── swiftdata/              # Class inheritance patterns
├── mapkit/                 # GeoToolbox, place descriptors
├── foundation/             # AttributedString updates
├── visionos/               # Spatial design (ergonomics, comfort, environments), widgets (2 skills)
├── testing/                # TDD workflows, test infrastructure, snapshot tests, flow walkthrough (9 skills)
├── monetization/           # Pricing strategy, tiers, free trials, external purchases, bundles & licensing (3 skills)
├── app-store/              # ASO, descriptions, screenshots, reviews, search ads, ad attribution, rejections, originality, IAP finalize, ratings, web presence (12 skills)
├── watchos/                # Watch apps, complications, health/fitness, widgets
├── release-review/         # Security, privacy, UX, distribution audits
├── shared/                 # Meta-skills: skill-creator, skill-auditor
└── _shared/                # Internal helpers, not skills (asc-api — ASC REST helper used by iap-finalizer & privacy-publish)
```

## Documentation

| Doc | Description |
|-----|-------------|
| [docs/USAGE.md](docs/USAGE.md) | How to use for new vs existing apps |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Skills roadmap and status |
| [CHANGELOG.md](CHANGELOG.md) | Notable changes and era tags (pinning/rollback points) |
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
| `preview-data-generator` | SwiftUI preview sample data + state/appearance variant matrix |
| `accessibility-generator` | VoiceOver, Dynamic Type |
| `widget-generator` | WidgetKit widgets with templates |
| `feature-flags` | Local/remote feature flags with templates |
| `app-icon-generator` | Placeholder app icons + layered source for Icon Composer (Liquid Glass) |
| `live-activity-generator` | ActivityKit Live Activities + Dynamic Island |
| `tipkit-generator` | TipKit inline/popover tips |
| `cloudkit-sync` | CKSyncEngine CloudKit sync |
| `http-cache` | HTTP response caching with ETag/offline |
| `pagination` | Offset/cursor pagination + infinite scroll |
| `image-loading` | Image pipeline with cache + CachedAsyncImage |
| `share-card` | Shareable image cards for social media |
| `social-export` | Export to Instagram, TikTok, X with correct formats |
| `subscription-lifecycle` | StoreKit 2 grace periods, billing retry, win-back |
| `referral-system` | Referral codes, deep link sharing, reward tracking |
| `watermark-engine` | Image watermarks with paywall removal |
| `streak-tracker` | Daily streaks with freezes and notifications |
| `milestone-celebration` | Confetti, badges, and achievement celebrations |
| `whats-new` | What's New screen after app updates |
| `lapsed-user` | Lapsed user detection and re-engagement |
| `usage-insights` | User-facing stats, recaps, activity dashboards |
| `variable-rewards` | Daily spins, mystery boxes, gamification rewards |
| `consent-flow` | GDPR/CCPA consent with ATT integration |
| `account-deletion` | Apple-compliant account deletion flow |
| `permission-priming` | Pre-permission screens for higher grant rates |
| `force-update` | Minimum version enforcement with update prompts |
| `state-restoration` | Navigation, tab, scroll position persistence |
| `debug-menu` | Developer debug menu (DEBUG builds only) |
| `offline-queue` | Offline operation queue with automatic retry |
| `feedback-form` | In-app feedback with screenshots and routing |
| `announcement-banner` | In-app banners with remote configuration |
| `quick-win-session` | Guided first-action flows for retention |
| `spotlight-indexing` | Core Spotlight indexing for system search |
| `app-clip` | App Clip target with invocation handling |
| `screenshot-automation` | Automated App Store screenshot generation |
| `background-processing` | BGTaskScheduler, background downloads, silent push |
| `app-extensions` | Share, Action, Keyboard, Safari extensions |
| `data-export` | JSON/CSV/PDF export, GDPR data portability |
| `subscription-offers` | StoreKit 2 intro, promotional, and win-back offers |
| `win-back-offers` | Win-back flow for churned subscribers via StoreKit Messages |
| `promoted-iap` | Promoted In-App Purchases on the App Store product page |
| `offer-codes-setup` | Offer code distribution for partner/influencer campaigns |
| `pre-orders` | App Store pre-order setup and launch timeline |
| `in-app-events` | In-App Event metadata for App Store Connect |
| `custom-product-pages` | Custom Product Page variants for targeted campaigns |
| `product-page-optimization` | A/B test plans for icon, screenshots, previews |
| `featuring-nomination` | App Store editorial featuring nomination pitches |
| `app-store-assets` | Asset specs for all App Store promotional artwork |

## Growth Skills

| Skill | What It Does |
|-------|--------------|
| `analytics-interpretation` | Interpret app metrics, AARRR funnels, decision trees |
| `store-growth-audit` | Stage-by-stage audit of an app's growth machinery — 54 levers (P0–P9), each detected via ASC/codebase evidence and routed to its fix (read-only ASC) |
| `store-signals` | Turn live reviews/analytics/sales/crashes into a metric-tagged backlog + verify last cycle (read-only ASC) |
| `press-media` | Press kit, journalist outreach, pitch templates |
| `community-building` | Social media, building in public, content strategy |
| `indie-business` | Business entity, taxes, revenue, hiring |

## Legal Skills

| Skill | What It Does |
|-------|--------------|
| `privacy-policy` | Privacy policies, Terms of Service, EULAs |
| `privacy-publish` | Host legal pages + set ASC privacy/support URLs (dry-run) |

## Core ML Skills

| Skill | What It Does |
|-------|--------------|
| `core-ml` | Vision, NaturalLanguage, model integration, Core ML vs Foundation Models |

## Testing & TDD Skills

| Skill | What It Does |
|-------|--------------|
| `characterization-test-generator` | Capture existing behavior before AI refactoring |
| `tdd-bug-fix` | Reproduce bug as failing test, then fix |
| `tdd-feature` | Red-green-refactor for new features |
| `test-contract` | Protocol test suites any implementation must pass |
| `tdd-refactor-guard` | Pre-refactor safety gate (verify coverage first) |
| `snapshot-test-setup` | SwiftUI visual regression with swift-snapshot-testing |
| `test-data-factory` | Factory/fixture helpers for test data |
| `integration-test-scaffold` | Cross-module test harness with mock server |
| `flow-walkthrough` | Drive user flows (XCUITest + screenshots), audit the nav graph for dead-ends |

## Monetization

| Skill | What It Does |
|-------|--------------|
| `monetization` | Readiness assessment, pricing model selection, tier structure, free trial strategy |
| `external-purchases` | US web checkout via the External Purchase Link entitlement — 0%-commission era, commission-flip architecture |
| `bundles-and-licensing` | Own-app bundles, Family Sharing, cross-developer suites, Group/Volume Purchasing (announced) |

## Design Skills

| Skill | What It Covers |
|-------|----------------|
| `design/liquid-glass` | Liquid Glass implementation + design rules (SwiftUI/AppKit/UIKit, never glass-on-glass, Regular vs Clear) |
| `design/animation-patterns` | Springs, PhaseAnimator/KeyframeAnimator, transitions (incl. zoom + interruptibility), symbol effects |
| `design/ui-prototyping` | Divergent UI directions as named #Preview variants — go wide, remix, tune |
| `design/design-principles` | The evergreen canon: wayfinding, discoverability, fluid-gesture physics, idea→interface process |
| `design/ux-writing` | Interface copy: PACE framework, voice/tone, alert anatomy, feature naming |
| `design/sf-symbols` | Choosing/configuring symbols, custom-symbol authoring, animation vocabulary |
| `design/typography` | Text styles, Dynamic Type, optical sizes, the SF family + width axis |

## visionOS Skills

| Skill | What It Covers |
|-------|----------------|
| `visionos/spatial-design` | Spatial layout ergonomics, eyes-and-hands input, motion comfort, immersion, environment budgets |
| `visionos/widgets` | Mounting styles, glass/paper textures, proximity-aware layouts, spatial families |

## SwiftUI Skills

| Skill | What It Covers |
|-------|----------------|
| `swiftui/data-flow` | View identity/lifetime/dependencies (the Demystify canon), Observation, state ownership, concurrency contract |
| `swiftui/layout` | Layout protocol, custom containers, lazy-stack + scrolling performance rules |
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

## App Store Skills

| Skill | What It Does |
|-------|--------------|
| `keyword-optimizer` | Find high-traffic, low-competition keywords |
| `app-description-writer` | Compelling descriptions that convert |
| `screenshot-planner` | Screenshot sequences with keyword-rich captions |
| `review-response-writer` | Professional review responses |
| `apple-search-ads` | Search Ads campaign setup, keyword bidding, ROAS |
| `ad-attribution` | AdAttributionKit install + re-engagement measurement, conversion-value strategy, postback testing |
| `rejection-handler` | Handle rejections, response templates, appeals |
| `originality-check` | Guideline-4.3 anti-spam gate: function/content/metadata distinctness before build or submit |
| `iap-finalizer` | Finalize one-time IAP price + localization in ASC (dry-run) |
| `ratings-mechanics` | Per-storefront ratings isolation, never-reset rule, phased + manual release as rating armor |
| `web-presence` | apps.apple.com SEO, landing page + Smart App Banner, deal-site price-drop ecosystem |
| `marketing-strategy` | Comprehensive promotional strategy |

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
