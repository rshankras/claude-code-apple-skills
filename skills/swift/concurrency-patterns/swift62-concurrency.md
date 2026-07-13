# Swift 6.2 Approachable Concurrency

Swift 6.2 makes strict concurrency dramatically easier to adopt. The core philosophy: code runs on `@MainActor` by default, async functions stay on the calling actor, and you explicitly opt into background execution with `@concurrent`. Sourced from Apple's WWDC25 "Embracing Swift concurrency" (268) and "What's new in Swift" (245); Swift 6.3/6.4 additions from WWDC26 "What's new in Swift" (262).

## Apple's Adoption Doctrine (WWDC25 268)

Apple prescribes an ordered path — do not skip steps:

1. **Start single-threaded.** "Your apps should start by running all of their code on the main thread, and you can get really far with single-threaded code."
2. **Introduce async/await only to hide latency** of high-latency operations (network, file I/O). Async ≠ parallel — it's still single-threaded interleaving.
3. **Introduce parallelism only after profiling.** "If it's work that can be made faster without concurrency, do that first. If it can't be made faster, you might need to introduce concurrency."
4. **Introduce actors last** — "when you find that storing data on the main actor is causing too much code to run on the main thread." Model classes "should generally be on the main actor with the UI, or kept non-Sendable, so that you don't encourage lots of concurrent accesses to your model."

Two build settings implement this (exact names):
- **"Approachable Concurrency"** — "enables a suite of upcoming features that make it easier to work with concurrency. We recommend that all projects adopt this setting."
- **"Default Actor Isolation" = MainActor** — module-wide implicit `@MainActor`; on by default for app projects created with Xcode 26. Use for app/UI modules only, not general-purpose libraries.

## Async Functions Stay on the Calling Actor

In Swift 6.0/6.1, non-actor-annotated async functions hopped to the generic concurrent executor. This caused data race errors when called from `@MainActor` types.

```swift
// ❌ Swift 6.0/6.1 — ERROR: Sending 'self.processor' risks causing data races
@MainActor
final class StickerModel {
    let processor = PhotoProcessor()

    func extract(_ item: PhotosPickerItem) async throws -> Sticker? {
        // processor would hop off MainActor — data race
        return await processor.extractSticker(data: data, with: item.itemIdentifier)
    }
}

class PhotoProcessor {
    func extractSticker(data: Data, with id: String?) async -> Sticker? { ... }
}
```

```swift
// ✅ Swift 6.2 — No error. Async functions stay on the caller's actor.
// The same code compiles cleanly with no changes needed.
@MainActor
final class StickerModel {
    let processor = PhotoProcessor()

    func extract(_ item: PhotosPickerItem) async throws -> Sticker? {
        return await processor.extractSticker(data: data, with: item.itemIdentifier)
    }
}
```

**Why?** In 6.2, `extractSticker` stays on `@MainActor` because the caller is `@MainActor`. No hop, no data race.

### The Mechanism: nonisolated(nonsending)

The formal name for this behavior is **`nonisolated(nonsending)`** — nonisolated async functions run on the *caller's* actor instead of hopping to the concurrent executor. Under the Approachable Concurrency setting (upcoming feature `NonisolatedNonsendingByDefault`) this becomes the default for all nonisolated async functions. Apple's framing (WWDC25 245): Swift 6.2 "eliminates implicit background offloading. Async functions that aren't tied to a specific actor continue running on the actor they were called from." The payoff: arguments never leave the caller's actor, so **non-Sendable values can be passed to nonisolated async functions without data-race errors**.

You can also write `nonisolated(nonsending)` explicitly on a single function to opt it into caller-inherited execution without the module-wide setting.

### Library API Doctrine (WWDC25 268)

- `nonisolated` runs on the caller's actor: "if you call it from the main actor, it will stay on the main actor. If you call it from a background thread, it will stay on a background thread. This makes it a great default for general-purpose libraries."
- "For libraries, it's best to provide a **nonisolated API and let clients decide whether to offload work**." Apple's example: `nonisolated public class JSONDecoder`.
- Three ways to break a main-actor tie from concurrent code: (1) move the main-actor code into a synchronous main-actor caller, (2) `await` the main actor from concurrent code, (3) mark the code `nonisolated` if it doesn't need the main actor at all.

## Infer Main Actor by Default

