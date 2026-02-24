---
name: monetization
description: Monetization strategy for iOS/macOS apps. Covers readiness assessment, pricing model selection, tier structuring, free trial strategy, and implementation guidance. Use when deciding what to charge, how to price, or planning monetization end-to-end.
allowed-tools: [Read, Write, Edit, Glob, Grep, WebSearch, AskUserQuestion]
---

# Monetization Strategy

End-to-end monetization guidance for Apple platform apps — from "should I charge?" to "here's your pricing page structure."

## When This Skill Activates

Use this skill when the user:
- Asks "should I monetize my app?" or "is my app ready to charge?"
- Wants help choosing between freemium, subscription, or one-time purchase
- Needs pricing tier recommendations
- Asks about free trial strategy
- Wants to plan monetization for a specific app type (kids, therapy, productivity, etc.)
- Mentions "pricing", "revenue model", or "how to make money from my app"
- Wants to understand Apple's commission structure

## Process

### Phase 1: Readiness Assessment

Before recommending a pricing model, evaluate whether the app is ready to monetize. Ask these questions via AskUserQuestion:

**1. App Stage**
- Pre-launch (idea/prototype)
- Beta / TestFlight
- Live with users (< 1K)
- Live with traction (1K+ users)

**2. Value Proposition**
- What problem does your app solve?
- Who is the target user?
- What alternatives exist (including doing nothing)?

**3. Current State**
- Do you have active users?
- What's your retention like? (Day 1, Day 7, Day 30)
- Are users asking for features / willing to pay?

#### Readiness Scorecard

Evaluate against these criteria:

| Signal | Ready | Not Ready |
|--------|-------|-----------|
| Core value | Clear, differentiated | Still finding product-market fit |
| User retention | D7 > 20% | D7 < 10% |
| User feedback | "I'd pay for this" | Silence or complaints |
| Feature depth | Enough for free + paid split | Everything feels essential |
| Competition | You offer something unique | Commodity feature set |
| Polish | Professional quality | Rough edges everywhere |

**Recommendation thresholds:**
- 5-6 Ready signals → Monetize now
- 3-4 Ready signals → Soft-launch pricing (low price, gather data)
- 0-2 Ready signals → Focus on product first, monetize later

### Phase 2: Pricing Model Selection

Based on app type and user behavior, recommend the right model.

#### Decision Framework

```
Is the app used daily/weekly?
├── YES → Does it provide ongoing value?
│   ├── YES → SUBSCRIPTION
│   └── NO → ONE-TIME PURCHASE (with optional tip jar)
└── NO → Is it a utility/tool?
    ├── YES → ONE-TIME PURCHASE or FREEMIUM
    └── NO → Is it content-based?
        ├── YES → SUBSCRIPTION or CONSUMABLE IAP
        └── NO → FREEMIUM with premium unlock
```

#### Model Comparison

Read **pricing-models.md** for detailed comparison of each model:
- Subscriptions (auto-renewable)
- One-time purchase (paid upfront or freemium unlock)
- Consumable IAP (credits, tokens)
- Non-consumable IAP (feature unlock)
- Tip jar / patronage
- Ad-supported with premium upgrade

#### App-Type Recommendations

Read **app-type-guides.md** for specific guidance by app category:
- Productivity / task management
- Health / therapy / wellness
- Kids / education
- Creative tools
- Social / community
- Developer tools
- Finance / budgeting

### Phase 3: Tier Structure

Once a model is selected, design the tier structure.

#### Subscription Tiers (if applicable)

**Two-tier structure** (recommended for most indie apps):
```
FREE                    PRO ($X.99/mo or $XX.99/yr)
─────────────────────   ─────────────────────────────
Core functionality      Everything in Free
Limited usage/storage   Unlimited usage
Basic features          Advanced features
                        Priority support (optional)
                        Early access to new features
```

**Three-tier structure** (for apps with clear user segments):
```
FREE          PLUS ($X.99/mo)     PRO ($XX.99/mo)
────────────  ──────────────────  ──────────────────
Basic use     Power user          Professional/team
Ads/limits    No ads, more quota  Unlimited + extras
```

#### Pricing Psychology

- **Anchor pricing**: Show yearly first to make monthly look expensive
- **Price ending**: Use .99 for < $10, round numbers for premium ($19, $29)
- **Yearly discount**: 15-40% off monthly equivalent (sweet spot: ~30%)
- **Decoy effect**: Three tiers where middle looks like best value
- **Regional pricing**: Use App Store price tiers for automatic localization

#### Free vs. Paid Feature Split

The hardest decision. Follow these principles:

**Free tier should:**
- Demonstrate the core value proposition
- Be genuinely useful (not a crippled demo)
- Create natural upgrade moments ("you've hit the limit")
- Let users invest time/data before hitting the paywall

**Paid tier should:**
- Unlock power/convenience, not basic functionality
- Feel like "more of what you love" not "removing annoyances"
- Include at least one "hero feature" worth paying for alone

**❌ Bad splits:**
- Free: Can view data → Paid: Can edit data (feels hostile)
- Free: 3-day trial → Paid: Everything (no ongoing free value)
- Free: Everything → Paid: Remove ads (weak value prop)

