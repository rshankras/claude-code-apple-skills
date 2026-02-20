# NavigationStack Patterns

The primary navigation container for hierarchical drill-down interfaces. Replaced `NavigationView` in iOS 16.

## Core Pattern

```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
            .navigationTitle("Items")
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    }
}
```

Key elements:
- `NavigationStack` wraps the root view
- `NavigationLink(value:)` pushes a value onto the stack
- `.navigationDestination(for:)` maps value types to destination views
- Destination registration can be on any view inside the stack

## NavigationLink

### Value-Based Links (Modern)

```swift
// ✅ Modern — type-safe, works with programmatic navigation
NavigationLink(value: item) {
    Label(item.name, systemImage: item.icon)
}

// Register the destination once
.navigationDestination(for: Item.self) { item in
    ItemDetailView(item: item)
}
```

### Destination-Based Links (Legacy)

```swift
// ❌ Legacy — no programmatic navigation support, eager view creation
NavigationLink(destination: ItemDetailView(item: item)) {
    Label(item.name, systemImage: item.icon)
}
```

**Why?** Destination-based links create the destination view immediately (even before tap). Value-based links defer view creation and integrate with `NavigationPath`.

## Multiple Destination Types

Register multiple `.navigationDestination` modifiers for different types:

```swift
NavigationStack {
    List {
        Section("People") {
            ForEach(people) { person in
                NavigationLink(value: person) {
                    PersonRow(person: person)
                }
            }
        }
        Section("Places") {
            ForEach(places) { place in
                NavigationLink(value: place) {
                    PlaceRow(place: place)
                }
            }
        }
    }
    .navigationDestination(for: Person.self) { person in
        PersonDetailView(person: person)
    }
    .navigationDestination(for: Place.self) { place in
        PlaceDetailView(place: place)
    }
}
```

## Nested Navigation (Multi-Level Drill-Down)

Each pushed view can have its own `NavigationLink` values. They all share the same stack:

```swift
struct CategoryView: View {
    let category: Category

    var body: some View {
        List(category.items) { item in
            NavigationLink(value: item) {
                ItemRow(item: item)
            }
        }
        .navigationTitle(category.name)
    }
}
```

No need for nested `NavigationStack` — there is one stack at the root and all pushed views participate in it.

## Common Mistakes

### Nesting NavigationStacks

```swift
// ❌ Double navigation bar, broken back button
NavigationStack {
    NavigationStack {
        Text("Hello")
    }
}

// ❌ NavigationStack inside a pushed view
struct DetailView: View {
    var body: some View {
        NavigationStack {  // Wrong — creates a second stack
            Text("Detail")
        }
    }
}

// ✅ One NavigationStack at the root, pushed views are plain
struct DetailView: View {
    var body: some View {
        Text("Detail")
            .navigationTitle("Detail")
    }
}
```

### Missing navigationDestination

```swift
// ❌ NavigationLink pushes a value but no destination registered — tap does nothing
NavigationStack {
    NavigationLink(value: item) { Text(item.name) }
    // Forgot .navigationDestination(for: Item.self) { ... }
}
```

### navigationDestination Outside NavigationStack

```swift
// ❌ Destination registered outside the stack — never matched
VStack {
    NavigationStack {
        NavigationLink(value: item) { Text(item.name) }
    }
    .navigationDestination(for: Item.self) { item in  // Outside stack
        DetailView(item: item)
    }
}

// ✅ Register inside the stack
NavigationStack {
    NavigationLink(value: item) { Text(item.name) }
        .navigationDestination(for: Item.self) { item in
            DetailView(item: item)
        }
}
```

### Duplicate Destination Registrations

```swift
// ❌ Two registrations for same type — undefined behavior
NavigationStack {
    content
        .navigationDestination(for: Item.self) { item in ViewA(item: item) }
        .navigationDestination(for: Item.self) { item in ViewB(item: item) }
}

// ✅ One registration per type, use an enum for multiple routes
enum Route: Hashable {
    case viewA(Item)
    case viewB(Item)
}

NavigationStack {
    content
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .viewA(let item): ViewA(item: item)
            case .viewB(let item): ViewB(item: item)
            }
        }
}
```

## navigationDestination with isPresented

For conditional navigation (push based on a boolean):

```swift
@State private var showSettings = false

NavigationStack {
    Button("Settings") { showSettings = true }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
}
```

This pushes `SettingsView` when `showSettings` becomes `true` and pops it when it becomes `false`.

## NavigationStack with Explicit Path

For programmatic control, pass a `NavigationPath` or typed array:

```swift
// Type-erased path (supports mixed types)
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    RootView()
        .navigationDestination(for: Item.self) { item in
            ItemView(item: item)
        }
        .navigationDestination(for: Category.self) { cat in
            CategoryView(category: cat)
        }
}

// Typed path (single type only)
@State private var path: [Item] = []

NavigationStack(path: $path) {
    RootView()
        .navigationDestination(for: Item.self) { item in
            ItemView(item: item)
        }
}
```

See `programmatic-navigation.md` for full programmatic navigation patterns.

## Toolbar and Navigation Bar

```swift
NavigationStack {
    ContentView()
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)  // .large, .inline, .automatic
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") { }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .toolbarRole(.editor)  // Hides back button title, shows only chevron
}
```

## Searchable Navigation

```swift
NavigationStack {
    List(filteredItems) { item in
        NavigationLink(value: item) { ItemRow(item: item) }
    }
    .searchable(text: $searchText, prompt: "Search items")
    .navigationTitle("Items")
    .navigationDestination(for: Item.self) { item in
        ItemDetailView(item: item)
    }
}
```

## Checklist

- [ ] Using `NavigationStack` (not deprecated `NavigationView`)
- [ ] Using `NavigationLink(value:)` with `.navigationDestination(for:)`
- [ ] No nested `NavigationStack` in pushed views
- [ ] One `.navigationDestination` per type per stack
- [ ] Destination registered inside the `NavigationStack` scope
- [ ] Using `NavigationPath` if programmatic navigation is needed
- [ ] Navigation title set on inner views (not on `NavigationStack` itself)
