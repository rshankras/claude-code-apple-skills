---
name: localization-strategy
description: Localization and internationalization strategy for iOS/macOS apps. Covers market prioritization, language tier recommendations, minimum viable localization levels, translation workflows, cultural adaptation, localized ASO, and testing. Use when planning localization, expanding to new markets, deciding which languages to support, or planning translation workflow.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion, WebSearch]
---

# Localization Strategy

End-to-end localization planning for Apple platform apps — from market prioritization through translation workflow to localized App Store optimization.

## When This Skill Activates

Use this skill when the user:
- Wants to localize their app for new markets
- Asks "which languages should I support?"
- Needs help deciding market expansion priorities
- Wants to plan a translation workflow
- Asks about internationalization (i18n) best practices
- Mentions "localization", "translation", "multi-language", or "global markets"
- Wants to understand localization ROI by language
- Needs cost estimates for translation
- Asks about right-to-left (RTL) layout support
- Wants to localize App Store metadata (title, description, keywords, screenshots)

## Process

### Phase 1: Market Prioritization Framework

Not all languages are equal. Prioritize by revenue potential, not just speaker count.

#### Revenue Potential by Language

Based on App Store revenue data and per-user spending patterns:

| Language | Relative Revenue Potential | Why |
|----------|---------------------------|-----|
| English | Baseline (1.0x) | Largest single market, highest per-user spend |
| Japanese | 0.8-1.2x | Extremely high willingness to pay, especially for subscriptions |
| Chinese (Simplified) | 0.6-0.9x | Massive volume, growing per-user spend, competitive market |
| German | 0.4-0.6x | High per-user spend, values quality and privacy |
| French | 0.3-0.5x | Large market across France, Canada, Africa |
| Korean | 0.3-0.5x | Tech-savvy users, high app spending per capita |
| Spanish | 0.3-0.4x | Huge population, lower per-user spend, growing market |
| Portuguese (Brazilian) | 0.2-0.4x | Large market, mobile-first users, growing economy |

**Key insight:** Japanese and German users often pay 2-3x more per user than Spanish or Portuguese users. Volume vs. value is the fundamental tradeoff.

#### Category-Specific Priorities

App category changes which languages to prioritize first:

| App Category | Prioritize First | Why |
|--------------|-----------------|-----|
| Productivity / Business | Japanese, German, French | High willingness to pay for tools |
| Games | Japanese, Korean, Chinese Simplified | Gaming culture, high IAP spend |
| Social / Communication | Spanish, Portuguese, French | Large connected populations |
| Health / Fitness | German, Japanese, Korean | Health-conscious, high-spend markets |
| Education / Kids | Chinese Simplified, Japanese, Spanish | Education investment culture |
| Creative Tools | Japanese, German, French | Creative professional markets |
| Finance / Budgeting | German, French, Japanese | Financial discipline culture |
| Developer Tools | Japanese, Chinese Simplified, Korean | Large developer populations |

#### Factors to Evaluate

For each potential language/market, assess:

| Factor | Questions to Ask |
|--------|-----------------|
| Market size | How many potential users in this language? |
| Willingness to pay | Do users in this market pay for apps or expect free? |
| Competition level | How many localized competitors exist? Less = more opportunity |
| Localization cost | How expensive is professional translation for this language? |
| Cultural distance | How much adaptation beyond translation is needed? |
| Support burden | Can you handle support inquiries in this language? |
| App Store presence | Is the App Store well-established in this market? |

Use AskUserQuestion to gather the user's app category, current markets, and budget constraints before making recommendations.

### Phase 2: Language Tier Recommendations

#### Tier 1 — Highest ROI (Localize First)

| Language | Key Market | Estimated Revenue Lift |
|----------|-----------|----------------------|
| Japanese (ja) | Japan | +15-30% (high per-user value) |
| Chinese Simplified (zh-Hans) | China, Singapore | +10-25% (massive volume) |
| German (de) | Germany, Austria, Switzerland | +8-15% (high per-user spend) |
| French (fr) | France, Canada, Belgium, Africa | +8-15% (wide geographic reach) |
| Korean (ko) | South Korea | +5-12% (tech-savvy, high spend) |

**Recommendation:** Localize into 2-3 Tier 1 languages first. Expected combined revenue lift: 20-50%.

#### Tier 2 — Good ROI (Localize Second)

