---
name: keyword-optimizer
description: Optimize app title, subtitle, and keywords for maximum App Store discoverability. Use when launching a new app, improving search rankings, entering new markets/languages, or safely optimizing ASO for an app with existing traffic.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, WebSearch]
---

# Keyword Optimizer

Optimize app title, subtitle, and keywords for maximum App Store discoverability.

## When This Skill Activates

- User is launching a new app
- User wants to improve search rankings
- User asks about ASO (App Store Optimization)
- User is entering new markets/languages
- User wants to analyze keyword opportunities
- User needs safe optimization for existing apps

## Reference Files

Before optimizing, load these reference materials:

| File | Purpose |
|------|---------|
| **keyword-criteria.md** | Popularity/Difficulty sweet spots, opportunity scoring |
| **advanced-tactics.md** | Cross-localization, screenshot indexing, velocity boost |
| **existing-app-strategy.md** | Safe optimization for apps with existing traffic |

## Information Gathering

Before optimizing, ask about:

1. **App Identity**
   - What does the app do in one sentence?
   - What category is it in?
   - What's the current app name (if exists)?

2. **Target Keywords**
   - What would users search to find this app?
   - What problem words would they use?
   - Any branded terms to include?

3. **Competition**
   - Main competitors?
   - What keywords do they target?
   - Where can you realistically compete?

4. **Goals**
   - Brand awareness vs. category traffic?
   - Specific markets to prioritize?

## Keyword Strategy

### Where Keywords Count

| Field | Limit | Weight | Notes |
|-------|-------|--------|-------|
| **App Name** | 30 chars | Highest | Most valuable real estate |
| **Subtitle** | 30 chars | High | Visible in search, below name |
| **Keywords** | 100 chars | Medium | Not visible to users |
| **Description** | 4000 chars | Low* | *Apple says indexed, debated |

### Keyword Types

1. **Branded** - Your app name, company name
2. **Category** - Generic terms (e.g., "todo app", "weather")
3. **Feature** - Specific functionality (e.g., "offline maps")
4. **Problem** - User pain points (e.g., "forget tasks")
5. **Long-tail** - Specific phrases (e.g., "minimalist habit tracker")

## Optimization Process

### Step 1: Keyword Research

**Generate Initial List:**
```
1. Brainstorm 50+ keywords
2. What would YOU search for this app?
3. Check competitor names/subtitles
4. Use autocomplete suggestions
5. Consider misspellings users make
```

**Research Tools:**
- App Store Search Autocomplete
- AppFollow, Sensor Tower, AppTweak (paid)
- Google Keyword Planner (related terms)
- Competitor subtitle/keyword analysis

### Step 2: Prioritize Keywords

Rate each keyword on:

| Factor | Question |
|--------|----------|
| **Relevance** | Does it accurately describe your app? |
| **Volume** | Do people actually search this? |
| **Difficulty** | Can you realistically rank? |
| **Intent** | Will searchers want your app? |

**Priority Matrix:**
```
High Volume + Low Difficulty = 🎯 Target First
High Volume + High Difficulty = 💪 Long-term Goal
Low Volume + Low Difficulty = ✅ Easy Wins
Low Volume + High Difficulty = ❌ Skip
```

### Step 3: Allocate Keywords

**App Name (30 characters):**
```
[Brand Name] - [Top Keyword Phrase]
or
[Brand Name]: [Value Proposition]

Examples:
"Notion - Notes & Docs"
"Calm: Sleep & Meditation"
"Fantastical - Calendar & Tasks"
```

**Subtitle (30 characters):**
```
[Second Priority Keywords] / [Unique Value]

Examples:
"Focus Timer & Daily Planner"
"Simple Habit Building"
"Weather Radar & Forecasts"
```

**Keywords Field (100 characters):**
```
Rules:
- Comma-separated, NO spaces after commas
- No plurals (Apple handles it)
- No duplicates from name/subtitle
- No category name (already indexed)
- Single words perform better than phrases

Example:
"timer,pomodoro,focus,concentration,study,productivity,work,session,break,technique"
```

## Character Optimization

### Maximize 100 Characters

**Bad (wastes characters):**
```
task manager, todo list, productivity app, reminder app, checklist
```

**Good (efficient):**
```
task,todo,productivity,reminder,checklist,planner,organize,gtd,schedule,daily
```

**Savings:**
- Remove spaces after commas
- Don't repeat words in different forms
- Skip obvious words (app, free, best)

### Word Combinations

Apple combines words from all fields:

```
Name: "Focus Timer"
Subtitle: "Pomodoro Technique"
Keywords: "study,productivity,work,session"

Searchable combinations:
- "focus timer"
- "pomodoro timer"
- "focus productivity"
- "study timer"
- "work focus"
(and more...)
```

## Cross-Field Deduplication

Apple indexes words from **all three fields** for the same locale. A word only needs to appear **once** — putting it in multiple fields wastes characters and provides zero ranking benefit.

### Priority Cascade

```
Title (30 chars)     → Highest search weight
  ↓ words flow down
Subtitle (30 chars)  → High search weight
  ↓ words flow down
Keywords (100 chars) → Medium search weight
```

**The rule:** If a word appears in your Title, **do not repeat it** in Subtitle or Keywords. If a word appears in your Subtitle, **do not repeat it** in Keywords. Apple already indexes it from the higher-weight field.

### Why This Matters

Every duplicated word steals characters from the Keywords field where you could fit **new** discoverable terms. With only 100 characters, even one wasted word costs you reach.

### Validation Process

For each locale, extract every word from all three fields and check for overlaps:

