# Offline Queue Code Templates

Production-ready Swift templates for an offline operation queue. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency with the Network framework.

## OfflineOperation.swift

```swift
import Foundation

/// The HTTP method for an offline operation.
enum OfflineHTTPMethod: String, Codable, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// The current status of an offline operation in the queue.
enum OfflineOperationStatus: String, Codable, Sendable {
    case pending
    case inProgress
    case completed
    case failed
    case conflict
}

/// The priority level for queue processing order.
enum OfflineOperationPriority: Int, Codable, Sendable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A single offline operation that can be persisted and replayed.
///
/// Each operation captures everything needed to replay an API request:
/// endpoint, method, body, headers, and metadata for retry logic.
///
/// Usage:
/// ```swift
/// let operation = OfflineOperation(
///     endpoint: "/api/posts",
///     httpMethod: .post,
///     body: try JSONEncoder().encode(post),
///     headers: ["Content-Type": "application/json"]
/// )
/// ```
struct OfflineOperation: Codable, Identifiable, Sendable {
    /// Unique identifier for this operation.
    let id: UUID

    /// The API endpoint path (e.g., "/api/posts").
    let endpoint: String

    /// The HTTP method for this request.
    let httpMethod: OfflineHTTPMethod

    /// The request body data, if any.
    let body: Data?

    /// HTTP headers to include with the request.
    var headers: [String: String]

    /// When this operation was created.
    let createdAt: Date

    /// Number of retry attempts so far.
    var retryCount: Int

    /// Maximum number of retries before marking as failed.
    let maxRetries: Int

    /// Unique key for server-side deduplication.
    ///
    /// The server should use this key to detect and reject duplicate
    /// requests if the client retries an operation that actually succeeded
    /// but whose response was lost.
    let idempotencyKey: String

    /// Current processing status.
    var status: OfflineOperationStatus

    /// Processing priority. Higher priority operations are processed first.
    let priority: OfflineOperationPriority

    /// Optional ID of an operation that must complete before this one.
    ///
    /// Use for ordered operations like "create parent before child".
    let dependsOn: UUID?

    /// Optional tag for grouping related operations (e.g., "sync-posts").
    let tag: String?

    /// Timestamp of the last retry attempt, if any.
    var lastAttemptAt: Date?

    /// Error message from the most recent failed attempt.
    var lastError: String?

    /// Server response data when a conflict (409) occurs.
    var conflictData: Data?

    init(
        id: UUID = UUID(),
        endpoint: String,
        httpMethod: OfflineHTTPMethod,
        body: Data? = nil,
        headers: [String: String] = [:],
        createdAt: Date = Date(),
        retryCount: Int = 0,
        maxRetries: Int = 5,
        idempotencyKey: String = UUID().uuidString,
        status: OfflineOperationStatus = .pending,
        priority: OfflineOperationPriority = .normal,
        dependsOn: UUID? = nil,
        tag: String? = nil
    ) {
        self.id = id
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.body = body
        self.headers = headers
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.maxRetries = maxRetries
        self.idempotencyKey = idempotencyKey
        self.status = status
        self.priority = priority
        self.dependsOn = dependsOn
        self.tag = tag
    }
}
```

## OfflineQueueManager.swift

```swift
import Foundation

/// Protocol for executing offline operations against the server.
///
/// Implement this protocol to connect the queue to your networking layer.
protocol OfflineOperationExecuting: Sendable {
    /// Execute a single operation. Throws on failure.
    func execute(_ operation: OfflineOperation) async throws -> OfflineExecutionResult
}

/// The result of executing an offline operation.
enum OfflineExecutionResult: Sendable {
    /// Operation succeeded.
    case success
    /// Server returned a conflict (409). Includes server data for resolution.
    case conflict(serverData: Data)
    /// Operation failed but can be retried.
    case retryable(error: Error)
    /// Operation failed permanently (e.g., 400 Bad Request). Do not retry.
    case permanent(error: Error)
}

