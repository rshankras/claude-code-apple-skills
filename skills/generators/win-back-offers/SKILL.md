---
name: win-back-offers
description: Generates the complete win-back offer flow for churned subscribers — StoreKit Message API handling, eligibility verification, offer sheet presentation, and analytics. Use when implementing win-back campaigns or re-engagement for lapsed subscribers.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# Win-Back Offers Generator

Generate a complete win-back flow for recovering churned subscribers using StoreKit 2's win-back offer APIs (iOS 18+), Message API handling, and fallback promotional offers for older OS versions.

## When This Skill Activates

Use this skill when the user:
- Asks to "win back" or "re-engage" churned subscribers
- Mentions "lapsed subscribers" or "subscriber recovery"
- Wants to implement "win-back offers" (iOS 18+)
- Asks about "subscription churn" reduction
- Mentions "Message API" for subscription offers
- Wants to reduce subscriber attrition

## Minimum Eligibility

Win-back offers involve meaningful engineering and ASC configuration. Check these thresholds before proceeding:

| Churned Subscribers | Recommendation |
|----|---|
| **Under 50** | Not worth the setup effort. Use personal email outreach instead — write individual messages to churned users. Focus energy on preventing churn (improve onboarding, engagement). |
| **50-500** | Implement basic win-back via promotional offers (simpler than full win-back flow). Use offer codes distributed via email. |
| **500+** | Full win-back implementation justified. Native iOS 18+ win-back offers, Message API handling, automated pipeline. |

**If you don't know your churn numbers:** Check App Store Connect > Subscriptions > Retention metrics. If your total subscriber base is under 200, you likely don't have enough churn volume to justify this skill yet.

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing StoreKit implementation
- [ ] Check deployment target (iOS 18+ for native win-back, iOS 16+ for promotional offer fallback)
- [ ] Look for existing subscription management code
- [ ] Check if `subscription-offers` skill was already used
- [ ] **Check churn volume** — is the number of churned subscribers worth automating?

### 2. Conflict Detection
```
Glob: **/*WinBack*.swift, **/*Reengag*.swift
Grep: "winBackOffers" or "Message.messages" or "presentWinBackOffer"
```

## Configuration Questions

Ask user via AskUserQuestion:

1. **Win-back approach**
   - Native win-back offers only (iOS 18+ required)
   - Promotional offer fallback (supports iOS 16+)
   - Both (recommended)

2. **Message handling**
   - Handle App Store messages in-app (recommended)
   - Let system handle messages
   - Custom message presentation

3. **Analytics integration**
   - Basic (print logging)
   - Custom analytics protocol
   - Specific SDK (specify which)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for all win-back implementation code.

### Step 2: Create Core Files

1. **WinBackOfferManager.swift** — Win-back offer detection, eligibility, and presentation
2. **WinBackMessageHandler.swift** — StoreKit Message API integration for in-app offer display
3. **WinBackEligibility.swift** — Churn detection and eligibility logic
4. **WinBackOfferView.swift** — Custom win-back offer presentation UI

### Step 3: Create Optional Files

5. **WinBackAnalytics.swift** — Track win-back funnel metrics
6. **WinBackFallback.swift** — Promotional offer fallback for iOS < 18

### Step 4: Determine File Location
```
- If Sources/Store/ exists → Sources/Store/WinBack/
- If Store/ exists → Store/WinBack/
- Otherwise → WinBack/
```

## Output Format

### Files Created
```
Store/WinBack/
├── WinBackOfferManager.swift      # Core win-back logic
├── WinBackMessageHandler.swift    # Message API handling
├── WinBackEligibility.swift       # Churn detection
├── WinBackOfferView.swift         # Custom offer UI
├── WinBackAnalytics.swift         # Funnel tracking (optional)
└── WinBackFallback.swift          # iOS < 18 fallback (optional)
```

### Integration Steps

**App Entry Point — Message Handling:**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .storeMessagesTask { message in
                    // Handle win-back messages from App Store
                    await WinBackMessageHandler.shared.handle(message)
                }
        }
    }
}
```

**Check Win-Back Eligibility:**
```swift
let manager = WinBackOfferManager()
let winBackOffer = await manager.checkWinBackAvailability(
    productID: "com.app.subscription.monthly"
)

