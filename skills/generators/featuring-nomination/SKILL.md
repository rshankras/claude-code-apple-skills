---
name: featuring-nomination
description: Generates App Store featuring nomination pitches with all required fields, compelling narratives, and Apple editorial angles. Use when submitting your app for App Store editorial featuring or preparing a self-nomination.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, WebSearch]
---

# Featuring Nomination Generator

Generate a compelling App Store featuring nomination ready for submission, including all required fields, narrative pitch, and strategic timing.

## When This Skill Activates

Use this skill when the user:
- Asks to "get featured" or "submit for App Store featuring"
- Mentions "featuring nomination" or "editorial feature"
- Wants help with "App Store editorial" pitch
- Is preparing a major launch or update and wants visibility
- Asks about "Today tab" or "Apps We Love"

## How App Store Featuring Works

Apple's editorial team hand-picks apps for featuring based on:
- **Quality**: Design, performance, and polish
- **Innovation**: Novel use of Apple technologies
- **Relevance**: Timely content or seasonal alignment
- **Story**: Compelling developer or user narrative

### Featuring Placements
| Placement | Visibility | Requirements |
|-----------|-----------|-------------|
| Today tab story | Highest | Exceptional quality + narrative |
| App of the Day | Very high | Outstanding app + timing |
| Collection feature | High | Fits a themed collection |
| Category feature | Medium | Top quality in category |
| Search result boost | Medium | Relevance + quality |

### Submission Timeline
- Submit **6-8 weeks** before desired featuring date
- Apple reviews and plans editorial calendar in advance
- Seasonal features are planned months ahead
- No guarantee of featuring — but quality nominations increase odds significantly

## Configuration Questions

Ask user via AskUserQuestion:

1. **Reason for nomination?**
   - New app launch
   - Major update with new features
   - Seasonal relevance (holiday, back-to-school, etc.)
   - Apple technology showcase (new API adoption)
   - Milestone (anniversary, user count, award)

2. **Apple technologies used?** (multi-select)
   - SwiftUI
   - WidgetKit / Live Activities
   - App Intents / Shortcuts
   - Apple Intelligence / Foundation Models
   - ARKit / RealityKit
   - HealthKit / ActivityKit
   - SharePlay
   - StoreKit 2
   - Apple Watch complications
   - visionOS support
   - Other (specify)

3. **Target featuring date?**
   - Within 2 weeks (too late for editorial, but can try)
   - 4-6 weeks from now (ideal timing)
   - 8+ weeks from now (best chance for planning)
   - Seasonal window (specify season)

## Generation Process

### Step 1: Gather App Details

Collect comprehensive information:
- App name, description, and category
- What's new in this version (if update)
- Apple technologies used with specific details
- Developer story (indie, team, background)
- User impact stories or metrics
- Visual design highlights
- Accessibility features
- Privacy stance

### Step 2: Identify Featuring Angles

Read `nomination-template.md` for the angle selection framework.

Strong angles by category:
- **Accessibility**: Apps that serve underserved communities
- **Health**: Mental health, physical wellness, therapy tools
- **Education**: Learning innovation, kids' safety
- **Sustainability**: Environmental impact, eco-friendly
- **Creativity**: Novel creative tools or expression
- **Apple Tech**: Deep integration with latest Apple APIs
- **Cultural**: Apps celebrating cultural moments or diversity

### Step 3: Generate Nomination

Produce the complete nomination document.

## Output Format

Read `nomination-template.md` and fill all fields.

```markdown
# App Store Featuring Nomination

## App Information
| Field | Value |
|-------|-------|
| App Name | [Name] |
| Developer | [Developer/Company Name] |
| App Store URL | [URL] |
| Category | [Primary Category] |
| Platforms | [iOS / macOS / watchOS / visionOS] |
| App Store Connect Contact | [Email] |

## Nomination Reason
[One of: New Launch / Major Update / Seasonal / Technology / Milestone]

## Desired Featuring Window
[Date range, aligned with launch or seasonal opportunity]

## App Overview (2-3 sentences)
[Compelling summary of what the app does and why it matters]

## What Makes This App Special (3-5 bullet points)
- [Unique value proposition]
- [Design or UX innovation]
- [Technical excellence]
- [User impact]
- [Cultural or social significance]

## Apple Technology Integration
| Technology | How It's Used |
|-----------|--------------|
| [SwiftUI] | [Specific usage details] |
| [WidgetKit] | [Specific usage details] |
| [etc.] | [etc.] |

## Developer Story (2-3 sentences)
[Personal or team narrative that makes the app relatable]

## User Impact
[Metrics, testimonials, or stories showing real-world impact]

## Design Highlights
[What makes the visual design noteworthy — animations, interactions, aesthetics]

## Accessibility Features
[VoiceOver support, Dynamic Type, color accessibility, etc.]

## Privacy Commitment
[How the app respects user privacy — on-device processing, minimal data collection, etc.]

## Media Kit
[Links to: screenshots, app preview video, press kit, developer photos]

## Social Proof (optional)
[Press mentions, awards, notable reviews, download milestones]
```

## References

- **nomination-template.md** — Detailed nomination form and angle framework
- Related: `app-store/marketing-strategy` — Featuring as part of broader strategy
- Related: `app-store/app-description-writer` — Compelling app copy
- Related: `generators/in-app-events` — Pair featuring with events
- Apple: [Nominate your app for featuring](https://developer.apple.com/app-store/discoverability/)
