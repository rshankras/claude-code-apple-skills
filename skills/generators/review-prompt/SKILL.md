---
name: review-prompt
description: Generates smart App Store review prompt infrastructure with configurable conditions and platform detection. Use when user wants to add review prompts, request ratings, or implement StoreKit reviews.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Review Prompt Generator

Generate smart App Store review prompting with configurable trigger conditions, platform detection, and proper timing logic.

## When This Skill Activates

Use this skill when the user:
- Asks to "add review prompt" or "request reviews"
- Mentions "App Store rating" or "app reviews"
- Wants to "prompt for ratings" or "ask for reviews"
- Asks about "StoreKit review" or "SKStoreReviewController"

## Platform Detection (CRITICAL)

**This skill only applies to App Store distributed apps.**

### iOS Apps
- Always applicable (iOS apps require App Store)

### macOS Apps
Detection steps:
1. Check for `com.apple.application-identifier` entitlement
2. Look for Mac App Store related code
3. If unclear, **ASK THE USER**:
   - "Is this app distributed via Mac App Store or direct download?"

### If NOT App Store:
- Explain that StoreKit reviews only work for App Store apps
- Offer alternative: In-app feedback form
- Skip generation or generate feedback form instead

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Determine platform (iOS/macOS)
- [ ] Check distribution method (App Store vs direct)
- [ ] Search for existing review prompt code
- [ ] Identify App entry point

### 2. Conflict Detection
Search for existing implementations:
```
Grep: "requestReview" or "SKStoreReviewController" or "StoreKit"
Glob: **/*Review*.swift
```

If found, ask user:
- Replace existing implementation?
- Enhance with better timing logic?

## Configuration Questions

Ask user via AskUserQuestion:

1. **Trigger conditions?** (multi-select)
   - Session count (e.g., after 5 sessions)
   - Days since install (e.g., after 3 days)
   - Positive actions (e.g., after completing a task)
   - Feature usage (e.g., after using key feature 3 times)

2. **Minimum thresholds?**
   - Sessions before first prompt: 3-5 (default: 3)
   - Days before first prompt: 2-7 (default: 3)

3. **Cool-down period?**
   - Days between prompts: 30-90 (default: 60)
   - Apple limits to 3 prompts/year anyway

4. **Debug mode?**
   - Include debug override for testing?

## Generation Process

### Step 1: Create Core Files

Generate these files:
1. `ReviewPromptManager.swift` - Core logic and timing
2. `ReviewPromptCondition.swift` - Configurable conditions
3. `ReviewPromptStorage.swift` - Persistence for tracking

### Step 2: Determine File Location

Check project structure:
- If `Sources/` exists → `Sources/Reviews/`
- If `App/` exists → `App/Reviews/`
- Otherwise → `Reviews/`

### Step 3: Add Platform Guards

For macOS, include:
```swift
#if os(macOS)
// Check if running from App Store
guard Bundle.main.appStoreReceiptURL?.lastPathComponent != "sandboxReceipt" else {
    // Running in sandbox but not App Store - skip
    return
}
#endif
```

## Output Format

After generation, provide:

### Files Created
```
Sources/Reviews/
├── ReviewPromptManager.swift      # Core logic
├── ReviewPromptCondition.swift    # Conditions enum
└── ReviewPromptStorage.swift      # UserDefaults persistence
```

### Integration Steps

**Option 1: Automatic (Recommended)**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    ReviewPromptManager.shared.incrementSession()
                }
        }
    }
}

// In relevant places (after positive actions):
ReviewPromptManager.shared.recordPositiveAction()
ReviewPromptManager.shared.requestReviewIfAppropriate()
```

**Option 2: Manual Trigger Points**
```swift
// After user completes a significant action
func completeTask() {
    // ... task completion logic ...

    ReviewPromptManager.shared.recordPositiveAction()
    ReviewPromptManager.shared.requestReviewIfAppropriate()
}
```

### Apple's Guidelines
- System limits to 3 prompts per 365-day period
- Prompt appears at system's discretion (not guaranteed)
- Never prompt after negative experience
- Don't prompt on first launch
- Don't interrupt user's workflow

### Testing Instructions

1. **Debug Mode**: Set `ReviewPromptManager.debugAlwaysShow = true`
2. **Reset State**: Call `ReviewPromptStorage.reset()`
3. **Simulate**: Increment sessions/actions in debug builds
4. **Note**: Actual prompt may not show in Simulator

### App Store Review URL (Alternative)
For custom UI or macOS direct distribution:
```swift
// Deep link to App Store review page
let appID = "YOUR_APP_ID"
let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!
NSWorkspace.shared.open(url)  // macOS
UIApplication.shared.open(url)  // iOS
```

## References

- **storekit-patterns.md** - Best practices and timing strategies
- **templates/** - All template files
