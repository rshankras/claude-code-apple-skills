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
| DELETE-candidate | 5 |
| TRIM | 56 |
| TRIM(prose) | 1 |
| KEEP | 94 |
| FIX | 5 |

## app-store

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| app-store/ad-attribution | A | KEEP | 0.43 | q3,q4,q5 | coverage 0.43; bare model failed: The first re-engagement conversion update must land within 48 hours; Click-through attribution requires calling appImpression.handleTap() w | — |
| app-store/app-description-writer | A | TRIM | 0.79 | q3 | coverage 0.79; keep only the missed deltas | human-review:borderline |
| app-store/apple-search-ads | A | KEEP | 0.46 | q1,q4,q5 | coverage 0.46; bare model failed: All Apple Search Ads placements price as cost-per-tap on a second-pric; Today Tab ads must come from a Custom Product Page with at least 4 por | human-review:borderline, human-review:unclear-contradiction |
| app-store/iap-finalizer | A | TRIM | 0.62 | q1,q5 | coverage 0.62; keep only the missed deltas | workflow-heavy |
| app-store/keyword-optimizer | A | TRIM | 0.54 | q2,q3,q5 | coverage 0.54; keep only the missed deltas | human-review:borderline, human-review:unverified-suspect |
| app-store/marketing-strategy | A | KEEP | 0.43 | q2,q4,q5 | coverage 0.43; bare model failed: Custom Product Pages need roughly 5,000 impressions/month minimum traf; Win-Back Offers are only worth the setup effort once an app has around | human-review:unclear-contradiction, workflow-heavy |
| app-store/originality-check | A | TRIM | 0.58 | q3,q5 | coverage 0.58; keep only the missed deltas | — |
| app-store/ratings-mechanics | A | DELETE-candidate | 0.81 | — | bare model covered 0.81 of claims with no contradictions | human-review:borderline, swiftship-referenced |
| app-store/rejection-handler | A | TRIM | 0.50 | q1,q5 | coverage 0.50; keep only the missed deltas | human-review:borderline, human-review:unclear-contradiction, workflow-heavy |
| app-store/review-response-writer | A | TRIM | 0.50 | q2,q4 | coverage 0.50; keep only the missed deltas | human-review:borderline, human-review:unclear-contradiction, human-review:unverified-suspect |
| app-store/screenshot-planner | A | KEEP | 0.38 | q4,q5 | coverage 0.38; bare model failed: Creative Assets, Product Page Header, and Custom Search Results visual; Assets pre-approved in the Asset Library can update the Product Page H | human-review:unclear-contradiction |
| app-store/web-presence | A | TRIM | 0.68 | q5 | coverage 0.68; keep only the missed deltas | human-review:unclear-contradiction |

## apple-intelligence

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| apple-intelligence/app-intents | A | KEEP | 0.43 | q1,q3,q4,q5 | coverage 0.43; bare model failed: Interactive Siri snippets have a max content height of 340pt; content ; A SnippetIntent's perform() method must never mutate state; mutations  | human-review:unverified-suspect, truncated |
| apple-intelligence/foundation-models | A | KEEP | 0.23 | q2,q3,q4,q5 | coverage 0.23; bare model failed: LanguageModelSession.GenerationError is deprecated at iOS 27 and becom; None of the Foundation Models error enums ever had a .cancelled case i | human-review:unverified-suspect |
| apple-intelligence/visual-intelligence | A | TRIM | 0.50 | q1,q4,q5 | coverage 0.50; keep only the missed deltas | human-review:borderline |

## core-ml

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| core-ml | A | TRIM | 0.70 | q1 | coverage 0.70; keep only the missed deltas | truncated, workflow-heavy |

## design

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| design/animation-patterns | A | TRIM | 0.83 | q2,q5 | coverage 0.83; keep only the missed deltas | human-review:borderline, human-review:unclear-contradiction, truncated |
| design/design-principles | A | DELETE-candidate | 0.96 | — | bare model covered 0.96 of claims with no contradictions | swiftship-referenced |
| design/liquid-glass | A | TRIM | 0.55 | q1,q2,q5 | coverage 0.55; keep only the missed deltas | human-review:borderline, human-review:unclear-contradiction, human-review:unverified-suspect |
| design/sf-symbols | A | KEEP | 0.29 | q2,q3,q4,q5 | coverage 0.29; bare model failed: SF Symbols 7 introduced gradients: a smooth linear gradient generated ; Variable Draw (SF Symbols 7) renders the path at a percentage instead  | human-review:unverified-suspect |
| design/typography | A | TRIM | 0.59 | q5 | coverage 0.59; keep only the missed deltas | — |
| design/ui-prototyping | A | KEEP | 0.42 | q1,q3,q5 | coverage 0.42; bare model failed: Generate 6–10 genuinely divergent variations of a single screen when g; Tuning panels should be laid out side-by-side on a wide window rather  | human-review:unclear-contradiction, workflow-heavy |
| design/ux-writing | A | TRIM | 0.79 | q1,q4 | coverage 0.79; keep only the missed deltas | human-review:borderline |

## foundation

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| foundation/attributed-string | A | TRIM | 0.62 | q1,q5 | coverage 0.62; keep only the missed deltas | — |

