# View Identity

How SwiftUI decides whether two views are the **same view** (update in place) or **different views** (destroy and recreate). Getting identity wrong causes lost state, broken animations, and unnecessary work.

## Two Kinds of Identity

### Structural Identity (Implicit)

SwiftUI assigns identity based on a view's **position in the view hierarchy**. Two views at the same position in the same parent are considered the same view across renders.

```swift
// These two Text views have different structural identities
// because they are at different positions in the VStack
VStack {
    Text("First")   // position 0
    Text("Second")  // position 1
}
```

### Explicit Identity

You override structural identity using `.id()` or `ForEach` identifiers. This tells SwiftUI: "this specific value identifies this view."

```swift
ForEach(items, id: \.id) { item in
    ItemRow(item: item)  // identity = item.id
}

DetailView(item: selectedItem)
    .id(selectedItem.id)  // identity = selectedItem.id
```

## How SwiftUI Uses Identity

| Identity comparison | SwiftUI behavior |
|--------------------|-----------------|
| Same identity, same type | **Update** existing view (preserves `@State`) |
| Same identity, different type | **Destroy** old view, **create** new view |
| Different identity | **Destroy** old view, **create** new view |
| No identity change | **Diff** the view's properties and update as needed |

Key consequence: when identity changes, **all `@State` is lost** and the view is recreated from scratch.

## .id() Modifier

### When to Use .id()

Force SwiftUI to treat a view as a completely new instance:

```swift
// Force recreation when switching between items
// Without .id(), SwiftUI would try to update the same view,
// which can show stale state or skip the appear animation
DetailView(item: selectedItem)
    .id(selectedItem.id)
```

### Stable vs Unstable Identifiers

```swift
// ✅ Stable: database ID, UUID, or model-provided unique key
ForEach(items, id: \.databaseID) { item in
    ItemRow(item: item)
}

// ✅ Stable: using Identifiable conformance
ForEach(items) { item in  // uses item.id automatically
    ItemRow(item: item)
}

// ❌ Unstable: array index on a mutable array
// When items are inserted/deleted, indices shift and
// SwiftUI matches the wrong data to the wrong view
ForEach(Array(items.enumerated()), id: \.offset) { index, item in
    ItemRow(item: item)
}

// ❌ Unstable: random value or Date()
// Generates a new identity every render, destroying all state
DetailView(item: item)
    .id(UUID())  // NEVER do this -- recreates view every body call
```

### Performance Impact of Unstable .id()

When `.id()` changes every render:
1. SwiftUI destroys the entire view subtree (including all child views)
2. All `@State` and `@StateObject` are lost
3. `onAppear` fires again
4. Animations treat it as a new view (insertion transition, not update)
5. Any in-flight async `task` is cancelled and restarted

This is the single most expensive identity mistake. A view with `N` children all get destroyed and recreated.

## Conditional View Branching

### The if/else Identity Problem

`if`/`else` branches create **different structural identities**:

```swift
// ❌ Problem: toggling isLoading destroys and recreates ContentView
// because the two branches are different structural positions
if isLoading {
    ProgressView()
} else {
    ContentView()
}
```

When `isLoading` changes from `true` to `false`:
- `ProgressView` is destroyed (it existed at the "if-true" branch)
- `ContentView` is created from scratch (it appears at the "if-else" branch)
- All `@State` inside `ContentView` resets

### When Destruction Is Acceptable

If the two branches show completely different content (like loading vs loaded), this destruction is fine and expected. The problem arises when you use `if`/`else` to toggle **modifiers** on the same view:

```swift
// ❌ Bad: destroys and recreates the same Text view
if isHighlighted {
    Text(item.title)
        .foregroundStyle(.yellow)
        .bold()
} else {
    Text(item.title)
        .foregroundStyle(.primary)
}

// ✅ Good: same structural identity, just different modifier values
Text(item.title)
    .foregroundStyle(isHighlighted ? .yellow : .primary)
    .bold(isHighlighted)
```