/// Actor-based manager for the offline operation queue.
///
/// Enqueues operations when offline, persists them to disk,
/// and processes them with exponential backoff when connectivity returns.
///
/// Usage:
/// ```swift
/// let manager = OfflineQueueManager(
///     persistence: FileQueuePersistence(),
///     monitor: NetworkMonitor.shared,
///     executor: APIOperationExecutor()
/// )
/// await manager.enqueue(operation)
/// ```
actor OfflineQueueManager {
    private let persistence: any QueuePersisting
    private let monitor: NetworkMonitor
    private let executor: any OfflineOperationExecuting
    private let retryPolicy: RetryPolicy

    private var queue: [OfflineOperation] = []
    private var isProcessing = false
    private var connectivityTask: Task<Void, Never>?

    /// Number of pending operations in the queue.
    var pendingCount: Int {
        queue.filter { $0.status == .pending }.count
    }

    /// Number of failed operations in the queue.
    var failedCount: Int {
        queue.filter { $0.status == .failed }.count
    }

    /// Number of operations with conflicts awaiting resolution.
    var conflictCount: Int {
        queue.filter { $0.status == .conflict }.count
    }

    /// All operations currently in the queue.
    var allOperations: [OfflineOperation] {
        queue
    }

    init(
        persistence: any QueuePersisting,
        monitor: NetworkMonitor,
        executor: any OfflineOperationExecuting,
        retryPolicy: RetryPolicy = RetryPolicy()
    ) {
        self.persistence = persistence
        self.monitor = monitor
        self.executor = executor
        self.retryPolicy = retryPolicy
    }

    /// Start the queue manager: load persisted operations and observe connectivity.
    func start() async {
        queue = await persistence.loadAll()
        observeConnectivity()

        // If already online and there are pending operations, process them
        if monitor.isConnected && !queue.isEmpty {
            await processQueue()
        }
    }

    /// Add an operation to the queue and persist it.
    func enqueue(_ operation: OfflineOperation) async {
        queue.append(operation)
        sortQueue()
        await persistence.save(operation)

        // If online, try processing immediately
        if monitor.isConnected && !isProcessing {
            await processQueue()
        }
    }

    /// Process all pending operations in order.
    ///
    /// Respects priority ordering and operation dependencies.
    /// Uses exponential backoff between retries.
    func processQueue() async {
        guard !isProcessing else { return }
        isProcessing = true

        defer { isProcessing = false }

        while let operation = nextOperationToProcess() {
            guard monitor.isConnected else { break }

            var mutableOp = operation
            mutableOp.status = .inProgress
            mutableOp.lastAttemptAt = Date()
            updateOperation(mutableOp)

            do {
                let result = try await executor.execute(mutableOp)

                switch result {
                case .success:
                    await markCompleted(mutableOp)

                case .conflict(let serverData):
                    mutableOp.status = .conflict
                    mutableOp.conflictData = serverData
                    updateOperation(mutableOp)
                    await persistence.save(mutableOp)

                case .retryable(let error):
                    await handleRetryableFailure(&mutableOp, error: error)

                case .permanent(let error):
                    mutableOp.status = .failed
                    mutableOp.lastError = error.localizedDescription
                    updateOperation(mutableOp)
                    await persistence.save(mutableOp)
                }
            } catch {
                await handleRetryableFailure(&mutableOp, error: error)
            }
        }
    }

    /// Mark an operation as completed and remove it from the queue.
    func markCompleted(_ operation: OfflineOperation) async {
        queue.removeAll { $0.id == operation.id }
        await persistence.delete(operation.id)
    }

    /// Retry a specific failed or conflicted operation.
    func retry(_ operation: OfflineOperation) async {
        guard let index = queue.firstIndex(where: { $0.id == operation.id }) else { return }
        queue[index].status = .pending
        queue[index].retryCount = 0
        queue[index].lastError = nil
        queue[index].conflictData = nil
        await persistence.save(queue[index])

        if monitor.isConnected && !isProcessing {
            await processQueue()
        }
    }

    /// Remove all failed operations from the queue.
    func clearFailed() async {
        let failedIDs = queue.filter { $0.status == .failed }.map(\.id)
        queue.removeAll { $0.status == .failed }
        for id in failedIDs {
            await persistence.delete(id)
        }
    }

    /// Remove all operations from the queue.
    func clearAll() async {
        let allIDs = queue.map(\.id)
        queue.removeAll()
        for id in allIDs {
            await persistence.delete(id)
        }
    }

    /// Remove operations older than the given TTL.
    func pruneStale(olderThan ttl: TimeInterval = 24 * 3600) async {
        let cutoff = Date().addingTimeInterval(-ttl)
        let staleIDs = queue.filter { $0.createdAt < cutoff }.map(\.id)
        queue.removeAll { $0.createdAt < cutoff }
        for id in staleIDs {
            await persistence.delete(id)
        }
    }

    // MARK: - Private

    private func observeConnectivity() {
        connectivityTask?.cancel()
        connectivityTask = Task { [weak self] in
            // Poll for connectivity changes
            var wasConnected = false
            while !Task.isCancelled {
                guard let self else { return }
                let isConnected = await MainActor.run { self.monitor.isConnected }

                if isConnected && !wasConnected {
                    // Just came online — process the queue
                    await self.processQueue()
                }
                wasConnected = isConnected
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private func nextOperationToProcess() -> OfflineOperation? {
        // Find next pending operation whose dependencies are met
        let completedIDs = Set(queue.filter { $0.status == .completed }.map(\.id))

        return queue.first { op in
            guard op.status == .pending else { return false }
            if let dependency = op.dependsOn {
                // Dependency must be completed (not just in the queue)
                return completedIDs.contains(dependency) ||
                       !queue.contains(where: { $0.id == dependency })
            }
            return true
        }
    }

    private func handleRetryableFailure(_ operation: inout OfflineOperation, error: Error) async {
        operation.retryCount += 1
        operation.lastError = error.localizedDescription

        if operation.retryCount >= operation.maxRetries {
            operation.status = .failed
        } else {
            operation.status = .pending
            // Apply backoff delay before next attempt
            let delay = retryPolicy.delay(forAttempt: operation.retryCount)
            try? await Task.sleep(for: .seconds(delay))
        }

        updateOperation(operation)
        await persistence.save(operation)
    }

    private func updateOperation(_ operation: OfflineOperation) {
        if let index = queue.firstIndex(where: { $0.id == operation.id }) {
            queue[index] = operation
        }
    }

    private func sortQueue() {
        queue.sort { a, b in
            if a.priority != b.priority {
                return a.priority > b.priority  // Higher priority first
            }
            return a.createdAt < b.createdAt  // FIFO within same priority
        }
    }
}
```

## QueuePersistence.swift

```swift
import Foundation

/// Protocol for persisting offline operations to durable storage.
///
/// Implementations must be sendable for use with actor-based queue manager.
protocol QueuePersisting: Sendable {
    /// Load all persisted operations.
    func loadAll() async -> [OfflineOperation]
    /// Save or update a single operation.
    func save(_ operation: OfflineOperation) async
    /// Delete an operation by ID.
    func delete(_ id: UUID) async
    /// Delete all persisted operations.
    func deleteAll() async
}

/// File-based persistence using JSON files in Application Support.
///
/// Each operation is stored as a separate JSON file, named by its UUID.
/// This approach avoids corruption from concurrent writes and makes
/// individual operation management straightforward.
///
/// Storage location:
/// ```
/// ApplicationSupport/
/// └── OfflineQueue/
///     ├── 550e8400-e29b-41d4-a716-446655440000.json
///     ├── 6ba7b810-9dad-11d1-80b4-00c04fd430c8.json
///     └── ...
/// ```
final class FileQueuePersistence: QueuePersisting, @unchecked Sendable {
    private let directory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default
    private let ioQueue = DispatchQueue(label: "com.app.offlinequeue.persistence", qos: .utility)

    init(directoryName: String = "OfflineQueue") {
        self.directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directoryName, isDirectory: true)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadAll() async -> [OfflineOperation] {
        await withCheckedContinuation { continuation in
            ioQueue.async { [self] in
                guard let files = try? fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                ) else {
                    continuation.resume(returning: [])
                    return
                }

                let operations = files
                    .filter { $0.pathExtension == "json" }
                    .compactMap { url -> OfflineOperation? in
                        guard let data = try? Data(contentsOf: url) else { return nil }
                        return try? decoder.decode(OfflineOperation.self, from: data)
                    }
                    .sorted { a, b in
                        if a.priority != b.priority {
                            return a.priority > b.priority
                        }
                        return a.createdAt < b.createdAt
                    }

                continuation.resume(returning: operations)
            }
        }
    }

    func save(_ operation: OfflineOperation) async {
        await withCheckedContinuation { continuation in
            ioQueue.async { [self] in
                let fileURL = directory.appendingPathComponent("\(operation.id.uuidString).json")
                if let data = try? encoder.encode(operation) {
                    try? data.write(to: fileURL, options: .atomic)
                }
                continuation.resume()
            }
        }
    }

    func delete(_ id: UUID) async {
        await withCheckedContinuation { continuation in
            ioQueue.async { [self] in
                let fileURL = directory.appendingPathComponent("\(id.uuidString).json")
                try? fileManager.removeItem(at: fileURL)
                continuation.resume()
            }
        }
    }

    func deleteAll() async {
        await withCheckedContinuation { continuation in
            ioQueue.async { [self] in
                guard let files = try? fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                ) else {
                    continuation.resume()
                    return
                }

                for file in files where file.pathExtension == "json" {
                    try? fileManager.removeItem(at: file)
                }
                continuation.resume()
            }
        }
    }
}
```

## NetworkMonitor.swift

```swift
import Foundation
import Network

/// The type of network connection currently available.
enum ConnectionType: String, Sendable {
    case wifi
    case cellular
    case wiredEthernet
    case other
    case none
}

/// @Observable wrapper around NWPathMonitor for connectivity tracking.
///
/// Publishes `isConnected` and `connectionType` that SwiftUI views
/// and the queue manager can observe for reactivity.
///
/// Usage:
/// ```swift
/// let monitor = NetworkMonitor.shared
/// monitor.start()
///
/// if monitor.isConnected {
///     // Online
/// }
/// ```
@Observable
final class NetworkMonitor: @unchecked Sendable {
    static let shared = NetworkMonitor()

    /// Whether the device currently has network connectivity.
    private(set) var isConnected: Bool = true

    /// The type of the current network connection.
    private(set) var connectionType: ConnectionType = .other

    /// Whether the connection is considered expensive (cellular, hotspot).
    private(set) var isExpensive: Bool = false

    /// Whether the connection is constrained (Low Data Mode).
    private(set) var isConstrained: Bool = false

    private let pathMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.app.networkmonitor", qos: .utility)

    init() {
        pathMonitor = NWPathMonitor()
    }

    /// Start monitoring network connectivity.
    ///
    /// Call this once at app launch, typically in the App struct's init.
    func start() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained
                self.connectionType = self.resolveConnectionType(path)
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    /// Stop monitoring. Call when no longer needed.
    func stop() {
        pathMonitor.cancel()
    }

    // MARK: - Private

    private func resolveConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else if path.status == .satisfied {
            return .other
        } else {
            return .none
        }
    }
}

