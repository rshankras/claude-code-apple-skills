# Lazy vs Eager Loading

How SwiftUI loads views in stacks, lists, and grids -- and the performance consequences of choosing the wrong container.

## Eager vs Lazy Containers

### Eager Containers

`VStack`, `HStack`, and `ZStack` create **all** child views immediately, regardless of whether they are visible on screen:

```swift
// ❌ Creates ALL 10,000 rows immediately -- hangs on appear
ScrollView {
    VStack {
        ForEach(items) { item in  // 10,000 items
            ItemRow(item: item)   // All 10,000 created at once
        }
    }
}
```

### Lazy Containers

`LazyVStack`, `LazyHStack`, `LazyVGrid`, and `LazyHGrid` create child views **on demand** as they scroll into the visible area:

```swift
// ✅ Only creates visible rows + a small prefetch buffer
ScrollView {
    LazyVStack {
        ForEach(items) { item in  // 10,000 items
            ItemRow(item: item)   // ~20-30 created at a time
        }
    }
}
```

### List

`List` is **always lazy**. It manages its own scroll view and creates rows on demand:

```swift
// ✅ Always lazy -- handles large data sets efficiently
List(items) { item in
    ItemRow(item: item)
}
```

## When to Use Each Container

| Container | Use when | Creates views |
|-----------|----------|---------------|
| `VStack` / `HStack` | Few items (< 50) or all must render at once | All immediately |
| `LazyVStack` / `LazyHStack` | Many items in a `ScrollView` | On demand |
| `LazyVGrid` / `LazyHGrid` | Grid layout with many items | On demand |
| `List` | Scrollable list with system styling (swipe actions, separators) | On demand |

Rule of thumb: if you have a `ForEach` with more than ~50 items inside a `ScrollView`, use a lazy container.

## LazyVStack vs VStack: Performance Comparison

### The Cost of Eager Loading

For a list of 1,000 items, each with a moderately complex row:

| Metric | `VStack` | `LazyVStack` |
|--------|----------|-------------|
| Views created on appear | 1,000 | ~20-30 |
| Time to first frame | Seconds (hang) | Milliseconds |
| Memory at rest | All 1,000 rows in memory | Only visible rows |
| Scroll start latency | None (already created) | Small (creates as you scroll) |

### Practical Threshold

| Item count | Recommendation |
|-----------|---------------|
| 1-20 | `VStack` is fine |
| 20-50 | Either works; use `LazyVStack` if rows are complex |
| 50+ | Always use `LazyVStack` or `List` |
| 500+ | `List` or `LazyVStack` mandatory; consider pagination |

## LazyVStack Configuration

### Pinned Headers

```swift
ScrollView {
    LazyVStack(spacing: 12, pinnedViews: [.sectionHeaders]) {
        ForEach(sections) { section in
            Section {
                ForEach(section.items) { item in
                    ItemRow(item: item)
                }
            } header: {
                SectionHeader(title: section.title)
            }
        }
    }
}
```

### Alignment and Spacing

```swift
LazyVStack(alignment: .leading, spacing: 8) {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
```

## Common Pitfalls with Lazy Containers

### Pitfall 1: Child Views That Defeat Laziness

If a child view requests infinite height, the lazy container must measure all children to determine layout, defeating the purpose of laziness:

```swift
// ❌ .frame(maxHeight: .infinity) forces the lazy container to measure all children
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
                .frame(maxHeight: .infinity)  // Defeats laziness!
        }
    }
}

// ✅ Use fixed or intrinsic sizing
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
                .frame(height: 60)  // Fixed height, laziness preserved
        }
    }
}
```

### Pitfall 2: GeometryReader Inside Lazy Containers

`GeometryReader` proposes `.infinity` to its children. Inside a lazy container, this can cause layout issues:

```swift
// ❌ GeometryReader inside LazyVStack: layout problems
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            GeometryReader { proxy in
                ItemRow(item: item, width: proxy.size.width)
            }
        }
    }
}

// ✅ Use GeometryReader outside the lazy container
ScrollView {
    GeometryReader { proxy in
        LazyVStack {
            ForEach(items) { item in
                ItemRow(item: item, width: proxy.size.width)
            }
        }
    }
}

// ✅ Or use containerRelativeFrame (iOS 17+)
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
                .containerRelativeFrame(.horizontal)
        }
    }
}
```

### Pitfall 3: ScrollView With No Lazy Container

A `ScrollView` does **not** make its content lazy. It only provides scrolling:

