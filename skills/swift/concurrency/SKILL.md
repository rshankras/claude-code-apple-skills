---
name: swift-concurrency-updates
description: Swift 6.2 concurrency updates including default MainActor inference, @concurrent for background work, isolated conformances, and approachable concurrency migration. Use when adopting Swift 6.2 concurrency features or fixing data-race errors.
allowed-tools: [Read, Glob, Grep]
---

# Swift 6.2 Concurrency Updates

Swift 6.2 introduces "Approachable Concurrency" -- a set of changes that make strict concurrency dramatically easier to adopt. The philosophy shifts from "opt in to safety" to "safe by default, opt in to concurrency." Code runs on `@MainActor` by default, async functions stay on the calling actor, and you explicitly request background execution with `@concurrent`.

This skill covers only the Swift 6.2 specific changes. For general concurrency patterns (actors, TaskGroup, AsyncSequence, Sendable, cancellation), see the `swift/concurrency-patterns` skill.

## When This Skill Activates

- User is adopting Swift 6.2 concurrency features
- User asks about default MainActor inference or the "infer main actor" build setting
- User encounters data-race errors that Swift 6.2 resolves
- User asks about `@concurrent`, isolated conformances, or approachable concurrency
- User wants to migrate from Swift 6.0/6.1 strict concurrency to 6.2
- User asks how async functions behave differently in Swift 6.2
- User needs to offload CPU-intensive work to a background thread in Swift 6.2

## What Changed in Swift 6.2 vs Before

### The Core Problem with Swift 6.0/6.1

In Swift 6.0 and 6.1, strict concurrency was correct but painful. Developers faced walls of data-race compiler errors that were difficult to resolve. Non-actor-annotated async functions would eagerly hop to the generic concurrent executor, causing unexpected data races when passing mutable state. Conforming `@MainActor` types to non-isolated protocols was often impossible without workarounds.

### Swift 6.2 Changes at a Glance

| Feature | Before (6.0/6.1) | After (6.2) |
|---------|------------------|-------------|
| Default isolation | Nothing inferred; manual `@MainActor` everywhere | Opt-in mode infers `@MainActor` on everything |
| Async function execution | Hops to generic concurrent executor | Stays on calling actor |
| `@MainActor` type conforming to protocol | Compiler error for non-isolated protocols | Isolated conformances: `@MainActor Protocol` |
| Background execution | `Task.detached` or manual nonisolated functions | `@concurrent` attribute |
| Global/static mutable state | Required `@MainActor` annotation or Sendable | Default MainActor mode handles it automatically |

---

## 1. Async Functions Stay on the Calling Actor

In Swift 6.0/6.1, a non-actor-annotated async function called from a `@MainActor` context would hop off the main actor to the generic concurrent executor. This caused data-race errors when the caller passed non-Sendable state.

In Swift 6.2, async functions without specific actor isolation stay on whatever actor they are called from. No hop, no data race.

### Before (Swift 6.0/6.1)

```swift
// ❌ Swift 6.0/6.1 -- ERROR: Sending 'self.processor' risks causing data races
@MainActor
final class StickerModel {
    let processor = PhotoProcessor()

    func extract(_ item: PhotosPickerItem) async throws -> Sticker? {
        let data = try await item.loadTransferable(type: Data.self)
        // processor hops off MainActor -- data race
        return await processor.extractSticker(data: data, with: item.itemIdentifier)
    }
}

class PhotoProcessor {
    func extractSticker(data: Data, with id: String?) async -> Sticker? {
        // This runs on the concurrent executor in 6.0/6.1
        ...
    }
}
```

### After (Swift 6.2)

