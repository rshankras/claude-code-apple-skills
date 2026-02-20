---
name: ipad-patterns
description: iPadOS-specific patterns including Stage Manager, multi-window, drag and drop, keyboard shortcuts, pointer interactions, and Apple Pencil support. Use when building iPad-optimized features.
allowed-tools: [Read, Glob, Grep]
---

# iPad Patterns

Comprehensive guide for iPadOS-specific development patterns. Covers multitasking (Stage Manager, Split View, Slide Over), multi-window support, drag and drop, keyboard shortcuts, pointer interactions, Apple Pencil, and external display support. These patterns differentiate an iPad-optimized app from a scaled-up iPhone app.

## When This Skill Activates

- User is building or reviewing iPad-specific features
- User asks about Stage Manager, multi-window, or UIScene lifecycle
- User needs drag and drop (NSItemProvider, Transferable, UIDragInteraction)
- User wants keyboard shortcuts or discoverability overlay
- User asks about pointer/trackpad interactions or hover effects
- User is implementing Apple Pencil or PencilKit support
- User needs adaptive layouts for Split View, Slide Over, or size classes
- User asks about external display support
- User wants to make an iPhone app work well on iPad

## Decision Tree

```
What iPad feature are you building?
|
+-- Multi-window / Stage Manager / UIScene lifecycle
|   +-- multitasking.md
|      +-- Scene configuration, requestSceneSessionActivation
|      +-- Window management, scene delegates
|
+-- Split View / Slide Over / Adaptive Layout
|   +-- multitasking.md
|      +-- Size classes, compact/regular transitions
|      +-- NavigationSplitView column widths
|
+-- Drag and Drop
|   +-- drag-drop.md
|      +-- SwiftUI: .draggable() / .dropDestination()
|      +-- UIKit: UIDragInteraction / UIDropInteraction
|      +-- Transferable protocol, NSItemProvider
|
+-- Keyboard Shortcuts
|   +-- input-methods.md
|      +-- SwiftUI: .keyboardShortcut()
|      +-- UIKit: UIKeyCommand
|      +-- Discoverability overlay (Cmd hold)
|
+-- Pointer / Trackpad Interactions
|   +-- input-methods.md
|      +-- .hoverEffect(), UIPointerInteraction
|      +-- Custom pointer shapes, lift/highlight effects
|
+-- Apple Pencil / PencilKit
|   +-- input-methods.md
|      +-- PKCanvasView, PKDrawing
|      +-- Touch type filtering, Scribble
|
+-- External Display
    +-- multitasking.md
       +-- WindowGroup for external scenes
       +-- UIScreen notifications (legacy)
```

## API Availability

| API | Minimum Version | Reference |
|-----|----------------|-----------|
| `UIScene` / `UISceneDelegate` | iPadOS 13 | multitasking.md |
| `UISceneConfiguration` | iPadOS 13 | multitasking.md |
| `UIUserInterfaceSizeClass` | iPadOS 8 | multitasking.md |
| `NavigationSplitView` | iPadOS 16 | multitasking.md |
| `.horizontalSizeClass` / `.verticalSizeClass` | iPadOS 14 (SwiftUI) | multitasking.md |
| `.hoverEffect()` | iPadOS 13 | input-methods.md |
| `UIPointerInteraction` | iPadOS 13.4 | input-methods.md |
| `.keyboardShortcut()` | iPadOS 14 | input-methods.md |
| `UIKeyCommand` | iPadOS 7 | input-methods.md |
| `PencilKit` (PKCanvasView) | iPadOS 13 | input-methods.md |
| `UIPencilInteraction` | iPadOS 12.1 | input-methods.md |
| `.draggable()` / `.dropDestination()` | iPadOS 16 | drag-drop.md |
| `Transferable` protocol | iPadOS 16 | drag-drop.md |
| `UIDragInteraction` / `UIDropInteraction` | iPadOS 11 | drag-drop.md |
| `NSItemProvider` | iPadOS 11 | drag-drop.md |
| `WindowGroup` (multi-window) | iPadOS 16 (SwiftUI lifecycle) | multitasking.md |
| `.handlesExternalEvents` | iPadOS 14 | multitasking.md |
| Stage Manager | iPadOS 16 (M1+ iPads) | multitasking.md |
| `UISceneSession.requestSceneSessionActivation` | iPadOS 13 | multitasking.md |
| `.focusable()` / `@FocusState` | iPadOS 15 | input-methods.md |
| `FocusedValue` / `FocusedObject` | iPadOS 16 | input-methods.md |

