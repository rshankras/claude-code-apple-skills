# UX Polish Checklist

User experience review for macOS and iOS applications.

## First Launch / Onboarding

### What Good Onboarding Includes

1. **Value proposition** - What does the app do?
2. **Key features** - 3-4 main capabilities
3. **Requirements** - What's needed to use the app
4. **Permissions context** - Why permissions are needed
5. **Get started** - Clear call to action

#### ✅ Good Pattern
```swift
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            // App icon and title
            Image(systemName: "app.icon")
            Text("Welcome to AppName")
                .font(.largeTitle)

            // Features
            FeatureRow(icon: "star", title: "Feature 1", description: "...")
            FeatureRow(icon: "heart", title: "Feature 2", description: "...")

            // Requirements
            RequirementsSection()

            // CTA
            Button("Get Started") { ... }
        }
    }
}
```

### Checklist
- [ ] Onboarding shown on first launch
- [ ] Clear value proposition
- [ ] Features explained concisely
- [ ] Requirements/prerequisites listed
- [ ] Permission requests explained before shown
- [ ] Skip option available (if appropriate)
- [ ] Onboarding state persisted

## Empty States

### Types of Empty States

1. **First use** - No data yet
2. **No results** - Search/filter returned nothing
3. **Error** - Something went wrong
4. **Cleared** - User deleted data

#### ✅ Good Pattern
```swift
if items.isEmpty {
    ContentUnavailableView {
        Label("No Projects Yet", systemImage: "folder")
    } description: {
        Text("Start using Claude Code to see your projects here.")
    } actions: {
        Button("Learn More") { ... }
    }
}
```

#### ❌ Anti-pattern
```swift
// Empty view with no guidance
if items.isEmpty {
    Text("No data")
}
```

### Checklist
- [ ] All lists have empty states
- [ ] Empty states explain why it's empty
- [ ] Empty states provide actionable guidance
- [ ] Search empty states differentiate from "no data"

## Error States

### Error Message Guidelines

1. **What happened** - Clear description
2. **Why it happened** - If known
3. **What to do** - Actionable next step

#### ✅ Good Pattern
```swift
enum AppError: LocalizedError {
    case tokenExpired
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .tokenExpired:
            return "Your session has expired. Please restart the app to refresh."
        case .networkUnavailable:
            return "Unable to connect. Check your internet connection and try again."
        }
    }
}
```

#### ❌ Anti-pattern
```swift
// Unhelpful error messages
case .error:
    return "An error occurred"

// Technical jargon
case .httpError(let code):
    return "HTTP \(code)"
```

### Checklist
- [ ] All errors have user-friendly messages
- [ ] Error messages explain what to do
- [ ] No technical jargon in user-facing errors
- [ ] Errors are recoverable where possible
- [ ] Retry options provided where appropriate

## Loading States

### Guidelines

#### ✅ Good Pattern
```swift
// Show loading indicator
if isLoading {
    ProgressView("Loading projects...")
}

// Skeleton loading for lists
ForEach(0..<5) { _ in
    SkeletonRow()
        .redacted(reason: .placeholder)
}
```

### Checklist
- [ ] Loading states shown for async operations
- [ ] Loading indicators have context (what's loading)
- [ ] Long operations show progress (not just spinner)
- [ ] Loading doesn't block entire UI unnecessarily

## Text & Accessibility

### Text Truncation

#### ✅ Good Pattern
```swift
Text(longText)
    .lineLimit(2)
    .help(longText)  // Tooltip shows full text

// Or allow selection
Text(longText)
    .textSelection(.enabled)
```

#### ❌ Anti-pattern
```swift
// Truncated with no way to see full text
Text(longText)
    .lineLimit(1)
    // No help or selection
```

### Checklist
- [ ] Truncated text has tooltip (`.help()`) or expansion
- [ ] Dynamic Type supported (iOS)
- [ ] VoiceOver labels for all interactive elements
- [ ] Sufficient color contrast
- [ ] No information conveyed by color alone

### Search Patterns
```
Grep: "lineLimit.*[^help]" (truncation without tooltip)
Grep: "accessibilityLabel|accessibilityHint"
```

## Dark Mode

### Checklist
- [ ] App supports dark mode
- [ ] Uses system colors (not hardcoded)
- [ ] Images/icons adapt to color scheme
- [ ] No readability issues in either mode

#### ✅ Good Pattern
```swift
// Use system colors
Color(nsColor: .controlBackgroundColor)
Color(nsColor: .textColor)
Color.primary
Color.secondary
```

#### ❌ Anti-pattern
```swift
// Hardcoded colors
Color.white
Color(red: 0.2, green: 0.2, blue: 0.2)
```

## Platform-Specific UX

### macOS

#### Menu Bar Apps
```swift
// Window activation - activate BEFORE dismissing menu
Button("Open Dashboard") {
    openWindow(id: "dashboard")
    NSApp.activate(ignoringOtherApps: true)  // First
    dismiss()  // Then dismiss
}
```

#### Keyboard Navigation
- [ ] Tab navigation works
- [ ] Keyboard shortcuts for common actions
- [ ] Focus rings visible
- [ ] Escape closes modals/popovers

#### Checklist
- [ ] Windows activate properly from menu bar
- [ ] Keyboard navigation complete
- [ ] Standard shortcuts work (Cmd+W, Cmd+Q, etc.)
- [ ] Preferences accessible via Cmd+,

### iOS

#### Launch Screen
- [ ] Launch screen matches initial UI
- [ ] No jarring transition from launch to app

#### Orientation
- [ ] Supported orientations declared
- [ ] UI adapts to orientation changes
- [ ] iPad multitasking supported (if applicable)

#### Safe Areas
- [ ] Content respects safe areas
- [ ] No content under notch/Dynamic Island
- [ ] Home indicator area respected

## Interactive Feedback

### Checklist
- [ ] Buttons show pressed state
- [ ] Destructive actions require confirmation
- [ ] Success/failure feedback provided
- [ ] Animations are subtle and purposeful

#### ✅ Good Pattern
```swift
Button("Delete", role: .destructive) { ... }
    .confirmationDialog("Delete this item?", isPresented: $showConfirm) {
        Button("Delete", role: .destructive) { delete() }
        Button("Cancel", role: .cancel) { }
    }
```

## Performance UX

### Checklist
- [ ] App launches quickly (< 2 seconds)
- [ ] UI remains responsive during background work
- [ ] No spinning beach ball (macOS)
- [ ] Scrolling is smooth (60fps)
- [ ] Memory warnings handled gracefully

## References

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Accessibility](https://developer.apple.com/accessibility/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
