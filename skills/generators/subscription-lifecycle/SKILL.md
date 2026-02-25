---
name: subscription-lifecycle
description: Generates StoreKit 2 subscription lifecycle management — grace periods, billing retry, offer codes, win-back offers, upgrade/downgrade paths, and subscription status monitoring. Use when user needs post-purchase subscription state handling beyond the initial paywall.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Subscription Lifecycle Generator

Generate production StoreKit 2 subscription lifecycle management with real-time status monitoring, grace period handling, billing retry detection, offer code redemption, win-back offers, and upgrade/downgrade path support.

**Different from paywall-generator:** The paywall generator handles the purchase UI and initial transaction. This skill handles everything that happens *after* purchase — monitoring subscription state changes, handling payment failures, retaining churning users, and managing tier transitions.

## When This Skill Activates

Use this skill when the user:
- Asks about "subscription management" or "subscription lifecycle"
- Mentions "grace period handling" or "grace period UI"
- Wants "billing retry" detection or payment failure handling
- Asks about "win-back offers" or "re-engagement offers"
- Mentions "subscription status" monitoring or dashboard
- Wants "upgrade/downgrade" path management
- Asks about "offer codes" or "promotional offers"
- Mentions "subscription churn" or "retention"
- Wants to "track subscription state changes"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (StoreKit 2 requires iOS 15+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Identify source file locations

### 2. Existing StoreKit Detection
Search for existing subscription code:
```
Glob: **/*Store*.swift, **/*Subscription*.swift, **/*Entitlement*.swift
Grep: "import StoreKit" or "Transaction.updates" or "Product.SubscriptionInfo"
```

If paywall-generator output found:
- Integrate with existing `StoreKitManager` — don't duplicate product loading
- Extend existing `SubscriptionStatus` enum if present
- Wire into existing transaction listener

If no existing StoreKit code found:
- Generate standalone — include minimal product loading
- Recommend running paywall-generator for purchase UI

### 3. Entitlement Check
```
Grep: "In-App Purchase" or "StoreKit" in *.entitlements
```
If missing, warn user to add the In-App Purchase capability in Xcode.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Subscription tiers?**
   - Single tier (one plan, e.g., "Pro")
   - Multiple tiers (e.g., "Basic", "Pro", "Business") with upgrade/downgrade paths

2. **Lifecycle features?** (multi-select)
   - Grace period detection and UI messaging
   - Billing retry period handling
   - Offer code redemption (App Store offer codes)
   - Win-back offers for expired subscribers
   - Upgrade/downgrade/crossgrade management

3. **Include subscription dashboard UI?**
   - Yes — SwiftUI view showing current plan, renewal date, management options
   - No — logic only, integrate into existing UI

4. **Server-side verification?**
   - Client-only (StoreKit 2 on-device verification) — recommended for most apps
   - Server-side (App Store Server API v2) — for apps with server backends

## Generation Process

### Step 1: Read Templates and Patterns
Read `patterns.md` for lifecycle state diagrams and StoreKit 2 behavior reference.
Read `templates.md` for production Swift code templates.

### Step 2: Create Core Files
Generate these files:
1. `SubscriptionState.swift` — Comprehensive enum for all lifecycle states
2. `SubscriptionMonitor.swift` — @Observable class monitoring real-time status via `Transaction.updates` and `Product.SubscriptionInfo`
3. `SubscriptionEntitlement.swift` — Maps product IDs to feature access levels

### Step 3: Create Lifecycle Handlers
Based on configuration:
4. `GracePeriodHandler.swift` — If grace period selected
5. `OfferManager.swift` — If offer codes or win-back selected

### Step 4: Create UI Files
If dashboard UI selected:
6. `SubscriptionDashboardView.swift` — SwiftUI view for plan management

### Step 5: Determine File Location
Check project structure:
- If `Sources/Store/` exists → `Sources/Store/Lifecycle/`
- If `Sources/` exists → `Sources/SubscriptionLifecycle/`
- If `App/` exists → `App/SubscriptionLifecycle/`
- Otherwise → `SubscriptionLifecycle/`

## Output Format

After generation, provide:

### Files Created
```
SubscriptionLifecycle/
├── SubscriptionState.swift           # All lifecycle states enum
├── SubscriptionMonitor.swift         # Real-time status monitoring
├── SubscriptionEntitlement.swift     # Product ID → feature mapping
├── GracePeriodHandler.swift          # Grace period detection & UI (optional)
├── OfferManager.swift                # Offers, codes, win-back (optional)
└── SubscriptionDashboardView.swift   # Plan management UI (optional)
```

### Integration with Existing Paywall

**If paywall-generator was already used:**
```swift
// In your existing StoreKitManager, add lifecycle monitoring
@Observable
final class StoreKitManager {
    // ... existing product loading and purchase code ...

    let lifecycleMonitor = SubscriptionMonitor()

    func startMonitoring() async {
        await lifecycleMonitor.start(
            groupID: "your.subscription.group",
            entitlements: SubscriptionEntitlement.default
        )
    }
}
```

**App Entry Point:**
```swift
@main
struct MyApp: App {
    @State private var monitor = SubscriptionMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(monitor)
                .task { await monitor.start(groupID: "your.group.id") }
        }
    }
}
```

**Check Access Anywhere:**
```swift
struct PremiumFeatureView: View {
    @Environment(SubscriptionMonitor.self) private var monitor

    var body: some View {
        if monitor.hasAccess {
            // Full feature
            PremiumContent()
        } else if monitor.state == .inGracePeriod {
            // Feature still accessible, but show payment warning
            VStack {
                PaymentWarningBanner()
                PremiumContent()
            }
        } else {
            // Show paywall
            PaywallView()
        }
    }
}
```

**Grace Period Notification:**
```swift
struct ContentView: View {
    @Environment(SubscriptionMonitor.self) private var monitor

    var body: some View {
        NavigationStack {
            MainContent()
                .overlay(alignment: .top) {
                    if monitor.state == .inGracePeriod {
                        GracePeriodBanner(
                            daysRemaining: monitor.gracePeriodDaysRemaining,
                            onFixPayment: { /* open manage subscriptions */ }
                        )
                    }
                }
        }
    }
}
```

**Win-Back Offer:**
```swift
struct ExpiredUserView: View {
    @State private var offerManager = OfferManager()

    var body: some View {
        if let winBackOffer = offerManager.availableWinBackOffer {
            WinBackOfferCard(offer: winBackOffer) {
                try await offerManager.redeemWinBackOffer(winBackOffer)
            }
        } else {
            StandardPaywallView()
        }
    }
}
```

### Testing

```swift
@Test
func gracePeriodGrantsAccess() async throws {
    let monitor = SubscriptionMonitor()
    monitor.updateState(.inGracePeriod(expiresIn: 3))

    #expect(monitor.hasAccess == true)
    #expect(monitor.gracePeriodDaysRemaining == 3)
}

@Test
func billingRetryGrantsAccess() async throws {
    let monitor = SubscriptionMonitor()
    monitor.updateState(.inBillingRetry)

    #expect(monitor.hasAccess == true)
    #expect(monitor.shouldShowPaymentWarning == true)
}

@Test
func expiredRevokesAccess() async throws {
    let monitor = SubscriptionMonitor()
    monitor.updateState(.expired(reason: .autoRenewDisabled))

    #expect(monitor.hasAccess == false)
}

@Test
func upgradeChangesEntitlementLevel() async throws {
    let entitlements = SubscriptionEntitlement.default
    let basicLevel = entitlements.accessLevel(for: "com.app.basic.monthly")
    let proLevel = entitlements.accessLevel(for: "com.app.pro.monthly")

    #expect(proLevel > basicLevel)
}
```

## Common Patterns

### Status Checking
```swift
// Check current subscription state
let state = monitor.state
switch state {
case .active(let renewalDate):
    print("Active until \(renewalDate)")
case .inGracePeriod(let expiresIn):
    print("Payment issue — \(expiresIn) days to fix")
case .inBillingRetry:
    print("Apple retrying payment")
case .expired(let reason):
    print("Expired: \(reason)")
case .revoked:
    print("Refunded or revoked")
default:
    break
}
```

### Grace Period Notification
```swift
// Show in-app banner during grace period
if case .inGracePeriod(let days) = monitor.state {
    Banner(
        message: "Payment issue. Update payment method within \(days) days.",
        action: "Fix Now",
        onTap: { await openSubscriptionManagement() }
    )
}
```

### Offer Code Redemption
```swift
// Present the system offer code redemption sheet
try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
```

### Tier Upgrade
```swift
// Upgrade from Basic to Pro (takes effect immediately)
let proProduct = try await Product.products(for: ["com.app.pro.monthly"]).first!
let result = try await proProduct.purchase()
// StoreKit handles prorating automatically
```

## Gotchas

### Transaction.currentEntitlements vs Product.SubscriptionInfo.status
- `Transaction.currentEntitlements` — Returns currently active transactions. Use for checking if user has access RIGHT NOW. Does not include grace period or billing retry details.
- `Product.SubscriptionInfo.status` — Returns detailed subscription status array including grace period state, billing retry, renewal info. Use for lifecycle management and showing appropriate UI.
- **Rule:** Use `currentEntitlements` for simple access checks. Use `SubscriptionInfo.status` for lifecycle state handling.

### Grace Period vs Billing Retry Period
- **Grace period** (if enabled in App Store Connect): User retains access for 6 or 16 days after payment failure. Apple shows its own payment failure messaging.
- **Billing retry period**: After grace period expires (or if no grace period), Apple retries billing for up to 60 days. User access depends on your app's policy.
- **Important:** Both `.inGracePeriod` and `.inBillingRetryPeriod` should typically grant continued access to reduce involuntary churn.

### Sandbox vs Production Testing
- Sandbox subscriptions renew at accelerated rates (monthly = ~5 minutes)
- Sandbox does not support all offer types
- `Transaction.environment` tells you if you're in sandbox, production, or Xcode
- Grace periods behave differently in sandbox — shorter durations
- Always test with StoreKit Testing in Xcode first, then sandbox, then TestFlight

### Offer Eligibility
- **Introductory offers:** Only for users who have never subscribed to any product in the subscription group
- **Promotional offers:** Require signing with your App Store Connect key; you control eligibility
- **Offer codes:** One-time use codes you generate in App Store Connect; limited to 10M per app per quarter
- **Win-back offers (iOS 18+):** Apple determines eligibility for lapsed subscribers; you configure in App Store Connect

### Transaction.finish() is Critical
Never forget to call `transaction.finish()`. Unfinished transactions will be re-delivered on every app launch, causing duplicate processing and potential UI glitches.

## References

- **templates.md** — All production Swift code templates
- **patterns.md** — Lifecycle state diagrams, StoreKit 2 behavior reference, anti-patterns
- Related: `generators/paywall-generator` — Purchase UI and initial transaction handling
- Related: `monetization/monetization-strategy` — Pricing tiers and revenue planning