| Language | Key Market | Estimated Revenue Lift |
|----------|-----------|----------------------|
| Spanish (es) | Spain, Latin America, US Hispanic | +5-10% |
| Portuguese (pt-BR) | Brazil | +4-8% |
| Italian (it) | Italy | +3-6% |
| Dutch (nl) | Netherlands, Belgium | +2-4% |
| Russian (ru) | Russia, CIS countries | +3-6% |

**Recommendation:** Add Tier 2 after Tier 1 languages prove ROI. Expected per-language lift: 3-8%.

#### Tier 3 — Volume Play (Localize for Scale)

| Language | Key Market | Notes |
|----------|-----------|-------|
| Arabic (ar) | Middle East, North Africa | RTL support required — higher dev cost |
| Turkish (tr) | Turkey | Growing mobile market |
| Hindi (hi) | India | Massive volume, very low per-user spend |
| Thai (th) | Thailand | Mobile-first market |
| Vietnamese (vi) | Vietnam | Fast-growing app market |
| Polish (pl) | Poland | Central European hub |

**Recommendation:** Tier 3 is for apps that already have strong Tier 1 and Tier 2 performance and want maximum global reach.

### Phase 3: Minimum Viable Localization Levels

Not every language needs full localization on day one. Start small, measure, then invest.

#### Level 0: Metadata-Only

**What you localize:**
- App Store title and subtitle
- App Store description
- App Store keywords
- Screenshots (text overlays and captions)
- Promotional text

**What stays in English:**
- All in-app UI
- Help/support content
- Push notification text

**Cost:** $100-300 per language (professional translation of ~500 words)
**Effort:** 1-2 days per language
**Best for:** Testing whether a market responds before investing further

**Why this works:** Users search the App Store in their language. Localized metadata means your app appears in local searches. Many users worldwide are comfortable with English UI but discover apps through local search terms.

#### Level 1: Metadata + UI Strings

**What you localize:**
- Everything in Level 0
- All user-facing strings (Xcode String Catalogs export)
- Date/time/number format adaptation
- System alerts and error messages

**What stays in English:**
- In-app content (help articles, onboarding guides)
- Marketing materials
- Support communication

**Cost:** $500-3,000 per language (depending on string count)
**Effort:** 1-2 weeks per language (including QA)
**Best for:** Languages that showed strong Level 0 results

#### Level 2: Full Localization

**What you localize:**
- Everything in Level 1
- In-app content (onboarding, tutorials, help text)
- Marketing website and materials
- Customer support in-language
- Legal documents (privacy policy, terms of service)
- Push notifications and emails

**Cost:** $3,000-10,000+ per language
**Effort:** 3-6 weeks per language
**Best for:** Top 1-2 markets by revenue, when the language represents >15% of revenue

#### Recommended Approach

```
Step 1: Ship Level 0 for 2-3 Tier 1 languages
Step 2: Measure downloads and revenue lift per language (4-6 weeks)
Step 3: Invest in Level 1 for languages that showed >5% download lift
Step 4: Invest in Level 2 only for markets generating >15% of total revenue
```

This approach limits risk. If Japanese Level 0 doesn't move the needle, you saved yourself $2,000+ in translation costs.

### Phase 4: Translation Workflow

#### Xcode String Catalogs

Starting with Xcode 15, String Catalogs (.xcstrings) are the standard localization format.

**Export workflow:**
1. Ensure all user-facing strings use `String(localized:)` or `LocalizedStringResource`
2. Build the project — Xcode auto-discovers strings
3. Open the `.xcstrings` file to see all strings with translation status
4. Export: Product > Export Localizations (creates .xcloc bundles)
5. Send .xcloc files to translators
6. Import: Product > Import Localizations

