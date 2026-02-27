# Strategy Template: Subscription Apps

Playbook for apps with auto-renewable subscriptions as the primary revenue model.

## Core Strategy: The Subscription Funnel

```
ACQUIRE → TRIAL → CONVERT → RETAIN → WIN BACK
   ↑         ↑        ↑         ↑         ↑
   |         |        |         |         |
  CPP    Intro     Paywall   Events    Win-back
  PPO    Offer     Design    Content    Offers
  ASA    Trial     Pricing   Updates    Offer Codes
```

Each stage has specific App Store features that optimize it.

---

## Stage 1: Acquire (Get Visitors to Product Page)

### Key Features
- **Product Page Optimization**: A/B test screenshots, descriptions, and icons
- **Custom Product Pages**: Tailored pages per audience segment or ad campaign
- **Featuring Nomination**: Editorial visibility → high-quality, low-cost installs
- **App Store Assets**: Professional screenshots and app preview videos

### Metrics to Track
- Impressions → Product page views (conversion rate)
- Product page views → Downloads (tap-through rate)
- Source attribution (organic vs. search vs. browse)

### Quick Wins
1. Optimize first 3 screenshots (most users don't scroll)
2. Make subtitle benefit-focused, not feature-focused
3. Add app preview video showing core value in first 5 seconds

---

## Stage 2: Trial (Convert Downloads to Trial Starts)

### Key Features
- **Introductory Offers**: Free trial (3, 7, or 14 days) or discounted first period
- **Promoted IAP**: Show subscription directly on the product page

### Trial Duration Decision
| App Usage Pattern | Recommended Trial | Reason |
|-------------------|-------------------|--------|
| Daily use (habit) | 7 days | One week to build habit |
| Weekly use | 14 days | Two cycles to see value |
| Infrequent/project-based | 7 days | Quick value demonstration |
| Complex/onboarding-heavy | 14-30 days | Time to learn and integrate |

### Onboarding During Trial
- Guide users to premium features immediately (not free features)
- Show progress/value metrics ("You've completed 5 sessions this week")
- Trigger contextual upsell at natural upgrade moments

---

## Stage 3: Convert (Trial → Paid Subscriber)

### Key Features
- **Paywall Design**: Use `generators/paywall-generator` for StoreKit 2 implementation
- **Pricing Psychology**: Annual-first presentation, anchor pricing
- **Promotional Offers**: Discounted rate for users who didn't convert from trial

### Conversion Tactics
1. **Trial ending notification** 2-3 days before expiry
2. **Value summary** showing what they'll lose ("You tracked 12 workouts")
3. **Annual offer** presented as "save X%" vs. monthly
4. **Promotional offer** 7-14 days after trial expires if not converted

### Price Testing Approach
1. Start with category benchmark pricing
2. Run 90-day A/B test on pricing page layout
3. Test annual vs. monthly prominence
4. Never test price directly (App Store doesn't support price A/B)

---

## Stage 4: Retain (Keep Subscribers Active)

### Key Features
- **In-App Events**: Regular content/challenges to maintain engagement
- **Promotional Offers**: Loyalty discounts at renewal risk points

### Retention Event Calendar
| Timing | Event Type | Goal |
|--------|-----------|------|
| Monthly | Feature spotlight or challenge | Remind of value |
| Quarterly | Major content update event | Re-engage dormant users |
| Seasonal | Themed campaign (New Year, etc.) | Capitalize on motivation spikes |
| Anniversary | Personal milestone celebration | Emotional connection |

### Churn Prevention Signals
Watch for these and trigger Promotional Offers:
- Usage drops significantly (< 50% of normal)
- User hasn't opened app in 14+ days
- User downgrades from premium features
- User contacts support with complaints

---

## Stage 5: Win Back (Recover Churned Subscribers)

### Key Features
- **Win-Back Offers**: StoreKit 2 win-back flow for lapsed subscribers
- **Offer Codes**: Distribute via email campaigns to churned users
- **In-App Events**: Signal major updates to bring users back

### Win-Back Timeline
| Days Since Churn | Action | Offer |
|------------------|--------|-------|
| 7-14 | App Store win-back offer | 25-50% off first period |
| 30 | Email with offer code | Free month |
| 60-90 | In-App Event notification | Major update announcement |
| 90+ | Aggressive win-back offer | 60%+ off or extended trial |

### Win-Back Messaging
- Focus on what's new since they left
- Acknowledge time away ("We've been busy while you were gone")
- Lead with the single most compelling new feature
- Make the offer time-limited to create urgency

---

## Subscription App Checklist

### Pre-Launch
- [ ] Configure subscription products in App Store Connect
- [ ] Set up introductory offer (free trial recommended)
- [ ] Implement StoreKit 2 with `paywall-generator` skill
- [ ] Prepare 3+ screenshot variations for PPO testing
- [ ] Write benefit-focused description and subtitle
- [ ] Plan launch In-App Event

### Launch Month
- [ ] Submit featuring nomination (if not done pre-launch)
- [ ] Start Product Page Optimization test
- [ ] Monitor trial-to-paid conversion rate
- [ ] Set up promotional offer for trial non-converters
- [ ] Configure promoted IAP

### Growth Phase (Month 2-6)
- [ ] Create Custom Product Pages for top audience segments
- [ ] Establish monthly In-App Event cadence
- [ ] Set up win-back offer for first churned cohort
- [ ] Distribute offer codes to partners/influencers
- [ ] Iterate on paywall design based on conversion data

### Mature Phase (Month 6+)
- [ ] Full win-back offer pipeline active
- [ ] Quarterly featuring nomination submissions
- [ ] Seasonal event calendar planned 3 months ahead
- [ ] Regular PPO tests running
- [ ] Offer code campaigns for email list

---

## Revenue Benchmarks (Subscription Apps)

| Metric | Below Average | Average | Good | Excellent |
|--------|--------------|---------|------|-----------|
| Trial start rate | < 5% | 5-10% | 10-20% | > 20% |
| Trial → Paid | < 30% | 30-50% | 50-65% | > 65% |
| Monthly churn | > 10% | 5-10% | 3-5% | < 3% |
| Annual plan mix | < 30% | 30-50% | 50-70% | > 70% |
| D30 retention | < 15% | 15-25% | 25-40% | > 40% |

Use these benchmarks to identify which funnel stage needs the most attention.