```swift
// ✅ Swift 6.2 -- No error. extractSticker stays on the caller's actor.
@MainActor
final class StickerModel {
    let processor = PhotoProcessor()

    func extract(_ item: PhotosPickerItem) async throws -> Sticker? {
        let data = try await item.loadTransferable(type: Data.self)
        // processor stays on MainActor -- no data race
        return await processor.extractSticker(data: data, with: item.itemIdentifier)
    }
}

class PhotoProcessor {
    func extractSticker(data: Data, with id: String?) async -> Sticker? {
        // In 6.2, this runs on MainActor because the caller is @MainActor
        ...
    }
}
```

**Why this matters:** Many data-race errors in Swift 6.0/6.1 were caused by this implicit hop. In 6.2, the same code compiles cleanly with no changes needed.

---

## 2. Default MainActor Inference Mode

An opt-in build setting that makes all code implicitly `@MainActor` unless explicitly opted out with `nonisolated`. This eliminates the vast majority of data-race errors for single-threaded app code.

### Enabling It

**Xcode:** Build Settings > Swift Compiler - Concurrency > "Default Actor Isolation" > "MainActor"

**Swift Package Manager:**

```swift
.executableTarget(
    name: "MyApp",
    swiftSettings: [
        .defaultIsolation(MainActor.self)
    ]
)
```

### What Changes

With this mode enabled, you no longer need `@MainActor` annotations on app-level types:

```swift
// ❌ Before (Swift 6.0/6.1) -- manual @MainActor annotations everywhere
@MainActor
final class StickerLibrary {
    static let shared: StickerLibrary = .init()
}

@MainActor
final class StickerModel {
    let processor: PhotoProcessor
    var selection: [PhotosPickerItem]
}

@MainActor
struct ContentView: View {
    @State private var model = StickerModel()
    var body: some View { ... }
}
```

```swift
// ✅ After (Swift 6.2 with default MainActor inference) -- no annotations needed
final class StickerLibrary {
    static let shared: StickerLibrary = .init()  // Implicitly @MainActor
}

final class StickerModel {
    let processor: PhotoProcessor    // Implicitly @MainActor
    var selection: [PhotosPickerItem]
}

struct ContentView: View {
    @State private var model = StickerModel()
    var body: some View { ... }
}
```

### When to Use Default MainActor Inference

| Target Type | Recommended? | Reason |
|-------------|-------------|--------|
| App target | Yes | Apps are UI-driven; most code belongs on MainActor |
| Script / executable | Yes | Scripts are sequential; MainActor default is natural |
| Library / framework | No | Libraries must not impose actor isolation on consumers |
| Package plugin | No | Same reasoning as libraries |

### Opting Out with nonisolated

When a type or function genuinely needs to run off the main actor, mark it `nonisolated`:

```swift
// With "infer main actor" enabled, use nonisolated to opt out:
nonisolated struct ImageProcessor {
    func processImage(_ data: Data) -> UIImage {
        // Runs on any thread, not MainActor
        ...
    }
}

nonisolated func heavyComputation() -> Result {
    // Runs on any thread
    ...
}
```

### Global and Static State Protection

With default MainActor inference enabled, global and static mutable state is automatically protected:

```swift
// ❌ Before -- required explicit annotation or Sendable conformance
@MainActor static let shared: StickerLibrary = .init()

// ✅ After -- default MainActor inference handles it
static let shared: StickerLibrary = .init()  // Implicitly @MainActor
```

Without default MainActor inference, you can still protect individual declarations:

```swift
@MainActor static let shared: StickerLibrary = .init()
```

---

## 3. Isolated Conformances

Allows `@MainActor` types to conform to protocols that do not require actor isolation. Before Swift 6.2, this was a common source of frustrating compiler errors.

### The Problem (Swift 6.0/6.1)

```swift
protocol Exportable {
    func export()
}

@MainActor
final class StickerModel {
    let processor: PhotoProcessor

    func doExport() {
        processor.exportAsPNG()
    }
}

// ❌ Swift 6.0/6.1 -- ERROR: Main actor-isolated conformance crosses isolation boundary
extension StickerModel: Exportable {
    func export() {
        processor.exportAsPNG()  // Needs MainActor, but protocol is non-isolated
    }
}
```