```swift
// ❌ ScrollView alone does NOT make content lazy
ScrollView {
    ForEach(items) { item in  // All created immediately!
        ItemRow(item: item)
    }
}

// ✅ Must wrap in LazyVStack
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### Pitfall 4: Nesting ScrollViews

Nesting scroll views in the same direction causes undefined behavior:

```swift
// ❌ Nested vertical scroll views -- inner scroll may not work
ScrollView {
    LazyVStack {
        ForEach(sections) { section in
            ScrollView {  // Nested vertical scroll!
                ForEach(section.items) { item in
                    ItemRow(item: item)
                }
            }
        }
    }
}

// ✅ Use a single scroll view with sections
ScrollView {
    LazyVStack(pinnedViews: [.sectionHeaders]) {
        ForEach(sections) { section in
            Section {
                ForEach(section.items) { item in
                    ItemRow(item: item)
                }
            } header: {
                SectionHeader(title: section.title)
            }
        }
    }
}
```

## Grid Performance

### LazyVGrid

```swift
let columns = [
    GridItem(.adaptive(minimum: 150, maximum: 200))
]

ScrollView {
    LazyVGrid(columns: columns, spacing: 16) {
        ForEach(items) { item in
            ItemCell(item: item)
        }
    }
    .padding()
}
```

### Fixed vs Adaptive vs Flexible Columns

| Column type | Behavior | Performance note |
|------------|----------|-----------------|
| `.fixed(200)` | Exact width | Fastest layout calculation |
| `.flexible(minimum: 100, maximum: 300)` | Fills available space | Moderate layout cost |
| `.adaptive(minimum: 150)` | As many as fit | Most layout calculation |

For large grids (500+ items), prefer `.fixed()` columns to minimize layout computation.

## List Performance

### Built-in Optimizations

`List` provides features that lazy stacks do not:
- Cell reuse (like `UITableView`)
- Built-in swipe actions
- Separator management
- Edit mode with reordering and deletion

### List Optimization Tips

```swift
List(items) { item in
    ItemRow(item: item)
        .listRowSeparator(.hidden)  // Slightly faster if you don't need separators
}
.listStyle(.plain)  // .plain is faster than .insetGrouped for large lists
```

### When to Use List vs LazyVStack

| Feature | `List` | `LazyVStack` in `ScrollView` |
|---------|--------|------------------------------|
| Cell reuse | Yes | No (but still lazy creation) |
| Custom styling | Limited | Full control |
| Swipe actions | Built-in | Manual implementation |
| Section headers | Built-in | Manual with `pinnedViews` |
| Scroll performance | Generally better for 1000+ items | Good for most cases |
| Pull to refresh | `.refreshable()` works | `.refreshable()` works |

## Scroll Position and Prefetching

### ScrollViewReader for Programmatic Scrolling

```swift
ScrollViewReader { proxy in
    ScrollView {
        LazyVStack {
            ForEach(items) { item in
                ItemRow(item: item)
                    .id(item.id)
            }
        }
    }
    .onChange(of: selectedItemID) { _, newID in
        withAnimation {
            proxy.scrollTo(newID, anchor: .center)
        }
    }
}
```

### Data Prefetching for Pagination

Lazy containers do not have built-in prefetch callbacks like `UICollectionViewDataSourcePrefetching`. Implement manually:

```swift
struct PaginatedListView: View {
    @State private var items: [Item] = []
    @State private var isLoadingMore = false

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(items) { item in
                    ItemRow(item: item)
                        .onAppear {
                            if item == items.last {
                                loadMoreIfNeeded()
                            }
                        }
                }

                if isLoadingMore {
                    ProgressView()
                }
            }
        }
    }

    private func loadMoreIfNeeded() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        Task {
            let newItems = await fetchNextPage()
            items.append(contentsOf: newItems)
            isLoadingMore = false
        }
    }
}
```

## Debugging Lazy Loading Issues

### Confirming Laziness

Add a print statement to verify views are created lazily:

```swift
struct ItemRow: View {
    let item: Item

    init(item: Item) {
        self.item = item
        print("ItemRow created: \(item.id)")  // Should only print for visible rows
    }

    var body: some View {
        Text(item.title)
    }
}
```

If you see all 1,000 items printed at once, the container is not lazy.

### Measuring Scroll Frame Rate

Use CADisplayLink or the Core Animation Commits instrument in Instruments to measure frame rate during scrolling. Dropped frames (below 60fps / 120fps on ProMotion) indicate scroll performance issues.
