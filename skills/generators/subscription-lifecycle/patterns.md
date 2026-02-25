# Subscription Lifecycle Patterns and Best Practices

## Subscription Lifecycle States

### State Diagram

```
                    ┌─────────────────────────────────────┐
                    │           PURCHASE                    │
                    │    (via paywall-generator)            │
                    └──────────────┬──────────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────┐
                    │         ACTIVE            │◄──── Renewal succeeds
                    │  (subscribed state)       │◄──── Upgrade/downgrade
                    └──────────┬───────────────┘
                               │
                    Payment fails at renewal
                               │
                    ┌──────────▼───────────────┐
                    │     GRACE PERIOD          │
                    │  (6 or 16 days)           │──── User still has access
                    │  Apple shows payment UI   │──── Payment succeeds → ACTIVE
                    └──────────┬───────────────┘
                               │
                    Grace period expires,
                    payment still failing
                               │
                    ┌──────────▼───────────────┐
                    │    BILLING RETRY          │
                    │  (up to 60 days)          │──── Access at app's discretion
                    │  Apple retries billing    │──── Payment succeeds → ACTIVE
                    └──────────┬───────────────┘
                               │
                    Retry period expires
                    OR user cancels
                               │
                    ┌──────────▼───────────────┐
                    │        EXPIRED            │
                    │  No access                │──── Win-back offer eligible
                    │  Reason tracked           │──── Can resubscribe
                    └──────────┬───────────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
    ┌──────▼─────┐     ┌──────▼─────┐     ┌──────▼─────┐
    │  REVOKED   │     │  User      │     │  Win-back  │
    │  (refund)  │     │  resubsc.  │     │  offer     │
    │  No access │     │  → ACTIVE  │     │  → ACTIVE  │
    └────────────┘     └────────────┘     └────────────┘
```

### State Transitions Summary

| From | To | Trigger | User Access |
|------|----|---------|-------------|
| Active | Grace Period | Payment fails at renewal | Yes |
| Active | Expired | User disables auto-renew | Yes (until period ends) |
| Active | Upgraded | User upgrades tier | Yes (new tier) |
| Grace Period | Active | Payment succeeds | Yes |
| Grace Period | Billing Retry | Grace period expires | Recommended: Yes |
| Billing Retry | Active | Payment succeeds | Recommended: Yes |
| Billing Retry | Expired | Retry period expires | No |
| Expired | Active | User resubscribes | Yes |
| Any | Revoked | Apple issues refund | No |

## Grace Period vs Billing Retry Period

### Grace Period

- **Duration:** 6 or 16 days (you choose in App Store Connect)
- **Configuration:** App Store Connect > App > Subscriptions > Subscription Group > Billing Grace Period
- **Apple behavior:** Apple shows payment failure messaging to the user automatically
- **User access:** Apple expects you to grant full access during this period
- **Detection:** `Product.SubscriptionInfo.Status.state == .inGracePeriod`
- **Best practice:** Always grant access. Show a subtle in-app banner encouraging payment update.

### Billing Retry Period

- **Duration:** Up to 60 days after grace period (or after initial failure if no grace period)
- **Configuration:** Automatic — Apple retries on their own schedule
- **Apple behavior:** Apple sends push notifications about failed payment
- **User access:** Your decision. Recommended: grant access to reduce involuntary churn.
- **Detection:** `Product.SubscriptionInfo.Status.state == .inBillingRetryPeriod`
- **Best practice:** Grant access but show more prominent payment warning than grace period.

### Timeline

```
Payment Fails
    │
    ├── Day 0-6/16: GRACE PERIOD (if enabled)
    │   └── Full access, Apple shows payment UI
    │
    ├── Day 6/16 - Day 60: BILLING RETRY
    │   └── Access recommended, Apple retries billing
    │
    └── Day 60+: EXPIRED
        └── No access, eligible for win-back
```

## When to Use Transaction.currentEntitlements vs Product.SubscriptionInfo.status

### Transaction.currentEntitlements

```swift
// Simple access check: "Does this user have access right now?"
for await result in Transaction.currentEntitlements {
    if case .verified(let transaction) = result {
        if transaction.productType == .autoRenewable {
            grantAccess()
        }
    }
}
```

