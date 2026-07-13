# Audit Checklist P5–P9 — Growth Loops (29 items)

Stanza format, flags, status vocabulary, and `new-app:` semantics are defined in `SKILL.md`.
Evidence keys (`EV.*`) are defined in `detection-playbook.md`. IDs are stable — never renumber.

## P5 — Experimentation

#### P5.1 Product Page Optimization running as a habit — core
- detect: MCP `EV.ppo`
- rule: ✅ a PPO experiment ran in the last 2 quarters or after the last asset change · 🟠 ran once, long ago · 🔴 never (up to 3 treatments on organic traffic, one variable at a time)
- new-app: defer — activates ~30 days post-launch (needs traffic)
- fix: generators/product-page-optimization → /apple:experiment

#### P5.2 Custom Product Pages for distinct audiences
- detect: MCP `EV.cpp`
- rule: ✅ CPPs live and mapped to audiences/campaigns (35 slots available) · 🟠 one token CPP · 🔴 none despite distinct audiences · ⚪ genuinely single-audience app
- new-app: defer
- fix: generators/custom-product-pages → /apple:experiment

#### P5.3 Creative Assets — ⏳ ANNOUNCED (WWDC26)
> Status: announced (WWDC26) — verify availability in App Store Connect before executing.
- prep: keep a motion-capable asset library (from PPO/CPP work) ready — rich video/animated media for the product-page header and search results, submittable without an app update
- recheck: every audit — is the Creative Assets section live in ASC? When live, apply:
- dormant rule: ✅ rich media asset live in header/search · 🔴 not adopted within a quarter of availability
- fix: app-store/screenshot-planner → /apple:screenshots

#### P5.4 In-app events cadence + badge variety
- detect: MCP `EV.events`
- rule: ✅ ≥1 event per quarter, badges varied by purpose · 🟠 sporadic events · 🔴 never used · applies-if: app has event-worthy moments (else ⚪)
- new-app: defer
- fix: generators/in-app-events → /apple:event
- note: new badge types (Now On Sale, Try Before You Buy) are ⏳ ANNOUNCED (WWDC26) — recheck each audit

## P6 — Featuring & free discovery

#### P6.1 Featuring nominations as a rolling calendar — core, RECURRING
- detect: MANUAL Q8 + the scorecard's Recurring Calendar
- rule: ✅ nomination submitted for the current cycle AND next moment scheduled 6–8 weeks ahead · 🟠 submitted once, no calendar · 🔴 never nominated
- new-app: plan — first nomination at launch (launches are featuring moments)
- fix: generators/featuring-nomination → ASC manual (calendar maintained by the audit)

