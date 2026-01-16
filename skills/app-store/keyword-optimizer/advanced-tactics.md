# Advanced ASO Tactics

Hidden strategies that most developers don't know. These can significantly boost discoverability.

## 1. Cross-Localization (Double Your Keywords)

For the US App Store, Apple indexes keywords from **two locales**:

| Locale | Indexed For US |
|--------|----------------|
| English (US) | Yes |
| Spanish (Mexico) | Yes |

### How to Use

In App Store Connect, add **Spanish (Mexico)** localization with **English keywords**:

```
English (US) Keywords:
roommate,group,cost,trip,tab,owe,money,tracker,pay,debt

Spanish (MX) Keywords (English!):
apartment,utilities,travel,vacation,dinner,friends,shared,divide,fair,easy
```

### Rules
- Don't repeat words between locales (no ranking boost)
- Words from different locales DON'T combine into phrases
- Can use English in Spanish locale if targeting US market

### Additional Locales for Other Markets

| Market | Primary | Secondary |
|--------|---------|-----------|
| US | English (US) | Spanish (Mexico) |
| UK | English (UK) | English (Australia) |
| Canada | English (Canada) | French (Canada) |
| Germany | German | English (UK) |
| Spain | Spanish (Spain) | English (UK) |

## 2. Screenshot Text Indexing (June 2025)

Apple now uses **OCR to read screenshot captions** and indexes them for search.

### What Changed

```
Before: Screenshots = conversion only
Now:    Screenshots = conversion + keyword ranking
```

### Where Apple Scans

Apple OCR focuses on **top and bottom** of screenshots:

```
┌─────────────────────┐
│ "SPLIT BILLS FAST"  │  ← TOP: Keywords here
│                     │
│    [App UI]         │
│                     │
│ "With roommates"    │  ← BOTTOM: Keywords here
└─────────────────────┘
```

### Caption Strategy

| Old Caption (Bad) | New Caption (Keyword-Rich) |
|-------------------|---------------------------|
| "Easy to use!" | "Split Bills Instantly" |
| "Track everything" | "Track Shared Expenses" |
| "Simple & fast" | "Settle Up with Friends" |

### Important Notes
- Keywords in screenshots DON'T compete with metadata keywords
- Apple EXPECTS keyword repetition in screenshots (unlike metadata)
- Use your most important keywords in first 2 screenshots
- Reported 22% boost in search visibility within 30 days

## 3. In-App Events (Free Featuring)

Apple allows **5 live events** that appear in search results. Most developers ignore this.

### Benefits
- Events get **separate search indexing**
- Can appear in "Events" tab = extra visibility
- Apple sometimes **features** interesting events
- Re-engages existing users

### Event Ideas by Category

| Category | Event Idea |
|----------|-----------|
| Finance | "New Year Budget Challenge" |
| Health | "30-Day Fitness Challenge" |
| Productivity | "Productivity Week" |
| Education | "Back to School Special" |
| Games | "Weekend Tournament" |

### Event Metadata = More Keywords
Event title and description are indexed separately from your app's main keywords.

## 4. First 48 Hours Velocity Boost

Apple gives new apps/updates a **temporary ranking boost**. Maximize it:

### Launch Strategy
1. Have friends/family download on Day 1
2. Share on social media immediately
3. Email your list on launch day
4. Coordinate with any press/coverage

### Update Strategy
- Don't waste updates on bug fixes alone
- Bundle bug fixes with keyword changes
- Time updates for when you can promote them

## 5. Manipulate "Most Helpful" Reviews

Hidden feature: **Long-press any review** → Mark as "Helpful"

### Strategy
1. Find your best 5-star reviews
2. Long-press each one
3. Mark as "Helpful"
4. They'll rise to "Most Helpful" section

Your top 3 "most helpful" reviews show first to potential users.

## 6. UK English for Extra Keywords

Add **English (UK)** localization with different keywords. These index for:
- United Kingdom
- Partially for other EU countries

### US vs UK Variations

| US Term | UK Term |
|---------|---------|
| roommate | flatmate |
| apartment | flat |
| vacation | holiday |
| check | cheque |
| color | colour |
| organization | organisation |

## 7. Left-to-Right Keyword Weight

Apple's algorithm reads title/subtitle **left to right** and gives more weight to words that appear first.

### Examples

```
Weaker:  Bills Split - Expense App
Stronger: Expense Split - Settle Up
          ↑ Most important word first
```

### Application
- Put your primary keyword FIRST in title
- Put secondary keyword FIRST in subtitle
- Front-load your keyword field too

## 8. Singular vs Plural (Don't Waste Space)

Apple treats these as equivalent:
```
bill = bills
expense = expenses
tracker = trackers
```

**Never include both forms** — it wastes precious characters.

## 9. Stop Words Are Auto-Indexed

Don't waste keyword space on:
```
a, an, the, and, for, with, of, to, by, app, application
```

Apple indexes these automatically.

## 10. Review Keywords = Ranking Boost

When users mention keywords in reviews, it can boost ranking.

### Prompt Strategy
```
"If you love splitting bills with roommates,
please leave a review!"
```

Natural keyword inclusion in reviews = organic boost.

## 11. Conversion Rate Affects Ranking

Apple tracks **impressions → downloads** ratio. Higher conversion = higher ranking.

### Improve Conversion
- Better icon (A/B test with Product Page Optimization)
- First screenshot is most important (70% decide from it alone)
- First 3 words of subtitle are visible in search results

## Quick Reference Checklist

### Zero-Risk Additions
- [ ] Add Spanish (Mexico) locale with extra keywords
- [ ] Add English (UK) locale with extra keywords
- [ ] Update screenshot captions with keywords
- [ ] Create In-App Events
- [ ] Mark best reviews as "Helpful"

### Optimization Rules
- [ ] No duplicate words across fields
- [ ] No spaces after commas in keywords
- [ ] No stop words wasting space
- [ ] No singular AND plural forms
- [ ] Primary keywords at START of title/subtitle
- [ ] Most important keywords in first 2 screenshots

### Tracking
- [ ] Note baseline metrics before changes
- [ ] Check rankings weekly
- [ ] Update keywords every 4-6 weeks
- [ ] Swap underperforming keywords (rank >100)

## Sources

- [MobileAction: Cross-Localization](https://www.mobileaction.co/blog/aso-keyword-research/)
- [AppTweak: Cross-Localization Guide](https://www.apptweak.com/en/aso-blog/how-to-benefit-from-cross-localization-on-the-app-store)
- [Appfigures: Screenshot Algorithm Update](https://appfigures.com/resources/guides/app-store-algorithm-update-2025)
- [Appfigures: Advanced ASO Secrets](https://appfigures.com/resources/guides/advanced-aso-secrets)
