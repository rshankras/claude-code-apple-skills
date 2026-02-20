---
name: idea-generator
description: Brainstorm and rank iOS/macOS app ideas tailored to developer skills. Use when user says "what should I build", "give me app ideas", "I don't know what to build", "brainstorm app ideas", or "help me find an app idea".
allowed-tools: [Read, Write, WebSearch, WebFetch, AskUserQuestion]
---

# Idea Generator Skill

Generates a ranked shortlist of 3-5 app ideas tailored to the developer's skills, interests, and constraints. Output is formatted to feed directly into `product-agent discover` for validation.

## When to Use This Skill

Use this skill when the user:
- Doesn't have an app idea yet
- Says "what should I build?" or "I don't know what to build"
- Wants to brainstorm app ideas
- Is stuck after a previous idea was rejected or abandoned
- Wants to explore what's possible with a specific technology (e.g., "what can I build with Foundation Models?")
- Wants inspiration based on their skills or domain expertise
- Asks for a brainstorm session

**Already has a specific idea?** Skip this skill. Use `product-agent discover` instead.

## What This Skill Does

### 1. Developer Profile Elicitation

Gathers context about the developer to personalize ideas:
- **Technical skills** — Languages, frameworks, platforms (Swift, SwiftUI, UIKit, CloudKit, etc.)
- **Domain interests** — Health, finance, productivity, education, creativity, etc.
- **Platform preference** — iOS, macOS, iPadOS, watchOS, visionOS, or multi-platform
- **Time availability** — Side project (5-10 hrs/week), full-time, weekend hack
- **Constraints** — Budget, backend experience, design skills, existing audience

### 2. Five Brainstorming Lenses

Each lens generates 5-8 raw ideas. Lenses are applied in order:

1. **Skills & Interests** — What can you uniquely build given what you know?
2. **Problem-First** — What took 30 seconds today that should take 5? What's annoying?
3. **Technology-First** — Which Apple frameworks have few indie apps? (Foundation Models, ActivityKit, WidgetKit, VisionKit, WeatherKit, MapKit)
4. **Market Gap** — Where are App Store categories underserved, stale, or overpriced?
5. **Trend-Based** — What macro trends create new app opportunities? (AI-native, privacy-first, health/wellness, single-use utilities, Apple Silicon productivity)

### 3. Feasibility Filtering

Each raw idea is evaluated against five filters:

| Filter | Question |
|--------|----------|
| Solo Dev Scope | Can one developer ship an MVP in 4-8 weeks? |
| Platform API Fit | Does this leverage Apple platform APIs well? |
| Monetization Viability | Is there a clear path to revenue? |
| Competition Density | How crowded is this space? |
| Technical Complexity | Does the developer have the skills to build this? |

### 4. Scoring and Ranking

Each surviving idea is scored across five dimensions:

| Dimension | WEAK (1-2) | MODERATE (3-5) | STRONG (6-8) | EXCELLENT (9-10) |
|-----------|------------|----------------|--------------|------------------|
| Solo Dev Scope | 6+ months | 3-6 months | 4-8 weeks | 2-4 weeks |
| Platform API Fit | Generic/cross-platform | Some native APIs | Good platform integration | Deep Apple API usage |
| Monetization | Unclear model | Ad-supported or low ARPU | Subscription viable | Premium pricing justified |
| Competition | Dominated by incumbents | Crowded but fragmented | Few quality options | Blue ocean |
| Technical Fit | Major skill gaps | Some learning needed | Good skill match | Perfect skill match |

**Overall Score** = weighted average on 1-10 scale (Solo Dev Scope and Technical Fit weighted 1.5x).

### 5. Shortlist Output

Final output is a ranked list of 3-5 ideas, each with:
- One-liner description
- Which lens generated it
- Problem statement and target user
- Feasibility scores
- Monetization model
- MVP scope estimate
- `next_step` formatted as an exact `product-agent discover` command

## Output Structure

