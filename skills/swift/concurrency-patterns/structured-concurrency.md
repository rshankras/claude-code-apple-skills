# Structured Concurrency

Patterns for running concurrent work with automatic cancellation and scoped lifetimes. Prefer structured concurrency over unstructured `Task {}` whenever possible. Task-tree rules sourced from Apple's WWDC21 "Explore structured concurrency in Swift" (10134) and WWDC23 "Beyond the basics of structured concurrency" (10170).

## The Task Tree Rules (WWDC21 10134, WWDC23 10170)

- Calling an async function does **not** create a task — the same task executes the callee. Tasks are created only explicitly: `async let`, task groups, `Task {}`, `Task.detached`.
- The tree governs three things: **cancellation, priority, and task-local values**. Structured tasks "live to the end of the scope where they are declared, like local variables, and are automatically cancelled when they go out of scope."
- **A parent task can only finish when all of its child tasks have finished** — enforced even under abnormal control flow: if a scope exits by a thrown error with an un-awaited `async let` child, Swift automatically marks the child cancelled and awaits it before exiting.
- Cancelling a parent cancels all descendants automatically. Children inherit the parent's priority; to background a whole subtree, set priority only on the root.
- Apple's doctrine: "Whenever possible, prefer structured Tasks" — automatic cancellation, priority propagation, and task-local inheritance "do not always apply to unstructured tasks."

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

### Child Closures Can't Capture Mutable State

Group child closures are `@Sendable` — they cannot mutate captured variables. Children **return** values; only the parent mutates, sequentially, in the `for await` loop (WWDC21 10134):

```swift
// ❌ Compiler error: mutation of captured var in concurrently-executing code
group.addTask { thumbnails[id] = try await fetchOneThumbnail(withID: id) }

// ✅ Children return values; the parent alone mutates
try await withThrowingTaskGroup(of: (String, UIImage).self) { group in
    for id in ids {
        group.addTask { (id, try await fetchOneThumbnail(withID: id)) }
    }
    for try await (id, thumbnail) in group {   // yields in order of COMPLETION
        thumbnails[id] = thumbnail             // safe: only the parent writes
    }
}
```

The `for await` loop over a group yields results in **completion order**, not submission order — store by ID if order matters.

### Group Exit and Cancellation Semantics (WWDC21 10134)

- A child's error **thrown out of the group's block** implicitly cancels all remaining children, then awaits them.
- A **normal exit** from the block does NOT cancel — remaining children are awaited to completion. To cancel eagerly, call `group.cancelAll()` before exiting.
- Call `try Task.checkCancellation()` at the top of the group body before adding work (WWDC23 10170).

### Limiting Concurrency

