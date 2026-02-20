# Actors and Isolation

Actors serialize access to mutable state, preventing data races at compile time. This file covers actor patterns, reentrancy pitfalls, `@MainActor`, `Sendable`, and isolation boundaries.

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

**Pattern 3: Use a synchronous method for the critical section**

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
