---
name: analytics-interpretation
description: Interpret app metrics and make data-driven decisions. Covers DAU/MAU, retention, LTV, ARPU, App Store Connect analytics, AARRR funnel analysis, cohort analysis, and diagnostic decision trees. Use when user wants to understand their metrics, diagnose problems, or build a data-driven growth plan.
allowed-tools: [Read, Glob, Grep, AskUserQuestion]
---

# Analytics Interpretation

Interpret your app's metrics, diagnose problems, and make data-driven decisions. Works with App Store Connect data, third-party analytics, or raw numbers the user provides.

## When This Skill Activates

Use this skill when the user:
- Wants to understand their app metrics or analytics
- Asks about retention, LTV, ARPU, or churn
- Wants to know if their metrics are good or bad
- Needs help interpreting App Store Connect analytics
- Wants a data-driven growth plan
- Asks "what should I focus on to grow?"
- Has metrics data and wants to know what it means

## Process

### Step 1: Gather Context

Ask the user via AskUserQuestion:

1. **App type and monetization model**
   - Free with ads, freemium, subscription, paid upfront, or hybrid?
2. **Current metrics they have access to**
   - App Store Connect? Third-party analytics (Mixpanel, Firebase, Amplitude)?
3. **Specific numbers they can share**
   - Downloads, DAU/MAU, retention, revenue, conversion rates?
4. **What they want to know**
   - "Are my metrics good?" / "What should I fix?" / "Should I keep going?"

### Step 2: Identify Key Metrics by App Type

Different monetization models have different north star metrics.

#### Free with Ads
| Metric | Why It Matters |
|--------|---------------|
| DAU/MAU | More daily users = more ad impressions |
| Session length | Longer sessions = more ad views |
| Sessions per day | More sessions = more revenue opportunities |
| Ad impressions/revenue | Direct revenue driver |
| D1/D7/D30 retention | Users must come back for ads to work |

#### Freemium (One-Time Unlock)
| Metric | Why It Matters |
|--------|---------------|
| Conversion rate (free → paid) | Primary revenue driver |
| Time to conversion | How long before users see enough value |
| Feature adoption | Which features drive upgrades |
| Revenue per download | Overall monetization efficiency |
| D7 retention (free users) | Must retain long enough to convert |

#### Subscription
| Metric | Why It Matters |
|--------|---------------|
| Trial start rate | Top of subscription funnel |
| Trial → paid conversion | Critical conversion point |
| Monthly churn rate | Determines LTV |
| LTV (lifetime value) | Revenue per subscriber over their lifetime |
| Payback period | Months to recoup acquisition cost |
| MRR / ARR | Business health snapshot |
| Subscriber retention (Month 1-12) | Long-term revenue curve |

#### Paid Upfront
| Metric | Why It Matters |
|--------|---------------|
| Downloads per day/week | Direct revenue driver |
| Revenue per download | Should equal price minus Apple's cut |
| Refund rate | Product quality signal (keep < 5%) |
| Ratings and reviews | Social proof drives more downloads |
| Organic vs. paid ratio | Sustainability indicator |

### Step 3: App Store Connect Analytics Interpretation

#### The App Store Funnel

```
Impressions (your app appeared in search/browse)
    ↓ Tap-through rate = Product Page Views / Impressions
Product Page Views (user tapped to see your page)
    ↓ Conversion rate = Downloads / Product Page Views
Downloads (user installed your app)
    ↓ D1 retention
Day 1 Active Users
    ↓ D7 retention
Day 7 Active Users
    ↓ D30 retention
Day 30 Active Users
    ↓ Monetization
Paying Users
```

#### Interpreting Each Funnel Step

**Impressions → Product Page Views (Tap-Through Rate)**

| Rating | TTR | Interpretation |
|--------|-----|---------------|
| Good | > 8% | Icon and title are compelling |
| Average | 4-8% | Room to improve first impression |
| Poor | < 4% | Icon, title, or subtitle need work |

