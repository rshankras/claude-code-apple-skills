---
name: variable-rewards
description: Generates a variable reward system with randomized rewards, daily bonuses, mystery box mechanics, and ethical engagement caps. Use when user wants daily spins, mystery boxes, random rewards, or gamification reward systems.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Variable Rewards Generator

Generate a variable reward system — randomized rewards (daily spins, mystery boxes, bonus points) that leverage variable-ratio reinforcement to increase engagement. Implements ethical engagement patterns with daily/weekly caps, transparent probability disclosure, and no pay-to-play mechanics.

## When This Skill Activates

Use this skill when the user:
- Asks to "add daily rewards" or "daily spin" mechanic
- Wants a "reward system" or "random rewards"
- Mentions "mystery box" or "loot box" (non-paid)
- Asks about "bonus system" or "daily bonus"
- Wants "gamification rewards" or "engagement rewards"
- Mentions "reward wheel" or "spin to win"
- Asks about "variable rewards" or "intermittent reinforcement"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 17+ / macOS 14+ for @Observable and SwiftData)
- [ ] Check for SwiftData availability and existing model container setup
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing reward or points systems:
```
Glob: **/*Reward*.swift, **/*Points*.swift, **/*DailySpin*.swift, **/*MysteryBox*.swift
Grep: "reward" or "dailySpin" or "mysteryBox" or "rewardPool" or "lootBox"
```

If existing reward system found:
- Ask if user wants to replace or extend it
- If extending, generate only the missing components

### 3. Platform Detection
Determine if generating for iOS or macOS or both (cross-platform). The templates use SwiftUI and are cross-platform by default.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Reward types?** (multi-select)
   - Points (numeric currency the user accumulates)
   - Items (unlockable content: themes, stickers, avatars)
   - Features (time-limited feature unlocks)
   - Badges (collectible achievement badges)
   - Mixed (all of the above) -- recommended

2. **Reward mechanism?**
   - Daily spin (wheel animation, one spin per day)
   - Mystery box (card-flip or chest-open, one per day)
   - Random bonus (surprise toast notification on qualifying action)
   - Multiple (daily spin + random bonus) -- recommended

3. **Include daily/weekly caps and cooldowns?**
   - Yes — enforce max rewards per day and per week with cooldown timers (recommended, ethical design)
   - No — unlimited claims (not recommended)

4. **Visual presentation?**
   - Wheel spin (rotating wheel with segments)
   - Card flip (card turns over to reveal reward)
   - Chest open (chest lid opens with glow effect)
   - All of the above -- recommended

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `Reward.swift` — Model for reward type, value, rarity, display metadata
2. `RewardPool.swift` — Weighted probability distribution with seeded random for testability
3. `RewardManager.swift` — @Observable class managing claims, daily resets, caps, history via SwiftData

### Step 3: Create UI Files
4. `DailySpinView.swift` — Animated spin wheel with disabled state when already claimed
5. `MysteryBoxView.swift` — Card-flip / chest-open animation with matchedGeometryEffect
6. `RewardHistoryView.swift` — List of past rewards grouped by day
7. `RewardNotificationView.swift` — Toast/banner overlay for reward availability

### Step 4: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/VariableRewards/`
- If `App/` exists -> `App/VariableRewards/`
- Otherwise -> `VariableRewards/`

## Output Format

After generation, provide:

### Files Created
```
VariableRewards/
├── Reward.swift                  # Reward model with type, rarity, value
├── RewardPool.swift              # Weighted random selection engine
├── RewardManager.swift           # Core manager: claims, caps, history
├── DailySpinView.swift           # Animated spin wheel
├── MysteryBoxView.swift          # Card-flip / chest-open reveal
├── RewardHistoryView.swift       # Past rewards grouped by day
└── RewardNotificationView.swift  # Toast overlay for available rewards
```

### Integration Steps

