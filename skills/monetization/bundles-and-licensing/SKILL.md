---
name: bundles-and-licensing
description: Revenue beyond the single-app price tag — own-app bundles, Family Sharing as a conversion lever, cross-developer bundles & suites, and institutional licensing via Group Purchases / Apple School & Business Manager. Use when a developer has multiple apps, a subscription worth sharing, complementary indie partners, or school/clinic/business buyers.
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Bundles & Licensing

Four ways one piece of software earns more than one price tag. Ordered from
available-today to announced.

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

A checkbox per IAP/subscription in ASC, plus StoreKit handling for shared entitlements.

- ✅ Enable for subscriptions whose *job* is shareable (utilities, education, health, home) —
  "the whole family for one price" beats a 6× cheaper feel at maybe 1.5× usage cost, and it's a
  paywall differentiator against non-sharing competitors.
- ✅ Handle `Transaction.currentEntitlements` for family members who never purchased; test the
  revoked-from-family path.
- ❌ Enabling it on a per-seat B2B-ish product where sharing cannibalizes real seats — that's
  what volume licensing (below) is for.
- One-way door: you can turn Family Sharing **on** for existing subscribers, but turning it off
  only affects new purchases.

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

> Status: announced (WWDC26) — verify availability in App Store Connect before executing.

Multi-seat subscription purchases and licensing through **Apple School Manager / Apple Business
Manager** — the institutional unlock if your buyers are schools, clinics, or businesses.

- prep now: identify whether an institutional segment already exists in your reviews/support mail
  ("can we get this for our class/team?"); design a seats model (who assigns, who owns data) and
  per-seat pricing before the tooling lands.
- Custom Apps via Apple Business Manager exist today for bespoke B2B distribution; Group
  Purchases extends the mainstream store to multi-seat — different tools, same buyer.
- ✅ Education/health apps: this often outearns consumer conversion optimization by an order of
  magnitude — one district buys more seats than a year of paywall A/B tests adds.
- ❌ Building seat management UI before validating a single institutional buyer exists.

## Decision sketch

| You have | Reach for |
|---|---|
| 2+ paid apps, shared audience | Own-app bundle |
| A shareable-job subscription | Family Sharing on |
| A complementary indie peer with real traffic | Cross-developer suite (or mutual offer codes today) |
| Institutions asking to buy seats | Group/Volume Purchasing prep now, ship when live |

## Output Format

```
Portfolio: bundle-eligible apps? bundle live? Complete-My-Bundle pricing sane?
Family Sharing: enabled where the job is shareable? entitlement handling tested?
Partnerships: candidate named? terms sketched?
Institutional: demand evidence? seats model drafted? feature availability rechecked?
```

Each gap routed to the numbered section above; StoreKit implementation to
`generators/subscription-lifecycle`, offer distribution to `generators/offer-codes-setup`.

## References

- https://developer.apple.com/help/app-store-connect/create-an-app-bundle/
- https://developer.apple.com/documentation/storekit/supporting-family-sharing-in-your-app
- https://support.apple.com/guide/apple-business-manager/welcome/web
- Related skills: `monetization` (pricing/tiers), `generators/subscription-lifecycle`, `generators/offer-codes-setup`, `growth/store-growth-audit`
