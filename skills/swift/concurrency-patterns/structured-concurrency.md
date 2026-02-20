# Structured Concurrency

Patterns for running concurrent work with automatic cancellation and scoped lifetimes. Prefer structured concurrency over unstructured `Task {}` whenever possible.

## async let — Fixed Parallel Operations

Run a known number of operations concurrently:

```swift
func loadDashboard() async throws -> Dashboard {
    async let user = fetchUser()
    async let posts = fetchPosts()
    async let notifications = fetchNotifications()

    // All three run concurrently. Await collects results.
    return try await Dashboard(
        user: user,
        posts: posts,
        notifications: notifications
    )
}
```

**Key properties:**
- Child tasks start immediately when `async let` is evaluated
- Results are awaited where they are used
- If the enclosing scope exits early (error thrown), pending tasks are automatically cancelled
- If one `async let` throws, the others are cancelled

### async let vs TaskGroup

| Feature | `async let` | `TaskGroup` |
|---------|------------|-------------|
| Number of tasks | Fixed, known at compile time | Dynamic, determined at runtime |
| Return types | Can be different per binding | Must be the same (or use enum) |
| Syntax | Simple variable bindings | Closure with `group.addTask` |
| Use when | 2-5 parallel calls with different types | Processing a collection in parallel |

```swift
// ✅ async let — different return types, fixed count
async let user = fetchUser()        // -> User
async let settings = fetchSettings() // -> Settings

// ✅ TaskGroup — same return type, dynamic count
let images = try await withThrowingTaskGroup(of: UIImage.self) { group in
    for url in imageURLs {
        group.addTask { try await downloadImage(url) }
    }
    var results: [UIImage] = []
    for try await image in group {
        results.append(image)
    }
    return results
}
```

## TaskGroup — Dynamic Parallel Operations

### Collecting Results

```swift
func fetchAllItems(ids: [UUID]) async throws -> [Item] {
    try await withThrowingTaskGroup(of: Item.self) { group in
        for id in ids {
            group.addTask {
                try await fetchItem(id: id)
            }
        }

        var items: [Item] = []
        for try await item in group {
            items.append(item)
        }
        return items
    }
}
```

### Limiting Concurrency

Prevent overwhelming the system with too many parallel tasks:

```swift
func downloadImages(urls: [URL]) async throws -> [UIImage] {
    try await withThrowingTaskGroup(of: UIImage.self) { group in
        let maxConcurrent = 4
        var index = 0
        var results: [UIImage] = []

        // Start initial batch
        for _ in 0..<min(maxConcurrent, urls.count) {
            group.addTask { try await self.downloadImage(urls[index]) }
            index += 1
        }

        // As each completes, start the next
        for try await image in group {
            results.append(image)
            if index < urls.count {
                group.addTask { try await self.downloadImage(urls[index]) }
                index += 1
            }
        }

        return results
    }
}
```

### DiscardingTaskGroup (Swift 5.9+)

For fire-and-forget child tasks where you don't need to collect results. More memory-efficient because completed child task values are discarded immediately.

```swift
// ✅ Discarding — good for side effects (logging, notifications, cache warming)
await withDiscardingTaskGroup { group in
    for item in items {
        group.addTask {
            await cacheService.warm(item)
        }
    }
    // No iteration needed — results are discarded
}

// ❌ Don't use regular TaskGroup if you ignore results — leaks memory
await withTaskGroup(of: Void.self) { group in
    for item in items {
        group.addTask { await cacheService.warm(item) }
    }
    // Must iterate even for Void: for await _ in group { }
    // Or results accumulate in memory
}
```

Use `withThrowingDiscardingTaskGroup` if child tasks can throw.

## .task Modifier — SwiftUI View Lifecycle

### Basic .task

```swift
struct ItemListView: View {
    @State private var items: [Item] = []

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
        .task {
            // Runs when view appears
            // Automatically cancelled when view disappears
            items = await fetchItems()
        }
    }
}
```

**Key properties:**
- Starts an async task when the view appears
- Automatically cancels the task when the view disappears
- The task inherits the view's actor isolation (usually `@MainActor`)

### .task(id:) — Re-run on Value Change

```swift
struct ItemDetailView: View {
    let itemID: UUID
    @State private var item: Item?

    var body: some View {
        Group {
            if let item {
                ItemContent(item: item)
            } else {
                ProgressView()
            }
        }
        .task(id: itemID) {
            // Runs when view appears AND when itemID changes
            // Previous task is cancelled before new one starts
            item = await fetchItem(id: itemID)
        }
    }
}
```

**Why use `.task(id:)` over `.onChange` + manual Task?**

```swift
// ❌ Manual pattern — error-prone, must handle cancellation yourself
@State private var loadTask: Task<Void, Never>?

.onChange(of: itemID) { _, newID in
    loadTask?.cancel()
    loadTask = Task {
        item = await fetchItem(id: newID)
    }
}

// ✅ .task(id:) handles cancellation automatically
.task(id: itemID) {
    item = await fetchItem(id: itemID)
}
```

