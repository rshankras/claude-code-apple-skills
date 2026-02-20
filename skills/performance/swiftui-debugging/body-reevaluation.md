# Body Re-evaluation

Understanding what triggers SwiftUI to call a view's `body` property, how to diagnose unnecessary re-evaluations, and how to minimize wasted work.

## What Triggers body Re-evaluation

SwiftUI calls `body` when it detects that a view's **dependencies** have changed. Dependencies include:

| Dependency type | Triggers body when... |
|----------------|----------------------|
| `@State` | The wrapped value changes |
| `@Binding` | The source value changes |
| `@Environment` | The environment value changes |
| `@Observable` object (iOS 17+) | A property **that body actually reads** changes |
| `@ObservedObject` / `@EnvironmentObject` | The `objectWillChange` publisher fires (any property) |
| Parent passes new value | An input property's value is different from last render |

Key insight: `body` being called does **not** necessarily mean the view re-renders on screen. SwiftUI diffs the output of `body` against the previous output and only updates what changed. However, calling `body` itself has a cost -- especially for complex view hierarchies.

## Self._printChanges()

The most important debugging tool for re-evaluation. Add it as the first line in `body`:

```swift
struct ItemDetailView: View {
    let item: Item
    @State private var isEditing = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let _ = Self._printChanges()
        // ... view content
    }
}
```

### Reading the Output

Output format: `ViewName: _dependency1, _dependency2 changed.`

