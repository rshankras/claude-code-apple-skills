---
name: onboarding-generator
description: Generates multi-step onboarding flows with persistence for iOS/macOS apps. Use when user wants to add onboarding, welcome screens, or first-launch experience.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Onboarding Generator

Generate a complete, customizable onboarding flow with persistence, animations, and accessibility support.

## When This Skill Activates

Use this skill when the user:
- Asks to "add onboarding" or "create onboarding"
- Mentions "welcome screens" or "first launch"
- Wants to "show intro on first launch"
- Asks about "onboarding flow" or "tutorial screens"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check for existing onboarding implementations
- [ ] Identify if SwiftUI or UIKit project
- [ ] Find App entry point location
- [ ] Check deployment target (TabView paging requires iOS 14+)

### 2. Conflict Detection
Search for existing onboarding:
```
Glob: **/*Onboarding*.swift, **/*Welcome*.swift
Grep: "hasCompletedOnboarding" or "isFirstLaunch"
```

If found, ask user:
- Replace existing onboarding?
- Keep existing, add new flow?

## Configuration Questions

Ask user via AskUserQuestion:

1. **Navigation style?**
   - Paged (horizontal swipe with dots)
   - Stepped (Next/Back buttons)

2. **Number of screens?**
   - 2-5 screens (recommend 3-4)

3. **Skip option?**
   - Allow skip button
   - Mandatory completion

4. **Presentation style?**
   - Full screen cover (modal)
   - Inline (embedded in view hierarchy)

5. **Include animations?**
   - Animated transitions
   - Static transitions

## Generation Process

### Step 1: Create Core Files

Generate these files:
1. `OnboardingView.swift` - Main container
2. `OnboardingPageView.swift` - Individual page template
3. `OnboardingPage.swift` - Page data model
4. `OnboardingStorage.swift` - Persistence
5. `OnboardingModifier.swift` - View modifier for easy integration

### Step 2: Customize Based on Configuration

**Paged Navigation:**
```swift
TabView(selection: $currentPage) {
    ForEach(pages) { page in
        OnboardingPageView(page: page)
            .tag(page.id)
    }
}
.tabViewStyle(.page(indexDisplayMode: .always))
```

**Stepped Navigation:**
```swift
VStack {
    OnboardingPageView(page: pages[currentPage])

    HStack {
        if currentPage > 0 {
            Button("Back") { currentPage -= 1 }
        }
        Spacer()
        Button(isLastPage ? "Get Started" : "Next") {
            if isLastPage {
                completeOnboarding()
            } else {
                currentPage += 1
            }
        }
    }
}
```

### Step 3: Determine File Location

Check project structure:
- If `Sources/` exists → `Sources/Onboarding/`
- If `App/` exists → `App/Onboarding/`
- Otherwise → `Onboarding/`

## Output Format

After generation, provide:

### Files Created
```
Sources/Onboarding/
├── OnboardingView.swift           # Main container
├── OnboardingPageView.swift       # Page template
├── OnboardingPage.swift           # Data model
├── OnboardingStorage.swift        # @AppStorage persistence
└── OnboardingModifier.swift       # .onboarding() modifier
```

### Integration Steps

**Option 1: View Modifier (Recommended)**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onboarding()  // Automatically shows on first launch
        }
    }
}
```

**Option 2: Manual Control**
```swift
@main
struct MyApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
                    OnboardingView()
                }
        }
    }
}
```

### Customization

**Add Your Content:**
```swift
// In OnboardingStorage.swift or OnboardingView.swift
static let pages: [OnboardingPage] = [
    OnboardingPage(
        title: "Welcome",
        description: "Your app description here",
        imageName: "hand.wave",  // SF Symbol or asset name
        accentColor: .blue
    ),
    // Add more pages...
]
```

### Testing Instructions
1. Delete app from simulator (to reset UserDefaults)
2. Run app - onboarding should appear
3. Complete onboarding
4. Relaunch app - onboarding should NOT appear
5. Reset via Settings or delete app to test again

### Debug/Testing Reset
```swift
// Add to Settings or debug menu
Button("Reset Onboarding") {
    UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
}
```

## References

- **onboarding-patterns.md** - Best practices and design patterns
- **templates/** - All template files