if let offer = winBackOffer {
    // Show win-back UI
    showWinBackSheet(offer: offer)
}
```

**Present Win-Back Offer:**
```swift
// Native (iOS 18+) — raw StoreKit path
if case .verified(let renewalInfo) = status.renewalInfo,
   let bestID = renewalInfo.eligibleWinBackOfferIDs.first,   // first ID = best offer
   let offer = product.subscription?.winBackOffers.first(where: { $0.id == bestID }) {
    let result = try await product.purchase(options: [.winBackOffer(offer)])
}

// With StoreKit views, choose the merchandised offer instead
SubscriptionStoreView(groupID: groupID)
    .preferredSubscriptionOffer { product, subscription, offers in
        offers.first { $0.type == .winBack }
    }
```

Hide win-back merchandising from anyone still entitled with auto-renew on — the offer is for lapsed subscribers only.

### Where Offers Surface (WWDC24)

The App Store does the distribution — eligible lapsed subscribers see your win-back offer on:

- Your **product page** (offer card)
- **Today / Games / Apps** editorial placements
- The App Store's **Subscriptions** management page
- **In-app**, via the APIs above

**Streamlined purchasing is ON by default:** users can redeem on the App Store before ever reopening your app, so the transaction arrives via `Transaction.updates` — listen from launch. If you disable streamlined purchasing, implement `PurchaseIntent` to complete the purchase in-app.

### Testing Instructions

1. **Sandbox Account**: Create a subscriber, cancel, wait for expiry — and enable "Display Win-back Offers" in the sandbox account settings
2. **StoreKit Testing**: Use Transaction Manager to simulate churn; the Xcode StoreKit configuration file has per-offer eligibility toggles to simulate any eligibility state
3. **Message Testing**: Test App Store message presentation
4. **Verify flow**: Churned → Offer shown → Purchase → Active subscriber

### App Store Connect Setup

1. Go to Subscriptions > Your Group > Win-Back Offers
2. Create offer with pricing and duration
3. Set the three declarative eligibility knobs (WWDC24):
   - **Minimum paid subscription months** — most recent *consecutive* paid months; any subscription in the group counts, and upgrades/downgrades don't reset the count
   - **Time since last subscribed** — both a minimum AND a maximum, in months
   - **Redemption cooldown** (optional) — wait between redemptions, starting after the offer period ends
   - Worked example: paid ≥ 3 months, lapsed 2–24 months, 6-month cooldown, offer = 1 month free
4. Configure offer priority if multiple offers exist — it decides which offer is "best" when several are eligible

**Config gotchas:**
- Offer identifier and pricing are immutable after creation
- Eligibility criteria lock at the offer's start date
- Stopping App Store promotion requires deleting the offer

### Retention Messaging (At-Cancel Save Offers)

> The App Store Connect tier is open to all developers (WWDC26); the real-time server API is gated behind an access-request form + a mandatory sandbox performance test. (Per the session "Explore Retention Messaging in App Store Connect".)

The App Store presents your message on the **cancel confirmation page** — the last screen before a subscriber churns. It complements win-back rather than replacing it:

| Mechanism | Fires |
|-----------|-------|
| Retention messaging | At cancel — before the user churns |
| Win-back offer | After lapse — once the subscription has expired |

Configure both — they cover opposite ends of the churn window.

**Mechanics (from Apple's session):**

- Three formats: message only · message + image (from the Asset Library) · message + **retention offer**.
- Attach **multiple offers** to one subscription with confidence — "the App Store will automatically choose the best offer for eligible customers."
- Setup (no server needed): ASC → Subscriptions → Retention Messaging → name it, write the message, optionally attach image + offers, pick subscriptions, **test in sandbox first**. Also configurable via the ASC API.
- Real-time variant: the App Store calls your endpoint for a per-customer message, falling back automatically (your ASC messages → API defaults → system fallback) if it times out — so always configure the ASC tier even when using real-time.
- Apple's observed impact: average **save-rate lift +1.4 points (~82%)**; messages carrying a promotional offer reached **+5.5 points (~223%)** — with "varying results across developers." (Save rate = % of subscribers who keep the subscription after reaching the cancel confirmation page.)

## References

- **templates.md** — All production Swift templates
- Related: `generators/subscription-offers` — All offer types including win-back
- Related: `generators/paywall-generator` — Full paywall implementation
- Related: `app-store/marketing-strategy` — Win-back campaign planning
