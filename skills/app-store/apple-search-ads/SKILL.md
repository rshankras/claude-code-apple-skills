---
name: apple-search-ads
description: Apple Search Ads campaign strategy for indie developers — paid acquisition, keyword bidding, budget planning, and ROAS optimization. Use when user asks about running ads, paid user acquisition, or Apple Search Ads campaigns.
allowed-tools: [Read, Glob, Grep, AskUserQuestion, WebSearch]
---

# Apple Search Ads for Indie Developers

Plan, launch, and optimize Apple Search Ads campaigns that deliver profitable user acquisition for indie apps.

## When This Skill Activates

Use this skill when the user:
- Asks about paid user acquisition or running ads for their app
- Mentions "Apple Search Ads", "Search Ads", or "ASA"
- Wants to set up ad campaigns in the App Store
- Asks about keyword bidding, CPT, or CPA optimization
- Needs help with campaign structure or budget allocation
- Wants to understand if paid acquisition makes sense for their app
- Asks how to complement ASO with paid promotion

## Pre-Requisite Check: Are You Ready for Ads?

Before recommending any campaign setup, verify these minimum thresholds. Running ads on an unoptimized listing burns money.

### Minimum Thresholds

| Requirement | Threshold | Why |
|-------------|-----------|-----|
| Organic downloads | 100+/month | Proves baseline demand exists |
| App Store page CVR | > 20% | Ads amplify your listing — a bad listing wastes spend |
| Screenshots | 5+ optimized | Paid traffic sees your product page first |
| Ratings | 3.5+ stars (or none) | Low ratings kill conversion from ads |
| Crash-free rate | > 99% | Crashes destroy ROAS through refunds and bad reviews |
| Monetization | Active | No point acquiring users you can't monetize |

**If thresholds are not met:**
- Focus on organic ASO first (use `keyword-optimizer` skill)
- Fix product page conversion (use `screenshot-planner` and `app-description-writer` skills)
- Improve app quality and ratings before spending on acquisition

### Readiness Decision

```
Have 100+ organic downloads/month?
├── NO → Stop. Fix organic first.
└── YES → Is your product page CVR > 20%?
    ├── NO → Optimize listing first, then run ads.
    └── YES → Ready for Apple Search Ads.
```

## Campaign Types

Apple Search Ads offers four placement types. Not all are useful for indie developers.

### Search Results (Recommended Starting Point)

- **Where**: Top of search results when users search specific keywords
- **Targeting**: Keyword-based (exact match or broad match)
- **Cost model**: Cost Per Tap (CPT)
- **Best for**: High-intent users actively looking for your category
- **Indie priority**: Start here. This is where you get the most control and best ROAS.

### Search Tab

- **Where**: Top of the Search tab before user types anything
- **Targeting**: Audience-based (demographics, customer type)
- **Cost model**: Cost Per Tap (CPT)
- **Best for**: Brand awareness and discovery
- **Indie priority**: Use after Search Results campaigns are profitable. Good for launch visibility.

### Today Tab

- **Where**: Today tab in the App Store
- **Targeting**: Audience-based
- **Cost model**: Cost Per Tap (CPT)
- **Best for**: Mass awareness, seasonal pushes
- **Indie priority**: Usually too expensive for indie budgets. Skip unless budget allows $500+/day.

### Product Page (You Might Also Like)

- **Where**: "You Might Also Like" section on other apps' product pages
- **Targeting**: Audience and category-based
- **Cost model**: Cost Per Tap (CPT)
- **Best for**: Reaching users browsing competitor or related apps
- **Indie priority**: Good second campaign after Search Results. Lower intent but can find relevant users.

### Recommended Progression for Indie Developers

```
Stage 1: Search Results (exact match keywords)
    ↓ profitable?
Stage 2: Search Results (broad match for discovery)
    ↓ profitable?
Stage 3: Product Page (competitor audiences)
    ↓ profitable?
Stage 4: Search Tab (brand awareness)
```

## Keyword Strategy

### Keyword Categories

**1. Brand Keywords (Your App Name)**
- Bid on these ONLY if competitors are bidding on your name
- Check by searching your app name — if a competitor appears above you, bid
- Otherwise, save the budget; you already rank #1 organically

