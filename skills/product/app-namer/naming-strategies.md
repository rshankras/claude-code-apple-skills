# Naming Strategies & App Store Display Mechanics

Reference for the `app-namer` skill: the three archetypes, generation techniques, and the App Store rules that constrain every name.

## The Three Archetypes

Every app name sits on a spectrum from "pure brand" to "pure description." Pick the mix deliberately.

### 1. Branded / Invented

A coined word with no inherent meaning. You build the meaning through the product.

**Examples:** Spotify, Halide, Bevel, Bear, Things, Fantastical, Tot, Bumpr, Reeder

| Pros | Cons |
|------|------|
| Fully ownable and trademarkable | Zero keyword value on its own |
| App Store name almost always available | Requires marketing to build meaning |
| Distinctive, no competitor confusion | Slower organic discovery early on |
| Room to expand scope later | Harder to "get" at a glance |

**Best when:** the app is a long-term brand, the category is crowded with descriptive names, or personality matters more than instant clarity.

### 2. Descriptive

The name says what the app does.

**Examples:** Sleep Cycle, PDF Expert, Pocket Casts, Weather Line, Just Press Record, Day One

| Pros | Cons |
|------|------|
| Instant clarity — no explanation needed | Hard or impossible to trademark |
| Carries a real ASO keyword in the name | Generic, blends into the category |
| Lower marketing burden | Exact name usually already taken |
| | Boxes you in if scope grows |

**Best when:** single-purpose utility, ASO-driven discovery is the whole strategy, and you don't need brand defensibility.

### 3. Hybrid / Suggestive (usually the winner)

A real or twisted word that *evokes* the benefit without literally describing it.

**Examples:** Streaks, Overcast, Carrot Weather, Drafts, Craft, Bumpr, Flighty, Dark Noise, Mela

| Pros | Cons |
|------|------|
| Ownable *and* evocative | Needs a subtitle/tagline to fully land |
| Usually trademarkable | Moderate (not instant) clarity |
| Memorable, distinctive | |
| Room to grow beyond v1 | |

**Best when:** almost always, for indie App Store apps. The hybrid name carries the brand; the **subtitle carries the descriptive keywords**. `Flighty — Live Flight Tracker`, `Mela — Recipe Manager`, `Streaks — Habit Tracker`.

### Default Recommendation

For a typical indie app, lead with a **hybrid name + descriptive subtitle**. You get the ownability of a brand and the discoverability of a descriptor, split across the two 30-char fields that Apple indexes.

## Generation Techniques

Use these to produce raw candidates. Mix techniques across archetypes.

| Technique | How | Examples |
|-----------|-----|----------|
| **Real word, repurposed** | Take an everyday word that evokes the feeling | Bear, Craft, Tide, Halide, Overcast |
| **Compound** | Fuse two short words | Pocket Casts, Dark Noise, Day One |
| **Portmanteau** | Blend two words into one | Instagram (instant+telegram), Pinterest |
| **Prefix / suffix** | Add -ly, -ify, -kit, -io, get-, try- | Calmly, Notify, get-, Flighty |
| **Dropped vowels / respelling** | Tweak spelling for ownability (use with care — radio-test it) | Flickr, Tumblr, Lyft |
| **Metaphor** | Name the concept the app stands for | Carrot (snark), Streaks, Anchor |
| **Foreign word** | A fitting word from another language | Mela (apple, Italian), Bevel |
| **Person / character** | A name that gives the app a persona | Carrot, Hazel, Bear |
| **Short + punchy** | One syllable, 3-5 letters, maximum ownability | Sip, Tot, Bear, Tide, Brim |

## App Store Display Mechanics (Hard Constraints)

These are non-negotiable platform rules. Every candidate must respect them.

### The 30-Character Name Limit