```json
{
  "developer_profile": {
    "skills": ["Swift", "SwiftUI", "HealthKit", "Core Motion"],
    "interests": ["fitness", "wearables", "data visualization"],
    "platform": "iOS + watchOS",
    "time_availability": "side project (10 hrs/week)",
    "constraints": ["no backend experience", "solo developer"]
  },
  "brainstorm_lenses_used": [
    "skills_and_interests",
    "problem_first",
    "technology_first",
    "market_gap",
    "trend_based"
  ],
  "shortlist": [
    {
      "rank": 1,
      "idea": "Workout Recovery Timer",
      "lens": "skills_and_interests",
      "one_liner": "Apple Watch app that tracks heart rate recovery between sets and suggests optimal rest periods",
      "platform": "watchOS + iOS companion",
      "problem_statement": "Gym-goers either rest too long (wasting time) or too short (risking injury). No app uses real-time HR data to personalize rest periods.",
      "target_user": "Regular gym-goers who wear Apple Watch during workouts",
      "feasibility": {
        "solo_dev_scope": "STRONG (6 weeks — HealthKit + WatchKit + simple UI)",
        "platform_api_fit": "EXCELLENT (HealthKit, WorkoutKit, Live Activities)",
        "monetization_viability": "STRONG (subscription $3.99/mo — fitness users pay for tools)",
        "competition_density": "STRONG (few apps focus specifically on HR-based rest timing)",
        "technical_fit": "EXCELLENT (matches HealthKit + Core Motion skills)"
      },
      "overall_score": 8.4,
      "monetization_model": "Freemium — free with 3 workouts/week, $3.99/mo unlimited + insights",
      "competition_notes": "Strong Timer+ and Intervals Pro exist but focus on pre-set timers, not adaptive HR-based rest",
      "mvp_scope": "Watch app with HR monitoring during rest, vibration alert when ready, basic iOS companion for history",
      "next_step": "product-agent discover --idea \"Apple Watch app that tracks heart rate recovery between sets and suggests optimal rest periods based on real-time HR data\" --platform \"watchOS + iOS\" --output-format json"
    },
    {
      "rank": 2,
      "idea": "Walking Meetings Tracker",
      "lens": "problem_first",
      "one_liner": "Track steps, route, and calories during meetings — share walking meeting summaries with attendees",
      "platform": "iOS + watchOS",
      "problem_statement": "Walking meetings are popular for health but there's no way to track the health benefit or share it. Calendar apps don't connect to HealthKit.",
      "target_user": "Knowledge workers and managers who take walking meetings",
      "feasibility": {
        "solo_dev_scope": "STRONG (5 weeks — HealthKit + MapKit + Calendar integration)",
        "platform_api_fit": "EXCELLENT (HealthKit, MapKit, EventKit, WidgetKit)",
        "monetization_viability": "MODERATE (niche audience, $2.99 one-time or $1.99/mo)",
        "competition_density": "EXCELLENT (no dedicated walking meeting app exists)",
        "technical_fit": "STRONG (HealthKit skills transfer, MapKit is new but manageable)"
      },
      "overall_score": 7.6,
      "monetization_model": "One-time purchase $4.99 with optional $1.99/mo for team features",
      "competition_notes": "Pedometer apps exist but none integrate with calendar or frame walking as meetings",
      "mvp_scope": "Start/stop walking meeting, auto-detect from calendar, log steps + route, share summary",
      "next_step": "product-agent discover --idea \"iOS app that tracks steps, route, and calories during walking meetings and shares summaries with attendees\" --platform \"iOS + watchOS\" --output-format json"
    },
    {
      "rank": 3,
      "idea": "Gym Equipment Wait Time",
      "lens": "market_gap",
      "one_liner": "Crowdsourced gym equipment availability — see which machines are free before you go",
      "platform": "iOS",
      "problem_statement": "Gyms are crowded at peak hours. No way to know if the squat rack is free without going. Leads to wasted time and frustration.",
      "target_user": "Gym members at commercial gyms (Planet Fitness, LA Fitness, Equinox)",
      "feasibility": {
        "solo_dev_scope": "MODERATE (8 weeks — needs crowdsource mechanics and gym database)",
        "platform_api_fit": "MODERATE (MapKit for gym location, but core logic is custom)",
        "monetization_viability": "STRONG (subscription or gym partnership revenue)",
        "competition_density": "STRONG (no quality solution exists — GymBook is workout logging, not availability)",
        "technical_fit": "MODERATE (needs backend for crowdsource data — outside current skills)"
      },
      "overall_score": 6.8,
      "monetization_model": "Freemium — free for 1 gym, $2.99/mo for multiple gyms + predictions",
      "competition_notes": "Some gyms have their own capacity apps but no cross-gym equipment-level tracking exists",
      "mvp_scope": "Single gym support, manual check-in/check-out for equipment, peak time predictions",
      "next_step": "product-agent discover --idea \"Crowdsourced gym equipment availability app that shows which machines are free at your gym\" --platform iOS --output-format json"
    }
  ],
  "ideas_filtered_out": [
    {
      "idea": "AI Personal Trainer",
      "lens": "technology_first",
      "reason": "Extremely competitive (Fitbod, Future, Hevy). Would need 6+ months to differentiate. Failed solo_dev_scope filter."
    },
    {
      "idea": "Sleep Architecture Analyzer",
      "lens": "trend_based",
      "reason": "Apple's own sleep tracking in watchOS 10+ covers most of this. Failed competition_density filter — competing with platform owner."
    }
  ],
  "recommendation": "Start with Rank 1 (Workout Recovery Timer). It scores highest, leverages your exact skills (HealthKit + Core Motion), has a clear monetization path, and can ship in 6 weeks. Run product-agent discover to validate the problem before committing."
}
```

