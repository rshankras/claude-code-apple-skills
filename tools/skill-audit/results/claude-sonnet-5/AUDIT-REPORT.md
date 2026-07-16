# Blind-Test Skill Audit — claude-sonnet-5 — 2026-07-16

Harness v1 · 161 entries (92 Track A, 69 Track B, 0 routers skipped) · isolation preflight: PASS

Scope: complements the structural auditor (skills/shared/skill-auditor, C-01…L-03) and the
CI tripwires (check-freshness.sh, check-api-symbols.sh). This report judges CONTENT
redundancy/staleness only. Track B (generators + spec-document skills) can never emit
DELETE — templates are not assessed here (compilability is owned by check-swift-templates.sh).
**Nothing is deleted without human approval of the rows below.**

## Summary

| Verdict | Count |
|---|---|
| DELETE-candidate | 1 |
| TRIM | 1 |

## app-store

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| app-store/ad-attribution | A | — not run — | | | | |
| app-store/app-description-writer | A | — not run — | | | | |
| app-store/apple-search-ads | A | — not run — | | | | |
| app-store/iap-finalizer | A | — not run — | | | | |
| app-store/keyword-optimizer | A | — not run — | | | | |
| app-store/marketing-strategy | A | — not run — | | | | |
| app-store/originality-check | A | — not run — | | | | |
| app-store/ratings-mechanics | A | — not run — | | | | |
| app-store/rejection-handler | A | — not run — | | | | |
| app-store/review-response-writer | A | — not run — | | | | |
| app-store/screenshot-planner | A | — not run — | | | | |
| app-store/web-presence | A | — not run — | | | | |

## apple-intelligence

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| apple-intelligence/app-intents | A | — not run — | | | | |
| apple-intelligence/foundation-models | A | — not run — | | | | |
| apple-intelligence/visual-intelligence | A | — not run — | | | | |

## core-ml

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| core-ml | A | — not run — | | | | |

## design

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| design/animation-patterns | A | — not run — | | | | |
| design/design-principles | A | — not run — | | | | |
| design/liquid-glass | A | — not run — | | | | |
| design/sf-symbols | A | — not run — | | | | |
| design/typography | A | — not run — | | | | |
| design/ui-prototyping | A | — not run — | | | | |
| design/ux-writing | A | — not run — | | | | |

## foundation

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| foundation/attributed-string | A | — not run — | | | | |

## generators

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| generators/accessibility-generator | B | — not run — | | | | |
| generators/account-deletion | B | — not run — | | | | |
| generators/analytics-setup | B | — not run — | | | | |
| generators/announcement-banner | B | — not run — | | | | |
| generators/app-clip | B | — not run — | | | | |
| generators/app-extensions | B | — not run — | | | | |
| generators/app-icon-generator | B | — not run — | | | | |
| generators/app-store-assets | B | — not run — | | | | |
| generators/auth-flow | B | — not run — | | | | |
| generators/background-processing | B | — not run — | | | | |
| generators/ci-cd-setup | B | — not run — | | | | |
| generators/cloudkit-sync | B | — not run — | | | | |
| generators/consent-flow | B | — not run — | | | | |
| generators/custom-product-pages | B | — not run — | | | | |
| generators/data-export | B | — not run — | | | | |
| generators/debug-menu | B | — not run — | | | | |
| generators/deep-linking | B | — not run — | | | | |
| generators/error-monitoring | B | — not run — | | | | |
| generators/feature-flags | B | — not run — | | | | |
| generators/featuring-nomination | B | — not run — | | | | |
| generators/feedback-form | B | — not run — | | | | |
| generators/force-update | B | — not run — | | | | |
| generators/http-cache | B | — not run — | | | | |
| generators/image-loading | B | — not run — | | | | |
| generators/in-app-events | B | — not run — | | | | |
| generators/lapsed-user | B | — not run — | | | | |
| generators/live-activity-generator | B | — not run — | | | | |
| generators/localization-setup | B | — not run — | | | | |
| generators/logging-setup | B | — not run — | | | | |
| generators/milestone-celebration | B | — not run — | | | | |
| generators/networking-layer | B | — not run — | | | | |
| generators/offer-codes-setup | B | — not run — | | | | |
| generators/offline-queue | B | — not run — | | | | |
| generators/onboarding-generator | B | — not run — | | | | |
| generators/pagination | B | — not run — | | | | |
| generators/paywall-generator | B | — not run — | | | | |
| generators/permission-priming | B | — not run — | | | | |
| generators/persistence-setup | B | — not run — | | | | |
| generators/pre-orders | B | — not run — | | | | |
| generators/preview-data-generator | B | — not run — | | | | |
| generators/product-page-optimization | B | — not run — | | | | |
| generators/promoted-iap | B | — not run — | | | | |
| generators/push-notifications | B | — not run — | | | | |
| generators/quick-win-session | B | — not run — | | | | |
| generators/referral-system | B | — not run — | | | | |
| generators/review-prompt | B | — not run — | | | | |
| generators/screenshot-automation | B | — not run — | | | | |
| generators/settings-screen | B | — not run — | | | | |
| generators/share-card | B | — not run — | | | | |
| generators/social-export | B | — not run — | | | | |
| generators/spotlight-indexing | B | — not run — | | | | |
| generators/state-restoration | B | — not run — | | | | |
| generators/streak-tracker | B | — not run — | | | | |
| generators/subscription-lifecycle | B | — not run — | | | | |
| generators/subscription-offers | B | — not run — | | | | |
| generators/test-generator | B | — not run — | | | | |
| generators/tipkit-generator | B | — not run — | | | | |
| generators/usage-insights | B | — not run — | | | | |
| generators/variable-rewards | B | — not run — | | | | |
| generators/watermark-engine | B | — not run — | | | | |
| generators/whats-new | B | — not run — | | | | |
| generators/widget-generator | B | — not run — | | | | |
| generators/win-back-offers | B | — not run — | | | | |

