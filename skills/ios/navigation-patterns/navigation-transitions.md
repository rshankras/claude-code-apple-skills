# Navigation Transitions

Custom push/pop transition animations for `NavigationStack`. Available on iOS 18+/macOS 15+.

## Built-in Transitions

### Zoom Transition (iOS 18+)

Creates a zoom effect from a source view to the pushed destination:

```swift
struct ListView: View {
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                        .matchedTransitionSource(id: item.id, in: namespace)
                }
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
                    .navigationTransition(.zoom(sourceID: item.id, in: namespace))
            }
        }
    }
}
```

Key components:
- `@Namespace` creates a shared animation namespace
- `.matchedTransitionSource(id:in:)` marks the source element
- `.navigationTransition(.zoom(sourceID:in:))` on the destination view

The zoom transition animates from the source cell to a full-screen destination, and reverses on pop.

### Slide Transition

The default push/pop slide animation:

```swift
.navigationTransition(.slide)
```

This is the system default — you only need to specify it explicitly if overriding a different transition.

## Namespace Best Practices

### One Namespace Per List

```swift
// ✅ Single namespace, unique IDs per item
@Namespace private var namespace

ForEach(items) { item in
    NavigationLink(value: item) {
        ItemRow(item: item)
            .matchedTransitionSource(id: item.id, in: namespace)
    }
}
```

### Namespace with Sections

```swift
@Namespace private var namespace

// ✅ IDs must be unique across all sections in the same namespace
Section("Recent") {
    ForEach(recentItems) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
                .matchedTransitionSource(id: "recent-\(item.id)", in: namespace)
        }
    }
}
Section("All") {
    ForEach(allItems) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
                .matchedTransitionSource(id: "all-\(item.id)", in: namespace)
        }
    }
}
```

## matchedTransitionSource vs matchedGeometryEffect

These solve different problems:

| API | Purpose | Context |
|-----|---------|---------|
| `matchedTransitionSource` + `navigationTransition(.zoom)` | Navigation push/pop animation | Between `NavigationStack` pages |
| `matchedGeometryEffect` | Shared element animation within a single view | Within the same view hierarchy (e.g., hero animation in a layout change) |

```swift
// ❌ matchedGeometryEffect does NOT work for NavigationStack transitions
NavigationLink(value: item) {
    ItemRow(item: item)
        .matchedGeometryEffect(id: item.id, in: namespace)  // Wrong API
}

// ✅ Use matchedTransitionSource for navigation
NavigationLink(value: item) {
    ItemRow(item: item)
        .matchedTransitionSource(id: item.id, in: namespace)
}
```

## Grid to Detail Zoom

Common pattern for photo grids or card layouts:

```swift
struct PhotoGrid: View {
    @Namespace private var namespace
    let photos: [Photo]
    private let columns = [GridItem(.adaptive(minimum: 100))]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(photos) { photo in
                        NavigationLink(value: photo) {
                            PhotoThumbnail(photo: photo)
                                .matchedTransitionSource(id: photo.id, in: namespace)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Photos")
            .navigationDestination(for: Photo.self) { photo in
                PhotoDetailView(photo: photo)
                    .navigationTransition(.zoom(sourceID: photo.id, in: namespace))
            }
        }
    }
}
```

## Conditional Transitions

Apply different transitions based on content:

```swift
.navigationDestination(for: Route.self) { route in
    switch route {
    case .photo(let photo):
        PhotoDetailView(photo: photo)
            .navigationTransition(.zoom(sourceID: photo.id, in: namespace))
    case .settings:
        SettingsView()
            // No custom transition — uses default slide
    }
}
```

## Common Mistakes

### Mismatched IDs

```swift
// ❌ Source and destination use different IDs — no animation
.matchedTransitionSource(id: item.id, in: namespace)
// ...
.navigationTransition(.zoom(sourceID: "item-\(item.id)", in: namespace))

// ✅ Same ID value in both
.matchedTransitionSource(id: item.id, in: namespace)
// ...
.navigationTransition(.zoom(sourceID: item.id, in: namespace))
```

### Different Namespaces

```swift
// ❌ Source and destination use different namespaces
@Namespace private var sourceNamespace
@Namespace private var destNamespace

.matchedTransitionSource(id: item.id, in: sourceNamespace)
.navigationTransition(.zoom(sourceID: item.id, in: destNamespace))

// ✅ Same namespace for source and destination
@Namespace private var namespace

.matchedTransitionSource(id: item.id, in: namespace)
.navigationTransition(.zoom(sourceID: item.id, in: namespace))
```

### Namespace Declared in Wrong Scope

```swift
// ❌ Namespace in child view — destroyed when child is popped
struct ChildView: View {
    @Namespace private var namespace  // Dies with this view

    var body: some View {
        NavigationLink(value: item) {
            ItemRow(item: item)
                .matchedTransitionSource(id: item.id, in: namespace)
        }
    }
}

// ✅ Namespace in the view that owns the NavigationStack or its direct children
struct ParentView: View {
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            ItemList(namespace: namespace)
                .navigationDestination(for: Item.self) { item in
                    ItemDetail(item: item)
                        .navigationTransition(.zoom(sourceID: item.id, in: namespace))
                }
        }
    }
}
```

## Checklist

- [ ] Using `matchedTransitionSource` (not `matchedGeometryEffect`) for navigation transitions
- [ ] Source and destination use identical IDs and the same `@Namespace`
- [ ] `@Namespace` declared in a view that persists across the transition
- [ ] IDs are unique across the entire list/grid
- [ ] `.buttonStyle(.plain)` on `NavigationLink` in grids to avoid highlight artifacts
- [ ] Fallback behavior considered for iOS < 18 (zoom unavailable, default slide used)
