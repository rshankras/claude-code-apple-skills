---
name: app-namer
description: Turn an app idea into validated, App-Store-ready name candidates. Use when the user says "name my app", "what should I call it", "app name ideas", "help me name this app", "is this name available", or needs to pick a brandable, ownable name before reserving it in App Store Connect.
allowed-tools: [Read, Write, WebSearch, WebFetch, AskUserQuestion]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# App Namer Skill

Takes an app idea or one-liner and produces a ranked shortlist of 5-8 **validated** name candidates — not random brainstorming. Each candidate is generated from a naming archetype, paired with a subtitle, checked against App Store display rules, and run through an availability gauntlet (App Store Connect name, trademark, domain, handle) before it's recommended.

The output is a name you can reserve in App Store Connect today, with the keyword work already aligned to feed the `app-store/keyword-optimizer` skill.

## When This Skill Activates

Use this skill when the user:
- Has an app idea but no name ("what should I call it?")
- Wants name ideas or a naming brainstorm for a specific app
- Needs to know if a name is available / safe to use
- Is about to create the app record in App Store Connect and needs to reserve a name
- Wants to rename an existing app and needs ownable, ASO-smart options
- Picked an idea from `idea-generator` and needs the name before writing the PRD

**No app idea yet?** Run `product/idea-generator` first, then come back with the chosen idea.

**Already have a locked name and just want ASO?** Skip this skill — go to `app-store/keyword-optimizer`.

## Reference Files

Before generating names, load both reference files:

| File | Purpose |
|------|---------|
| **naming-strategies.md** | The 3 archetypes, naming techniques, App Store display mechanics (30-char limit, home-screen truncation, name/subtitle interplay), good/bad examples |
| **validation-checklist.md** | The knockout gauntlet — App Store Connect name availability, trademark sanity check, domain/.app, social handles, linguistic safety |

## What This Skill Does

```
Idea/positioning
   ↓  elicit
Naming brief (what it does, who it's for, personality, scope ceiling)
   ↓  generate across archetypes
20-40 raw candidates (branded / descriptive / hybrid)
   ↓  filter (pronounce, spell, truncate, confusability)
8-12 survivors
   ↓  pair with subtitle + score
Ranked candidates with name + subtitle + display preview
   ↓  validate (ASC name / trademark / domain / handle)
5-8 validated candidates
   ↓
Recommendation + "reserve now" action
```

## The Naming Process

### Step 1: Build the Naming Brief

If the user hasn't given enough context, gather it with AskUserQuestion. You need:

| Field | Why it matters |
|-------|----------------|
| **One-liner** | What the app does in one sentence — drives descriptive/hybrid candidates |
| **Target user** | Tone calibration (pro tool vs. playful consumer app) |
| **Personality** | Serious, playful, minimal, premium, technical? Sets the archetype mix |
| **Category** | App Store category — affects trademark class and competitor naming norms |
| **Scope ceiling** | Will it stay single-purpose or grow? A too-descriptive name boxes you in |
| **Existing brand** | Company/developer name, existing app family to stay consistent with |

If the user gives a one-liner and nothing else, infer sensible defaults, **state your assumptions**, and proceed — don't block on a full questionnaire.

### Step 2: Generate Across Archetypes

Generate 20-40 raw candidates spread across the three archetypes (see **naming-strategies.md** for each technique and examples):

1. **Branded / invented** — coined, ownable, zero literal meaning (Spotify, Halide, Bevel, Bear)
2. **Descriptive** — says what it does, carries a keyword (Sleep Cycle, PDF Expert, Pocket Casts)
3. **Hybrid / suggestive** — a real or twisted word that evokes the benefit (Streaks, Overcast, Carrot Weather, Drafts)

Aim for roughly **40% hybrid, 30% branded, 30% descriptive** for a typical indie app — hybrid names tend to win because they're ownable *and* memorable, with the descriptive keyword pushed into the subtitle.

Use the techniques in **naming-strategies.md**: real words, compounds, portmanteaus, prefix/suffix, dropped vowels, foreign words, metaphors.

### Step 3: Filter Hard and Fast

Kill any candidate that fails a basic filter before spending effort scoring it:

- ❌ Can't be pronounced correctly on first read
- ❌ Can't be spelled correctly after hearing it once (the "radio test")
- ❌ (iOS) Doesn't read cleanly when truncated to ~12 characters on the Home Screen — relaxes for Mac apps (see naming-strategies.md)
- ❌ Confusable with a major existing app (Notes, Notion, Things, etc.)
- ❌ Purely generic/descriptive with no distinctiveness (un-trademarkable)
- ❌ Produces an ugly bundle ID or has awkward casing