**✅ Good splits:**
- Free: 5 projects → Paid: Unlimited projects + templates
- Free: Basic tracking → Paid: Insights, trends, export
- Free: Single device → Paid: Sync across devices + widgets

### Phase 4: Free Trial Strategy

#### Trial Types

| Type | Best For | Apple Support |
|------|----------|---------------|
| Introductory offer (free) | Subscriptions | Built-in via App Store |
| Introductory offer (discounted) | High-value subscriptions | Built-in via App Store |
| Feature-limited free tier | Freemium apps | N/A (your logic) |
| Time-limited full access | Productivity apps | Built-in via App Store |

#### Trial Duration Recommendations

| App Type | Trial Length | Reason |
|----------|-------------|--------|
| Daily-use productivity | 7 days | Quick to see value |
| Health/fitness tracking | 14 days | Need time to build habit |
| Creative tools | 7 days | One project cycle |
| Business/professional | 14-30 days | Need to integrate into workflow |
| Education/learning | 7 days | One learning cycle |

#### Trial Conversion Tactics

1. **Onboard to premium features** during trial (not free features)
2. **Show "trial ending" reminder** 2-3 days before expiration
3. **Highlight value received** ("You tracked 47 workouts this month")
4. **Offer annual option** at trial end (bigger commitment but better price)
5. **Win-back offer** if they don't convert (promotional offer after 30 days)

### Phase 5: Implementation Guidance

After strategy is set, guide implementation.

#### Apple Commission Structure

| Scenario | Apple's Cut | You Keep |
|----------|-------------|----------|
| Standard (Year 1) | 30% | 70% |
| After Year 1 of subscription | 15% | 85% |
| Small Business Program (< $1M/yr) | 15% | 85% |
| Small Business + Year 2 subscription | 15% | 85% |

**Important:** Revenue calculations should always account for Apple's cut. A $9.99/mo subscription with Small Business Program = ~$8.49/mo to you.

#### StoreKit 2 Implementation

For code generation, refer users to the **paywall-generator** skill:
```
Use the paywall-generator skill to create:
- StoreKit 2 subscription management
- Paywall UI (SwiftUI)
- Receipt validation
- Subscription status tracking
```

#### Paywall UI Patterns (HIG-Compliant)

**Do:**
- Show feature comparison (free vs. paid)
- Display price per period clearly
- Highlight savings on annual plan
- Include "Restore Purchases" button
- Show terms of service and privacy policy links
- Use system subscription views where available (iOS 18.4+)

**Don't:**
- Block the app immediately on launch
- Use dark patterns (hidden close button, confusing language)
- Make it hard to dismiss the paywall
- Misrepresent subscription terms
- Auto-select the most expensive option

#### App Store Review Guidelines (Monetization)

Key rules to follow:
- **3.1.1**: In-app purchase required for digital content/features
- **3.1.2**: Subscriptions must provide ongoing value
- **3.1.3**: "Reader" apps can link to web for account management
- **3.2.2**: Unacceptable business models (bait-and-switch, etc.)
- **5.6**: Developer Code of Conduct (no manipulative tactics)

## Output Format

Present monetization strategy as:

```markdown
# Monetization Strategy: [App Name]

## Readiness Assessment
**Score**: X/6 — [Ready to monetize / Soft-launch / Focus on product]

| Signal | Status | Notes |
|--------|--------|-------|
| Core value | ✅/❌ | ... |
| Retention | ✅/❌ | ... |
| User demand | ✅/❌ | ... |
| Feature depth | ✅/❌ | ... |
| Differentiation | ✅/❌ | ... |
| Polish | ✅/❌ | ... |

## Recommended Model
**[Model Name]** — [One-line rationale]

## Tier Structure

| Feature | Free | Pro ($X.99/mo) |
|---------|------|-----------------|
| ... | ✅ | ✅ |
| ... | Limited | Unlimited |
| ... | ❌ | ✅ |

**Annual pricing**: $XX.99/yr (XX% savings)

## Free Trial
**Type**: [Introductory offer / Feature-limited / etc.]
**Duration**: [X days]
**Conversion tactics**: [Bullet list]

## Revenue Projections (Conservative)

| Metric | Estimate |
|--------|----------|
| Monthly price | $X.99 |
| Annual price | $XX.99 |
| Conversion rate (free→paid) | X-X% |
| Revenue per 1K MAU | $XXX-$XXX/mo |

## Implementation Checklist
- [ ] Configure products in App Store Connect
- [ ] Implement StoreKit 2 (use paywall-generator skill)
- [ ] Design paywall UI
- [ ] Set up introductory offers
- [ ] Add analytics for conversion tracking
- [ ] Test with StoreKit Configuration file
- [ ] Submit for review

## Next Steps
1. [First action item]
2. [Second action item]
3. [Third action item]
```

## References

- **pricing-models.md** — Detailed comparison of all pricing models
- **app-type-guides.md** — Category-specific monetization recommendations
- **paywall-generator** skill — For StoreKit 2 code generation
- **app-store** skill — For App Store description optimization
- Apple App Store Review Guidelines §3 (Business)
- Apple StoreKit 2 documentation