## generators

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| generators/accessibility-generator | B | KEEP | 0.40 | — | coverage 0.40; bare model failed: Use UIAccessibility.buttonShapesEnabled and its change notification to; Bold Text support is free with system text styles, but custom fonts mu Templates NOT assessed (Track B). | — |
| generators/account-deletion | B | KEEP | 0.65 | — | coverage 0.65; bare model failed: CloudKit private database records are tied to the user's iCloud accoun; Offering data export before deletion is a privacy best practice that b Templates NOT assessed (Track B). | workflow-heavy |
| generators/analytics-setup | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: The AnalyticsService protocol is a stable interface that never changes; Firebase setup also requires a GoogleService-Info.plist file in additi Templates NOT assessed (Track B). | human-review:borderline, human-review:unverified-suspect, workflow-heavy |
| generators/announcement-banner | B | KEEP | 0.79 | — | coverage 0.79; bare model failed: If a user navigates away mid-animation, ensure the banner state resets Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/app-clip | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: App Clip binary must be under 10 MB; App Clip data is deleted after 8 hours of inactivity Templates NOT assessed (Track B). | human-review:borderline, human-review:unverified-suspect, workflow-heavy |
| generators/app-extensions | B | KEEP | 0.60 | — | coverage 0.60; bare model failed: Safari Web Extension content scripts have approximately a 6 MB memory ; Safari Web Extension content scripts run in an isolated world and cann Templates NOT assessed (Track B). | workflow-heavy |
| generators/app-icon-generator | B | KEEP | 0.20 | — | coverage 0.20; bare model failed: watchOS uses a 1088×1088 canvas (not 1024×1024) to deliberately oversh; Layer filenames should be prefixed with a Z-order number so stacking i Templates NOT assessed (Track B). | workflow-heavy |
| generators/app-store-assets | B | KEEP | 0.70 | — | coverage 0.70; bare model failed: Production checklist should confirm assets are tested on actual device Templates NOT assessed (Track B). | workflow-heavy |
| generators/auth-flow | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: The generated AuthenticationManager should be implemented using the @O; Testing Sign in with Apple should use a sandbox Apple ID Templates NOT assessed (Track B). | human-review:borderline, human-review:unverified-suspect, workflow-heavy |
| generators/background-processing | B | KEEP | 0.88 | — | coverage 0.88; bare model failed: If BGTaskScheduler.register(forTaskWithIdentifier:) is called after di Templates NOT assessed (Track B). | workflow-heavy |
| generators/ci-cd-setup | B | KEEP | 0.25 | — | coverage 0.25; bare model failed: The App Store Connect API Key used for CI should be generated with the; The .p8 private key file for the App Store Connect API key is only ava Templates NOT assessed (Track B). | — |
| generators/cloudkit-sync | B | KEEP | 0.60 | — | coverage 0.60; bare model failed: Record types are auto-created when you first save a CKRecord of that t; Indexes are required for queryable fields and must be added in the Clo Templates NOT assessed (Track B). | workflow-heavy |
| generators/consent-flow | B | KEEP | 0.38 | — | coverage 0.38; bare model failed: Consent must be as easy to withdraw as to grant (GDPR Article 7(3)); Different regulations have different age thresholds (GDPR 16/13, CCPA  Templates NOT assessed (Track B). | workflow-heavy |
| generators/custom-product-pages | B | KEEP | 0.14 | — | coverage 0.14; bare model failed: Under 2,000 monthly impressions: don't create CPPs, focus on optimizin; Exception: CPPs are valuable even at low organic volume if running pai Templates NOT assessed (Track B). | workflow-heavy |
| generators/data-export | B | TRIM(prose) | 0.81 | — | coverage 0.81; keep only the missed deltas Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/debug-menu | B | KEEP | 0.72 | — | coverage 0.72; bare model failed: Shake gesture for debug menu can conflict with UIKit's system shake-to; Swift 5.9+ is required for the generated code. Templates NOT assessed (Track B). | workflow-heavy |
| generators/deep-linking | B | KEEP | 0.38 | — | coverage 0.38; bare model failed: When testing the AASA file with curl, it should return Content-Type: a; Content entities should be indexed with CSSearchableIndex for Spotligh Templates NOT assessed (Track B). | — |
| generators/error-monitoring | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: For GDPR compliance, use the NoOp monitoring implementation for EU use; Use App Tracking Transparency if combining crash monitoring with analy Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/feature-flags | B | KEEP | 0.38 | — | coverage 0.38; bare model failed: After a feature is fully rolled out, remove the flag enum case and rel; When a flag controls a UI branch, write tests for both the enabled and Templates NOT assessed (Track B). | workflow-heavy |
| generators/featuring-nomination | B | KEEP | 0.29 | — | coverage 0.29; bare model failed: Nominations should be submitted 6-8 weeks before the desired featuring; Apple reviews and plans its editorial calendar well in advance, with s Templates NOT assessed (Track B). | human-review:unclear-contradiction, workflow-heavy |
| generators/feedback-form | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: Consider blurring or redacting sensitive data (passwords, financial in; If offline when feedback is submitted, queue the entry to disk and ret Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/force-update | B | KEEP | 0.70 | — | coverage 0.70; bare model failed: If the user hasn't completed onboarding, defer the force update check  Templates NOT assessed (Track B). | workflow-heavy |
| generators/http-cache | B | KEEP | 0.57 | — | coverage 0.57; bare model failed: Recommends Medium cache storage sizing (25 MB memory / 100 MB disk) as; When an existing networking-layer's APIClient protocol is detected, th Templates NOT assessed (Track B). | workflow-heavy |
| generators/image-loading | B | KEEP | 0.67 | — | coverage 0.67; bare model failed: If a third-party image loading library (Kingfisher, SDWebImage, Nuke) ; The generator should determine whether it's targeting iOS (UIImage), m Templates NOT assessed (Track B). | workflow-heavy |
| generators/in-app-events | B | KEEP | 0.15 | — | coverage 0.15; bare model failed: Event duration must be between 15 minutes and 31 days; Concurrent limits: 10 approved events / 5 published simultaneously acr Templates NOT assessed (Track B). | human-review:unverified-suspect, workflow-heavy |
| generators/lapsed-user | B | KEEP | 0.12 | — | coverage 0.12; bare model failed: To avoid false positives from background app refresh, pair scenePhase ; Day calculations for inactivity should use Calendar.current rather tha Templates NOT assessed (Track B). | workflow-heavy |
| generators/live-activity-generator | B | KEEP | 0.55 | — | coverage 0.55; bare model failed: Lock Screen presentation should use 14pt margins on all edges, matchin; StandBy scales the presentation to 200% and won't draw under the senso Templates NOT assessed (Track B). | human-review:unverified-suspect, workflow-heavy |
| generators/localization-setup | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: String Catalogs require iOS 16+ / macOS 13+ deployment target; Key naming should be descriptive and hierarchical rather than vague or Templates NOT assessed (Track B). | human-review:borderline, human-review:unverified-suspect |
| generators/logging-setup | B | KEEP | 0.69 | — | coverage 0.69; bare model failed: Debug logs are compiled out in Release builds (as a benefit of Logger ; .sensitive privacy annotation always redacts data such as passwords an Templates NOT assessed (Track B). | human-review:unverified-suspect, workflow-heavy |
| generators/milestone-celebration | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: Confetti particle count should be capped (birthRate 50-80) to maintain; Use emitterCells with only 3-5 distinct shapes to reduce GPU draw call Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/networking-layer | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: async/await requires Swift 5.5+; Use @concurrent to offload heavy processing onto a background thread Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/offer-codes-setup | B | KEEP | 0.05 | — | coverage 0.05; bare model failed: Up to 10 active offers per subscription SKU; One-time use codes are generated in batches of 500 to 25,000 Templates NOT assessed (Track B). | human-review:unclear-contradiction, workflow-heavy |
| generators/offline-queue | B | KEEP | 0.42 | — | coverage 0.42; bare model failed: The queue processes operations in FIFO order by default, with an expli; For long offline periods, add a TTL to operations (e.g., 24 hours) and Templates NOT assessed (Track B). | workflow-heavy |
| generators/onboarding-generator | B | KEEP | 0.79 | — | coverage 0.79; bare model failed: To test onboarding on first launch, delete the app from the simulator  Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/pagination | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: Project should target Swift 5.9+; When a networking-layer generator was already used, pagination data so Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/paywall-generator | B | FIX | 0.20 | — | suspect/contradicted claim confirmed: Transaction.currentEntitlements(for:) is a new API for entitlements as of iOS 18.4. Templates NOT assessed (Track B). | human-review:unverified-suspect, workflow-heavy |
| generators/permission-priming | B | KEEP | 0.69 | — | coverage 0.69; bare model failed: Pre-permission priming dramatically increases permission grant rates v Templates NOT assessed (Track B). | workflow-heavy |
| generators/persistence-setup | B | KEEP | 0.56 | — | coverage 0.56; bare model failed: Repository pattern is recommended because it allows easy testing; Default CloudKit quota is generous (free tier: 100MB asset storage) Templates NOT assessed (Track B). | workflow-heavy |
| generators/pre-orders | B | KEEP | 0.11 | — | coverage 0.11; bare model failed: On release day, the app auto-downloads within ~24 hours; Pre-orders count toward launch day download numbers Templates NOT assessed (Track B). | human-review:unclear-contradiction, human-review:unverified-suspect, workflow-heavy |
| generators/preview-data-generator | B | KEEP | 0.56 | — | coverage 0.56; bare model failed: Where a test-data factory (Model.fixture()) already exists, the previe; The correct preview API is chosen by deployment target: iOS 17+ uses t Templates NOT assessed (Track B). | human-review:unverified-suspect, workflow-heavy |
| generators/product-page-optimization | B | KEEP | 0.35 | — | coverage 0.35; bare model failed: Traffic proportion for PPO tests is 1–50% of page traffic, split evenl; No confidence is shown for the first 7 days; 90% confidence is the dec Templates NOT assessed (Track B). | human-review:unclear-contradiction, workflow-heavy |
| generators/promoted-iap | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: Choose your most compelling IAP as the first promoted product; Apple may also feature your IAPs in editorial content beyond the produ Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/push-notifications | B | KEEP | 0.28 | — | coverage 0.28; bare model failed: Use provisional authorization for passive content, reserving the expli; Every notification must carry a specific message or completable task,  Templates NOT assessed (Track B). | — |
| generators/quick-win-session | B | KEEP | 0.30 | — | coverage 0.30; bare model failed: Provide a Skip button and never show the quick win again after complet; The quick win should produce a real artifact, not feel like a demo/tut Templates NOT assessed (Track B). | workflow-heavy |
| generators/referral-system | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: Each invitee should only be able to redeem one referral code ever; Referral systems must not manipulate App Store ratings or reviews (Gui Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/review-prompt | B | KEEP | 0.62 | — | coverage 0.62; bare model failed: This skill only applies to App Store distributed apps (StoreKit review; On macOS, detect App Store distribution by checking whether the app's  Templates NOT assessed (Track B). | human-review:unverified-suspect, workflow-heavy |
| generators/screenshot-automation | B | KEEP | 0.30 | — | coverage 0.30; bare model failed: Marketing captions should be short (3-6 words) and benefit-focused; The first screenshot is the most important for App Store search result Templates NOT assessed (Track B). | workflow-heavy |
| generators/settings-screen | B | KEEP | 0.75 | — | coverage 0.75; bare model failed: Verification should include confirming VoiceOver navigation works on t; iOS settings should use NavigationStack with List Templates NOT assessed (Track B). | human-review:unclear-contradiction, workflow-heavy |
| generators/share-card | B | KEEP | 0.25 | — | coverage 0.25; bare model failed: Image format guidance: use JPEG at high quality for Instagram to avoid; A 1080x1920 card at @3x scale consumes roughly 75 MB in memory Templates NOT assessed (Track B). | human-review:unverified-suspect, workflow-heavy |
| generators/social-export | B | KEEP | 0.62 | — | coverage 0.62; bare model failed: Instagram Stories image export has a max file size of ~12 MB; The source_application parameter must be the Facebook App ID Templates NOT assessed (Track B). | workflow-heavy |
| generators/spotlight-indexing | B | KEEP | 0.39 | — | coverage 0.39; bare model failed: CSSearchableIndex has no hard documented limit, but Apple recommends k; CSSearchableIndex.default() returns a singleton but its methods are NO Templates NOT assessed (Track B). | workflow-heavy |
| generators/state-restoration | B | KEEP | 0.67 | — | coverage 0.67; bare model failed: Never persist passwords, tokens, or PII in state restoration files; us; Use String tags instead of Int for tab selection for readability and s Templates NOT assessed (Track B). | workflow-heavy |
| generators/streak-tracker | B | KEEP | 0.17 | — | coverage 0.17; bare model failed: For midnight edge cases, the raw timestamp should be recorded alongsid; To mitigate device clock manipulation, store createdAt timestamps alon Templates NOT assessed (Track B). | workflow-heavy |
| generators/subscription-lifecycle | B | KEEP | 0.20 | — | coverage 0.20; bare model failed: Commission compounds from 70% net in year one to 85% once a subscriber; Specific retention math example: from 10,000 subscribers, 12 months la Templates NOT assessed (Track B). | human-review:unverified-suspect, workflow-heavy |
| generators/subscription-offers | B | KEEP | 0.25 | — | coverage 0.25; bare model failed: Promotional offer baseline eligibility is deliberately broad — any cur; Promotional offer pay-up-front prices are deliberately NOT price-valid Templates NOT assessed (Track B). | workflow-heavy |
| generators/test-generator | B | KEEP | 0.28 | — | coverage 0.28; bare model failed: Swift Testing requires a minimum deployment target of iOS 16+ / macOS ; Top mistake: testing implementation details instead of behavior, since Templates NOT assessed (Track B). | — |
| generators/tipkit-generator | B | KEEP | 0.23 | — | coverage 0.23; bare model failed: Tip title should be a direct action phrase naming the feature, not a g; Tips should never be used for promotion/upsells Templates NOT assessed (Track B). | workflow-heavy |
| generators/usage-insights | B | KEEP | 0.65 | — | coverage 0.65; bare model failed: Handle timezone changes gracefully by storing timestamps in UTC and di; Use .chartYScale(domain:) to prevent the axis from starting at a misle Templates NOT assessed (Track B). | workflow-heavy |
| generators/variable-rewards | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: RewardPool accepts a seed parameter for deterministic testing of rando; Slot-style spins and near-miss animations can read as simulated gambli Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/watermark-engine | B | KEEP | 0.31 | — | coverage 0.31; bare model failed: CoreGraphics contexts must account for screen scale; watermarks look b; Rendering watermarks on very large (48MP) photos allocates significant Templates NOT assessed (Track B). | workflow-heavy |
| generators/whats-new | B | KEEP | 0.50 | — | coverage 0.50; bare model failed: Features should be grouped/accumulated per release version so users wh; Content can be fetched from a remote server (with local fallback) to u Templates NOT assessed (Track B). | human-review:borderline, human-review:unclear-contradiction, workflow-heavy |
| generators/widget-generator | B | KEEP | 0.45 | — | coverage 0.45; bare model failed: Widget extensions are killed if they exceed the 40MB memory limit; Small widgets should have max ~4 pieces of information and exactly one Templates NOT assessed (Track B). | human-review:borderline, workflow-heavy |
| generators/win-back-offers | B | KEEP | 0.10 | — | coverage 0.10; bare model failed: Churn volume thresholds: under 50 churned subscribers isn't worth the ; When picking a native win-back offer, the first ID in eligibleWinBackO Templates NOT assessed (Track B). | workflow-heavy |

## growth

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| growth/analytics-interpretation | A | KEEP | 0.36 | q1,q2,q3,q4 | coverage 0.36; bare model failed: A peer group in App Store Connect benchmarks is defined by category + ; As of WWDC25, up to 7 filters can be stacked per metric in App Store C | human-review:unclear-contradiction, human-review:unverified-suspect, workflow-heavy |
| growth/community-building | A | TRIM | 0.54 | q1,q3,q5 | coverage 0.54; keep only the missed deltas | human-review:borderline, human-review:unclear-contradiction, workflow-heavy |
| growth/indie-business | A | TRIM | 0.75 | q1 | coverage 0.75; keep only the missed deltas | workflow-heavy |
| growth/press-media | A | TRIM | 0.58 | q2,q4,q5 | coverage 0.58; keep only the missed deltas | human-review:unclear-contradiction, workflow-heavy |
| growth/store-growth-audit | A | KEEP | 0.47 | q1,q2,q5 | coverage 0.47; bare model failed: Exactly 13 checklist items across the whole audit are flagged as phase; Enabling both Billing Grace Period and Billing Retry is estimated to r | human-review:borderline, human-review:unclear-contradiction, human-review:unverified-suspect, workflow-heavy |
| growth/store-signals | A | KEEP | 0.35 | q3,q4,q5 | coverage 0.35; bare model failed: On-strategy findings go to the backlog; off-strategy findings are list; A move of less than 3 percentage points on a retention/conversion metr | human-review:unclear-contradiction |

## ios

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| ios/accessibility-audit | A | TRIM | 0.73 | q1 | coverage 0.73; keep only the missed deltas | human-review:unclear-contradiction, human-review:unverified-suspect |
| ios/app-planner | A | KEEP | 0.46 | q1,q5 | coverage 0.46; bare model failed: Existing app codebase size is categorized as small (<10 screens), medi; The recommended improvement roadmap for an existing app begins with a  | human-review:borderline, human-review:unclear-contradiction, truncated, workflow-heavy |
| ios/assistive-access | A | KEEP | 0.38 | q1,q2,q3,q4,q5 | coverage 0.38; bare model failed: Assistive Access has three integration levels: no adoption (reduced fr; Assistive Access mode itself shipped with iOS 17, but the AssistiveAcc | — |
| ios/coding-best-practices | A | TRIM | 0.50 | q1,q2,q3,q4,q5 | coverage 0.50; keep only the missed deltas | human-review:borderline |
| ios/ipad-patterns | A | TRIM | 0.89 | — | coverage 0.89; keep only the missed deltas | judge-disagreement |
| ios/migration-patterns | A | FIX | 0.58 | q1,q3,q5 | suspect/contradicted claim confirmed: SwiftData's @Model macro does not synthesize an initializer; you must write one explicitly, unlike N | human-review:unverified-suspect, truncated |
| ios/navigation-patterns | A | TRIM | 0.83 | Q2 | coverage 0.83; keep only the missed deltas | human-review:borderline, human-review:unclear-contradiction |
| ios/run-device | A | KEEP | 0.36 | q1,q3,q5 | coverage 0.36; bare model failed: xcodebuild matches devices by hardware UDID, not the devicectl CoreDev; Build for a device using -destination 'generic/platform=iOS' instead o | human-review:unverified-suspect |
| ios/run-simulator | A | TRIM | 0.79 | q1 | coverage 0.79; keep only the missed deltas | human-review:borderline |
| ios/ui-review | A | TRIM | 0.64 | q1,q4,q5 | coverage 0.64; keep only the missed deltas | human-review:unclear-contradiction, human-review:unverified-suspect |

## legal

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| legal/privacy-policy | A | TRIM | 0.68 | q5 | coverage 0.68; keep only the missed deltas | workflow-heavy |
| legal/privacy-publish | A | TRIM | 0.58 | q2,q3,q4,q5 | coverage 0.58; keep only the missed deltas | workflow-heavy |

## macos

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| macos/app-planner | A | TRIM | 0.50 | q1,q3,q4,q5 | coverage 0.50; keep only the missed deltas | human-review:borderline, human-review:unclear-contradiction |
| macos/appkit-swiftui-bridge | A | TRIM | 0.73 | q1,q5 | coverage 0.73; keep only the missed deltas | — |
| macos/architecture-patterns | A | TRIM | 0.94 | — | coverage 0.94; keep only the missed deltas | judge-disagreement |
| macos/coding-best-practices | A | TRIM | 0.69 | q4 | coverage 0.69; keep only the missed deltas | truncated |
| macos/macos-capabilities | A | TRIM | 0.88 | q4 | coverage 0.88; keep only the missed deltas | — |
| macos/macos-tahoe-apis | A | FIX | 0.50 | Q1,Q3,Q4 | suspect/contradicted claim confirmed: The document imports Foundation Models text generation/summarization APIs via a module called 'Apple | human-review:borderline, human-review:unverified-suspect |
| macos/swiftdata-architecture | A | TRIM | 0.69 | Q2,Q4,Q5 | coverage 0.69; keep only the missed deltas | — |
| macos/ui-review-tahoe | A | TRIM | 0.73 | q1,q5 | coverage 0.73; keep only the missed deltas | human-review:unverified-suspect, truncated |

## mapkit

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| mapkit/geotoolbox | A | TRIM | 0.62 | q1,q5 | coverage 0.62; keep only the missed deltas | — |

## monetization

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| monetization | A | KEEP | 0.32 | q2,q3,q4,q5 | coverage 0.32; bare model failed: Health/fitness tracking apps should use a 14-day free trial because us; A readiness score of 5-6 ready signals means an app should monetize no | human-review:unclear-contradiction, workflow-heavy |
| monetization/bundles-and-licensing | A | KEEP | 0.42 | q1,q2,q4,q5 | coverage 0.42; bare model failed: Bundle pricing should aim for the second app ~half off and third+ apps; Enabling Family Sharing is a one-way door: it takes effect within hour | — |
| monetization/external-purchases | A | TRIM | 0.75 | — | coverage 0.75; keep only the missed deltas | — |

## performance

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| performance/profiling | A | KEEP | 0.32 | q1,q2,q3,q4,q5 | coverage 0.32; bare model failed: MetricKit/Xcode automatically generate a disk-write exception report (; Xcode Organizer aggregates performance metrics from consented user dev | human-review:unclear-contradiction, human-review:unverified-suspect, truncated |
| performance/swiftui-debugging | A | TRIM | 0.61 | Q1,Q2,Q4,Q5 | coverage 0.61; keep only the missed deltas | human-review:unclear-contradiction |

## product

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| product/app-namer | A | TRIM | 0.75 | q4 | coverage 0.75; keep only the missed deltas | workflow-heavy |
| product/architecture-spec | B | KEEP | 0.00 | — | coverage 0.00; bare model failed: For simple apps (1-3 core features, basic CRUD), MVVM with SwiftUI is ; Unit testing coverage target of 70%+ for business logic Templates NOT assessed (Track B). | human-review:unclear-contradiction |
| product/beta-testing | A | KEEP | 0.42 | q3,q5 | coverage 0.42; bare model failed: Do not offer cash payment for beta testing since it attracts the wrong; Surveys should be capped at 5 questions because completion rate drops  | human-review:unclear-contradiction, human-review:unverified-suspect, workflow-heavy |
| product/competitive-analysis | A | KEEP | 0.15 | q1,q2,q4,q5 | coverage 0.15; bare model failed: The workflow begins by running the product-agent skill for discovery a; When verifying with App Store data, read recent reviews from only the  | human-review:unclear-contradiction |
| product/idea-generator | A | KEEP | 0.17 | q1,q2,q3,q4,q5 | coverage 0.17; bare model failed: The five brainstorming lenses (Skills & Interests, Problem-First, Tech; The overall feasibility score is a weighted average on a 1-10 scale, w | workflow-heavy |
| product/implementation-guide | B | KEEP | 0.00 | — | coverage 0.00; bare model failed: Minimize third-party dependencies; use native frameworks when possible; Use `final` for classes that don't need subclassing, for performance r Templates NOT assessed (Track B). | — |
| product/implementation-spec | B | KEEP | 0.00 | — | coverage 0.00; bare model failed: User decision gates must never be skipped; the orchestrator should nev; Consistency across specs requires that PRD features match Architecture Templates NOT assessed (Track B). | workflow-heavy |
| product/localization-strategy | A | TRIM | 0.62 | q2,q5 | coverage 0.62; keep only the missed deltas | human-review:unclear-contradiction, workflow-heavy |
| product/market-research | A | KEEP | 0.42 | q1,q2,q4 | coverage 0.42; bare model failed: SOM (Serviceable Obtainable Market) should be calculated as the realis; For indie developers, a SOM above $5M is a good opportunity, $1-5M is  | human-review:unclear-contradiction, workflow-heavy |
| product/prd-generator | A | TRIM | 0.75 | q3 | coverage 0.75; keep only the missed deltas | human-review:unclear-contradiction |
| product/product-agent | A | KEEP | 0.05 | q1,q2,q3,q4,q5 | coverage 0.05; bare model failed: Severity score bands are defined as 1-3 weak/low urgency, 4-6 moderate; The recommendation field must use one of three verdicts: BUILD, PROCEE | — |
| product/release-spec | B | KEEP | 0.25 | — | coverage 0.25; bare model failed: App preview video should be 15-30 seconds, under 500MB, in portrait or; Bitcode should not be enabled since it is deprecated by Apple Templates NOT assessed (Track B). | human-review:unverified-suspect |
| product/test-spec | B | KEEP | 0.39 | — | coverage 0.39; bare model failed: Test pyramid should be roughly 70% unit tests / 20% integration tests ; Cold app launch time target should be under 1.5 seconds Templates NOT assessed (Track B). | human-review:unclear-contradiction |
| product/ux-spec | B | KEEP | 0.25 | — | coverage 0.25; bare model failed: Empty states should use ContentUnavailableView, available iOS 17+; Tab bars should have 3-5 tabs maximum Templates NOT assessed (Track B). | — |

## release-review

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| release-review | A | TRIM | 0.73 | q1,q4,q5 | coverage 0.73; keep only the missed deltas | human-review:unclear-contradiction, human-review:unverified-suspect |

## security

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| security | A | DELETE-candidate | 0.86 | — | bare model covered 0.86 of claims with no contradictions | swiftship-referenced |
| security/privacy-manifests | A | TRIM | 0.79 | q4 | coverage 0.79; keep only the missed deltas | human-review:borderline, human-review:unverified-suspect |

## shared

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| shared/skill-auditor | A | KEEP | 0.00 | q1,q2,q3,q4,q5 | coverage 0.00; bare model failed: As of the 2026-07-11 baseline, the known-current version constants are; A single-file skill is flagged as oversized (M-04) only if it exceeds  | — |
| shared/skill-creator | A | KEEP | 0.40 | q1,q2,q3 | coverage 0.40; bare model failed: A skill should be modularized into supporting reference files once the; SKILL.md files have an ideal size of 200-300 lines and a max of 400 li | — |

## swift

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| swift/concurrency | A | TRIM | 0.75 | q2,q5 | coverage 0.75; keep only the missed deltas | human-review:unverified-suspect |
| swift/concurrency-patterns | A | TRIM | 0.71 | q3,q4,q5 | coverage 0.71; keep only the missed deltas | human-review:unverified-suspect, truncated |
| swift/memory | A | TRIM | 0.50 | q1,q2,q3,q5 | coverage 0.50; keep only the missed deltas | human-review:borderline, human-review:unclear-contradiction, human-review:unverified-suspect |

## swiftdata

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| swiftdata/inheritance | A | TRIM | 0.55 | q4,q5 | coverage 0.55; keep only the missed deltas | human-review:unclear-contradiction, human-review:unverified-suspect |

## swiftui

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| swiftui/alarmkit | A | FIX | 0.71 | q1,q4,q5 | suspect/contradicted claim confirmed: All AlarmKit APIs listed (AlarmManager, Alarm, AlarmPresentation, AlarmAttributes, AlarmMetadata, Al | human-review:unclear-contradiction, human-review:unverified-suspect |
| swiftui/charts-3d | A | TRIM | 0.92 | — | coverage 0.92; keep only the missed deltas | judge-disagreement |
| swiftui/data-flow | A | TRIM | 0.77 | q1 | coverage 0.77; keep only the missed deltas | human-review:borderline, human-review:unclear-contradiction |
| swiftui/layout | A | TRIM | 0.61 | q4,q5 | coverage 0.61; keep only the missed deltas | human-review:unverified-suspect |
| swiftui/text-editing | A | TRIM | 0.67 | q1,q5 | coverage 0.67; keep only the missed deltas | — |
| swiftui/toolbars | A | TRIM | 0.67 | q1,q2,q3,q4 | coverage 0.67; keep only the missed deltas | human-review:unverified-suspect |
| swiftui/webkit | A | TRIM | 0.68 | q2,q4,q5 | coverage 0.68; keep only the missed deltas | human-review:unclear-contradiction, human-review:unverified-suspect |

## testing

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| testing/characterization-test-generator | A | TRIM | 0.68 | — | coverage 0.68; keep only the missed deltas | — |
| testing/flow-walkthrough | A | KEEP | 0.36 | Q4,Q5 | coverage 0.36; bare model failed: UI/UX bugs fall into three distinct failure classes, each caught by a ; For every @Model with a Create path, there must be both a Read and an  | — |
| testing/integration-test-scaffold | A | DELETE-candidate | 0.83 | — | bare model covered 0.83 of claims with no contradictions | human-review:borderline, swiftship-referenced, workflow-heavy |
| testing/snapshot-test-setup | A | TRIM | 0.73 | q1,q4 | coverage 0.73; keep only the missed deltas | human-review:unclear-contradiction, workflow-heavy |
| testing/tdd-bug-fix | A | TRIM | 0.68 | q5 | coverage 0.68; keep only the missed deltas | — |
| testing/tdd-feature | A | KEEP | 0.42 | q1,q4,q5 | coverage 0.42; bare model failed: Tests should be written in order: Construction, Happy path, State veri; Writing too many tests before implementing is overwhelming and hides p | human-review:unclear-contradiction |
| testing/tdd-refactor-guard | A | DELETE-candidate | 0.80 | — | bare model covered 0.80 of claims with no contradictions | human-review:borderline, swiftship-referenced, workflow-heavy |
| testing/test-contract | A | TRIM | 0.75 | q1,q5 | coverage 0.75; keep only the missed deltas | — |
| testing/test-data-factory | A | TRIM | 0.75 | q3,q4 | coverage 0.75; keep only the missed deltas | human-review:unclear-contradiction, workflow-heavy |

## visionos

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| visionos/spatial-design | A | KEEP | 0.42 | q1,q3,q5 | coverage 0.42; bare model failed: Hover effects should use a subtle ~5% scale change, with a reveal dela; Ornaments should overlap the window's bottom edge by 20pt, with border | human-review:unverified-suspect |
| visionos/widgets | A | TRIM | 0.50 | q1,q2,q4 | coverage 0.50; keep only the missed deltas | human-review:borderline |

## watchos

| Skill | Track | Verdict | Coverage | Failed Qs | Justification | Flags |
|---|---|---|---|---|---|---|
| watchos | A | FIX | 0.53 | q2,q4,q5 | suspect/contradicted claim confirmed: All new watch complications should use WidgetKit; ClockKit is deprecated as of watchOS 9 and removed | human-review:borderline, human-review:unclear-contradiction, human-review:unverified-suspect, truncated |

## Appendix A — FIX detail

### generators/paywall-generator
- `missed` iOS 18.4+ introduces SubscriptionOfferView, a new SwiftUI view for merchandising subscriptions, alongside a subscriptionStatusTask modifier for tracking subscri
  - suspect: SubscriptionOfferView does not match known StoreKit SwiftUI API names (SubscriptionStoreView, ProductView, StoreView); likely a hallucinated or misremembered AP (cross-check: n/a)
- `partial` Transaction.currentEntitlements(for:) is a new API for entitlements as of iOS 18.4.
  - suspect: Real StoreKit API has plural Transaction.currentEntitlements as a parameterless AsyncSequence, and a separate singular Transaction.currentEntitlement(for:) that (cross-check: n/a)

### ios/migration-patterns
- `contradicted` When migrating both app code and tests, migrate the tests to Swift Testing first to establish a safety net before migrating the app code.
- `contradicted` Each framework migration should be its own PR; don't combine e.g. CoreData->SwiftData and ObservableObject->@Observable in the same pull request.
- `contradicted` SwiftData's @Model macro does not synthesize an initializer; you must write one explicitly, unlike NSManagedObject subclasses.
  - suspect: The reference claim that @Model does not synthesize an initializer appears factually wrong — Apple's documented SwiftData behavior is that @Model does generate  (cross-check: n/a)

### macos/macos-tahoe-apis
- `contradicted` The document imports Foundation Models text generation/summarization APIs via a module called 'AppleIntelligence', which it explicitly flags as hypothetical (no
- `contradicted` The document claims macOS 26's on-device AI stack includes MCP (Model Context Protocol) support alongside Foundation Models.
  - suspect: No Apple framework or SDK ships MCP support alongside Foundation Models; this appears to be a fabricated feature. (cross-check: n/a)
- `contradicted` Setting an EKReminder's priority to 1 is described as triggering the macOS 26 'urgent' reminder flag.
  - suspect: EKReminderPriority has no 'urgent' case or flag; priority=1 maps to .high, not a distinct urgent state. (cross-check: n/a)
- `contradicted` Control Center customization is described as system-level only; apps cannot add their own Control Center entries directly and must instead expose functionality 
  - suspect: Claim describes Control Center as system-level-only with no direct app entries, but Apple's Controls/ControlWidget API (extended to macOS) does let apps add dir (cross-check: n/a)
- `contradicted` Setting a Foundation Model's processingLocation to .onDevice is claimed to ensure privacy.
  - suspect: No processingLocation property exists on Foundation Models APIs; the framework only exposes the on-device model with no such switch. (cross-check: n/a)

### swiftui/alarmkit
- `contradicted` The Info.plist key NSAlarmKitUsageDescription must be added before calling requestAuthorization(), or the request fails silently
- `contradicted` Secondary alert buttons are created via factory methods .snoozeButton(), .openAppButton(), and .repeatButton()
  - suspect: AlarmKit is a very new framework (iOS 26); I cannot confirm with certainty whether AlarmButton exposes static factory methods like .snoozeButton()/.openAppButto (cross-check: n/a)
- `contradicted` All AlarmKit APIs listed (AlarmManager, Alarm, AlarmPresentation, AlarmAttributes, AlarmMetadata, AlarmButton, CountdownDuration, alarmUpdates, authorizationUpd
  - suspect: AlarmKit was introduced at WWDC 2025 for iOS 26; a stated minimum of iOS 18 for AlarmManager and related AlarmKit APIs appears incorrect. (cross-check: n/a)

### watchos
- `partial` All new watch complications should use WidgetKit; ClockKit is deprecated as of watchOS 9 and removed entirely in watchOS 11.
  - suspect: Claim asserts ClockKit is fully removed in watchOS 11; I'm not confident Apple has actually removed ClockKit entirely as of watchOS 11 (it was deprecated in wat (cross-check: n/a)
- `partial` WidgetCenter.shared.reloadTimelines is budget-limited and should not be called more than 4 times per hour.
  - suspect: Apple has never published an exact reload budget number for WidgetCenter.reloadTimelines; the specific '4 times per hour' figure isn't something I can confirm i (cross-check: n/a)
- `partial` A WKExtendedRuntimeSession of type .selfCare (or .mindfulness) is capped at up to 10 minutes.
  - suspect: The case name '.selfCare' doesn't match the WKExtendedRuntimeSessionType case I know of, which is '.mindfulness'; '.selfCare' may not be a real case name. (cross-check: n/a)
- `contradicted` Interactive controls on watchOS should use a minimum touch target height of 38pt.
  - suspect: 38pt is an unusual figure I don't recognize from Apple's HIG, which more commonly cites 44pt as the minimum tappable target size; not confident either number is (cross-check: n/a)
- `contradicted` AssistiveTouch maps specific hand gestures to watch actions: clench for tap, double-clench for the action menu, pinch to move to the next element, and double-pi
  - suspect: My recollection of Apple's AssistiveTouch for Apple Watch support documentation is that Pinch = tap/select and Clench = move to next item, which is the opposite (cross-check: n/a)
- `contradicted` Complication timeline providers should supply at most 4-8 timeline entries rather than generating an entry for every minute.
- `contradicted` For HealthKit read-type authorization, checking authorizationStatus always reports .notDetermined regardless of whether the user actually granted or denied read
- `partial` The watchOS toolbar's More button is a circular ellipsis rendered white at 85% opacity with a 1pt black outer glow at 50%, and should hold only secondary action
  - suspect: The precise styling spec (white at 85% opacity, 1pt black outer glow at 50%) is very specific undocumented visual detail not present in Apple's public HIG; uncl (cross-check: n/a)

## Appendix B — DELETE dossiers (the rows requiring human approval)

### app-store/ratings-mechanics
- ⚠️ referenced by SwiftShip: commands/ratings.md, commands/ship.md, CLAUDE.md — deletion blocked until paired
- covered: Ratings are isolated per App Store storefront; a rating built up in one country shows as no rating at all in another unt
  - evidence: “When you launch in Japan, the JP storefront starts at 0 ratings / no stars shown until Japanese users actually rate the ”
- partial: The written-review pool is also per-storefront, so fresh markets will show empty review sections that need to be seeded 
  - evidence: “they'll see an empty or sparse review list until JP users start writing their own”
- partial: Resetting the ratings summary in ASC discards both the count and the average, and the count can only be rebuilt one rati
  - evidence: “you'd be trading 3,000 data points of social proof and an above-average score for a rating count of zero the moment your”
- partial: A near-exception to the never-reset rule is a catastrophic launch (sub-3★, low count, root cause fixed) on an app with a
  - evidence: “The rating is dragged down by a specific, now-fixed defect (e.g., an app sitting at 2.3 stars because of a crash bug tha”
- covered: When a user updates their review after receiving a developer reply, the new score replaces the old one in the average, m
  - evidence: “If the star rating changes, Apple removes the old rating value and substitutes the new one in the aggregate; it isn't ad”
- covered: Apple's phased release is a 7-day staged rollout to auto-update users following the schedule 1% → 2% → 5% → 10% → 20% → 
  - evidence: “Phased-rollout percentages (Apple's fixed schedule, days 1–7): 1% → 2% → 5% → 10% → 20% → 50% → 100%.”
- covered: Manual version release means App Review approval does not automatically trigger release, letting a developer choose to r
  - evidence: “The only thing manual release changes is the moment the approved build goes live: instead of auto-releasing the instant ”
- partial: A crashing build caught on day 1-2 of a phased rollout has already reached roughly 3% of users at that point in the sche
  - evidence: “actual exposure on day 1–2 is higher than that headline number and isn't something you can bound precisely from App Stor”
- covered: Pausing a phased release only stops new deliveries to additional users — it does not roll back users who already receive
  - evidence: “It doesn't roll back anyone who already auto-updated — there's no way to un-push a version to a device.”
- covered: The recommended default posture for every release is phased release on, manual release on, and monitoring day-1 crash ra
  - evidence: “Should you default to manual release + phased release on? Yes, generally reasonable for an app with a meaningful auto-up”
- partial: requestReview prompts should be aimed at success moments, with frequency capped and the definition of 'success' localize
  - evidence: “Never fire on first launch or during onboarding — Apple's HIG is explicit that the prompt should appear after the user h”
- covered: requestReview prompt triggers should be weighted by storefront maturity, since a market with only 12 ratings needs promp
  - evidence: “Statistically, each new rating in the 12-count market moves the average ~8.3%; in the 5,000-count market it moves it ~0.”
- covered: Unanswered negative reviews should be tracked per storefront rather than globally, since a storefront with only 5 review
  - evidence: “In the 5,000-rating market you can batch/triage; in the 12-rating market treat every negative review as an incident.”

### design/design-principles
- ⚠️ referenced by SwiftShip: commands/visual-qa.md, commands/build.md, commands/plan.md, commands/walkthrough.md, commands/review.md, CLAUDE.md — deletion blocked until paired
- covered: Every screen must let a user immediately answer three questions: Where am I? What can I do here? Where can I go from her
  - evidence: “1. **Where am I?** — Clear indication of context/location in the app's hierarchy”
- covered: Personal data should only be requested at the moment it's needed, never at app launch.
  - evidence: “Core rule: request in context, not at launch. Never front-load permissions during onboarding.”
- partial: Delight in design is defined as a byproduct of getting purpose, agency, familiarity, and craft right, not decorative flo
  - evidence: “Treat delight as a **byproduct of getting fundamentals right, not an independent goal to design toward.**”
- covered: iOS gestures typically require a movement threshold of about 10 points before committing to a directional gesture (hyste
  - evidence: “**Drag commit threshold:** ~10 points of movement before a pan is disambiguated into a directional gesture.”
- covered: Hamburger menus are discouraged for primary features because users don't know what's inside them; tab bars are preferred
  - evidence: “hamburger menus hide navigation behind an icon that has no visual preview of what's inside, requires an extra tap to eve”
- covered: Custom gestures should only be accelerators — a visible primary path to the same action must always exist.
  - evidence: “HIG's rule of thumb is that gestures are accelerators for people who already know the app, not the only path to a featur”
- covered: Tabs should represent content categories, never actions — per HIG there should be no 'Add' tab, since primary actions be
  - evidence: “On "Add" as a tab: no, don't make an action item a tab. Tabs represent persistent, mutually exclusive destinations/views”
- covered: Animations should be tuned as springs (using damping for overshoot and response for speed) rather than fixed durations.
  - evidence: “Tune with **damping ratio**, not duration: ~1.0 for a settle with no overshoot, ~0.7–0.85 for a slight, natural bounce.”
- covered: Following the 80/20 rule, the rarely-used 80% of features should be de-emphasized while the visible 20% does the work.
  - evidence: “about 20% of features (the primary, high-frequency tasks) live in top-level, always-visible navigation (tab bar, home sc”
- covered: Scrollable content should rubber-band (soft boundary) at edges rather than stopping abruptly.
  - evidence: “**Overscroll / edge behavior:** rubber-banding, not a hard stop.”
- covered: The idea-to-interface process starts by inventorying everything the app does before judging or removing anything.
  - evidence: “**First step:** Do a full feature/content inventory and card-sort it against actual usage data (analytics + support tick”
- covered: For scannable, structured information, a List layout is preferred over a Grid.
  - evidence: “If in doubt and the content has any textual detail to scan, default to list.”
- covered: Colors should be referenced via semantic names (like 'label' or 'secondarySystemBackground') rather than by appearance, 
  - evidence: “Prefer **semantic system colors** where they fit your case: `Color.primary`/`Color.secondary`, `UIColor.label`/`.seconda”

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

### testing/integration-test-scaffold
- ⚠️ referenced by SwiftShip: commands/roadmap.md, commands/build.md, commands/plan.md, commands/test.md, CLAUDE.md — deletion blocked until paired
- covered: MockURLProtocol.canInit(with:) always returns true so it intercepts every URLSession request.
  - evidence: “Return `true` for every request you want the mock to intercept — typically all of them in a test double”
- covered: The mock URLSession is built with URLSessionConfiguration.ephemeral and its protocolClasses set to [MockURLProtocol.self
  - evidence: “configuration.protocolClasses = [MockURLProtocol.self]”
- covered: In-memory SwiftData testing uses ModelConfiguration(isStoredInMemoryOnly: true).
  - evidence: “let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)”
- covered: Three mock strategy options are offered for configuration: URLProtocol-based mock server, protocol-based mock (swap impl
  - evidence: “Protocol-based service boundary”
- covered: If a requested path has no registered mock response, MockURLProtocol defaults to a 404 status code with empty Data.
  - evidence: “Status: **404 Not Found**
- Body: empty `Data()`”
- covered: MockServer.respondWithError defaults to a 500 status code.
  - evidence: “Status: **500 Internal Server Error** is the near-universal default”
- partial: The scaffold process finds module dependencies by grepping for "import |@testable import" before mapping integration bou
  - evidence: “grep -rl "^import ModuleX" Sources/ModuleY”
- partial: Integration tests are distinguished from unit tests as testing multiple things together, which is described as realistic
  - evidence: “Integration test: exercises real collaborators together, verifies the *contract* between them holds”
- partial: Generated test infrastructure is organized under Tests/Infrastructure for shared test infrastructure, separate from Inte
  - evidence: “Pull shared test doubles, fixtures, and harness code (mock URLProtocols, in-memory Core Data stacks, fixture loaders) in”
- covered: Auth token integration tests verify the Authorization header is formatted as a Bearer token, e.g. "Bearer test-token".
  - evidence: “XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(expectedToken)")”
- partial: MockURLProtocol simulates network latency by calling Thread.sleep(forTimeInterval:) with a configurable responseDelay be
  - evidence: “the cleaner approach is an async delay so you don't tie up a loading-system thread”
- covered: Mock responses are delivered with a cacheStoragePolicy of .notAllowed.
  - evidence: “Cache storage policy**: use `.notAllowed`.”

### testing/tdd-refactor-guard
- ⚠️ referenced by SwiftShip: CLAUDE.md — deletion blocked until paired
- covered: Test coverage above 80% of public methods (with happy + error path tests) is rated 'Good' and the guard proceeds with re
  - evidence: “Good (safe to refactor with normal care): ~80%+ line coverage”
- covered: Coverage between 40-80% is rated 'Partial' and requires adding characterization tests for uncovered methods before refac
  - evidence: “Partial (refactor with a safety net you build yourself first): ~40-80%”
- covered: When no tests exist at all (0% coverage), the guard says to STOP and create characterization tests before any refactorin
  - evidence: “Write characterization tests against the original code, not the refactor.”
- covered: A test quality checklist item flags assertions like #expect(true) as always-passing and testing nothing, and recommends 
  - evidence: “#expect(true) (or XCTAssertTrue(true)) is a no-op assertion.”
- partial: Renaming a variable/method/type, extracting a method, inlining a temporary variable, moving a method to another type, an
  - evidence: “Inline method/variable — Same caveats as extraction, reversed.”
- partial: Changing a method signature, reordering operations, replacing an algorithm, merging/splitting classes, changing a data s
  - evidence: “Splitting or merging classes/protocols”
- partial: Architecture changes (MVC → MVVM), framework migrations (UIKit → SwiftUI), storage migrations (UserDefaults → SwiftData)
  - evidence: “Migrating frameworks (Core Data → SwiftData, UIKit → SwiftUI, delegate patterns → Combine/async streams)”
- covered: Post-refactor verification recommends running xcodebuild test with the -only-testing flag scoped to the characterization
  - evidence: “-only-testing:MyAppTests/CharacterizationTests”
- covered: The document cites Martin Fowler's book 'Refactoring: Improving the Design of Existing Code' as a reference for this gua
  - evidence: “Martin Fowler's Refactoring (2nd ed., 2018) is the companion reference for the catalog of refactoring moves themselves”
- partial: The guard produces a three-tier verdict — Green Light (proceed), Yellow Light (needs tests), or Red Light (stop) — as th
  - evidence: “not as a green light on their own”

## Appendix C — errors / truncations

- apple-intelligence/app-intents: supporting files truncated to outline (content budget)
- core-ml: supporting files truncated to outline (content budget)
- design/animation-patterns: supporting files truncated to outline (content budget)
- ios/app-planner: supporting files truncated to outline (content budget)
- ios/migration-patterns: supporting files truncated to outline (content budget)
- macos/coding-best-practices: supporting files truncated to outline (content budget)
- macos/ui-review-tahoe: supporting files truncated to outline (content budget)
- performance/profiling: supporting files truncated to outline (content budget)
- swift/concurrency-patterns: supporting files truncated to outline (content budget)
- watchos: supporting files truncated to outline (content budget)
