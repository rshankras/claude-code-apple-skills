# Programmatic Navigation

Patterns for controlling navigation state in code: pushing, popping, deep linking coordination, and state restoration.

## NavigationPath

`NavigationPath` is a type-erased stack of navigation values. It supports mixed types and provides the core API for programmatic navigation.

```swift
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    HomeView()
        .navigationDestination(for: Item.self) { item in
            ItemDetailView(item: item)
        }
        .navigationDestination(for: Category.self) { category in
            CategoryView(category: category)
        }
}
```

### Push

```swift
path.append(item)           // Push Item view
path.append(category)       // Push Category view (mixed types)
```

### Pop

```swift
path.removeLast()           // Pop one level
path.removeLast(2)          // Pop two levels
```

### Pop to Root

```swift
path = NavigationPath()     // Clear entire stack — returns to root
```

### Check Stack

```swift
path.isEmpty                // True if at root
path.count                  // Number of items on stack
```

## Typed Path (Single Type)

When all navigation destinations are the same type, use a plain array:

```swift
@State private var path: [Item] = []

NavigationStack(path: $path) {
    ListView()
        .navigationDestination(for: Item.self) { item in
            ItemDetailView(item: item)
        }
}

// Push
path.append(item)

// Pop to root
path.removeAll()

// Build a specific stack (e.g., from deep link)
path = [parentItem, childItem, grandchildItem]
```

**Advantage:** Direct array access, subscripting, filtering. Use when you only navigate to one type.

## Navigation Coordinator

Centralize navigation logic in an `@Observable` class:

```swift
@Observable
final class NavigationCoordinator {
    var path = NavigationPath()

    func navigate(to item: Item) {
        path.append(item)
    }

    func navigate(to category: Category) {
        path.append(category)
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Deep link handling
    func handle(deepLink: DeepLink) {
        popToRoot()
        switch deepLink {
        case .item(let id):
            if let item = ItemStore.shared.item(for: id) {
                path.append(item)
            }
        case .category(let id):
            if let category = CategoryStore.shared.category(for: id) {
                path.append(category)
            }
        }
    }
}
```

Usage:

```swift
struct AppView: View {
    @State private var coordinator = NavigationCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: Item.self) { item in
                    ItemDetailView(item: item)
                }
                .navigationDestination(for: Category.self) { category in
                    CategoryView(category: category)
                }
        }
        .environment(coordinator)
        .onOpenURL { url in
            if let deepLink = DeepLink(url: url) {
                coordinator.handle(deepLink: deepLink)
            }
        }
    }
}

// Any child view can navigate programmatically
struct SomeChildView: View {
    @Environment(NavigationCoordinator.self) private var coordinator

    var body: some View {
        Button("Go to item") {
            coordinator.navigate(to: item)
        }
    }
}
```

## Tab Navigation + Per-Tab Paths

For apps with tabs where each tab has independent navigation:

```swift
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var searchPath = NavigationPath()
    var profilePath: [ProfileDestination] = []

    func switchTab(_ tab: AppTab, resettingNavigation: Bool = false) {
        if selectedTab == tab && !homePath(for: tab).isEmpty {
            // Tapping active tab pops to root (standard iOS behavior)
            popToRoot(for: tab)
        } else {
            selectedTab = tab
        }
        if resettingNavigation {
            popToRoot(for: tab)
        }
    }

    func popToRoot(for tab: AppTab) {
        switch tab {
        case .home: homePath = NavigationPath()
        case .search: searchPath = NavigationPath()
        case .profile: profilePath.removeAll()
        }
    }
}
```

## State Restoration

Save and restore navigation state across app launches using `NavigationPath.CodableRepresentation`:

```swift
@Observable
final class NavigationCoordinator {
    var path = NavigationPath()

    private static let savedPathKey = "savedNavigationPath"

    var codableRepresentation: NavigationPath.CodableRepresentation? {
        path.codable
    }

    func save() {
        guard let representation = path.codable else { return }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(representation) {
            UserDefaults.standard.set(data, forKey: Self.savedPathKey)
        }
    }

    func restore() {
        guard let data = UserDefaults.standard.data(forKey: Self.savedPathKey),
              let representation = try? JSONDecoder().decode(
                  NavigationPath.CodableRepresentation.self, from: data
              ) else { return }
        path = NavigationPath(representation)
    }
}
```