What to fix if low:
- App icon not standing out (test bolder colors, simpler design)
- Title not communicating value (add keyword after brand name)
- Subtitle too vague (make it specific: "Budget Tracker" not "Finance App")
- Poor search ranking (see keyword-optimizer skill)

**Product Page Views → Downloads (Conversion Rate)**

| Rating | CVR | Interpretation |
|--------|-----|---------------|
| Good | > 40% | Screenshots and description are effective |
| Average | 25-40% | Some friction on the product page |
| Poor | < 25% | Major product page issues |

What to fix if low:
- First 3 screenshots not showing core value
- No app preview video (adds 15-25% lift)
- Description too long before showing key benefits
- Bad ratings visible (address review issues first)
- Price too high relative to perceived value

**Downloads → Day 1 Retention**

| Rating | D1 | Interpretation |
|--------|-----|---------------|
| Good | > 35% | Onboarding delivers on promise |
| Average | 20-35% | Some users confused or disappointed |
| Poor | < 20% | App not delivering expected value |

What to fix if low:
- Onboarding too long or confusing
- App Store screenshots overpromised
- Core value not visible in first session
- Permissions requested too early (camera, notifications)
- Performance issues (slow launch, crashes)

**Day 1 → Day 7 Retention**

| Rating | D7 | Interpretation |
|--------|-----|---------------|
| Good | > 20% | Users forming habit |
| Average | 10-20% | Some users finding value |
| Poor | < 10% | Most users abandoning after trying |

What to fix if low:
- No reason to come back (add notifications, reminders, streaks)
- Core loop not engaging enough
- Too complex — users haven't learned enough features
- Missing "aha moment" in first week

**Day 7 → Day 30 Retention**

| Rating | D30 | Interpretation |
|--------|-----|---------------|
| Good | > 10% | Strong product-market fit signal |
| Average | 5-10% | Decent but room to grow |
| Poor | < 5% | Retention cliff — users churning |

What to fix if low:
- Feature depth too shallow (users exhaust value)
- No progression or new content
- Competitor doing it better
- Consider: is this a "use once" tool, not a habit app?

### Step 4: AARRR Funnel Analysis

The pirate metrics framework — diagnose where your funnel leaks.

#### Acquisition: How do users find you?

| Metric | Benchmark | Diagnostic |
|--------|-----------|-----------|
| Organic search impressions | Growing month-over-month | Are your keywords working? |
| Browse impressions | Category-dependent | Are you getting featured/editorial? |
| Referral traffic | > 10% of total | Do users share your app? |
| Paid acquisition CPA | < 1/3 of LTV | Is paid acquisition sustainable? |

**Questions to ask:**
- What are your top 3 acquisition sources?
- Is organic growing or shrinking?
- What's your cost per install (if running ads)?

#### Activation: Do users experience the core value?

| Metric | Benchmark | Diagnostic |
|--------|-----------|-----------|
| Onboarding completion | > 70% | Is onboarding too long? |
| "Aha moment" reached | > 50% in first session | Do users discover core value? |
| First key action taken | > 40% of installs | Are users doing the main thing? |

**Questions to ask:**
- What is the one action that defines "this user gets it"?
- How many steps to reach that action?
- What percentage of new users complete it?

#### Retention: Do users come back?

| Metric | Benchmark | Diagnostic |
|--------|-----------|-----------|
| D1 retention | 25-40% | First impression quality |
| D7 retention | 15-25% | Habit formation |
| D30 retention | 8-15% | Product-market fit |
| DAU/MAU ratio | 15-30% | Daily engagement strength |

**Questions to ask:**
- Where is the biggest retention drop-off?
- What do retained users do differently from churned users?
- Is there a retention cliff at a specific day?

#### Revenue: Are users paying?

| Metric | Benchmark | Diagnostic |
|--------|-----------|-----------|
| Free → trial rate | 10-30% | Is the paywall compelling? |
| Trial → paid rate | 40-60% | Does the trial demonstrate value? |
| ARPU (all users) | Category-dependent | Overall monetization efficiency |
| ARPPU (paying users) | 5-20x ARPU | Are payers happy with value? |