**Use when:**
- You need a simple yes/no access check
- Checking entitlements at app launch
- Gating features behind a subscription
- You don't need to know WHY the user has access

**Limitations:**
- Does NOT tell you if user is in grace period vs active
- Does NOT provide renewal info or expiration reasons
- Returns transactions, not subscription state

### Product.SubscriptionInfo.status

```swift
// Detailed lifecycle state: "What exact state is this subscription in?"
let statuses = try await Product.SubscriptionInfo.status(for: groupID)
for status in statuses {
    switch status.state {
    case .subscribed: handleActive(status)
    case .inGracePeriod: handleGracePeriod(status)
    case .inBillingRetryPeriod: handleBillingRetry(status)
    case .expired: handleExpired(status)
    case .revoked: handleRevoked(status)
    default: break
    }
}
```

**Use when:**
- Building a subscription dashboard
- Showing lifecycle-aware UI (grace period banners, billing retry warnings)
- Determining eligibility for offers
- Tracking renewal info and expiration reasons
- Managing upgrade/downgrade paths

**Decision matrix:**

| Need | Use |
|------|-----|
| "Can user access feature X?" | `Transaction.currentEntitlements` |
| "Is user in grace period?" | `Product.SubscriptionInfo.status` |
| "Why did subscription expire?" | `Product.SubscriptionInfo.status` + `renewalInfo` |
| "What plan is user on?" | Either (both provide product ID) |
| "When does subscription renew?" | `Product.SubscriptionInfo.status` |
| "Simple entitlement gate" | `Transaction.currentEntitlements` |

## Offer Types and Eligibility

### Introductory Offers

- **What:** First-time subscriber discount (free trial, pay-up-front, pay-as-you-go)
- **Eligibility:** Users who have NEVER subscribed to ANY product in the subscription group
- **Configuration:** App Store Connect per product
- **Detection:**
```swift
let isEligible = await product.subscription?.isEligibleForIntroOffer ?? false
```
- **Limit:** One per subscription group per Apple ID, ever

### Promotional Offers

- **What:** Discounts for existing or lapsed subscribers
- **Eligibility:** You control — determine on your server who should see offers
- **Configuration:** App Store Connect per product + server-side signing
- **Signing required:** Yes — generate signature with your App Store Connect API key
- **Use cases:** Retention (about to churn), win-back (already churned), loyalty (long-time subscriber)

```swift
// Server generates signed offer, client applies it
let signedOffer = Product.PurchaseOption.promotionalOffer(
    offerID: "retention_50_off",
    keyID: "YOUR_KEY_ID",
    nonce: nonce,
    signature: serverSignature,
    timestamp: timestamp
)
let result = try await product.purchase(options: [signedOffer])
```

### Offer Codes

- **What:** One-time use codes you generate in App Store Connect
- **Eligibility:** Anyone with a valid code (new or existing subscribers)
- **Configuration:** App Store Connect > Subscriptions > Offer Codes
- **Limit:** 10 million codes per app per quarter
- **Redemption:**
```swift
// Present system redemption sheet
try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
```
- **Use cases:** Marketing campaigns, partnerships, customer support

### Win-Back Offers (iOS 18+)

- **What:** Special offers for users whose subscription has expired
- **Eligibility:** Apple determines automatically based on subscription history
- **Configuration:** App Store Connect > Subscriptions > Win-Back Offers
- **Detection:** Available through `Product.SubscriptionOffer` on the product
- **Apple behavior:** Apple may show offers in the App Store automatically
- **Use cases:** Re-engaging lapsed subscribers

### Eligibility Summary

| Offer Type | New Users | Active Subscribers | Lapsed Subscribers | Server Signing |
|-----------|-----------|-------------------|-------------------|---------------|
| Introductory | Yes (first time only) | No | No | No |
| Promotional | Your choice | Your choice | Your choice | Yes |
| Offer Codes | Yes | Yes | Yes | No |
| Win-Back | No | No | Yes (Apple decides) | No |

## Upgrade/Downgrade/Crossgrade Behavior

### How Tier Changes Work

StoreKit handles tier changes within a subscription group automatically:

| Change Type | When It Takes Effect | Billing |
|------------|---------------------|---------|
| **Upgrade** | Immediately | Prorated credit for remaining time |
| **Downgrade** | Next renewal date | Current tier continues until renewal |
| **Crossgrade** (same level) | Next renewal date | Current plan continues until renewal |

### Tier Ranking in App Store Connect

You define tier ranking in App Store Connect:
- Level 1 = highest (e.g., Business)
- Level 2 = next (e.g., Pro)
- Level 3 = next (e.g., Basic)

Moving from Level 3 to Level 1 = upgrade (immediate).
Moving from Level 1 to Level 3 = downgrade (next renewal).

### Handling in Code

```swift
// Detect upgrade/downgrade
func handleTierChange(from currentProductID: String, to newProductID: String) {
    let entitlements = SubscriptionEntitlement.default
    let change = entitlements.tierChange(from: currentProductID, to: newProductID)

    switch change {
    case .upgrade:
        // Takes effect immediately after purchase
        // Update UI right away
        refreshEntitlements()

    case .downgrade:
        // Won't take effect until next renewal
        // Show message: "Your plan will change to X on [renewal date]"
        showPendingDowngradeMessage(newProductID: newProductID)

    case .crossgrade:
        // Same tier, different period (e.g., monthly → yearly)
        // Takes effect at next renewal
        showPendingCrossgradeMessage(newProductID: newProductID)
    }
}
```

### Pending Downgrades

When a user downgrades, they keep their current tier until renewal. Check `renewalInfo` for pending changes:

```swift
if let renewalInfo = status.renewalInfo,
   case .verified(let info) = renewalInfo {
    if info.currentProductID != info.autoRenewPreference {
        // There's a pending tier change
        let pendingProductID = info.autoRenewPreference
        showPendingChangeNotice(to: pendingProductID)
    }
}
```

## Server-Side Verification with App Store Server API v2

### When You Need Server-Side

- Apps with server backends that gate features server-side
- High-value subscriptions requiring additional security
- Cross-platform apps (iOS + web + Android) sharing subscription state
- Compliance requirements for receipt validation

### App Store Server API v2 Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /inApps/v1/subscriptions/{transactionId}` | Get subscription status |
| `GET /inApps/v1/history/{transactionId}` | Get transaction history |
| `POST /inApps/v1/notifications/test` | Test server notifications |
| `GET /inApps/v2/refund/lookup/{transactionId}` | Check refund status |

### App Store Server Notifications V2

Configure in App Store Connect to receive real-time webhook notifications:

| Notification | When |
|-------------|------|
| `SUBSCRIBED` | New subscription or resubscription |
| `DID_RENEW` | Successful auto-renewal |
| `DID_FAIL_TO_RENEW` | Renewal payment failed |
| `GRACE_PERIOD_EXPIRED` | Grace period ended without payment |
| `EXPIRED` | Subscription expired |
| `REFUND` | Apple issued a refund |
| `OFFER_REDEEMED` | User redeemed an offer or code |
| `PRICE_INCREASE` | Consent needed for price increase |

### Signed Transaction (JWS)

StoreKit 2 transactions are signed as JWS (JSON Web Signature). Verify on your server:

```
// JWS structure
Header.Payload.Signature

// Verify using Apple's root certificate chain
// Apple provides a certificate chain in the x5c header
```

## Sandbox vs Production Testing Differences

### Subscription Renewal Timing

| Period | Production | Sandbox | StoreKit Testing (Xcode) |
|--------|-----------|---------|--------------------------|
| 1 week | 7 days | 3 minutes | Configurable |
| 1 month | ~30 days | 5 minutes | Configurable |
| 2 months | ~60 days | 10 minutes | Configurable |
| 3 months | ~90 days | 15 minutes | Configurable |
| 6 months | ~180 days | 30 minutes | Configurable |
| 1 year | 365 days | 1 hour | Configurable |

### Sandbox Limitations

- Subscriptions auto-renew a maximum of **6 times** in sandbox (then expire)
- Grace period durations are shorter (proportional to accelerated time)
- Not all offer types are fully testable
- Sandbox Apple IDs are separate from production Apple IDs
- Payment sheet shows "[Environment: Sandbox]" text

