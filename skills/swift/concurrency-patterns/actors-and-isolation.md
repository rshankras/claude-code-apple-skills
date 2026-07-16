# Actors and Isolation

Actors serialize access to mutable state, preventing data races at compile time. This file covers actor patterns, reentrancy pitfalls, `@MainActor`, `Sendable`, and isolation boundaries. Core doctrine sourced from Apple's WWDC21 "Protect mutable state with Swift actors" (10133) and WWDC22 "Eliminate data races using Swift Concurrency" (110351).

## The Mental Model: Islands in a Sea of Concurrency (WWDC22 110351)

Apple's canonical picture: **tasks are boats, actors are islands, non-isolated code is the open sea** (the global cooperative pool). "Each island is self-contained, with its own state that is isolated from everything else in the sea… Only one boat can visit the island to run code at a time." Every value that crosses a boat↔boat or boat↔island boundary — task-creation captures, task return values, actor call arguments and results — goes through **Sendable checking**.

Three doctrine points that follow:
- A **data race** needs shared *mutable* state: "If your data doesn't change or it isn't shared across multiple concurrent tasks, you can't have a data race on it" (WWDC21 10133). Races are nondeterministic and demand nonlocal reasoning — which is why the compiler, not review, must catch them.
- Architecture: views and view controllers on the main actor, business logic on other actors, tasks shuttling **Sendable** data between them — "all of your concurrent code should primarily communicate in terms of Sendable types."
- Actors are **not FIFO** — unlike serial Dispatch queues, they run highest-priority work first. Never port order-dependent serial-queue code onto an actor; for strict ordering, use a single task or an `AsyncStream`.

## Actor Basics

```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]

    func image(for url: URL) -> UIImage? {
        cache[url]
    }

    func store(_ image: UIImage, for url: URL) {
        cache[url] = image
    }

    func clear() {
        cache.removeAll()
    }
}

// All access is through await:
let cache = ImageCache()
await cache.store(image, for: url)
let cached = await cache.image(for: url)
```

### nonisolated Members

Functions that don't access mutable state can be `nonisolated` to skip the await:

```swift
actor UserStore {
    let id: UUID                    // let is implicitly nonisolated
    private var users: [User] = []

    nonisolated var storeIdentifier: String {
        id.uuidString               // Only accesses let property — safe
    }

    func addUser(_ user: User) {    // Isolated — requires await
        users.append(user)
    }
}

let store = UserStore()
let id = store.storeIdentifier     // No await needed
await store.addUser(user)          // await required
```

**Synchronous protocol requirements** (WWDC21 10133): requirements like `Hashable.hash(into:)` can't be actor-isolated — there's no way for the protocol's callers to `await` them. Mark them `nonisolated`. The rule: "because nonisolated methods are treated as being outside the actor, they cannot reference mutable state on the actor" — immutable `let` properties only; hashing a `var` is a compiler error. Static methods have no `self` and are always outside actor isolation.

## Actor Reentrancy

Actors are reentrant: when an actor method hits an `await` suspension point, other callers can execute on the same actor. This means state can change across `await` points.

```swift
// ❌ Bug — actor reentrancy
actor BankAccount {
    var balance: Int = 1000

    func withdraw(amount: Int) async -> Bool {
        guard balance >= amount else { return false }
        // ⚠️ SUSPENSION POINT — another caller can run here
        await logTransaction(amount)
        // balance may have changed! Another withdraw could have run.
        balance -= amount  // Could go negative!
        return true
    }
}
```

### Fixing Reentrancy

**Pattern 1: Read and write state before the suspension point**

```swift
// ✅ Capture state before await
actor BankAccount {
    var balance: Int = 1000

    func withdraw(amount: Int) async -> Bool {
        guard balance >= amount else { return false }
        balance -= amount          // Modify BEFORE the await
        await logTransaction(amount) // Now it's safe
        return true
    }
}
```

**Pattern 2: Re-check state after the suspension point**

```swift
// ✅ Re-validate after await
actor BankAccount {
    var balance: Int = 1000

    func withdraw(amount: Int) async -> Bool {
        guard balance >= amount else { return false }
        await logTransaction(amount)
        // Re-check after suspension
        guard balance >= amount else {
            await reverseTransaction(amount)
            return false
        }
        balance -= amount
        return true
    }
}
```

**Pattern 3: Cache the in-flight Task so concurrent callers share ONE operation**

