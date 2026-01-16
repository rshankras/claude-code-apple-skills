# StoreKit Review Patterns and Best Practices

## Apple's Review Prompt Rules

### System Limitations
- Maximum 3 prompts per 365-day period per app
- System decides whether to actually show the prompt
- No feedback to app about whether prompt was shown
- Prompt may not show in Simulator

### Guidelines
1. **Don't prompt immediately** - Wait for user to use app
2. **Don't interrupt** - Choose natural break points
3. **After positive moments** - User just accomplished something
4. **Never after negative** - Errors, crashes, frustration
5. **Don't ask repeatedly** - Respect the 3/year limit

## Timing Strategies

### Good Timing
- After completing a task successfully
- After achieving a milestone (10th entry, etc.)
- After using the app for several sessions
- At natural pause points (returning from background)

### Bad Timing
- On first launch
- During active workflow
- After an error
- When user is trying to do something
- Right after a purchase

## Condition-Based Triggering

### Session Count
```swift
// Don't ask until user has come back multiple times
func shouldPromptBasedOnSessions() -> Bool {
    sessionCount >= minimumSessions
}
```

**Why**: Users who return are more likely to be satisfied

### Days Since Install
```swift
// Give users time to evaluate the app
func shouldPromptBasedOnDays() -> Bool {
    daysSinceInstall >= minimumDays
}
```

**Why**: First impressions may not reflect long-term value

### Positive Actions
```swift
// Track successful completions
func shouldPromptBasedOnActions() -> Bool {
    positiveActionCount >= minimumPositiveActions
}
```

**Why**: Users who accomplish things are happier

### Combined Conditions
```swift
// Require ALL conditions
func shouldPrompt() -> Bool {
    sessionCount >= minimumSessions &&
    daysSinceInstall >= minimumDays &&
    positiveActionCount >= minimumPositiveActions &&
    daysSinceLastPrompt >= cooldownDays
}
```

## Cool-Down Strategy

### Why Cool-Down Matters
- Apple limits to 3/year anyway
- Repeated prompts annoy users
- Space out for maximum effectiveness

### Recommended Cool-Down
```swift
// 60-90 days between prompts
let cooldownDays = 60

func canPromptAgain() -> Bool {
    guard let lastPromptDate = lastPromptDate else { return true }
    let daysSince = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0
    return daysSince >= cooldownDays
}
```

## Platform-Specific Considerations

### iOS
```swift
import StoreKit

func requestReview() {
    if let scene = UIApplication.shared.connectedScenes
        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
        SKStoreReviewController.requestReview(in: scene)
    }
}
```

### macOS (App Store Only)
```swift
import StoreKit

func requestReview() {
    // Check if running from App Store
    guard isAppStoreVersion() else {
        // Direct distribution - use alternative
        openAppStoreReviewPage()
        return
    }

    SKStoreReviewController.requestReview()
}

func isAppStoreVersion() -> Bool {
    // sandboxReceipt indicates development/TestFlight
    // Receipt present without sandbox indicates App Store
    guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
    return FileManager.default.fileExists(atPath: receiptURL.path) &&
           !receiptURL.path.contains("sandboxReceipt")
}
```

### macOS (Direct Distribution Alternative)
```swift
func openAppStoreReviewPage() {
    let appID = "YOUR_APP_ID"
    if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
        NSWorkspace.shared.open(url)
    }
}
```

## Debug and Testing

### Debug Override
```swift
#if DEBUG
static var debugAlwaysShow = false

func requestReviewIfAppropriate() {
    if Self.debugAlwaysShow {
        requestReview()
        return
    }
    // Normal logic...
}
#endif
```

### State Reset
```swift
static func resetForTesting() {
    UserDefaults.standard.removeObject(forKey: Keys.sessionCount)
    UserDefaults.standard.removeObject(forKey: Keys.installDate)
    UserDefaults.standard.removeObject(forKey: Keys.lastPromptDate)
    UserDefaults.standard.removeObject(forKey: Keys.positiveActionCount)
}
```

### Simulator Notes
- Prompt may not appear in Simulator
- Test on physical device for actual behavior
- Use debug logging to verify conditions are met

## Tracking What Worked

### Analytics Integration
```swift
func requestReviewIfAppropriate() {
    guard shouldPrompt() else { return }

    // Track that we attempted to show prompt
    analytics.track(.reviewPromptAttempted(
        sessions: sessionCount,
        days: daysSinceInstall,
        actions: positiveActionCount
    ))

    requestReview()
    recordPromptDate()
}
```

### A/B Testing Conditions
```swift
// Test different thresholds
let thresholds: ReviewThresholds = FeatureFlags.reviewPromptVariant == .aggressive
    ? .init(sessions: 2, days: 1, actions: 3)
    : .init(sessions: 5, days: 7, actions: 5)
```

## In-App Feedback Alternative

For when App Store review isn't appropriate:

```swift
struct FeedbackView: View {
    @State private var rating: Int = 0
    @State private var feedback: String = ""

    var body: some View {
        VStack {
            Text("How are we doing?")

            // Star rating
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .onTapGesture { rating = star }
                }
            }

            if rating > 0 {
                if rating >= 4 {
                    // Happy user - ask for App Store review
                    Button("Rate on App Store") {
                        ReviewPromptManager.shared.requestReview()
                    }
                } else {
                    // Unhappy user - capture feedback internally
                    TextField("How can we improve?", text: $feedback)
                    Button("Send Feedback") {
                        sendFeedback(rating: rating, feedback: feedback)
                    }
                }
            }
        }
    }
}
```

## Common Anti-Patterns

### Don't Do This
```swift
// Bad: Prompting on every launch
func applicationDidBecomeActive() {
    SKStoreReviewController.requestReview()  // NO!
}

// Bad: Prompting after errors
func handleError(_ error: Error) {
    showErrorAlert(error)
    requestReview()  // NO! User is frustrated
}

// Bad: Prompting immediately after purchase
func handlePurchaseSuccess() {
    // User just paid - let them use what they bought
    requestReview()  // NO! Too early
}

// Bad: Begging
func showCustomPrompt() {
    "Please rate us 5 stars!"  // NO! Let the system prompt
}
```

### Do This Instead
```swift
// Good: After positive action with conditions met
func taskCompleted() {
    saveTask()
    celebrateCompletion()

    // Check all conditions before prompting
    if shouldPromptForReview() {
        // Small delay to not interrupt celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            requestReviewIfAppropriate()
        }
    }
}
```