### The Solution (Swift 6.2)

```swift
// ✅ Swift 6.2 -- Isolated conformance
extension StickerModel: @MainActor Exportable {
    func export() {
        processor.exportAsPNG()  // Works: conformance is MainActor-isolated
    }
}
```

### Usage Rules for Isolated Conformances

The compiler enforces that isolated conformances are only used in matching isolation contexts:

```swift
// ✅ Used within @MainActor context -- OK
@MainActor
struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // OK: both are @MainActor
    }
}

// ❌ Used outside @MainActor -- compile error
nonisolated struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // Error: Main actor-isolated conformance
                            // cannot be used in nonisolated context
    }
}
```

The conformance is not universally available. It only works when the caller shares the same isolation domain.

---

## 4. @concurrent -- Explicit Background Execution

When you need true parallelism for CPU-heavy work, use `@concurrent` to explicitly offload to the background thread pool. This replaces the pattern of using `Task.detached` for compute-intensive operations.

### Basic Usage

```swift
class PhotoProcessor {
    var cachedStickers: [String: Sticker]

    func extractSticker(data: Data, with id: String) async -> Sticker {
        if let sticker = cachedStickers[id] { return sticker }
        let sticker = await Self.extractSubject(from: data)  // Background execution
        cachedStickers[id] = sticker
        return sticker
    }

    @concurrent
    static func extractSubject(from data: Data) async -> Sticker {
        // Heavy image processing -- runs on concurrent thread pool
        ...
    }
}
```

### Steps to Offload Work

1. Make the type `nonisolated` (for structs/classes; actors are already isolated)
2. Add `@concurrent` to the function
3. Make the function `async`
4. Callers use `await`

```swift
nonisolated struct ImageProcessor {
    @concurrent
    func resize(image: Data, to size: CGSize) async -> Data {
        // Runs on background thread pool
        ...
    }
}

// Caller (on MainActor):
let resized = await ImageProcessor().resize(image: data, to: targetSize)
```

### @concurrent vs Task.detached vs actor

| Mechanism | Use Case | Structured? |
|-----------|----------|-------------|
| `@concurrent` | Single function that must run on background thread | Yes (inherits task context) |
| `Task.detached` | Fire-and-forget background work, no structured parent | No |
| `actor` | Shared mutable state needing serialized access | N/A (isolation, not scheduling) |
| `Task {}` | Unstructured task inheriting current actor | No |

Prefer `@concurrent` for compute-heavy functions. Prefer actors for shared state. Avoid `Task.detached` when `@concurrent` or structured concurrency works.

### When NOT to Use @concurrent

Do not mark every async function as `@concurrent`. Most app code should stay on the calling actor. Only use `@concurrent` when:

- The function performs CPU-intensive work (image processing, parsing, compression)
- The function performs blocking I/O that would freeze the UI
- You have measured that the work takes enough time to justify the thread hop

```swift
// ❌ Wrong -- trivial work does not need @concurrent
nonisolated struct UserFormatter {
    @concurrent
    func formatName(_ user: User) async -> String {  // Unnecessary thread hop
        return "\(user.firstName) \(user.lastName)"
    }
}

// ✅ Right -- leave it on the calling actor
struct UserFormatter {
    func formatName(_ user: User) -> String {
        return "\(user.firstName) \(user.lastName)"
    }
}
```

---

## 5. Migration Guide

### From Swift 6.0/6.1 to Swift 6.2

**Step 1: Update to Swift 6.2 toolchain**

Ensure your Xcode version supports Swift 6.2 and your project's Swift language version is set to 6.2.

**Step 2: Enable default MainActor inference (for app targets)**

Xcode: Build Settings > Swift Compiler - Concurrency > Default Actor Isolation > MainActor

Swift Package Manager:

```swift
.executableTarget(
    name: "MyApp",
    swiftSettings: [
        .defaultIsolation(MainActor.self)
    ]
)
```

**Step 3: Remove redundant `@MainActor` annotations**

With default MainActor inference enabled, explicit `@MainActor` annotations on app-level types are redundant. Remove them to reduce noise:

```swift
// Before
@MainActor class ViewModel { ... }
@MainActor struct ContentView: View { ... }

// After (with default MainActor inference)
class ViewModel { ... }
struct ContentView: View { ... }
```

**Step 4: Replace `Task.detached` with `@concurrent` where appropriate**

```swift
// Before
func processImages(_ data: [Data]) async -> [UIImage] {
    await withTaskGroup(of: UIImage.self) { group in
        for item in data {
            group.addTask { // Task.detached implied hop
                await self.decode(item)
            }
        }
        return await group.reduce(into: []) { $0.append($1) }
    }
}

// After
@concurrent
func decode(_ data: Data) async -> UIImage {
    // Explicitly runs on background
    ...
}
```

**Step 5: Fix remaining conformance errors with isolated conformances**

```swift
// Before -- workaround with @unchecked Sendable or nonisolated
extension MyModel: @unchecked Sendable {}  // Unsafe workaround

// After -- isolated conformance
extension MyModel: @MainActor Exportable {
    func export() { ... }
}
```

**Step 6: Add `nonisolated` to types/functions that must not be on MainActor**

With default MainActor inference, anything not explicitly marked `nonisolated` runs on MainActor. Audit your code for:

- Background data processing types
- Network parsers
- File I/O utilities
- Computation-heavy algorithms

```swift
nonisolated struct JSONParser {
    @concurrent
    func parse(_ data: Data) async throws -> [Model] { ... }
}
```

### Migration Resources

