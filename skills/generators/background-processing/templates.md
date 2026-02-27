# Background Processing Code Templates

Production-ready Swift templates for background processing infrastructure. All code targets iOS 16+ and uses modern Swift concurrency. BGTaskScheduler requires iOS 13+ but these templates use async/await patterns from iOS 16+.

## BackgroundTaskManager.swift

```swift
import Foundation
import BackgroundTasks
import os

/// Central manager for registering and scheduling all background tasks.
///
/// Handles BGAppRefreshTask (lightweight periodic updates) and
/// BGProcessingTask (long-running operations). Must be configured
/// at app launch before `didFinishLaunchingWithOptions` returns.
///
/// Usage:
/// ```swift
/// // In AppDelegate.didFinishLaunchingWithOptions:
/// BackgroundTaskManager.shared.registerTasks()
///
/// // When app enters background:
/// BackgroundTaskManager.shared.scheduleAppRefresh()
/// ```
final class BackgroundTaskManager: Sendable {
    static let shared = BackgroundTaskManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app",
        category: "BackgroundTask"
    )

    // MARK: - Task Identifiers

    /// All background task identifiers. These must match Info.plist
    /// BGTaskSchedulerPermittedIdentifiers entries exactly.
    enum TaskIdentifier: String, CaseIterable {
        case appRefresh = "com.app.refresh"
        case dataProcessing = "com.app.processing"
    }

    // MARK: - Registration

    /// Register all background tasks with the scheduler.
    ///
    /// **Must be called during `application(_:didFinishLaunchingWithOptions:)`**
    /// before it returns. Calling later causes silent registration failure.
    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.appRefresh.rawValue,
            using: nil
        ) { [self] task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleAppRefresh(refreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.dataProcessing.rawValue,
            using: nil
        ) { [self] task in
            guard let processingTask = task as? BGProcessingTask else { return }
            handleDataProcessing(processingTask)
        }

        logger.info("Background tasks registered")
    }

    // MARK: - Scheduling

    /// Schedule a lightweight app refresh task.
    ///
    /// The system decides the actual execution time based on user patterns,
    /// battery level, and network availability. `earliestBeginDate` is a hint.
    ///
    /// Call this when the app enters the background.
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(
            identifier: TaskIdentifier.appRefresh.rawValue
        )
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes minimum

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("App refresh scheduled")
        } catch {
            logger.error("Failed to schedule app refresh: \(error.localizedDescription)")
        }
    }

    /// Schedule a long-running processing task.
    ///
    /// Processing tasks can run for several minutes when the device is
    /// charging and on Wi-Fi. Use for database cleanup, ML model updates,
    /// or large data syncs.
    ///
    /// - Parameters:
    ///   - requiresNetwork: Whether the task needs network access.
    ///   - requiresPower: Whether the task should only run on external power.
    func scheduleProcessingTask(
        requiresNetwork: Bool = false,
        requiresPower: Bool = false
    ) {
        let request = BGProcessingTaskRequest(
            identifier: TaskIdentifier.dataProcessing.rawValue
        )
        request.requiresNetworkConnectivity = requiresNetwork
        request.requiresExternalPower = requiresPower
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour minimum

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Processing task scheduled (network: \(requiresNetwork), power: \(requiresPower))")
        } catch {
            logger.error("Failed to schedule processing task: \(error.localizedDescription)")
        }
    }

    // MARK: - Task Handlers

    /// Handle an app refresh task (~30 seconds of execution time).
    private func handleAppRefresh(_ task: BGAppRefreshTask) {
        logger.info("App refresh task started")

        // Schedule the next refresh immediately
        scheduleAppRefresh()

        let refreshOperation = Task {
            do {
                try await performAppRefresh()
                task.setTaskCompleted(success: true)
                logger.info("App refresh completed successfully")
            } catch {
                task.setTaskCompleted(success: false)
                logger.error("App refresh failed: \(error.localizedDescription)")
            }
        }

        // Handle expiration: cancel the work and mark complete
        task.expirationHandler = {
            refreshOperation.cancel()
        }
    }

    /// Handle a processing task (several minutes of execution time).
    private func handleDataProcessing(_ task: BGProcessingTask) {
        logger.info("Data processing task started")

        let processingOperation = Task {
            do {
                try await performDataProcessing()
                task.setTaskCompleted(success: true)
                logger.info("Data processing completed successfully")
            } catch {
                task.setTaskCompleted(success: false)
                logger.error("Data processing failed: \(error.localizedDescription)")
            }
        }

        // Handle expiration: save progress and mark incomplete
        task.expirationHandler = {
            processingOperation.cancel()
            // The task will be rescheduled automatically
        }
    }

    // MARK: - Work Implementation

    /// Perform the lightweight refresh work.
    ///
    /// Replace this with your actual refresh logic:
    /// - Fetch new content from API
    /// - Update local cache
    /// - Refresh widget timelines
    private func performAppRefresh() async throws {
        // TODO: Replace with actual refresh logic
        // Example:
        // let newContent = try await apiClient.fetchLatestContent()
        // try await contentStore.update(with: newContent)
        // WidgetCenter.shared.reloadAllTimelines()
    }

    /// Perform long-running processing work.
    ///
    /// Replace this with your actual processing logic:
    /// - Database cleanup and optimization
    /// - ML model updates
    /// - Large data synchronization
    /// - Cache pruning
    private func performDataProcessing() async throws {
        // TODO: Replace with actual processing logic
        // Example:
        // try await database.vacuum()
        // try await cacheManager.pruneExpired()
        // try await syncManager.fullSync()
    }
}
```

## BackgroundTaskConfiguration.swift

```swift
import Foundation