Target 8-12 survivors going into scoring.

### Step 4: Pair With a Subtitle

For each survivor, write the `Name — Subtitle` pairing the way it appears on the App Store. This is where the ASO strategy lives:

```
[Brand Name] — [Descriptive keyword phrase]

Halide — Pro Camera
Streaks — Habit Tracker
Bear — Markdown Notes
```

The **name** carries the brand; the **subtitle** carries the searchable keywords. This means a branded/hybrid name doesn't need to be descriptive — the subtitle does that job. Both are 30-char fields and both are indexed. (See `app-store/keyword-optimizer` for full keyword allocation.)

### Step 5: Score Each Candidate

Score each candidate 1-10 on six dimensions:

| Dimension | WEAK (1-3) | STRONG (4-7) | EXCELLENT (8-10) |
|-----------|------------|--------------|------------------|
| **Memorability** | Forgettable, generic | Distinctive | Sticky, instantly recalled |
| **Clarity/Fit** | Misleading or opaque | Evokes the benefit (with subtitle) | Name+subtitle = instant understanding |
| **Availability** | Name & domain taken, TM conflict | Domain workaround, name free | Name + .com/.app + clean TM headroom |
| **ASO Value** | Dead keyword-wise | Subtitle carries keywords | Brandable + subtitle owns a keyword |
| **Pronounce/Spell** | Fails radio test | Minor ambiguity | Say it once, spell it right, Siri-safe |
| **Scalability** | Boxed into v1 scope | Some room | Grows with the product |

**Overall = weighted average**, with **Availability and Memorability weighted 1.5×** (an unavailable name scores zero regardless of how clever it is).

### Step 6: Validate the Top Candidates

Run the top 5-8 through the gauntlet in **validation-checklist.md**. For each, record status as `available` / `taken` / `conflict` / `unchecked`:

1. **App Store name** — exact-name search on the App Store; reserve in App Store Connect if clear
2. **Trademark knockout** — USPTO/EUIPO + web search in the software class (not legal clearance)
3. **Domain** — `.com`, then `.app`, then `get-/try-/use-` prefixes
4. **Social handle** — consistent handle across X / Instagram (nice-to-have)
5. **Linguistic safety** — no bad meanings in top ASO markets, Siri-pronounceable

Use WebSearch/WebFetch to check what's checkable (existing App Store apps, trademark databases, domain registrars). For anything you can't verify, mark it `unchecked` and tell the user exactly how to check — **never report a name as available if you didn't verify it.**

### Step 7: Recommend and Reserve

Present the ranked shortlist, then make a single clear recommendation. End with the action: **reserve the winning name in App Store Connect now** — App Store names are unique and first-come, so a name that's available today can be gone tomorrow.

## Output Structure

```json
{
  "naming_brief": {
    "one_liner": "On-device app that turns leftover ingredients into recipe suggestions",
    "target_user": "Home cooks who want to reduce food waste",
    "personality": "warm, simple, a little playful",
    "category": "Food & Drink",
    "scope_ceiling": "could expand to meal planning and grocery lists",
    "assumptions": ["No existing brand to match", "iOS-first, US market primary"]
  },
  "shortlist": [
    {
      "rank": 1,
      "name": "Larder",
      "archetype": "hybrid",
      "name_subtitle": "Larder — Recipes From Leftovers",
      "char_counts": { "name": 6, "subtitle": 30 },
      "home_screen_preview": "Larder",
      "rationale": "Evokes the source (what's in your larder) without being literal about recipes; warm, short, and far more ownable than the generic 'Pantry'; subtitle carries the 'recipes' + 'leftovers' keywords.",
      "scores": {
        "memorability": 8,
        "clarity_fit": 8,
        "availability": 9,
        "aso_value": 8,
        "pronounce_spell": 9,
        "scalability": 9
      },
      "overall_score": 8.4,
      "validation": {
        "app_store_name": "no live 'Larder' recipe app found — verify in ASC New App and reserve",
        "trademark": "unchecked — run USPTO TESS for 'Larder' in Class 9/42 before committing",
        "domain": "larder.com taken; larder.app available — recommended buy",
        "handle": "@larder taken; @larderapp available",
        "linguistic": "clean in EN/ES/DE/JA; Siri-safe"
      },
      "risks": "Slightly less self-explanatory than 'Pantry' on its own — the subtitle does the clarifying. Confirm the trademark knockout before reserving."
    }
  ],
  "filtered_out": [
    { "name": "Pantry", "reason": "Too generic to own — App Store name and pantry.com almost certainly taken, un-trademarkable" },
    { "name": "LeftoverChef", "reason": "Two-word compound truncates badly on Home Screen; 'Chef' is crowded and trademark-risky" },
    { "name": "Fridgify", "reason": "Cute but fails the radio test — users will spell it 'Fridgefy'/'Fridgi'" }
  ],
  "recommendation": "Lead with Rank 1 if a clean App Store variant clears reservation; otherwise Rank 2. Reserve the winner in App Store Connect immediately, then run app-store/keyword-optimizer to lock the subtitle and keyword field.",
  "next_step": "Reserve the name in App Store Connect → run keyword-optimizer for subtitle + 100-char keywords → feed the name into prd-generator"
}
```

