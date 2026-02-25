---
name: referral-system
description: Generates referral/invite infrastructure with unique codes, deep link sharing, reward tracking, and fraud prevention. Use when user wants referral codes, invite friends flow, or viral growth mechanics.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Referral System Generator

Generate a production referral/invite system with unique code generation, deep link sharing, reward tracking, fraud prevention, and SwiftUI views for inviting friends and monitoring referral performance.

## When This Skill Activates

Use this skill when the user:
- Asks to "add a referral system" or "referral codes"
- Wants to "invite friends" or "refer a friend" flow
- Mentions "viral growth" or "invitation system"
- Asks about "referral rewards" or "referral tracking"
- Wants "invite codes" or "shareable invite links"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 17+ / macOS 14+ for @Observable and SwiftData)
- [ ] Identify source file locations
- [ ] Check for existing entitlements (Associated Domains for deep links)

### 2. Conflict Detection
Search for existing referral/invite code:
```
Glob: **/*Referral*.swift, **/*Invite*.swift, **/*InviteCode*.swift
Grep: "referralCode" or "inviteCode" or "ReferralManager"
```

If existing referral system found:
- Ask if user wants to replace or extend it
- If extending, identify integration points

### 3. Deep Link Setup Detection
Search for existing deep link handling:
```
Glob: **/*DeepLink*.swift, **/*UniversalLink*.swift
Grep: "onOpenURL" or "userActivity" or "NSUserActivity"
```

If deep link handling exists, integrate with it rather than generating a standalone handler.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Reward type?**
   - Both-get (referrer and invitee both earn a reward) -- recommended
   - Referrer-only (only the person who shares gets rewarded)
   - Points-based (both parties earn points toward rewards)

2. **Code format?**
   - Short alphanumeric (e.g., `A7K2M9`) -- recommended
   - Custom prefix (e.g., `MYAPP-A7K2M9`)
   - Username-based (e.g., `john-A7K2`)

3. **Sharing method?**
   - Deep link (universal link with embedded code) -- recommended
   - Clipboard copy (copy code to pasteboard)
   - Share sheet (system share with link and message)
   - All of the above

4. **Storage?**
   - SwiftData (local persistence, recommended for most apps)
   - UserDefaults (lightweight, for simple single-code scenarios)
   - CloudKit (sync across devices)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `ReferralCode.swift` -- Model with unique code generation, expiration, usage tracking
2. `ReferralManager.swift` -- @Observable manager for code lifecycle and redemption
3. `ReferralReward.swift` -- Reward configuration, conditions, and fulfillment tracking

### Step 3: Create UI Files
4. `InviteView.swift` -- SwiftUI invite screen with code display and sharing
5. `ReferralDashboardView.swift` -- Stats view for referral performance

### Step 4: Create Integration Files
6. `ReferralDeepLinkHandler.swift` -- Deep link parsing and redemption triggering

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/Referral/`
- If `App/` exists -> `App/Referral/`
- Otherwise -> `Referral/`

## Output Format

After generation, provide:

### Files Created
```
Referral/
├── ReferralCode.swift            # Code model with generation and validation
├── ReferralManager.swift         # @Observable manager for code lifecycle
├── ReferralReward.swift          # Reward config and fulfillment tracking
├── InviteView.swift              # Invite screen with share actions
├── ReferralDashboardView.swift   # Referral stats dashboard
└── ReferralDeepLinkHandler.swift # Deep link parsing and redemption
```

### Integration Steps

**Add deep link handling in your App struct:**
```swift
@main
struct MyApp: App {
    @State private var referralManager = ReferralManager()
    private let deepLinkHandler = ReferralDeepLinkHandler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(referralManager)
                .onOpenURL { url in
                    if let code = deepLinkHandler.extractCode(from: url) {
                        Task {
                            await referralManager.redeemCode(code)
                        }
                    }
                }
        }
    }
}
```

**Present the invite screen:**
```swift
struct ProfileView: View {
    @State private var showInvite = false