/// Background task configuration constants and Info.plist documentation.
///
/// ## Required Info.plist Keys
///
/// Add to your app's Info.plist:
/// ```xml
/// <key>BGTaskSchedulerPermittedIdentifiers</key>
/// <array>
///     <string>com.app.refresh</string>
///     <string>com.app.processing</string>
/// </array>
/// ```
///
/// ## Required Background Modes
///
/// In Xcode, add these under Target > Signing & Capabilities > Background Modes:
/// - **Background fetch** — enables BGAppRefreshTask
/// - **Background processing** — enables BGProcessingTask
///
/// These add to Info.plist:
/// ```xml
/// <key>UIBackgroundModes</key>
/// <array>
///     <string>fetch</string>
///     <string>processing</string>
/// </array>
/// ```
///
/// ## Xcode Debugger Commands
///
/// Simulate a background task launch:
/// ```
/// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.app.refresh"]
/// ```
///
/// Simulate task expiration:
/// ```
/// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.app.refresh"]
/// ```
enum BackgroundTaskConfiguration {

    /// All permitted task identifiers.
    /// Must match BGTaskSchedulerPermittedIdentifiers in Info.plist.
    static let permittedIdentifiers: [String] = [
        BackgroundTaskManager.TaskIdentifier.appRefresh.rawValue,
        BackgroundTaskManager.TaskIdentifier.dataProcessing.rawValue,
    ]

    /// Minimum interval between app refresh schedules.
    static let refreshMinimumInterval: TimeInterval = 15 * 60 // 15 minutes

    /// Minimum interval between processing task schedules.
    static let processingMinimumInterval: TimeInterval = 60 * 60 // 1 hour

    /// Info.plist keys required for background task support.
    enum InfoPlistKeys {
        /// Array of permitted task identifier strings.
        static let schedulerPermittedIdentifiers = "BGTaskSchedulerPermittedIdentifiers"

        /// Array of background mode strings.
        static let backgroundModes = "UIBackgroundModes"

        /// Background mode values.
        enum BackgroundMode: String {
            case fetch = "fetch"
            case processing = "processing"
            case remoteNotification = "remote-notification"
        }
    }
}
```

## BackgroundDownloadManager.swift

```swift
import Foundation
import os

/// Protocol for handling background download completion events.
///
/// Implement this to process downloaded files, update UI, or trigger
/// further operations when a background download finishes.
protocol BackgroundDownloadDelegate: AnyObject, Sendable {
    /// Called when a download completes successfully.
    /// The file at `location` is temporary and must be moved before returning.
    func downloadDidComplete(taskIdentifier: Int, location: URL)

    /// Called when a download fails.
    func downloadDidFail(taskIdentifier: Int, error: Error)

    /// Called when download progress updates.
    func downloadDidProgress(taskIdentifier: Int, progress: Double)
}

/// Manages background URLSession downloads that survive app termination.
///
/// Downloads initiated through this manager continue even when the app
/// is suspended or terminated. When the download completes, the system
/// relaunches the app and delivers the file via delegate callbacks.
///
/// ## Setup Requirements
///
/// In AppDelegate, implement:
/// ```swift
/// func application(
///     _ application: UIApplication,
///     handleEventsForBackgroundURLSession identifier: String,
///     completionHandler: @escaping () -> Void
/// ) {
///     BackgroundDownloadManager.shared.setCompletionHandler(completionHandler, for: identifier)
/// }
/// ```
///
/// ## Usage
///
/// ```swift
/// BackgroundDownloadManager.shared.startDownload(from: assetURL)
/// ```
final class BackgroundDownloadManager: NSObject, @unchecked Sendable {
    static let shared = BackgroundDownloadManager()

