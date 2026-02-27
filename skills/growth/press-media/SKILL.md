---
name: press-media
description: Get press coverage and media attention for your indie app. Covers press kit preparation, finding journalists/bloggers/YouTubers, pitch timing, embargo strategy, and story angles that get coverage. Use when user wants press coverage, is preparing for a launch, or wants to build a media kit.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion, WebSearch]
---

# Press & Media Outreach

Get press coverage and media attention for your indie Apple app. Covers everything from press kit preparation to finding the right journalists to crafting pitches that get responses.

## When This Skill Activates

Use this skill when the user:
- Wants press coverage for their app
- Is preparing for a launch and wants PR
- Wants to create a media kit or press kit
- Is looking for reviewers, bloggers, or YouTubers
- Asks about getting featured by Apple-focused outlets
- Wants to pitch their app to podcasts

## Process

### Step 1: Gather Context

Ask the user via AskUserQuestion:

1. **App details**: What does the app do? What platform(s)?
2. **Launch timing**: When is/was the launch? Is this a new app or major update?
3. **Story angle**: What makes this app unique or interesting?
4. **Previous coverage**: Have you been covered before? Any existing press kit?
5. **Budget**: Any budget for PR, or purely organic outreach?

### Step 2: Press Kit Preparation

A press kit makes it easy for journalists to write about your app. If they have to hunt for information, they will skip you.

#### Required Assets

| Asset | Specification | Notes |
|-------|--------------|-------|
| App icon | 1024x1024 PNG, no rounded corners | Journalists crop it themselves |
| Screenshots | 5-8 key screens, with and without device frames | Both raw and framed versions |
| App description (short) | 1 sentence, < 150 characters | For quick mentions |
| App description (medium) | 1 paragraph, 3-4 sentences | For brief coverage |
| App description (long) | 3 paragraphs | For feature articles |
| Developer bio | 2-3 sentences about you | Include relevant background |
| Developer photo | Headshot, 800x800+ | Professional but approachable |
| Fact sheet | Structured data | See template below |
| Promo video | 30-60 seconds (optional) | Dramatically increases coverage odds |

#### Fact Sheet Template

```
APP NAME: [Name]
DEVELOPER: [Your Name / Company]
LAUNCH DATE: [Date or "Available Now"]
PRICE: [Free / $X.XX / Free with subscription ($X.XX/mo)]
PLATFORMS: [iOS / macOS / iPadOS / watchOS / visionOS]
REQUIREMENTS: [iOS 17+ / macOS 14+]
WEBSITE: [URL]
APP STORE: [App Store link]
PRESS KIT: [URL to downloadable press kit]
CONTACT: [press@yourdomain.com]

KEY FEATURES:
- [Feature 1]: [One sentence description]
- [Feature 2]: [One sentence description]
- [Feature 3]: [One sentence description]
- [Feature 4]: [One sentence description]
- [Feature 5]: [One sentence description]

WHAT MAKES IT DIFFERENT:
[2-3 sentences on unique value proposition]
```

#### Press Kit Hosting Options

| Option | Cost | Pros | Cons |
|--------|------|------|------|
| presskit.html on your website | Free (hosting cost) | Professional, SEO benefits | Requires web dev |
| Notion page | Free | Easy to update, looks clean | Less professional URL |
| GitHub repo | Free | Easy asset downloads | Slightly technical feel |
| presskit() generator | Free | Industry standard format | Template-based |
| Dedicated presskit page | Free-$10/mo | Purpose-built for press kits | Another service to manage |

**Recommendation:** A simple `/press` page on your website with downloadable ZIP of all assets. Include everything inline so journalists can copy-paste without downloading.

### Step 3: Finding Relevant Journalists and Outlets

Build a targeted list of 20-30 contacts. Quality over quantity — 20 personalized pitches outperform 200 generic ones.

#### Apple-Focused Outlets

