---
name: promoted-iap
description: Generates Promoted In-App Purchase setup with StoreKit 2 product configuration, paywall integration, and App Store product page display. Use when setting up promoted purchases that appear on the App Store product page.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Promoted In-App Purchases Generator

Set up promoted In-App Purchases so your premium offerings appear directly on your App Store product page, in search results, and in editorial features.

## When This Skill Activates

Use this skill when the user:
- Asks to "promote IAP" or "show purchase on product page"
- Mentions "promoted in-app purchase" or "App Store product page IAP"
- Wants subscription/IAP visible in App Store search results
- Asks about `paymentQueue(_:shouldAddStorePayment:for:)`
- Wants to handle purchases initiated from the App Store

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing StoreKit implementation
- [ ] Check deployment target (iOS 15+ for StoreKit 2)
- [ ] Look for existing IAP product definitions
- [ ] Check if `paywall-generator` was already used

### 2. Conflict Detection
```
Glob: **/*Promoted*.swift, **/*StorePayment*.swift
Grep: "shouldAddStorePayment" or "PurchaseIntent" or "promotedPurchase"
```

## How Promoted IAP Works

1. **App Store Connect**: Mark IAP products as "Promoted" with promotional image
2. **Product Page**: Up to 20 promoted IAPs appear on your product page
3. **Search Results**: Promoted IAPs can appear in search
4. **User Action**: User taps "Buy" on App Store → your app opens to complete purchase
5. **Your App**: Must handle the incoming purchase intent

### Promoted IAP Display Order
- You control the order in App Store Connect
- Choose your most compelling IAP as the first promoted product
- Apple may also feature your IAPs in editorial content

## Configuration Questions

Ask user via AskUserQuestion:

1. **What type of IAP to promote?**
   - Auto-renewable subscription
   - Non-consumable (one-time unlock)
   - Consumable (credits/tokens)

2. **How to handle App Store-initiated purchases?**
   - Show immediately (direct purchase)
   - Show paywall first (let user see options before buying)
   - Show onboarding then purchase (new users from App Store)

3. **Number of promoted products?**
   - Single product
   - Multiple products (2-5)
   - Full catalog (6+)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for promoted IAP implementation code.

### Step 2: Create Core Files

1. **PromotedPurchaseHandler.swift** — Handle purchases initiated from App Store
2. **PromotedProductConfiguration.swift** — Product definitions and promotional images specs
3. **PromotedPurchaseFlowView.swift** — UI for completing promoted purchases in-app

### Step 3: Determine File Location
```
- If Sources/Store/ exists → Sources/Store/Promoted/
- If Store/ exists → Store/Promoted/
- Otherwise → Store/Promoted/
```

## Output Format

### Files Created
```
Store/Promoted/
├── PromotedPurchaseHandler.swift        # App Store purchase handling
├── PromotedProductConfiguration.swift   # Product setup & image specs
└── PromotedPurchaseFlowView.swift       # In-app purchase completion UI
```

### Integration Steps

**Handle App Store-Initiated Purchases (StoreKit 2):**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Listen for purchases initiated from App Store
                    for await purchaseIntent in PurchaseIntent.intents {
                        await PromotedPurchaseHandler.shared.handle(purchaseIntent)
                    }
                }
        }
    }
}
```

**Complete the Purchase:**
```swift
// PromotedPurchaseHandler determines the right flow:
// 1. Direct purchase (existing user, known product)
// 2. Paywall (show options first)
// 3. Onboarding (new user from App Store)
```

### App Store Connect Setup

1. Go to App Store Connect > Your App > In-App Purchases
2. Select the IAP product
3. Under "App Store Promotion":
   - Upload promotional image (1024x1024, no alpha, no rounded corners)
   - Set display order
   - Enable promotion
4. Repeat for each product you want to promote

### Promotional Image Requirements
- **Size**: 1024 x 1024 pixels
- **Format**: PNG or JPEG, no transparency
- **Content**: Feature the product value, not just the app icon
- **Text**: Minimal — the product name appears separately
- **Style**: Match your app's visual identity

### Testing Instructions

1. **StoreKit Configuration**: Add promoted products to your .storekit file
2. **Test purchase flow**: Simulate App Store-initiated purchase
3. **Test user states**: New user, existing free user, existing subscriber
4. **Verify UI**: Purchase completion view looks correct for each product type

## References

- **templates.md** — Production Swift templates
- Related: `generators/paywall-generator` — Full paywall for purchase completion
- Related: `generators/subscription-offers` — Offer types for promoted subscriptions
- Related: `app-store/marketing-strategy` — Strategic product promotion planning