**Requirements:** All value types pushed onto the path must conform to `Codable` (in addition to `Hashable`).

```swift
// ✅ Works — conforms to both Hashable and Codable
struct Item: Hashable, Codable {
    let id: UUID
    let name: String
}

// ❌ Won't compile for state restoration — missing Codable
struct Item: Hashable {
    let id: UUID
    let name: String
}
```

Save on scene phase change:

```swift
struct AppView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var coordinator = NavigationCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                coordinator.save()
            }
        }
        .onAppear {
            coordinator.restore()
        }
    }
}
```

## Deep Link Coordination

Connect URL-based deep links to programmatic navigation:

```swift
enum DeepLink {
    case item(id: UUID)
    case category(id: UUID)
    case profile(username: String)
    case settings

    init?(url: URL) {
        // Handle custom scheme: myapp://item/UUID
        // Handle universal link: https://example.com/item/UUID
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        let pathParts = components.path.split(separator: "/").map(String.init)

        switch pathParts.first {
        case "item":
            guard let idString = pathParts.dropFirst().first,
                  let id = UUID(uuidString: idString) else { return nil }
            self = .item(id: id)
        case "category":
            guard let idString = pathParts.dropFirst().first,
                  let id = UUID(uuidString: idString) else { return nil }
            self = .category(id: id)
        case "profile":
            guard let username = pathParts.dropFirst().first else { return nil }
            self = .profile(username: username)
        case "settings":
            self = .settings
        default:
            return nil
        }
    }
}
```

Handle in the coordinator:

```swift
.onOpenURL { url in
    if let deepLink = DeepLink(url: url) {
        coordinator.handle(deepLink: deepLink)
    }
}
```

For full deep link infrastructure (URL schemes, Universal Links, AASA files), see the `generators/deep-linking/` skill.

## Passing Data Back (Pop with Result)

SwiftUI has no built-in "pop with result" API. Common patterns:

### Closure Callback

```swift
struct PickerView: View {
    let onSelect: (Item) -> Void

    var body: some View {
        List(items) { item in
            Button(item.name) {
                onSelect(item)
            }
        }
    }
}

// In the calling view
.navigationDestination(for: PickerRoute.self) { _ in
    PickerView { selectedItem in
        self.selectedItem = selectedItem
        path.removeLast()  // Pop after selection
    }
}
```

### Environment / Observable Shared State

```swift
@Observable
final class SelectionState {
    var pickedItem: Item?
}

// Parent sets up state, child writes to it
// Parent observes changes via onChange
```

## Common Mistakes

### Mutating Path During View Update

```swift
// ❌ Causes "Modifying state during view update" warning
var body: some View {
    if someCondition {
        path.append(item)  // Don't mutate state in body
    }
}

// ✅ Mutate in response to actions or onChange
.onChange(of: someCondition) { _, newValue in
    if newValue {
        path.append(item)
    }
}
```

### Not Resetting Path on Deep Link

```swift
// ❌ Deep link pushes on top of existing stack — confusing
func handle(deepLink: DeepLink) {
    path.append(deepLink.destination)
}

// ✅ Clear stack first, then navigate
func handle(deepLink: DeepLink) {
    path = NavigationPath()          // Pop to root
    path.append(deepLink.destination) // Navigate to target
}
```

### Storing NavigationPath in @Observable Without @State

```swift
// ❌ Path doesn't trigger view updates when not @State
struct ContentView: View {
    let path = NavigationPath()
}

// ✅ Path must be @State (or in an @Observable class used via @State)
@State private var path = NavigationPath()

// ✅ Or in an @Observable coordinator injected as @State
@State private var coordinator = NavigationCoordinator()
NavigationStack(path: $coordinator.path) { }
```

## Checklist

- [ ] `NavigationPath` is `@State` or inside an `@Observable` class held by `@State`
- [ ] Pop-to-root implemented (clear path) for tab re-tap or deep links
- [ ] Deep links reset the navigation stack before pushing
- [ ] All path value types conform to `Hashable` (and `Codable` if state restoration needed)
- [ ] State saved on `scenePhase == .background` if restoration needed
- [ ] Navigation mutations happen in action closures, not in `body`
- [ ] Navigation coordinator injected via `.environment()` for child view access