- The **App Name is capped at 30 characters** and is both the displayed name *and* the single highest-weighted ASO ranking field.
- The **Subtitle is a separate 30-character field**, also indexed, shown directly under the name.
- Apple indexes words from the name **and** subtitle (and the 100-char keyword field). See `app-store/keyword-optimizer` for full allocation and cross-field deduplication.

### Home-Screen Truncation (the missed one)

Under the icon on the Home Screen, iOS shows only about **11-12 characters** before truncating with an ellipsis (it's proportional width, not a hard count — wide letters truncate sooner).

```
✅ "Fantastical" (11)  → shows fully
✅ "Halide" (6)        → shows fully
⚠️ "Carrot Weather"   → shows "Carrot Weat…" (the brand word still reads)
❌ "Productivity Pro"  → shows "Productivit…" (useless)
```

**Rule:** the standalone part of the name — everything *before* a `—` or `:` separator — should read cleanly when truncated to ~12 characters. This is why short brand words win: `Bear`, `Things`, `Drafts` need no truncation at all.

**On macOS this rule relaxes.** A Mac app's name lives in the menu bar (usually an icon, no text), Launchpad, the Applications folder, the Dock tooltip, and the Mac App Store — there's no Home-Screen icon with iOS's tight ~12-character cutoff. Launchpad and Finder truncate, but far more generously. So for a Mac app, treat length as a soft preference (short still wins for memorability), not a hard limit — don't reject an otherwise strong 8-14 character name on truncation grounds alone.

### What the Name May NOT Contain

Apple rejects or forces changes for:
- ❌ Another app's name or a trademark you don't own
- ❌ Prices or pricing terms ("Free", "$2.99")
- ❌ "for iPhone", "for iPad", "for Apple Watch", or platform names
- ❌ "best", "#1", or unverifiable superlatives
- ❌ Emoji or decorative special characters
- ❌ Misleading terms (functionality the app doesn't have)

### Bundle ID Implications

The bundle identifier (reverse-DNS, e.g. `com.yourcompany.brim`) is **permanent** and set once. It's independent of the display name, but a clean name yields a clean bundle ID, product name, and Xcode scheme.

- ✅ "Brim" → `com.company.brim` (clean)
- ⚠️ "Carrot Weather" → `com.company.carrotweather` (fine, just longer)
- ❌ "My App!! 2.0" → forces an awkward sanitized identifier

Quick check: lowercase the name, strip spaces and punctuation — does it still look like a clean identifier?

## The Radio Test, Siri Test, and Confusability

Three quick gut-checks every finalist must pass:

1. **Radio test** — say the name out loud once. Can someone spell it correctly without seeing it? (`Flickr` fails; `Bear` passes.)
2. **Siri test** — "Hey Siri, open ___." Is it pronounceable and distinct enough that a voice assistant won't mishear it? Avoid names that collide with common words or other app names.
3. **Confusability** — is it one letter or one sound away from a major app (Notes, Notion, Things, Bear, Halide)? If users could type a competitor's name by mistake, drop it.

## Good vs. Bad Naming Patterns

#### ✅ Good

```
Streaks — Habit Tracker
  Hybrid brand (evocative, ownable, short), descriptive keyword in subtitle,
  no truncation, trademarkable, Siri-safe.

Flighty — Live Flight Tracker
  Invented-ish brand with personality, subtitle owns "flight tracker",
  clean bundle ID (com.x.flighty).
```

#### ❌ Bad

```
Best Habit Tracker Pro 2026
  "Best" is puffery (rejection risk), no brand, truncates to "Best Habit…",
  un-trademarkable, blends into 500 identical names.

Habitz
  Cute respelling fails the radio test (users type "Habits"),
  hands the traffic to the correctly-spelled competitor.
```

#### Why it matters

The name is the most permanent, highest-leverage decision in the app's marketing. It's the #1 ASO field, the Home-Screen label, the brand you'll say on podcasts, and the bundle ID you can never change. A name that's ownable, spellable, and short pays compounding dividends; a clever-but-unspellable one leaks every install to a competitor.
