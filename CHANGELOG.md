# Changelog

This repo has no version numbers by design: `plugin.json` is deliberately
versionless (git-SHA versioning — every commit to `main` is a release), and
plugin installs always track `main`. This file groups the notable changes so
you can see what moved without reading `git log`, and **annotated era tags**
mark the content boundary before each year's post-WWDC refresh:

| Tag | Meaning |
|-----|---------|
| `wwdc25-era-final` | Last commit of the iOS 26 / WWDC25 content era |

Era tags are contractual reference points — they are never moved or deleted.
To pin to one: `git clone --branch wwdc25-era-final <repo-url>` and install
from the local copy (see "Pinning and rollback" in the README).

## [Unreleased]

### Added
- SwiftUI practice harvest from 24 Apple sessions (WWDC20–26): two new skills — `swiftui/data-flow` (the Demystify canon: structural/explicit identity, the inert-modifier rule, lifetime = identity, ForEach ID rules, Observation's per-property tracking, state-ownership decision table, body discipline, the WWDC25 main-actor contract, the WWDC26 @State lazy-init macro) and `swiftui/layout` (Layout protocol vs GeometryReader, spacing preferences, custom containers with sections + @Entry container values, the WWDC26 lazy-stack rulebook: one-subview-per-element, init-not-onAppear prefetch, hoisted state, the scroll API map) — SwiftUI 5 → 7, total 158 → 160; plus enrichment: animation-patterns (Animatable mechanics, TransactionKey, phase-vs-keyframe decision, scrollTransition/visualEffect/TextRenderer/shaders/MeshGradient), charts-3d (2D Swift Charts construction reference), navigation-patterns (the three navigation recipes + id-only state restoration), ios/macos coding-best-practices (modern SwiftUI baseline from the What's-new sweeps), swiftui-debugging (Demystify-performance workflow), ui-prototyping (real-data + on-device demo practices)
- Spatial/watch design harvest from 22 more Apple sessions (WWDC20–26): new skill `visionos/spatial-design` (+ `immersive-environments.md`) — layout ergonomics (60pt eye targets, dynamic scale, ≤6 tab items, 20pt ornament overlap), eyes-and-hands input + hover rules (5% scale, 0.8s/0.2s reveal delays), motion comfort (0.2 Hz oscillation rule, vection, depth-cue agreement), immersion strategy, spatial sound, video-format decision guide, and environment production budgets (<200k triangles, <100 draw calls, <250 MB textures, 1 km billboard threshold) — visionOS 1 → 2, total 157 → 158; plus watch/widget enrichment: watchos (10-second attention budget, Dial/Infographic/List layouts, vertical pagination, Source List pattern, More-button spec), widgets-for-watch (six Smart Stack layouts, five relevancy signals, session widgets), visionos/widgets (75–125% resize, frame/tinting rules, Default/Simplified proximity states), live-activity-generator (watch Smart Stack auto-generation, one-control rule)
- Design harvest from 38 Apple design sessions (WWDC17–WWDC26): four new skills — `design/design-principles` (wayfinding, the five WWDC26 principles, fluid-gesture physics, discoverability, idea→interface process), `design/ux-writing` (PACE framework, voice/tone, alert anatomy, Think/Feel/Do feature naming, the four small edits), `design/sf-symbols` (rendering modes, variable color/draw, custom-symbol authoring with 3-source interpolation, animation vocabulary), `design/typography` (text styles, optical sizes 17–28pt, the SF width axis, tracking vs kerning, custom-font scaling) — Design 3 → 7, total 153 → 157
- Design-session specifics folded into 14 existing skills: liquid-glass (never glass-on-glass, Regular vs Clear rules, shape system, GlassEffectContainer sampling), ui-prototyping (WWDC26 agent workflow: go wide/remix/repeat, tuning panels), animation-patterns (zoom transitions, interruptibility rules, gesture-driven springs), ios/navigation-patterns (no catch-all Home tab, modal rules), ios/ui-review (search-UX + menus/pickers checklists), ios/ipad-patterns (windowing, pointer, menu rules), app-icon-generator (Icon Composer workflow, layered material rules, squint/folder tests), widget-generator (4-info small-widget cap, 16/11pt margins), live-activity-generator (14pt margins, Dynamic Island concentricity, no forehead), app-intents (App Shortcuts 2–5 quality cap, intent-design rules, 340pt snippets), tipkit-generator (eligibility rules, invalidate-on-action), push-notifications (provisional auth, never-prompt-at-launch, trust patterns), charts-3d (marks by goal, zero-based bars, non-visual encoding), accessibility-generator (4.5:1 floor, full UIAccessibility API sweep, 1-in-7 inclusive principles)
- `app-store/ad-attribution` — AdAttributionKit install + re-engagement measurement: conversion-value strategy under crowd anonymity (fine 0–63 / coarse, first-2-digit source encoding), conversion tags, attribution windows/cooldowns, Developer Mode postback rehearsal; notes the AdServices seam for Apple Ads
- Apple-transcript harvest across ~20 growth skills — best practices, exact limits, and Apple's own numbers from 26 WWDC/Tech Talk sessions folded into: product-page-optimization (test discipline: 3 treatments, 90% confidence, 7-day increments, case-study lifts), custom-product-pages (per-page analytics, keyword→CPP routing, +33%/−14% CPI segmentation data), in-app-events (30/50/120 char budgets, 10/5 limits, badge-fit + deep-link rules), pre-orders (180/365-day regional windows), analytics-interpretation (peer-group mechanics, 25/50/75 bands, payer metrics, benchmark→action map), subscription-lifecycle (3/16/28-day grace with 40/75/90% recovery, 60-day retry, voluntary-churn window, retention compounding), win-back-offers (native eligibility knobs + Retention Messaging mechanics with save-rate data), subscription-offers (trial-length by category/region, 60%-began-with-intro, six churn playbooks), offer-codes-setup (quota table incl. the 1M/quarter ceiling), pricing-models (900 price points, base-storefront rules, price-increase consent mechanics), bundles-and-licensing (Group Purchases live: ≤5 volume bands; Family Sharing implementation rules), paywall-generator (3–4-tap sign-up data), beta-testing (TestFlight limits), keyword-optimizer (App Store Tags curation §15, keyword→CPP routing §16), apple-search-ads, web-presence, marketing-strategy, screenshot-planner (Asset Library / Product Page Header / Search Results visuals)
- `check-counts.sh` now guards **listings**, not just counts: README per-skill tables, category `## Available Skills` indexes, and ROADMAP's category name lists must each name every skill in the tree — the drift class where counts get bumped but names never land is now CI-impossible
- `growth/store-growth-audit`: **Scoped Runs** — audit a single phase (`P3`, or a range like `P1-P3`): evidence batches subset to the scope, only in-scope scorecard rows update, output is the phase worklist instead of the top-5
- `growth/store-growth-audit` — the 54-item P0–P9 store-growth playbook as an auditable checklist (SKILL.md + detection-playbook + two phase checklists); every item scored via ASC MCP read / codebase grep / explicit question, routed to the skill that fixes it; backs SwiftShip's `/apple:growth`
- `app-store/ratings-mechanics` — per-storefront ratings isolation, the never-reset rule, phased + manual release as rating armor
- `app-store/web-presence` — apps.apple.com Google SEO, landing page + Smart App Banner, the deal-site price-drop ecosystem
- `monetization/external-purchases` — US External Purchase Link entitlement (0% commission era), commission-flip architecture, day-one funnel analytics
- `monetization/bundles-and-licensing` — own-app bundles, Family Sharing, cross-developer suites, Group/Volume Purchasing (announced) via School & Business Manager
- Growth-tactic upgrades across 13 existing skills: developer-name indexing, Apple AI tagging, ASA search-term keyword refresh (keyword-optimizer); discovery-as-research, ASA→organic halo, CPP pairing (apple-search-ads); peer-group benchmarks (analytics-interpretation); pre-shipped alternate icons (product-page-optimization); PPP pricing playbook (pricing-models); regional pre-orders; TestFlight public-link waitlist (beta-testing); announced badge types (in-app-events); Retention Messaging (win-back-offers); distribution levers (marketing-strategy); Creative Assets (screenshot-planner); US external-purchase entitlement nuance (rejection-handler, streak-tracker)
- `CHANGELOG.md` and the `wwdc25-era-final` era tag — rollback/reference points for unpinned plugin installs
- `scripts/versions.env` — single source of truth for the current Apple OS generation (bump once per WWDC)
- `scripts/check-freshness.sh` — CI tripwire: fails when a skill claims recency ("Latest", "New in") against an OS version two or more generations old
- `scripts/check-swift-templates.sh` + CI job — every `templates/*.swift` file must parse (`swiftc -parse`)
- App Store Guidelines risk sections in the five engagement-mechanic generators (variable-rewards, streak-tracker, milestone-celebration, watermark-engine, quick-win-session), cross-linked to `app-store/originality-check`

