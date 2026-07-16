---
name: settings-screen
description: Generates a complete settings screen for iOS/macOS apps with common sections. Use when user wants to add settings, preferences, or configuration UI.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# Settings Screen Generator

Generates a production-ready settings screen with modular sections for iOS and macOS apps.

## When This Skill Activates

- User asks to "add settings" or "create settings screen"
- User mentions "preferences", "app settings", or "configuration UI"
- User wants to add dark mode toggle, notifications settings, or about screen

## Pre-Generation Checks (CRITICAL)

### 1. Project Context Detection

Before generating, ALWAYS check:

```
# Find existing settings implementations
rg -l "SettingsView|PreferencesView|SettingsScreen" --type swift

# Check deployment target
cat Package.swift | grep -i "platform"
# Or check project.pbxproj for deployment target

# Detect architecture pattern
rg -l "Observable|ObservableObject|@EnvironmentObject" --type swift | head -5

# Check platform (iOS vs macOS)
rg "UIKit|UIApplication" --type swift | head -1  # iOS
rg "AppKit|NSApplication" --type swift | head -1  # macOS
```

### 2. Conflict Detection

If existing settings implementation found:
- Ask user: Extend existing, replace, or create separate?
- Check for naming conflicts with existing files

## Configuration Questions

Ask user via AskUserQuestion:

1. **Which sections do you need?**
   - Account (sign out, delete account)
   - Appearance (dark mode, app icon)
   - Notifications (push settings)
   - About (version, developer info)
   - Legal (terms, privacy)

2. **Platform?**
   - iOS (NavigationStack)
   - macOS (Settings scene / NavigationSplitView)
   - Both (adaptive)

3. **Additional features?**
   - App icon selector
   - Language selector
   - Data export
   - Cache clearing

## Generation Process

### Step 1: Create Core Files

Generate these files (customize based on answers):

```
Sources/Settings/
├── SettingsView.swift              # Main container
├── AppSettings.swift               # @AppStorage wrapper
├── Components/
│   └── SettingsRow.swift           # Reusable row component
└── Sections/
    ├── AppearanceSettingsView.swift
    ├── AccountSettingsView.swift
    ├── NotificationsSettingsView.swift
    ├── AboutSettingsView.swift
    └── LegalSettingsView.swift
```

### Step 2: Read Templates

Read templates from this skill:
- `templates/SettingsView.swift`
- `templates/AppSettings.swift`
- `templates/SettingsRow.swift`
- `templates/AppearanceSettingsView.swift`
- `templates/AccountSettingsView.swift`
- `templates/NotificationsSettingsView.swift`
- `templates/AboutSettingsView.swift`
- `templates/LegalSettingsView.swift`

### Step 3: Customize for Project

Adapt templates to match:
- Project naming conventions
- Existing architecture patterns
- Selected sections only
- Platform-specific code

### Step 4: Integration

**iOS Integration:**
```swift
// In any view
NavigationLink("Settings") {
    SettingsView()
}

// Or as sheet
.sheet(isPresented: $showSettings) {
    NavigationStack {
        SettingsView()
    }
}
```

**macOS Integration:**
```swift
// In App.swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Settings {
            SettingsView()
        }
    }
}
```

## Platform-Specific Considerations

### iOS
- Use `NavigationStack` with `List`
- Use `Form` for grouped appearance
- Link to Settings app for notifications: `UIApplication.openSettingsURLString`

### macOS
- Use `Settings` scene for standard preferences window
- Consider `TabView` for multiple sections
- Use `Form` with appropriate styling
- Support keyboard shortcut (⌘,)

### Cross-Platform
- Use conditional compilation for platform-specific features
- Abstract platform differences in AppSettings

## Generated Code Patterns

### AppStorage Wrapper
```swift
@Observable
final class AppSettings {
    static let shared = AppSettings()

    @AppStorage("appearance") var appearance: Appearance = .system
    @AppStorage("notificationsEnabled") var notificationsEnabled = true

    enum Appearance: String, CaseIterable {
        case system, light, dark
    }
}
```

### Settings Row Component
```swift
struct SettingsRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: () -> Content

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 28)
            Text(title)
            Spacer()
            content()
        }
    }
}
```

## Verification Checklist

After generation, verify:

- [ ] Settings accessible from main UI
- [ ] All selected sections present
- [ ] AppStorage persists between launches
- [ ] Dark mode toggle works correctly
- [ ] Links to external URLs work (privacy, terms)
- [ ] Platform-appropriate navigation
- [ ] Accessibility labels present
- [ ] VoiceOver navigation works

## Common Customizations

### Adding Custom Sections
```swift
// In SettingsView
Section("Custom") {
    NavigationLink("My Feature") {
        MyFeatureSettingsView()
    }
}
```

### Conditional Features
```swift
#if DEBUG
Section("Debug") {
    DebugSettingsView()
}
#endif
```

### Subscription Integration
```swift
if !subscriptionStatus.hasAccess {
    Section {
        Button("Upgrade to Pro") {
            showPaywall = true
        }
    }
}
```

## Related Skills

- `paywall-generator` - For subscription upgrade prompts in settings
- `auth-flow` - For account management integration
- `review-prompt` - Trigger review from settings (sparingly)

## References

- [Apple HIG: Settings](https://developer.apple.com/design/human-interface-guidelines/settings)
- [SwiftUI Settings Scene](https://developer.apple.com/documentation/swiftui/settings)
- [AppStorage Documentation](https://developer.apple.com/documentation/swiftui/appstorage)
