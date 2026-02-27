---
name: offer-codes-setup
description: Generates offer code distribution strategies and configuration guides for subscription and IAP promotions — including partner campaigns, influencer programs, and email re-engagement. Use when setting up offer codes for distribution.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, WebSearch]
---

# Offer Codes Setup Generator

Generate offer code distribution strategies, configuration guides, and campaign templates for promoting subscriptions and IAPs through redeemable codes.

## When This Skill Activates

Use this skill when the user:
- Asks about "offer codes" or "promo codes" for subscriptions
- Wants to distribute free/discounted subscriptions to partners or influencers
- Mentions "redemption codes" or "App Store codes"
- Asks about re-engaging users via email with promotional codes
- Wants to set up influencer or reviewer programs

## How Offer Codes Work

- Create in **App Store Connect** under Subscriptions > Offer Codes
- Two types: **one-time use codes** and **custom codes** (reusable, max 25 chars)
- Maximum **150,000 codes per app per quarter** (per subscription)
- Users redeem via: App Store, your app (using `presentOfferCodeRedeemSheet()`), or direct link
- Offer applies the configured discount (free period, discounted rate, etc.)
- Codes expire after the date you set in App Store Connect

### Code Types
| Type | Description | Best For |
|------|-------------|----------|
| One-time use | Unique codes, each used once | Email campaigns, individual distribution |
| Custom codes | Reusable keyword codes (e.g., "LAUNCH2025") | Social media, events, partnerships |

### Redemption Methods
1. **App Store > Account > Redeem Gift Card or Code**
2. **In your app** via `AppStore.presentOfferCodeRedeemSheet()`
3. **Direct URL**: `https://apps.apple.com/redeem?ctx=offercodes&id=APPID&code=CODE`

## Configuration Questions

Ask user via AskUserQuestion:

1. **Distribution purpose?**
   - Influencer/reviewer program (free access for promotion)
   - Partner distribution (B2B or affiliate)
   - Email re-engagement (win-back lapsed users)
   - Event/conference distribution (in-person)
   - Social media promotion (public campaign)

2. **Offer type?**
   - Free subscription period (1 week, 1 month, 3 months)
   - Discounted first period
   - Extended free trial

3. **Scale?**
   - Small (< 100 codes, targeted distribution)
   - Medium (100-1,000 codes, campaign-based)
   - Large (1,000+ codes, broad distribution)

## Generation Process

### Step 1: Design Campaign Strategy

Based on the distribution purpose, design:
- Target audience and outreach plan
- Code type (one-time vs. custom)
- Offer duration and terms
- Distribution channel and messaging
- Tracking and measurement plan

### Step 2: Generate Campaign Document

## Output Format

```markdown
# Offer Code Campaign: [Campaign Name]

## Campaign Overview
| Field | Value |
|-------|-------|
| Purpose | [Distribution purpose] |
| Target Audience | [Who receives codes] |
| Code Type | [One-time / Custom] |
| Offer | [Free X months / Y% off first period] |
| Total Codes | [Number] |
| Distribution Period | [Date range] |
| Code Expiration | [Date] |

## App Store Connect Setup

1. Go to App Store Connect > Subscriptions > [Group] > [Subscription]
2. Navigate to "Offer Codes" tab
3. Create new offer:
   - Offer type: [Free / Pay as you go / Pay up front]
   - Duration: [X weeks/months]
   - Pricing: [If discounted, specify tier]
4. Generate codes:
   - Type: [One-time use / Custom code]
   - Quantity: [Number]
   - Custom code name: [If custom, e.g., "LAUNCH2025"]
   - Expiration: [Date]
5. Download codes CSV (for one-time codes)

## Distribution Plan

### Channel: [Channel Name]
- **Recipients**: [Who gets codes and how many]
- **Delivery method**: [Email / DM / QR code / Link]
- **Message template**: [See below]
- **Tracking**: [How to measure redemption]

### Message Template

#### For Influencers/Reviewers
Subject: [App Name] — Complimentary Pro Access

> Hi [Name],
>
> I'd love to offer you complimentary Pro access to [App Name] — [one-line description].
>
> Your personal code: **[CODE]**
>
> Redeem: Open the App Store → Account → Redeem Gift Card or Code → Enter code
> Or direct link: [redemption URL]
>
> This gives you [offer details — e.g., 3 months free Pro].
>
> If you enjoy the app, we'd love an honest review or mention. No obligation at all.
>
> Best,
> [Your name]

#### For Email Re-engagement
Subject: We've missed you — here's [X] free on us

> Hi [Name],
>
> It's been a while since you've used [App Name], and we've been busy making it better.
>
> Here's what's new:
> - [Feature 1]
> - [Feature 2]
> - [Feature 3]
>
> We'd love for you to come back and try it. Here's a code for [offer details]:
>
> **[CODE]**
>
> [Redemption instructions or direct link]
>
> This code expires [date].
>
> Welcome back,
> [Your name / App name]

#### For Social Media (Custom Code)
> [Emoji] Special offer! Use code **[CUSTOMCODE]** in the App Store to get
> [offer details] of [App Name] completely free.
>
> Redeem: [Link]
>
> Limited time — expires [date]. [Emoji]

## In-App Redemption

### Add Code Entry to Your App

```swift
import StoreKit

struct SettingsView: View {
    var body: some View {
        Button("Redeem Offer Code") {
            Task {
                try? await AppStore.presentOfferCodeRedeemSheet()
            }
        }
    }
}
```

## Measurement

| Metric | How to Track |
|--------|-------------|
| Codes distributed | Your distribution records |
| Codes redeemed | App Store Connect > Offer Codes |
| Redemption rate | Redeemed / Distributed |
| Post-offer retention | Retained after offer period ends |
| Conversion to paid | Continued subscription after offer |

## Campaign Calendar

| Month | Campaign | Codes | Channel |
|-------|----------|-------|---------|
| [Month] | [Campaign name] | [Count] | [Channel] |
```

## Distribution Strategies by Purpose

### Influencer Program
- **Scale**: 10-50 codes per quarter
- **Code type**: One-time use (track individual redemption)
- **Offer**: 3-6 months free (generous for genuine feedback)
- **Follow-up**: Request honest review 2 weeks after redemption
- **Tracking**: Spreadsheet mapping code → influencer → outcome

### Partner/Affiliate
- **Scale**: 100-1,000 codes per partner
- **Code type**: Custom code per partner ("PARTNER2025")
- **Offer**: 1-3 months free
- **Terms**: Clear agreement on promotion expectations
- **Tracking**: Unique custom code per partner for attribution

### Email Re-Engagement
- **Scale**: Match churned user count
- **Code type**: One-time use (unique per user)
- **Offer**: 1 month free (low barrier to return)
- **Timing**: 30-60 days after churn
- **Tracking**: Email open → Redemption → Retention

### Event/Conference
- **Scale**: Match expected attendees
- **Code type**: Custom code ("WWDC2025")
- **Offer**: 1-3 months free
- **Distribution**: QR code on slides/booth, printed cards
- **Tracking**: Post-event redemption monitoring

## References

- Related: `generators/subscription-offers` — StoreKit 2 offer implementation
- Related: `generators/win-back-offers` — Win-back campaign strategy
- Related: `app-store/marketing-strategy` — Overall promotional strategy