## Top 5 Mistakes

| # | Mistake | Fix | Details |
|---|---------|-----|---------|
| 1 | Ignoring size classes, building fixed layouts | Use `@Environment(\.horizontalSizeClass)` to adapt between compact and regular | multitasking.md |
| 2 | No keyboard shortcuts for common actions | Add `.keyboardShortcut()` to primary actions (Cmd+N, Cmd+S, Delete) | input-methods.md |
| 3 | Missing drag and drop on list/grid items | Add `.draggable()` and `.dropDestination()` for content types users expect to move | drag-drop.md |
| 4 | No hover effects on interactive elements | Add `.hoverEffect()` to buttons, list rows, and custom controls | input-methods.md |
| 5 | Not supporting multiple windows (single-scene only) | Add `WindowGroup` support and handle `NSUserActivity` for state restoration | multitasking.md |

## Process

### 1. Identify iPad Features Needed

Read the user's code or requirements to determine:
- Is this a new iPad app or adapting an iPhone app?
- Which iPad-specific features are relevant (multitasking, drag/drop, keyboard, pencil)?
- Target iPadOS version and hardware (Stage Manager requires M1+)
- Whether the app uses SwiftUI lifecycle or UIKit AppDelegate

### 2. Load Relevant Reference Files

Based on the need, read from this directory:
- `multitasking.md` -- Stage Manager, multi-window, Split View, Slide Over, size classes, external display
- `input-methods.md` -- Keyboard shortcuts, pointer interactions, Apple Pencil, focus system
- `drag-drop.md` -- Drag and drop, Transferable protocol, NSItemProvider

### 3. Review or Recommend

Apply patterns from the reference files. Check for common issues using the review checklist below.

### 4. Cross-Reference

- For **navigation architecture** on iPad, see `ios/navigation-patterns/navigation-split-view.md`
- For **macOS Catalyst** concerns, see `macos/coding-best-practices/`
- For **toolbar patterns**, see `swiftui/toolbars/SKILL.md`
- For **animation and transitions**, see `design/animation-patterns/`

## Review Checklist

When reviewing code for iPad optimization, verify:

- [ ] **Size class adaptation** -- UI adapts to compact/regular width (Split View, Slide Over)
- [ ] **Keyboard shortcuts** -- primary actions have `.keyboardShortcut()` modifiers
- [ ] **Discoverability** -- shortcuts appear when user holds Command key
- [ ] **Pointer effects** -- interactive elements have `.hoverEffect()`
- [ ] **Drag and drop** -- list/grid items support `.draggable()` and `.dropDestination()`
- [ ] **Multi-window** -- app supports multiple windows if content model allows it
- [ ] **Scene restoration** -- state is preserved when scene disconnects/reconnects
- [ ] **Pencil support** -- drawing views filter touch types, PencilKit configured correctly
- [ ] **Column layout** -- `NavigationSplitView` column widths appropriate for iPad
- [ ] **No hardcoded widths** -- layouts use `.frame(minWidth:idealWidth:maxWidth:)` or geometry-based sizing
- [ ] **Context menus** -- long-press context menus on relevant items (also improve right-click with pointer)
- [ ] **Toolbar placement** -- actions placed in `.primaryAction`, `.secondaryAction`, or `.keyboard` as appropriate

## References

- [Preparing your iPadOS app for multitasking](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ipados_app_for_multitasking)
- [Adding drag and drop to a SwiftUI view](https://developer.apple.com/documentation/swiftui/adding-drag-and-drop)
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable)
- [Adding keyboard shortcuts](https://developer.apple.com/documentation/swiftui/adding-keyboard-shortcuts-to-a-swiftui-app)
- [Pointer interactions](https://developer.apple.com/documentation/uikit/pointer_interactions)
- [PencilKit](https://developer.apple.com/documentation/pencilkit)
- [UIScene](https://developer.apple.com/documentation/uikit/uiscene)
