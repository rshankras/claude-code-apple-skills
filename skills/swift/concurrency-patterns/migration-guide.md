# Swift 6 Strict Concurrency Migration

Step-by-step guide for incrementally adopting Swift 6 strict concurrency checking. Covers the migration path from Swift 5 to Swift 6.2. Doctrine sourced from Apple's WWDC24 "Migrate your app to Swift 6" (10169); full strategy guide at swift.org/migration.

## Apple's Migration Doctrine (WWDC24 10169)

- **Migrate per target, one at a time**: enable complete checking (warnings) → resolve all warnings → flip that target to Swift 6 language mode (locks in enforcement) → next target.
- **Start with the UI/app target and work top-down.** The UI layer mostly runs on the main thread against SDK APIs already annotated `@MainActor`, and going app → your frameworks handles not-yet-migrated dependencies gracefully.
- **Don't refactor while migrating.** Verbatim: "resist the temptation to blend together both significant refactoring and enabling data race safety. Try to do one at a time. If you try to do both at once, you'll probably find it too much change at once, and have to backtrack." Whole-app refactors (e.g. moving `nonisolated(unsafe)` state into actors) come *after* all targets are migrated.
- **Don't pre-audit — let the compiler drive.** Skip the manual `@MainActor`/`Sendable` audit; turn on complete checking and follow the diagnostics ("like a pair programmer pointing out potential bugs").
- **Don't panic at the warning count.** Warnings cluster: a few root issues produce many knock-on diagnostics. Hunt quick wins first (`var`→`let` on a global, one `@MainActor`, one `Sendable` conformance can clear dozens of sites).
- **Migration is pausable.** You can turn complete checking back off to ship; every fix already made remains a valid improvement to commit.
- **Re-check against the latest SDKs before fixing.** Newer SDKs added `@MainActor` annotations (the SwiftUI `View` protocol, many delegate protocols) — annotations you added under older SDKs may now be inferable and removable.
- Building with a Swift 6 compiler changes nothing by itself — data-race enforcement is the *only* thing gated by the language mode; all other Swift 6 features are on regardless (WWDC24 10136).
- If you maintain a public package, migrate it ASAP — downstream migrators benefit from Swift-6-clean dependencies.

## Migration Strategy

Adopt strict concurrency incrementally, not all at once:

```
Swift 5 mode          → Swift 6 language mode
(no checking)           (strict checking)

Step 1: minimal        Warnings for clearly unsafe patterns
Step 2: targeted       Warnings for code interacting with concurrent features
Step 3: complete       Warnings for ALL concurrency violations
Step 4: Swift 6 mode   Warnings become errors
Step 5: Swift 6.2      Enable "infer main actor" for even cleaner code
```

## Step 1: Enable Minimal Checking

Start with minimal concurrency warnings to find the most obvious issues.

**Xcode:** Build Settings → "Strict Concurrency Checking" → "Minimal"

**Package.swift:**
```swift
.target(
    name: "MyTarget",
    swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency=minimal")
    ]
)
```

Fix issues like:
- Global/static `var` without isolation
- Non-Sendable types used in `@Sendable` closures

## Step 2: Enable Targeted Checking

**Xcode:** Build Settings → "Strict Concurrency Checking" → "Targeted"

This warns about code that interacts with concurrency features (async functions, actors, Task).

## Step 3: Enable Complete Checking

**Xcode:** Build Settings → "Strict Concurrency Checking" → "Complete"

**Package.swift:**
```swift
.target(
    name: "MyTarget",
    swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency=complete")
    ]
)
```

All concurrency violations now produce warnings. Fix them all before proceeding.

## Step 4: Switch to Swift 6 Language Mode

Now promote all warnings to errors:

**Xcode:** Build Settings → "Swift Language Version" → "6"

**Package.swift:**
```swift
// swift-tools-version: 6.0
let package = Package(
    name: "MyPackage",
    ...
)
```

## Step 5: Adopt Swift 6.2 Features (Optional)