### .task vs Task {} in .onAppear

```swift
// ❌ Unstructured task — not cancelled when view disappears
.onAppear {
    Task {
        items = await fetchItems()  // May complete after view is gone
    }
}

// ✅ Structured — automatically cancelled on disappear
.task {
    items = await fetchItems()
}
```

The `.onAppear` + `Task {}` pattern creates an unstructured task that outlives the view. If the view disappears quickly (e.g., fast tab switching), the task keeps running and may update `@State` on a deallocated view.

## Task Cancellation

### Checking Cancellation

```swift
func processLargeDataset(_ items: [Item]) async throws -> [ProcessedItem] {
    var results: [ProcessedItem] = []
    for item in items {
        // Check before each expensive operation
        try Task.checkCancellation()  // Throws CancellationError if cancelled
        results.append(await processItem(item))
    }
    return results
}
```

### Cooperative Cancellation in Loops

```swift
func processItems(_ items: [Item]) async -> [ProcessedItem] {
    var results: [ProcessedItem] = []
    for item in items {
        guard !Task.isCancelled else { break }  // Non-throwing check
        results.append(await processItem(item))
    }
    return results
}
```

### withTaskCancellationHandler

For proactive cleanup when a task is cancelled (e.g., aborting a network request):

```swift
func downloadFile(from url: URL) async throws -> Data {
    let request = URLRequest(url: url)
    let (data, _) = try await withTaskCancellationHandler {
        try await URLSession.shared.data(for: request)
    } onCancel: {
        // Called immediately when the task is cancelled
        // Runs on an arbitrary thread — must be Sendable-safe
        URLSession.shared.getAllTasks { tasks in
            tasks.filter { $0.originalRequest?.url == url }.forEach { $0.cancel() }
        }
    }
    return data
}
```

### Task.yield()

Cooperatively yield execution in CPU-heavy loops to let other tasks run:

```swift
func processHugeArray(_ items: [Item]) async -> [ProcessedItem] {
    var results: [ProcessedItem] = []
    for (index, item) in items.enumerated() {
        results.append(process(item))
        if index.isMultiple(of: 100) {
            await Task.yield()  // Let other tasks run every 100 items
        }
    }
    return results
}
```

## Task Priorities

```swift
Task(priority: .userInitiated) { await loadVisibleContent() }
Task(priority: .background) { await prefetchNextPage() }
Task(priority: .low) { await updateSearchIndex() }
```

### Priority Escalation

If a high-priority task awaits a low-priority task, the low-priority task's priority is escalated:

```swift
let backgroundTask = Task(priority: .background) {
    await heavyComputation()
}

// Later, a high-priority task needs the result:
Task(priority: .userInitiated) {
    let result = await backgroundTask.value  // Escalates backgroundTask to .userInitiated
}
```

This prevents priority inversion but can cause unexpected scheduling behavior. Design your concurrency so high-priority paths don't depend on low-priority tasks.

## Common Mistakes

### Creating Tasks Where Structured Concurrency Works

```swift
// ❌ Unstructured — no automatic cancellation, harder to reason about
func loadData() {
    let task1 = Task { await fetchUsers() }
    let task2 = Task { await fetchPosts() }
    // Must manually manage cancellation
}

// ✅ Structured — automatic cancellation, clear lifetime
func loadData() async {
    async let users = fetchUsers()
    async let posts = fetchPosts()
    let (u, p) = await (users, posts)
}
```

### Not Iterating TaskGroup Results

```swift
// ❌ Memory leak — completed task values accumulate
await withTaskGroup(of: Data.self) { group in
    for url in urls {
        group.addTask { await download(url) }
    }
    // Never iterate group — results pile up in memory
}

// ✅ Always iterate, or use withDiscardingTaskGroup for Void results
await withTaskGroup(of: Data.self) { group in
    for url in urls {
        group.addTask { await download(url) }
    }
    for await data in group {
        process(data)
    }
}
```

### Ignoring Task Cancellation

```swift
// ❌ Runs to completion even when parent is cancelled
func processAll(_ items: [Item]) async -> [Result] {
    var results: [Result] = []
    for item in items {
        results.append(await process(item))  // Never checks cancellation
    }
    return results
}

// ✅ Cooperative cancellation
func processAll(_ items: [Item]) async throws -> [Result] {
    var results: [Result] = []
    for item in items {
        try Task.checkCancellation()
        results.append(await process(item))
    }
    return results
}
```

## Checklist

- [ ] Using `async let` for fixed parallel operations (not `Task {}`)
- [ ] Using `TaskGroup` for dynamic parallel operations
- [ ] Using `withDiscardingTaskGroup` when results aren't needed
- [ ] `.task` modifier instead of `.onAppear` + `Task {}`
- [ ] `.task(id:)` instead of `.onChange` + manual task cancellation
- [ ] Cooperative cancellation in long loops (`Task.checkCancellation()` or `Task.isCancelled`)
- [ ] `Task.yield()` in CPU-heavy loops to prevent hangs
- [ ] TaskGroup results iterated (or using discarding variant)
