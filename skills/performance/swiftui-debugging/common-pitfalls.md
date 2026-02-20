# Common SwiftUI Performance Pitfalls

Specific anti-patterns that cause SwiftUI performance problems, with concrete before/after fixes for each.

## 1. AnyView Type Erasure

### The Problem

`AnyView` wraps a view in a type-erased container. SwiftUI uses **type information** for its diffing algorithm -- when types are erased, SwiftUI cannot efficiently diff and must do more work:

- Cannot use structural identity (all `AnyView` instances have the same type)
- Cannot skip diffing subtrees when the type has not changed
- Prevents compile-time optimization of the view hierarchy

### Before (Slow)

```swift
// ❌ AnyView defeats SwiftUI's diffing optimization
func makeView(for item: Item) -> AnyView {
    switch item.kind {
    case .text:
        return AnyView(TextItemView(item: item))
    case .image:
        return AnyView(ImageItemView(item: item))
    case .video:
        return AnyView(VideoItemView(item: item))
    }
}

// Usage in ForEach compounds the problem
ForEach(items) { item in
    makeView(for: item)  // SwiftUI cannot diff between renders
}
```

### After (Fast)

```swift
// ✅ @ViewBuilder preserves type information for the compiler
@ViewBuilder
func makeView(for item: Item) -> some View {
    switch item.kind {
    case .text:
        TextItemView(item: item)
    case .image:
        ImageItemView(item: item)
    case .video:
        VideoItemView(item: item)
    }
}

// ✅ Or better: dedicated view struct (avoids large switch in @ViewBuilder)
struct ItemView: View {
    let item: Item

    var body: some View {
        switch item.kind {
        case .text:
            TextItemView(item: item)
        case .image:
            ImageItemView(item: item)
        case .video:
            VideoItemView(item: item)
        }
    }
}
```

### When AnyView Is Acceptable

`AnyView` has negligible cost in these cases:
- A single view used once (not in a list or `ForEach`)
- Prototyping / throwaway code
- Bridging to UIKit hosting controllers where type erasure is required

## 2. Object Creation in body

### The Problem

`body` can be called frequently (dozens of times per second during animation). Creating objects each time wastes CPU and memory:

```swift
// ❌ Creates a new DateFormatter every time body runs
// DateFormatter init is ~50x more expensive than a simple alloc
var body: some View {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    Text(formatter.string(from: date))
}
```

### Expensive Objects to Watch For

| Object | Cost of creation | Alternative |
|--------|-----------------|-------------|
| `DateFormatter` | ~5-10 microseconds | `static let` shared instance |
| `NumberFormatter` | ~5-10 microseconds | `static let` shared instance |
| `JSONDecoder` / `JSONEncoder` | Moderate | `static let` shared instance |
| `NSRegularExpression` | Moderate (compiles regex) | `static let` or Swift `Regex` literal |
| `NSPredicate` | Moderate | `static let` or reuse via `@State` |
| `URLSession` | Heavy | Use `URLSession.shared` or inject |
| View models / controllers | Heavy | `@State` or `@StateObject` |
| `AttributedString` with markdown | Moderate (parses markdown) | Cache in model or `@State` |

### After (Fast)

```swift
// ✅ Static shared formatter -- created once, reused forever
struct DateLabel: View {
    let date: Date

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        Text(Self.formatter.string(from: date))
    }
}

// ✅ Or use the modern formatted() API which handles caching internally
struct DateLabel: View {
    let date: Date

    var body: some View {
        Text(date.formatted(.dateTime.month().day().year()))
    }
}
```

## 3. Over-Observation with ObservableObject

### The Problem

With `ObservableObject`, changing **any** `@Published` property notifies **all** observers. If a large view observes a store with many properties, it re-evaluates on every change:

```swift
// ❌ All views observing AppState re-evaluate when ANY property changes
class AppState: ObservableObject {
    @Published var user: User?
    @Published var items: [Item] = []
    @Published var searchText = ""        // Typing here re-evaluates everything
    @Published var selectedTab = 0
    @Published var isOnboarding = false
    @Published var notifications: [Notification] = []
}
```

### Fix Option A: Migrate to @Observable (iOS 17+)

```swift
// ✅ Per-property observation -- views only update when their dependencies change
@Observable
class AppState {
    var user: User?
    var items: [Item] = []
    var searchText = ""          // Only views reading searchText re-evaluate
    var selectedTab = 0
    var notifications: [Notification] = []
}
```

### Fix Option B: Split Into Focused Stores (Pre-iOS 17)

```swift
// ✅ Each store has a narrow scope
class UserStore: ObservableObject {
    @Published var user: User?
}

class SearchStore: ObservableObject {
    @Published var searchText = ""
    @Published var results: [Item] = []
}

class NavigationStore: ObservableObject {
    @Published var selectedTab = 0
}
```

### Fix Option C: Extract Subviews to Narrow Scope

```swift
// ❌ Entire view re-evaluates when searchText changes
struct ContentView: View {
    @ObservedObject var store: AppState

    var body: some View {
        VStack {
            TextField("Search", text: $store.searchText)
            ItemList(items: store.items)
            UserBadge(user: store.user)
        }
    }
}

// ✅ Each subview only connects to what it needs
struct ContentView: View {
    @ObservedObject var store: AppState

    var body: some View {
        VStack {
            SearchBar(store: store)
            ItemList(items: store.items)
            UserBadge(user: store.user)
        }
    }
}

struct SearchBar: View {
    @ObservedObject var store: AppState  // Re-evaluates often, but it's tiny

    var body: some View {
        TextField("Search", text: $store.searchText)
    }
}
```

## 4. Expensive Computation in body

### The Problem

`body` runs on the main thread. Any expensive work directly blocks the UI:

```swift
// ❌ Filtering and sorting 10,000 items every time body runs
var body: some View {
    let filtered = items.filter { $0.matchesQuery(searchText) }
    let sorted = filtered.sorted { $0.date > $1.date }

    List(sorted) { item in
        ItemRow(item: item)
    }
}
```

### After: Cache Computed Results

```swift
// ✅ Compute on change, not on every body call
struct ItemListView: View {
    let items: [Item]
    @State private var searchText = ""
    @State private var filteredItems: [Item] = []

    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
            List(filteredItems) { item in
                ItemRow(item: item)
            }
        }
        .onChange(of: searchText) { _, newValue in
            filteredItems = items.filter { $0.matchesQuery(newValue) }
                .sorted { $0.date > $1.date }
        }
        .onAppear {
            filteredItems = items.sorted { $0.date > $1.date }
        }
    }
}
```

### After: Offload to Background for Large Data Sets

```swift
// ✅ Background computation for expensive operations
struct ItemListView: View {
    let items: [Item]
    @State private var searchText = ""
    @State private var filteredItems: [Item] = []

    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
            List(filteredItems) { item in
                ItemRow(item: item)
            }
        }
        .task(id: searchText) {
            // Runs on a background cooperative thread
            // Automatically cancelled if searchText changes again
            let query = searchText
            let allItems = items
            let results = await Task.detached {
                allItems.filter { $0.matchesQuery(query) }
                    .sorted { $0.date > $1.date }
            }.value
            filteredItems = results
        }
    }
}
```

## 5. Large Images Without Proper Sizing

### The Problem

Loading full-resolution images in a scrolling list causes memory spikes and decode latency:

```swift
// ❌ Loads full resolution, decodes on main thread
List(photos) { photo in
    Image(uiImage: UIImage(contentsOfFile: photo.path)!)
        .resizable()
        .frame(height: 200)
}
```

### After (Fast)