- Xcode build settings: Swift Compiler > Concurrency
- SwiftSettings API for Swift packages
- Official migration tooling: [swift.org/migration](https://www.swift.org/migration)
- Apple doc reference: `/Users/ravishankar/Downloads/docs/Swift-Concurrency-Updates.md`

---

## Mental Model

```
Swift 6.2 Concurrency Defaults
+--------------------------------------------+
| Everything is @MainActor by default        |
| (with "infer main actor" build setting)    |
|                                            |
| Async functions stay on the calling actor  |
| (no implicit hop to background)            |
|                                            |
| Use @concurrent to explicitly go background|
| Use nonisolated to opt out of MainActor    |
+--------------------------------------------+

Progression:
1. Write code          -> runs on MainActor        -> no data races
2. Use async/await     -> stays on calling actor   -> still no races
3. Need parallelism    -> @concurrent              -> explicit, auditable
4. Need shared state   -> actor                    -> serialized access
```

---

## Top Mistakes

### Mistake 1: Enabling default MainActor inference for a library

```swift
// ❌ Wrong -- library imposes MainActor on all consumers
// Package.swift
.target(
    name: "MyNetworkingLib",
    swiftSettings: [
        .defaultIsolation(MainActor.self)  // Do NOT do this for libraries
    ]
)
```

Libraries should let consumers choose their own isolation strategy. Only app targets and executables should use default MainActor inference.

### Mistake 2: Marking trivial functions @concurrent

```swift
// ❌ Wrong -- unnecessary thread hop for trivial work
@concurrent
func greet(_ name: String) async -> String {
    "Hello, \(name)"
}

// ✅ Right -- no @concurrent needed
func greet(_ name: String) -> String {
    "Hello, \(name)"
}
```

Every `@concurrent` call involves a thread hop. Only use it for genuinely expensive work.

### Mistake 3: Forgetting nonisolated when default MainActor is enabled

```swift
// With default MainActor inference enabled:

// ❌ Wrong -- this CPU-intensive parser now runs on MainActor, blocking UI
struct LargeFileParser {
    func parse(_ data: Data) -> [Record] {
        // Heavy parsing blocks the main thread
        ...
    }
}

// ✅ Right -- opt out of MainActor for background-suitable types
nonisolated struct LargeFileParser {
    @concurrent
    func parse(_ data: Data) async -> [Record] {
        // Runs on background thread pool
        ...
    }
}
```

### Mistake 4: Using isolated conformances in nonisolated contexts

```swift
extension MyModel: @MainActor Exportable {
    func export() { ... }
}

// ❌ Wrong -- trying to use the conformance from a nonisolated context
nonisolated func exportAll(_ items: [any Exportable]) {
    for item in items {
        item.export()  // Compiler error: isolated conformance not available here
    }
}

// ✅ Right -- use the conformance from a matching isolation context
@MainActor
func exportAll(_ items: [any Exportable]) {
    for item in items {
        item.export()  // OK: both are @MainActor
    }
}
```

### Mistake 5: Removing @MainActor annotations without enabling the build setting

```swift
// ❌ Wrong -- removed annotations but did NOT enable default MainActor inference
class ViewModel {  // No longer @MainActor -- state is unprotected
    var items: [Item] = []
    func load() async { ... }
}

// ✅ Right -- either keep annotations OR enable the build setting
// Option A: Keep the annotation
@MainActor
class ViewModel {
    var items: [Item] = []
    func load() async { ... }
}

// Option B: Enable "Default Actor Isolation: MainActor" in build settings
// Then annotations are unnecessary
class ViewModel {
    var items: [Item] = []
    func load() async { ... }
}
```

---

## Review Checklist

When reviewing code that uses or should use Swift 6.2 concurrency features:

### Build Configuration
- [ ] Swift language version is set to 6.2
- [ ] Default MainActor inference is enabled for app/executable targets only (not libraries)
- [ ] Libraries and frameworks do NOT use `.defaultIsolation(MainActor.self)`

### Actor Isolation
- [ ] Redundant `@MainActor` annotations removed (if default MainActor inference is enabled)
- [ ] `nonisolated` applied to types/functions that must run off the main actor
- [ ] CPU-intensive work marked `nonisolated` and uses `@concurrent`
- [ ] No heavy computation running implicitly on MainActor

### @concurrent Usage
- [ ] `@concurrent` only used for genuinely expensive operations
- [ ] `@concurrent` functions are `async`
- [ ] Containing type is `nonisolated` (for structs/classes)
- [ ] `Task.detached` replaced with `@concurrent` where structured concurrency is preferable

### Isolated Conformances
- [ ] `@MainActor Protocol` syntax used for MainActor types conforming to non-isolated protocols
- [ ] Isolated conformances only consumed from matching isolation contexts
- [ ] No `@unchecked Sendable` workarounds that isolated conformances can replace

### Migration Hygiene
- [ ] No leftover `@unchecked Sendable` conformances from pre-6.2 workarounds
- [ ] No unnecessary `Task.detached` calls (prefer `@concurrent` or structured concurrency)
- [ ] Async functions that previously caused data-race errors re-tested without workarounds
- [ ] Global and static mutable state properly protected (via default MainActor or explicit annotation)

---

## Cross-References

- **General concurrency patterns** (actors, TaskGroup, AsyncSequence, Sendable, cancellation): `swift/concurrency-patterns`
- **Actors and isolation deep dive**: `swift/concurrency-patterns/actors-and-isolation.md`
- **Structured concurrency patterns**: `swift/concurrency-patterns/structured-concurrency.md`
- **Swift 6 migration guide**: `swift/concurrency-patterns/migration-guide.md`
- **Apple documentation**: `/Users/ravishankar/Downloads/docs/Swift-Concurrency-Updates.md`

## References

- [Swift Evolution: Approachable Concurrency](https://www.swift.org/blog/approachable-concurrency/)
- [Migrating to Swift 6](https://www.swift.org/migration/documentation/migrationguide/)
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
