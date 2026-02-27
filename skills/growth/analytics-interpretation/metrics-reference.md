# Metrics Reference

Definitions, formulas, and benchmarks for key app metrics. Use this as a lookup when interpreting user data in the analytics-interpretation skill.

## Metric Definitions and Formulas

### Engagement Metrics

**DAU (Daily Active Users)**
Users who open the app at least once in a calendar day.
```
DAU = count of unique users with at least one session on a given day
```

**MAU (Monthly Active Users)**
Users who open the app at least once in a 30-day rolling window.
```
MAU = count of unique users with at least one session in the last 30 days
```

**DAU/MAU Ratio (Stickiness)**
Percentage of monthly users who use the app on any given day. Higher = more habitual usage.
```
DAU/MAU = DAU / MAU × 100
```

**Session Length**
Average time spent per app session, from foreground to background.
```
Avg Session Length = total session time / total sessions
```

**Sessions Per User Per Day**
How many times the average daily user opens the app.
```
Sessions/User/Day = total daily sessions / DAU
```

### Retention Metrics

**Day N Retention (D1, D7, D30)**
Percentage of users who installed on Day 0 and returned on Day N.
```
DN Retention = users active on Day N / users installed on Day 0 × 100
```
Note: This is "classic retention" (active on exactly Day N), not "rolling retention" (active on Day N or later).

**Rolling Retention (Return Rate)**
Percentage of users who installed on Day 0 and returned on Day N or any day after.
```
Rolling DN Retention = users active on Day N or later / users installed on Day 0 × 100
```
Rolling retention is always >= classic retention and gives a more optimistic view.

**Weekly Retention**
Percentage of users active in Week 1 who are also active in Week N.
```
Week N Retention = users active in Week N / users active in Week 1 × 100
```

**Churn Rate (Monthly)**
Percentage of subscribers who cancel in a given month.
```
Monthly Churn = subscribers lost in month / subscribers at start of month × 100
```

### Revenue Metrics

**LTV (Lifetime Value)**
Total revenue expected from a single user over their entire lifetime.
```
LTV = ARPU / Monthly Churn Rate
or
LTV = ARPU × Average Customer Lifetime (in months)
```

**ARPU (Average Revenue Per User)**
Revenue per user across all users (including free users).
```
ARPU = total revenue / total users (in period)
```

**ARPPU (Average Revenue Per Paying User)**
Revenue per paying user only.
```
ARPPU = total revenue / paying users (in period)
```

**MRR (Monthly Recurring Revenue)**
Predictable monthly revenue from active subscriptions.
```
MRR = number of active subscribers × average monthly subscription price
```

**ARR (Annual Recurring Revenue)**
Annualized version of MRR.
```
ARR = MRR × 12
```

**CAC (Customer Acquisition Cost)**
Cost to acquire one new user through paid channels.
```
CAC = total acquisition spend / new users acquired
```

**Payback Period**
Months to recoup the cost of acquiring a user.
```
Payback Period = CAC / monthly ARPU (in months)
```

**Trial Start Rate**
Percentage of downloads that start a free trial.
```
Trial Start Rate = trial starts / downloads × 100
```

**Trial Conversion Rate**
Percentage of free trials that convert to paid subscriptions.
```
Trial Conversion = paid conversions / trial starts × 100
```

### App Store Metrics

**Impressions**
Number of times your app appeared in App Store search results, featured sections, or browse pages. Counts views of your icon/title, not full page views.

**Product Page Views (PPV)**
Number of times users tapped through to your full product page (screenshots, description, reviews).

**Tap-Through Rate (TTR)**
```
TTR = Product Page Views / Impressions × 100
```

**Conversion Rate (CVR)**
```
CVR = App Units (downloads) / Product Page Views × 100
```

**App Units**
First-time downloads. Does not include re-downloads or updates.

## Benchmarks by App Category

### Social / Communication Apps
| Metric | Poor | Average | Good | Excellent |
|--------|------|---------|------|-----------|
| DAU/MAU | < 20% | 20-40% | 40-60% | > 60% |
| D1 Retention | < 20% | 20-30% | 30-40% | > 40% |
| D7 Retention | < 8% | 8-15% | 15-25% | > 25% |
| D30 Retention | < 4% | 4-8% | 8-15% | > 15% |
| Session Length | < 2 min | 2-5 min | 5-15 min | > 15 min |
| Sessions/Day | < 2 | 2-4 | 4-8 | > 8 |

