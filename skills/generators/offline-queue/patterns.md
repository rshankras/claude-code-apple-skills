# Offline Queue Patterns & Strategies

## Offline-First vs Offline-Tolerant

Two fundamentally different approaches to offline support:

| Aspect | Offline-Tolerant | Offline-First |
|--------|-----------------|---------------|
| Default state | Online; offline is an edge case | Offline; online is a sync opportunity |
| Reads | Always from server | Always from local store |
| Writes | Fail or queue when offline | Always write locally, sync later |
| Complexity | Lower — queue and retry | Higher — full local data layer + sync |
| User experience | "Retry when online" banners | App works seamlessly, syncs in background |
| Best for | Form submissions, mutations | Note apps, todo apps, field apps |

**This generator produces an offline-tolerant queue.** For full offline-first architecture, combine this with a local persistence layer (SwiftData, Core Data, or SQLite) that serves as the source of truth.

### When to Use Each

**Offline-tolerant (this generator):**
- User submits a form while in a tunnel
- API call fails due to transient connectivity
- File upload interrupted by network switch
- The app primarily reads from the server

**Offline-first (requires additional architecture):**
- Note-taking or todo apps that must work in airplane mode
- Field service apps used in areas with poor connectivity
- Collaborative apps where users work independently then sync
- Apps where read and write must both work offline

## Idempotency

### Why Every Queued Operation Needs a Unique Key

Without idempotency keys, this failure scenario creates duplicates:

```
1. Client sends POST /api/orders (create order)
2. Server processes request, creates order #1234
3. Network drops before response reaches client
4. Client thinks it failed, retries POST /api/orders
5. Server creates ANOTHER order #1235 — duplicate!
```

With idempotency keys:

```
1. Client sends POST /api/orders with Idempotency-Key: abc-123
2. Server processes request, stores key abc-123 → order #1234
3. Network drops before response reaches client
4. Client retries POST /api/orders with same Idempotency-Key: abc-123
5. Server sees key abc-123 already used → returns order #1234 (no duplicate)
```

### Implementation

```swift
struct OfflineOperation: Codable {
    let idempotencyKey: String  // UUID generated at enqueue time

    init(endpoint: String, ...) {
        // Key is created ONCE when the operation is first enqueued
        // and persists across all retry attempts
        self.idempotencyKey = UUID().uuidString
    }
}
```

### Server-Side Deduplication

The server must:
1. Store idempotency keys with their results (e.g., in Redis with TTL)
2. On receiving a request, check if the key exists
3. If key exists, return the stored result without re-processing
4. If key is new, process the request and store the key + result

```swift
// Client sends the key as a header
func execute(_ operation: OfflineOperation) async throws {
    var request = URLRequest(url: baseURL.appending(path: operation.endpoint))
    request.httpMethod = operation.httpMethod.rawValue
    request.httpBody = operation.body
    request.setValue(operation.idempotencyKey, forHTTPHeaderField: "Idempotency-Key")

    for (key, value) in operation.headers {
        request.setValue(value, forHTTPHeaderField: key)
    }

    let (data, response) = try await session.data(for: request)
    // Handle response...
}
```

### Key Lifetime

- Keys should be stored server-side for at least 24 hours
- Client must use the **same** key across all retries of the same logical operation
- A new logical operation (even to the same endpoint) gets a new key

## Conflict Resolution Strategies

When the client replays a queued operation and the server state has changed, conflicts arise. Four main strategies:

### Last-Write-Wins (LWW)

The most recent write overwrites all previous writes, regardless of source.

```swift
// Server compares timestamps
// Whichever write has the later timestamp wins
// Simple but can lose data silently
```

**Pros:** Simple, no user intervention
**Cons:** Silently loses data, timestamp ordering issues across devices

### Server-Wins

When a conflict is detected (HTTP 409), the client discards its local changes and fetches the current server state.

