# Swift 6 Strict Concurrency Migration

Step-by-step guide for incrementally adopting Swift 6 strict concurrency checking. Covers the migration path from Swift 5 to Swift 6.2.

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

**Fix:**

```swift
// ✅ Dispatch to MainActor
func locationManager(_ manager: CLLocationManager,
                      didUpdateLocations locations: [CLLocation]) {
    let location = locations.last
    Task { @MainActor in
        lastLocation = location
    }
}
```

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