**2. Category Keywords (Generic Terms)**
- Examples: "todo app", "weather radar", "habit tracker"
- High volume, high competition, expensive
- Target long-tail variants: "simple todo app", "habit tracker no account"
- These are your bread and butter for growth

**3. Competitor Keywords (Rival App Names)**
- Legal and common practice in Apple Search Ads
- Lower conversion (users wanted the other app) but can be effective
- Best when your app has a clear advantage over that competitor
- Use Custom Product Pages to message directly against competitors

**4. Discovery Keywords (Problem/Solution)**
- Examples: "stop procrastinating", "save money automatically", "focus while studying"
- Lower volume but very high intent
- Often cheapest CPT because few advertisers target them
- Excellent ROAS potential

### Keyword Research Process

1. **Start with brainstorming** — List 50+ terms a user might search
2. **Use Search Ads keyword suggestions** — Apple provides recommendations in the campaign manager
3. **Mine your ASO research** — Keywords from `keyword-optimizer` skill that you can't rank organically
4. **Check autocomplete** — Type partial queries in the App Store
5. **Analyze competitors** — What keywords trigger their ads?
6. **Use Search Ads intelligence tools** — SearchAds.com, SplitMetrics Acquire, AppTweak

### Keyword Selection Criteria

| Factor | Target | Notes |
|--------|--------|-------|
| Relevance | High | Only bid on keywords your app genuinely serves |
| Search volume | Medium-High | Low volume = too few impressions to matter |
| Competition | Low-Medium | High competition = expensive CPT |
| Intent | Transactional | "best X app" > "what is X" |

## Budget Planning

### Budget by App Stage

| Stage | Daily Budget | Monthly Budget | Strategy |
|-------|-------------|----------------|----------|
| **Launch** (first 30 days) | $10-30/day | $300-900 | Discovery, keyword validation |
| **Growth** (months 2-6) | $50-100/day | $1,500-3,000 | Scale winners, cut losers |
| **Scale** (6+ months) | $100+/day | $3,000+ | Maximize profitable keywords |

### Launch Budget Allocation

```
Total: $20/day example

Search Results (Exact Match): $12/day (60%)
  → 10-15 carefully chosen keywords
  → Focus on category + discovery keywords

Search Results (Broad Match): $5/day (25%)
  → 3-5 broad terms for keyword discovery
  → Mine Search Terms report weekly for new exact match targets

Product Page Ads: $3/day (15%)
  → Target 2-3 competitor categories
  → Test which audiences convert
```

### When to Increase Budget

- ROAS > 1.5x target → Increase budget 20-30%
- High impression share on profitable keywords → Increase bid, not budget
- Discovered new profitable keyword clusters → Add budget for new ad groups

### When to Decrease Budget

- ROAS < 0.5x target for 7+ days → Pause or reduce
- CPT climbing with flat CVR → Market is getting competitive, reassess
- Seasonal dip in your category → Reduce and wait

## Bid Optimization

### CPT Benchmarks by Category

These are approximate ranges for the US market. Actual CPT varies by competition and keyword.

| Category | Low CPT | Median CPT | High CPT |
|----------|---------|------------|----------|
| Utilities | $0.30 | $0.80 | $2.00 |
| Productivity | $0.50 | $1.50 | $4.00 |
| Health & Fitness | $0.60 | $1.80 | $5.00 |
| Finance | $1.00 | $3.00 | $8.00 |
| Games (Casual) | $0.20 | $0.60 | $1.50 |
| Games (Mid-core) | $0.50 | $1.50 | $4.00 |
| Education | $0.40 | $1.20 | $3.00 |
| Photo & Video | $0.30 | $1.00 | $3.00 |
| Social | $0.40 | $1.20 | $3.50 |
| Shopping | $0.50 | $1.50 | $4.00 |

### Bid Strategy

**Starting bids:**
- Set initial bids at the median CPT for your category
- Let campaigns run for 3-5 days before adjusting
- Need at least 100 impressions per keyword to evaluate