### Productivity / Business Apps
| Metric | Poor | Average | Good | Excellent |
|--------|------|---------|------|-----------|
| DAU/MAU | < 10% | 10-20% | 20-30% | > 30% |
| D1 Retention | < 15% | 15-25% | 25-35% | > 35% |
| D7 Retention | < 7% | 7-12% | 12-20% | > 20% |
| D30 Retention | < 3% | 3-6% | 6-12% | > 12% |
| Session Length | < 1 min | 1-3 min | 3-10 min | > 10 min |
| Trial-to-Paid | < 20% | 20-40% | 40-60% | > 60% |

### Games (Casual)
| Metric | Poor | Average | Good | Excellent |
|--------|------|---------|------|-----------|
| DAU/MAU | < 10% | 10-15% | 15-25% | > 25% |
| D1 Retention | < 25% | 25-35% | 35-45% | > 45% |
| D7 Retention | < 8% | 8-15% | 15-20% | > 20% |
| D30 Retention | < 3% | 3-6% | 6-10% | > 10% |
| Session Length | < 3 min | 3-8 min | 8-20 min | > 20 min |
| Sessions/Day | < 2 | 2-3 | 3-5 | > 5 |

### Utilities / Tools
| Metric | Poor | Average | Good | Excellent |
|--------|------|---------|------|-----------|
| DAU/MAU | < 5% | 5-10% | 10-20% | > 20% |
| D1 Retention | < 15% | 15-20% | 20-30% | > 30% |
| D7 Retention | < 5% | 5-10% | 10-15% | > 15% |
| D30 Retention | < 2% | 2-5% | 5-10% | > 10% |
| Session Length | < 30s | 30s-2 min | 2-5 min | > 5 min |

Note: Utility apps often have low DAU/MAU because they are used only when needed (e.g., a calculator). Low stickiness is not necessarily bad for utilities — focus on retention and satisfaction instead.

### Subscription Apps (General)
| Metric | Poor | Average | Good | Excellent |
|--------|------|---------|------|-----------|
| Trial Start Rate | < 10% | 10-20% | 20-30% | > 30% |
| Trial-to-Paid | < 30% | 30-50% | 50-65% | > 65% |
| Monthly Churn | > 15% | 10-15% | 5-10% | < 5% |
| Annual Churn | > 50% | 35-50% | 20-35% | < 20% |
| LTV | < $10 | $10-30 | $30-80 | > $80 |
| Payback Period | > 6 mo | 3-6 mo | 1-3 mo | < 1 mo |

## App Store Conversion Benchmarks

### Tap-Through Rate (Impressions → Product Page Views)
| Category | Poor | Average | Good |
|----------|------|---------|------|
| Games | < 3% | 3-7% | > 7% |
| Productivity | < 4% | 4-8% | > 8% |
| Social | < 3% | 3-6% | > 6% |
| Utilities | < 5% | 5-10% | > 10% |
| Health & Fitness | < 4% | 4-8% | > 8% |

### Product Page Conversion Rate (PPV → Downloads)
| Category | Poor | Average | Good |
|----------|------|---------|------|
| Games (Free) | < 25% | 25-40% | > 40% |
| Games (Paid) | < 5% | 5-15% | > 15% |
| Productivity (Free) | < 20% | 20-35% | > 35% |
| Productivity (Paid) | < 8% | 8-20% | > 20% |
| Utilities (Free) | < 30% | 30-50% | > 50% |
| Utilities (Paid) | < 10% | 10-25% | > 25% |

## Quick Threshold Reference

Use these stoplight ratings in analytics reports:

| Metric | 🔴 Red | 🟡 Yellow | 🟢 Green |
|--------|--------|----------|---------|
| D1 Retention | < 20% | 20-35% | > 35% |
| D7 Retention | < 10% | 10-20% | > 20% |
| D30 Retention | < 5% | 5-10% | > 10% |
| DAU/MAU | < 10% | 10-25% | > 25% |
| Trial-to-Paid | < 30% | 30-50% | > 50% |
| Monthly Churn | > 12% | 7-12% | < 7% |
| TTR | < 4% | 4-8% | > 8% |
| PPV → Download CVR | < 20% | 20-35% | > 35% |
| App Rating | < 3.5 | 3.5-4.3 | > 4.3 |
| Refund Rate | > 10% | 5-10% | < 5% |

Note: These are general guidelines. Always consider app category, target audience, and monetization model when evaluating. A utility app with 8% DAU/MAU might be performing excellently, while a social app at 8% has a problem.