An opt-in build setting that makes all code implicitly `@MainActor` unless explicitly opted out. Eliminates most data race errors for app targets.

### Enabling It

**Xcode:** Build Settings → Swift Compiler - Concurrency → "Default Actor Isolation" → "MainActor"

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
// ❌ Before (Swift 6.0/6.1) — manual annotations everywhere
@MainActor
final class StickerLibrary {
    static let shared: StickerLibrary = .init()
}

@MainActor
final class StickerModel {
    let processor: PhotoProcessor
    var selection: [PhotosPickerItem]
}
```

```swift
// ✅ After (Swift 6.2 with infer main actor) — no annotations needed
final class StickerLibrary {
    static let shared: StickerLibrary = .init()  // Implicitly @MainActor
}

final class StickerModel {
    let processor: PhotoProcessor
    var selection: [PhotosPickerItem]  // Implicitly @MainActor
}
```

### When to Use

| Target Type | Recommended? | Why |
|-------------|-------------|-----|
| App target | Yes | Apps are UI-driven, most code belongs on MainActor |
| Script target | Yes | Scripts are sequential, MainActor default is natural |
| Library/framework | No | Libraries should not impose actor isolation on consumers |
| Package plugin | No | Same as libraries |

### Opting Out

When a type or function needs to run off the main actor, use `nonisolated`:

```swift
// With "infer main actor" enabled:
nonisolated struct ImageProcessor {
    func processImage(_ data: Data) -> UIImage { ... }  // Runs on any thread
}

nonisolated func heavyComputation() -> Result { ... }
```

## Isolated Conformances

Allows `@MainActor` types to conform to protocols that don't require actor isolation:

```swift
protocol Exportable {
    func export()
}

// ❌ Swift 6.0/6.1 — ERROR: Conformance crosses into main actor-isolated code
extension StickerModel: Exportable {
    func export() {
        processor.exportAsPNG()
    }
}
```

```swift
// ✅ Swift 6.2 — Isolated conformance
extension StickerModel: @MainActor Exportable {
    func export() {
        processor.exportAsPNG()
    }
}
```

### Usage Rules

Isolated conformances can only be used in matching isolation contexts:

```swift
// ✅ Used within @MainActor context — OK
@MainActor
struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // OK — both are @MainActor
    }
}

// ❌ Used outside @MainActor — compile error
nonisolated struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // Error: Main actor-isolated conformance
                            // cannot be used in nonisolated context
    }
}
```

## @concurrent — Explicit Background Execution

When you need true parallelism (CPU-heavy work off the main thread), use `@concurrent`:

```swift
class PhotoProcessor {
    var cachedStickers: [String: Sticker]

    func extractSticker(data: Data, with id: String) async -> Sticker {
        if let sticker = cachedStickers[id] { return sticker }
        let sticker = await Self.extractSubject(from: data)  // Runs on background
        cachedStickers[id] = sticker
        return sticker
    }

    @concurrent
    static func extractSubject(from data: Data) async -> Sticker {
        // Heavy image processing — runs on concurrent thread pool
        ...
    }
}
```

### Steps to Offload Work

1. Make the type `nonisolated` (if it's a struct/class, not an actor)
2. Add `@concurrent` to the function
3. Make the function `async`
4. Callers use `await`

```swift
nonisolated struct ImageProcessor {
    @concurrent
    func resize(image: Data, to size: CGSize) async -> Data {
        // Runs on background thread
        ...
    }
}

// Caller (on MainActor):
let resized = await ImageProcessor().resize(image: data, to: targetSize)
```

### @concurrent vs Task.detached vs Actor

| Mechanism | Use Case |
|-----------|----------|
| `@concurrent` | Single function that must run on background thread |
| `Task.detached` | Fire-and-forget background work, no structured parent |
| `actor` | Shared mutable state that needs serialized access |
| `Task {}` | Unstructured task inheriting current actor (usually MainActor) |

Prefer `@concurrent` for compute-heavy functions. Prefer actors for shared state. Avoid `Task.detached` when structured concurrency works.

## Concurrency in SwiftUI Views (WWDC25 266)

The `View` protocol is `@MainActor`-isolated, so every conforming type inherits it — `body`, `@State`, all members, and any `Task {}` created in the body run on the main actor. All SwiftUI action callbacks (button actions, `onTapGesture`, …) are synchronous on the main thread by design.

But SwiftUI calls **some** of your code off the main thread — these closures/requirements are `@Sendable` and may run on background threads:
- `Shape.path(in:)` (called from a background thread during animation)
- `.visualEffect { }` closures
- `Layout` protocol method requirements
- `.onGeometryChange` closures

Sharing main-actor state into those closures — capture a Sendable copy by value:

```swift
// ❌ Sends self; reads @MainActor state from a Sendable background closure
.visualEffect { content, _ in content.blur(radius: pulse ? 2 : 0) }

