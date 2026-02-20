# NavigationSplitView Patterns

Multi-column navigation for iPad and macOS. Automatically adapts to compact size classes (iPhone) by collapsing into a single `NavigationStack`-like experience.

## Two-Column Layout

```swift
struct ContentView: View {
    @State private var selectedItem: Item?

    var body: some View {
        NavigationSplitView {
            List(items, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.name, systemImage: item.icon)
                }
            }
            .navigationTitle("Items")
        } detail: {
            if let item = selectedItem {
                ItemDetailView(item: item)
                    .id(item.id)  // Force recreation when selection changes
            } else {
                ContentUnavailableView("Select an Item",
                    systemImage: "doc",
                    description: Text("Choose an item from the sidebar"))
            }
        }
    }
}
```

Key points:
- The sidebar uses `List(selection:)` to bind selection
- Detail column shows a placeholder when nothing is selected
- `.id(item.id)` forces SwiftUI to recreate the detail view on selection change

## Three-Column Layout

```swift
struct ContentView: View {
    @State private var selectedCategory: Category?
    @State private var selectedItem: Item?

    var body: some View {
        NavigationSplitView {
            // Column 1: Sidebar
            List(categories, selection: $selectedCategory) { category in
                NavigationLink(value: category) {
                    Label(category.name, systemImage: category.icon)
                }
            }
            .navigationTitle("Categories")
        } content: {
            // Column 2: Content
            if let category = selectedCategory {
                List(category.items, selection: $selectedItem) { item in
                    NavigationLink(value: item) {
                        Text(item.name)
                    }
                }
                .navigationTitle(category.name)
            } else {
                ContentUnavailableView("Select a Category",
                    systemImage: "folder")
            }
        } detail: {
            // Column 3: Detail
            if let item = selectedItem {
                ItemDetailView(item: item)
                    .id(item.id)
            } else {
                ContentUnavailableView("Select an Item",
                    systemImage: "doc")
            }
        }
    }
}
```

## Column Width Control

```swift
NavigationSplitView {
    SidebarView()
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
} content: {
    ContentListView()
        .navigationSplitViewColumnWidth(min: 200, ideal: 300, max: 400)
} detail: {
    DetailView()
        .navigationSplitViewColumnWidth(min: 300, ideal: 500)
}
```

Use `ideal` width only for a fixed-width column:

```swift
.navigationSplitViewColumnWidth(250)  // Fixed width
```

## Column Visibility

Control which columns are visible programmatically:

```swift
@State private var columnVisibility: NavigationSplitViewVisibility = .all

NavigationSplitView(columnVisibility: $columnVisibility) {
    SidebarView()
} content: {
    ContentListView()
} detail: {
    DetailView()
}
```

Visibility options:
| Value | Behavior |
|-------|----------|
| `.all` | Show all columns |
| `.doubleColumn` | Show content + detail (hide sidebar) |
| `.detailOnly` | Show only detail column |
| `.automatic` | System decides based on size class |

Toggle sidebar visibility:

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Toggle Sidebar") {
            withAnimation {
                columnVisibility = columnVisibility == .all ? .detailOnly : .all
            }
        }
    }
}
```

## Split View Style

```swift
NavigationSplitView {
    SidebarView()
} detail: {
    DetailView()
}
.navigationSplitViewStyle(.balanced)       // Sidebar and detail share space
// .navigationSplitViewStyle(.prominentDetail)  // Detail takes priority
// .navigationSplitViewStyle(.automatic)        // System decides
```

## NavigationStack Inside Detail

When the detail column needs its own drill-down navigation:

```swift
NavigationSplitView {
    List(categories, selection: $selectedCategory) { category in
        NavigationLink(value: category) {
            Text(category.name)
        }
    }
} detail: {
    if let category = selectedCategory {
        // NavigationStack inside detail for drill-down
        NavigationStack {
            List(category.items) { item in
                NavigationLink(value: item) {
                    Text(item.name)
                }
            }
            .navigationTitle(category.name)
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    } else {
        ContentUnavailableView("Select a Category", systemImage: "folder")
    }
}
```

### When to Use NavigationStack Inside Detail

- Detail column needs hierarchical navigation (list → detail → sub-detail)
- Detail column needs programmatic push/pop

### When NOT to Use NavigationStack Inside Detail

```swift
// ❌ Unnecessary NavigationStack — detail has no drill-down
NavigationSplitView {
    SidebarView()
} detail: {
    NavigationStack {
        SimpleDetailView(item: selected)  // No NavigationLinks here
    }
}

// ✅ Just show the detail view directly
NavigationSplitView {
    SidebarView()
} detail: {
    SimpleDetailView(item: selected)
}
```

## Compact Adaptation (iPhone)

`NavigationSplitView` automatically collapses to a single-column `NavigationStack`-like experience on compact width (iPhone). The sidebar becomes the root and columns stack as push destinations.

Control the preferred compact column:

```swift
@State private var preferredColumn: NavigationSplitViewColumn = .sidebar

NavigationSplitView(preferredCompactColumn: $preferredColumn) {
    SidebarView()
} detail: {
    DetailView()
}
```

This controls which column is shown by default on compact. Setting `.detail` shows the detail view immediately on iPhone.

## Common Mistakes

### Putting NavigationStack Around NavigationSplitView

```swift
// ❌ Double navigation bars, broken layout
NavigationStack {
    NavigationSplitView {
        SidebarView()
    } detail: {
        DetailView()
    }
}

// ✅ NavigationSplitView is a top-level container
NavigationSplitView {
    SidebarView()
} detail: {
    DetailView()
}
```

### Not Handling Empty Selection

```swift
// ❌ Force unwrap or ignoring nil selection
NavigationSplitView {
    SidebarView()
} detail: {
    DetailView(item: selectedItem!)  // Crash when nil
}

// ✅ Always provide a placeholder
NavigationSplitView {
    SidebarView()
} detail: {
    if let item = selectedItem {
        DetailView(item: item)
    } else {
        ContentUnavailableView("No Selection", systemImage: "sidebar.left")
    }
}
```

### Not Using .id() on Detail View

```swift
// ❌ Detail view keeps stale state when selection changes
} detail: {
    if let item = selectedItem {
        ItemDetailView(item: item)  // @State inside won't reset
    }
}

// ✅ Force recreation with .id()
} detail: {
    if let item = selectedItem {
        ItemDetailView(item: item)
            .id(item.id)
    }
}
```

**Why?** SwiftUI may reuse the same view instance when the selection changes. Internal `@State` properties won't reset unless the view identity changes.

## Checklist

- [ ] Using `NavigationSplitView` (not deprecated `NavigationView(.columns)`)
- [ ] Handling `nil` selection with `ContentUnavailableView`
- [ ] Using `.id()` on detail views to force state reset
- [ ] Column widths set with `navigationSplitViewColumnWidth`
- [ ] Only wrapping detail in `NavigationStack` when drill-down is needed
- [ ] Testing compact (iPhone) behavior for adaptive layouts
- [ ] Not nesting `NavigationSplitView` inside `NavigationStack`
