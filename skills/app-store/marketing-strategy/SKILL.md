---
name: marketing-strategy
description: App Store marketing strategy advisor that analyzes your app and recommends the best promotional features. Orchestrates sub-skills for implementation. Use when planning app promotion, launch strategy, user acquisition, or re-engagement campaigns.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, WebSearch]
---

# App Store Marketing Strategy

Analyzes your app's type, monetization model, audience, and lifecycle stage, then builds a tailored promotional strategy using Apple's App Store features. Calls relevant sub-skills to generate implementation code and metadata.

## When This Skill Activates

Use this skill when the user:
- Asks "how should I market my app?" or "what App Store features should I use?"
- Wants a promotional strategy for launch, growth, or re-engagement
- Mentions "App Store promotion", "user acquisition", or "app marketing"
- Wants to increase downloads or reduce churn
- Asks about in-app events, custom product pages, or win-back offers
- Is preparing for a major update or seasonal campaign
- Wants to get featured on the App Store

## Process

### Phase 1: App Profile Collection

Gather information via AskUserQuestion:

**1. App Identity**
- App name and one-line description
- App Store category (primary + secondary)
- Platform(s): iOS, macOS, iPadOS, watchOS, visionOS

**2. Monetization Model**
- Free (ad-supported)
- Freemium (free + IAP/subscription)
- Paid upfront
- Subscription only
- Free (no monetization yet)

**3. Target Audience**
- Primary demographic (age, role, context)
- Secondary audience (if any)
- Geographic focus

**4. Lifecycle Stage**
- Pre-launch (building / TestFlight)
- Launch (first 30 days)
- Growth (active, adding users)
- Mature (stable user base, seeking retention)
- Re-engagement (declining, need to win back users)

**5. Current State**
- Monthly active users (approximate)
- Existing promotional features already configured
- Upcoming updates or milestones
- Marketing budget (none / small / moderate)

### Phase 2: Strategy Analysis

Read **decision-matrix.md** to map the app profile to recommended features.

The decision matrix evaluates these dimensions:
- Monetization model → Which offer types apply
- Lifecycle stage → Which tactics are highest priority
- App category → Which featuring angles work
- Audience segments → Whether custom product pages help
- Content/events → Whether in-app events fit
- **Minimum eligibility thresholds** → Whether the app has sufficient scale for each feature

**CRITICAL — Check Eligibility Before Recommending:**
Not every feature makes sense at every scale. The decision matrix (Dimension 6) defines minimum thresholds. Features that require traffic volume (PPO, CPPs) or user base size (win-back, promotional offers) should NOT be recommended for apps below those thresholds. Instead, recommend the alternatives specified in the matrix. Always be honest about what will and won't work at the app's current scale — recommending PPO to an app with 200 impressions/month wastes their time.

### Phase 3: Strategy Generation

Based on the analysis, read the appropriate strategy template:
- `strategy-templates/subscription-app.md` — For subscription-based apps
- `strategy-templates/paid-app.md` — For paid upfront apps
- `strategy-templates/freemium-app.md` — For freemium with IAP
- `strategy-templates/game-app.md` — For games (any monetization)

Customize the template with the app's specific details.

### Phase 4: Implementation Roadmap

For each recommended feature, provide:
1. **Priority** (High / Medium / Low)
2. **Effort** (Quick win / Moderate / Significant)
3. **Expected impact** on the primary goal (downloads, retention, revenue)
4. **Implementation skill** to call for code/metadata generation

#### Available Sub-Skills

| Feature | Generator Skill | What It Produces |
|---------|----------------|------------------|
| Introductory/promotional offers | `generators/subscription-offers` | StoreKit 2 offer code + eligibility |
| Win-back campaigns | `generators/win-back-offers` | Win-back flow + Message API handling |
| Promoted IAP on product page | `generators/promoted-iap` | StoreKit 2 promoted purchase setup |
| In-App Events | `generators/in-app-events` | Event metadata + image specs |
| Custom Product Pages | `generators/custom-product-pages` | Page metadata + screenshot strategy |
| Product Page Optimization | `generators/product-page-optimization` | A/B test plan + optimization checklist |
| App Store featuring | `generators/featuring-nomination` | Nomination form + pitch template |
| Offer codes distribution | `generators/offer-codes-setup` | Distribution strategy + configuration |
| Pre-launch / pre-orders | `generators/pre-orders` | Pre-order setup + launch timeline |
| Promotional assets | `generators/app-store-assets` | Asset specs + guidelines |

