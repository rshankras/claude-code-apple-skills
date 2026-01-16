# Existing App Optimization Strategy

How to improve ASO for apps that already have downloads without risking existing traffic.

## The Risk

When optimizing an existing app:
- You can see **rankings** but not which keywords drive **actual downloads**
- Changing keywords that are working can **kill traffic**
- Recovery can take weeks if you make mistakes

## Identify Traffic Sources

### Method 1: Math-Based Estimation

Traffic from a keyword ≈ **Popularity × Position Factor**

| Position | Approx. Click Share |
|----------|-------------------|
| #1-3 | 40-60% of searches |
| #4-10 | 10-25% of searches |
| #11-30 | 2-8% of searches |
| #30+ | <1% of searches |

### Method 2: Opportunity Score

```
Score = (Popularity × 2) - Difficulty

High Score + Good Rank = Likely driving traffic
Low Score + Any Rank = Probably not driving traffic
```

### Analysis Template

| Keyword | Pop | Rank | Est. Traffic | Protect? |
|---------|-----|------|--------------|----------|
| [keyword] | [X] | #[Y] | High/Med/Low | Yes/No |

**Example:**
| Keyword | Pop | Rank | Est. Traffic | Protect? |
|---------|-----|------|--------------|----------|
| settle up | 29 | #4 | HIGH | YES |
| expense split | 5 | #6 | Low | No |
| settle | 21 | #18 | Medium | YES |
| split bill | 21 | #211 | None | No |

## The Golden Rule

**Never touch what's working.**

```
KEEP (don't change):
- Keywords where you rank Top 10 + Popularity >15
- Your app title if ranking well for branded terms

SAFE TO CHANGE:
- Subtitle (if current keywords not ranking well)
- Keyword field (low-ranking keywords only)
- Add new locales (purely additive)
- Screenshot captions (purely additive)
```

## Phased Rollout Plan

### Phase 1: Additive Only (Week 1-2)

**Zero Risk Actions:**
- [ ] Add Spanish (Mexico) locale with new keywords
- [ ] Add English (UK) locale with new keywords
- [ ] Update screenshot captions with keywords
- [ ] Create 1-2 In-App Events

These don't affect existing rankings — they only ADD opportunities.

### Phase 2: Monitor & Measure (Week 3-4)

Track in your ASO tool:
- [ ] Did new keywords start ranking?
- [ ] Did downloads increase?
- [ ] Did existing rankings stay stable?

**Baseline Tracking Template:**
```
Date: ___________
Daily downloads: ___
Keyword 1: ___ rank #___
Keyword 2: ___ rank #___
Keyword 3: ___ rank #___
```

### Phase 3: Careful Optimization (Week 5-6)

**Only if Phase 2 shows stable/improved metrics:**

- [ ] Update subtitle only (keep title same)
- [ ] Replace lowest-performing keywords in keyword field
- [ ] Keep all top-ranking keywords untouched

### Phase 4: Evaluate Full Changes (Week 7+)

**Only if downloads stable/increased:**
- Consider title adjustments (if needed)
- Continue keyword field optimization
- Always protect your best-ranking keywords

## Safe Change Examples

### Subtitle Change

```
Before: "Simple expense sharing"
After:  "Split bills & rent easily"

Why Safe:
- Keeps core meaning
- Adds target keywords (bills, rent)
- Doesn't remove existing ranking keywords
```

### Keyword Field Change

```
Before: task,todo,list,note,reminder,productivity,organize,manage,plan
After:  todo,reminder,productivity,organize,roommate,trip,dinner,vacation

Why Safe:
- Removed low-value keywords (task, list, note - rank >100)
- Kept high-value keywords (todo, reminder, productivity)
- Added new opportunity keywords
```

## What NOT to Change

### Protect These Keywords

1. **Top 10 Rankings** — Don't touch if Pop >15
2. **Branded Terms** — Your app name/company
3. **Core Category Terms** — If you're a "timer app", keep "timer"

### Red Flags

Don't change if:
- Keyword ranks Top 5 with Pop >20
- Keyword drives measurable traffic (from Apple Search Ads data)
- It's your app's core identity term

## Apple Search Ads for Data

If possible, run a small Apple Search Ads campaign ($20-50):

### What You Learn
- Exact keywords driving installs
- Conversion rates per keyword
- Cost per install (indicates competition)

### Campaign Strategy
1. Create "Exact Match" ad groups
2. Add your suspected traffic-driving keywords
3. Run for 1-2 weeks
4. Analyze which keywords convert

This data is **gold** for deciding what to protect vs. change.

## Recovery Plan

If rankings drop after changes:

### Immediate (Day 1-3)
- Document what changed
- Check if rankings are actually down or just fluctuating
- Don't panic — rankings fluctuate naturally

### Short-Term (Week 1)
- If significant drop, consider reverting changes
- Reversion takes ~1 week to re-index

### Long-Term (Week 2+)
- If still down, revert to previous metadata
- Wait for full re-indexing (2-4 weeks)
- Try smaller changes next time

## Checklist: Before Making Changes

- [ ] Documented current rankings for all tracked keywords
- [ ] Identified which keywords are likely driving traffic
- [ ] Listed keywords that are PROTECTED (won't change)
- [ ] Planned additive changes first (new locales, screenshots)
- [ ] Have a rollback plan if things go wrong
- [ ] Set calendar reminder to check metrics in 1 week

## Example: Safe Optimization Flow

**App:** Expense Split (7 downloads/day)

**Current Rankings:**
- "settle up" — #4, Pop 29 → PROTECT
- "settle" — #18, Pop 21 → PROTECT
- "split bill" — #211, Pop 21 → SAFE TO TARGET

**Phase 1 Plan:**
1. Add Spanish (MX) with: roommate,apartment,utilities,dinner,trip,vacation
2. Add screenshot caption: "Split Bills with Roommates"
3. DON'T change title (has "Settle Up")

**Phase 2 Monitor:**
- Check if new keywords start ranking
- Verify "settle up" stays at #4
- Track daily downloads

**Phase 3 (if stable):**
- Update subtitle to include "split bills"
- Replace low-value keywords in keyword field
