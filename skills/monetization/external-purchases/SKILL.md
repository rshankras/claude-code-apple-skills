---
name: external-purchases
description: US web checkout via the StoreKit External Purchase Link entitlement — currently 0% Apple commission (litigation ongoing), how to ship it safely, and how to architect for a commission flip so a future ruling is a config change, not a rewrite. Use when adding external purchase links, weighing web checkout vs IAP, or planning US-storefront pricing strategy.
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# External Purchases (US Web Checkout)

On the **US storefront**, apps may link out to a web checkout for digital goods using the
StoreKit External Purchase Link entitlement — and as of mid-2026, court orders have Apple's
commission on those purchases at **0%**, with the fee case still moving through district court.
This is the largest indie revenue unlock of the era, and it is *reversible by a ruling* — so the
engineering rule is: **ship it now, architect it so a commission can be flipped on later.**

> Verify current state before relying on this: the entitlement terms, the commission rate, and
> the litigation status have each changed more than once. Treat every number here as
> "true as of 2026-07, re-check."

## When This Skill Activates

- "Add a web checkout / Stripe / external purchase link" for digital goods
- Deciding IAP vs web checkout for a US-heavy revenue base
- The store-growth audit flags P8.4
- Reviewing an app whose external links might be non-compliant (wrong storefront, no entitlement)

## The rules of the road

- **US storefront only.** Elsewhere, Guideline 3.1.1 still applies in force (separate regimes
  exist in the EU/JP/KR — different entitlements, different terms; don't extrapolate from the US).
- **Entitlement required**: `com.apple.developer.storekit.external-purchase-link` in the app's
  entitlements + the matching `Info.plist` declarations. A bare `Link("Buy", …)` to your site
  without the entitlement is still a rejection (see `app-store/rejection-handler` §3.1.1).
- Present the link per the entitlement's UI terms (StoreKit's `ExternalPurchaseLink` /
  disclosure sheet where required). Don't dark-pattern the IAP option away if you keep both.
- Purchases made on the web are **your** customer relationship: your payment processor, your
  refunds, your taxes (Apple's commission was also Apple's merchant-of-record work — that work
  is now yours).

## Architecture: the commission flip

Design so that a future "Apple takes N% of external purchases initiated in-app" ruling changes a
config value, not your codebase:

- ✅ Route every in-app-initiated web checkout through **one** link-out service that stamps the
  session (`source=app`, timestamp, storefront) — web-organic checkouts stay unstamped. If a
  commission returns, it applies to a knowable, logged subset.
- ✅ Keep a single `CommissionPolicy` (remote-configurable): `rate`, `applies_to`,
  `effective_date`. Report/accrue against it from day one — at 0% it's just a counter.
- ✅ Log day-one analytics: link taps → checkout starts → completions, vs the IAP funnel. The
  conversion drop through a web checkout (Apple's sheet, Safari hop, payment form) is real;
  whether 0% beats IAP's frictionless 85–70% is an *empirical* per-app question.
- ❌ Scattering `openURL("https://…/buy")` calls through features — un-auditable, un-flippable.
- ❌ Ripping out StoreKit. Keep IAP as a fallback path (non-US storefronts still need it, and
  some US users convert better in-sheet).

## Decision sketch

| Situation | Lean |
|---|---|
| Subscriptions, US-heavy, ARPU high enough to absorb processor fees + your own support | Web checkout for new subs; keep IAP for the rest of world |
| Impulse-priced consumables/unlocks | IAP — checkout friction eats more than 15–30% commission |
| Existing subscriber base on IAP | Don't force-migrate; offer web at renewal decision points |
| B2B/prosumer, invoicing needs | Web checkout regardless of commission math |

## Output Format

```
Status: entitlement present? · storefront scope correct (US-only gating)? ·
link-out service centralized? · CommissionPolicy flippable? · funnel analytics live?
Verdict + the one next step.
```

## References

- https://developer.apple.com/documentation/storekit/externalpurchaselink
- https://developer.apple.com/support/storekit-external-entitlement-us/
- https://developer.apple.com/app-store/review/guidelines/#in-app-purchase
- Related skills: `app-store/rejection-handler` (the non-entitled rejection pattern), `generators/subscription-lifecycle`, `monetization` (pricing), `growth/store-growth-audit`
