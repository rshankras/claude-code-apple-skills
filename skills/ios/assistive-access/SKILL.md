---
name: assistive-access
description: Assistive Access implementation for cognitive accessibility including simplified scenes, navigation icons, runtime detection, and design principles. Use when optimizing apps for Assistive Access mode.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# Assistive Access

Guide for implementing Assistive Access support in iOS and iPadOS apps. Assistive Access (iOS 17+/iPadOS 17+) provides a streamlined system experience for people with cognitive disabilities, presenting simplified interfaces with large controls and reduced complexity.

## When This Skill Activates

- User wants to add Assistive Access support to their app
- User asks about cognitive accessibility or simplified interfaces
- User mentions `AssistiveAccess`, `UISupportsAssistiveAccess`, or assistive access scenes
- User needs runtime detection of Assistive Access mode
- User is reviewing accessibility compliance for cognitive disabilities
- User asks about `.assistiveAccessNavigationIcon`

## Setup

### The Three Integration Levels (WWDC25 238)

- **No adoption**: the app runs in a reduced frame to leave room for the system back
  button always shown along the bottom (back returns to the Assistive Access Home
  Screen). The reduced frame keeps apps built for specific device sizes rendering
  correctly.
- **Full screen as-is** (`UISupportsFullScreenInAssistiveAccess`): for apps already
  designed for cognitive accessibility — AAC apps and similar tools. The app looks
  identical to normal, just full-screen; requires layout that adapts to arbitrary sizes.
- **`AssistiveAccess` scene** (`UISupportsAssistiveAccess` + the scene below, iOS 26/
  iPadOS 26): a tailored experience where native controls automatically render in the
  large, prominent Assistive Access style and follow the user's grid-or-rows layout
  setting. Recommended when unsure (WWDC25 238).

The Assistive Access mode itself shipped with iOS 17; the `AssistiveAccess` scene type,
`UISupportsAssistiveAccess` key, and `.assistiveAccess` preview trait are iOS 26 APIs.

### Step 1: Declare Support in Info.plist

Add these keys to your app's `Info.plist` so the system lists your app as an "Optimized App" in Assistive Access configuration:

```xml
<key>UISupportsAssistiveAccess</key>
<true/>
```

For AAC (Augmentative and Alternative Communication) apps or similar tools that need full-screen presentation:

```xml
<key>UISupportsAssistiveAccess</key>
<true/>
<key>UISupportsFullScreenInAssistiveAccess</key>
<true/>
```

### Step 2: Add the Assistive Access Scene

#### SwiftUI

Add an `AssistiveAccess` scene alongside your standard `WindowGroup`:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        AssistiveAccess {
            AssistiveAccessContentView()
        }
    }
}
```

The system automatically uses the `AssistiveAccess` scene when the device is in Assistive Access mode and falls back to `WindowGroup` otherwise.

#### UIKit

Use `UIHostingSceneDelegate` with a static `rootScene` property that returns an `AssistiveAccess` scene:

```swift
class AssistiveAccessSceneDelegate: UIHostingSceneDelegate {
    static var rootScene: some Scene {
        AssistiveAccess {
            AssistiveAccessContentView()
        }
    }
}
```

Register the scene configuration in your app delegate with the `.windowAssistiveAccessApplication` role:

```swift
func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
) -> UISceneConfiguration {
    let config = UISceneConfiguration(
        name: "Assistive Access",
        sessionRole: .windowAssistiveAccessApplication
    )
    config.delegateClass = AssistiveAccessSceneDelegate.self
    return config
}
```

## Runtime Detection

Detect whether Assistive Access mode is active at runtime to conditionally adjust behavior:

```swift
struct AdaptiveView: View {
    @Environment(\.accessibilityAssistiveAccessEnabled) var assistiveAccessEnabled