Enable "infer main actor by default" for app targets to eliminate remaining annotations:

**Xcode:** Build Settings → "Default Actor Isolation" → "MainActor"

See `swift62-concurrency.md` for details.

## Common Migration Patterns

### Global / Static Variables

```swift
// ❌ Swift 6 error: Static property is not concurrency-safe
class AppConfig {
    static var shared = AppConfig()
    var apiKey: String = ""
}
```

**Fix options:**

```swift
// Option 1: Make it @MainActor (simplest for app code)
@MainActor
class AppConfig {
    static let shared = AppConfig()
    var apiKey: String = ""
}

// Option 2: Make it an actor
actor AppConfig {
    static let shared = AppConfig()
    var apiKey: String = ""
}

// Option 3: Make it Sendable + immutable
final class AppConfig: Sendable {
    static let shared = AppConfig()
    let apiKey: String = "..."  // Must be let, not var
}

// Option 4: nonisolated(unsafe) — last resort
nonisolated(unsafe) static var shared = AppConfig()
```

Prefer Options 1–3 above, in order, over Option 4 — `nonisolated(unsafe)` is a last resort only when something else already guards the state.

### Non-Sendable Closures

```swift
// ❌ Closure captures non-Sendable type
let viewModel = MyViewModel()  // Not Sendable
Task {
    await viewModel.load()  // Sending non-Sendable across isolation
}
```

**Fix options:**

```swift
// Option 1: Make the type Sendable
final class MyViewModel: Sendable { ... }

// Option 2: Make it @MainActor (if it's a ViewModel)
@MainActor
final class MyViewModel { ... }

// Option 3: Use the type within its own isolation
@MainActor
func loadData() async {
    let viewModel = MyViewModel()  // Created on MainActor
    await viewModel.load()         // Stays on MainActor
}
```

### Protocol Conformances

```swift
// ❌ Swift 6 error: @MainActor type can't conform to non-isolated protocol
protocol DataProvider {
    func fetchData() async -> [Item]
}

@MainActor
class ItemProvider: DataProvider {
    func fetchData() async -> [Item] { ... }  // Error
}
```

**Fix with Swift 6.2 isolated conformance:**

```swift
// ✅ Swift 6.2: Isolated conformance
extension ItemProvider: @MainActor DataProvider {
    func fetchData() async -> [Item] { ... }
}
```

**Fix for Swift 6.0/6.1:**

```swift
// ✅ Make the protocol method nonisolated
extension ItemProvider: DataProvider {
    nonisolated func fetchData() async -> [Item] {
        await MainActor.run { ... }
    }
}
```

### Imported C / Objective-C Types

Many imported types are not annotated for concurrency. Use `@preconcurrency` to suppress warnings:

```swift
// ❌ Warning: Type from ObjC module is not Sendable
import CoreLocation

// ✅ Suppress warnings for imported module
@preconcurrency import CoreLocation
```

`@preconcurrency` silences Sendable warnings for types from that module. Remove it once the module adds Sendable annotations.

### Delegate Patterns

Every callback API falls into one of three isolation contracts (WWDC24 10169):

| Contract | Example | Migration move |
|---|---|---|
| Guaranteed main thread | Most UI frameworks | Rely on / add `@MainActor` |
| Arbitrary thread | Backend-style callbacks (e.g. HealthKit) | Receiver `nonisolated`, re-dispatch explicitly |
| Dynamic guarantee | `CLLocationManager` (calls back on the thread that created it) | `nonisolated` + `MainActor.assumeIsolated` (below) |

```swift
// ❌ Delegate callback crosses isolation
class LocationService: NSObject, CLLocationManagerDelegate {
    @MainActor var lastLocation: CLLocation?

    func locationManager(_ manager: CLLocationManager,
                          didUpdateLocations locations: [CLLocation]) {
        // Error: mutating @MainActor property from non-isolated context
        lastLocation = locations.last
    }
}
```

**Fix (arbitrary-thread contract) — hop explicitly:**