### Ternary Expressions vs if/else in View Body

```swift
// ✅ Ternary: single structural identity, SwiftUI diffs the values
RoundedRectangle(cornerRadius: 12)
    .fill(isSelected ? Color.blue : Color.gray)
    .frame(height: isExpanded ? 200 : 80)

// ❌ if/else: two different structural identities
if isSelected {
    RoundedRectangle(cornerRadius: 12).fill(.blue)
} else {
    RoundedRectangle(cornerRadius: 12).fill(.gray)
}
```

### AnyView and Identity

`AnyView` erases type information, which breaks structural identity tracking:

```swift
// ❌ AnyView: SwiftUI cannot track structural identity across renders
func makeView() -> AnyView {
    if condition {
        return AnyView(ViewA())
    } else {
        return AnyView(ViewB())
    }
}

// ✅ @ViewBuilder: preserves structural identity
@ViewBuilder
func makeView() -> some View {
    if condition {
        ViewA()
    } else {
        ViewB()
    }
}
```

See common-pitfalls.md for more on `AnyView` performance costs.

## ForEach Identity

### How ForEach Uses Identifiers

`ForEach` maps each data element to a view using the `id` key path. SwiftUI uses these identifiers to:
- Match existing views to updated data (minimizing recreations)
- Animate insertions, removals, and reorderings
- Preserve `@State` in each row

```swift
// ✅ Identifiable conformance (cleanest)
struct Item: Identifiable {
    let id: UUID
    var title: String
}
ForEach(items) { item in
    ItemRow(item: item)
}

// ✅ Explicit id key path
ForEach(items, id: \.uniqueKey) { item in
    ItemRow(item: item)
}
```

### Duplicate Identifiers

If two items share the same `id`, SwiftUI behavior is **undefined** -- it may show duplicates, skip items, or crash:

```swift
// ❌ Dangerous: if two items have the same title, behavior is undefined
ForEach(items, id: \.title) { item in
    ItemRow(item: item)
}

// ✅ Always use a truly unique identifier
ForEach(items, id: \.id) { item in
    ItemRow(item: item)
}
```

## Debugging Identity Issues

### Symptoms of Identity Problems

| Symptom | Likely cause |
|---------|-------------|
| View `@State` resets unexpectedly | Identity changed, causing view recreation |
| `onAppear` fires repeatedly on the same view | Identity keeps changing (unstable `.id()`) |
| Animations show insertion/removal instead of smooth update | View destroyed and recreated instead of updated |
| Scroll position resets in a list | `ForEach` identifiers changed for existing items |
| Text fields lose focus and typed content | The `TextField` view got a new identity |

### Using _printChanges to Detect Recreation

```swift
var body: some View {
    let _ = Self._printChanges()
    // If you see "@identity changed" in the output,
    // SwiftUI considers this a brand-new view instance
    Text("Content")
}
```

Output `@identity changed` means the view was **destroyed and recreated**, not updated in place. This usually means an unstable `.id()` or a structural identity change from `if`/`else` branching.

### Verifying with onAppear / onDisappear

```swift
DetailView(item: item)
    .id(item.id)
    .onAppear { print("DetailView appeared: \(item.id)") }
    .onDisappear { print("DetailView disappeared") }
```

If you see rapid appear/disappear cycles for the same content, the identity is unstable.

## Fix Patterns Summary

| Problem | Fix |
|---------|-----|
| `.id(UUID())` or `.id(Date())` | Use a stable model identifier |
| `if`/`else` toggling modifiers on same view | Use ternary expressions for modifier values |
| `ForEach` with array index as id | Use `Identifiable` conformance or stable key path |
| State lost on navigation | Add `.id(item.id)` to force correct recreation timing |
| Duplicate `ForEach` identifiers | Ensure model has truly unique `id` property |