// For testing: allow injection via SwiftUI Environment
private struct NetworkMonitorKey: EnvironmentKey {
    static let defaultValue: NetworkMonitor = .shared
}

extension EnvironmentValues {
    var networkMonitor: NetworkMonitor {
        get { self[NetworkMonitorKey.self] }
        set { self[NetworkMonitorKey.self] = newValue }
    }
}
```

## RetryPolicy.swift

```swift
import Foundation

/// Configurable retry policy with exponential backoff and jitter.
///
/// Calculates the delay before the next retry attempt based on
/// the attempt number, a base delay, a multiplier, and optional
/// random jitter to prevent thundering herd problems.
///
/// Default configuration:
/// - Attempt 0: ~1s
/// - Attempt 1: ~2s
/// - Attempt 2: ~4s
/// - Attempt 3: ~8s
/// - Attempt 4: ~16s (capped at maxDelay)
///
/// Usage:
/// ```swift
/// let policy = RetryPolicy(maxRetries: 5, baseDelay: 1.0, maxDelay: 60.0)
/// let delay = policy.delay(forAttempt: 2)  // ~4 seconds + jitter
/// ```
struct RetryPolicy: Sendable {
    /// Maximum number of retry attempts before giving up.
    let maxRetries: Int

    /// Base delay in seconds for the first retry.
    let baseDelay: TimeInterval

