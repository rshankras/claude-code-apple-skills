---
name: subscription-offers
description: Generates StoreKit 2 code for all subscription offer types — introductory, promotional, offer codes, and win-back. Includes eligibility checks, offer presentation, and the preferredSubscriptionOffer modifier. Use when adding subscription offers, free trials, or promotional pricing.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Subscription Offers Generator

Generate complete StoreKit 2 implementation for all four subscription offer types with eligibility verification, offer presentation, and transaction handling.

## When This Skill Activates

Use this skill when the user:
- Asks to "add subscription offers" or "set up free trial"
- Mentions "introductory offer", "promotional offer", or "offer codes"
- Wants "StoreKit 2 offers" implementation
- Asks about "subscription pricing" or "discounted subscription"
- Mentions "preferredSubscriptionOffer" or "eligibility check"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing StoreKit implementations (`import StoreKit`)
- [ ] Check deployment target (iOS 16.4+ for `SubscriptionStoreView` offers, iOS 15+ for manual)
- [ ] Look for existing product/subscription group IDs
- [ ] Identify if `paywall-generator` was already used

### 2. Conflict Detection
```
Glob: **/*Offer*.swift, **/*Eligibility*.swift
Grep: "introductoryOffer" or "promotionalOffers" or "winBackOffers"
```

If existing offer code found, ask:
- Extend with additional offer types?
- Replace existing implementation?

## Offer Types Reference

### 1. Introductory Offers
- **Who**: New subscribers who haven't previously subscribed
- **Types**: Free trial, pay-as-you-go, pay-up-front
- **Limit**: One per subscription group per Apple ID
- **StoreKit 2**: `product.subscription?.introductoryOffer`

### 2. Promotional Offers
- **Who**: Current or lapsed subscribers (you control eligibility)
- **Types**: Free, pay-as-you-go, pay-up-front
- **Limit**: Up to 10 per subscription group
- **Requires**: Server-side signature generation
- **StoreKit 2**: `product.subscription?.promotionalOffers`

### 3. Offer Codes
- **Who**: Anyone with a valid code (you distribute)
- **Types**: Free or discounted period
- **Limit**: Configurable per campaign in App Store Connect
- **StoreKit 2**: `try await AppStore.presentOfferCodeRedeemSheet()`

### 4. Win-Back Offers
- **Who**: Previously subscribed users who churned
- **Types**: Free or discounted period
- **Eligibility**: Automatic via App Store (iOS 18+)
- **StoreKit 2**: `product.subscription?.winBackOffers`

## Configuration Questions

Ask user via AskUserQuestion:

1. **Which offer types?** (multi-select)
   - Introductory offer (free trial / discounted first period)
   - Promotional offers (targeted discounts for eligible users)
   - Offer codes (redeemable codes you distribute)
   - Win-back offers (re-engage churned subscribers)

2. **Introductory offer details** (if selected)
   - Free trial: 3 days / 7 days / 14 days / 30 days
   - Pay-as-you-go: discounted rate for X periods
   - Pay-up-front: discounted rate for full period

3. **Deployment target**
   - iOS 15+ (manual offer UI)
   - iOS 16.4+ (SubscriptionStoreView with offers)
   - iOS 18+ (win-back offer support)

4. **Server-side signature** (if promotional offers selected)
   - Will you generate signatures server-side?
   - Use App Store Server Library?

## Generation Process

### Step 1: Read Templates
Read `templates.md` for all offer implementation code.

### Step 2: Create Core Files

1. **SubscriptionOfferManager.swift** — Central offer management
   - Offer eligibility checking for all types
   - Offer presentation logic
   - Transaction handling for offer purchases

2. **OfferEligibility.swift** — Eligibility verification
   - Introductory offer eligibility (`isEligibleForIntroOffer`)
   - Promotional offer eligibility (your business logic)
   - Win-back offer eligibility (iOS 18+)

3. **OfferConfiguration.swift** — Offer type definitions and configuration

### Step 3: Create UI Files (conditional)

4. **OfferBannerView.swift** — Contextual offer banners
   - Shows appropriate offer based on user state
   - Introductory offer for new users
   - Promotional offer for at-risk subscribers
   - Win-back offer for churned subscribers

5. **OfferCodeRedemptionView.swift** — Offer code entry UI (if offer codes selected)

### Step 4: Create Optional Files

6. **OfferSignatureProvider.swift** — Server-side signature handling (if promotional offers)
7. **OfferAnalytics.swift** — Track offer impression, tap, and conversion events

### Step 5: Determine File Location
```
- If Sources/Store/ exists → Sources/Store/Offers/
- If Store/ exists → Store/Offers/
- If Subscriptions/ exists → Subscriptions/Offers/
- Otherwise → Offers/
```

## Output Format

### Files Created
```
Store/Offers/
├── SubscriptionOfferManager.swift    # Central offer management
├── OfferEligibility.swift            # Eligibility verification
├── OfferConfiguration.swift          # Offer type definitions
├── OfferBannerView.swift             # Contextual offer UI
├── OfferCodeRedemptionView.swift     # Code entry (optional)
├── OfferSignatureProvider.swift      # Server signatures (optional)
└── OfferAnalytics.swift              # Offer tracking (optional)
```

### Integration Steps

**Check Introductory Offer Eligibility:**
```swift
let manager = SubscriptionOfferManager()
let isEligible = await manager.isEligibleForIntroOffer(
    productID: "com.app.subscription.monthly"
)
```

**Present Best Available Offer:**
```swift
// Automatically selects the best offer for the user's state
let offer = await manager.bestAvailableOffer(
    for: "com.app.subscription.monthly"
)

// Use with SubscriptionStoreView (iOS 16.4+)
SubscriptionStoreView(groupID: groupID)
    .preferredSubscriptionOffer(offer)
```

**Present Offer Code Sheet:**
```swift
// iOS 16+
try await AppStore.presentOfferCodeRedeemSheet()
```

**Win-Back Offer (iOS 18+):**
```swift
let winBackOffers = await manager.availableWinBackOffers(
    for: "com.app.subscription.monthly"
)
if let bestOffer = winBackOffers.first {
    // Present win-back UI
}
```

### Testing Instructions

1. **StoreKit Configuration file**: Add offer configurations
2. **Test each offer type** in Sandbox environment
3. **Verify eligibility logic**: Test with new, current, and lapsed accounts
4. **Test edge cases**: Expired trials, multiple subscription groups, family sharing

### App Store Connect Setup

1. Go to App Store Connect > Subscriptions > Your Group
2. **Introductory Offer**: Set in subscription pricing section
3. **Promotional Offers**: Create under "Subscription Prices" > "Promotional Offers"
4. **Offer Codes**: Create under "Offer Codes" tab
5. **Win-Back Offers**: Configure under "Win-Back Offers" (iOS 18+)

## References

- **templates.md** — All production Swift templates
- Related: `generators/win-back-offers` — Dedicated win-back flow skill
- Related: `generators/paywall-generator` — Full paywall with offer integration
- Related: `app-store/marketing-strategy` — Strategic offer planning