    /// The background session identifier. Must be unique per app and consistent
    /// across launches so the system can reconnect completed downloads.
    static let sessionIdentifier = "com.app.background-download"

    weak var delegate: BackgroundDownloadDelegate?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app",
        category: "BackgroundDownload"
    )

    /// Completion handler provided by the system when the app is woken
    /// for background session events. Must be called after all events
    /// are delivered.
    private var backgroundCompletionHandler: (() -> Void)?

    /// Active download tasks keyed by task identifier.
    private var activeDownloads: [Int: URL] = [:]

    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(
            withIdentifier: Self.sessionIdentifier
        )
        config.isDiscretionary = false // Set to true for non-urgent downloads
        config.sessionSendsLaunchEvents = true // Wake app on completion
        config.allowsCellularAccess = true
        config.timeoutIntervalForResource = 60 * 60 * 24 // 24 hours

        // For energy-efficient non-urgent downloads:
        // config.isDiscretionary = true
        // config.allowsExpensiveNetworkAccess = false
        // config.allowsConstrainedNetworkAccess = false

        return URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil
        )
    }()

    // MARK: - Public API

    /// Start a background download from the given URL.
    ///
    /// The download continues even if the app is suspended or terminated.
    /// Implement `BackgroundDownloadDelegate` to handle completion.
    ///
    /// - Parameter url: The remote URL to download.
    /// - Returns: The URLSessionDownloadTask identifier for tracking.
    @discardableResult
    func startDownload(from url: URL) -> Int {
        let task = backgroundSession.downloadTask(with: url)
        activeDownloads[task.taskIdentifier] = url
        task.resume()

        logger.info("Started background download: \(url.lastPathComponent)")
        return task.taskIdentifier
    }

    /// Start a background download with a custom URLRequest.
    ///
    /// Use this when you need custom headers (e.g., authentication).
    @discardableResult
    func startDownload(with request: URLRequest) -> Int {
        let task = backgroundSession.downloadTask(with: request)
        if let url = request.url {
            activeDownloads[task.taskIdentifier] = url
        }
        task.resume()

        logger.info("Started background download with custom request")
        return task.taskIdentifier
    }

    /// Set the system-provided completion handler for background session events.
    ///
    /// Call this from `application(_:handleEventsForBackgroundURLSession:completionHandler:)`.
    func setCompletionHandler(_ handler: @escaping () -> Void, for identifier: String) {
        guard identifier == Self.sessionIdentifier else { return }
        backgroundCompletionHandler = handler
    }

    /// Cancel all active background downloads.
    func cancelAll() {
        backgroundSession.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        activeDownloads.removeAll()
    }

    // MARK: - File Management

    /// Default download destination directory.
    ///
    /// Override this to customize where downloaded files are stored.
    var downloadDirectory: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Downloads", isDirectory: true)
    }

    /// Move the downloaded temporary file to the permanent download directory.
    private func moveToDownloads(from tempLocation: URL, originalURL: URL) -> URL? {
        let destinationDir = downloadDirectory
        try? FileManager.default.createDirectory(
            at: destinationDir,
            withIntermediateDirectories: true
        )

        let destinationURL = destinationDir.appendingPathComponent(originalURL.lastPathComponent)

        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)

        do {
            try FileManager.default.moveItem(at: tempLocation, to: destinationURL)
            return destinationURL
        } catch {
            logger.error("Failed to move download: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloadManager: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let taskID = downloadTask.taskIdentifier
        logger.info("Download completed for task \(taskID)")

        // Move file from temporary location before it is deleted
        if let originalURL = activeDownloads[taskID] ?? downloadTask.originalRequest?.url {
            if let permanentURL = moveToDownloads(from: location, originalURL: originalURL) {
                delegate?.downloadDidComplete(taskIdentifier: taskID, location: permanentURL)
            }
        }

        activeDownloads.removeValue(forKey: taskID)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        delegate?.downloadDidProgress(
            taskIdentifier: downloadTask.taskIdentifier,
            progress: progress
        )
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        if let error {
            logger.error("Download task \(task.taskIdentifier) failed: \(error.localizedDescription)")
            delegate?.downloadDidFail(taskIdentifier: task.taskIdentifier, error: error)
            activeDownloads.removeValue(forKey: task.taskIdentifier)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // All background session events have been delivered.
        // Call the system completion handler to update the app snapshot.
        Task { @MainActor in
            backgroundCompletionHandler?()
            backgroundCompletionHandler = nil
        }
    }
}

// MARK: - URLSessionDelegate

extension BackgroundDownloadManager: URLSessionDelegate {

    func urlSession(
        _ session: URLSession,
        didBecomeInvalidWithError error: (any Error)?
    ) {
        if let error {
            logger.error("Background session invalidated: \(error.localizedDescription)")
        }
    }
}
```

## SilentPushHandler.swift

```swift
import Foundation
import UIKit
import os

/// Protocol for performing work when a silent push notification arrives.
///
/// Implement this to define the actual background work triggered by
/// a silent push (e.g., fetching new content, syncing data).
protocol SilentPushWorker: Sendable {
    /// Perform background work triggered by a silent push.
    ///
    /// - Parameter userInfo: The notification payload dictionary.
    /// - Returns: The fetch result indicating what happened.
    func performWork(userInfo: [AnyHashable: Any]) async throws -> UIBackgroundFetchResult
}

/// Handles silent push notifications (content-available: 1) for
/// server-triggered background content updates.
///
/// Silent push notifications wake the app in the background when the
/// server has new content. The app gets approximately 30 seconds to
/// fetch data and update its state.
///
/// ## APNs Payload Format
///
/// ```json
/// {
///     "aps": {
///         "content-available": 1
///     },
///     "type": "content-update",
///     "contentId": "article-123"
/// }
/// ```
///
/// ## AppDelegate Integration
///
/// ```swift
/// func application(
///     _ application: UIApplication,
///     didReceiveRemoteNotification userInfo: [AnyHashable: Any]
/// ) async -> UIBackgroundFetchResult {
///     await SilentPushHandler.shared.handle(userInfo: userInfo)
/// }
/// ```
///
/// ## Required Configuration
///
/// 1. Enable "Remote notifications" in Background Modes capability
/// 2. APNs payload must include `"content-available": 1`
/// 3. APNs push type header must be `background` (not `alert`)
final class SilentPushHandler: Sendable {
    static let shared = SilentPushHandler()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app",
        category: "SilentPush"
    )

    /// Registered workers for specific push types.
    /// Key is the push type string, value is the worker that handles it.
    private let workers: [String: any SilentPushWorker]

    /// Default worker for untyped silent pushes.
    private let defaultWorker: (any SilentPushWorker)?

    init(
        workers: [String: any SilentPushWorker] = [:],
        defaultWorker: (any SilentPushWorker)? = nil
    ) {
        self.workers = workers
        self.defaultWorker = defaultWorker
    }

    // MARK: - Handle Silent Push

    /// Handle an incoming silent push notification.
    ///
    /// Routes the push to the appropriate worker based on the `type`
    /// field in the payload. Returns the fetch result for the system.
    ///
    /// - Parameter userInfo: The push notification payload.
    /// - Returns: The background fetch result.
    func handle(userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        logger.info("Silent push received")

        // Validate this is a silent push (content-available: 1)
        guard isSilentPush(userInfo) else {
            logger.warning("Received non-silent push in silent handler")
            return .noData
        }

        // Route to the appropriate worker
        let pushType = userInfo["type"] as? String

        do {
            if let pushType, let worker = workers[pushType] {
                logger.info("Routing silent push to worker for type: \(pushType)")
                return try await worker.performWork(userInfo: userInfo)
            } else if let defaultWorker {
                logger.info("Routing silent push to default worker")
                return try await defaultWorker.performWork(userInfo: userInfo)
            } else {
                logger.warning("No worker registered for push type: \(pushType ?? "nil")")
                return .noData
            }
        } catch {
            logger.error("Silent push handling failed: \(error.localizedDescription)")
            return .failed
        }
    }

    // MARK: - Validation

    /// Check whether the notification payload is a silent push.
    private func isSilentPush(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard let aps = userInfo["aps"] as? [String: Any] else { return false }
        guard let contentAvailable = aps["content-available"] as? Int else { return false }
        return contentAvailable == 1
    }
}

// MARK: - Example Workers

/// Example worker that fetches new content when triggered by a silent push.
///
/// Replace with your actual content fetching logic.
///
/// ```swift
/// let handler = SilentPushHandler(
///     workers: ["content-update": ContentUpdateWorker()],
///     defaultWorker: ContentUpdateWorker()
/// )
/// ```
struct ContentUpdateWorker: SilentPushWorker {
    func performWork(userInfo: [AnyHashable: Any]) async throws -> UIBackgroundFetchResult {
        // Extract content ID from payload
        guard let contentId = userInfo["contentId"] as? String else {
            return .noData
        }

        // TODO: Replace with actual content fetching
        // let content = try await apiClient.fetchContent(id: contentId)
        // try await contentStore.save(content)
        _ = contentId

        return .newData
    }
}
```