**Questions to ask:**
- At what point do users encounter the paywall?
- What's the conversion rate at each paywall touchpoint?
- Do longer-retained users convert at higher rates?

#### Referral: Do users tell others?

| Metric | Benchmark | Diagnostic |
|--------|-----------|-----------|
| Organic multiplier | > 1.0 | Each user brings > 1 new user |
| Share rate | > 5% of MAU | Users actively sharing |
| Rating/review rate | > 1% of MAU | Users willing to vouch publicly |
| Average rating | > 4.5 | High satisfaction |

**Questions to ask:**
- Is there a share feature in the app?
- Do you ask for ratings at the right moment?
- What triggers a user to recommend your app?

### Step 5: Cohort Analysis (Subscription Apps)

#### How to Read a Cohort Retention Table

```
              Month 0  Month 1  Month 2  Month 3  Month 4  Month 5
Jan cohort    100%     62%      55%      50%      48%      46%
Feb cohort    100%     58%      51%      46%      44%      —
Mar cohort    100%     65%      59%      54%      —        —
Apr cohort    100%     70%      63%      —        —        —
May cohort    100%     68%      —        —        —        —
```

**What to look for:**

1. **Month 0 → Month 1 drop**: The biggest drop. Industry average is 30-50% churn. If yours is > 50%, trial experience needs work.

2. **Flattening curve**: Retention should flatten over time. If Month 3 → Month 4 → Month 5 are similar, you've found your "natural retention floor."

3. **Improving cohorts**: Compare Jan vs. Apr cohorts at the same month. If Apr Month 1 (70%) > Jan Month 1 (62%), your product improvements are working.

4. **Retention cliff**: A sudden drop at a specific month often indicates:
   - Month 1: Annual subscribers who don't renew
   - Month 3: Users who gave it a fair try and decided no
   - Month 12: Annual subscribers hitting renewal

#### Comparing Cohorts to Measure Impact

When you ship a change, compare cohorts before and after:

```
Before change (Jan-Mar avg):  Month 1 retention = 58%
After change (Apr-May avg):   Month 1 retention = 69%

Improvement: +11 percentage points → significant positive impact
```

**Rules of thumb:**
- < 3 percentage point change: likely noise
- 3-10 percentage point change: meaningful, keep the change
- > 10 percentage point change: major win, double down on this direction

### Step 6: Diagnostic Decision Trees

Use these when the user says "my [metric] is bad, what do I do?"

#### Low Impressions (< 1,000/day for established app)
```
Low impressions
├── Are you ranking for any keywords?
│   ├── NO → ASO problem: optimize title, subtitle, keywords
│   │        See keyword-optimizer skill
│   └── YES → Are those keywords high-volume?
│       ├── NO → Target higher-volume keywords
│       └── YES → Are you ranking in top 10?
│           ├── NO → Improve rankings (more ratings, better conversion)
│           └── YES → Expand to more keywords or new markets
```

#### High Impressions, Low Product Page Views (TTR < 4%)
```
Low tap-through rate
├── Is your icon professional and distinctive?
│   ├── NO → Redesign icon (test 3 variants)
│   └── YES → Is your title clear and keyword-rich?
│       ├── NO → Rewrite title: [Brand] - [Value Keyword]
│       └── YES → Is your subtitle compelling?
│           ├── NO → Rewrite subtitle with specific benefit
│           └── YES → Check competitor positioning — are you differentiated?
```

#### Good Downloads, Bad Retention (D1 < 25%)
```
Poor day-1 retention
├── Is onboarding complete rate > 70%?
│   ├── NO → Simplify onboarding (fewer steps, skip option)
│   └── YES → Do users reach "aha moment" in first session?
│       ├── NO → Restructure first-run experience to show core value immediately
│       └── YES → Are there performance issues (crashes, slow load)?
│           ├── YES → Fix stability first (check crash reports)
│           └── NO → Does the app match what screenshots promised?
│               ├── NO → Align marketing with actual product
│               └── YES → Core value may not be strong enough → user research needed
```