```swift
func resolveServerWins(_ operation: OfflineOperation, serverData: Data) async {
    // Discard the local operation
    await queueManager.markCompleted(operation)

    // Fetch fresh server state and update local UI
    let currentState = try? JSONDecoder().decode(ServerModel.self, from: serverData)
    await updateLocalState(currentState)
}
```

**Pros:** Server is always the source of truth, simple
**Cons:** User loses offline changes, frustrating UX

### Client-Wins

The client forces its changes onto the server, overwriting whatever changed.

```swift
func resolveClientWins(_ operation: OfflineOperation) async {
    // Retry with a force-overwrite header
    var retryOp = operation
    retryOp.headers["X-Force-Overwrite"] = "true"
    retryOp.headers["If-Match"] = "*"  // Override any ETag check
    await queueManager.retry(retryOp)
}
```

**Pros:** User changes are always preserved
**Cons:** Can overwrite important server-side changes from other users

### Manual Merge (Three-Way Merge)

Surface the conflict to the user, showing both the local and server versions, and let the user decide.

```swift
/// A conflict requiring user resolution.
struct ConflictResolution: Identifiable {
    let id: UUID
    let operation: OfflineOperation
    let localData: Data
    let serverData: Data
    let description: String
}

/// View for resolving a single conflict.
struct ConflictResolutionView: View {
    let conflict: ConflictResolution
    let onResolve: (ConflictChoice) -> Void

    enum ConflictChoice {
        case keepLocal
        case keepServer
        case mergeManually(Data)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Conflict Detected")
                .font(.headline)

            Text(conflict.description)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Your Version").font(.subheadline.bold())
                    // Display local data
                }

                Divider()

                VStack(alignment: .leading) {
                    Text("Server Version").font(.subheadline.bold())
                    // Display server data
                }
            }

            HStack {
                Button("Keep Mine") { onResolve(.keepLocal) }
                    .buttonStyle(.bordered)
                Button("Keep Server") { onResolve(.keepServer) }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
```

**Pros:** Most accurate, no data loss
**Cons:** Requires user interaction, complex to implement, poor UX if frequent

### Choosing a Strategy

| App Type | Recommended Strategy |
|----------|---------------------|
| Social media (posts, comments) | Server-wins — other users' context matters |
| Note-taking / personal data | Client-wins — user's changes are sacred |
| Collaborative editing | Manual merge — both versions matter |
| E-commerce (orders) | Idempotency — conflicts shouldn't happen |
| Analytics / logging | Last-write-wins — order doesn't matter |

## Operation Dependencies

### The Problem

Some operations must execute in a specific order:

```
1. POST /api/folders (create parent folder)
2. POST /api/documents (create document in that folder)

If #2 executes before #1 → 404: folder not found
```

### Solution: Dependency Chain

```swift
let createFolder = OfflineOperation(
    id: UUID(),
    endpoint: "/api/folders",
    httpMethod: .post,
    body: folderData
)

let createDocument = OfflineOperation(
    endpoint: "/api/documents",
    httpMethod: .post,
    body: documentData,
    dependsOn: createFolder.id  // Won't execute until folder is created
)

await queueManager.enqueue(createFolder)
await queueManager.enqueue(createDocument)
```

### Queue Manager Dependency Resolution

```swift
private func nextOperationToProcess() -> OfflineOperation? {
    let completedIDs = Set(queue.filter { $0.status == .completed }.map(\.id))

    return queue.first { op in
        guard op.status == .pending else { return false }

        // Check if dependency is satisfied
        if let dependency = op.dependsOn {
            let dependencyCompleted = completedIDs.contains(dependency)
            let dependencyGone = !queue.contains(where: { $0.id == dependency })
            return dependencyCompleted || dependencyGone
        }

        return true
    }
}
```

### Cascading Failures

When a parent operation fails permanently, all dependent operations should also fail:

```swift
private func cascadeFailure(for operationID: UUID) {
    let dependents = queue.filter { $0.dependsOn == operationID }
    for var dependent in dependents {
        dependent.status = .failed
        dependent.lastError = "Dependency failed"
        updateOperation(dependent)
        // Recursively cascade
        cascadeFailure(for: dependent.id)
    }
}
```