    /// Maximum delay in seconds (cap for exponential growth).
    let maxDelay: TimeInterval

    /// Multiplier applied per retry attempt (2.0 = double each time).
    let multiplier: Double

    /// Whether to add random jitter to prevent thundering herd.
    let jitterEnabled: Bool

    init(
        maxRetries: Int = 5,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        multiplier: Double = 2.0,
        jitterEnabled: Bool = true
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.multiplier = multiplier
        self.jitterEnabled = jitterEnabled
    }

    /// Calculate the delay for the given retry attempt number.
    ///
    /// - Parameter attempt: The retry attempt number (0-based).
    /// - Returns: The delay in seconds before the next retry.
    func delay(forAttempt attempt: Int) -> TimeInterval {
        // Exponential: baseDelay * multiplier^attempt
        let exponentialDelay = baseDelay * pow(multiplier, Double(attempt))
        let cappedDelay = min(exponentialDelay, maxDelay)

        if jitterEnabled {
            // Full jitter: random value between 0 and cappedDelay
            // This distributes retries evenly and prevents thundering herd
            let jitter = Double.random(in: 0...1)
            return cappedDelay * jitter + (cappedDelay * 0.5)  // Between 50%-150% of delay
        }

        return cappedDelay
    }

    /// Whether the given attempt number has exceeded the maximum retries.
    func shouldGiveUp(attempt: Int) -> Bool {
        attempt >= maxRetries
    }

