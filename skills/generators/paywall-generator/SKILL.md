---
name: paywall-generator
description: Generates StoreKit 2 subscription paywall with modern SwiftUI views. Use when user wants to add subscriptions, paywall, or in-app purchases.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Paywall Generator

Generate a complete StoreKit 2 subscription paywall with modern SwiftUI views, subscription status tracking, and proper purchase handling.

## When This Skill Activates

Use this skill when the user:
- Asks to "add subscriptions" or "add paywall"
- Mentions "in-app purchases" or "IAP"
- Wants "StoreKit 2" implementation
- Asks about "subscription management"
- Mentions "premium features" or "pro version"

## Paywall Design Principles (Apple's Data)

- **Keep sign-up to 3-4 taps.** Per Apple's Tech Talk: 61% conversion at 3 taps, 48% at 4 — collapsing to 7% at 9 taps.
- **Make the paywall glanceable** — value proposition, price, and renewal/trial terms in one view, no scrolling to find the price.
- **Show clear renewal and trial terms everywhere you pitch** the subscription, not just on the paywall.
- **Persistent entry point over pop-ups** — a tasteful, always-available subscribe button (plus subscribe/manage in Settings). Pop-ups train users to dismiss.
- **Trigger the offer at moments of interest** — when the user taps locked content, not on a timer.
- **Offer 3-4 duration tiers** so users self-select their commitment level.
- **Let users experience value first** — free trial (works best for known brands), freemium, or content sampling (e.g., N free articles per month).

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing StoreKit implementations
- [ ] Check deployment target (StoreKit 2 requires iOS 15+)
- [ ] Look for existing product IDs in codebase
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing StoreKit:
```
Glob: **/*Store*.swift, **/*Purchase*.swift, **/*Subscription*.swift
Grep: "import StoreKit" or "Product.products"
```

If found, ask user:
- Replace existing implementation?
- Extend with additional features?

## Apple Docs Reference

**StoreKit subscription APIs (iOS 18.4+):**
- `SubscriptionOfferView` - New SwiftUI view for merchandising subscriptions
- `subscriptionStatusTask` modifier for tracking subscription state
- `Transaction.currentEntitlements(for:)` - per-product entitlement check (iOS 18.4+)
- `RenewalInfo` enhancements for expiration reasons

## Configuration Questions

Ask user via AskUserQuestion:

1. **Subscription tiers?** (multi-select)
   - Monthly
   - Yearly (with discount)
   - Lifetime
   - Weekly

2. **Features needed?**
   - Free trial
   - Family sharing
   - Promotional offers

3. **UI style?**
   - Full paywall screen
   - Inline subscription view
   - Both

## Generation Process

### Step 1: Create Core Files

Generate these files:
1. `StoreKitManager.swift` - Product loading and purchasing
2. `SubscriptionStatus.swift` - Status tracking
3. `PaywallView.swift` - Full paywall UI
4. `SubscriptionButton.swift` - Individual plan button

### Step 2: Create Configuration

- `Products.swift` - Product ID constants

### Step 3: Determine File Location

Check project structure:
- If `Sources/` exists → `Sources/Store/`
- If `App/` exists → `App/Store/`
- Otherwise → `Store/`

## Product ID Setup

### App Store Connect

1. Go to App Store Connect > Your App > Subscriptions
2. Create subscription group
3. Add subscription products with IDs like:
   - `com.yourapp.subscription.monthly`
   - `com.yourapp.subscription.yearly`
   - `com.yourapp.subscription.lifetime`

### StoreKit Configuration (Testing)

Create `Products.storekit` for local testing:
1. File > New > File > StoreKit Configuration
2. Add products matching your IDs
3. Edit scheme > Options > StoreKit Configuration

## Output Format

After generation, provide:

### Files Created
```
Sources/Store/
├── StoreKitManager.swift        # Product loading & purchasing
├── SubscriptionStatus.swift     # Status enum & tracking
├── Products.swift               # Product ID constants
└── Views/
    ├── PaywallView.swift        # Full paywall screen
    ├── SubscriptionButton.swift # Plan selection button
    └── SubscriptionOfferCard.swift # iOS 18.4+ view
```

### Integration Steps

**App Entry Point:**
```swift
@main
struct MyApp: App {
    @State private var subscriptionStatus: SubscriptionStatus = .unknown

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.subscriptionStatus, subscriptionStatus)
                .subscriptionStatusTask(for: "your.group.id") { statuses in
                    subscriptionStatus = SubscriptionStatus.from(statuses)
                }
        }
    }
}
```

**Show Paywall:**
```swift
struct ContentView: View {
    @State private var showPaywall = false
    @Environment(\.subscriptionStatus) var status

    var body: some View {
        VStack {
            if status != .subscribed {
                Button("Upgrade to Pro") {
                    showPaywall = true
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
```

**SubscriptionOfferView (iOS 18.4+):**
```swift
// Simple merchandising view
SubscriptionOfferView(productID: "com.app.subscription.monthly")
    .prefersPromotionalIcon(true)
    .subscriptionOfferViewDetailAction {
        showPaywall = true
    }
```

### Testing Instructions

1. **Create StoreKit Configuration:**
   - File > New > StoreKit Configuration
   - Add your products

2. **Edit Scheme:**
   - Product > Scheme > Edit Scheme
   - Options > StoreKit Configuration > Select your file

3. **Test Purchases:**
   - Run in Simulator
   - Use Transaction Manager (Debug > StoreKit > Transaction Manager)

4. **Test Scenarios:**
   - Purchase flow
   - Restore purchases
   - Subscription expiration
   - Renewal

## References

- **storekit-patterns.md** - Best practices and patterns
- **templates/** - All template files
- Apple Docs: StoreKit Updates (iOS 18.4+)