**Tier 1 — Major Coverage (hardest to get, biggest impact)**
| Outlet | Focus | Best For |
|--------|-------|----------|
| MacStories | In-depth iOS/Mac app reviews | Thoughtful, well-designed apps |
| 9to5Mac | Apple news and app coverage | News-worthy launches and updates |
| The Verge | Tech culture and reviews | Apps with broad appeal |
| TechCrunch | Startup and tech news | Apps with a business/funding angle |
| Daring Fireball | Apple commentary | Apps John Gruber would personally use |

**Tier 2 — Focused Coverage (more accessible, strong reach)**
| Outlet | Focus | Best For |
|--------|-------|----------|
| iMore | Apple ecosystem guides | How-to and practical apps |
| Six Colors | Apple analysis (Jason Snell) | Productivity and creative tools |
| Club MacStories | App discovery | Polished, design-forward apps |
| TUAW / Cult of Mac | Apple enthusiast coverage | Consumer-friendly apps |
| Indie App Santa | Indie app promotion | Well-designed indie apps |

**Tier 3 — Niche and Community (most accessible, targeted reach)**
| Outlet | Focus | Best For |
|--------|-------|----------|
| SwiftUI Weekly / iOS Dev Weekly | Developer newsletters | Developer tools and technical apps |
| Product Hunt | Launch platform | Any new app launch |
| Hacker News | Tech community | Technical or privacy-focused apps |
| Category-specific blogs | Niche audiences | Apps serving specific verticals |

#### YouTube Reviewers

Search for "best iOS apps" or "best Mac apps" on YouTube. Look for:
- Channels with 10K-500K subscribers (large enough for reach, small enough to respond)
- Recent uploads (active channel)
- Previous indie app coverage (not just major apps)
- Professional review style (not just listicles)

#### Podcast Hosts

| Podcast | Focus | Format |
|---------|-------|--------|
| AppStories (MacStories) | App discovery and discussion | Weekly discussion |
| Launched (Charlie Chapman) | Indie developer stories | Interview |
| Under the Radar (Marco/David) | Indie development | Discussion |
| Stacktrace | Apple dev and design | Discussion |
| Core Intuition (Jalkut/Simmons) | Indie Mac/iOS | Discussion |
| Accidental Tech Podcast | Apple tech (if relevant) | Discussion |

### Step 4: Pitch Timing

#### When to Reach Out

| Timing | Action |
|--------|--------|
| 3-4 weeks before launch | Reach out to Tier 1 outlets for exclusive/embargo |
| 2-3 weeks before launch | Broader outreach to Tier 2 and 3 |
| 1 week before launch | Follow up with non-responders (once only) |
| Launch day | Share on social media, Product Hunt, Hacker News |
| 1 week after launch | Thank journalists who covered you |

#### Best Days and Times
- **Best days:** Tuesday, Wednesday, Thursday
- **Best time:** 9-11 AM in the journalist's time zone
- **Worst days:** Monday (inbox overload), Friday (winding down)
- **Avoid:** Major Apple events (WWDC, iPhone launch, iPad event), CES week, holiday weeks

