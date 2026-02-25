---
name: offline-queue
description: Generates an offline operation queue with persistence, automatic retry on connectivity, and conflict resolution. Use when user needs offline-first behavior, queued mutations, or pending operations that sync when back online.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Offline Queue Generator

Generate a production offline operation queue that persists API requests/mutations when offline, stores them to disk, and retries with exponential backoff when connectivity returns. Essential for apps that need offline-first behavior.

## When This Skill Activates

Use this skill when the user:
- Asks to "add offline queue" or "offline support"
- Wants to "queue requests" when there is no network
- Mentions "offline first" architecture or design
- Asks about "retry when online" or "retry on reconnect"
- Wants "pending operations" that sync later
- Mentions "offline mutations" or "queue API calls"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing networking/offline code:
```
Glob: **/*OfflineQueue*.swift, **/*OfflineOperation*.swift, **/*NetworkMonitor*.swift, **/*RetryPolicy*.swift
Grep: "NWPathMonitor" or "OfflineQueue" or "pendingOperations" or "offlineQueue"
```

If existing offline handling found:
- Ask if user wants to replace or extend it
- If extending, adapt generated code to existing patterns

### 3. Framework Availability
Check for Network framework availability (required for NWPathMonitor). Available on iOS 12+ / macOS 10.14+, so effectively always available for our iOS 16+ / macOS 13+ targets.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Operation types?**
   - API calls only (JSON requests/responses)
   - File uploads only (multipart data)
   - Both API calls and file uploads

2. **Persistence strategy?**
   - SwiftData (iOS 17+ / macOS 14+) — structured queries, migration support
   - File-based (JSON files in app support) — simpler, wider compatibility — recommended

3. **Retry strategy?**
   - Exponential backoff with jitter — recommended (prevents thundering herd)
   - Linear backoff (fixed interval between retries)
   - Immediate (retry as soon as connectivity returns, no delay)

4. **Conflict resolution?**
   - Server wins (discard client changes on conflict)
   - Client wins (overwrite server data on conflict)
   - Manual merge (surface conflicts to the user for resolution)

## Generation Process

### Step 1: Read Templates
Read `patterns.md` for architecture guidance and conflict resolution strategies.
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `OfflineOperation.swift` — Codable model for queued operations
2. `OfflineQueueManager.swift` — Actor managing enqueue, dequeue, process, retry
3. `QueuePersistence.swift` — Protocol + file-based implementation for saving operations
4. `NetworkMonitor.swift` — @Observable wrapper around NWPathMonitor

### Step 3: Create Policy Files
5. `RetryPolicy.swift` — Configurable backoff strategy with jitter

### Step 4: Create UI Files
6. `OfflineQueueDashboardView.swift` — Debug view showing queue state and manual controls
7. `OfflineQueueModifier.swift` — ViewModifier showing "Offline" banner when disconnected

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists → `Sources/OfflineQueue/`
- If `App/` exists → `App/OfflineQueue/`
- Otherwise → `OfflineQueue/`

## Output Format

After generation, provide:

### Files Created
```
OfflineQueue/
├── OfflineOperation.swift          # Codable operation model
├── OfflineQueueManager.swift       # Actor-based queue manager
├── QueuePersistence.swift          # Protocol + file-based persistence
├── NetworkMonitor.swift            # NWPathMonitor wrapper
├── RetryPolicy.swift               # Exponential backoff with jitter
├── OfflineQueueDashboardView.swift # Debug dashboard view
└── OfflineQueueModifier.swift      # Offline banner modifier
```

### Integration with Networking Layer

**Enqueue an operation when offline:**
```swift
// In your networking layer or repository
func createPost(_ post: Post) async throws {
    guard networkMonitor.isConnected else {
        let operation = OfflineOperation(
            endpoint: "/api/posts",
            httpMethod: .post,
            body: try JSONEncoder().encode(post),
            headers: ["Content-Type": "application/json"]
        )
        await queueManager.enqueue(operation)
        return
    }
    // Normal online request
    try await apiClient.post("/api/posts", body: post)
}
```

**Transparent offline support with a wrapper:**
```swift
func performOrQueue<T: Codable>(
    endpoint: String,
    method: HTTPMethod,
    body: T
) async throws {
    let data = try JSONEncoder().encode(body)

    if networkMonitor.isConnected {
        try await apiClient.request(endpoint: endpoint, method: method, body: data)
    } else {
        let operation = OfflineOperation(
            endpoint: endpoint,
            httpMethod: method,
            body: data
        )
        await queueManager.enqueue(operation)
    }
}
```