## growth

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| growth/analytics-interpretation | A | — not run — | | | | |
| growth/community-building | A | — not run — | | | | |
| growth/indie-business | A | — not run — | | | | |
| growth/press-media | A | — not run — | | | | |
| growth/store-growth-audit | A | — not run — | | | | |
| growth/store-signals | A | — not run — | | | | |

## ios

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| ios/accessibility-audit | A | — not run — | | | | |
| ios/app-planner | A | — not run — | | | | |
| ios/assistive-access | A | — not run — | | | | |
| ios/coding-best-practices | A | — not run — | | | | |
| ios/ipad-patterns | A | — not run — | | | | |
| ios/migration-patterns | A | — not run — | | | | |
| ios/navigation-patterns | A | — not run — | | | | |
| ios/run-device | A | — not run — | | | | |
| ios/run-simulator | A | — not run — | | | | |
| ios/ui-review | A | — not run — | | | | |

## legal

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| legal/privacy-policy | A | — not run — | | | | |
| legal/privacy-publish | A | — not run — | | | | |

## macos

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| macos/app-planner | A | — not run — | | | | |
| macos/appkit-swiftui-bridge | A | — not run — | | | | |
| macos/architecture-patterns | A | — not run — | | | | |
| macos/coding-best-practices | A | — not run — | | | | |
| macos/macos-capabilities | A | — not run — | | | | |
| macos/macos-tahoe-apis | A | — not run — | | | | |
| macos/swiftdata-architecture | A | — not run — | | | | |
| macos/ui-review-tahoe | A | — not run — | | | | |

## mapkit

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| mapkit/geotoolbox | A | — not run — | | | | |

## monetization

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| monetization | A | — not run — | | | | |
| monetization/bundles-and-licensing | A | — not run — | | | | |
| monetization/external-purchases | A | — not run — | | | | |

## performance

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| performance/profiling | A | — not run — | | | | |
| performance/swiftui-debugging | A | — not run — | | | | |

## product

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| product/app-namer | A | — not run — | | | | |
| product/architecture-spec | B | — not run — | | | | |
| product/beta-testing | A | — not run — | | | | |
| product/competitive-analysis | A | — not run — | | | | |
| product/idea-generator | A | — not run — | | | | |
| product/implementation-guide | B | — not run — | | | | |
| product/implementation-spec | B | — not run — | | | | |
| product/localization-strategy | A | — not run — | | | | |
| product/market-research | A | — not run — | | | | |
| product/prd-generator | A | — not run — | | | | |
| product/product-agent | A | — not run — | | | | |
| product/release-spec | B | — not run — | | | | |
| product/test-spec | B | — not run — | | | | |
| product/ux-spec | B | — not run — | | | | |

## release-review

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| release-review | A | — not run — | | | | |

## security

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| security | A | DELETE-candidate | 0.86 | — | bare model covered 0.86 of claims with no contradictions | swiftship-referenced |
| security/privacy-manifests | A | TRIM | 0.79 | q4 | coverage 0.79; keep only the missed deltas | human-review:borderline, human-review:unverified-suspect |

## shared

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| shared/skill-auditor | A | — not run — | | | | |
| shared/skill-creator | A | — not run — | | | | |

## swift

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| swift/concurrency | A | — not run — | | | | |
| swift/concurrency-patterns | A | — not run — | | | | |
| swift/memory | A | — not run — | | | | |

## swiftdata

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| swiftdata/inheritance | A | — not run — | | | | |