**Set up the model container (SwiftData):**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [RewardClaim.self])
    }
}
```

**Add the daily spin to your home screen:**
```swift
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var rewardManager: RewardManager?

    var body: some View {
        VStack {
            if let manager = rewardManager {
                DailySpinView(manager: manager)
            }
        }
        .onAppear {
            rewardManager = RewardManager(modelContext: modelContext)
        }
    }
}
```

**Trigger a mystery box reveal:**
```swift
struct MilestoneView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var rewardManager: RewardManager?
    @State private var showMysteryBox = false

    var body: some View {
        VStack {
            Button("Open Mystery Box") {
                showMysteryBox = true
            }
            .disabled(rewardManager?.canClaimToday == false)
        }
        .sheet(isPresented: $showMysteryBox) {
            if let manager = rewardManager {
                MysteryBoxView(manager: manager)
            }
        }
        .onAppear {
            rewardManager = RewardManager(modelContext: modelContext)
        }
    }
}
```

**Show a reward notification toast:**
```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var rewardManager: RewardManager?

    var body: some View {
        ZStack {
            MainTabView()
            if let manager = rewardManager {
                RewardNotificationView(manager: manager)
            }
        }
        .onAppear {
            rewardManager = RewardManager(modelContext: modelContext)
        }
    }
}
```

**View reward history:**
```swift
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var rewardManager: RewardManager?

    var body: some View {
        NavigationStack {
            if let manager = rewardManager {
                RewardHistoryView(manager: manager)
            }
        }
        .onAppear {
            rewardManager = RewardManager(modelContext: modelContext)
        }
    }
}
```

### Testing

```swift
import Testing
import SwiftData