## How to Generate Ideas

### Step 1: Gather Developer Profile

If the user hasn't provided context, ask using AskUserQuestion:

**Questions to ask:**
- What programming languages and frameworks do you know? (Swift, SwiftUI, UIKit, etc.)
- What topics or domains interest you? (health, finance, productivity, etc.)
- Which Apple platforms do you want to target?
- How much time can you dedicate? (side project, full-time, weekend hack)
- Any constraints? (no backend, solo dev, no design skills, etc.)

If the user provides partial info, infer reasonable defaults and state assumptions.

### Step 2: Apply Skills & Interests Lens

Generate 5-8 ideas from the intersection of what the developer knows and cares about.

**Process:**
1. List the developer's top 3-5 skills
2. List their top 3-5 interests
3. For each skill-interest pair, ask: "What app could a developer with [skill] build for people interested in [interest]?"
4. Prefer ideas that use 2+ of their skills simultaneously

**Example:** Swift + HealthKit + fitness interest → workout recovery timer, exercise form checker, fitness challenge app

### Step 3: Apply Problem-First Lens

Find real problems worth solving.

**Process:**
1. Ask the developer: "What took 30 seconds today that should take 5?"
2. Think about common daily friction points in their domain
3. Search for complaint threads: `"[domain] app sucks" OR "[domain] app wish" site:reddit.com`
4. Look for manual processes people do with spreadsheets or notes

**Example:** "I always forget which supplements I took" → supplement tracking app

### Step 4: Apply Technology-First Lens

Identify Apple frameworks with few quality indie apps.

**High-opportunity frameworks (2026):**
- **Foundation Models** — On-device LLM, few indie apps yet
- **ActivityKit / Live Activities** — Sports, cooking, transit, workout tracking
- **WidgetKit** — Glanceable info apps (many categories underserved)
- **VisionKit** — Document scanning, text recognition, visual lookup
- **WeatherKit** — Hyper-local weather for niche use cases
- **SensorKit / Core Motion** — Movement, posture, activity detection
- **DeviceActivity / Screen Time API** — Digital wellness, parental controls

**Process:**
1. Pick 2-3 frameworks matching the developer's platform preference
2. Search App Store for apps using that framework
3. Identify gaps — what should exist but doesn't?

### Step 5: Apply Market Gap Lens

Use WebSearch to find underserved App Store categories.

**Searches to run:**
```
"underserved App Store categories 2026"
"indie app opportunities iOS 2026"
"App Store category [domain] top apps" (check staleness)
"[category] app reviews complaints" site:reddit.com
```

**Signals of opportunity:**
- Top apps haven't been updated in 12+ months
- Reviews complain about the same issues across multiple apps
- Premium pricing ($9.99+) with mediocre ratings (< 4.0)
- Category has few apps but clear demand

### Step 6: Apply Trend Lens

Identify macro trends creating new app opportunities.

**Current trends (2026):**
- **AI-native apps** — Apps that couldn't exist without on-device AI
- **Privacy-first** — Apps that explicitly don't collect data (selling point)
- **Health & wellness** — Mental health, sleep, nutrition, fitness
- **Single-use utilities** — Do one thing exceptionally well
- **Apple Silicon productivity** — Pro tools for Mac (M-series GPU, Neural Engine)
- **Aging population** — Accessibility, health monitoring, simplified tech
- **Creator economy** — Tools for content creators, freelancers

**Process:**
1. Pick 2-3 trends relevant to the developer's interests
2. For each trend, generate 2-3 ideas that serve the trend
3. Prefer trend + skill intersections

### Step 7: Filter, Score, and Rank

