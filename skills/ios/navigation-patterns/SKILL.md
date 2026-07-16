---
name: navigation-patterns
description: SwiftUI navigation architecture patterns including NavigationStack, NavigationSplitView, TabView, programmatic navigation, and custom transitions. Use when reviewing or building navigation, fixing navigation bugs, or architecting app flow.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# Navigation Patterns

Comprehensive guide for SwiftUI navigation architecture on iOS, iPadOS, and macOS. Covers the modern navigation APIs (iOS 16+/macOS 13+) with patterns for common and advanced use cases.

## When This Skill Activates

- User is building or reviewing navigation architecture
- User has navigation-related bugs (stack not updating, back button issues, state loss)
- User asks about NavigationStack, NavigationSplitView, TabView, or NavigationPath
- User needs programmatic navigation (push, pop, pop-to-root)
- User is implementing deep linking that connects to navigation
- User asks about navigation transitions or animations
- User is choosing between navigation approaches for their app

## Decision Tree

Use this to pick the right navigation container:

```
What is the app structure?
│
├─ Flat sections (3-5 top-level areas)
│  └─ TabView → see tab-view.md
│
├─ Hierarchical drill-down (list → detail)
│  └─ NavigationStack → see navigation-stack.md
│
├─ Sidebar + content (macOS / iPad)
│  ├─ Two columns → NavigationSplitView → see navigation-split-view.md
│  └─ Three columns → NavigationSplitView → see navigation-split-view.md
│
└─ Combined (tabs with drill-down, sidebar with stacks)
   └─ TabView + NavigationStack per tab
      OR NavigationSplitView + NavigationStack in detail
```

## Quick Reference

| Pattern | Container | Min OS | Reference |
|---------|-----------|--------|-----------|
| Simple drill-down | `NavigationStack` | iOS 16 | `navigation-stack.md` |
| Value-based links | `NavigationLink(value:)` | iOS 16 | `navigation-stack.md` |
| Programmatic push/pop | `NavigationPath` | iOS 16 | `programmatic-navigation.md` |
| Pop to root | `path = NavigationPath()` | iOS 16 | `programmatic-navigation.md` |
| State restoration | `NavigationPath.CodableRepresentation` | iOS 16 | `programmatic-navigation.md` |
| Two-column layout | `NavigationSplitView` | iOS 16 | `navigation-split-view.md` |
| Three-column layout | `NavigationSplitView` | iOS 16 | `navigation-split-view.md` |
| Column visibility | `NavigationSplitViewVisibility` | iOS 16 | `navigation-split-view.md` |
| Tab bar | `TabView` | iOS 13 | `tab-view.md` |
| Customizable tabs | `Tab` + `TabView` | iOS 18 | `tab-view.md` |
| Sidebar tabs (iPad) | `.tabViewStyle(.sidebarAdaptable)` | iOS 18 | `tab-view.md` |
| Zoom transition | `.navigationTransition(.zoom)` | iOS 18 | `navigation-transitions.md` |
| Custom transitions | `NavigationTransition` | iOS 18 | `navigation-transitions.md` |

## Navigation Design Rules (WWDC22)

The container APIs above decide *how* navigation is built; these rules decide *whether* it's designed right.

**Tab bars**
- Tabs are top-level **content categories**, not arbitrary groupings — balance features across tabs so each carries real weight.
- ❌ Never auto-switch tabs in response to an action taken in another tab — confirm in place instead.

**Push vs modal**
- Push (right-to-left) = traversing the app's hierarchy. Modal (slides up — covering the tab bar is *by design*) = a self-contained task apart from the hierarchy.
- Modals come in three types: simple task, multi-step task, full-screen content.
- Limit modals presented over modals — each stacked layer buries the user deeper in transient state.

**Wayfinding**
- Nav bar title = the current location; the back button shows the *previous* screen's title.

## The Three Cookbook Recipes (WWDC22)

Nearly every app is one of these three shapes. Pick one per scene, then lift its navigation state.

1. **Pushable stack** — `NavigationStack(path:)` + `NavigationLink(value:)` + `.navigationDestination(for:)`. Pop-to-root is `path.removeAll()`; a deep link is just assigning the path.
2. **Multi-column without stacks** — `NavigationSplitView` + `List(selection:)` in each leading column. Value links auto-drive the next column's selection, so programmatic navigation is setting the selection value.
3. **Split + stack (Photos-style)** — `NavigationSplitView` with a `NavigationStack(path:)` *inside the detail column*: sidebar selection picks the collection, the stack drills into it.

**Rules that make the recipes hold up:**
- Build with `NavigationSplitView` even for iPhone-first apps — it auto-collapses to a single stack in compact width, and iPad/Mac layouts come free.
- Lift navigation state: exactly one bound `path`/selection per container. That single source of truth is what makes pop-to-root, deep links, and restoration one-line operations.

**State restoration:** persist through `@SceneStorage("navigation")` plus a `.task` that restores once on appear, then streams subsequent path changes back into storage.

## Process

### 1. Identify Navigation Needs

Read the user's code or requirements to determine:
- App structure (flat, hierarchical, sidebar-based)
- Target platforms (iOS only, iPad adaptive, macOS)
- Whether programmatic navigation is needed
- Deep linking requirements

### 2. Load Relevant Reference Files

Based on the need, read from this directory:
- `navigation-stack.md` — NavigationStack, NavigationLink, navigationDestination
- `navigation-split-view.md` — Two/three column layouts, column control, adaptive behavior
- `tab-view.md` — TabView, iOS 18 customizable tabs, sidebar mode
- `programmatic-navigation.md` — NavigationPath, state restoration, coordinators, pop-to-root
- `navigation-transitions.md` — Custom push/pop transitions (iOS 18+)

### 3. Review or Recommend

Apply patterns from the reference files. Check for common mistakes:

- [ ] Using deprecated `NavigationView` instead of `NavigationStack`/`NavigationSplitView`
- [ ] Using `NavigationLink(destination:)` instead of `NavigationLink(value:)` + `.navigationDestination`
- [ ] Placing `NavigationStack` in a sidebar/content column of `NavigationSplitView` (a stack belongs only in the detail column — Recipe 3)
- [ ] `.navigationDestination` attached inside a lazy container (destination may never register)
- [ ] Missing `.navigationDestination` registration for a value type
- [ ] NavigationPath not `@State` or not in the right scope
- [ ] Multiple NavigationStacks competing for the same navigation context
- [ ] Hard-coding navigation instead of using `NavigationPath` for programmatic control
- [ ] Not handling deep links through the navigation system

### 4. Cross-Reference

- For **deep linking URL handling**, see `generators/deep-linking/` skill
- For **navigation animations**, see `design/animation-patterns/transitions.md`
- For **macOS sidebar patterns**, see `macos/ui-review-tahoe/swiftui-macos.md`

## References

- [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)
- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [NavigationPath](https://developer.apple.com/documentation/swiftui/navigationpath)
- [TabView](https://developer.apple.com/documentation/swiftui/tabview)
- [Migrating to new navigation types](https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types)