#### Good Retention, Low Revenue (conversion < 3%)
```
Low monetization
├── Do users see the paywall?
│   ├── NO → Add natural paywall touchpoints (feature gates, usage limits)
│   └── YES → Is the paywall compelling?
│       ├── NO → Redesign paywall (show value, social proof, feature comparison)
│       └── YES → Is the price right?
│           ├── TOO HIGH → Test lower price point or add cheaper tier
│           ├── TOO LOW → Users may not perceive enough value — test higher price
│           └── SEEMS RIGHT → Is trial experience showcasing premium features?
│               ├── NO → Onboard users to premium features during trial
│               └── YES → Test different trial lengths or offer types
```

### Step 7: Invest, Iterate, Pivot, or Sunset?

Based on the overall picture, recommend one of four paths:

#### Invest (Double Down)
**Signals:**
- D7 retention > 40%
- Growing organically (installs increasing without paid acquisition)
- Users actively requesting features
- Conversion rate improving over time
- Strong ratings (> 4.5 stars)

**Action:** Increase development speed, consider marketing spend, expand to new platforms.

#### Iterate (Keep Improving)
**Signals:**
- D7 retention 20-40%
- Some organic growth but not accelerating
- Mixed user feedback (some love it, some confused)
- Conversion rate stable but not great

**Action:** Focus on the retention cliff. Find what retained users do differently and make all users do that. A/B test paywall and onboarding.

#### Pivot (Change Direction)
**Signals:**
- D7 retention < 20% after 3+ iterations
- Engagement concentrated in unexpected feature
- Users using app differently than intended
- Specific segment retains well, others don't

**Action:** Double down on the unexpected use case. Rebuild around what users actually do, not what you planned.

#### Sunset (Move On)
**Signals:**
- Declining metrics across the board
- No organic growth despite multiple iterations
- Users not engaging even after onboarding improvements
- Opportunity cost too high (other ideas with more potential)

**Action:** Put app in maintenance mode. Stop active development. Consider open-sourcing or selling. Redirect energy to next project.

**Important caveat:** Sunsetting is not failure. Most successful indie developers shipped several apps before finding the one that worked.

## Reference Files

See **metrics-reference.md** for:
- Detailed metric definitions and formulas
- Benchmark ranges by app category (social, productivity, games, utilities)
- App Store Connect specific metric definitions
- Red/yellow/green thresholds for all key metrics

## Output Format

Present analysis as an Analytics Health Report:

```markdown
# Analytics Health Report: [App Name]

## Overview
**App type:** [Free/Freemium/Subscription/Paid]
**Stage:** [Pre-launch/Early/Growing/Established]
**Data period:** [Date range analyzed]

## Funnel Health

| Stage | Metric | Value | Rating | Action |
|-------|--------|-------|--------|--------|
| Acquisition | Impressions/day | X,XXX | 🟢/🟡/🔴 | ... |
| Acquisition | Tap-through rate | X.X% | 🟢/🟡/🔴 | ... |
| Activation | Conversion rate | X.X% | 🟢/🟡/🔴 | ... |
| Retention | D1 retention | XX% | 🟢/🟡/🔴 | ... |
| Retention | D7 retention | XX% | 🟢/🟡/🔴 | ... |
| Retention | D30 retention | XX% | 🟢/🟡/🔴 | ... |
| Revenue | Conversion rate | X.X% | 🟢/🟡/🔴 | ... |
| Revenue | LTV | $XX.XX | 🟢/🟡/🔴 | ... |

## Primary Bottleneck
**[Stage name]** — [One sentence explanation of the biggest problem]

## Recommended Actions (Priority Order)
1. 🔴 [Critical fix] — Expected impact: [X]
2. 🟠 [High priority] — Expected impact: [X]
3. 🟡 [Medium priority] — Expected impact: [X]

## Overall Assessment
**Recommendation:** [Invest / Iterate / Pivot / Sunset]
**Rationale:** [2-3 sentences]
```

## References

- **metrics-reference.md** — Metric definitions, formulas, and benchmarks
- **app-store/keyword-optimizer/** — For ASO-related fixes
- **monetization/** — For pricing and paywall optimization
- **testing/** — For A/B test methodology