## Background Processing

### BGTaskScheduler for Queue Processing

Process the offline queue even when the app is in the background:

```swift
import BackgroundTasks

/// Register background task at app launch.
func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.app.offlinequeue.process",
        using: nil
    ) { task in
        handleOfflineQueueProcessing(task: task as! BGProcessingTask)
    }
}

/// Schedule background processing.
func scheduleOfflineQueueProcessing() {
    let request = BGProcessingTaskRequest(identifier: "com.app.offlinequeue.process")
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = false
    request.earliestBeginDate = Date(timeIntervalSinceNow: 60)  // 1 minute from now

    try? BGTaskScheduler.shared.submit(request)
}

/// Handle background task execution.
func handleOfflineQueueProcessing(task: BGProcessingTask) {
    let processingTask = Task {
        await queueManager.processQueue()
    }

    task.expirationHandler = {
        processingTask.cancel()
    }

    Task {
        _ = await processingTask.result
        task.setTaskCompleted(success: true)
        // Schedule next run if there are still pending operations
        if await queueManager.pendingCount > 0 {
            scheduleOfflineQueueProcessing()
        }
    }
}
```

Add to `Info.plist`:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.app.offlinequeue.process</string>
</array>
```

### Background URLSession for Large Uploads

For file uploads that should continue when the app is suspended:

```swift
/// Background upload session for large file operations.
final class BackgroundUploadManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate, Sendable {
    static let shared = BackgroundUploadManager()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(
            withIdentifier: "com.app.offlinequeue.uploads"
        )
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func uploadFile(at localURL: URL, to remoteURL: URL) {
        var request = URLRequest(url: remoteURL)
        request.httpMethod = "POST"
        session.uploadTask(with: request, fromFile: localURL).resume()
    }

    // URLSessionTaskDelegate
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            // Handle upload failure — re-enqueue if needed
            print("Background upload failed: \(error.localizedDescription)")
        } else {
            // Upload succeeded
            print("Background upload completed")
        }
    }
}
```

## Queue Size Management

### Why Limits Matter

Without limits, a device offline for days could accumulate thousands of operations, consuming storage and creating a "thundering herd" when connectivity returns.

### Maximum Queue Size

```swift
actor OfflineQueueManager {
    private let maxQueueSize = 500
    private let maxQueueBytes = 50 * 1024 * 1024  // 50 MB

    func enqueue(_ operation: OfflineOperation) async throws {
        guard queue.count < maxQueueSize else {
            throw OfflineQueueError.queueFull(
                message: "Queue has \(queue.count) operations. Connect to sync pending changes."
            )
        }

        let currentSize = await persistence.totalSize()
        guard currentSize < maxQueueBytes else {
            throw OfflineQueueError.storageFull(
                message: "Queue storage exceeds \(maxQueueBytes / 1024 / 1024) MB."
            )
        }

        queue.append(operation)
        await persistence.save(operation)
    }
}

enum OfflineQueueError: Error, LocalizedError {
    case queueFull(message: String)
    case storageFull(message: String)

    var errorDescription: String? {
        switch self {
        case .queueFull(let message): return message
        case .storageFull(let message): return message
        }
    }
}
```

### TTL for Stale Operations

Operations older than a threshold should be discarded:

```swift
func pruneStale(olderThan ttl: TimeInterval = 24 * 3600) async {
    let cutoff = Date().addingTimeInterval(-ttl)
    let stale = queue.filter { $0.createdAt < cutoff }

    for operation in stale {
        queue.removeAll { $0.id == operation.id }
        await persistence.delete(operation.id)
    }

    if !stale.isEmpty {
        // Notify user that stale operations were discarded
        NotificationCenter.default.post(
            name: .offlineQueuePruned,
            object: nil,
            userInfo: ["count": stale.count]
        )
    }
}