**Show offline banner in your app:**
```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            FeedView()
        }
        .offlineQueueBanner()  // Shows "Offline — changes will sync" when disconnected
    }
}
```

**Add dashboard for debugging:**
```swift
#if DEBUG
NavigationLink("Offline Queue") {
    OfflineQueueDashboardView()
}
#endif
```

### Testing

```swift
@Test
func operationEnqueuedWhenOffline() async throws {
    let persistence = MockQueuePersistence()
    let monitor = MockNetworkMonitor(isConnected: false)
    let manager = OfflineQueueManager(persistence: persistence, monitor: monitor)

    let operation = OfflineOperation(
        endpoint: "/api/posts",
        httpMethod: .post,
        body: Data("{\"title\":\"Hello\"}".utf8)
    )
    await manager.enqueue(operation)

    let pending = await persistence.loadAll()
    #expect(pending.count == 1)
    #expect(pending.first?.endpoint == "/api/posts")
}

@Test
func operationsProcessedOnReconnect() async throws {
    let persistence = MockQueuePersistence()
    let monitor = MockNetworkMonitor(isConnected: false)
    let executor = MockOperationExecutor()
    let manager = OfflineQueueManager(
        persistence: persistence,
        monitor: monitor,
        executor: executor
    )

    let operation = OfflineOperation(
        endpoint: "/api/posts",
        httpMethod: .post,
        body: Data("{\"title\":\"Hello\"}".utf8)
    )
    await manager.enqueue(operation)

    // Simulate coming back online
    monitor.simulateConnectivityChange(isConnected: true)

    // Wait for processing
    try await Task.sleep(for: .milliseconds(200))

    #expect(executor.executedOperations.count == 1)
    let remaining = await persistence.loadAll()
    #expect(remaining.isEmpty)
}

@Test
func exponentialBackoffCalculation() {
    let policy = RetryPolicy(
        maxRetries: 5,
        baseDelay: 1.0,
        maxDelay: 60.0,
        multiplier: 2.0
    )

    #expect(policy.delay(forAttempt: 0) >= 1.0)
    #expect(policy.delay(forAttempt: 1) >= 2.0)
    #expect(policy.delay(forAttempt: 2) >= 4.0)
    #expect(policy.delay(forAttempt: 5) <= 60.0)  // Capped at maxDelay
}
```

## Common Patterns

### Enqueue Operation
```swift
let operation = OfflineOperation(
    endpoint: "/api/comments",
    httpMethod: .post,
    body: try JSONEncoder().encode(comment),
    headers: ["Authorization": "Bearer \(token)"]
)
await queueManager.enqueue(operation)
```

### Process Queue on Connectivity
```swift
// Automatic — OfflineQueueManager observes NetworkMonitor
// and calls processQueue() when connectivity returns.
// No manual intervention needed.
```

### Handle Conflict Resolution
```swift
// Server returns 409 Conflict
switch conflictStrategy {
case .serverWins:
    // Discard local operation, fetch server state
    await queueManager.markCompleted(operation)
case .clientWins:
    // Retry with force flag
    operation.headers["X-Force-Overwrite"] = "true"
    await queueManager.retry(operation)
case .manualMerge:
    // Surface to user
    await queueManager.markConflict(operation, serverData: responseData)
}
```

## Gotchas

### Operation Ordering and Dependencies
Operations may have dependencies (e.g., "create parent" must succeed before "create child"). The queue processes in FIFO order by default. For explicit dependencies, use the `dependsOn` field to chain operations, and the queue manager will skip dependent operations until their prerequisites complete.

### Idempotency Keys
Every queued operation gets a UUID-based idempotency key. The server must check this key to avoid duplicate processing if the client retries an operation that actually succeeded but the response was lost. Without idempotency keys, a retry could create duplicate records.

### Stale Data After Long Offline Periods
If the device is offline for hours or days, queued operations may reference data that has changed server-side. Consider adding a TTL to operations (e.g., 24 hours) and discarding expired operations with a user notification rather than blindly replaying stale mutations.

### Background URLSession for Large Uploads
For file uploads, use a background `URLSession` configuration so uploads continue even when the app is suspended. The standard queue manager handles JSON API calls; for large uploads, delegate to a background transfer service.

### Queue Size Limits
Set a maximum queue size (e.g., 500 operations or 50 MB) to prevent unbounded growth. When the limit is reached, notify the user that offline storage is full and suggest connecting to sync pending changes.

## References

- **templates.md** — All production Swift templates
- **patterns.md** — Offline-first architecture, conflict resolution, idempotency
- Related: `generators/networking-layer` — Base networking layer to wrap with offline support
- Related: `generators/http-cache` — Cache GET responses for offline reading