### Phase 5: Timeline & Calendar

Build a promotional calendar based on:
- App launch date or next update
- Seasonal opportunities (back to school, holidays, New Year)
- Apple events (WWDC, iPhone launch, etc.)
- Category-specific timing (tax season for finance, January for fitness)

## Output Format

Present the strategy as:

```markdown
# Marketing Strategy: [App Name]

## App Profile
| Attribute | Value |
|-----------|-------|
| Category | [Category] |
| Model | [Monetization model] |
| Stage | [Lifecycle stage] |
| Audience | [Primary audience] |
| Platform | [Platforms] |

## Strategic Goals
1. [Primary goal based on lifecycle stage]
2. [Secondary goal]
3. [Tertiary goal]

## Recommended Features (Eligible Now)

### 🔴 High Priority

#### [Feature Name]
- **Why**: [Rationale for this app]
- **Effort**: [Quick win / Moderate / Significant]
- **Impact**: [Expected outcome]
- **Skill**: `generators/[skill-name]`
- **Action**: [Specific next step]

### 🟠 Medium Priority
[Same format]

### 🟢 Nice to Have
[Same format]

## Not Yet Recommended (Scale Thresholds Not Met)

| Feature | Minimum Needed | Your Current Level | When to Revisit |
|---------|---------------|-------------------|-----------------|
| [Feature] | [Threshold] | [Current metric] | [Milestone to hit] |

> These features will become effective once you reach the indicated thresholds.
> Focus on the eligible features above to grow toward these milestones.

## Promotional Calendar

| Month | Action | Feature | Notes |
|-------|--------|---------|-------|
| [M1] | [Action] | [Feature] | [Context] |
| [M2] | [Action] | [Feature] | [Context] |

## Implementation Order

1. **Week 1-2**: [First actions — quick wins]
2. **Week 3-4**: [Second wave — moderate effort]
3. **Month 2**: [Bigger initiatives]
4. **Ongoing**: [Recurring activities]

## Revenue Impact Estimate

| Feature | Estimated Lift | Confidence |
|---------|---------------|------------|
| [Feature] | [+X% downloads / -X% churn] | [High/Medium/Low] |

## Next Steps
1. [Immediate action item]
2. [Call specific generator skill]
3. [Prepare specific asset or metadata]
```

## Strategy Examples

### Example: Speech Therapy App (Subscription, Growth Stage)
**Profile**: Blow Quest, freemium + subscription, targeting parents of kids in speech therapy
**Recommended**:
- 🔴 In-App Events → Weekly breath challenges to drive engagement
- 🔴 Custom Product Pages → One for parents, one for SLPs (speech-language pathologists)
- 🟠 Win-Back Offers → Re-engage churned subscribers with 50% off
- 🟠 Featuring Nomination → Accessibility + Health angle
- 🟢 Promoted IAP → Show subscription on product page
- 🟢 Offer Codes → Partner with SLP clinics for distribution

### Example: Watch Meditation App (Subscription, Launch Stage)
**Profile**: ChantFlow, Apple Watch, paid + subscription, meditation
**Recommended**:
- 🔴 Introductory Offer → 7-day free trial for subscription
- 🔴 App Store Assets → watchOS screenshots + short-form video
- 🟠 Product Page Optimization → A/B test meditation vs. mindfulness positioning
- 🟠 Featuring Nomination → Mindfulness + Apple Watch angle
- 🟢 Pre-Orders → Build anticipation before major update
- 🟢 In-App Events → Monthly meditation challenges

### Example: Productivity App (Freemium, Mature Stage)
**Profile**: TaskFlow, freemium with premium unlock, 50K MAU, stable
**Recommended**:
- 🔴 Win-Back Offers → Re-engage lapsed premium users
- 🔴 Product Page Optimization → Test benefit-led vs. feature-led screenshots
- 🟠 Custom Product Pages → Pages for students, freelancers, teams
- 🟠 In-App Events → Productivity Week challenge (January)
- 🟢 Offer Codes → Influencer/reviewer distribution
- 🟢 Promotional Offers → Loyalty discount for long-term free users

## References

- **decision-matrix.md** — Feature recommendation logic by app attributes
- **strategy-templates/** — Monetization-specific strategy playbooks
- Related: `app-store/keyword-optimizer` — ASO keyword strategy
- Related: `app-store/app-description-writer` — Product page copy
- Related: `app-store/screenshot-planner` — Screenshot sequences
- Related: `monetization` — Pricing and tier strategy
