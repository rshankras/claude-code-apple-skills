---
name: pre-orders
description: Generates pre-order setup guides and launch timeline templates for App Store pre-orders. Use when planning a pre-order strategy for a new app launch or major update.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, WebSearch]
---

# Pre-Orders Generator

Generate pre-order configuration guides, launch timeline templates, and marketing coordination plans for App Store pre-orders.

## When This Skill Activates

Use this skill when the user:
- Asks about "pre-orders" or "App Store pre-order"
- Wants to "build anticipation" before a launch
- Mentions "pre-launch strategy" or "launch countdown"
- Asks about making their app available before release date
- Wants to collect day-one downloads

## How Pre-Orders Work

- Available up to **180 days** before release
- Users can order your app before it's available
- App auto-downloads on release day
- Pre-orders count toward your launch day download numbers
- Your app appears in search and browse during pre-order period
- Price can be set to "Free" or any paid tier during pre-order

### Key Benefits
1. **Accumulate downloads**: Pre-orders count toward day-one velocity
2. **Search visibility**: App is searchable before release
3. **Featuring eligibility**: Apple can feature pre-order apps
4. **Marketing anchor**: Give audiences a concrete action ("Pre-order now")

### Limitations
- Cannot change app name or primary category after pre-order starts
- Price increases require 7-day notice to pre-order customers
- App must be ready for review before pre-order goes live
- Release date can be moved earlier but not more than 180 days out

## Configuration Questions

Ask user via AskUserQuestion:

1. **Pre-order reason?**
   - Brand new app launch
   - Major version update (new app listing)
   - Seasonal launch timing (holiday, back to school)
   - WWDC/new OS tie-in

2. **Pre-order duration?**
   - Short (1-2 weeks) — urgency-driven
   - Medium (4-6 weeks) — time to build awareness
   - Long (2-6 months) — major marketing campaign

3. **Pricing strategy?**
   - Free app (maximize pre-orders)
   - Paid at final price
   - Paid with launch discount (raise price after launch week)

## Output Format

```markdown
# Pre-Order Plan: [App Name]

## Configuration

| Setting | Value |
|---------|-------|
| Pre-Order Start | [Date] |
| Release Date | [Date] |
| Pre-Order Duration | [X weeks] |
| Price During Pre-Order | [Free / $X.99] |
| Post-Launch Price | [$X.99] |

## App Store Connect Setup

1. Go to App Store Connect > Your App
2. Under "Pricing and Availability":
   - Set the release date to your planned launch date
   - Enable "Pre-Order" availability
3. Under "App Information":
   - App name, category, and description must be final
   - Screenshots should show the final app (or close to final)
4. Submit app for review:
   - App must pass review before pre-order goes live
   - Prepare a TestFlight-ready build for review

## Launch Timeline

### [X] Weeks Before Launch: Pre-Order Goes Live
- [ ] Submit app for App Store review
- [ ] Prepare pre-order announcement
- [ ] Schedule social media posts
- [ ] Send press kit to media contacts
- [ ] Configure In-App Event for launch day

### [X-2] Weeks Before: Build Anticipation
- [ ] Share development updates/behind-the-scenes
- [ ] Release app preview video on social channels
- [ ] Follow up with press contacts
- [ ] Share pre-order link in email newsletter

### 1 Week Before: Final Push
- [ ] Countdown posts on social media
- [ ] Featuring nomination follow-up
- [ ] Prepare launch day communications
- [ ] Verify build is ready for release

### Launch Day
- [ ] Release the app (automatic for pre-orders)
- [ ] Publish launch In-App Event
- [ ] Send launch announcement to email list
- [ ] Post across all social channels
- [ ] Monitor reviews and respond quickly
- [ ] Track download velocity

### Launch Week
- [ ] Start Product Page Optimization test
- [ ] Monitor conversion rates
- [ ] Adjust marketing based on initial data
- [ ] Submit second featuring nomination if not featured

## Pre-Order Marketing Assets

### Landing Page
- Pre-order App Store badge/button
- App preview screenshots
- Feature highlights
- Release date and countdown

### Social Media
- Announcement post with pre-order link
- 3-5 countdown posts leading to launch
- Feature highlight posts (one feature per post)
- Behind-the-scenes development content

### Email
- Pre-order announcement to existing audience
- 1-week reminder before launch
- Launch day celebration email

## Measurement

| Metric | Target | Track In |
|--------|--------|----------|
| Pre-order count | [Goal] | App Store Connect |
| Day 1 downloads | [Goal] | App Store Connect |
| First week downloads | [Goal] | App Store Connect |
| Conversion rate | [X%] | App Store Connect Analytics |
```

## Pre-Order Best Practices

### Timing
| Scenario | Recommended Duration | Reason |
|----------|---------------------|--------|
| Indie app, small audience | 2-4 weeks | Short attention span, limited reach |
| Established brand, new app | 4-8 weeks | Time for press and marketing |
| Seasonal launch | Align with season start | Holiday: early Nov, Back to school: mid-Aug |
| WWDC tie-in | Start at WWDC, launch with OS | Ride the hype wave |

### Pricing Strategy
| Model | During Pre-Order | After Launch | Best For |
|-------|-----------------|-------------|----------|
| Free launch | Free | Free | Freemium apps, maximum pre-orders |
| Introductory price | $0.99-2.99 | $4.99-9.99 | Create urgency, reward early adopters |
| Full price | $X.99 | $X.99 | Premium apps with strong demand |
| Free then paid | Free | $X.99 | Controversial — may frustrate expectations |

## References

- Related: `generators/in-app-events` — Launch event for release day
- Related: `generators/featuring-nomination` — Featuring during pre-order
- Related: `generators/app-store-assets` — Asset specs for pre-order page
- Related: `app-store/marketing-strategy` — Pre-launch as part of overall strategy
