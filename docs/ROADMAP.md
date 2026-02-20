# Skills Roadmap

Future skills to be created based on Apple documentation and gap analysis.

## Current Coverage

### Apple Intelligence
| Doc | Skill | Status |
|-----|-------|--------|
| FoundationModels-Using-on-device-LLM-in-your-app.md | `apple-intelligence/foundation-models` | ✅ Complete |
| Implementing-Visual-Intelligence-in-iOS.md | `apple-intelligence/visual-intelligence` | ✅ Complete |

### Design
| Doc | Skill | Status |
|-----|-------|--------|
| SwiftUI-Implementing-Liquid-Glass-Design.md | `design/liquid-glass` | ✅ Complete |
| AppKit-Implementing-Liquid-Glass-Design.md | `design/liquid-glass` | ✅ Complete |
| Animation patterns (springs, transitions, keyframes) | `design/animation-patterns` | ✅ Complete |

### Security
| Topic | Skill | Status |
|-------|-------|--------|
| Secure Storage (Keychain, Data Protection, Secure Enclave) | `security` | ✅ Complete |
| Biometric Auth (Face ID, Touch ID, LAContext) | `security` | ✅ Complete |
| Network Security (ATS, Certificate Pinning, TLS) | `security` | ✅ Complete |
| Platform-Specific Security (iOS, macOS, watchOS) | `security` | ✅ Complete |

---

## Planned Skills

### High Priority

#### Navigation & Architecture (Gap — No Existing Skill)

| Proposed Skill | Description | Why High Priority |
|----------------|-------------|-------------------|
| `ios/navigation-patterns` | NavigationStack, NavigationSplitView, programmatic navigation, TabView, deep linking with navigation | ✅ Complete |
| `swift/concurrency-patterns` | Actor isolation, @Sendable, TaskGroup, AsyncSequence, MainActor, cancellation patterns | ✅ Complete |
| `performance/profiling` | Instruments workflows, Time Profiler, Allocations, hang detection, launch time optimization | ✅ Complete |
| `performance/swiftui-debugging` | View identity, body re-evaluation, `Self._printChanges()`, lazy vs eager loading, view diffing | SwiftUI performance problems are hard to diagnose without these |

#### SwiftUI Features (Doc-Based)

| Doc | Proposed Skill | Description |
|-----|----------------|-------------|
| SwiftUI-AlarmKit-Integration.md | `swiftui/alarmkit` | Alarm and timer functionality |
| SwiftUI-WebKit-Integration.md | `swiftui/webkit` | WebView integration in SwiftUI |
| SwiftUI-Styled-Text-Editing.md | `swiftui/text-editing` | Rich text editing with new APIs |
| SwiftUI-New-Toolbar-Features.md | `swiftui/toolbars` | Modern toolbar patterns |

#### Data Visualization (Doc-Based)

| Doc | Proposed Skill | Description |
|-----|----------------|-------------|
| Swift-Charts-3D-Visualization.md | `swiftui/charts-3d` | 3D chart visualization |

---

### Medium Priority

#### New Generator Skills (Gap — No Existing Skill)

| Proposed Skill | Description | Why Valuable |
|----------------|-------------|--------------|
| `generators/live-activity-generator` | ActivityKit setup, Dynamic Island layouts, push-to-update | Tricky API surface; common feature request |
| `generators/tipkit-generator` | Inline/popover tips, rules, display frequency, invalidation, testing | Deceptively simple API with several gotchas |
| `generators/cloudkit-sync` | CKSyncEngine (iOS 17+), CloudKit sharing, conflict resolution | persistence-setup mentions "optional iCloud" but has no real CloudKit coverage |

#### Migration Guides (Gap — No Existing Skill)

| Proposed Skill | Description | Why Valuable |
|----------------|-------------|--------------|
| `ios/migration-patterns` | CoreData → SwiftData, UIKit → SwiftUI, ObservableObject → @Observable, XCTest → Swift Testing | Developers constantly migrate between framework generations; no coverage |

#### Data & Persistence (Doc-Based)

| Doc | Proposed Skill | Description |
|-----|----------------|-------------|
| SwiftData-Class-Inheritance.md | `swiftdata/inheritance` | Model class inheritance patterns |

#### Swift Language (Doc-Based)