Store the in-flight `Task` synchronously in the cache before awaiting it (Apple's ImageDownloader fix, WWDC21 10133):

```swift
// ✅ Deduplicates concurrent requests for the same key
actor ImageDownloader {
    private enum CacheEntry {
        case inProgress(Task<Image, Error>)
        case ready(Image)
    }
    private var cache: [URL: CacheEntry] = [:]

    func image(from url: URL) async throws -> Image {
        if let entry = cache[url] {
            switch entry {
            case .ready(let image): return image
            case .inProgress(let task): return try await task.value
            }
        }
        let task = Task { try await downloadImage(from: url) }
        cache[url] = .inProgress(task)      // synchronous — no interleaving before this
        do {
            let image = try await task.value
            cache[url] = .ready(image)
            return image
        } catch {
            cache[url] = nil                // allow retry after failure
            throw error
        }
    }
}
```

Apple's design-for-reentrancy checklist (WWDC21 10133, verbatim): (1) "perform mutation of actor state within synchronous code"; (2) if state must be temporarily inconsistent, "make sure to restore consistency before an await"; (3) expect that after any resume "the overall program state will have changed" — "an await in your code means the world can move on and invalidate your assumptions."

**Pattern 4: Use a synchronous method for the critical section**

```swift
// ✅ No suspension point in the critical path
actor BankAccount {
    var balance: Int = 1000

    // Synchronous — no reentrancy possible
    func withdraw(amount: Int) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }

    // Logging is separate, after the state change
    func withdrawAndLog(amount: Int) async -> Bool {
        let success = withdraw(amount: amount)
        if success {
            await logTransaction(amount)
        }
        return success
    }
}
```

## @MainActor

Marks code that must run on the main thread. Use for all UI-related state and updates.

### On Types

```swift
@MainActor
@Observable
final class ItemListViewModel {
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await itemService.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### On Functions

```swift
class DataProcessor {
    @MainActor
    func updateUI(with result: ProcessingResult) {
        // Guaranteed to run on main thread
    }

    nonisolated func processInBackground(data: Data) async -> ProcessingResult {
        // Runs on any thread
        ...
    }
}
```

### MainActor.run

For one-off main thread execution from a non-main context:

```swift
func processData() async {
    let result = await heavyComputation()
    await MainActor.run {
        self.displayResult = result
    }
}
```

Prefer `@MainActor` on the type/method over `MainActor.run` — it's more declarative and catches errors at compile time.

## Sendable

Types that can safely cross isolation boundaries (between actors, between threads).

### Automatically Sendable

- Value types (structs, enums) with all Sendable properties
- Actors (always Sendable)
- Immutable classes (`final class` with only `let` properties)

### Explicit Sendable

```swift
// ✅ Value type with Sendable properties — automatically Sendable
struct UserProfile: Sendable {
    let id: UUID
    let name: String
    let email: String
}

// ✅ Immutable final class
final class AppConfig: Sendable {
    let apiURL: URL
    let timeout: TimeInterval
}
```

### @unchecked Sendable

For types you guarantee are thread-safe through external mechanisms (locks, queues):

```swift
// ⚠️ Use only when you can prove thread safety
final class ThreadSafeCache<Key: Hashable & Sendable, Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Key: Value] = [:]

    func value(for key: Key) -> Value? {
        lock.withLock { storage[key] }
    }

    func store(_ value: Value, for key: Key) {
        lock.withLock { storage[key] = value }
    }
}
```

Prefer actors over `@unchecked Sendable` + locks. Use `@unchecked Sendable` only for performance-critical paths or bridging with legacy code.

### @Sendable Closures

Closures that cross isolation boundaries must be `@Sendable`:

```swift
// TaskGroup requires @Sendable closures
await withTaskGroup(of: Void.self) { group in
    group.addTask { @Sendable in
        await processItem(item)  // Closure must be @Sendable
    }
}
```

Most closure parameters in the concurrency APIs are already marked `@Sendable`. You typically only need the annotation when the compiler can't infer it.

The three `@Sendable` closure rules (WWDC21 10133, verbatim): they cannot capture mutable local variables ("that would allow data races on the local variable"); everything they capture must be Sendable; and a synchronous `@Sendable` closure cannot be actor-isolated ("that would allow code to be run on the actor from the outside"). Corollary: a non-Sendable closure formed *inside* an actor method (e.g. passed to `reduce` and run inline) stays actor-isolated and may call actor methods synchronously; the same-looking closure passed to `Task.detached` is `@Sendable` and must `await`.

### Sendable Inference Is Not Public

Internal structs/enums with Sendable storage get `Sendable` automatically; **public types never do** — conformance on a public type is an API guarantee to clients, so declare it explicitly.

### The Returned-Reference Trap

Returning a value type from an actor hands the caller a safe copy. Returning a **class** hands the caller "a reference into the mutable state of the actor" — mutating it from outside is a data race even though every access compiled (WWDC21 10133). Return value types or Sendable snapshots from actors.

### Region-Based Isolation (Swift 6)

Swift 6 accepts sending a **non-Sendable** value across an isolation boundary when the compiler can prove the origin never uses it again after the send. If you get "sending 'x' risks causing data races," check whether the origin keeps using the value after the transfer — restructuring so it doesn't is often easier than adding conformances.

### Atomic and Mutex (Swift 6 Synchronization module)

For the narrow cases where an actor is the wrong tool (synchronous contexts, hot paths), Swift 6's `Synchronization` module replaces hand-rolled lock wrappers (WWDC24 10136):

```swift
import Synchronization