// ✅ Capture a Sendable copy in the capture list
.visualEffect { [pulse] content, _ in content.blur(radius: pulse ? 2 : 0) }
```

Async + animation rule: an `await` splits the function and resumption timing is not guaranteed — "this suspension could mean my task closure doesn't resume until much later, passing the refresh deadline." Structure work as a **sync/async sandwich**: set loading state synchronously → await the long-running work → set completion state synchronously. Never put time-sensitive UI mutations after an `await` when a frame deadline matters.

For the data-flow side (view identity, `@State` ownership), see `swiftui/data-flow`.

## Unsharing State Instead of Sharing It (WWDC25 270)

When parallel branches (`async let`, task group children) both need a helper that holds mutable state, don't share one instance across them — give each branch its own:

```swift
// ❌ Shared stored property accessed from two parallel branches — data-race error
let colorExtractor = ColorExtractor()          // stored on the type
async let sticker = extractSticker(from: data)
async let colors = extractColors(from: data)   // both branches touch colorExtractor

// ✅ Create the instance locally inside the branch that uses it
func extractColors(from data: Data) async -> ColorScheme {
    let colorExtractor = ColorExtractor()      // each call gets its own
    ...
}
```

The same code-along establishes the offload recipe on a 6.1+ toolchain: mark the helper type `nonisolated` (on the *type* — all members become nonisolated, detaching it from the module's MainActor default), mark the heavy function `@concurrent`, pass Sendable values (like `Data`) across, and verify the hang is gone in Instruments before and after.

## Swift 6.3 / 6.4 Additions (WWDC26 262)

Concurrency-related language changes announced at WWDC26:

| Feature | Version | What it does |
|---|---|---|
| Unhandled task error warning | 6.4 | Warning "if you silently ignore an error thrown from a Swift Concurrency task" — handle it inside `Task { do { … } catch { … } }` or store the task and check it later |
| `async` in `defer` | 6.4 | "The old restriction on calling async functions from a defer block is now gone" |
| `withTaskCancellationShield {}` | 6.4 | Inside the shield, `Task.isCancelled` reads false — finish or roll back critical work (keep the shielded region short) |
| `Continuation` type | 6.4 | "Checks at compile time that you only resume it once, making it even safer than a CheckedContinuation but just as efficient as an UnsafeContinuation" (built on noncopyable types) |
| `weak let` | 6.4 | Immutable weak references — a class previously forced into `@unchecked Sendable` by a `weak var` can keep real Sendable checking |
| `~Sendable` | 6.4 | Explicitly declare a type non-Sendable; note it "doesn't stop subclasses from being Sendable" |
| Module selectors `::` | 6.3 | `Rocket::SaturnV()` disambiguates same-named types across modules |

## Mental Model Summary

```
Swift 6.2 Concurrency Defaults:
┌────────────────────────────────────────────┐
│ Everything is @MainActor by default        │
│ (with "infer main actor" build setting)    │
│                                            │
│ async functions stay on the calling actor   │
│ (no implicit hop to background)            │
│                                            │
│ Use @concurrent to explicitly go background │
│ Use nonisolated to opt out of MainActor    │
└────────────────────────────────────────────┘

Progression:
1. Write code → runs on MainActor → no data races
2. Use async/await → stays on calling actor → still no races
3. Need parallelism → @concurrent → explicit, auditable
```

## Checklist

- [ ] Using Swift 6.2+ for approachable concurrency features
- [ ] "Infer main actor by default" enabled for app targets (not libraries)
- [ ] `@concurrent` used for CPU-heavy functions that must run on background
- [ ] `nonisolated` used to opt types/functions out of MainActor when needed
- [ ] Isolated conformances (`@MainActor Protocol`) used for MainActor types conforming to non-isolated protocols
- [ ] Not using `@MainActor` annotations everywhere (let inference handle it in 6.2)