### StoreKit Testing in Xcode (Recommended for Development)

- Fully local — no App Store Connect required
- Configurable renewal rates
- Transaction Manager for simulating states
- Can simulate: failed transactions, ask-to-buy, interrupted purchases
- **Best for:** Unit tests, UI development, rapid iteration

### Testing Strategy

```
1. StoreKit Testing in Xcode    → Development & unit tests
2. Sandbox                       → Integration testing
3. TestFlight (sandbox)          → Beta testing
4. Production                    → Release
```

### Detecting Environment

```swift
// Check transaction environment
for await result in Transaction.currentEntitlements {
    if case .verified(let transaction) = result {
        switch transaction.environment {
        case .xcode:
            print("StoreKit Testing in Xcode")
        case .sandbox:
            print("Sandbox environment")
        case .production:
            print("Production")
        default:
            break
        }
    }
}
```

## Common Anti-Patterns

### Don't Check Receipt File Directly

```swift
// Bad — StoreKit 1 pattern, fragile
if let receiptURL = Bundle.main.appStoreReceiptURL,
   let receiptData = try? Data(contentsOf: receiptURL) {
    // Parse ASN.1... this is painful and error-prone
}

// Good — StoreKit 2 handles verification
for await result in Transaction.currentEntitlements {
    if case .verified(let transaction) = result {
        // Already verified by StoreKit
    }
}
```

### Don't Forget to Handle Revocation

```swift
// Bad — only checks if active, ignores refunds
if hasActiveTransaction { grantAccess() }

// Good — explicitly handle revocation
switch status.state {
case .subscribed: grantAccess()
case .revoked: revokeAccess(); showRefundMessage()
// ... other states
}
```

### Don't Treat Grace Period as Expired

```swift
// Bad — user loses access during grace period → involuntary churn
if status.state != .subscribed {
    revokeAccess()
}

// Good — grant access during grace period and billing retry
switch status.state {
case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
    grantAccess()
case .expired, .revoked:
    revokeAccess()
}
```

### Don't Poll for Status Changes

```swift
// Bad — wasteful polling
Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
    Task { await checkSubscriptionStatus() }
}

// Good — listen for real-time updates
Task.detached {
    for await result in Transaction.updates {
        if case .verified(let transaction) = result {
            await transaction.finish()
            await refreshStatus()
        }
    }
}
```

### Don't Ignore Pending Tier Changes

```swift
// Bad — shows current tier without mentioning pending change
Text("Your plan: Pro")

// Good — inform user about upcoming change
if pendingDowngrade != nil {
    Text("Your plan: Pro")
    Text("Changing to Basic on \(renewalDate)")
        .font(.caption)
        .foregroundStyle(.secondary)
}
```

### Don't Gate All Features During Billing Issues

```swift
// Bad — locks out user immediately on billing failure
if state != .active { showPaywall() }

// Good — progressive restriction
switch state {
case .active:
    showFullApp()
case .inGracePeriod, .inBillingRetry:
    showFullApp()  // Keep access
    showPaymentWarning()  // But warn them
case .expired:
    showPaywall()  // Now restrict
}
```

## Retention Strategies

### Involuntary Churn (Payment Failures)

1. **Enable grace period** in App Store Connect (16 days recommended)
2. **Grant access during billing retry** to keep users engaged
3. **Show in-app payment warning** with clear "Fix Now" action
4. **Don't block features** — a blocked user is more likely to churn permanently

### Voluntary Churn (User Cancels)

1. **Detect auto-renew disabled** via `renewalInfo.willAutoRenew == false`
2. **Show value reminder** — highlight features they'll lose
3. **Offer downgrade** instead of cancellation
4. **Win-back offer** after expiration (iOS 18+)

### Offer Timing

| User State | Offer Type | Timing |
|-----------|-----------|---------|
| Active, auto-renew off | Promotional offer | Before expiration |
| In grace period | None (Apple handles) | N/A |
| Recently expired (< 30 days) | Win-back offer | First app open after expiry |
| Long-lapsed (> 30 days) | Win-back offer or code | Re-engagement campaign |
| About to hit billing retry limit | Promotional offer | Before retry period ends |