#### Follow-Up Cadence
- Send initial pitch
- Wait 5-7 business days
- Send ONE follow-up (add new info or angle, don't just repeat)
- If no response after follow-up, move on — do NOT keep emailing
- Never guilt-trip or get frustrated in follow-ups

### Step 5: Embargo Strategy

Embargoes let you give journalists early access in exchange for coordinated coverage on launch day.

#### Exclusive Strategy (Tier 1)
1. Pick ONE top-tier outlet that covers your app's category
2. Offer 1-2 week exclusive access before launch
3. Provide TestFlight build, press kit, and personal demo offer
4. Agree on publish date (your launch day)
5. Benefits: deep review, stronger relationship, headline coverage

#### Broader Embargo (Tier 2-3)
1. After exclusive is confirmed, invite 5-10 outlets under embargo
2. Set clear embargo lift date and time (usually launch day, 9 AM ET)
3. Include TestFlight link and press kit
4. Benefits: wave of coverage on launch day

#### Rules of Embargoes
- Always put embargo date/time in writing
- Honor the exclusive — don't give the same story to competitors
- If someone breaks embargo, never work with them again
- Be understanding if a small outlet publishes early by accident

### Step 6: Story Angles That Get Coverage

Journalists don't write about apps — they write about stories. Frame your pitch around a story, not a feature list.

#### Story Angles That Work for Indie Developers

**The Solo Developer Story**
- "I quit my job at [Big Tech] to build the app I always wanted"
- "I built this while recovering from [life event]"
- "A 22-year-old student built a top-rated [category] app"
- Why it works: readers love underdog stories

**Scratching Your Own Itch**
- "I couldn't find a [category] app that [specific need], so I built one"
- "As a [profession], I needed [specific tool] — it didn't exist"
- Why it works: authentic, relatable, shows deep domain knowledge

**Innovative Apple Technology Use**
- "First app to use [new iOS/macOS feature]"
- "Built entirely with SwiftUI and [new framework]"
- "Uses on-device ML for [clever application]"
- Why it works: Apple-focused outlets love showcasing platform capabilities

**Privacy-First Alternative**
- "A [category] app that keeps your data on your device"
- "No accounts, no servers, no tracking"
- Why it works: privacy is a hot topic, especially for Apple audience

**Accessibility Champion**
- "Designed VoiceOver-first for visually impaired users"
- "Built to help people with [condition]"
- Why it works: feel-good story, Apple values accessibility

**Design Excellence**
- "What happens when a designer builds their own app"
- Award-worthy UI/UX (Apple Design Awards angle)
- Why it works: Apple-focused outlets value design deeply

#### Story Angles That Do NOT Work
- "My app is better than [competitor]" — sounds petty
- "My app has 50 features" — feature lists are boring
- "My app is the best [category] app" — let reviewers decide
- "I need coverage to grow" — journalists are not your marketing team
- "Check out my app" (no angle at all) — gives them nothing to write about

### Step 7: After Coverage

#### When You Get Coverage
1. Thank the journalist publicly (tweet/post) and privately (email)
2. Share the article on all your channels
3. Add "As featured in..." to your App Store description and website
4. Screenshot the coverage for future press kit
5. Note which angle worked — use it for future pitches

#### When You Don't Get Coverage
- Do NOT send angry or disappointed emails
- Evaluate: was the pitch personalized? Was the timing right? Was the angle strong?
- Try a different angle next time (update, milestone, seasonal)
- Build the relationship anyway — comment on their articles, engage on social media
- Remember: most pitches don't get responses. A 10-20% response rate is normal.

## Reference Files

See **pitch-templates.md** for:
- Launch pitch email template
- Update/feature pitch template
- Story angle pitch template
- Podcast pitch template
- Follow-up template

## Output Format

Present outreach plan as:

```markdown
# Press Outreach Plan: [App Name]

## Press Kit Status
- [ ] App icon (1024x1024)
- [ ] Screenshots (X screens, framed and raw)
- [ ] Description (short / medium / long)
- [ ] Developer bio and photo
- [ ] Fact sheet
- [ ] Press kit hosted at [URL]

## Story Angle
**Primary:** [The main story angle]
**Secondary:** [Backup angle if primary doesn't land]

## Target List (20-30 contacts)

### Tier 1 — Exclusive Target
| Outlet | Contact | Why Them |
|--------|---------|----------|
| [outlet] | [name] | [reason] |

### Tier 2 — Embargo Group
| Outlet | Contact | Why Them |
|--------|---------|----------|
| ... | ... | ... |

### Tier 3 — Broad Outreach
| Outlet | Contact | Why Them |
|--------|---------|----------|
| ... | ... | ... |

## Timeline
| Date | Action |
|------|--------|
| [T-3 weeks] | Send exclusive pitch to Tier 1 |
| [T-2 weeks] | Send embargo pitches to Tier 2 |
| [T-1 week] | Send broad pitches to Tier 3, follow up Tier 1 |
| [Launch day] | Embargo lifts, social media push, Product Hunt |
| [T+1 week] | Thank journalists, share coverage |

## Pitch Drafts
[See pitch-templates.md for templates, customize for each contact]
```

## References

- **pitch-templates.md** — Email templates for all pitch types
- **community-building/** — For organic promotion via social media
- **app-store/** — For optimizing the product page journalists will link to
