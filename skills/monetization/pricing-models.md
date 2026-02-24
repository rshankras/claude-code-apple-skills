# Pricing Models Reference

Detailed comparison of monetization models for Apple platform apps.

## 1. Auto-Renewable Subscriptions

**How it works**: User pays recurring fee (weekly/monthly/quarterly/yearly). Apple handles billing, renewals, and cancellation.

**Best for**: Apps with ongoing value — content, sync, storage, AI features, data tracking.

**Pros:**
- Predictable recurring revenue (MRR)
- Higher lifetime value (LTV) per user
- Apple reduces commission to 15% after Year 1
- Built-in trial support (introductory offers)
- Family sharing support
- Subscription offer codes for marketing

**Cons:**
- Users increasingly wary of "subscription fatigue"
- Higher churn — must continuously deliver value
- More complex to implement than one-time purchase
- Requires demonstrating ongoing value to App Review

**Revenue math:**
```
Monthly: $4.99/mo × 1,000 subscribers = $4,990/mo
Apple cut (15% SBP): -$748.50
Net: $4,241.50/mo = $50,898/yr
```

**Pricing sweet spots (indie apps):**
- Low: $2.99-4.99/mo (utility, habit tracking)
- Mid: $6.99-9.99/mo (productivity, creative tools)
- High: $14.99-29.99/mo (professional tools, B2B)

**Subscription groups:**
- Group related tiers (Free, Plus, Pro) in one subscription group
- Users can upgrade/downgrade within a group
- Only one active subscription per group

---

## 2. One-Time Purchase (Paid Upfront)

**How it works**: User pays once to download the app. No free version.

**Best for**: Complete, self-contained tools with clear value.

**Pros:**
- Simple — no ongoing obligation
- Users prefer paying once
- No churn management
- Easy to implement

**Cons:**
- Revenue stops after initial download surge
- Must acquire new users for continued revenue
- No recurring revenue (harder to sustain development)
- Race to the bottom on pricing
- Harder to justify major updates without new revenue

**Pricing sweet spots:**
- Simple utility: $0.99-2.99
- Quality tool: $4.99-9.99
- Professional tool: $14.99-49.99
- Niche/specialized: $49.99-99.99+

**Sustainability tip:** Pair with a "Pro" IAP unlock for power features, or use paid major version upgrades (new App Store listing).

---

## 3. Freemium (Free + IAP Unlock)

**How it works**: App is free. Core features available. Premium features unlocked via non-consumable IAP.

**Best for**: Apps that need large user base, where free tier drives organic growth.

**Pros:**
- Low friction — massive download potential
- Users try before buying
- Word of mouth from free users
- Non-consumable IAP = one-time revenue per user

**Cons:**
- Most users never convert (typical: 2-5%)
- Must maintain free experience for 95%+ of users
- Feature split is tricky to get right
- Free users have expectations

**Conversion benchmarks:**
- Good: 3-5% free to paid
- Great: 5-10%
- Exceptional: 10%+ (niche apps with devoted users)

**Revenue math:**
```
10,000 MAU × 4% conversion × $9.99 = $3,996
Apple cut (15% SBP): -$599.40
Net: $3,396.60 (one-time, not recurring)
```

---

## 4. Consumable IAP

**How it works**: Users buy consumable items (credits, tokens, virtual currency) that get used up.

**Best for**: AI-powered apps (API costs), games, content generation tools.

**Pros:**
- Revenue scales with usage
- Can offset variable costs (API fees)
- Users self-select spending level
- Repeated purchases = recurring-ish revenue

**Cons:**
- Complex to balance (too expensive = churn, too cheap = unprofitable)
- Users dislike "running out"
- Harder to predict revenue
- Must track consumption carefully

**Common patterns:**
- Credit packs: 10 credits ($0.99), 50 ($3.99), 200 ($9.99)
- Token bundles with bonus: Buy 100, get 20 free
- Combined: Subscription includes X credits/month + buy more

---

## 5. Tip Jar / Patronage

**How it works**: App is fully functional for free. Users can tip/donate to support development.

**Best for**: Open-source-adjacent apps, community tools, passion projects.

**Pros:**
- Zero friction for users
- Builds goodwill
- Authentic relationship with users
- No feature gating complexity

**Cons:**
- Very low conversion (< 1% typical)
- Unpredictable revenue
- Not sustainable as sole model for most apps
- Apple still takes 30%/15% cut

**Implementation:**
- Non-consumable IAPs: "Buy me a coffee" ($1.99), "Supporter" ($4.99), "Patron" ($9.99)
- Or consumable for repeat tips

---

## 6. Ad-Supported + Premium

**How it works**: Free with ads. Pay to remove ads and unlock features.

**Best for**: High-volume, casual-use apps (weather, news, simple tools).

**Pros:**
- Revenue from both free (ads) and paid users
- Low barrier to entry
- Ad revenue scales with DAU

**Cons:**
- Ad revenue per user is very low ($0.50-3.00 eCPM)
- Ads degrade user experience
- Ad SDKs add complexity and privacy concerns
- "Remove ads" is weak premium value alone

**Revenue math:**
```
Ad revenue: 10,000 DAU × 3 impressions × $2.00 eCPM = $60/day = $1,800/mo
Premium upgrades: 10,000 MAU × 2% × $4.99 = $998
Total: ~$2,800/mo
```

**Tip:** Always pair ad removal with additional premium features. "Remove ads" alone isn't compelling enough.

---

## Model Selection Matrix

| Factor | Subscription | One-Time | Freemium | Consumable | Tip Jar | Ad + Premium |
|--------|-------------|----------|----------|------------|---------|-------------|
| Recurring revenue | ✅ | ❌ | ❌ | Partial | ❌ | Partial |
| User-friendly | ⚠️ | ✅ | ✅ | ⚠️ | ✅ | ⚠️ |
| Implementation complexity | High | Low | Medium | High | Low | Medium |
| Scalability | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ |
| Indie-friendly | ✅ | ✅ | ✅ | ⚠️ | ❌ | ⚠️ |
| Works with small audience | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## Hybrid Models

Many successful indie apps combine models:

**Freemium + Subscription:**
```
Free: Basic features
Pro Monthly ($4.99/mo): Full features
Pro Annual ($29.99/yr): Full features, 50% savings
Lifetime ($79.99): One-time unlock
```

**Subscription + Consumable:**
```
Free: 5 AI queries/day
Pro ($9.99/mo): 100 queries/day + premium features
Extra credits: Buy 50 for $1.99
```

**Free + Tip Jar + Premium:**
```
Free: Full app
Tips: $1.99, $4.99, $9.99
Pro ($4.99 one-time): Themes, widgets, export
```

## Pricing Localization

Apple provides 87 price tiers with automatic localization. Key considerations:

- **Price tier 1** ($0.99) is universal baseline
- Higher tiers have regional variation (e.g., Tier 5 = $4.99 US, ¥800 Japan)
- Some regions have purchasing power adjustments
- Consider offering **lower tiers in emerging markets** via App Store pricing tools
- Apple's "Pricing and Availability" now supports per-country pricing

## When to Change Your Price

**Raise prices when:**
- You've added significant new features
- Conversion rate is high (> 8%) — may be underpriced
- Competitors charge more for less
- Costs have increased (API, infrastructure)

**Lower prices when:**
- Conversion is very low (< 1%)
- Users cite price as reason for not upgrading
- Entering a new market
- Running a seasonal promotion

**How to test:**
- Use introductory offers for new price points
- A/B test with offer codes
- Announce upcoming price increase to drive urgency
