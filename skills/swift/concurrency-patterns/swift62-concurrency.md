# Swift 6.2 Approachable Concurrency

Swift 6.2 makes strict concurrency dramatically easier to adopt. The core philosophy: code runs on `@MainActor` by default, async functions stay on the calling actor, and you explicitly opt into background execution with `@concurrent`.

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
