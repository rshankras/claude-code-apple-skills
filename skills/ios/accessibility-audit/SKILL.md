---
name: accessibility-audit
description: Run a structured accessibility audit on an iOS/macOS app — automated XCUITest audits, Accessibility Inspector, manual VoiceOver/Dynamic Type passes, and App Store Accessibility Nutrition Label evaluation. Use before release, when preparing Nutrition Label declarations, or for EU Accessibility Act compliance.
allowed-tools: [Read, Glob, Grep, Bash]
---

# Accessibility Audit

A repeatable audit workflow that takes an app from "we think it's accessible" to evidence: automated audits in CI, an Inspector pass, manual assistive-tech passes, and an Accessibility Nutrition Label evaluation you can defend. Distilled from Apple's WWDC23 "Perform accessibility audits" (10035), WWDC19 "Accessibility Inspector" (257), WWDC25 "Evaluate your app for Accessibility Nutrition Labels" (224), and the 2026 Tech Talk "Prepare your app for Accessibility Nutrition Labels" (111433).

Why it matters: about **1 in 7 people worldwide** has a disability that affects how they use devices (WWDC23 10035); the **EU Accessibility Act** has applied to consumer apps in the EU market since June 2025; and **Accessibility Nutrition Labels** on the App Store make your support (or its absence) visible before download.

## When This Skill Activates

- User asks for an accessibility audit, review, or compliance check
- User is preparing Accessibility Nutrition Label declarations for App Store Connect
- User asks about `performAccessibilityAudit`, Accessibility Inspector, or automated a11y testing
- User mentions EU Accessibility Act / accessibility compliance
- Pre-release checks (pairs with `release-review`)

## The Audit Workflow

### 1. Define common tasks first (WWDC25 224)

List the primary tasks people download the app for, **plus** the fundamentals: first-launch experience, login, purchase, settings. Every subsequent pass evaluates these tasks, on **every device family the app supports**.

### 2. Automated pass — XCUITest audits in CI

`try app.performAccessibilityAudit()` audits the current view exactly as the Inspector does; the test fails automatically on findings. Full API, audit-type table, issue filtering, and CI patterns: **automated-audits.md**. Baseline rules:

- Audits cover only what's on screen — write one audit per distinct screen/state.
- `continueAfterFailure = true` before the audit to surface all issues in one run.
- Filter *accepted* issues via the issue handler (return `true` to ignore) — never by skipping whole audit types.

### 3. Inspector pass (WWDC19 257)

Xcode → Open Developer Tool → Accessibility Inspector, target the app:

1. **Run Audit** → each finding highlights the view and offers a Help suggestion.
2. Fix, re-run to zero.
3. **Auto Navigate** through the screen with the speaker button — hear exactly what VoiceOver would say, in order; wrong reading order shows up here.
4. **Point Inspection** for spot checks; **Color Contrast Calculator** (Window menu) for failing pairs.

Classic findings and fixes: filename-as-label (give a real `accessibilityLabel`; move technical IDs to `accessibilityIdentifier`), text drawn via `CATextLayer` invisible to VoiceOver (`isAccessibilityElement = true` + label), contrast below threshold (Inspector flags pairs; fix with darker/lighter variants until it passes — 4.5:1 is the floor for body text).

### 4. Manual assistive-tech passes (per common task)

| Pass | How | Pass criterion |
|---|---|---|
| VoiceOver | Swipe right through every element; double-tap to activate; complete each common task eyes-free | Every element speaks label + trait + value; task completable with gestures only |
| Voice Control | Complete tasks by voice only | Every interactive element has a speakable label (`accessibilityInputLabels` for synonyms) |
| Dynamic Type | Test at 200% and at the largest accessibility size (310%) | Text wraps (never truncates), fields grow, layout adapts |
| Sufficient Contrast | Light + dark appearance, with Increase Contrast on | Legible everywhere |
| Dark Interface | Dark mode + Smart Invert | Photos/video NOT inverted (`accessibilityIgnoresInvertColors`) |
| Reduced Motion | Reduce Motion on | Zoom/slide transitions, autoplay, parallax replaced (modified, not just removed) |
| Keyboard (Mac / iPad FKA) | Complete tasks keyboard-only | Focus reaches everything; no hover-only affordances |

### 5. Nutrition Label evaluation and declaration

Map the evidence from passes 2–4 onto the nine App Store features and declare only what holds for **all** common tasks on **all** supported device families. Per-feature criteria, disqualifier examples, and the declaration flow: **nutrition-labels.md**. The model behavior (Apple's own demo): find bugs at 235%/310% text size → **fix first, claim after**. Not applicable (no video content) ≠ supported — leave it unclaimed.

## Output Format

Report findings as:

- 🔴 Critical — blocks an assistive-tech user from completing a common task (unlabeled control on the purchase path, VoiceOver trap, text that doesn't scale)
- 🟠 High — feature claim at risk (truncation at accessibility sizes, color-only state, missing captions)
- 🟡 Medium — friction (bad reading order, unclear labels, missing rotors/actions)
- 🟢 Low — polish (verbosity, missing synonyms, hint quality)
- ✅ Strengths — passes worth keeping (cite the pass that proved them)

For each finding: the screen/task, the failing feature category, the fix (API-level), and which audit pass detects the regression.

## Cross-References

- `generators/accessibility-generator` — implementation patterns (labels, Dynamic Type, custom actions, rotors) to fix what the audit finds
- `macos/ui-review-tahoe/accessibility.md` — Mac-specific VoiceOver/keyboard depth
- `ios/assistive-access` — the separate Assistive Access experience (cognitive disabilities)
- `design/typography` — Dynamic Type design rules
- `release-review` — this audit slots into the pre-release gate

## References

- **automated-audits.md** (this skill) — performAccessibilityAudit API, audit types, CI patterns, Inspector workflow
- **nutrition-labels.md** (this skill) — the nine features, per-feature criteria, evaluation + declaration process
- [WWDC23 — Perform accessibility audits for your app](https://developer.apple.com/videos/play/wwdc2023/10035/)
- [WWDC25 — Evaluate your app for Accessibility Nutrition Labels](https://developer.apple.com/videos/play/wwdc2025/224/)
- [Tech Talk — Prepare your app for Accessibility Nutrition Labels](https://developer.apple.com/videos/play/tech-talks/111433/)
- [Accessibility Nutrition Labels evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)