@Test
func dailySpinGrantsReward() async throws {
    let container = try ModelContainer(
        for: RewardClaim.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let pool = RewardPool(seed: 42) // Deterministic for testing
    let manager = RewardManager(modelContext: context, rewardPool: pool)

    let reward = try await manager.claimDailySpin()
    #expect(reward != nil)
    #expect(manager.canClaimToday == false) // Already claimed
}

@Test
func dailyCapEnforced() async throws {
    let container = try ModelContainer(
        for: RewardClaim.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let pool = RewardPool(seed: 42)
    let manager = RewardManager(modelContext: context, rewardPool: pool, dailyCap: 1)

    _ = try await manager.claimDailySpin()
    let second = try await manager.claimDailySpin()
    #expect(second == nil) // Cap reached
}

@Test
func deterministicSeedProducesSameReward() {
    let pool1 = RewardPool(seed: 123)
    let pool2 = RewardPool(seed: 123)

    let reward1 = pool1.drawReward()
    let reward2 = pool2.drawReward()

    #expect(reward1.type == reward2.type)
    #expect(reward1.rarity == reward2.rarity)
}

@Test
func weeklyCapResetsAfterWeek() async throws {
    let container = try ModelContainer(
        for: RewardClaim.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let pool = RewardPool(seed: 42)
    let manager = RewardManager(modelContext: context, rewardPool: pool, weeklyCap: 3)

    // Simulate 3 claims on different days within the same week
    let calendar = Calendar.current
    for daysAgo in (0...2).reversed() {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
        _ = try await manager.claimDailySpin(date: date)
    }

    #expect(manager.weeklyClaimCount == 3)
    #expect(manager.canClaimThisWeek == false)
}
```

## Common Patterns

### Daily Spin
```swift
// Check if user can spin today
if rewardManager.canClaimToday {
    let reward = try await rewardManager.claimDailySpin()
    // Show reward animation
}

// Time until next spin
let timeRemaining = rewardManager.timeUntilNextClaim
// Returns TimeInterval — use for countdown display
```

### Claim a Reward
```swift
// Claim via mystery box mechanism
let reward = try await rewardManager.claimMysteryBox()

// Claim via random bonus (triggered by app action)
let bonus = try await rewardManager.claimRandomBonus()

// All claim methods enforce daily/weekly caps automatically
```

### View History
```swift
// Get all past rewards
let history = rewardManager.claimHistory // [RewardClaim]

// Grouped by day for display
let grouped = rewardManager.claimHistoryByDay // [Date: [RewardClaim]]

// Filter by rarity
let rareRewards = rewardManager.claims(withRarity: .rare)
```

### Query Reward State
```swift
let canClaim = rewardManager.canClaimToday       // Daily cap not reached
let canClaimWeek = rewardManager.canClaimThisWeek // Weekly cap not reached
let countdown = rewardManager.timeUntilNextClaim  // Seconds until midnight reset
let todayCount = rewardManager.dailyClaimCount    // Claims made today
let weekCount = rewardManager.weeklyClaimCount    // Claims made this week
```

## Gotchas & Edge Cases

### Ethical Design: Caps, Transparency, No Pay-to-Play
Variable-ratio reinforcement is a powerful engagement mechanic. The templates enforce ethical boundaries:
- **Daily and weekly caps** prevent compulsive over-engagement. Default: 1 daily spin + 2 random bonuses per day, 10 total per week.
- **Probability transparency** — `RewardPool` exposes its rarity weights so you can display them in a "Reward Rates" info sheet (required by some App Store regions).
- **No pay-to-play** — the templates do not gate rewards behind purchases. If you add premium reward tiers, keep a generous free tier and clearly label paid content.
- **Cooldown timers** show users exactly when the next reward is available rather than encouraging constant app-checking.

### Server Time vs Device Time for Daily Resets
Users can change their device clock to claim extra rewards. Mitigations:
- For local-only apps, use `Date()` with `Calendar.current.startOfDay(for:)` — accept that determined users can game it.
- For server-synced apps, fetch the current time from your server on each claim and validate server-side. The templates include a `timeProvider` protocol for injecting server time.
- Store raw `Date` timestamps alongside normalized day values so you can detect anomalies (claims with `createdAt` before a previously recorded claim).

### Deterministic Testing of Random Outcomes
`RewardPool` accepts a `seed` parameter that initializes the random number generator deterministically. In tests, always pass a fixed seed so assertions are stable:
```swift
let pool = RewardPool(seed: 42)
let reward = pool.drawReward() // Always produces the same reward for seed 42
```
In production, omit the seed to use system entropy.

### Rarity Weight Tuning
The default rarity weights (common: 60%, uncommon: 25%, rare: 10%, epic: 5%) produce one epic reward roughly every 20 claims. Adjust weights in `RewardPool.defaultWeights` to match your engagement goals. Verify with a histogram test:
```swift
@Test
func rarityDistributionMatchesWeights() {
    let pool = RewardPool(seed: 0)
    var counts: [Reward.Rarity: Int] = [:]
    for _ in 0..<10_000 {
        let reward = pool.drawReward()
        counts[reward.rarity, default: 0] += 1
    }
    // Epic should be roughly 5% (500 +/- tolerance)
    #expect(counts[.epic]! > 300 && counts[.epic]! < 700)
}
```

### App Reinstall / Data Loss
SwiftData stores persist across app updates but are lost on reinstall. For valuable reward inventories, sync to CloudKit or a backend. The `RewardManager` includes a `lastSyncDate` hook for this purpose.

### Midnight Reset Race Condition
If a user claims a reward at 11:59:59 PM and the daily reset fires at midnight, ensure the claim is attributed to the correct day. The templates use `Calendar.current.startOfDay(for: claimDate)` to normalize all claims to their calendar day, avoiding off-by-one errors at the boundary.

## References

- **templates.md** — All production Swift templates for variable rewards
- Related: `generators/milestone-celebration` — Celebrate reward milestones with animations
- Related: `generators/streak-tracker` — Combine streaks with daily rewards for compounding engagement
- Related: `generators/tipkit-generator` — Coach marks to introduce the reward system to new users