## swiftui

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| swiftui/alarmkit | A | — not run — | | | | |
| swiftui/charts-3d | A | — not run — | | | | |
| swiftui/data-flow | A | — not run — | | | | |
| swiftui/layout | A | — not run — | | | | |
| swiftui/text-editing | A | — not run — | | | | |
| swiftui/toolbars | A | — not run — | | | | |
| swiftui/webkit | A | — not run — | | | | |

## testing

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| testing/characterization-test-generator | A | — not run — | | | | |
| testing/flow-walkthrough | A | — not run — | | | | |
| testing/integration-test-scaffold | A | — not run — | | | | |
| testing/snapshot-test-setup | A | — not run — | | | | |
| testing/tdd-bug-fix | A | — not run — | | | | |
| testing/tdd-feature | A | — not run — | | | | |
| testing/tdd-refactor-guard | A | — not run — | | | | |
| testing/test-contract | A | — not run — | | | | |
| testing/test-data-factory | A | — not run — | | | | |

## visionos

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| visionos/spatial-design | A | — not run — | | | | |
| visionos/widgets | A | — not run — | | | | |

## watchos

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| watchos | A | — not run — | | | | |

## Appendix A — FIX detail

## Appendix B — DELETE dossiers (the rows requiring human approval)

### security
- ⚠️ referenced by SwiftShip: commands/help.md, commands/release.md, commands/build.md, commands/submit.md, commands/plan.md, commands/review.md, commands/security.md, CLAUDE.md — deletion blocked until paired
- covered: Omitting NSFaceIDUsageDescription from Info.plist causes the app to crash when Face ID is requested.
  - evidence: “The app doesn't get a graceful denial — it crashes at runtime.”
- ungradable: Avoid the .biometryAny access control flag since it's too permissive (works even after new biometric enrollment); prefer
  - evidence: “Avoid `.biometryAny` for high-security items. It lets the Keychain item remain accessible after the enrolled biometrics ”
- covered: App Transport Security's default behavior requires HTTPS with TLS 1.2 or later.
  - evidence: “ATS requires a minimum of **TLS 1.2** by default”
- partial: Setting NSAllowsArbitraryLoads to disable ATS entirely will likely cause App Store rejection and exposes users to MITM a
  - evidence: “it (a) requires written justification in App Store Connect that reviewers scrutinize and can reject, and (b) genuinely w”
- ungradable: Certificate pinning is recommended as Required for banking/financial and healthcare apps, strongly recommended for apps 
  - evidence: “Healthcare data app: Yes, strongly consider it. ... App that just calls third-party APIs ... Usually not worth it, and c”
- covered: Public key pinning is preferred over certificate pinning because it survives certificate rotation better.
  - evidence: “Public key (SPKI) pinning is more robust, for one concrete reason: key reuse across cert renewal.”
- ungradable: kSecAttrAccessibleWhenUnlockedThisDeviceOnly is recommended for most Keychain use cases because it is not included in de
  - evidence: “kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly is the standard recommendation for auth tokens... If your token truly o”
- covered: kSecAttrAccessibleAlways should never be used for Keychain items because it is deprecated and insecure.
  - evidence: “Deprecated/insecure constant to avoid: kSecAttrAccessibleAlways (and its kSecAttrAccessibleAlwaysThisDeviceOnly variant)”
- partial: watchOS Keychain items are not automatically shared with a paired iPhone; Watch Connectivity must be used to sync creden
  - evidence: “No, not automatically. Keychain items only propagate off-device via iCloud Keychain, which requires (a) the item explici”
- covered: Secure Enclave signing keys are generated using kSecAttrKeyTypeECSECPrimeRandom with a key size of 256 bits.
  - evidence: “kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom
kSecAttrKeySizeInBits: 256”
- partial: A sample app-lock pattern re-locks the app after 60 seconds in the background.
  - evidence: “Moderate sensitivity (enterprise/MDM-managed apps): 30s–5min is typical; many MDM profiles default to 1–2 min.”
- covered: A sample replay-attack prevention scheme treats signed requests as expired after a 5-minute (300 second) window.
  - evidence: “60–300 seconds is the typical tolerance band”
- covered: Jailbreak detection can be bypassed by determined attackers and should be used only as defense-in-depth, not the sole pr
  - evidence: “Low. Treat it as a speed bump / telemetry signal, never a control gating access to secrets or as your sole security boun”
- covered: On macOS 10.15+, kSecUseDataProtectionKeychain can be set to true to get iOS-like Keychain behavior.
  - evidence: “Set kSecUseDataProtectionKeychain: kCFBooleanTrue in every SecItemAdd/SecItemCopyMatching/SecItemUpdate/SecItemDelete qu”

## Appendix C — errors / truncations