Prevent overwhelming the system with too many parallel tasks (Apple's own demo seeds with `min(3, items.count)` and adds one task per completion — WWDC23 10170):

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

Apple's exact guarantees (WWDC23 10170): "Resources used by tasks are freed immediately after the task finishes" (regular groups retain child results until `next()` is called — memory grows with many fire-and-forget children), and **automatic sibling cancellation** — "if any of the child tasks throw an error, all remaining tasks are automatically cancelled." Discarding groups are "ideal… when you're processing a stream of requests."

**Service-loop-with-deadline pattern** — a throwing child doubles as a shutdown timer, because its error auto-cancels all siblings:

```swift
try await withThrowingDiscardingTaskGroup { group in
    for cook in staff.keys { group.addTask { try await cook.handleShift() } }
    group.addTask {
        try await Task.sleep(for: shiftDuration)   // run until closing time
        throw TimeToCloseError()                   // throw → siblings auto-cancel
    }
}
```

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

### Cancellation Is Cooperative — and a Race

Apple's exact semantics (WWDC21 10134, WWDC23 10170): "Marking a task as canceled does not stop the task. It simply informs the task that its results are no longer needed" — your code must check and wind down. And "cancellation is a race": a check may pass just before cancellation lands, in which case the work simply runs to completion.

Two API-design rules from WWDC21 10134:
- "Implement your APIs with cancellation in mind, especially if they involve long-running computations" — callers expect the computation to stop as soon as possible.
- If you return a **partial result** on cancellation, "you must ensure that your API clearly states that a partial result may be returned" — otherwise callers relying on a complete result can hit fatal errors.

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

**Handler concurrency warning** (WWDC23 10170): the `onCancel` closure "runs immediately" — synchronously, even instantly if the task is already cancelled. Any state it touches "is shared mutable state between the cancellation handler and main body, which can run concurrently." Protect it with atomics, a lock, or a queue — an actor won't do, because the handler is synchronous and can't `await`.

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

Exact escalation rules (WWDC23 10170): awaiting a higher-priority task "escalates the priority of all child tasks in the task tree"; awaiting a task group's next result "escalates all child tasks in the group, since we don't know which one is most likely to complete next"; and **escalation is one-way** — "the task keeps the escalated priority for the remainder of its lifetime. It's not possible to undo a priority escalation."

## Task-Local Values (WWDC23 10170)

Task-locals attach contextual values (request IDs, trace context, current user) to the task tree without threading parameters through every call:

```swift
enum Kitchen {
    @TaskLocal static var orderID: Int?     // static or global; optional or defaulted
}

// Bound ONLY via a scoped block — no arbitrary sets
await Kitchen.$orderID.withValue(42) {
    await makeSoup()    // orderID visible here and in all child tasks
}
```

- Inheritance rule: "All tasks, **except detached tasks**, inherit task-local values from the current task." Lookup walks the parent chain to the first binding; rebinding inside a nested scope shadows without destroying the outer value.
- An entire `Task.detached` subtree sees no inherited values.
- Production patterns Apple shows: SwiftLog's `Logger.MetadataProvider` (bootstrap once, every log line auto-carries the bound context) and Swift Distributed Tracing's `withSpan("makeSoup") { span in … }` propagating trace IDs across the task tree — and across machines.

## Unstructured Tasks: When and How (WWDC21 10134)

Legitimate uses: launching async work from **non-async code**, and work whose lifetime doesn't fit one scope (start on one delegate callback, cancel on another — common in AppKit/UIKit delegates). `Task {}` inherits the actor, priority, and task-locals of its origin; but "cancellation and errors won't automatically propagate, and the task's result will not be implicitly awaited unless we take explicit action."

The delegate lifetime pattern — store handles keyed by work item, clear them with `defer` so a stale task is never cancelled by mistake:

```swift
@MainActor
class ThumbnailDelegate: NSObject, UICollectionViewDelegate {
    var thumbnailTasks: [IndexPath: Task<Void, Never>] = [:]

    func collectionView(_ view: UICollectionView, willDisplay cell: UICollectionViewCell,
                        forItemAt item: IndexPath) {
        thumbnailTasks[item] = Task {
            defer { thumbnailTasks[item] = nil }   // never cancel a later task for this row
            await displayThumbnail(for: item)
        }
    }

    func collectionView(_ view: UICollectionView, didEndDisplaying cell: UICollectionViewCell,
                        forItemAt item: IndexPath) {
        thumbnailTasks[item]?.cancel()
    }
}
```

`Task.detached` composition doctrine: instead of detaching one task per background job, detach **one** root and open a task group inside it — children inherit the detached root's (e.g. background) priority, and cancelling the root cancels everything:

```swift
Task.detached(priority: .background) {
    withTaskGroup(of: Void.self) { group in
        group.addTask { writeToLocalCache(thumbnails) }
        group.addTask { log(thumbnails) }
    }
}
```

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
- [ ] Group children return values; only the parent mutates shared state
- [ ] `group.cancelAll()` called when exiting a group early without consuming all results
- [ ] APIs that return partial results on cancellation document that contract
- [ ] `withTaskCancellationHandler` onCancel state protected by lock/atomic (handler is synchronous)
- [ ] Context (IDs, trace data) passed via `@TaskLocal`, not global mutable state
- [ ] Unstructured task handles stored + cancelled at the matching lifecycle point (delegate pattern)
