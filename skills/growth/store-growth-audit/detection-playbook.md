# Detection Playbook — gather once, evaluate 54

The audit's evidence-gathering machinery. Run **all three passes up front**, store the evidence
under the keys below, then evaluate every checklist item against the stored evidence. Never
interleave gathering with scoring; never ask MANUAL questions one at a time.

## Pass 1 — MCP evidence batch (read-only, ~14 calls)

One call per row; each populates an evidence key consumed by the listed items.

| Call | Evidence key | Feeds items |
|------|--------------|-------------|
| `list_apps` | `EV.app` (appId, state, live?) | mode detection |
| `get_metadata` | `EV.meta` (name, subtitle, keywords, description, promo text, categories, URLs, version, what's-new) | P1.1 P1.2 P1.6 P1.7 P2.2 P2.3 P2.4 P6.3 P9.3 |
| `list_locales` | `EV.locales` (localized locales + per-locale fields) | P1.2 P3.1 P3.4 |
| `get_app_pricing` | `EV.pricing` (base price + per-storefront overrides) | P3.3 |
| `list_price_points` | `EV.pricepoints` (available tiers per storefront) | P3.3 |
| `get_availability` | `EV.territories` (territories, platforms) | P3.2 P6.4 P7.6 |
| `list_iap` | `EV.iaps` (IAPs, display names, familySharable) | P1.4 P7.7 P8.7 |
| `list_subscription_groups` + `list_subscriptions` | `EV.subs` (groups, tiers, offers, familySharable) | P0.2 P8.1 P8.2 P8.7 |
| `list_app_events` | `EV.events` (events, badges, dates, metadata) | P1.5 P5.4 |
| `list_experiments` | `EV.ppo` (PPO experiments + states + dates) | P2.1 P5.1 P9.4 |
| `list_custom_pages` | `EV.cpp` (custom product pages) | P5.2 P7.1 |
| `get_analytics_report` | `EV.analytics` (impressions, page views, CVR, retention, sources) | P0.3 P3.4 baseline snapshot |
| `get_sales_report` | `EV.sales` (units/proceeds, by territory) | P3.4 baseline snapshot |
| `list_reviews` | `EV.reviews` (recent reviews, stars, developer-response present?) | P4.2 |

Pre-launch mode: skip the batch (no live app); `EV.meta`-class evidence comes from
`.planning/ASO.md`, `APP.md`, `ROADMAP.md` instead. Analytics not configured yet → note
"baseline lands next cycle — route to store-signals to set up" (never call setup from the audit).

## Pass 2 — codebase grep batch

One pass over the app repo (skip if no codebase is at hand — affected items fall back to MANUAL).

| Pattern (Grep/Glob) | Evidence key | Feeds items |
|---------------------|--------------|-------------|
| `requestReview\|SKStoreReviewController\|AppStore.requestReview` | `EV.code.reviewprompt` | P4.1 |
| `setAlternateIconName\|CFBundleAlternateIcons` + alternate entries in `*.xcassets` | `EV.code.alticons` | P2.5 |
| `import AppIntents\|AppShortcutsProvider\|INIntent` | `EV.code.intents` | P6.5 |
| `CSSearchableItem\|CoreSpotlight` | `EV.code.spotlight` | P6.5 |
| `import WidgetKit` / `import ActivityKit` | `EV.code.widgets` / `EV.code.liveactivity` | P9.1 |
| `UNUserNotificationCenter\|requestAuthorization` | `EV.code.notifications` | P9.1 |
| onboarding flow markers (`Onboarding`, first-run flags) | `EV.code.onboarding` | P9.1 |
| `com.apple.developer.storekit.external-purchase` in `*.entitlements` | `EV.code.extpurchase` | P8.4 |
| `*.storekit` config, `SubscriptionStoreView\|StoreKit` paywall views | `EV.code.paywall` | P8.1 |
| deletion flow (`deleteAccount`, account-deletion UI) | `EV.code.accountdeletion` | P2.4 |
| `*.lproj` dirs / locales inside `*.xcstrings` | `EV.code.locales` | P3.4 |
| platform targets in `project.pbxproj` (`SDKROOT`, `SUPPORTED_PLATFORMS`, Catalyst flag) | `EV.code.platforms` | P6.4 |
| fastlane/ASC-API scripts (`fastlane/`, `deliver`, `app_store_connect_api_key`, metadata upload scripts) | `EV.code.automation` | P3.5 |
| new-OS API adoption (imports gated by current-year `#available`) | `EV.code.newapis` | P6.2 |

## Pass 3 — the MANUAL question batch

One `AskUserQuestion` round covering every MANUAL/HYBRID item the first two passes can't settle.
Ask only what's still unknown; phrase options so each maps directly to a status. "Not sure" is
always an option and always scores 🟠 *unverified*.

| # | Question | Maps to |
|---|----------|---------|
| 1 | Enrolled in the App Store Small Business Program? (enrolled / not enrolled / ineligible >$1M / not sure) | P0.1 |
| 2 | Billing Grace Period AND Billing Retry enabled in ASC? (both / one / neither / no subs) | P0.2 |
| 3 | Checked ASC peer-group benchmarks for this app? (yes, recently / long ago / never) | P0.3 |
| 4 | Apple Ads: any discovery campaign run for keyword research? Exact-match campaigns? Brand term defended? | P0.4 P7.1 P7.2 |
| 5 | Is the developer/brand name a deliberate, descriptive choice? | P1.3 |
| 6 | Privacy nutrition labels reviewed against current data collection? | P2.4 |
| 7 | Do you release phased + manual (not auto-release on approval)? | P4.3 |
| 8 | Any featuring nomination submitted in the last 6 months? A calendar for them? | P6.1 |
| 9 | Landing page live? Smart App Banner on it? Ever listed on deal sites during a price drop? | P6.6 P7.5 |
| 10 | Launch-spike playbook used at last major release (Product Hunt + press + newsletter inside 48h)? | P7.4 |
| 11 | Pre-orders ever used (incl. regionally for new storefronts)? Offer codes distributed? TestFlight public link used as a waitlist? | P7.6 P7.7 P7.8 |
| 12 | Paywall/pricing experiments run in the last two quarters? | P8.1 |
| 13 | US web-checkout / External Purchase Link entitlement: shipped, planned, or not considered? | P8.4 |
| 14 | Any cross-developer bundle conversations? Institutional (school/business) buyers in your audience? | P8.5 P8.6 |
| 15 | ASA search-term report folded into keywords in the last quarter? | P9.2 |

Trim the batch: drop questions already answered by evidence (e.g. `EV.code.extpurchase` present →
ask only about the commission-flip architecture, not whether it shipped). In portfolio mode ask
only the account-level questions (1, 3, 4-brand, 8) once for all apps.

## Freshness caveats

- Analytics/sales reports arrive on Apple's schedule; a missing report is "no data yet", not 🔴.
- `EV.reviews` developer-response coverage is the signal for P4.2 — count unanswered 1–3★ reviews
  from the last 90 days, don't judge tone here (that's `review-response-writer`'s job).
- Evidence strings must be terse and dated where MANUAL: `SBP: enrolled (user, 2026-07)`,
  `locales: en-US, de, ja`, `PPO: last experiment 2026-03 (stale)`.
