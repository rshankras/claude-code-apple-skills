---
name: bundles-and-licensing
description: Revenue beyond the single-app price tag — own-app bundles, Family Sharing as a conversion lever, cross-developer bundles & suites, and institutional licensing via Group Purchases / Apple School & Business Manager. Use when a developer has multiple apps, a subscription worth sharing, complementary indie partners, or school/clinic/business buyers.
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Bundles & Licensing

Four ways one piece of software earns more than one price tag.

## When This Skill Activates

- A portfolio developer asks how apps can sell each other ("bundle my apps?")
- Deciding whether to enable Family Sharing on a subscription or purchase
- Exploring partnerships with complementary indie apps
- Schools, clinics, or businesses keep asking "how do we buy 30 seats?"
- The store-growth audit flags P8.5, P8.6, or P8.7

## 1. Own-app bundles (available now)

App bundles group up to 10 of your own paid apps — or apps sharing a subscription — at a bundle
price, with **Complete My Bundle** crediting what a user already paid.

- ✅ Portfolio play: your catalog cross-sells itself on every member app's product page — a
  discovery surface, not just a discount (pairs with the checkbox-storefront and portfolio
  tactics in `app-store/marketing-strategy`).
- ✅ Price the bundle at "second app ~half off, third+ nearly free" — the goal is basket size
  and page presence, not margin per unit.
- ❌ Bundling apps with no shared audience; the bundle card confuses both product pages.
- Mechanics: paid apps only (or one subscription spanning the bundle); free apps can't bundle.

## 2. Family Sharing (available now — chronically under-enabled)

A checkbox per IAP/subscription in ASC, plus StoreKit handling for shared entitlements. One
purchase covers up to 5 additional family members — 6 entitlements, "6 for the price of 1".

- ✅ Enable for subscriptions whose *job* is shareable (utilities, education, health, home) —
  "the whole family for one price" beats a 6× cheaper feel at maybe 1.5× usage cost, and it's a
  paywall differentiator against non-sharing competitors.
- ✅ Drive paywall copy off `isFamilyShareable` rather than hardcoding "share with your family".
- ✅ Distinguish `ownershipType` — `PURCHASED` vs `FAMILY_PURCHASED` — to tailor onboarding;
  the family member never saw your paywall or purchase flow.
- ✅ Family entitlements arrive *outside* any purchase flow, and after a deliberate delay (the
  purchaser gets a window to disable sharing first) — listen on `Transaction.updates`, and
  check entitlement before merchandising (a family member may already be covered).
- ✅ Handle `revocationDate` + the REVOKE server notification by re-deriving entitlements from
  the full transaction history; test the revoked-from-family path.
- ❌ Enabling it on a per-seat B2B-ish product where sharing cannibalizes real seats — that's
  what volume licensing (below) is for.
- One-way door: enabling takes effect **within hours for new and existing customers** and is
  irreversible — turning it off only affects new purchases.

## 3. Cross-developer bundles & suites

Combined subscriptions spanning apps from *different* developers — the "indie suite" model
(several complementary tools, one subscription).

- The unlock: each partner's install base becomes the others' warm audience — distribution
  cheaper than any paid channel.
- ✅ Partner selection: same buyer, adjacent jobs, no feature overlap (writing tool + reference
  manager + focus timer, not three writing tools). Draft revenue-share on *attribution of the
  acquiring app*, not equal splits.
- ✅ Verify current ASC mechanics before promising a ship date — cross-developer suites are a
  recent capability and terms/tooling are still settling; the fallback is coordinated own-app
  pricing + mutual offer codes (`generators/offer-codes-setup`).
- ❌ Partnering with an app whose rating or privacy posture you wouldn't put your name on — a
  suite shares reputational blast radius (run `app-store/originality-check` thinking on partners).

## 4. Group Purchases & Volume Purchasing — institutional sales

Live for all auto-renewable subscriptions using StoreKit 2 (StoreKit 2 required). ON by default
for most new and existing StoreKit 2 subscriptions — but Family Sharing-enabled subscriptions
are opted OUT by default. Configure per subscription in ASC.

Two sale paths, same seat pool:
- **In-app group purchases** — a customer buys N seats, shares an invite link, and accepters are
  auto-assigned to seats.
- **Volume purchasing** through **Apple Business Manager / Apple School Manager** — the
  institutional channel for schools, clinics, and businesses.

Mechanics:
- **Volume pricing = up to 5 price bands**, with full control of seat thresholds and each band's
  price. The default is every seat at the current price — no discount exists until you configure
  bands (e.g., $19.99 → $13.99 at 21–40 seats → $10.99 at 41+; a 50-seat purchase then averages
  ~20% off).
- ✅ Prefer the built-in seat management (invites, acceptance tracking, seat lifecycle) unless
  you already run member management — then use the App Store Server API group endpoints instead.
- ✅ Merchandise the group value in-app — buyers won't discover multi-seat pricing on their own.
- ✅ Education/health apps: this often outearns consumer conversion optimization by an order of
  magnitude — one district buys more seats than a year of paywall A/B tests adds.
- ❌ Building custom seat management UI before validating a single institutional buyer exists —
  the built-in flow covers the first sale.
- Custom Apps via Apple Business Manager remain the path for bespoke B2B distribution; Group
  Purchases brings multi-seat to the mainstream store — different tools, same buyer.
- Reference: the WWDC26 session on group purchases and volume purchasing.

## Decision sketch

| You have | Reach for |
|---|---|
| 2+ paid apps, shared audience | Own-app bundle |
| A shareable-job subscription | Family Sharing on |
| A complementary indie peer with real traffic | Cross-developer suite (or mutual offer codes today) |
| Institutions asking to buy seats | Group Purchases / volume price bands (live — configure in ASC) |

## Output Format

```
Portfolio: bundle-eligible apps? bundle live? Complete-My-Bundle pricing sane?
Family Sharing: enabled where the job is shareable? entitlement handling tested?
Partnerships: candidate named? terms sketched?
Institutional: demand evidence? seats model drafted? volume price bands configured?
```

Each gap routed to the numbered section above; StoreKit implementation to
`generators/subscription-lifecycle`, offer distribution to `generators/offer-codes-setup`.

## References

- https://developer.apple.com/help/app-store-connect/create-an-app-bundle/
- https://developer.apple.com/documentation/storekit/supporting-family-sharing-in-your-app
- https://support.apple.com/guide/apple-business-manager/welcome/web
- Related skills: `monetization` (pricing/tiers), `generators/subscription-lifecycle`, `generators/offer-codes-setup`, `growth/store-growth-audit`