    var body: some View {
        if assistiveAccessEnabled {
            SimplifiedView()
        } else {
            FullFeatureView()
        }
    }
}
```

Use this to hide advanced features, reduce information density, or switch to larger controls even within a shared view hierarchy.

## Navigation Icons

Assistive Access uses large grid-based navigation, and icons paired with text reduce
cognitive load. Give **every navigation title** an icon, not just the root (WWDC25 238):

```swift
// Paired with the navigation title of each screen
DrawView()
    .navigationTitle("Draw")
    .assistiveAccessNavigationIcon(systemImage: "hand.draw.fill")

// Using a custom image from the asset catalog
GalleryView()
    .navigationTitle("Gallery")
    .assistiveAccessNavigationIcon(Image("custom-icon"))
```

## Design Principles

These six principles guide what to build in your Assistive Access scene.

### 1. Distill to Core Functionality

Identify the one or two most essential features and present only those. Remove secondary workflows, settings screens, and advanced options.

```swift
// ✅ Good: Only the core action
struct AssistiveAccessContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            MessageListView()
            ComposeButton()
        }
    }
}

// ❌ Bad: Exposing the full app with all tabs
struct AssistiveAccessContentView: View {
    var body: some View {
        TabView {
            MessagesTab()
            ContactsTab()
            SettingsTab()
            ProfileTab()
        }
    }
}
```

### 2. Clear, Prominent Controls

Use large buttons with ample spacing. Native SwiftUI controls automatically adopt Assistive Access styling, so prefer standard `Button`, `Toggle`, and `Picker` over custom controls.

```swift
// ✅ Good: Large, standard controls with generous spacing
VStack(spacing: 20) {
    Button("Call Mom") {
        placeCall(to: .mom)
    }
    .font(.title)

    Button("Call Dad") {
        placeCall(to: .dad)
    }
    .font(.title)
}
.padding(24)

// ❌ Bad: Small, densely packed custom controls
HStack(spacing: 4) {
    SmallCustomButton("Mom", size: 30)
    SmallCustomButton("Dad", size: 30)
    SmallCustomButton("Sis", size: 30)
    SmallCustomButton("Bro", size: 30)
}
```

### 3. Multiple Representations

Pair text labels with icons so users can rely on whichever representation they understand best.

```swift
// ✅ Good: Text and icon together
Button {
    startCamera()
} label: {
    Label("Take Photo", systemImage: "camera.fill")
        .font(.title2)
}

// ❌ Bad: Icon only with no visible label
Button {
    startCamera()
} label: {
    Image(systemName: "camera.fill")
}
```

### 4. Intuitive Navigation

Use step-by-step flows with **one decision per screen** and reasonably few steps — reorder
decisions if needed. The session's drawing-app demo inserted a dedicated color-selection
view between "Draw" and the canvas, replacing the in-canvas color picker, so everyone
arrives at the canvas with a color already chosen (WWDC25 238). Avoid deep hierarchies or
complex branching.

The system back button traverses back up your `NavigationStack` automatically — do not
build your own back affordance (WWDC25 238).

```swift
// ✅ Good: Linear step-by-step flow
NavigationStack {
    ChooseRecipientView()
        .navigationTitle("Send Message")
}

// ❌ Bad: Multi-level nested navigation with side branches
NavigationSplitView {
    SidebarView()
} content: {
    CategoryView()
} detail: {
    DetailView()
}
```

### 5. Safe Interactions

Prevent irreversible actions. Prefer **removing destructive actions from the Assistive
Access scene entirely** — the session's demo dropped undo-stroke and delete-drawing — and
where one must stay, confirm it twice with clear, understandable prompts (WWDC25 238).

```swift
// ✅ Good: Confirmation before destructive action
Button("Delete Photo", role: .destructive) {
    showDeleteConfirmation = true
}
.confirmationDialog(
    "Delete this photo?",
    isPresented: $showDeleteConfirmation,
    titleVisibility: .visible
) {
    Button("Delete", role: .destructive) {
        deletePhoto()
    }
    Button("Keep Photo", role: .cancel) {}
}

