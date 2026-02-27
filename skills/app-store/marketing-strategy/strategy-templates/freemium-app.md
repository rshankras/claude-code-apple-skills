# Strategy Template: Freemium Apps (IAP)

Playbook for free apps that monetize through non-consumable or consumable in-app purchases.

## Core Strategy: Volume + Conversion

Freemium apps need two funnels: maximize downloads (free), then convert free users to paying users. App Store features serve both goals.

```
ACQUIRE → ENGAGE → UPGRADE → EXPAND → RE-ENGAGE
    ↑        ↑        ↑         ↑          ↑
    |        |        |         |          |
   PPO    Events   Promoted   Offer     Offer
   CPP    Content    IAP      Codes     Codes
  Feat.   Onboard  Paywall   Bundles   Events
```

---

## Stage 1: Acquire (Maximize Downloads)

### Key Features
- **Product Page Optimization**: Optimize for download rate (low commitment)
- **Custom Product Pages**: Per ad campaign / audience segment
- **Featuring Nomination**: Free apps with IAP are Apple's bread and butter

### Freemium Product Page Strategy
- **DO** lead with free value — what users get without paying
- **DON'T** lead with premium features (scares off downloads)
- Show the app is fully functional for free, with premium as "more"

### Screenshot Strategy
1. **Screenshot 1**: Core free experience (compelling, complete)
2. **Screenshot 2-3**: Key free features in action
3. **Screenshot 4**: Premium features preview ("Unlock Pro")
4. **Screenshot 5**: Social proof or breadth of features

---

## Stage 2: Engage (Build Investment)

### Key Features
- **In-App Events**: Regular challenges/content that get free users invested
- **Push Notifications**: Re-engagement (not an App Store feature, but critical)

### Engagement Before Monetization
Users must invest time and data before seeing a paywall:
- **Productivity apps**: Let them create 5+ items before suggesting premium
- **Creative apps**: Let them complete one project, then offer premium exports
- **Utility apps**: Let them use core function 10+ times before limits
- **Content apps**: Give generous free content, then gate advanced/new content

### Event Strategy for Freemium
| Event Type | Goal | Frequency |
|-----------|------|-----------|
| Challenge/competition | Create engagement habit | Weekly/biweekly |
| Content update | Show app is actively developed | Monthly |
| Feature spotlight | Showcase premium features organically | Monthly |
| Community event | Build social investment | Quarterly |

---

## Stage 3: Upgrade (Free → Paid)

### Key Features
- **Promoted IAP**: Show premium unlock directly on the App Store product page
- **Paywall Design**: Use `generators/paywall-generator`

### Promoted IAP Best Practices
- Choose your most compelling IAP to promote (usually "Pro" or "Premium" unlock)
- Use a clear, benefit-focused name ("Pro — Unlimited Everything")
- Set an attractive promotional image (1024x1024)
- This appears on your product page and in search results

### Conversion Trigger Points
Show upgrade prompt when the user:
- Hits a free tier limit ("You've used 5 of 5 free projects")
- Tries to access a premium feature
- Completes a successful action (positive emotion = higher conversion)
- Has used the app for 7+ days (investment threshold)

### Pricing for IAP
| IAP Type | Price Range | Strategy |
|----------|-------------|----------|
| Feature unlock | $2.99-$9.99 | One-time, permanent |
| Pro bundle | $9.99-$29.99 | Unlock everything |
| Content pack | $0.99-$4.99 | Per pack, expandable |
| Consumable credits | $0.99-$9.99 | Recurring revenue |
| Tip jar | $0.99-$9.99 | Optional support |

---

## Stage 4: Expand (Increase Revenue per User)

### Key Features
- **Offer Codes**: Give premium access to influencers/partners for promotion
- **Additional IAP**: Upsell existing premium users on add-ons

### Expansion Revenue Tactics
1. **Content packs**: New themes, templates, tools for existing premium users
2. **Feature add-ons**: Specialized features beyond the core premium unlock
3. **Tip jar**: Let satisfied users pay more voluntarily
4. **Bundle pricing**: "All-in-one" bundle at discount vs. individual purchases

---

## Stage 5: Re-Engage (Bring Back Lapsed Users)

### Key Features
- **Offer Codes**: Distribute premium access to lapsed users via email
- **In-App Events**: Major events visible to lapsed users in App Store

### Re-Engagement Timeline
| Days Lapsed | Action | Method |
|-------------|--------|--------|
| 7-14 | Push notification with new content | Notification |
| 14-30 | In-App Event announcement | App Store |
| 30-60 | Offer code for free premium trial | Email |
| 60+ | Major update In-App Event | App Store |

---

## Freemium App Checklist

### Pre-Launch
- [ ] Define free vs. paid feature split (generous free tier)
- [ ] Configure IAP products in App Store Connect
- [ ] Set up Promoted IAP with promotional image
- [ ] Write product page copy emphasizing free value
- [ ] Plan launch In-App Event

### Launch
- [ ] Start Product Page Optimization test
- [ ] Monitor download-to-IAP conversion funnel
- [ ] Create Custom Product Pages for different ad sets
- [ ] Submit featuring nomination

### Growth
- [ ] Establish In-App Event cadence (weekly or biweekly)
- [ ] Distribute offer codes to app reviewers/influencers
- [ ] A/B test paywall timing and messaging
- [ ] Create Custom Product Pages per audience segment
- [ ] Plan seasonal expansion content

### Ongoing
- [ ] Quarterly featuring nominations
- [ ] Regular content/feature updates
- [ ] PPO tests running continuously
- [ ] Offer code campaigns for re-engagement

---

## Freemium App Benchmarks

| Metric | Below Average | Average | Good | Excellent |
|--------|--------------|---------|------|-----------|
| Page → Download | < 20% | 20-35% | 35-50% | > 50% |
| D1 retention | < 25% | 25-35% | 35-50% | > 50% |
| Free → Paid | < 2% | 2-5% | 5-10% | > 10% |
| ARPU (monthly) | < $0.05 | $0.05-0.20 | $0.20-1.00 | > $1.00 |
| IAP refund rate | > 8% | 4-8% | 2-4% | < 2% |