| Doc | Proposed Skill | Description |
|-----|----------------|-------------|
| Swift-Concurrency-Updates.md | `swift/concurrency` | Latest async/await features (complements `swift/concurrency-patterns`) |

#### Frameworks (Doc-Based)

| Doc | Proposed Skill | Description |
|-----|----------------|-------------|
| StoreKit-Updates.md | `generators/paywall-generator` | Update existing skill |
| AppIntents-Updates.md | `apple-intelligence/app-intents` | Siri and Shortcuts updates |
| MapKit-GeoToolbox-PlaceDescriptors.md | `mapkit/geotoolbox` | Location and place features |

---

### Lower Priority

#### Platform Specific (Gap — No Existing Skill)

| Proposed Skill | Description | Why Valuable |
|----------------|-------------|--------------|
| `ios/ipad-patterns` | Stage Manager, multi-window, drag & drop, keyboard shortcuts, pointer interactions | CLAUDE.md mentions iPadOS but zero coverage |

#### Security & Privacy (Gap — Thin Coverage)

| Proposed Skill | Description | Why Valuable |
|----------------|-------------|--------------|
| `security/privacy-manifests` | Privacy manifest format, required reason APIs, third-party SDK declarations, App Tracking Transparency | Required since 2024; release-review touches on privacy but not the manifest mechanics |

#### Existing Skill Improvements (Gap — Incomplete Skills)

| Skill | What's Missing |
|-------|---------------|
| `generators/test-generator` | Update for Swift Testing framework (`@Test`, `#expect`, `@Suite`) alongside XCTest |
| `generators/feature-flags` | No reference files or templates — only a SKILL.md; other generators have full template sets |
| `generators/widget-generator` | No reference files or templates — only a SKILL.md |
| `watchos/` | Only 1 SKILL.md + 1 file; missing sub-skills for complications, WidgetKit for Watch, health/fitness sensors |

#### Platform Specific (Doc-Based)

| Doc | Proposed Skill | Description |
|-----|----------------|-------------|
| Widgets-for-visionOS.md | `visionos/widgets` | visionOS widget development |
| UIKit-Implementing-Liquid-Glass-Design.md | `design/liquid-glass` | Add UIKit section |
| WidgetKit-Implementing-Liquid-Glass-Design.md | `design/liquid-glass` | Add WidgetKit section |

#### Accessibility (Doc-Based)

| Doc | Proposed Skill | Description |
|-----|----------------|-------------|
| Implementing-Assistive-Access-in-iOS.md | `ios/assistive-access` | Accessibility features |

#### Foundation (Doc-Based)

| Doc | Proposed Skill | Description |
|-----|----------------|-------------|
| Foundation-AttributedString-Updates.md | `foundation/attributed-string` | Rich text formatting |
| Swift-InlineArray-Span.md | `swift/memory` | Low-level memory features |

---

## Reference

Apple docs location: `/Users/ravishankar/Downloads/docs/`

### Existing Skills by Category

| Category | Count | Skills |
|----------|-------|--------|
| generators/ | 18 | logging-setup, analytics-setup, networking-layer, auth-flow, paywall-generator, settings-screen, persistence-setup, onboarding-generator, review-prompt, error-monitoring, ci-cd-setup, localization-setup, push-notifications, deep-linking, test-generator, accessibility-generator, widget-generator, feature-flags |
| product/ | 11 | idea-generator, product-agent, competitive-analysis, market-research, prd-generator, architecture-spec, ux-spec, implementation-guide, implementation-spec, test-spec, release-spec |
| macos/ | 8 | app-planner, coding-best-practices, architecture-patterns, swiftdata-architecture, ui-review-tahoe, macos-tahoe-apis, macos-capabilities, appkit-swiftui-bridge |
| app-store/ | 4 | keyword-optimizer, app-description-writer, screenshot-planner, review-response-writer |
| ios/ | 4 | coding-best-practices, ui-review, app-planner, navigation-patterns |
| design/ | 2 | liquid-glass, animation-patterns |
| apple-intelligence/ | 2 | foundation-models, visual-intelligence |
| release-review/ | 1 | release-review |
| security/ | 1 | security |
| watchos/ | 1 | watchos |
| shared/ | 1 | skill-creator |
| performance/ | 1 | profiling |
| swift/ | 1 | concurrency-patterns |
| **Total** | **54** |