// ❌ Bad: Immediate destructive action with no confirmation
Button("Delete") {
    deletePhoto()
}
```

### 6. No Timed Interactions

Redesign anything that disappears or changes state after a timeout — auto-dismissing
toasts, countdown confirmations, rotating banners. Everyone works at their own pace, and
UI that acts on a timer creates pressure and errors (WWDC25 238).

```swift
// ✅ Good: Persistent confirmation the user dismisses
if didSave {
    Label("Saved", systemImage: "checkmark.circle.fill")
    Button("OK") { didSave = false }
}

// ❌ Bad: Toast that vanishes after 3 seconds
.onAppear {
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { didSave = false }
}
```

## Native Controls Auto-Style

When the device is in Assistive Access mode, standard SwiftUI controls (Button, Toggle, Picker, NavigationStack, and others) automatically adopt larger sizes and simplified styling. You do not need to add extra styling or conditional modifiers for these controls. Use native controls whenever possible and let the system handle the presentation.

## Testing

### Xcode Previews

Use the `.assistiveAccess` preview trait to see your Assistive Access scene in the canvas:

```swift
#Preview(traits: .assistiveAccess) {
    AssistiveAccessContentView()
}
```

### On-Device Testing

1. Go to Settings > Accessibility > Assistive Access
2. Follow the setup flow to configure Assistive Access
3. Select your app from the list of optimized apps
4. Enter Assistive Access mode to test the full experience
5. Triple-click the side button to exit Assistive Access mode

## Top Mistakes

| Mistake | Why It Fails | Fix |
|---------|-------------|-----|
| Missing `UISupportsAssistiveAccess` in Info.plist | App does not appear in the optimized apps list during Assistive Access setup | Add the key and set it to `true` |
| No `AssistiveAccess` scene in the App body | System falls back to the standard `WindowGroup`, showing the full complex UI | Add an `AssistiveAccess { }` scene |
| Exposing all app features in the Assistive Access scene | Overwhelming for users with cognitive disabilities; defeats the purpose | Distill to 1-2 core features |
| Custom-drawn controls instead of native SwiftUI | Misses automatic Assistive Access styling from the system | Use standard Button, Toggle, Picker |
| Icon-only buttons without text labels | Users may not understand the icon; no fallback representation | Use `Label` with both text and icon |
| Destructive actions without confirmation | Risk of accidental, irreversible data loss | Remove them from the AA scene, or confirm twice |
| Timed UI (auto-dismissing toasts, countdowns) | Users work at their own pace; state changing on a timer causes errors | Make state changes user-driven; remove timeouts |
| Custom back buttons inside the AA scene | Duplicates the system back button, which already traverses `NavigationStack` | Rely on the system back button |
| Only testing in standard mode | Assistive Access layout and behavior differ from standard mode | Test with `.assistiveAccess` preview trait and on-device |

## Review Checklist

When reviewing an app's Assistive Access implementation, verify each item:

- [ ] `UISupportsAssistiveAccess` is `true` in Info.plist
- [ ] `UISupportsFullScreenInAssistiveAccess` is set if the app is an AAC tool
- [ ] `AssistiveAccess` scene is present in the App body
- [ ] Assistive Access scene contains only 1-2 core features
- [ ] All controls use native SwiftUI components (Button, Toggle, Picker)
- [ ] All buttons have both text and icon via `Label`
- [ ] Navigation is linear and shallow (no deep hierarchies); one decision per screen
- [ ] No custom back affordance — the system back button traverses the NavigationStack
- [ ] No timed interactions — nothing disappears or changes state on a timeout
- [ ] Destructive actions removed from the scene, or double-confirmed
- [ ] Every navigation title has an `.assistiveAccessNavigationIcon`
- [ ] Runtime detection via `@Environment(\.accessibilityAssistiveAccessEnabled)` is used where shared views need conditional behavior
- [ ] Xcode previews use `#Preview(traits: .assistiveAccess)`
- [ ] Tested on-device in Assistive Access mode

## References

- [Assistive Access](https://developer.apple.com/documentation/assistiveaccess)
- [AssistiveAccess Scene](https://developer.apple.com/documentation/swiftui/assistiveaccess)
- [Accessibility on Apple Platforms](https://developer.apple.com/accessibility/)
- [Human Interface Guidelines: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