#### P6.2 New-OS APIs adopted at launch
- detect: HYBRID — `EV.code.newapis` + MANUAL timing (shipped within the new OS's launch window?)
- rule: ✅ current-cycle APIs adopted in a launch-window release (the most reliable featuring trigger) · 🟠 adopted late · 🔴 still targeting only old APIs
- new-app: code — build against the current SDK's new surfaces from day one
- fix: /apple:modernize — standalone: design/ + apple-intelligence/ adoption skills

#### P6.3 Secondary category set
- detect: MCP `EV.meta` (categories)
- rule: ✅ secondary category set and deliberately chosen (second chart presence) · 🔴 empty
- new-app: plan
- fix: /apple:ship (category step) — standalone: app-store/marketing-strategy (decision-matrix)

#### P6.4 Checkbox storefronts shipped where sensible
- detect: HYBRID — `EV.code.platforms` + `EV.territories`
- rule: ✅ viable easy ports shipped (Mac via Catalyst/iPad-on-Mac, visionOS, watchOS, tvOS — tiny catalogs, easy charts and featuring) · 🟠 viable port identified but not shipped · ⚪ no sensible port
- new-app: plan — check the checkbox platforms at project setup
- fix: /apple:new-app (platform choice) / /apple:plan — standalone: visionos/, watchos/, ios/ipad-patterns

#### P6.5 App Intents as an out-of-store discovery channel
- detect: CODE `EV.code.intents` + `EV.code.spotlight`
- rule: ✅ App Shortcuts + Spotlight indexing shipped (Siri, Spotlight, Shortcuts become discovery surfaces) · 🟠 intents exist but no AppShortcutsProvider/Spotlight · 🔴 none
- new-app: code
- fix: apple-intelligence/app-intents + generators/spotlight-indexing → /apple:plan

#### P6.6 Web presence: apps.apple.com SEO + landing page + Smart App Banner
- detect: MANUAL Q9 (CODE if a web repo is at hand)
- rule: ✅ landing page live with Smart App Banner, store page ranks for the app's name queries · 🟠 landing page only · 🔴 no web presence
- new-app: plan — the store's web page ranks on Google from day one; give it help
- fix: app-store/web-presence

## P7 — Paid & external traffic

#### P7.1 Apple Ads ladder: discovery → exact-match winners (+ CPP pairing)
- detect: MANUAL Q4 + `EV.cpp` (paired pages)
- rule: ✅ discovery feeding exact-match campaigns, winners paired with matching CPPs · 🟠 ads running unstructured · 🔴/⚪ no ads (⚪ if deliberately organic-only and P1–P6 healthy)
- new-app: defer — paid comes after the free machinery works
- fix: app-store/apple-search-ads → /apple:aso if installed

#### P7.2 Brand term defended
- detect: MANUAL Q4
- rule: ✅ brand campaign live (competitors bid on your name; brand CPAs are cheap) · 🟠 unsure · 🔴 brand undefended while competitors bid · applies-if: running ads or brand has search volume
- new-app: defer
- fix: app-store/apple-search-ads

#### P7.3 ASA→organic halo tracked
- detect: MANUAL
- rule: ✅ organic rank movement watched on paid keywords (paid conversion lifts organic rank) · 🟠 not tracked · ⚪ no ads
- new-app: defer
- fix: app-store/apple-search-ads + growth/store-signals → /apple:learn-from-store

#### P7.4 Compressed launch spikes
- detect: MANUAL Q10 / `.planning/` launch plan
- rule: ✅ last major release compressed Product Hunt + press embargo + newsletter into 48h (chart velocity beats volume) · 🟠 channels used but spread out · 🔴 launches go out quietly
- new-app: plan — write the spike plan before launch week
- fix: growth/press-media + growth/community-building → /apple:release-notes (assets)

#### P7.5 Deal-site ecosystem used for price drops
- detect: MANUAL Q9
- rule: ✅ price drops timed knowing aggregators auto-scrape them (spike → chart climb → organic tail) · 🟠 price drops happen unannounced · ⚪ free app, no price to drop
- new-app: defer
- fix: app-store/web-presence (deal-site section)

#### P7.6 Pre-orders used (including regionally)
- detect: MANUAL Q11 + `EV.territories`
- rule: ✅ pre-orders used at launch or regionally when entering new storefronts (up to 180 days of accumulated taps) · 🟠 known but unused at last opportunity · ⚪ no upcoming launch/expansion
- new-app: plan — decide pre-order length before first submission
- fix: generators/pre-orders → /apple:ship

#### P7.7 Offer codes distributed
- detect: MANUAL Q11 + `EV.iaps`/`EV.subs`
- rule: ✅ URL-redeemable codes in use for influencers/communities/conferences · 🟠 configured, never distributed · 🔴 unused despite subs/IAP · applies-if: has subs/IAP
- new-app: defer
- fix: generators/offer-codes-setup → /apple:subscription

#### P7.8 TestFlight public link as a waitlist
- detect: MANUAL Q11
- rule: ✅ public link doubled as pre-launch waitlist (up to 10k testers → day-one installers) · 🟠 TestFlight private-only pre-launch · ⚪ already long-launched with no major relaunch coming
- new-app: plan
- fix: product/beta-testing → /apple:testflight

## P8 — Earnings

#### P8.1 Paywall + pricing experiments — core
- detect: HYBRID — `EV.code.paywall` + MANUAL Q12
- rule: ✅ paywall variable (trial length, intro offer, layout) tested in the last 2 quarters · 🟠 paywall shipped, never experimented · 🔴 no deliberate paywall · applies-if: monetized
- new-app: plan (paywall) / defer (experiments)
- fix: generators/paywall-generator + monetization → /apple:subscription

#### P8.2 Win-back offers configured
- detect: MCP `EV.subs` (offers) — MANUAL fallback
- rule: ✅ win-back offers live (the App Store surfaces them to lapsed subscribers by itself) · 🔴 not configured · applies-if: subscriptions ≥ minimum eligibility
- new-app: defer
- fix: generators/win-back-offers → /apple:subscription

#### P8.3 Retention Messaging (save offer at cancel) — ⏳ ANNOUNCED (WWDC26)
> Status: announced (WWDC26) — verify availability in App Store Connect before executing.
- prep: draft the save-offer copy and eligibility rules now; decide the discount you can afford at the cancel moment
- recheck: every audit — Retention Messaging live in ASC/API? When live, apply:
- dormant rule: ✅ save offer configured at cancel moment · 🔴 not configured within a quarter of availability · applies-if: subscriptions
- fix: generators/win-back-offers (Retention Messaging section) → /apple:subscription

#### P8.4 US web checkout / External Purchase Links — core
- detect: HYBRID — CODE `EV.code.extpurchase` + MANUAL Q13
- rule: ✅ shipped with commission-flip architecture + analytics from day one (currently 0% commission; litigation ongoing — re-verify) · 🟠 planned/considered · 🔴 not considered · applies-if: US storefront + digital goods revenue
- new-app: plan — architect the flip switch before you need it
- fix: monetization/external-purchases

#### P8.5 Cross-developer bundles & suites
- detect: MANUAL Q14
- rule: ✅ partnered bundle live or in motion with complementary indie apps · 🟠 explored · ⚪ no sensible partner category
- new-app: defer
- fix: monetization/bundles-and-licensing

#### P8.6 Group Purchases + Volume Purchasing — ⏳ ANNOUNCED (WWDC26)
> Status: announced (WWDC26) — verify availability in App Store Connect before executing.
- prep: identify whether schools/clinics/businesses buy your app; if yes, prepare multi-seat pricing now
- recheck: every audit — Group Purchases / Apple School & Business Manager licensing live? When live, apply:
- dormant rule: ✅ institutional licensing configured · 🔴 institutional demand exists but unconfigured · applies-if: B2B/edu buyer segment
- fix: monetization/bundles-and-licensing

#### P8.7 Own-app bundles + Family Sharing
- detect: MCP `EV.iaps` + `EV.subs` (familySharable) + MANUAL (bundles)
- rule: ✅ Family Sharing enabled where it fits AND multi-app developers bundle their own apps · 🟠 either unexamined · ⚪ single free app · applies-if: paid/subs
- new-app: plan
- fix: monetization/bundles-and-licensing → /apple:subscription

## P9 — Retention loop & ops

#### P9.1 Retention surfaces shipped
- detect: CODE — `EV.code.onboarding`, `EV.code.notifications`, `EV.code.widgets`, `EV.code.liveactivity`
- rule: ✅ onboarding + notifications + at least one ambient surface (widget/Live Activity) · 🟠 some · 🔴 none (retention feeds both ranking and LTV)
- new-app: code
- fix: generators/onboarding-generator, push-notifications, widget-generator, live-activity-generator → /apple:plan

#### P9.2 Quarterly keyword refresh from ASA search-term reports — core, RECURRING
- detect: MANUAL Q15 + the scorecard's Recurring Calendar
- rule: ✅ refresh done within the last quarter with search-term data · 🟠 refreshed without paid-data input · 🔴 keywords untouched for two-plus quarters
- new-app: defer — first refresh one quarter after launch
- fix: app-store/keyword-optimizer (advanced-tactics §14) → /apple:metadata

#### P9.3 Update freshness
- detect: MCP `EV.meta` (current version's release recency)
- rule: ✅ shipped within ~8–12 weeks (each release re-triggers indexing + freshness signals) · 🟠 3–6 months · 🔴 6+ months stale
- new-app: ⚪ pre-launch
- fix: /apple:next-version — standalone: growth/store-signals for what to ship

#### P9.4 The re-run loop is closed — RECURRING
- detect: the scorecard itself — Recurring Calendar rows have `last done` within cadence
- rule: ✅ PPO re-run after last asset change, featuring calendar rolling, benchmarks rechecked · 🟠 calendar exists, rows overdue · 🔴 no calendar
- new-app: plan — seed the calendar at launch
- fix: this skill (re-audit) + generators/product-page-optimization + growth/analytics-interpretation
