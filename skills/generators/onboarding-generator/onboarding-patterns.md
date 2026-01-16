# Onboarding Patterns and Best Practices

## Design Principles

### Keep It Short
- 3-4 screens optimal
- Users want to use the app, not read tutorials
- Save detailed tutorials for in-app help

### Focus on Value
- Explain benefits, not features
- "Save time" not "Has a calendar sync feature"
- Show outcomes, not mechanics

### Make It Skippable
- Power users don't need handholding
- Always provide a way out
- Remember: they already downloaded your app

## Navigation Patterns

### Paged (Swipe)
Best for: Visual, image-heavy onboarding

```swift
TabView(selection: $currentPage) {
    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
        OnboardingPageView(page: page)
            .tag(index)
    }
}
.tabViewStyle(.page(indexDisplayMode: .always))
.indexViewStyle(.page(backgroundDisplayMode: .always))
```

**Pros:**
- Intuitive gesture
- Progress visible via dots
- Works well on all screen sizes

**Cons:**
- Easy to accidentally swipe past content
- Less control over pacing

### Stepped (Buttons)
Best for: Permission requests, sequential setup

```swift
VStack {
    OnboardingPageView(page: pages[currentPage])
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))

    HStack {
        if currentPage > 0 {
            Button("Back") {
                withAnimation { currentPage -= 1 }
            }
        }
        Spacer()
        Button(currentPage == pages.count - 1 ? "Get Started" : "Next") {
            withAnimation {
                if currentPage == pages.count - 1 {
                    completeOnboarding()
                } else {
                    currentPage += 1
                }
            }
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
}
```

**Pros:**
- Clear calls to action
- Better for requesting permissions at specific steps
- Users must acknowledge each screen

**Cons:**
- More taps required
- Can feel slower

## Persistence Patterns

### @AppStorage (Simple)
```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
```

**When to use:**
- Simple boolean "has seen onboarding"
- No need to track individual pages
- OK if reset on app reinstall

### UserDefaults with Version
```swift
struct OnboardingStorage {
    private static let key = "onboardingCompletedVersion"
    private static let currentVersion = 2  // Increment to show again

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.integer(forKey: key) >= currentVersion }
        set { UserDefaults.standard.set(newValue ? currentVersion : 0, forKey: key) }
    }
}
```

**When to use:**
- Want to show onboarding again after major updates
- Need to track which version user saw

### Keychain (Persists Reinstall)
```swift
// Use KeychainAccess or similar library
let keychain = Keychain(service: "com.yourapp.onboarding")
let hasCompleted = keychain["completed"] != nil
```

**When to use:**
- Must persist across reinstalls
- Subscription apps where reinstall shouldn't reset

## Presentation Patterns

### Full Screen Cover
```swift
.fullScreenCover(isPresented: $showOnboarding) {
    OnboardingView(onComplete: { showOnboarding = false })
}
```

**Best for:**
- Immersive onboarding
- When main UI shouldn't be visible

### Sheet
```swift
.sheet(isPresented: $showOnboarding) {
    OnboardingView()
        .interactiveDismissDisabled()  // Prevent swipe to dismiss
}
```

**Best for:**
- Less intrusive feel
- macOS apps (sheets are more common)

### Inline
```swift
if !hasCompletedOnboarding {
    OnboardingView(onComplete: { hasCompletedOnboarding = true })
} else {
    MainContentView()
}
```

**Best for:**
- Simple apps
- When you want immediate transition

## Animation Patterns

### Page Transitions
```swift
OnboardingPageView(page: pages[currentPage])
    .id(currentPage)  // Force view recreation
    .transition(.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    ))
    .animation(.easeInOut(duration: 0.3), value: currentPage)
```

### Image Animations
```swift
Image(systemName: page.imageName)
    .font(.system(size: 100))
    .symbolEffect(.bounce, value: isAnimating)
    .onAppear { isAnimating = true }
```

### Progress Indicator
```swift
// Custom progress bar
GeometryReader { geometry in
    Rectangle()
        .fill(Color.accentColor)
        .frame(width: geometry.size.width * CGFloat(currentPage + 1) / CGFloat(pages.count))
        .animation(.easeInOut, value: currentPage)
}
.frame(height: 4)
```

## Accessibility Patterns

### VoiceOver Support
```swift
OnboardingPageView(page: page)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(page.title). \(page.description)")
    .accessibilityHint("Page \(index + 1) of \(pages.count)")
```

### Dynamic Type
```swift
Text(page.title)
    .font(.title)  // Use semantic fonts
    .minimumScaleFactor(0.7)  // Allow shrinking if needed
    .lineLimit(2)

Text(page.description)
    .font(.body)
```

### Reduced Motion
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? nil : .easeInOut, value: currentPage)
```

## Permission Request Integration

Request permissions at relevant onboarding steps:

```swift
struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let permissionRequest: PermissionType?

    enum PermissionType {
        case notifications
        case location
        case camera
        case photos
    }
}

// In OnboardingPageView
if let permission = page.permissionRequest {
    Button("Enable") {
        requestPermission(permission)
    }
    .buttonStyle(.borderedProminent)
}
```

## Content Guidelines

### Screen 1: Welcome
- App name/logo
- One-line value proposition
- Warm, inviting imagery

### Screen 2-3: Key Features
- One feature per screen
- Benefit-focused copy
- Relevant illustration/screenshot

### Screen 4: Get Started
- Clear call to action
- Optional: Sign up / Sign in
- Optional: Permission request

## Anti-Patterns to Avoid

### Don't
- Show more than 5 screens
- Use walls of text
- Require all permissions upfront
- Make it unskippable with no good reason
- Show onboarding on every app update

### Do
- Keep text under 2 sentences per screen
- Use illustrations/icons
- Request permissions contextually
- Provide skip option
- Use versioned persistence for updates
