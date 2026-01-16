# Keyword Selection Criteria

How to evaluate and select keywords for maximum impact with achievable rankings.

## The Indie Developer Strategy

From successful indie devs building $200-2,000/month apps:

```
Find keywords with:
- Popularity > 20 (enough traffic)
- Difficulty < 60 (beatable competition)
```

Build simple, single-feature apps around those keywords.

## Understanding Scores

### Popularity Score (0-100)

From Apple Search Ads. Represents search volume.

| Score | Traffic Level | Notes |
|-------|--------------|-------|
| 5-15 | Very Low | Only target if very niche |
| 16-25 | Low | Good for long-tail, low competition |
| 26-40 | Medium | Sweet spot for indie apps |
| 41-60 | Good | Worthwhile if difficulty allows |
| 61-80 | High | Usually high competition |
| 81-100 | Very High | Dominated by brands |

**Important:** Popularity is exponential, not linear.
- Score 50 is NOT 2x traffic of Score 25
- Score 80 could be 10x traffic of Score 40

### Difficulty Score (0-100)

Estimated from competitor strength and count.

| Score | Competition | Your Chances |
|-------|------------|--------------|
| 0-25 | Very Low | Easy ranking |
| 26-40 | Low | Good opportunity |
| 41-55 | Medium | Achievable with good ASO |
| 56-70 | High | Hard, need excellent app + ASO |
| 71-100 | Very High | Dominated by established apps |

## The Sweet Spot Matrix

```
        │ Difficulty
        │ Low (<40)  │ Med (40-55) │ High (>55)
────────┼────────────┼─────────────┼──────────────
Pop     │            │             │
High    │ GOLD       │ WORTH IT    │ LONG-TERM
(40+)   │ Target Now │ Target Now  │ GOAL
────────┼────────────┼─────────────┼──────────────
Pop     │            │             │
Med     │ GREAT      │ GOOD        │ SKIP
(25-40) │ Target Now │ Consider    │ Too Hard
────────┼────────────┼─────────────┼──────────────
Pop     │            │             │
Low     │ MAYBE      │ SKIP        │ SKIP
(15-25) │ Easy Win   │ Not Worth   │ Not Worth
────────┼────────────┼─────────────┼──────────────
Pop     │            │             │
V.Low   │ SKIP       │ SKIP        │ SKIP
(<15)   │ No Traffic │ No Traffic  │ No Traffic
```

## Opportunity Score Formula

Calculate opportunity score for comparison:

```
Opportunity Score = (Popularity × 2) - Difficulty

Bonus: +20 if Pop 20-50 AND Diff <40 (sweet spot)
Bonus: +10 if Pop 20-50 AND Diff <50 (good range)
Penalty: -30 if Diff >70 (very competitive)
```

### Grading Scale

| Score | Grade | Action |
|-------|-------|--------|
| 80+ | A+ | HIGH PRIORITY - Target immediately |
| 60-79 | A | Good opportunity |
| 40-59 | B | Worth pursuing |
| 20-39 | C | Consider if relevant |
| 0-19 | D | Low priority |
| <0 | F | Skip |

### Example Calculations

```
"brown noise" - Pop 25, Diff 30
Score = (25 × 2) - 30 + 20 (bonus) = 40 → Grade B

"meditation timer" - Pop 35, Diff 45
Score = (35 × 2) - 45 + 10 (bonus) = 35 → Grade C

"podcast app" - Pop 70, Diff 85
Score = (70 × 2) - 85 - 30 (penalty) = 25 → Grade C (despite high pop!)
```

## Keyword Categories by Opportunity

### Tier 1: Target Immediately
- Pop 25-50, Diff <40
- Pop 40-60, Diff <50
- Score 60+

### Tier 2: Good Opportunities
- Pop 20-40, Diff 40-55
- Pop 50-70, Diff 50-60
- Score 40-59

### Tier 3: Long-term Goals
- Pop 60+, Diff 60-75
- Build app strength first, then target

### Tier 4: Skip
- Pop <15 (not enough traffic)
- Diff >75 (too competitive)
- Score <20

## Finding Keywords to Analyze

### Tool: Astro (Recommended for Indies)

1. Search a seed keyword
2. Note Popularity and Difficulty
3. Check "Related Keywords" suggestions
4. Look for sweet spot matches

### Seed Keyword Strategy

Start with generic terms, find specific variants:

```
Seed: "timer"
├── pomodoro timer (Pop 35, Diff 42) ✅
├── study timer (Pop 28, Diff 38) ✅
├── focus timer (Pop 40, Diff 55) ⚠️
├── interval timer (Pop 32, Diff 35) ✅
└── countdown timer (Pop 45, Diff 62) ⚠️

Best: "interval timer", "pomodoro timer", "study timer"
```

### Category-Specific Opportunities

Based on Nov 2025 App Store data:

| Category | High-Opportunity Keywords |
|----------|--------------------------|
| Health | "ai coach", "brown noise", "pink noise" |
| Business | "invoice", "fax", "side hustle" |
| Utilities | "storage cleaner", "free up space" |
| Lifestyle | "mood tracker", "gratitude journal" |
| Music | "metronome", "tuner" |
| Productivity | "pomodoro timer", "habit tracker" |

## Competitor Keyword Analysis

### Finding Keyword Gaps

1. In Astro, tap on competitor apps
2. See what keywords they rank for
3. Find keywords where:
   - They rank #20-50 (not optimized)
   - You don't rank at all
   - Pop >20, Diff <50

### Steal Strategy

Target keywords competitors rank for weakly:
- Their rank: #30-100
- Your potential: Top 10 with good ASO

## Trademark Considerations

### Check Before Targeting

Some keywords are trademarked:
- "Divvy" — Bill.com trademark
- "Splitwise" — Brand name
- "Venmo" — Brand name

### Safe vs Risky Keywords

| Safe (Generic) | Risky (Trademarked) |
|----------------|-------------------|
| split bill | splitwise |
| expense tracker | divvy |
| payment | venmo |
| settle up | paypal |

### Rule

If a keyword shows high popularity but is a brand name:
- Traffic is people looking for THAT app
- Even if you rank, conversion will be poor
- May get trademark complaint

## Quick Evaluation Checklist

For each keyword:

- [ ] Popularity >20? (enough traffic)
- [ ] Difficulty <60? (beatable)
- [ ] Not a trademark/brand?
- [ ] Relevant to your app?
- [ ] Makes sense in title/subtitle/keywords?

If all yes → Target it
If any no → Skip or deprioritize

## Keyword Tracking Template

```csv
keyword,popularity,difficulty,opportunity_score,grade,current_rank,action
pomodoro timer,35,42,48,B,-,Target in subtitle
study timer,28,38,38,C,-,Add to keywords
interval timer,32,35,49,B,-,Target in title
meditation,65,78,-31,F,-,Skip - too competitive
```

## When to Re-evaluate

- **Weekly:** Check ranking changes
- **Monthly:** Re-run opportunity analysis
- **Quarterly:** Major keyword strategy review
- **Seasonally:** Add seasonal keywords (holiday, summer, etc.)