### Changed
- store-growth-audit watchlist graduations, verified against WWDC26 transcripts: P5.3 Creative Assets (Asset Library live, renders on iOS 27), P8.3 Retention Messaging (ASC tier open to all; real-time API access-gated), P8.6 Group/Volume Purchasing (live for StoreKit 2 subs, on by default) — all three moved from ⏳ announced to live detection rules; P1.7 extended with App Store Tags curation, P5.2 with keyword→CPP routing
- skill-auditor known-current constants bumped to the iOS 27 / WWDC26 era; M-02 now defers to `scripts/versions.env` as the normative source
- `scripts/check-counts.sh` now also guards `docs/ROADMAP.md`, `plugin.json`, and `.claude-plugin/marketplace.json` counts

### Fixed
- README gains Design (7) and visionOS (2) per-skill tables, both now covered by the listings guard (README_TABLE_CATS += design visionos)
- Listing drift the new guard exposed: `design`/`legal`/`testing` category indexes were missing ui-prototyping, privacy-publish, flow-walkthrough; ROADMAP name lists were missing 17 skills (the 11 store-feature generators, run-simulator/run-device, app-namer, and the three above) with stale row counts
- README detail drift: the Growth/Monetization/App Store per-skill tables and directory-tree comments were missing the five new skills (only the summary-table counts are CI-guarded)
- Category index drift: `app-store/SKILL.md` and `growth/SKILL.md` "Available Skills" were missing previously added members (iap-finalizer, originality-check, store-signals); `docs/ROADMAP.md` per-category rows for app-store/growth/monetization brought current
- `check-counts.sh` cross-repo check pointed at `commands/apple/` but SwiftShip's commands live at `commands/` — the count guard could never fire; README docs table now lists CHANGELOG.md
- Stale recency claims in paywall-generator, test-spec, live-activity-generator, usage-insights, ci-cd-setup
- `deep-linking/templates/AppShortcuts.swift`: `ContentTypeEntity` declared as `struct` with `case` members — did not parse; now `enum ContentTypeEntity: String, AppEnum`
- `docs/ROADMAP.md` skill total (149 → 147) and stale maintenance bullets

## 2026-04 – 2026-07

### Added
- Plugin-marketplace distribution: `/plugin install apple-skills@indie-apple-stack` (#19), SwiftShip listed in the same marketplace (#20, #21, #22), standalone `plugin.json` for external catalogs (#23)
- `originality-check` + `store-signals` skills (#14)
- ASC-automation skills: `iap-finalizer`, `privacy-publish`, `_shared/asc-api` (#13)

### Changed
- All documented counts synced to reality (147) with `scripts/check-counts.sh` making drift impossible (#17)
- App Annie reference replaced with vendor-neutral app intelligence tools (#25)

### Fixed
- Machine-local paths removed from skills — portable across install types (#18)
- `macos/*/skill.md` renamed to uppercase `SKILL.md` (case-sensitivity bug) (#15)

Earlier history: `git log`.