**Raise bids when:**
- Impression share is low on a profitable keyword (you're being outbid)
- CVR is high but volume is low (more taps would mean more installs)
- ROAS is well above target (room to pay more per user)

**Lower bids when:**
- CPT is above your CPA target and CVR is average
- Impressions are high but TTR is low (keyword may not be relevant)
- ROAS is negative after 7+ days of data

**Pause keywords when:**
- 1000+ impressions, zero installs
- CPA is 3x+ your target after 14 days
- Keyword is clearly irrelevant (check Search Terms report)

## Custom Product Pages Integration

Apple Search Ads supports linking ad groups to Custom Product Pages (CPPs) for tailored messaging.

### When to Use CPPs with Ads

| Scenario | CPP Strategy |
|----------|-------------|
| Competitor keywords | Highlight advantages over that competitor |
| Feature keywords | Show the specific feature being searched |
| Audience segments | Different messaging for students vs. professionals |
| Seasonal campaigns | Holiday or event-themed screenshots/descriptions |

### CPP Setup for Ads

1. Create Custom Product Pages in App Store Connect (max 35)
2. Design screenshots and promotional text for each audience
3. In Search Ads, create separate ad groups per CPP
4. Assign relevant keywords to each ad group
5. Monitor CVR per CPP to see which messaging converts best

Use the `generators/custom-product-pages` skill for CPP metadata and strategy.

## Campaign Structure Template

### Recommended Organization

```
CAMPAIGN: [App Name] - Search Results
├── AD GROUP: Brand Defense
│   ├── Keywords: [your app name], [your app name + category]
│   ├── Match: Exact
│   ├── CPP: Default product page
│   └── Budget: 10% of campaign
│
├── AD GROUP: Category - Core
│   ├── Keywords: [top 10 category terms, exact match]
│   ├── Match: Exact
│   ├── CPP: Feature-focused product page
│   └── Budget: 40% of campaign
│
├── AD GROUP: Category - Discovery
│   ├── Keywords: [5 broad category terms]
│   ├── Match: Broad
│   ├── Negative keywords: [brand terms, irrelevant terms]
│   ├── CPP: Default product page
│   └── Budget: 20% of campaign
│
├── AD GROUP: Competitor
│   ├── Keywords: [competitor app names]
│   ├── Match: Exact
│   ├── CPP: Comparison-focused product page
│   └── Budget: 15% of campaign
│
└── AD GROUP: Problem/Solution
    ├── Keywords: [pain point searches]
    ├── Match: Exact
    ├── CPP: Problem-solution product page
    └── Budget: 15% of campaign

CAMPAIGN: [App Name] - Product Page
├── AD GROUP: Related Category
│   └── Audience: Users browsing [related category]
└── AD GROUP: Competitor Users
    └── Audience: Users viewing [competitor apps]
```

## Measurement & KPIs

### Key Metrics

| Metric | Definition | Target Range |
|--------|-----------|--------------|
| **TTR** (Tap-Through Rate) | Taps / Impressions | 5-12% |
| **CVR** (Conversion Rate) | Installs / Taps | 30-60% |
| **CPT** (Cost Per Tap) | Spend / Taps | Category-dependent (see benchmarks) |
| **CPA** (Cost Per Acquisition) | Spend / Installs | < Customer LTV |
| **ROAS** (Return on Ad Spend) | Revenue / Spend | > 1.0 (ideally > 2.0) |

### Interpreting Metrics

**High TTR + Low CVR:**
- Your ad is attractive but your product page doesn't convert
- Fix: Improve screenshots, description, ratings
- Check: Is the keyword truly relevant to your app?

**Low TTR + High CVR:**
- Users who do tap convert well, but few are tapping
- Fix: Raise bid to get better placement, review keyword relevance
- Consider: Your app name/icon may not stand out in results

**High CPA + High CVR:**
- You're paying too much per tap but converting well
- Fix: Find cheaper keywords with similar intent
- Consider: Lower bids and accept fewer impressions

**Low CPA + Low ROAS:**
- Cheap installs but users aren't monetizing
- Fix: Check onboarding-to-conversion funnel, not the ad
- Consider: The keyword may attract wrong user segment

### Reporting Cadence

| Frequency | What to Check | Action |
|-----------|---------------|--------|
| Daily | Spend, CPA | Pause runaway spend |
| Weekly | Keyword performance, Search Terms | Add negatives, find new keywords |
| Bi-weekly | ROAS, campaign-level metrics | Adjust bids, reallocate budget |
| Monthly | Overall ROI, LTV/CPA ratio | Strategic changes, new campaigns |

## Common Mistakes

### 1. Bidding on Your Own Brand Name Too Early

- You already rank #1 organically for your name
- Brand defense is only needed when competitors actively bid on your name
- Check first by searching — if no competitor ad appears, save the budget

### 2. Starting with Broad Match Only

- Broad match burns budget on irrelevant queries
- Always start with exact match on validated keywords
- Use broad match in a separate, low-budget discovery ad group
- Mine the Search Terms report to find exact match winners

### 3. No Negative Keywords

- Without negative keywords, broad match campaigns waste 30-50% of spend
- Add negative keywords weekly from Search Terms report
- Pre-load obvious negatives: competitor names in discovery groups, unrelated terms

### 4. Running Ads Before Optimizing Your Listing

- Ads drive traffic to your product page — if it doesn't convert, ads just cost money
- Optimize screenshots, description, and ratings FIRST
- Target 30%+ CVR organically before turning on ads

### 5. Setting Daily Budget Too High Initially

- Start small ($10-20/day) to gather data
- Scale only after 2+ weeks of data confirms profitability
- A $100/day budget on day one with no data is gambling, not marketing

### 6. Ignoring the Search Terms Report

- This is the most valuable data Apple gives you
- Shows ACTUAL queries that triggered your broad match ads
- Review weekly, add winners as exact match, add losers as negatives

### 7. Not Linking Custom Product Pages

- Generic product page for all keyword intents wastes conversion potential
- Different searchers need different messaging
- Even 2-3 CPPs can significantly improve CVR

### 8. Expecting Instant Results

- Apple Search Ads needs 7-14 days minimum to gather meaningful data
- Don't change bids daily — let data accumulate
- Statistical significance requires volume: aim for 100+ taps per keyword before judging

## Output Format

When advising on Apple Search Ads, produce this document:

```markdown
# Apple Search Ads Strategy: [App Name]

## Readiness Assessment
| Requirement | Status | Notes |
|-------------|--------|-------|
| Organic downloads | ✅/❌ | [X/month] |
| Product page CVR | ✅/❌ | [X%] |
| Screenshots | ✅/❌ | [X screenshots] |
| Ratings | ✅/❌ | [X.X stars] |
| Crash-free rate | ✅/❌ | [X%] |
| Monetization | ✅/❌ | [Model] |

**Verdict**: [Ready / Optimize first / Not ready]

## Recommended Campaign Structure

### Campaign 1: [Name]
- **Type**: [Search Results / Product Page / etc.]
- **Daily budget**: $X
- **Ad groups**: [List]

### Ad Group: [Name]
- **Keywords**: [List with match type]
- **Starting CPT bid**: $X.XX
- **Custom Product Page**: [Default / specific CPP]
- **Target CPA**: $X.XX

[Repeat for each ad group]

## Keyword Plan

| Keyword | Match | Category | Est. CPT | Priority |
|---------|-------|----------|----------|----------|
| [keyword] | Exact | Category | $X.XX | High |
| [keyword] | Exact | Discovery | $X.XX | High |
| [keyword] | Broad | Discovery | $X.XX | Medium |

## Budget Summary

| Campaign | Daily | Monthly | % of Total |
|----------|-------|---------|------------|
| [Campaign 1] | $X | $X | X% |
| [Campaign 2] | $X | $X | X% |
| **Total** | **$X** | **$X** | **100%** |

## KPI Targets

| Metric | Target | Review Frequency |
|--------|--------|-----------------|
| TTR | X% | Weekly |
| CVR | X% | Weekly |
| CPA | $X.XX | Bi-weekly |
| ROAS | X.Xx | Monthly |

## Negative Keywords (Pre-loaded)
- [List of terms to exclude from broad match]

## Week 1-2 Action Items
1. [First thing to set up]
2. [Second thing to set up]
3. [Third thing to set up]

## Month 1 Review Checklist
- [ ] Review Search Terms report
- [ ] Add negative keywords
- [ ] Evaluate keyword-level ROAS
- [ ] Adjust bids on top/bottom performers
- [ ] Consider CPP creation for top ad groups
```

## References

- Related: `app-store/keyword-optimizer` — ASO keyword strategy (organic, complements paid)
- Related: `app-store/screenshot-planner` — Product page optimization (improves ad CVR)
- Related: `generators/custom-product-pages` — Custom Product Page creation for ad groups
- Related: `app-store/marketing-strategy` — Overall marketing strategy including paid acquisition
- Apple Search Ads documentation: https://searchads.apple.com