```
Step 1: List all words in Title
Step 2: List all words in Subtitle → flag any that appear in Title
Step 3: List all words in Keywords → flag any that appear in Title OR Subtitle
Step 4: Remove flagged words from lower fields
Step 5: Replace removed words with new keyword opportunities
```

### Before & After Example

```
❌ BEFORE (duplicated words waste 23 characters):

Title:    "Focus Timer - Stay Productive"
Subtitle: "Pomodoro Timer & Focus Sessions"
Keywords: "timer,focus,pomodoro,productive,study,work,session,break"

Duplicates:
  "timer"      — in Title AND Subtitle AND Keywords
  "focus"      — in Title AND Subtitle AND Keywords
  "pomodoro"   — in Subtitle AND Keywords
  "productive" — in Title ("Productive") AND Keywords
  "session"    — in Subtitle ("Sessions") AND Keywords

Wasted: 5 keyword slots = ~38 characters lost

✅ AFTER (zero duplication, 5 new keywords gained):

Title:    "Focus Timer - Stay Productive"
Subtitle: "Pomodoro Technique & Deep Work"
Keywords: "study,concentration,interval,tomato,distraction,block,exam,revision,flowstate,desk"

New searchable combinations gained:
  "focus concentration"  "timer interval"
  "study timer"          "deep focus"
  "exam study"           "pomodoro technique"
```

### Quick Dedup Check

When generating keyword recommendations, always verify:

| Check | Rule |
|-------|------|
| Title word in Subtitle? | Remove from Subtitle |
| Title word in Keywords? | Remove from Keywords |
| Subtitle word in Keywords? | Remove from Keywords |
| Plural/singular variant across fields? | Keep only in highest field |
| Stop words (a, the, and, for)? | Don't include anywhere — auto-indexed |

## Common Mistakes

❌ **Don't Do This:**
- Using spaces after commas in keywords
- Duplicating words across fields
- Including your category name
- Using competitor brand names
- Adding "app" or "application"
- Including "free" (filterable separately)
- Using special characters or emoji
- Repeating singular/plural forms

✅ **Do This:**
- Research before guessing
- Prioritize relevance over volume
- Update keywords quarterly
- Track ranking changes
- Localize keywords per market

## Keyword Template

```
APP NAME STRATEGY
━━━━━━━━━━━━━━━━━
Current: [existing name or blank]
Proposed: [Brand] - [Keywords]
Characters: [X/30]
Primary keywords: [list]

SUBTITLE STRATEGY
━━━━━━━━━━━━━━━━━
Current: [existing subtitle or blank]
Proposed: [keyword-rich subtitle]
Characters: [X/30]
Secondary keywords: [list]

KEYWORDS FIELD (100 chars)
━━━━━━━━━━━━━━━━━━━━━━━━━
Proposed: keyword1,keyword2,keyword3,...
Characters: [X/100]

EXPECTED COMBINATIONS
━━━━━━━━━━━━━━━━━━━━━
• [combination 1]
• [combination 2]
• [combination 3]
...
```

## Localization Strategy

### Priority Markets by Revenue

1. 🇺🇸 United States (English)
2. 🇨🇳 China (Simplified Chinese)
3. 🇯🇵 Japan (Japanese)
4. 🇬🇧 UK (British English - can differ!)
5. 🇩🇪 Germany (German)
6. 🇫🇷 France (French)
7. 🇰🇷 South Korea (Korean)
8. 🇪🇸 Spain (Spanish)
9. 🇮🇹 Italy (Italian)
10. 🇧🇷 Brazil (Portuguese)

### Localization Tips

- Don't just translate—research local search terms
- Some markets search in English even for local apps
- Character limits may be tighter in some languages
- Hire native speakers to verify keywords make sense
- Consider cultural differences in app usage

## Tracking & Iteration

### What to Track

- Keyword rankings (use ASO tools)
- Impressions (App Store Connect)
- Conversion rate
- Download sources

### When to Update

- **Weekly:** Check ranking changes
- **Monthly:** Assess underperforming keywords
- **Quarterly:** Major keyword refresh
- **Seasonally:** Add seasonal keywords

### A/B Testing

App Store Connect allows testing:
- App icons
- Screenshots
- App previews

Use Product Page Optimization to test different approaches.

## Quick Reference

### Prohibited Terms
- "Free" (use pricing filter instead)
- "#1" or "best" without verification
- Competitor names
- "App" or "application"
- Pricing information

### Always Include
- Core functionality words
- Problem/solution words
- Category-relevant terms
- Action verbs users would search

### Character Limits
```
App Name:      30 characters
Subtitle:      30 characters
Keywords:     100 characters
Description: 4000 characters (low SEO value)
```

## Indie Developer Strategy

For building apps that generate $200-2,000/month:

### The Sweet Spot Formula
```
Target keywords where:
- Popularity > 20 (enough traffic)
- Difficulty < 60 (beatable competition)

Ideal: Popularity 25-50, Difficulty < 45
```

### Process
1. Find underserved keywords using ASO tools (Astro, AppTweak)
2. Build simple, single-feature apps around those keywords
3. Double down on winners, abandon losers
4. Portfolio effect compounds (30 apps × $500 = $15k/month)

See **keyword-criteria.md** for detailed scoring and evaluation.

## Advanced Tactics Summary

### Cross-Localization (Double Keywords)
Add Spanish (Mexico) locale with English keywords for US market.
See **advanced-tactics.md** for all locales.

### Screenshot Text Indexing (June 2025)
Apple OCR reads screenshot captions for keyword ranking.
Put keywords in top/bottom of screenshots.

### Existing App Optimization
Never change what's working. Use phased rollout.
See **existing-app-strategy.md** for safe optimization.
