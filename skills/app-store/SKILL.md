---
name: app-store
description: App Store optimization and marketing skills for descriptions, screenshots, keywords, review responses, and comprehensive promotional strategy. Use when user needs help with App Store presence, ASO, marketing, or customer communication.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, WebSearch]
---

# App Store Optimization & Marketing Skills

Skills for optimizing your app's App Store presence and building promotional strategies — from descriptions to comprehensive marketing campaigns.

## When This Skill Activates

Use this skill when the user:
- Needs to write App Store description or promotional text
- Wants to plan screenshot sequence and captions
- Asks about ASO (App Store Optimization) or keywords
- Needs help responding to App Store reviews
- Wants to improve app discoverability
- Asks about marketing strategy, promotion, or user acquisition
- Wants to use App Store features (events, custom pages, offers, featuring)
- Asks about paid acquisition or Apple Search Ads
- App was rejected or wants to avoid rejection

## Available Skills

### marketing-strategy/ ⭐ NEW
Comprehensive marketing strategy advisor — describe your app and get a tailored promotional plan.
- Analyzes app type, monetization model, audience, and lifecycle stage
- Recommends the right App Store features for your situation
- Builds promotional calendar with implementation roadmap
- Orchestrates generator sub-skills for implementation
- Strategy templates for subscription, paid, freemium, and game apps

### app-description-writer/
Generate compelling App Store descriptions that convert.
- Promotional text (170 chars)
- Full description (4000 chars)
- What's New text for updates
- Localization guidance

### screenshot-planner/
Plan App Store screenshot sequences with captions.
- 5-10 screenshot storyboard
- Caption writing
- Device frame recommendations
- Localization considerations

### keyword-optimizer/
Optimize app title, subtitle, and keywords for search.
- Keyword research methodology
- Character limit optimization (100 chars)
- Competitor analysis
- Localization keyword strategy
- **NEW:** Advanced tactics (cross-localization, screenshot indexing)
- **NEW:** Keyword criteria (Pop/Diff sweet spots, opportunity scoring)
- **NEW:** Existing app strategy (safe optimization)

### review-response-writer/
Professional responses to App Store reviews.
- Templates for common scenarios
- Tone and brand voice guidelines
- Turning negative reviews into opportunities
- When to respond vs. when not to

### apple-search-ads/
Apple Search Ads campaign strategy for indie developers.
- Readiness assessment (minimum thresholds before spending)
- Campaign types and keyword strategy
- Budget planning by app stage (launch, growth, scale)
- Bid optimization with CPT benchmarks by category
- Campaign structure templates and measurement KPIs
- Custom Product Pages integration for ad groups

### rejection-handler/
Handle App Store rejections and prepare submissions to avoid them.
- Pre-submission audit checklist by guideline section
- Rejection analysis and response strategy
- Resolution Center response templates
- Appeal escalation path (Resolution Center → phone → App Review Board)
- Top 20 common rejections with fixes (common-rejections.md)

## Related Generator Skills

These generator skills produce code, metadata, and configuration for App Store features:

| Skill | Purpose |
|-------|---------|
| `generators/subscription-offers` | StoreKit 2 code for all subscription offer types |
| `generators/win-back-offers` | Win-back flow for churned subscribers |
| `generators/promoted-iap` | Promoted In-App Purchase setup |
| `generators/in-app-events` | In-App Event metadata templates |
| `generators/custom-product-pages` | Custom Product Page strategy and metadata |
| `generators/product-page-optimization` | A/B test plans for product page |
| `generators/featuring-nomination` | App Store featuring pitch templates |
| `generators/offer-codes-setup` | Offer code distribution strategies |
| `generators/pre-orders` | Pre-order setup and launch timelines |
| `generators/app-store-assets` | Asset specs for all App Store media |

## How to Use

1. User requests App Store help
2. For strategy questions → Read `marketing-strategy/SKILL.md`
3. For paid acquisition → Read `apple-search-ads/SKILL.md`
4. For rejections or submission prep → Read `rejection-handler/SKILL.md`
5. For specific content → Read the relevant sub-skill's SKILL.md
6. For code/implementation → Read the relevant generator skill
7. Ask clarifying questions about the app
8. Generate optimized content
9. Provide alternatives and explain choices

## Key Principles

### 1. User-Focused Copy
- Lead with benefits, not features
- Speak to user pain points
- Use clear, simple language
- Include social proof where possible

### 2. Platform Guidelines
- Stay within character limits
- Follow Apple's content guidelines
- Avoid prohibited terms (free, best, #1)
- Don't mention competing platforms

### 3. Search Optimization
- Use high-value keywords naturally
- Don't stuff keywords
- Consider localized search terms
- Update for seasonal relevance
