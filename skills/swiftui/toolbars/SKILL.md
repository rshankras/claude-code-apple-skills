---
name: toolbars
description: Modern SwiftUI toolbar patterns including customizable toolbars, search integration, transition effects, and platform-specific behavior. Use when implementing or customizing toolbars in SwiftUI.
allowed-tools: [Read, Glob, Grep]
---

# SwiftUI Toolbars

Modern toolbar patterns for SwiftUI apps. Covers customizable toolbars, enhanced search integration, new placements, transition effects, and platform-specific considerations.

## When This Skill Activates

Use this skill when the user:
- Wants to add or customize toolbars
- Asks about customizable/user-configurable toolbars
- Needs search field in toolbar with specific placement
- Wants toolbar item transitions or animations
- Asks about toolbar placements (bottomBar, largeSubtitle, etc.)
- Needs platform-specific toolbar behavior (iOS vs macOS)
- Wants to reposition system toolbar items (search, sidebar)

## Decision Tree

```
What toolbar feature do you need?
|
+- User-customizable toolbar (add/remove/reorder items)
|  +- Use .toolbar(id:) with ToolbarItem(id:)
|
+- Search field in toolbar
|  +- Minimize to button -> .searchToolbarBehavior(.minimize)
|  +- Reposition search -> DefaultToolbarItem(kind: .search, placement:)
|
+- Toolbar transition/animation
|  +- Zoom transition from toolbar item -> .matchedTransitionSource(id:in:)
|  +- Hide glass background -> .sharedBackgroundVisibility(.hidden)
|
+- Custom subtitle area content
|  +- Use ToolbarItem(placement: .largeSubtitle)
|
+- System toolbar items with custom placement
|  +- DefaultToolbarItem(kind: .search/.sidebar, placement:)
```

## API Availability

| API | Minimum Version | Notes |
|-----|----------------|-------|
| `.toolbar { }` | iOS 14 | Basic toolbar |
| `ToolbarItem(placement:)` | iOS 14 | Standard placements |
| `.toolbar(id:)` | iOS 16 | Customizable toolbars |
| `ToolbarItem(id:)` | iOS 16 | Items in customizable toolbars |
| `ToolbarSpacer` | iOS 16 | Fixed and flexible spacers |
| `.searchable()` | iOS 15 | Search integration |
| `.searchToolbarBehavior(.minimize)` | iOS 17 | Minimized search button |
| `DefaultToolbarItem(kind:placement:)` | iOS 18 | Reposition system items |
| `ToolbarItem(placement: .largeSubtitle)` | iOS 18 | Subtitle area content |
| `.matchedTransitionSource(id:in:)` | iOS 18 | Toolbar transition source |
| `.sharedBackgroundVisibility()` | iOS 18 | Glass background control |

## Customizable Toolbars

Allow users to personalize toolbar items by adding, removing, and rearranging:

```swift
ContentView()
    .toolbar(id: "main-toolbar") {
        ToolbarItem(id: "tag") {
            TagButton()
        }
        ToolbarItem(id: "share") {
            ShareButton()
        }
        ToolbarSpacer(.fixed)
        ToolbarItem(id: "more") {
            MoreButton()
        }
    }
```

### Toolbar Spacers

```swift
ToolbarSpacer(.fixed)      // Fixed-width space
ToolbarSpacer(.flexible)   // Flexible space — pushes items apart
```

### Anti-Patterns

```swift
// ❌ Missing IDs in customizable toolbar — items can't be customized
.toolbar(id: "main") {
    ToolbarItem {           // No id parameter
        ShareButton()
    }
}

// ✅ Every item needs its own ID
.toolbar(id: "main") {
    ToolbarItem(id: "share") {
        ShareButton()
    }
}
```

## Enhanced Search Integration

### Minimized Search

Renders search field as a compact button that expands on tap:

```swift
@State private var searchText = ""

NavigationStack {
    RecipeList()
        .searchable(text: $searchText)
        .searchToolbarBehavior(.minimize)
}
```

### Repositioning Search

Move the default search field to a different toolbar position:

```swift
NavigationSplitView {
    AllCalendarsView()
} detail: {
    SelectedCalendarView()
        .searchable(text: $query)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                CalendarPicker()
            }
            ToolbarItem(placement: .bottomBar) {
                Invites()
            }
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                NewEventButton()
            }
        }
}
```

## System-Defined Toolbar Items

Reposition system items with custom placements:

```swift
.toolbar {
    DefaultToolbarItem(kind: .search, placement: .bottomBar)
    DefaultToolbarItem(kind: .sidebar, placement: .navigationBarLeading)
}
```

## Large Subtitle Placement

Place custom content in the navigation bar subtitle area:

```swift
NavigationStack {
    DetailView()
        .navigationTitle("Title")
        .navigationSubtitle("Subtitle")
        .toolbar {
            ToolbarItem(placement: .largeSubtitle) {
                CustomLargeNavigationSubtitle()
            }
        }
}
```

The `.largeSubtitle` placement takes precedence over the value provided to `navigationSubtitle(_:)`.

## Transition Effects

### Matched Transition from Toolbar

Create zoom transitions originating from a toolbar button:

```swift
struct ContentView: View {
    @State private var isPresented = false
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            DetailView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Show Sheet", systemImage: "globe") {
                            isPresented = true
                        }
                    }
                    .matchedTransitionSource(id: "world", in: namespace)
                }
                .sheet(isPresented: $isPresented) {
                    SheetView()
                        .navigationTransition(
                            .zoom(sourceID: "world", in: namespace))
                }
        }
    }
}
```

### Glass Background Control

Control the shared glass background on toolbar items:

```swift
ContentView()
    .toolbar(id: "main") {
        ToolbarItem(id: "build-status", placement: .principal) {
            BuildStatus()
        }
        .sharedBackgroundVisibility(.hidden)
    }
```

## Top 5 Mistakes

| # | Mistake | Fix |
|---|---------|-----|
| 1 | Missing `id` on ToolbarItem in customizable toolbar | Every item in `.toolbar(id:)` must have its own `id` parameter |
| 2 | Using `.searchToolbarBehavior(.minimize)` without `.searchable()` | Must pair with `.searchable()` modifier — `.minimize` only affects rendering |
| 3 | Putting `.matchedTransitionSource` on the Button instead of ToolbarItem | Apply `.matchedTransitionSource(id:in:)` on the `ToolbarItem`, not its content |
| 4 | Using `.largeSubtitle` alongside `.navigationSubtitle()` expecting both to show | `.largeSubtitle` takes precedence — the subtitle modifier value is hidden |
| 5 | Forgetting `placement:` on DefaultToolbarItem | Without explicit placement, system items use their default position |

## Platform Considerations

| Platform | Recommendations |
|----------|----------------|
| **iOS** | Bottom bar useful on iPhones. Use `.searchToolbarBehavior(.minimize)` for space efficiency. |
| **iPadOS** | Customizable toolbars valuable in productivity apps. Consider keyboard shortcuts. |
| **macOS** | Users expect toolbar customization. Use spacers for logical groupings. |

## Review Checklist

### Customizable Toolbars
- [ ] `.toolbar(id:)` has a unique, stable string identifier
- [ ] Every `ToolbarItem` within has its own unique `id`
- [ ] Spacers used to create logical groups of related items
- [ ] Toolbar tested with customization panel (long-press on iPadOS, right-click on macOS)

### Search Integration
- [ ] `.searchable()` paired with appropriate `.searchToolbarBehavior()`
- [ ] Search placement makes sense for the platform (bottom bar on iOS, toolbar on macOS)
- [ ] `DefaultToolbarItem(kind: .search)` used when repositioning is needed

### Transitions
- [ ] `.matchedTransitionSource` applied to `ToolbarItem`, not its content view
- [ ] Namespace declared with `@Namespace` at the view level
- [ ] Source ID matches between `.matchedTransitionSource` and `.navigationTransition(.zoom)`

### Platform
- [ ] Toolbar layouts tested on both iOS and macOS (if multiplatform)
- [ ] Bottom bar items appropriate for small screens
- [ ] Customizable toolbars provided for complex macOS apps

## References

- [SwiftUI ToolbarItemPlacement](https://developer.apple.com/documentation/SwiftUI/ToolbarItemPlacement)
- [SwiftUI CustomizableToolbarContent](https://developer.apple.com/documentation/SwiftUI/CustomizableToolbarContent)
- [SwiftUI SearchToolbarBehavior](https://developer.apple.com/documentation/SwiftUI/SearchToolbarBehavior)
- [SwiftUI DefaultToolbarItem](https://developer.apple.com/documentation/SwiftUI/DefaultToolbarItem)
- [SwiftUI ToolbarSpacer](https://developer.apple.com/documentation/SwiftUI/ToolbarSpacer)