extension Notification.Name {
    static let offlineQueuePruned = Notification.Name("offlineQueuePruned")
}
```

### Pruning Strategy

| Strategy | When | Action |
|----------|------|--------|
| TTL expiration | On app launch, periodically | Remove operations older than 24h |
| Size-based | Before enqueue | Reject if queue > 500 items or > 50 MB |
| Priority-based | When queue is full | Remove lowest-priority pending operations first |
| Tag-based | On user action | Clear all operations with a specific tag |

## Testing Offline Scenarios

### Mock NetworkMonitor

```swift
/// Testable network monitor that doesn't use NWPathMonitor.
@Observable
final class MockNetworkMonitor: @unchecked Sendable {
    var isConnected: Bool
    var connectionType: ConnectionType
    var isExpensive: Bool
    var isConstrained: Bool

    init(
        isConnected: Bool = true,
        connectionType: ConnectionType = .wifi,
        isExpensive: Bool = false,
        isConstrained: Bool = false
    ) {
        self.isConnected = isConnected
        self.connectionType = connectionType
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }

    /// Simulate a connectivity change for testing.
    func simulateConnectivityChange(isConnected: Bool) {
        self.isConnected = isConnected
        self.connectionType = isConnected ? .wifi : .none
    }
}
```

### Mock Persistence

```swift
/// In-memory persistence for unit tests.
actor MockQueuePersistence: QueuePersisting {
    private var operations: [UUID: OfflineOperation] = [:]

    func loadAll() async -> [OfflineOperation] {
        Array(operations.values).sorted { $0.createdAt < $1.createdAt }
    }

    func save(_ operation: OfflineOperation) async {
        operations[operation.id] = operation
    }

    func delete(_ id: UUID) async {
        operations.removeValue(forKey: id)
    }

    func deleteAll() async {
        operations.removeAll()
    }
}
```

### Mock Operation Executor

```swift
/// Mock executor that records executed operations for assertions.
actor MockOperationExecutor: OfflineOperationExecuting {
    var executedOperations: [OfflineOperation] = []
    var resultToReturn: OfflineExecutionResult = .success
    var shouldThrow = false

    func execute(_ operation: OfflineOperation) async throws -> OfflineExecutionResult {
        executedOperations.append(operation)
        if shouldThrow {
            throw URLError(.notConnectedToInternet)
        }
        return resultToReturn
    }
}
```

### Network Link Conditioner

For manual testing on device or simulator:

1. **On device:** Settings > Developer > Network Link Conditioner
   - "100% Loss" — simulates complete offline
   - "Very Bad Network" — simulates intermittent connectivity
   - "Edge" — simulates slow cellular

2. **On Mac (for simulator):** Install "Network Link Conditioner" from Additional Tools for Xcode
   - System Settings > Network Link Conditioner
   - Create custom profiles for specific test scenarios

3. **In code (UI tests):**
```swift
// Toggle airplane mode via launch arguments
let app = XCUIApplication()
app.launchArguments.append("--simulate-offline")

// In your app:
#if DEBUG
if CommandLine.arguments.contains("--simulate-offline") {
    // Use MockNetworkMonitor with isConnected = false
}
#endif
```

### Integration Test Pattern

```swift
@Test
func fullOfflineOnlineRoundTrip() async throws {
    // Setup
    let persistence = MockQueuePersistence()
    let monitor = MockNetworkMonitor(isConnected: false)
    let executor = MockOperationExecutor()
    let manager = OfflineQueueManager(
        persistence: persistence,
        monitor: monitor,
        executor: executor
    )
    await manager.start()

    // 1. Enqueue while offline
    let op1 = OfflineOperation(endpoint: "/api/posts", httpMethod: .post, body: Data("{}".utf8))
    let op2 = OfflineOperation(endpoint: "/api/comments", httpMethod: .post, body: Data("{}".utf8))
    await manager.enqueue(op1)
    await manager.enqueue(op2)

    // Verify queued
    #expect(await manager.pendingCount == 2)
    #expect(await executor.executedOperations.isEmpty)

    // 2. Come back online
    monitor.simulateConnectivityChange(isConnected: true)
    await manager.processQueue()

    // 3. Verify processed
    #expect(await executor.executedOperations.count == 2)
    #expect(await manager.pendingCount == 0)

    // 4. Verify persistence cleaned up
    let remaining = await persistence.loadAll()
    #expect(remaining.isEmpty)
}

