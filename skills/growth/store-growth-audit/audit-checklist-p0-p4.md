# Audit Checklist P0–P4 — Foundations (25 items)

Stanza format, flags, status vocabulary, and `new-app:` semantics are defined in `SKILL.md`.
Evidence keys (`EV.*`) are defined in `detection-playbook.md`. IDs are stable — never renumber.

## P0 — Day-one money toggles

#### P0.1 Small Business Program enrollment — core
- detect: MANUAL Q1
- rule: ✅ enrolled · 🔴 eligible but not enrolled · 🟠 not sure · applies-if: <$1M proceeds/yr (else ⚪ ineligible)
- new-app: plan — apply as soon as the account has (or will have) paid transactions; 15% vs 30% commission
- fix: growth/indie-business → ASC manual (enroll under Agreements)

#### P0.2 Billing Grace Period + Billing Retry enabled — core
- detect: MANUAL Q2 (+ `EV.subs` to establish applies-if)
- rule: ✅ both enabled · 🟠 one, or unsure · 🔴 neither · applies-if: has auto-renewable subscriptions
- new-app: plan — enable at subscription setup; recovers 5–15% of revenue lost to failed cards
- fix: generators/subscription-lifecycle → /apple:subscription

#### P0.3 Analytics baseline + peer-group benchmarks
- detect: HYBRID — `EV.analytics` (report configured, baseline recorded) + MANUAL Q3 (benchmarks checked)
- rule: ✅ baseline snapshot recorded AND benchmarks checked this quarter · 🟠 one of the two · 🔴 neither
- new-app: defer — activates once the app has 30 days of store data
- fix: growth/analytics-interpretation → /apple:learn-from-store

#### P0.4 Keyword research done (autocomplete + competitors + Apple Ads discovery probe)
- detect: HYBRID — keyword research artifacts (`.planning/ASO.md` keyword table or equivalent) + MANUAL Q4
- rule: ✅ researched list incl. popularity data exists · 🟠 informal/partial research · 🔴 keywords guessed
- new-app: plan — research before first metadata, not after
- fix: app-store/keyword-optimizer + app-store/apple-search-ads → /apple:metadata (or /apple:aso if installed)

## P1 — On-metadata ASO

#### P1.1 Title, subtitle, keyword field optimized — core
- detect: MCP `EV.meta`
- rule: ✅ all three fields near their 30/30/100 limits, no cross-field duplicate words, keyword field comma-separated without spaces · 🟠 fields present but wasteful (duplicates, spaces, unused chars) · 🔴 subtitle or keyword field empty/default
- new-app: plan — score the drafted fields in ASO.md by the same rule
- fix: app-store/keyword-optimizer → /apple:metadata

#### P1.2 Cross-localization indexing exploited
- detect: MCP `EV.locales` + `EV.meta`
- rule: ✅ extra indexed locales for the primary storefront carry distinct keywords (e.g. en-GB, es-MX for US) · 🟠 extra locales exist but duplicate the primary keywords · 🔴 primary locale only
- new-app: plan
- fix: app-store/keyword-optimizer (advanced-tactics §1) → /apple:localize

#### P1.3 Developer name is a deliberate, descriptive choice
- detect: MANUAL Q5
- rule: ✅ descriptive or deliberately branded · 🟠 never considered · 🔴 misleading/squatted (rare)
- new-app: plan — one-time strategic choice; heavy to change later
- fix: app-store/keyword-optimizer (advanced-tactics §12)

#### P1.4 Promoted in-app purchases with keyword-bearing display names
- detect: MCP `EV.iaps` (display names; promoted flag may need MANUAL confirm)
- rule: ✅ promoted IAPs configured with descriptive 30-char display names · 🟠 IAPs exist, none promoted or names generic ("Pro Upgrade") · 🔴 none configured · applies-if: has IAPs/subscriptions
- new-app: plan — up to 20 promoted IAPs, each an indexed search result card
- fix: generators/promoted-iap → /apple:iap

#### P1.5 In-app event metadata used as indexed surface
- detect: MCP `EV.events`
- rule: ✅ at least one event in the last 6 months with keyword-conscious name/description · 🟠 events exist but metadata is throwaway · 🔴 never used · applies-if: app has event-worthy moments (judgment — else ⚪)
- new-app: defer — activates post-launch
- fix: generators/in-app-events → /apple:event

#### P1.6 Description + promotional text working
- detect: MCP `EV.meta`
- rule: ✅ benefit-led first paragraph AND promo text in use (it updates instantly, no review) · 🟠 description fine but promo text empty · 🔴 feature-list-only description
- new-app: plan
- fix: app-store/app-description-writer → /apple:metadata

