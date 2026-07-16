---
name: ratings-mechanics
description: How App Store ratings actually behave — per-storefront isolation (your US stars show nowhere else), the never-reset rule, phased release + manual release as rating protection, and where prompting/replying fit. Use when planning ratings strategy for new markets, considering a ratings reset, setting release options, or diagnosing "why is my rating missing in country X."
allowed-tools: [Read, Write, Edit, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# Ratings Mechanics

The rating is an asset with mechanics most developers learn the hard way. This skill covers the
four rules that aren't obvious from the ASC UI. Prompting *code* lives in
`generators/review-prompt`; reply *writing* lives in `app-store/review-response-writer` — this
skill is the strategy layer that tells you when each matters.

## When This Skill Activates

- Localizing or expanding into new storefronts ("why does my app show no rating in Japan?")
- Considering the "reset ratings summary" option on a version release
- Choosing release options before submitting (phased vs immediate, auto vs manual)
- Planning a per-market ratings strategy alongside `product/localization-strategy`
- A bad build or review-bomb is threatening the rating

## Rule 1: Ratings are per-storefront — they do not travel

Your 4.8★ from 2,000 US ratings renders as **no rating at all** on the Japanese storefront until
Japanese users rate the app there. Every storefront starts from zero.

Consequences:

- ✅ Entering a new market = re-running the early-days ratings playbook *in that market*: prompt
  eagerly (within guidelines), localize the prompt moment, reply to every early review.
- ✅ Weight `requestReview` triggers by storefront maturity — a market with 12 ratings needs the
  prompt more than the home market with 5,000.
- ❌ Assuming social proof transfers with the binary. A localized listing with zero local ratings
  converts like an unknown app, because there it *is* one.
- The written-review pool is also per-storefront: expect empty review sections in fresh markets
  and seed them via TestFlight communities or launch outreach in that region.

## Rule 2: Never reset the ratings summary

ASC offers a reset when you release a new version. It is almost always a mistake:

- Reset discards the count as well as the average — 4.2★ from 3,000 ratings converts better than
  a naked 5.0★ from 6, and the count never comes back except one rating at a time.
- The instinct to reset ("v2 is a big rewrite, old reviews don't apply") is better served by
  replying to outdated negative reviews (updated ratings **replace** the old score — see
  `review-response-writer`) and by the What's New copy.
- ✅ Legitimate near-exception: a catastrophic launch (sub-3★, low count, fixed root cause) on an
  app with almost no ratings mass. Even then, run the math on count loss first.
- ❌ Resetting an established app to chase a higher average. You'll rank and convert worse for
  months.

## Rule 3: Phased release + manual release are rating armor

Two ASC toggles turn a bad build from a rating catastrophe into a contained incident:

- **Manual version release** — approval ≠ release. Release when you're awake and watching
  crash dashboards, not whenever review finishes.
- **Phased release** — 7-day staged rollout (1% → 2% → 5% → 10% → 20% → 50% → 100%) to users
  with automatic updates. A crashing build caught on day 1–2 has burned ~3% of your users;
  **pause** the rollout, fix, resubmit. Without it, 100% of users get the bad build and the
  1-star flood arrives before the hotfix does.
- ✅ Default for every release: phased ON + manual release + monitor day-1 crash rate.
- ❌ Halting a phased release as a rollback. Pausing stops *new* deliveries only — users who got
  the build keep it, and manual App Store downloads always get the new version. The armor is
  damage *limitation*; the fix still has to ship.

## Rule 4: The prompt-and-reply loop is the only rating input you control

- **Prompt** at success moments with `requestReview` — never at launch, never mid-task. Aim the
  moment, cap the frequency, and localize what "success" means per market. Implementation:
  `generators/review-prompt`.
- **Reply** to negative reviews — when a user updates their review after a reply, the new score
  replaces the old one in the average. Replies are the only mechanism that converts existing
  1-stars into 4-stars. Templates: `app-store/review-response-writer`.
- Per-storefront corollary: track "unanswered negative reviews" per market, not globally — a
  5-review storefront is one bad review away from 60% negative.

## Output Format

When auditing an app's ratings posture, report per storefront:

```
Storefront | Rating (count) | Unanswered 1–3★ (90d) | Prompt localized? | Phased+manual habit?
```

flagging: fresh storefronts with no prompting plan, any reset consideration (🔴 stop), and
releases going out unphased.

## References

- https://developer.apple.com/documentation/storekit/requesting-app-store-reviews
- https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases
- https://developer.apple.com/help/app-store-connect/monitor-app-performance/reset-your-app-s-summary-rating
- Related skills: `generators/review-prompt`, `app-store/review-response-writer`, `product/localization-strategy`, `growth/store-growth-audit`