**String Catalog best practices:**
- Add comments to strings that need context (e.g., "Title of settings screen" or "Button label, max 15 characters")
- Use string interpolation with proper grammar agreement (Foundation's automatic grammar support)
- Mark strings that should NOT be translated (e.g., brand names) with "Don't Translate"
- Review the "Stale" state — it flags strings whose source changed after translation

#### Translation Service Options

| Service Type | Cost per Word | Quality | Turnaround | Best For |
|-------------|---------------|---------|------------|----------|
| Professional agency | $0.08-0.15 | High | 1-2 weeks | Level 1-2, critical apps |
| Freelance translators | $0.05-0.12 | Variable | 3-7 days | Level 1, budget-conscious |
| AI + human review | $0.03-0.06 | Good | 1-3 days | Level 0-1, fast iteration |
| Community/crowdsource | Free-$0.03 | Variable | Unpredictable | Open source, community apps |

**AI + human review workflow (recommended for indie devs):**
1. Export strings from Xcode
2. Run through high-quality AI translation (provide app context and glossary)
3. Native speaker reviews and corrects (1-2 hours for 500 strings)
4. Import back into Xcode
5. Test in-context (some translations don't work in UI context)

#### Cost Estimates by App Size

| App Size | String Count | Level 0 Cost/Language | Level 1 Cost/Language | Level 2 Cost/Language |
|----------|-------------|----------------------|----------------------|----------------------|
| Small (utility) | 100-500 strings | $100-200 | $500-1,000 | $2,000-4,000 |
| Medium (productivity) | 500-2,000 strings | $200-400 | $1,000-3,000 | $4,000-8,000 |
| Large (complex app) | 2,000-5,000+ strings | $300-600 | $2,500-6,000 | $8,000-15,000 |

**Budget planning:** For a medium app localizing into 3 Tier 1 languages at Level 1: ~$3,000-9,000 total.

#### Review Process

Native speaker review is mandatory — never ship translations without it.

**Review checklist per language:**
- [ ] Grammar and spelling correct
- [ ] Tone matches the app's voice (casual, professional, playful)
- [ ] Technical terms translated consistently (use a glossary)
- [ ] No literal translations that sound unnatural
- [ ] String length fits UI constraints (check for truncation)
- [ ] Culturally appropriate (no unintended meanings)
- [ ] Placeholder variables render correctly (%@, %d, etc.)

### Phase 5: Cultural Adaptation Beyond Translation

Translation is necessary but not sufficient. Cultural adaptation catches issues that literal translation misses.

#### Date, Time, and Number Formats

**Rule:** Always use Foundation formatters. Never hardcode format strings.

```swift
// CORRECT - adapts to locale automatically
let formatter = Date.FormatStyle()
    .year().month().day()
Text(date.formatted(formatter))

// CORRECT - number formatting
Text(price.formatted(.currency(code: "JPY")))

// WRONG - hardcoded US format
Text(String(format: "%m/%d/%Y", date))
```

| Format | US | Germany | Japan |
|--------|-----|---------|-------|
| Date | 02/27/2026 | 27.02.2026 | 2026/02/27 |
| Time | 2:30 PM | 14:30 | 14:30 |
| Number | 1,234.56 | 1.234,56 | 1,234.56 |
| Currency | $9.99 | 9,99 EUR | 1,500 JPY |

#### Currency Display

- Always use the user's locale for display, even if your product is priced in USD
- App Store handles currency conversion for IAP — but display in marketing materials should match locale
- Some markets are sensitive to seeing foreign currencies (Japan especially)

#### Color Meanings

| Color | Western Meaning | East Asian Meaning | Middle Eastern |
|-------|----------------|-------------------|----------------|
| Red | Danger, error, stop | Luck, prosperity, celebration | Danger (similar to Western) |
| White | Purity, clean | Mourning, death (in some contexts) | Purity, peace |
| Green | Success, go, nature | Nature, health | Islam, paradise, nature |
| Yellow | Caution, warning | Royalty, courage (China) | Happiness, prosperity |

**Recommendation:** Use semantic system colors (`Color.red` for errors) and let the system handle meaning. Avoid using color as the ONLY way to convey information (accessibility requirement too).

#### Layout Direction

Right-to-left (RTL) languages require layout mirroring:

**RTL languages:** Arabic, Hebrew, Urdu, Persian

**What to mirror:**
- Navigation direction (back button on right)
- Text alignment (leading becomes trailing)
- Horizontal scroll direction
- Progress indicators (fill from right)
- Icons with directional meaning (arrows)

**What NOT to mirror:**
- Media playback controls (play, pause, skip)
- Phone number input
- Clocks and timers
- Brand logos

**SwiftUI RTL support:**
- Use `.leading` and `.trailing` instead of `.left` and `.right`
- Use `@Environment(\.layoutDirection)` for conditional layout
- Test with: Edit Scheme > Run > Options > Application Language > Right to Left Pseudolanguage

#### Image and Icon Localization

Some images need localization:
- Screenshots showing text (localize the text)
- Icons with text or cultural symbols
- Hand gesture icons (thumbs up, OK sign differ by culture)
- Body language icons (eye contact norms differ)

### Phase 6: Localized App Store Optimization (ASO)

#### Why Localized ASO Matters

- Localized App Store metadata increases conversion rate 30-80% in non-English markets
- Users search in their native language, even if they can use English apps
- App Store search algorithms weight localized keywords for each storefront
- Localized screenshots dramatically improve first impressions

#### Keyword Research by Market

**Critical:** Do NOT just translate your English keywords. Keyword search behavior differs dramatically by market.

| Market | Keyword Behavior |
|--------|-----------------|
| Japan | Users search with specific, descriptive terms; katakana for foreign concepts |
| Germany | Users prefer German terms over English loanwords for productivity apps |
| France | Strong preference for French terms; English terms for tech-specific concepts |
| Korea | Mix of Korean and English; English terms common in tech context |
| Brazil | Portuguese terms preferred; English for tech/gaming terms |
| China | Exclusively Chinese terms; English keywords rarely used |

**Localized keyword research process:**
1. Translate your top 10 English keywords as a starting point
2. Use WebSearch to find what local users actually search for: `"[category] app" site:[country-domain]`
3. Check local competitors' keywords (what terms do their listings target?)
4. Ask a native speaker: "How would you search for an app that does [X]?"
5. Test different keyword sets per locale and measure impressions

#### Localized Screenshots

Screenshots are the most impactful localization investment after metadata.

**What to localize in screenshots:**
- Overlay text and captions (translate and adapt, don't just translate)
- App content shown in screenshots (use locale-appropriate sample data)
- Feature callouts (highlight features that matter most in that market)
- Device frames (use devices popular in that market if relevant)

**What to keep consistent:**
- Overall visual style and branding
- Screenshot order (unless market research suggests different feature priority)
- App icon

**Cost-effective approach:** Create screenshot templates with text layers. Swapping text is fast and cheap compared to redesigning screenshots per locale.

#### Competitor Analysis by Storefront

Use WebSearch to research competitors in each target storefront:
- Which apps rank for your keywords in Japan vs. Germany vs. Brazil?
- Are local competitors absent from some markets? (opportunity)
- What pricing do competitors use in each market?
- What App Store categories are they listed under? (may differ by market)

### Phase 7: Testing Localized Builds

#### Xcode Preview with Locale Override

Test UI in different locales without changing device settings:

```swift
#Preview {
    ContentView()
        .environment(\.locale, Locale(identifier: "ja"))
}

#Preview {
    ContentView()
        .environment(\.locale, Locale(identifier: "de"))
}

#Preview {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
}
```

#### Pseudo-Localization

Catch localization bugs before real translations arrive:

**Accented English:** Replaces characters with accented versions (e.g., "Settings" becomes "[Seeetttiiiinnggss]"). Helps catch:
- Hardcoded strings that bypass localization
- Character encoding issues

**Double-length strings:** Doubles every string. Helps catch:
- Truncation in fixed-width UI elements
- Layout overflow
- Buttons that can't grow

**Right-to-Left:** Mirrors layout. Helps catch:
- Hardcoded `.left` / `.right` instead of `.leading` / `.trailing`
- Icons that need mirroring
- Layout assumptions

**Enable in Xcode:** Edit Scheme > Run > Options > Application Language > choose pseudo-language.

#### String Length Testing

Translation length varies significantly by language:

| Language | Length vs. English |
|----------|-------------------|
| German | +25-35% longer |
| French | +15-25% longer |
| Spanish | +15-25% longer |
| Italian | +15-20% longer |
| Japanese | 0-20% shorter (but may need more vertical space) |
| Chinese | 30-50% shorter (characters are information-dense) |
| Korean | 0-15% shorter |
| Arabic | +20-25% longer |

**Implication:** If your English UI barely fits, German will definitely overflow. Design with 30% padding for text elements, or use dynamic type sizing.

#### Screenshot Testing Across Locales

Automate localized screenshot capture:
1. Use Xcode UI tests with `XCUIApplication().launchArguments` to set locale
2. Capture screenshots in each supported locale
3. Review for truncation, layout breaks, and placeholder leaks (%@ visible in UI)
4. Verify sample data matches locale expectations

#### Localization QA Checklist

Run this for every supported language before release:

- [ ] All strings translated (no English fallbacks visible)
- [ ] No truncated text in any screen
- [ ] Date/time/number formats correct for locale
- [ ] Currency displays correctly
- [ ] Pluralization rules work (many languages have complex plural forms)
- [ ] RTL layout correct (if applicable)
- [ ] Images with text localized
- [ ] App Store metadata reviewed by native speaker
- [ ] Screenshots localized and accurate
- [ ] Dynamic Type works with translated strings
- [ ] VoiceOver reads localized strings correctly

## Output Format

Present the localization roadmap as:

```markdown
# Localization Roadmap: [App Name]

## Current State
- **Supported languages**: [List]
- **App size**: [Small/Medium/Large] ([N] strings)
- **App category**: [Category]

## Market Prioritization

### Recommended Languages (Priority Order)

| Priority | Language | Tier | Level | Est. Revenue Lift | Est. Cost | Timeline |
|----------|----------|------|-------|-------------------|-----------|----------|
| 1 | [Language] | Tier 1 | Level [0/1] | +X-Y% | $X-Y | [N weeks] |
| 2 | [Language] | Tier 1 | Level [0/1] | +X-Y% | $X-Y | [N weeks] |
| 3 | [Language] | Tier [1/2] | Level [0/1] | +X-Y% | $X-Y | [N weeks] |

### Total Budget Estimate
- **Phase 1** (Tier 1 languages): $X-Y
- **Phase 2** (Tier 2 languages): $X-Y
- **Total**: $X-Y

## Translation Workflow
1. [Export method]
2. [Translation service]
3. [Review process]
4. [Import and QA]

## Localized ASO Plan
- **Keywords**: [Research approach per market]
- **Screenshots**: [Localization approach]
- **Description**: [Translation + adaptation approach]

## Cultural Adaptations Required
- [Adaptation 1]
- [Adaptation 2]

## Testing Plan
- [ ] Pseudo-localization pass
- [ ] Native speaker review per language
- [ ] Screenshot testing per locale
- [ ] RTL testing (if applicable)
- [ ] String length / truncation audit

## Timeline

| Phase | Duration | Languages | Level | Milestone |
|-------|----------|-----------|-------|-----------|
| 1 | Weeks 1-2 | [Languages] | Level 0 | Metadata live, measure downloads |
| 2 | Weeks 3-6 | [Languages] | Level 1 | Full UI localized for top performers |
| 3 | Weeks 7-10 | [Languages] | Level 0 | Tier 2 metadata test |
| 4 | Ongoing | [As needed] | Level 1-2 | Expand based on data |

## Success Metrics
- Downloads per locale (before vs. after localization)
- Conversion rate per storefront
- Revenue per locale
- Review ratings per locale (watch for localization complaints)

## Next Steps
1. [First action item]
2. [Second action item]
3. [Third action item]
```

## Integration with Other Skills

This skill connects to the broader product development pipeline:

```
1. product-agent discover     --> Validate idea
2. market-research            --> Identify global opportunity
3. competitive-analysis       --> Check competition per market
4. localization-strategy      --> THIS SKILL
   (THIS SKILL)
5. app-store                  --> Localized App Store listing
6. monetization               --> Regional pricing strategy
```

**Inputs from other skills:**
- `market-research` provides TAM/SAM/SOM data that helps prioritize markets
- `competitive-analysis` reveals which markets have fewer localized competitors
- `monetization` informs regional pricing (App Store price tier selection)

**Outputs to other skills:**
- Prioritized language list feeds into `app-store` for localized metadata
- Regional competitor data informs `competitive-analysis` per market
- Revenue projections per market feed into `monetization` strategy

## Common Mistakes to Avoid

### Translating keywords literally
```
Bad:  English keyword "to-do list" translated literally to Japanese
Good: Research what Japanese users actually search for (Japanese users often
      search for the concept differently than a literal translation)
```

### Hardcoding date/number formats
```
Bad:  String(format: "%m/%d/%Y", date)
Good: date.formatted(.dateTime.year().month().day())
```

### Ignoring string length differences
```
Bad:  Fixed-width button that fits "Save" but not "Speichern" (German)
Good: Flexible layout that adapts to any string length
```

### Localizing everything at once
```
Bad:  Translate into 15 languages at Level 2 before validating demand
Good: Level 0 for 3 languages, measure for 4 weeks, then invest in winners
```

### Skipping native speaker review
```
Bad:  Ship AI-translated strings without human review
Good: Every translation reviewed by a native speaker in-context
```

### Using left/right instead of leading/trailing
```
Bad:  .frame(alignment: .left)
Good: .frame(alignment: .leading)
```

---

**Localization is not translation — it's making your app feel native in every market. Start with metadata, prove demand with data, then invest in full localization where the numbers justify it.**