final class Stats: Sendable {
    private let counter = Atomic<Int>(0)          // must be stored in a `let`
    func hit() { counter.wrappingAdd(1, ordering: .relaxed) }
    var value: Int { counter.load(ordering: .relaxed) }
}

final class Registry: Sendable {
    private let state = Mutex<[String: Int]>([:]) // must be stored in a `let`
    func set(_ key: String, _ value: Int) {
        state.withLock { $0[key] = value }        // all access through withLock
    }
}
```

A `final class` whose only storage is `Atomic`/`Mutex` values is legitimately `Sendable` — no `@unchecked` needed.

## Isolation Boundaries in Practice

### Sending Values Between Actors

```swift
actor DataStore {
    func save(_ item: Item) { ... }
}

@MainActor
class ViewModel {
    let store = DataStore()

    func saveItem(_ item: Item) async {
        // item crosses from MainActor to DataStore actor
        // item must be Sendable
        await store.save(item)
    }
}
```

### Non-Sendable Types at Boundaries

```swift
// ❌ NSMutableArray is not Sendable
actor Processor {
    func process(_ array: NSMutableArray) { }  // Compiler error
}

// ✅ Convert to Sendable type at the boundary
actor Processor {
    func process(_ items: [Item]) { }  // [Item] is Sendable if Item is
}
```

## Common Mistakes

### Assuming Actors Are Like Locks

```swift
// ❌ Wrong mental model — actor is not a lock, it's a mailbox
actor Counter {
    var count = 0

    func incrementTwice() async {
        count += 1
        await someAsyncWork()  // Other callers can run here!
        count += 1             // count may have been modified
    }
}

// ✅ Correct mental model — avoid await between state mutations
actor Counter {
    var count = 0

    func incrementTwice() {  // Synchronous — no interleaving
        count += 2
    }
}
```

### @MainActor with Heavy Computation

```swift
// ❌ Blocks the main thread — UI freezes
@MainActor
func processImages(_ images: [Data]) -> [UIImage] {
    images.map { heavyProcessing($0) }  // Synchronous heavy work on main thread
}

// ✅ Offload to background, return to main actor
@MainActor
func processImages(_ images: [Data]) async -> [UIImage] {
    await withTaskGroup(of: UIImage.self) { group in
        for data in images {
            group.addTask { @Sendable in
                heavyProcessing(data)  // Runs on concurrent thread pool
            }
        }
        var results: [UIImage] = []
        for await image in group {
            results.append(image)
        }
        return results
    }
}
```

### Using @unchecked Sendable to Silence Warnings

```swift
// ❌ Dangerous — silences compiler but doesn't fix the data race
class UnsafeCache: @unchecked Sendable {
    var items: [String: Any] = [:]  // No synchronization!
}

// ✅ Use an actor instead
actor SafeCache {
    var items: [String: Any] = [:]
}
```

## Checklist

- [ ] Shared mutable state protected by actors (not locks or DispatchQueue)
- [ ] Actor reentrancy considered — state mutations before `await` points
- [ ] `@MainActor` on all UI-bound types (ViewModels, UI state)
- [ ] `Sendable` conformance on types that cross isolation boundaries
- [ ] `@unchecked Sendable` used only with proven synchronization, never to silence warnings
- [ ] No heavy synchronous work on `@MainActor`
- [ ] `nonisolated` on actor methods that don't access mutable state
- [ ] Prefer `@MainActor` annotation over `MainActor.run` for clarity
- [ ] Actors return value types / Sendable snapshots, never references into their own mutable state
- [ ] No order-dependent logic assumes actor FIFO (actors schedule by priority)
- [ ] Concurrent duplicate requests deduplicated via the in-flight-Task cache pattern
- [ ] Public Sendable types declare conformance explicitly (no inference on public types)
- [ ] `Atomic`/`Mutex` (Synchronization module) used instead of `@unchecked Sendable` + NSLock

## References

- [WWDC21 — Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)
- [WWDC22 — Eliminate data races using Swift Concurrency](https://developer.apple.com/videos/play/wwdc2022/110351/)
- [WWDC24 — What's new in Swift (region-based isolation, Synchronization)](https://developer.apple.com/videos/play/wwdc2024/10136/)