**Filter phase:**
1. Collect all raw ideas from Steps 2-6 (typically 25-40 ideas)
2. Apply the five feasibility filters (see Section 3)
3. Remove any idea that scores WEAK on Solo Dev Scope or Technical Fit
4. Remove any idea that scores WEAK on 3+ dimensions

**Score phase:**
1. Score each surviving idea on all five dimensions
2. Calculate overall score (Solo Dev Scope and Technical Fit weighted 1.5x)
3. Rank by overall score descending

**Output phase:**
1. Take the top 3-5 ideas
2. Write full entries with all fields from Output Structure
3. Format `next_step` as exact `product-agent discover` command
4. List 1-3 filtered-out ideas with reasons
5. Write a recommendation highlighting Rank 1 and why

## End-to-End Example

**Developer profile:**
> Maya, backend engineer (Python, some Swift), interested in nutrition and cooking. Wants to build her first iOS app as a side project (8 hrs/week). No design skills. Comfortable with APIs but no HealthKit experience.

**Lens application:**

1. **Skills & Interests →** Recipe nutrition calculator (Swift + API skills + nutrition interest), meal prep planner, ingredient substitution finder
2. **Problem-First →** "I never know if my meals hit my protein target" → macro tracker that works from photos, "grocery lists from recipes are always wrong" → smart grocery list
3. **Technology-First →** Foundation Models → describe leftovers and get recipe suggestions, VisionKit → scan nutrition labels and auto-log
4. **Market Gap →** Searched "nutrition app complaints reddit" → users hate manual food logging, want simpler interfaces, tired of ads in free tier
5. **Trend →** AI-native + health/wellness → on-device food recognition, privacy-first nutrition tracking (no cloud data)

**After filtering and scoring:**

| Rank | Idea | Score | Key Strength |
|------|------|-------|-------------|
| 1 | AI Leftover Recipe Finder | 8.1 | Foundation Models + cooking interest, blue ocean |
| 2 | Photo Macro Tracker | 7.4 | Problem-first (everyone hates manual logging) |
| 3 | Smart Grocery List | 6.9 | Simple scope, clear monetization |

**Recommendation:** "Start with AI Leftover Recipe Finder. It uses Foundation Models (few competitors), aligns with your cooking interest, and can ship a basic version in 5 weeks. Run `product-agent discover` to validate demand."

## Integration with Other Skills

```
Phase 0: idea-generator (THIS SKILL)
    ↓ pick 1 idea from shortlist
Phase 1: product-agent discover → validate the problem
    ↓
Phase 2: market-research / competitive-analysis → size the opportunity
    ↓
Phase 3: prd-generator → define features
    ↓
Phase 4: architecture-spec → technical design
    ↓
Phase 5+: ux-spec, implementation-guide, test-spec, release-spec
```

The `next_step` field in each shortlist entry is pre-formatted as the exact `product-agent discover` command. After the user picks their favorite idea, they can run it directly to kick off Phase 1 validation.

**Feeding into product-agent:**
- The `one_liner` becomes the `--idea` argument
- The `platform` becomes the `--platform` argument
- `--output-format json` is always included for structured output

## When NOT to Use This Skill

- **Already has a specific idea** — Go directly to `product-agent discover`
- **Already validated an idea** — Go to `market-research` or `competitive-analysis`
- **Wants code generation** — Use the `generators/` skills
- **Building to learn only** — Skip feasibility filtering; just pick what's fun
- **Hard deadline** — Skip brainstorming; go straight to `product-agent discover` with whatever idea you have

## Deliverables

At the end of this skill, you should have:

- [ ] Developer profile captured (skills, interests, platform, time, constraints)
- [ ] All 5 brainstorming lenses applied
- [ ] Feasibility filtering applied (5 filters)
- [ ] Shortlist of 3-5 ideas with full scoring
- [ ] Ideas ranked by overall_score (highest first)
- [ ] Each idea has `next_step` formatted as `product-agent discover` command
- [ ] Filtered-out ideas listed with reasons
- [ ] Recommendation paragraph highlighting Rank 1

## Output File Location

Save results to:
- `idea-shortlist.json` (project root)

**Format:** Use the JSON structure from the Output Structure section.

**Next action:** Feed Rank 1 into `product-agent discover` by running the `next_step` command.

---

**Generate fast, filter ruthlessly, validate before committing.** The best app idea is the one that matches your skills, solves a real problem, and can ship in weeks — not months.