#### P1.7 Metadata written for Apple's AI tagging + App Store Tags curated
- detect: MCP heuristic on `EV.meta` (copy unambiguous about what the app does and who it's for?) + MANUAL ("App Store Tags reviewed — irrelevant tags deselected?")
- rule: ✅ literal, tag-friendly copy incl. screenshot captions AND tags curated in ASC · 🟠 clever/metaphorical copy or tags never reviewed · 🔴 misleading copy or wrong tags left live
- new-app: plan
- fix: app-store/keyword-optimizer (advanced-tactics §13 + §15) → /apple:metadata

## P2 — Conversion assets

#### P2.1 Icon is deliberate and has been tested
- detect: HYBRID — `EV.ppo` (any icon experiment ever) + MANUAL
- rule: ✅ icon tested via PPO or consciously chosen against competitors · 🟠 default/first-draft icon never revisited · 🔴 placeholder
- new-app: plan — icon is the single biggest conversion lever in search results
- fix: generators/product-page-optimization → /apple:icon + /apple:experiment

#### P2.2 Screenshots: first three carry benefit captions — core
- detect: HYBRID — `EV.meta` where screenshot info is exposed; else MANUAL
- rule: ✅ first 3 screenshots lead with benefit captions readable at thumbnail size · 🟠 screenshots fine but captions absent/feature-speak · 🔴 raw UI dumps
- new-app: plan
- fix: app-store/screenshot-planner → /apple:screenshots

#### P2.3 App preview video (once screenshots are solid)
- detect: HYBRID — `EV.meta` / MANUAL
- rule: ✅ preview video live · 🟠 planned/produced but not shipped · 🔴 none and screenshots already solid · applies-if: screenshots done (else ⚪ — sequence matters)
- new-app: defer
- fix: app-store/screenshot-planner → /apple:screenshots

#### P2.4 Trust signals: privacy labels, support URL, account deletion — core
- detect: HYBRID — `EV.meta` (support/privacy URLs live) + `EV.code.accountdeletion` + MANUAL Q6 (labels reviewed)
- rule: ✅ all three verified current · 🟠 URLs live but labels unreviewed, or account deletion N/A-unclear · 🔴 broken URL or missing deletion where accounts exist
- new-app: plan
- fix: legal/privacy-publish + generators/account-deletion → /apple:privacy

#### P2.5 Alternate icons pre-shipped for future PPO icon tests
- detect: CODE `EV.code.alticons`
- rule: ✅ candidate alternate icons in the shipped asset catalog · 🔴 none (icon PPO tests blocked one full release)
- new-app: code — ship candidates in v1.0; unused alternates cost nothing
- fix: generators/product-page-optimization → /apple:icon

## P3 — Localization

#### P3.1 Metadata-only localization for the big seven — core
- detect: MCP `EV.locales`
- rule: ✅ ≥7 of {ja, de, fr, es, pt-BR, ko, zh-Hans} localized (title/subtitle/keywords minimum) · 🟠 1–6 non-English locales · 🔴 English only
- new-app: plan — metadata-only is Level 0 localization; the app itself can wait
- fix: product/localization-strategy → /apple:localize

#### P3.2 Per-storefront ratings strategy
- detect: HYBRID — `EV.territories` (where it's sold) + MANUAL (prompting strategy per market)
- rule: ✅ aware ratings don't carry across storefronts AND prompting actively in each target market · 🟠 selling wide, prompting only at home · 🔴 assumed the home rating shows everywhere
- new-app: defer — activates with first non-home-market push
- fix: app-store/ratings-mechanics → /apple:localize

#### P3.3 PPP pricing for India, Brazil, Turkey, Indonesia
- detect: MCP `EV.pricing` + `EV.pricepoints`
- rule: ✅ manual price points set for IN/BR/TR/ID below auto-equalized levels · 🟠 some manual overrides · 🔴 pure auto-equalization · applies-if: paid app or IAP/subs sold in those territories
- new-app: plan
- fix: monetization (pricing-models, Pricing Localization) → ASC pricing (dry-run via /apple:ship)

#### P3.4 App itself localized where demand is proven
- detect: HYBRID — `EV.sales`/`EV.analytics` by territory vs `EV.code.locales`
- rule: ✅ in-app localization matches the markets producing revenue · 🟠 a market >15% of revenue still un-localized in-app · 🔴 localized nowhere despite proven foreign demand · ⚪ no foreign demand signal yet
- new-app: defer
- fix: product/localization-strategy → /apple:localize

#### P3.5 Metadata updates automated via the ASC API
- detect: CODE `EV.code.automation`
- rule: ✅ scripted/bulk metadata pushes (fastlane deliver, ASC API scripts, bulk tooling) · 🟠 partially scripted · 🔴 35+ locales maintained by hand
- new-app: plan
- fix: /apple:localize + /apple:metadata (bulk update paths) — standalone: `_shared/asc-api`

## P4 — Ratings machinery

#### P4.1 requestReview at success moments — core
- detect: CODE `EV.code.reviewprompt`
- rule: ✅ requestReview called at a success moment with condition gating · 🟠 called but at launch/random (guideline-safe but conversion-poor) · 🔴 never prompts
- new-app: code
- fix: generators/review-prompt → /apple:build

#### P4.2 Negative reviews answered — core
- detect: MCP `EV.reviews`
- rule: ✅ 1–3★ reviews from the last 90 days have developer responses · 🟠 some answered · 🔴 none answered (updated ratings replace old scores — replies are recoverable stars)
- new-app: defer — activates with first reviews
- fix: app-store/review-response-writer → route replies via ASC (surfaced by /apple:learn-from-store)

#### P4.3 Phased release + manual version release habit
- detect: MANUAL Q7
- rule: ✅ both habits (7-day phased rollout, manual release after approval) · 🟠 one · 🔴 auto-release, full blast (one bad build can nuke the rating before you wake up)
- new-app: plan — set on the first release
- fix: app-store/ratings-mechanics → /apple:ship (phased release step)

#### P4.4 Never reset the ratings summary — guardrail
- detect: MANUAL (only if a reset is being considered; default ✅)
- rule: ✅ no reset planned/performed · 🔴 reset planned or recently performed
- new-app: plan — note the rule before v2.0 temptation arrives
- fix: app-store/ratings-mechanics (read it before touching the toggle)
