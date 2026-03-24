# Advanced ASO Tactics

Hidden strategies that most developers don't know. These can significantly boost discoverability.

## 1. Cross-Localization (10x Your Keywords)

Apple indexes keywords from **multiple locales per storefront**. Each additional locale gives you up to **160 extra indexable characters** (30 title + 30 subtitle + 100 keywords). For the US alone, that's up to **1,440 bonus characters**.

### US App Store — 10 Indexed Locales

| # | Locale | Code | Notes |
|---|--------|------|-------|
| 1 | English (US) | en-US | Primary |
| 2 | Spanish (Mexico) | es-MX | Most commonly used secondary |
| 3 | Arabic | ar | |
| 4 | Chinese (Simplified) | zh-Hans | |
| 5 | Chinese (Traditional) | zh-Hant | |
| 6 | French | fr | |
| 7 | Korean | ko | |
| 8 | Portuguese (Brazil) | pt-BR | |
| 9 | Russian | ru | |
| 10 | Vietnamese | vi | |

### How to Use

In App Store Connect, add secondary localizations with **English keywords** (you don't need to translate — English words index for the US market regardless of which locale they're in):

```
English (US) Keywords:
roommate,group,cost,trip,tab,owe,money,tracker,pay,debt

Spanish (MX) Keywords (English!):
apartment,utilities,travel,vacation,dinner,friends,shared,divide,fair,easy

Portuguese (BR) Keywords (English!):
budget,household,groceries,restaurant,rent,settle,balance,fair,receipt,reimburse

Arabic Keywords (English!):
colleague,lunch,cab,uber,airbnb,weekend,event,party,wedding,gift

... repeat for remaining locales with NEW unique keywords each time
```

### Rules
- **No duplicate words across ANY locale** — each word is counted only once even across locales, so repetition provides zero ranking boost
- Words from different locales **DON'T combine** into phrases (only words within the same locale combine)
- You CAN use English in any locale if targeting an English-speaking market
- Apply the same Title → Subtitle → Keywords dedup cascade within each locale
- Prioritize your highest-value keywords in en-US (highest weight), use secondary locales for long-tail and supplementary terms

### Cross-Localization for All Major Markets

| Market | Primary Locale | Secondary Locales Indexed |
|--------|---------------|--------------------------|
| **United States** | English (US) | Spanish (MX), Arabic, Chinese (Simplified), Chinese (Traditional), French, Korean, Portuguese (BR), Russian, Vietnamese |
| **Canada** | English (Canada) | French (Canada) |
| **United Kingdom** | English (UK) | — (single locale) |
| **Australia** | English (Australia) | — (single locale) |
| **Mexico** | Spanish (Mexico) | English (US) |
| **Brazil** | Portuguese (Brazil) | English (US) |
| **Japan** | Japanese | English (US) |
| **South Korea** | Korean | English (US) |
| **China (Mainland)** | Chinese (Simplified) | English (US) |
| **Taiwan** | Chinese (Traditional) | English (US) |
| **Germany** | German | English (UK) |
| **France** | French | English (UK) |
| **Spain** | Spanish (Spain) | English (UK), Catalan |
| **Italy** | Italian | English (UK) |
| **Netherlands** | Dutch | English (UK) |
| **Portugal** | Portuguese (Portugal) | English (UK) |
| **Russia** | Russian | English (UK) |
| **India** | English (India) | Hindi |
| **Switzerland** | German (Switzerland) | French, Italian, English (UK) |
| **Belgium** | Dutch (Belgium) | French (Belgium) |
| **Sweden** | Swedish | English (UK) |
| **Norway** | Norwegian | English (UK) |
| **Denmark** | Danish | English (UK) |
| **Finland** | Finnish | English (UK) |

**Key pattern:** English (UK) is the fallback for most European markets. English (US) is the fallback for most Asian and Latin American markets.

### Implementation Priority

For an English-language app targeting the US market:

```
Phase 1 (Day 1): Set up en-US with your best keywords
Phase 2 (Day 1): Add es-MX with next-best English keywords
Phase 3 (Week 1): Add pt-BR, fr, ko with more English keywords
Phase 4 (Week 2): Add zh-Hans, zh-Hant, ar, ru, vi to fill remaining slots
Phase 5 (Week 3): If targeting EU/Asia, add en-UK keywords for European reach
```

### Character Budget Calculator

```
US Market Total Indexable Characters:
  10 locales × (30 title + 30 subtitle + 100 keywords) = 1,600 characters

Minus primary en-US:                                     = 1,440 bonus characters
Minus realistic dedup overhead (~15%):                   ≈ 1,220 usable bonus characters

That's 12x your single-locale keyword capacity.
```

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
- [ ] Add all 9 secondary US locales (es-MX, ar, zh-Hans, zh-Hant, fr, ko, pt-BR, ru, vi) with unique English keywords
- [ ] Add en-UK locale with extra keywords (for European market reach)
- [ ] Update screenshot captions with keywords
- [ ] Create In-App Events
- [ ] Mark best reviews as "Helpful"

### Optimization Rules
- [ ] No duplicate words across fields (Title → Subtitle → Keywords cascade)
- [ ] No duplicate words across locales (each word counted once globally)
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

- [ASO.dev: Cross-Localization Guide](https://aso.dev/metadata/cross-localization/)
- [AppTweak: Cross-Localization Guide](https://www.apptweak.com/en/aso-blog/how-to-benefit-from-cross-localization-on-the-app-store)
- [AppFollow: App Store Keywords Localizations](https://appfollow.io/app-store-keywords-localizations)
- [Appfigures: 10x Your Keyword List](https://appfigures.com/resources/guides/extend-keyword-list)
- [OutrankApps: Cross-Localization Guide](https://outrankapps.com/app-store-optimization-cross-localization/)
- [Appfigures: Screenshot Algorithm Update](https://appfigures.com/resources/guides/app-store-algorithm-update-2025)
- [Appfigures: Advanced ASO Secrets](https://appfigures.com/resources/guides/advanced-aso-secrets)
- [MobileAction: Cross-Localization](https://www.mobileaction.co/blog/aso-keyword-research/)