```swift
// ✅ AsyncImage handles loading and caching
List(photos) { photo in
    AsyncImage(url: photo.url) { image in
        image.resizable().scaledToFill()
    } placeholder: {
        Color.gray.opacity(0.2)
    }
    .frame(height: 200)
    .clipped()
}

// ✅ For local images: thumbnail generation off main thread
struct ThumbnailView: View {
    let imagePath: String
    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(height: 200)
        .clipped()
        .task {
            thumbnail = await UIImage(contentsOfFile: imagePath)?
                .byPreparingThumbnail(ofSize: CGSize(width: 400, height: 400))
        }
    }
}
```

## 6. Unnecessary @State Updates

### The Problem

Setting a `@State` variable to its current value still triggers a re-evaluation:

```swift
// ❌ Triggers re-evaluation even when value hasn't changed
.onReceive(timer) { _ in
    currentTime = Date()  // Always a new value, always triggers body
}

// ❌ Setting state in body (causes infinite loop risk)
var body: some View {
    let _ = { isReady = true }()  // NEVER modify state during body
    Text("Hello")
}
```

### After (Fast)

```swift
// ✅ Guard against redundant updates
.onReceive(timer) { _ in
    let newTime = Date()
    // Only update if the displayed value actually changes
    if Calendar.current.component(.second, from: newTime) !=
       Calendar.current.component(.second, from: currentTime) {
        currentTime = newTime
    }
}

// ✅ Use TimelineView for time-based updates (iOS 15+)
TimelineView(.periodic(from: .now, by: 1.0)) { context in
    Text(context.date.formatted(.dateTime.hour().minute().second()))
}
```

## 7. Deep View Hierarchies

### The Problem

Deeply nested view modifiers create large view trees that are expensive to diff:

```swift
// ❌ Each modifier adds a wrapper view to the tree
Text("Hello")
    .padding()
    .background(Color.blue)
    .cornerRadius(8)
    .padding()
    .background(Color.gray)
    .cornerRadius(12)
    .shadow(radius: 4)
    .padding()
    .background(Color.white)
    .cornerRadius(16)
```

### After: Consolidate Modifiers

```swift
// ✅ Flatten by using composite modifiers and fewer nesting levels
Text("Hello")
    .padding(8)
    .background(
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue)
    )
    .padding(8)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray)
            .shadow(radius: 4)
    )
    .padding(8)
```

### Custom ViewModifier for Reusable Combinations

```swift
// ✅ Encapsulate common modifier combinations
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// Usage: single modifier instead of three
Text("Hello").cardStyle()
```

## 8. Inefficient Conditional Rendering

### The Problem

Using `opacity(0)` or `hidden()` to hide views still keeps them in the view tree and evaluates their body:

```swift
// ❌ View is invisible but still evaluated and in the layout
ExpensiveView()
    .opacity(showExpensive ? 1 : 0)
```

### After: Conditional Inclusion

```swift
// ✅ View is not created at all when hidden
if showExpensive {
    ExpensiveView()
}

// ✅ Or use Group with optional for cleaner syntax
Group {
    if showExpensive {
        ExpensiveView()
    }
}
```

Note: this changes the view's structural identity (see view-identity.md). Use `opacity` when you need to preserve state; use `if` when you want to avoid the evaluation cost.

## Quick Diagnosis Table

| Symptom | Likely pitfall | Fix |
|---------|---------------|-----|
| Entire screen re-renders on any state change | Over-observation (#3) | Migrate to `@Observable` or split stores |
| List scrolling stutters | Eager loading, images (#5) | Use `LazyVStack`, async image loading |
| View body runs 100+ times/second | Unnecessary state updates (#6) | Guard against redundant state changes |
| Memory climbs while scrolling | Full-resolution images (#5) | Use thumbnails, `AsyncImage` |
| Initial load takes seconds | Eager container (#1 in lazy-loading.md) | Switch to lazy container |
| Type checker hangs during build | Large `@ViewBuilder` switch | Extract cases into separate view structs |
| Animation stutters | Expensive computation in body (#4) | Move to `.task {}` or `onChange` |
