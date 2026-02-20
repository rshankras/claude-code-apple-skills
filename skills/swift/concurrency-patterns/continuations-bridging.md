# Continuations and Bridging

Patterns for wrapping legacy callback-based, delegate-based, and notification-based APIs into async/await.

## withCheckedContinuation

Wraps a single-callback API into an async function:

```swift
func currentLocation() async -> CLLocation {
    await withCheckedContinuation { continuation in
        locationManager.requestLocation { location in
            continuation.resume(returning: location)
        }
    }
}
```

### Throwing Variant

```swift
func fetchImage(named name: String) async throws -> UIImage {
    try await withCheckedThrowingContinuation { continuation in
        imageLoader.load(name: name) { result in
            switch result {
            case .success(let image):
                continuation.resume(returning: image)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

### The "Exactly Once" Rule

A continuation must be resumed **exactly once**. Resuming zero times leaks the task forever. Resuming twice crashes.

```swift
// ❌ Bug — continuation never resumed on timeout
func fetchWithTimeout() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        apiClient.fetch { data in
            continuation.resume(returning: data)
        }
        // If timeout fires and callback never fires → leaked forever
    }
}

// ❌ Bug — continuation resumed twice
func fetchData() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        apiClient.fetch { result in
            switch result {
            case .success(let data):
                continuation.resume(returning: data)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
        // What if the callback fires twice? Second resume → crash
    }
}
```

**Fix: Guard with a flag or use the callback structure carefully:**

```swift
// ✅ Ensure exactly one resume
func fetchData() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        var hasResumed = false

        apiClient.fetch { result in
            guard !hasResumed else { return }
            hasResumed = true

            switch result {
            case .success(let data):
                continuation.resume(returning: data)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

### Checked vs Unsafe Continuations

| Type | Debug Behavior | Release Behavior | Use When |
|------|---------------|-----------------|----------|
| `withCheckedContinuation` | Traps on misuse (zero or double resume) | Traps on misuse | Default choice, always start here |
| `withUnsafeContinuation` | No checking | No checking | Performance-critical hot paths only |

Always use `withCheckedContinuation` unless profiling shows the check is a bottleneck. The checked variant catches bugs that are extremely hard to debug otherwise.

## Bridging Delegate APIs

Many Apple APIs use delegates (CLLocationManager, ASAuthorizationController, etc.). Bridge them with a continuation-holding helper:

```swift
class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.last!)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

// Usage:
let fetcher = LocationFetcher()
let location = try await fetcher.requestLocation()
```

### Sign in with Apple

```swift
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?

    func signIn() async throws -> ASAuthorization {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
```

## AsyncStream — Bridging Multi-Value Sources

For APIs that produce multiple values over time (delegates, NotificationCenter, KVO), use `AsyncStream`:

### NotificationCenter

```swift
extension NotificationCenter {
    func notifications(named name: Notification.Name) -> AsyncStream<Notification> {
        AsyncStream { continuation in
            let observer = addObserver(forName: name, object: nil, queue: nil) { notification in
                continuation.yield(notification)
            }
            continuation.onTermination = { @Sendable _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

// Usage:
for await notification in NotificationCenter.default.notifications(named: .NSManagedObjectContextDidSave) {
    await handleSave(notification)
}
```

### CLLocationManager Continuous Updates

```swift
class LocationStream: NSObject, CLLocationManagerDelegate {
    private var continuation: AsyncStream<CLLocation>.Continuation?
    private let manager = CLLocationManager()

    func locations() -> AsyncStream<CLLocation> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                self?.manager.stopUpdatingLocation()
            }
            manager.delegate = self
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            continuation?.yield(location)
        }
    }
}

// Usage:
for await location in locationStream.locations() {
    updateMap(with: location)
}
```

### AsyncStream with Buffering

```swift
AsyncStream(bufferingPolicy: .bufferingNewest(10)) { continuation in
    // Keeps only the 10 most recent values if consumer is slow
    eventSource.onEvent = { event in
        continuation.yield(event)
    }
}
```

Buffering policies:
| Policy | Behavior |
|--------|----------|
| `.unbounded` | Buffer everything (default, can grow unbounded) |
| `.bufferingNewest(N)` | Keep only the N most recent values |
| `.bufferingOldest(N)` | Keep only the N oldest values, drop new ones |

## AsyncThrowingStream

For streams that can also produce errors:

```swift
func eventStream() -> AsyncThrowingStream<Event, Error> {
    AsyncThrowingStream { continuation in
        websocket.onMessage = { message in
            continuation.yield(message)
        }
        websocket.onError = { error in
            continuation.finish(throwing: error)
        }
        websocket.onClose = {
            continuation.finish()
        }
    }
}

// Usage:
do {
    for try await event in eventStream() {
        handle(event)
    }
} catch {
    handleDisconnection(error)
}
```

## Common Mistakes

### Forgetting onTermination Cleanup

```swift
// ❌ Resource leak — observer never removed
AsyncStream<Notification> { continuation in
    let observer = NotificationCenter.default.addObserver(...)
    // No cleanup when stream is cancelled
}

// ✅ Clean up on termination
AsyncStream<Notification> { continuation in
    let observer = NotificationCenter.default.addObserver(...)
    continuation.onTermination = { @Sendable _ in
        NotificationCenter.default.removeObserver(observer)
    }
}
```

### Capturing Self Strongly in Continuation

```swift
// ❌ Retain cycle — continuation holds self, self holds continuation
class StreamProvider {
    var continuation: AsyncStream<Event>.Continuation?

    func events() -> AsyncStream<Event> {
        AsyncStream { continuation in
            self.continuation = continuation  // Strong reference cycle
        }
    }
}

// ✅ Use weak self in onTermination, nil out continuation
continuation.onTermination = { @Sendable [weak self] _ in
    self?.continuation = nil
}
```

### Using AsyncStream for Single Values

```swift
// ❌ Overkill — AsyncStream for a one-shot result
func fetchUser() -> AsyncStream<User> {
    AsyncStream { continuation in
        api.getUser { user in
            continuation.yield(user)
            continuation.finish()
        }
    }
}

// ✅ Use withCheckedContinuation for single values
func fetchUser() async -> User {
    await withCheckedContinuation { continuation in
        api.getUser { user in
            continuation.resume(returning: user)
        }
    }
}
```

## Checklist

- [ ] Using `withCheckedContinuation` (not unsafe) unless profiling demands it
- [ ] Continuation resumed exactly once in all code paths
- [ ] `continuation = nil` after resuming to prevent double-resume
- [ ] `onTermination` handler cleans up resources (observers, delegates, timers)
- [ ] `AsyncStream` for multi-value sources, `withCheckedContinuation` for single-value
- [ ] Appropriate buffering policy chosen for `AsyncStream`
- [ ] No strong reference cycles between continuation holder and stream provider