```swift
// ✅ Dispatch to MainActor (new task; ordering not guaranteed)
func locationManager(_ manager: CLLocationManager,
                      didUpdateLocations locations: [CLLocation]) {
    let location = locations.last
    Task { @MainActor in
        lastLocation = location
    }
}
```

**Fix (dynamic contract) — assert the isolation you can prove:** when docs/source guarantee the callback arrives on the main actor (e.g. the whole delegate class is `@MainActor`, so the manager was created on the main thread), use `MainActor.assumeIsolated` — no new task, and it **traps** if ever called off the main actor. Apple's rationale: "trapping isn't something you want, but it's better than a race condition that could corrupt user's data."

```swift
@MainActor
class LocationService: NSObject, CLLocationManagerDelegate {
    var lastLocation: CLLocation?

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            lastLocation = locations.last
        }
    }
}
```

**Shorthand for a whole conformance**: `extension MyType: @preconcurrency SomeDelegate` assumes the conforming type's isolation at each requirement and traps if violated. It self-cleans: once the protocol gains a real `@MainActor` annotation, the compiler warns the attribute "has no effect" — remove it.

**Prefer async-sequence APIs over delegates** when the deployment target allows (e.g. `for try await update in CLLocationUpdate.liveUpdates()`) — straight-line code instead of state stashed across delegate fires; Apple suggests this alone can justify raising a deployment target.

### Notification Observers

```swift
// ❌ Closure may run on any thread
NotificationCenter.default.addObserver(
    forName: .someNotification, object: nil, queue: nil
) { notification in
    self.handleNotification(notification)  // May cross isolation
}

// ✅ Specify main queue, or bridge to AsyncSequence
NotificationCenter.default.addObserver(
    forName: .someNotification, object: nil, queue: .main
) { notification in
    self.handleNotification(notification)  // Runs on main thread
}

// ✅ Or use async notification stream
for await notification in NotificationCenter.default.notifications(named: .someNotification) {
    await handleNotification(notification)
}
```

## nonisolated(unsafe) — Last Resort

For code that you know is safe but can't prove to the compiler:

```swift
// Only use when you've exhausted all other options
nonisolated(unsafe) static var shared = LegacyManager()
```

**When it's acceptable:**
- Bridging with C/ObjC singletons that are known thread-safe
- Third-party library types that are thread-safe but not Sendable-annotated
- Temporary escape hatch during incremental migration

**When it's NOT acceptable:**
- To silence warnings you don't understand
- For mutable state without synchronization
- As a permanent solution (always plan to remove it)

## Module-by-Module Migration

For large projects, migrate one module at a time:

1. Start with leaf modules (no dependencies on other project modules)
2. Enable "complete" checking on that module
3. Fix all warnings
4. Move to the next module up the dependency chain
5. Once all modules pass, switch to Swift 6 language mode

This prevents a flood of errors across the entire project.

## Checklist

- [ ] Started with "minimal" checking, progressed to "complete"
- [ ] All global/static `var` either `@MainActor`, actor-isolated, or immutable
- [ ] Non-Sendable types not crossing isolation boundaries
- [ ] `@preconcurrency import` used for unannoted third-party modules
- [ ] No `nonisolated(unsafe)` without a comment explaining why it's safe
- [ ] Protocol conformances using isolated conformances (6.2) or `nonisolated` workarounds
- [ ] Delegate callbacks dispatched to correct isolation context
- [ ] Migration done module-by-module for large projects
- [ ] Swift 6 language mode enabled after all warnings resolved
- [ ] Sendable chains followed to the root: marking a type Sendable flags its non-Sendable stored properties — fix those, don't `@unchecked` the parent
- [ ] `MainActor.assumeIsolated` / `@preconcurrency` conformance used only where the main-thread guarantee is documented
- [ ] No refactoring mixed into the migration commits

## References

- [WWDC24 — Migrate your app to Swift 6](https://developer.apple.com/videos/play/wwdc2024/10169/)
- [Swift 6 migration guide](https://www.swift.org/migration/)