    var body: some View {
        Button("Invite Friends") { showInvite = true }
            .sheet(isPresented: $showInvite) {
                InviteView()
            }
    }
}
```

**Show referral dashboard:**
```swift
NavigationLink("My Referrals") {
    ReferralDashboardView()
}
```

### Testing

```swift
@Test
func generatedCodeIsUnique() async throws {
    let manager = ReferralManager(store: InMemoryReferralStore())

    let code1 = await manager.generateCode(for: "user-1")
    let code2 = await manager.generateCode(for: "user-2")

    #expect(code1.value != code2.value)
}

@Test
func redemptionGrantsReward() async throws {
    let manager = ReferralManager(store: InMemoryReferralStore())
    let code = await manager.generateCode(for: "referrer-1")

    let result = await manager.redeemCode(code.value, redeemedBy: "invitee-1")

    #expect(result == .success)
    #expect(manager.rewards(for: "referrer-1").count == 1)
    #expect(manager.rewards(for: "invitee-1").count == 1)
}

@Test
func selfReferralIsRejected() async throws {
    let manager = ReferralManager(store: InMemoryReferralStore())
    let code = await manager.generateCode(for: "user-1")

    let result = await manager.redeemCode(code.value, redeemedBy: "user-1")

    #expect(result == .fraudDetected(.selfReferral))
}

@Test
func expiredCodeIsRejected() async throws {
    let manager = ReferralManager(store: InMemoryReferralStore())
    let code = ReferralCode(
        value: "EXPIRED1",
        ownerID: "user-1",
        expiresAt: Date.distantPast
    )

    let result = await manager.redeemCode(code.value, redeemedBy: "user-2")

    #expect(result == .expired)
}
```

## Common Patterns

### Generate and Share a Referral Code

```swift
// Generate code for current user
let code = await referralManager.generateCode(for: currentUserID)

// Share via system share sheet
let shareURL = deepLinkHandler.buildShareURL(for: code)
let message = "Join me on MyApp! Use my code \(code.value) for a bonus."
let activityItems: [Any] = [message, shareURL]
```

### Redeem a Referral Code

```swift
// On app launch or deep link open
let result = await referralManager.redeemCode(codeString, redeemedBy: currentUserID)

switch result {
case .success:
    showRewardAnimation()
case .alreadyRedeemed:
    showAlert("You've already used a referral code.")
case .expired:
    showAlert("This referral code has expired.")
case .fraudDetected(let reason):
    logger.warning("Fraud detected: \(reason)")
case .invalid:
    showAlert("Invalid referral code.")
}
```

### Track Rewards

```swift
// Check pending rewards
let pending = referralManager.pendingRewards(for: currentUserID)
for reward in pending {
    await fulfillReward(reward)
    await referralManager.markFulfilled(reward)
}
```

## Gotchas

### Fraud Prevention
- **Self-referral**: Always verify referrer ID != redeemer ID. Users will try creating alt accounts.
- **Device fingerprinting**: Consider storing device identifiers to detect multi-account abuse.
- **Rate limiting**: Cap the number of referrals per user per time period (e.g., 50 per month).
- **Code reuse**: Each invitee should only be able to redeem one referral code ever.

### App Store Guidelines
- **Guideline 3.1.1**: Do not offer real-money rewards or gift cards for referrals without proper IAP integration.
- **Guideline 3.2.2(vii)**: Referral systems must not manipulate App Store ratings or reviews.
- **Incentivized installs**: Apple may reject apps that reward users purely for downloading. Tie rewards to meaningful in-app actions (e.g., completing a first task, making a purchase).

### Deep Link Expiration
- Universal links require an `apple-app-site-association` file on your server.
- Referral deep links should have a TTL (default 30 days) to prevent stale code accumulation.
- Handle the case where a user taps a referral link but the app is not installed (redirect to App Store, then capture code on first launch).

### Data Privacy
- Referral codes should not expose user PII (no emails or phone numbers in codes).
- Provide opt-out: let users disable their referral code at any time.
- Comply with GDPR/CCPA if tracking referral relationships across users.

## References

- **templates.md** -- All production Swift templates
- Related: `generators/deep-linking` -- Universal link and deep link infrastructure
- Related: `generators/share-card` -- Visual share cards for social sharing
- Related: `generators/analytics-setup` -- Track referral funnel events