| Output | Meaning |
|--------|---------|
| `ItemDetailView: _item changed.` | The `item` property received a new value from the parent |
| `ItemDetailView: _isEditing changed.` | The `@State` property `isEditing` was modified |
| `ItemDetailView: _colorScheme changed.` | The environment's color scheme changed |
| `ItemDetailView: @self changed.` | The view struct itself was recreated (parent's body ran) |
| `ItemDetailView: @identity changed.` | The view's identity changed (destroyed and recreated) |

### @self changed -- What It Means

`@self changed` means the parent view's `body` was called, which recreated this view's struct. Even if all property values are identical, SwiftUI may still call `body` because the struct was freshly allocated.

This is the most common source of "unnecessary" re-evaluations. Fix it by ensuring the parent does not needlessly recreate child views.

### Reducing @self Changes

```swift
// ❌ Parent rebuilds child every time its own body runs
struct ParentView: View {
    @State private var counter = 0

    var body: some View {
        VStack {
            Text("Count: \(counter)")
            Button("+1") { counter += 1 }
            ExpensiveChildView()  // @self changes every time counter changes
        }
    }
}

// ✅ Extract child so its body only runs when its own deps change
struct ParentView: View {
    @State private var counter = 0

    var body: some View {
        VStack {
            CounterSection(counter: $counter)
            ExpensiveChildView()  // Now in its own struct, isolated from counter
        }
    }
}

struct CounterSection: View {
    @Binding var counter: Int

    var body: some View {
        VStack {
            Text("Count: \(counter)")
            Button("+1") { counter += 1 }
        }
    }
}
```

## @Observable vs ObservableObject

This is the single largest performance improvement available in modern SwiftUI.

### ObservableObject: Whole-Object Observation (iOS 13+)

`ObservableObject` notifies **all** observing views when **any** `@Published` property changes:

```swift
// Every view observing this object re-evaluates when ANY property changes
class UserStore: ObservableObject {
    @Published var name = ""           // Change triggers all observers
    @Published var email = ""          // Change triggers all observers
    @Published var avatarURL: URL?     // Change triggers all observers
    @Published var preferences = Preferences()  // Change triggers all observers
}

struct NameLabel: View {
    @ObservedObject var store: UserStore

    var body: some View {
        let _ = Self._printChanges()
        // This body runs when email, avatarURL, or preferences change too!
        Text(store.name)
    }
}
```

### @Observable: Per-Property Observation (iOS 17+)

`@Observable` tracks which properties each view's `body` actually **reads** and only notifies when those specific properties change:

```swift
@Observable
class UserStore {
    var name = ""
    var email = ""
    var avatarURL: URL?
    var preferences = Preferences()
}

struct NameLabel: View {
    var store: UserStore

    var body: some View {
        let _ = Self._printChanges()
        // Only re-evaluates when store.name changes
        // Changes to email, avatarURL, preferences do NOT trigger this view
        Text(store.name)
    }
}
```

### Migration Benefit

| Scenario | ObservableObject | @Observable |
|----------|-----------------|-------------|
| 10 views observe a model with 5 properties | Changing 1 property re-evaluates all 10 views | Only views reading that specific property re-evaluate |
| List of 100 rows, each observing a shared store | All 100 rows re-evaluate on any change | Only affected rows re-evaluate |
| Form with 20 fields bound to a model | Every keystroke re-evaluates all 20 fields | Only the active field re-evaluates |

### @Observable Gotchas

**Reading a property outside body does not create observation:**

```swift
@Observable class Model {
    var value = 0
}

struct MyView: View {
    var model: Model

    // ❌ This read happens in init, not body -- no observation established
    var label: String { "Value: \(model.value)" }

    var body: some View {
        // ✅ Must read model.value inside body (directly or via computed property called from body)
        Text("Value: \(model.value)")
    }
}
```

**Computed properties that read observed properties do establish observation when called from body:**

```swift
@Observable class Model {
    var firstName = ""
    var lastName = ""

    var fullName: String { "\(firstName) \(lastName)" }
}

struct NameView: View {
    var model: Model

    var body: some View {
        // ✅ This observes both firstName and lastName
        // because fullName reads them, and fullName is called from body
        Text(model.fullName)
    }
}
```

## Minimizing Re-evaluations

### Strategy 1: Extract Subviews

The most effective technique. Each extracted subview only re-evaluates when its own dependencies change:

```swift
// ❌ Monolithic: entire view re-evaluates when any state changes
struct ProfileView: View {
    @State private var isEditingName = false
    @State private var isEditingBio = false
    var user: User

    var body: some View {
        VStack {
            // All of this re-evaluates when isEditingBio changes
            HStack {
                Text(user.name)
                Button("Edit") { isEditingName.toggle() }
            }
            // All of this re-evaluates when isEditingName changes
            HStack {
                Text(user.bio)
                Button("Edit") { isEditingBio.toggle() }
            }
        }
    }
}

// ✅ Split: each section only re-evaluates for its own state
struct ProfileView: View {
    var user: User

    var body: some View {
        VStack {
            NameSection(name: user.name)
            BioSection(bio: user.bio)
        }
    }
}

struct NameSection: View {
    let name: String
    @State private var isEditing = false

    var body: some View {
        HStack {
            Text(name)
            Button("Edit") { isEditing.toggle() }
        }
    }
}

struct BioSection: View {
    let bio: String
    @State private var isEditing = false

    var body: some View {
        HStack {
            Text(bio)
            Button("Edit") { isEditing.toggle() }
        }
    }
}
```

### Strategy 2: Use EquatableView or Equatable Conformance

Tell SwiftUI to skip body if properties are equal:

```swift
struct ExpensiveView: View, Equatable {
    let data: LargeDataSet

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data.id == rhs.data.id && lhs.data.version == rhs.data.version
    }

    var body: some View {
        // Complex rendering that should only happen when data truly changes
        ComplexChart(data: data)
    }
}

// Usage: .equatable() tells SwiftUI to use the Equatable conformance
ExpensiveView(data: chartData)
    .equatable()
```

### Strategy 3: Move State Down

Keep `@State` as close to the view that uses it as possible:

```swift
// ❌ State at the top causes the entire tree to re-evaluate
struct ContentView: View {
    @State private var searchText = ""  // Every keystroke re-evaluates everything

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText)
                ResultsList(query: searchText)
                // ... many other views that don't need searchText
                SidePanel()
                Footer()
            }
        }
    }
}

// ✅ Encapsulate search state in a dedicated view
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                SearchSection()  // Owns its own @State
                SidePanel()      // Not affected by search keystrokes
                Footer()         // Not affected by search keystrokes
            }
        }
    }
}

struct SearchSection: View {
    @State private var searchText = ""

    var body: some View {
        VStack {
            SearchBar(text: $searchText)
            ResultsList(query: searchText)
        }
    }
}
```

## Counting Body Evaluations

### Instruments SwiftUI Template

The **View Body** instrument counts how many times each view type's body is called:

1. **Xcode > Product > Profile** (Cmd+I)
2. Choose **SwiftUI** template
3. Record while reproducing the slow interaction
4. The **View Body** lane shows evaluation counts per view type
5. Sort by count to find views that evaluate most frequently

### Manual Counting with os_signpost

```swift
import os

private let logger = Logger(subsystem: "com.app", category: "ViewBody")

struct MyView: View {
    var body: some View {
        let _ = logger.debug("MyView.body evaluated")
        // ... view content
    }
}
```

Filter Console output by your subsystem to see evaluation frequency.

### What Counts Are Acceptable

| Scenario | Expected body count | Concerning if |
|----------|-------------------|---------------|
| View appears once | 1-2 | > 5 |
| Scroll through 100 rows | ~20-30 (visible + prefetch) | 100+ (not lazy) |
| Typing in a text field | 1 per keystroke for the field | 50+ other views also updating |
| Tapping a button | 1-3 for affected views | 20+ unrelated views updating |

## Environment Changes

Environment values like `colorScheme`, `dynamicTypeSize`, and `locale` affect **every** view in the subtree. When they change, a large portion of the view tree re-evaluates.

This is normal and expected -- but avoid reading environment values in views that do not need them:

```swift
// ❌ Reads colorScheme even though it does not use it
struct ItemRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let item: Item

    var body: some View {
        Text(item.title)  // Does not actually use colorScheme
    }
}

// ✅ Only read environment values you actually use in body
struct ItemRow: View {
    let item: Item

    var body: some View {
        Text(item.title)
    }
}
```
