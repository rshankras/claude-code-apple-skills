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
- skill-auditor known-current constants bumped to the iOS 27 / WWDC26 era; M-02 now defers to `scripts/versions.env` as the normative source
- `scripts/check-counts.sh` now also guards `docs/ROADMAP.md`, `plugin.json`, and `.claude-plugin/marketplace.json` counts

### Fixed
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