    // MARK: - Preset Configurations

    /// Aggressive retry: short delays, many attempts.
    static let aggressive = RetryPolicy(
        maxRetries: 10,
        baseDelay: 0.5,
        maxDelay: 30.0,
        multiplier: 1.5
    )

    /// Conservative retry: longer delays, fewer attempts.
    static let conservative = RetryPolicy(
        maxRetries: 3,
        baseDelay: 5.0,
        maxDelay: 120.0,
        multiplier: 3.0
    )

    /// Linear retry: fixed interval between attempts.
    static func linear(interval: TimeInterval = 5.0, maxRetries: Int = 5) -> RetryPolicy {
        RetryPolicy(
            maxRetries: maxRetries,
            baseDelay: interval,
            maxDelay: interval,
            multiplier: 1.0,
            jitterEnabled: false
        )
    }

    /// Immediate retry: no delay (useful for quick transient failures).
    static let immediate = RetryPolicy(
        maxRetries: 3,
        baseDelay: 0.1,
        maxDelay: 0.1,
        multiplier: 1.0,
        jitterEnabled: false
    )
}
```

## OfflineQueueDashboardView.swift

```swift
import SwiftUI

/// Debug dashboard showing the state of the offline operation queue.
///
/// Displays counts of pending, in-progress, failed, and conflicted operations.
/// Provides manual retry and clear controls for debugging.
///
/// Usage:
/// ```swift
/// #if DEBUG
/// NavigationLink("Offline Queue") {
///     OfflineQueueDashboardView()
/// }
/// #endif
/// ```
struct OfflineQueueDashboardView: View {
    let queueManager: OfflineQueueManager

    @Environment(\.networkMonitor) private var networkMonitor
    @State private var operations: [OfflineOperation] = []
    @State private var pendingCount = 0
    @State private var failedCount = 0
    @State private var conflictCount = 0
    @State private var isRefreshing = false