@Test
func retryWithBackoffOnFailure() async throws {
    let persistence = MockQueuePersistence()
    let monitor = MockNetworkMonitor(isConnected: true)
    let executor = MockOperationExecutor()
    executor.resultToReturn = .retryable(error: URLError(.timedOut))

    let policy = RetryPolicy(maxRetries: 2, baseDelay: 0.1, maxDelay: 0.5, jitterEnabled: false)
    let manager = OfflineQueueManager(
        persistence: persistence,
        monitor: monitor,
        executor: executor,
        retryPolicy: policy
    )

    let operation = OfflineOperation(
        endpoint: "/api/posts",
        httpMethod: .post,
        maxRetries: 2
    )
    await manager.enqueue(operation)

    // Wait for retries to exhaust
    try await Task.sleep(for: .seconds(2))

    // Should have attempted multiple times then marked as failed
    let operations = await persistence.loadAll()
    #expect(operations.first?.status == .failed)
}
```

## Anti-Patterns to Avoid

### Don't Queue GET Requests

```swift
// ❌ Don't queue reads — cache them instead
if !networkMonitor.isConnected {
    queueManager.enqueue(OfflineOperation(endpoint: "/api/feed", httpMethod: .get))
}

// ✅ Use HTTP cache or local store for reads
if !networkMonitor.isConnected {
    return try localStore.loadCachedFeed()
}
```

### Don't Ignore Operation Size

```swift
// ❌ Queue a 100 MB video upload as a normal operation
let operation = OfflineOperation(
    endpoint: "/api/uploads",
    httpMethod: .post,
    body: videoData  // 100 MB in memory!
)

// ✅ Save large files to disk, queue a reference
let fileURL = try saveToDisk(videoData)
let operation = OfflineOperation(
    endpoint: "/api/uploads",
    httpMethod: .post,
    body: try JSONEncoder().encode(["fileRef": fileURL.path])
)
// Use BackgroundUploadManager for the actual transfer
```

### Don't Retry Without Idempotency

```swift
// ❌ Retry a payment without idempotency key
// Could charge the user twice!
try await apiClient.post("/api/payments", body: paymentData)

// ✅ Always include idempotency key for mutations
var request = URLRequest(url: paymentsURL)
request.setValue(operation.idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
```

### Don't Process Queue Immediately on Every Connectivity Change

```swift
// ❌ Wifi drops and reconnects rapidly → queue processes 10 times in 30 seconds
pathMonitor.pathUpdateHandler = { path in
    if path.status == .satisfied {
        Task { await queueManager.processQueue() }
    }
}

// ✅ Debounce connectivity changes
pathMonitor.pathUpdateHandler = { [weak self] path in
    self?.connectivityDebounceTask?.cancel()
    self?.connectivityDebounceTask = Task {
        try await Task.sleep(for: .seconds(2))  // Wait for stable connection
        guard !Task.isCancelled else { return }
        if path.status == .satisfied {
            await self?.queueManager.processQueue()
        }
    }
}
```

### Don't Store Auth Tokens in Queued Operations

```swift
// ❌ Token may expire by the time operation executes
let operation = OfflineOperation(
    endpoint: "/api/posts",
    headers: ["Authorization": "Bearer \(currentToken)"]  // Stale in 1 hour
)

// ✅ Inject fresh token at execution time
func execute(_ operation: OfflineOperation) async throws -> OfflineExecutionResult {
    var request = buildRequest(from: operation)
    // Add fresh auth token at execution time
    let token = try await authManager.validToken()
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    // ...
}
```
