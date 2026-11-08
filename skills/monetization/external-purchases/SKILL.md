---
name: external-purchases
description: US web checkout for digital goods — on the US storefront, buttons, external links and calls to action need no entitlement (Guideline 3.1.1(a)); currently 0% Apple commission (litigation ongoing), how to ship it safely, and how to architect for a commission flip so a future ruling is a config change, not a rewrite. Use when adding external purchase links, weighing web checkout vs IAP, or planning US-storefront pricing strategy.
allowed-tools: [Read, Write, Edit, Glob, Grep]
last_verified: 2026-11-08
review_by: 2027-06-22
---

# External Purchases (US Web Checkout)

On the **US storefront**, apps may include buttons, external links, and other calls to action
to a web checkout for digital goods, with **no entitlement required** (Guideline 3.1.1(a), as of
the 2026-10-16 update). As of mid-2026, court orders have Apple's
commission on those purchases at **0%**, with the fee case still moving through district court.
This is the largest indie revenue unlock of the era, and it is *reversible by a ruling* — so the
engineering rule is: **ship it now, architect it so a commission can be flipped on later.**

> Verify current state before relying on this. The guideline text, the commission rate, and
> the litigation status have each changed more than once. The commission figures and litigation
> notes come from court orders, not from the App Review Guidelines. Treat every number here as
> "true as of 2026-07, re-check."

## When This Skill Activates

- "Add a web checkout / Stripe / external purchase link" for digital goods
- Deciding IAP vs web checkout for a US-heavy revenue base
- The store-growth audit flags P8.4
- Reviewing an app whose external links might be non-compliant (links shown outside the US storefront without an entitlement)

## The rules of the road

Guideline 3.1.1(a) splits the world into three cases:

| Storefront | External purchase buttons / links / calls to action |
|---|---|
| **United States** | Allowed. **No entitlement required.** |
| **Specific other regions** (where Apple offers it) | Allowed only with a **StoreKit External Purchase Link Entitlement** (or, where permitted, a **Music Streaming Services Entitlement**), linking to a *permitted destination*. Approved destinations vary by region and the entitlement is limited to certain platforms. |
| **All other storefronts** | **Prohibited.** Apps and their metadata may not direct customers to purchasing mechanisms other than IAP. |

- **Gate by storefront.** A US-only checkout link must not appear on other storefronts. Read
  `Storefront.current` (StoreKit 2) and show the link only where it is allowed.
- **Outside the US, follow the entitlement's terms**: the entitlement plus its `Info.plist`
  declaration, and the `ExternalPurchaseLink` / disclosure sheet where the entitlement requires
  it. Don't extrapolate US rules to EU, JP, KR, or other regions.
- Don't dark-pattern the IAP option away if you keep both. Misleading marketing, scams, or
  fraud around external purchase links can get the app removed and you expelled from the
  Developer Program (3.1.1(a)).
- Purchases made on the web are **your** customer relationship — payment processor, refunds,
  taxes; Apple's merchant-of-record role no longer applies.

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
Status: storefront gating correct (US: no entitlement needed; entitlement regions: entitlement +
permitted destination; elsewhere: no link)? ·
link-out service centralized? · CommissionPolicy flippable? · funnel analytics live?
Verdict + the one next step.
```

## References

- https://developer.apple.com/documentation/storekit/externalpurchaselink
- https://developer.apple.com/support/storekit-external-entitlement-us/
- https://developer.apple.com/app-store/review/guidelines/#in-app-purchase
- Related skills: `app-store/rejection-handler` (the external-link rejection pattern outside the US), `generators/subscription-lifecycle`, `monetization` (pricing), `growth/store-growth-audit`