    var body: some View {
        List {
            statusSection
            countsSection
            actionsSection
            operationsSection
        }
        .navigationTitle("Offline Queue")
        .task {
            await refreshState()
        }
        .refreshable {
            await refreshState()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var statusSection: some View {
        Section("Connectivity") {
            HStack {
                Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                    .foregroundStyle(networkMonitor.isConnected ? .green : .red)
                Text(networkMonitor.isConnected ? "Online" : "Offline")
                Spacer()
                Text(networkMonitor.connectionType.rawValue.capitalized)
                    .foregroundStyle(.secondary)
            }

            if networkMonitor.isExpensive {
                Label("Expensive connection (cellular/hotspot)", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            if networkMonitor.isConstrained {
                Label("Low Data Mode active", systemImage: "arrow.down.circle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var countsSection: some View {
        Section("Queue Summary") {
            LabeledContent("Pending", value: "\(pendingCount)")
            LabeledContent("Failed", value: "\(failedCount)")
            LabeledContent("Conflicts", value: "\(conflictCount)")
            LabeledContent("Total", value: "\(operations.count)")
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        Section("Actions") {
            Button {
                Task {
                    await queueManager.processQueue()
                    await refreshState()
                }
            } label: {
                Label("Retry All Pending", systemImage: "arrow.clockwise")
            }
            .disabled(!networkMonitor.isConnected || pendingCount == 0)

            Button {
                Task {
                    await queueManager.clearFailed()
                    await refreshState()
                }
            } label: {
                Label("Clear Failed", systemImage: "trash")
            }
            .disabled(failedCount == 0)
            .foregroundStyle(.red)

            Button {
                Task {
                    await queueManager.pruneStale()
                    await refreshState()
                }
            } label: {
                Label("Prune Stale (>24h)", systemImage: "clock.badge.xmark")
            }

            Button(role: .destructive) {
                Task {
                    await queueManager.clearAll()
                    await refreshState()
                }
            } label: {
                Label("Clear All", systemImage: "trash.fill")
            }
        }
    }

    @ViewBuilder
    private var operationsSection: some View {
        if !operations.isEmpty {
            Section("Operations") {
                ForEach(operations) { operation in
                    OperationRowView(operation: operation) {
                        Task {
                            await queueManager.retry(operation)
                            await refreshState()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func refreshState() async {
        operations = await queueManager.allOperations
        pendingCount = await queueManager.pendingCount
        failedCount = await queueManager.failedCount
        conflictCount = await queueManager.conflictCount
    }
}

/// Row view for a single offline operation in the dashboard.
private struct OperationRowView: View {
    let operation: OfflineOperation
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                statusIcon
                Text(operation.httpMethod.rawValue)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text(operation.endpoint)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            HStack {
                Text(operation.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if operation.retryCount > 0 {
                    Text("Retries: \(operation.retryCount)/\(operation.maxRetries)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if operation.status == .failed || operation.status == .conflict {
                    Button("Retry", action: onRetry)
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                }
            }

            if let error = operation.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch operation.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.orange)
        case .inProgress:
            ProgressView()
                .controlSize(.mini)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .conflict:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
        }
    }
}
```

## OfflineQueueModifier.swift

```swift
import SwiftUI

/// ViewModifier that displays a subtle "Offline" banner when the device
/// loses connectivity and there are pending operations to sync.
///
/// Usage:
/// ```swift
/// ContentView()
///     .offlineQueueBanner()
/// ```
struct OfflineQueueBannerModifier: ViewModifier {
    @Environment(\.networkMonitor) private var networkMonitor

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if !networkMonitor.isConnected {
                    offlineBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }

    @ViewBuilder
    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.subheadline)
            Text("Offline — changes will sync when connected")
                .font(.subheadline)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.gradient)
        )
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
}

extension View {
    /// Adds a subtle offline banner at the bottom of the view when
    /// the device has no network connectivity.
    func offlineQueueBanner() -> some View {
        modifier(OfflineQueueBannerModifier())
    }
}
```
