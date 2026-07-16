---
name: swift-concurrency-updates
description: Swift 6.2 concurrency updates including default MainActor inference, @concurrent for background work, isolated conformances, and approachable concurrency migration. Use when adopting Swift 6.2 concurrency features or fixing data-race errors.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# Swift 6.2 Concurrency Updates

Swift 6.2 introduces "Approachable Concurrency" -- a set of changes that make strict concurrency dramatically easier to adopt. Code runs on `@MainActor` by default, async functions stay on the calling actor, and you explicitly request background execution with `@concurrent`.

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

In Swift 6.2, async functions without specific actor isolation stay on whatever actor called them, instead of hopping to the generic concurrent executor as in 6.0/6.1 -- eliminating a common source of data-race errors with no code changes required.

---

## 2. Default MainActor Inference Mode

An opt-in build setting that makes all code implicitly `@MainActor` unless explicitly opted out with `nonisolated`.

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

With this enabled, app-level types no longer need explicit `@MainActor` annotations -- including global/static mutable state, which otherwise needs an explicit `@MainActor static let ...`.

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
nonisolated struct ImageProcessor {
    func processImage(_ data: Data) -> UIImage {
        // Runs on any thread, not MainActor
        ...
    }
}
```

---

## 3. Isolated Conformances

Isolated conformances let a `@MainActor` type conform to a protocol that does not require actor isolation, using `extension Type: @MainActor ProtocolName`. Before Swift 6.2, this produced a compiler error about the main actor-isolated conformance crossing an isolation boundary.

```swift
protocol Exportable {
    func export()
}

@MainActor
final class StickerModel {
    let processor: PhotoProcessor
    func doExport() { processor.exportAsPNG() }
}

// ✅ Swift 6.2 -- isolated conformance
extension StickerModel: @MainActor Exportable {
    func export() {
        processor.exportAsPNG()  // Works: conformance is MainActor-isolated
    }
}
```

The conformance can only be used from a context that shares the same isolation domain:

```swift
// ✅ Used within @MainActor context -- OK
@MainActor
func exportAll(_ items: [any Exportable]) {
    for item in items { item.export() }
}

// ❌ Used outside @MainActor -- compile error
nonisolated func exportAll(_ items: [any Exportable]) {
    for item in items {
        item.export()  // Error: isolated conformance not available here
    }
}
```

---

## 4. @concurrent -- Explicit Background Execution

`@concurrent` explicitly offloads a function to the background thread pool, replacing the pattern of using `Task.detached` for compute-intensive operations.

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

### Steps to Offload Work

1. Make the containing type `nonisolated` (for structs/classes; actors are already isolated)
2. Add `@concurrent` to the function
3. Make the function `async`
4. Callers use `await`

### @concurrent vs Task.detached vs actor

| Mechanism | Use Case | Structured? |
|-----------|----------|-------------|
| `@concurrent` | Single function that must run on background thread | Yes (inherits task context) |
| `Task.detached` | Fire-and-forget background work, no structured parent | No |
| `actor` | Shared mutable state needing serialized access | N/A (isolation, not scheduling) |
| `Task {}` | Unstructured task inheriting current actor | No |

### When NOT to Use @concurrent

Reserve it for CPU-intensive work, blocking I/O that would freeze the UI, or work measured to be long enough to justify the thread hop -- not trivial functions:

```swift
// ❌ Wrong -- trivial work does not need @concurrent
nonisolated struct UserFormatter {
    @concurrent
    func formatName(_ user: User) async -> String {
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

See "Enabling It" above -- the Xcode build setting or `.defaultIsolation(MainActor.self)` in `swiftSettings`.

**Step 3: Remove redundant `@MainActor` annotations**

With default MainActor inference enabled, explicit `@MainActor` annotations on app-level types are redundant and can be removed to reduce noise.

**Step 4: Replace `Task.detached` with `@concurrent` where appropriate**

Mark the offloaded function `@concurrent` directly instead of wrapping it in a detached task inside a `TaskGroup`.

**Step 5: Fix remaining conformance errors with isolated conformances**

Part of migrating to Swift 6.2 involves replacing unsafe `@unchecked Sendable` workarounds with isolated conformances:

```swift
// Before -- unsafe workaround
extension MyModel: @unchecked Sendable {}

// After -- isolated conformance
extension MyModel: @MainActor Exportable {
    func export() { ... }
}
```

**Step 6: Add `nonisolated` to types/functions that must not be on MainActor**

With default MainActor inference, anything not explicitly marked `nonisolated` runs on MainActor. Audit background data processing types, network parsers, file I/O utilities, and computation-heavy algorithms.

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
- Local captured doc (optional): `~/Downloads/docs/Swift-Concurrency-Updates.md` — read if present; skip silently if absent.

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

Libraries should let consumers choose their own isolation strategy. Only app targets and executables should use default MainActor inference.

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

### Mistake 2: Marking trivial functions @concurrent

Every `@concurrent` call involves a thread hop. Only use it for genuinely expensive work (see "When NOT to Use @concurrent" above).

### Mistake 3: Forgetting nonisolated when default MainActor is enabled

```swift
// With default MainActor inference enabled:

// ❌ Wrong -- this CPU-intensive parser now runs on MainActor, blocking UI
struct LargeFileParser {
    func parse(_ data: Data) -> [Record] {
        ...
    }
}

// ✅ Right -- opt out of MainActor for background-suitable types
nonisolated struct LargeFileParser {
    @concurrent
    func parse(_ data: Data) async -> [Record] {
        ...
    }
}
```

### Mistake 4: Using isolated conformances in nonisolated contexts

See "Isolated Conformances" above -- the conformance is only usable from a context that matches its isolation.

### Mistake 5: Removing @MainActor annotations without enabling the build setting

```swift
// ❌ Wrong -- removed annotations but did NOT enable default MainActor inference
class ViewModel {  // No longer @MainActor -- state is unprotected
    var items: [Item] = []
    func load() async { ... }
}

// ✅ Right -- either keep the annotation...
@MainActor
class ViewModel {
    var items: [Item] = []
    func load() async { ... }
}

// ...or enable "Default Actor Isolation: MainActor" in build settings
// and then annotations are unnecessary
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
- **Local captured doc (optional)**: `~/Downloads/docs/Swift-Concurrency-Updates.md` — read if present; skip silently if absent.

## References

- [Swift Evolution: Approachable Concurrency](https://www.swift.org/blog/approachable-concurrency/)
- [Migrating to Swift 6](https://www.swift.org/migration/documentation/migrationguide/)
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
