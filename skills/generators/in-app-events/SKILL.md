---
name: in-app-events
description: Generates In-App Event metadata templates for App Store Connect — event names, descriptions, badge types, image specs, and deep link configuration. Use when creating events for App Store visibility, engagement campaigns, or seasonal promotions.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, WebSearch]
---

# In-App Events Generator

Generate complete In-App Event metadata ready for App Store Connect upload, including event cards, descriptions, deep link configuration, and promotional image specifications.

## When This Skill Activates

Use this skill when the user:
- Asks to "create in-app events" or "add App Store events"
- Mentions "event cards" or "App Store event metadata"
- Wants to create seasonal campaigns or challenges on the App Store
- Asks about "event badges" or "event promotion"
- Mentions driving engagement through App Store events

## How In-App Events Work

In-App Events appear on:
- Your product page (up to 5 events visible)
- Search results (when relevant to search term)
- Editorial features and collections
- Personalized recommendations

Events are visible to ALL users — including people who haven't downloaded your app. This makes them a powerful discovery and re-engagement tool.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Event type**
   - Challenge (skill-based competition or goal)
   - Competition (leaderboard or ranked event)
   - Live Event (real-time participation)
   - Special Event (limited-time content or feature)
   - Major Update (significant new version)
   - New Season (seasonal content refresh)
   - Premiere (first-time content debut)

2. **Event purpose**
   - Drive new downloads (acquisition)
   - Re-engage lapsed users (re-engagement)
   - Increase active user engagement (retention)
   - Promote new content/feature (awareness)

3. **Number of events to create**
   - Single event
   - Event series (3-5 related events)
   - Seasonal calendar (12-month plan)

## Generation Process

### Step 1: Gather Event Details

For each event, collect:
- Event concept and theme
- Start and end dates
- Target audience (new users, existing users, lapsed users)
- Related app feature or content

### Step 2: Generate Metadata

For each event, produce:
1. **Event Reference Name** (internal, not shown to users)
2. **Event Badge** (one of the 7 badge types)
3. **Event Name** (30 characters max, shown on event card)
4. **Short Description** (50 characters max, shown on event card)
5. **Long Description** (120 characters max, shown on event detail page)
6. **Event Media Specs** (image/video requirements)
7. **Deep Link** (where users land when they tap the event)

### Step 3: Generate Image Specs

Provide exact image specifications for event cards:
- **Event Card Image**: 1080 x 1920 pixels (portrait) or 1920 x 1080 (landscape)
- **Format**: PNG or JPEG
- **Safe zones**: Keep critical content within center 80%

### Step 4: Produce Output Document

Write a markdown document with all metadata ready for copy/paste into App Store Connect.

## Event Badge Reference

| Badge | Use For | Examples |
|-------|---------|---------|
| **Challenge** | Goal-based activities users can complete | "30-Day Fitness Challenge", "Photography Week" |
| **Competition** | Ranked or scored events against other users | "Weekly Leaderboard", "Speed Run Contest" |
| **Live Event** | Real-time events at a specific time | "Live Q&A with Creator", "Launch Party" |
| **Special Event** | Limited-time features, offers, or content | "Holiday Collection", "Anniversary Sale" |
| **Major Update** | Significant new app version | "Version 3.0 — Complete Redesign" |
| **New Season** | Seasonal content refreshes | "Winter Season", "Chapter 3" |
| **Premiere** | First-time content or feature debut | "Introducing Dark Mode", "New Game Mode" |

## Metadata Best Practices

### Event Name (30 chars)
- **DO**: Use action-oriented language ("Join the Challenge", "Explore New Features")
- **DO**: Include time urgency ("This Week Only", "24-Hour Event")
- **DON'T**: Use generic names ("Special Event", "Update")
- **DON'T**: Include app name (it's already shown)

### Short Description (50 chars)
- **DO**: Explain the core value or action
- **DO**: Create urgency or excitement
- **DON'T**: Repeat the event name
- **DON'T**: Use marketing fluff

### Long Description (120 chars)
- **DO**: Provide specific details about what users will experience
- **DO**: Include clear call to action
- **DON'T**: List features — describe the experience

## Output Format

### Single Event Template

```markdown
# In-App Event: [Event Concept]

## App Store Connect Metadata

| Field | Value |
|-------|-------|
| Reference Name | [internal-name-kebab-case] |
| Badge | [Badge Type] |
| Event Name | [30 chars max] |
| Short Description | [50 chars max] |
| Long Description | [120 chars max] |
| Start Date | [YYYY-MM-DD HH:MM timezone] |
| End Date | [YYYY-MM-DD HH:MM timezone] |
| Event Purpose | [Primary / Informational] |
| Event Priority | [Normal / High] |
| Deep Link | [yourapp://event/event-id] |

## Event Card Image

| Spec | Value |
|------|-------|
| Size | 1080 x 1920 px (portrait) |
| Format | PNG, no transparency |
| Safe Zone | Center 80% for critical content |
| Background | [Color/gradient suggestion] |
| Content | [Visual description] |
| Text Overlay | [Text to include on image] |

## Deep Link Configuration

- URL Scheme: `yourapp://event/[event-id]`
- Universal Link: `https://yourapp.com/event/[event-id]`
- Fallback: App Store product page

## Localization Notes

- [Language]: [Localized event name and descriptions]
```

### Event Series Template

```markdown
# Event Series: [Series Name]

## Series Overview
[Brief description of the series theme and cadence]

## Events

### Event 1: [Name]
[Same fields as single event template]

### Event 2: [Name]
[Same fields as single event template]

### Event 3: [Name]
[Same fields as single event template]

## Series Strategy
- **Cadence**: [Weekly / Biweekly / Monthly]
- **Escalation**: [How events build on each other]
- **Retention hook**: [What brings users back for the next event]
```

### Annual Calendar Template

```markdown
# Annual Event Calendar: [App Name]

| Month | Event | Badge | Duration | Goal |
|-------|-------|-------|----------|------|
| Jan | [Event name] | [Badge] | [X days] | [Goal] |
| Feb | [Event name] | [Badge] | [X days] | [Goal] |
| ... | ... | ... | ... | ... |

## Seasonal Themes
- **Q1 (Jan-Mar)**: [Theme — e.g., New Year motivation]
- **Q2 (Apr-Jun)**: [Theme — e.g., Spring refresh, WWDC tie-in]
- **Q3 (Jul-Sep)**: [Theme — e.g., Summer activities, back to school]
- **Q4 (Oct-Dec)**: [Theme — e.g., Halloween, holiday season]
```

## References

- Related: `app-store/marketing-strategy` — Strategic event planning by app type
- Related: `generators/custom-product-pages` — Pair events with targeted product pages
- Related: `app-store/app-description-writer` — Event description writing style
- Apple: App Store Connect Help > In-App Events