## End-to-End Example

**Brief:** "A minimalist iOS app that tracks daily water intake with a single tap. For health-conscious people who find existing trackers cluttered. Personality: clean, calm, premium. Stays single-purpose."

**Generate (sample of ~30):**
- *Branded:* Drift, Sip, Wello, Aqo, Nim
- *Descriptive:* Water Daily, Hydrate, Daily Water, Intake
- *Hybrid:* Gulp, Tide, Droplet, Wave, Brim, Flow

**Filter:** Drop "Intake" (generic, taken), "Hydrate" (crowded, hard to own), "Aqo" (fails spell test).

**Pair + score top survivors:**

| Name | Pairing | Memorable | Avail. | ASO | Overall |
|------|---------|-----------|--------|-----|---------|
| Brim | Brim — Water Tracker | 8 | 7 | 7 | 7.6 |
| Sip | Sip — Daily Water | 9 | 5 | 7 | 7.2 |
| Droplet | Droplet — Hydration | 7 | 6 | 8 | 7.0 |

**Validate (top 3):** "Sip" — App Store name almost certainly taken (very common), sip.com taken. "Brim" — exact App Store name worth checking, brim.app likely available, no obvious TM conflict in Class 9. "Droplet" — used by DigitalOcean (TM risk in software).

**Recommendation:** "Go with **Brim — Water Tracker**. It's short (stands alone on the Home Screen), calm and ownable, almost certainly clears the App Store name, and `brim.app` is available. Avoid Droplet (DigitalOcean trademark in software). Reserve 'Brim' in App Store Connect now, then run keyword-optimizer to fill the subtitle and keyword field around 'water, hydration, drink, reminder.'"

## Integration With Other Skills

```
product/idea-generator        → pick an idea
        ↓
product/app-namer (THIS SKILL) → name it + reserve it
        ↓
app-store/keyword-optimizer    → lock subtitle + 100-char keywords around the name
        ↓
product/prd-generator          → [App Name] is now filled in
        ↓
generators/app-icon-generator  → icon that matches the name's personality
```

The name you pick here is the highest-weighted ASO field and a permanent brand decision — it flows into the keyword strategy, the PRD, the icon, and the bundle ID. Get it right before you build.

## When NOT to Use This Skill

- **No idea yet** — run `idea-generator` first
- **Name is already locked** — go to `keyword-optimizer` for ASO
- **You need the legal clearance** — this skill does a *knockout* search, not trademark clearance; consult an attorney before filing
- **Renaming a high-traffic live app** — renaming resets branded search equity; see `keyword-optimizer/existing-app-strategy.md` before changing a name that's working

## Deliverables

At the end of this skill you should have:

- [ ] Naming brief captured (one-liner, user, personality, category, scope, assumptions)
- [ ] Candidates generated across all three archetypes
- [ ] Filtered down with reasons (pronounce/spell/truncate/confusability)
- [ ] Each finalist paired as `Name — Subtitle` with char counts ≤ 30
- [ ] Home-screen truncation preview for each
- [ ] Scored on all six dimensions, ranked by weighted overall
- [ ] Top candidates run through the validation gauntlet with status flags
- [ ] One clear recommendation + the "reserve in App Store Connect now" action
- [ ] `next_step` pointing to keyword-optimizer and prd-generator

## Output File Location

Save results to `app-name-shortlist.json` (project root), using the Output Structure above.

---

**Generate wide, filter hard, validate before you fall in love.** The best app name is short, ownable, spellable, available today, and lets the subtitle do the keyword work.
