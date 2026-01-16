# Push Notification Patterns

Best practices for implementing push notifications in iOS/macOS apps.

## Registration Flow

### Complete Registration Sequence

```swift
import UserNotifications
import UIKit

@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var deviceToken: String?

    private init() {}

    // MARK: - Authorization

    /// Request notification authorization.
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()

        let options: UNAuthorizationOptions = [
            .alert,
            .badge,
            .sound,
            .providesAppNotificationSettings  // iOS 15.4+
        ]

        let granted = try await center.requestAuthorization(options: options)

        // Update status
        authorizationStatus = try await center.notificationSettings().authorizationStatus

        return granted
    }

    /// Check current authorization status.
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        return authorizationStatus
    }

    // MARK: - Registration

    /// Register for remote notifications.
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Unregister from remote notifications.
    func unregisterForRemoteNotifications() {
        UIApplication.shared.unregisterForRemoteNotifications()
        deviceToken = nil
    }

    /// Handle successful registration.
    func didRegister(with deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        print("📱 Device token: \(token)")

        // Send to your server
        Task {
            await sendTokenToServer(token)
        }
    }

    /// Handle registration failure.
    func didFailToRegister(with error: Error) {
        print("❌ Failed to register: \(error.localizedDescription)")
    }

    private func sendTokenToServer(_ token: String) async {
        // TODO: Implement server token upload
        // await APIClient.shared.registerDeviceToken(token)
    }

    // MARK: - Badge Management

    /// Clear the app badge.
    func clearBadge() async {
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
    }

    /// Set badge count.
    func setBadge(_ count: Int) async {
        try? await UNUserNotificationCenter.current().setBadgeCount(count)
    }
}
```

## Notification Delegate

### Complete Implementation

```swift
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // MARK: - Foreground Notifications

    /// Called when notification arrives while app is in foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {

        let userInfo = notification.request.content.userInfo

        // Log or process the notification
        print("📬 Received notification in foreground: \(userInfo)")

        // Parse payload
        if let payload = NotificationPayload(userInfo: userInfo) {
            await handlePayload(payload, inForeground: true)
        }

        // Return presentation options
        // Customize based on notification type
        return [.banner, .sound, .badge, .list]
    }

    // MARK: - Notification Response

    /// Called when user interacts with notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {

        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        print("📬 User responded to notification: \(actionIdentifier)")

        // Handle based on action
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped notification
            if let payload = NotificationPayload(userInfo: userInfo) {
                await handlePayload(payload, inForeground: false)
            }

        case UNNotificationDismissActionIdentifier:
            // User dismissed notification
            break

        default:
            // Custom action
            await handleCustomAction(actionIdentifier, userInfo: userInfo)
        }
    }

    // MARK: - Settings

    /// Called when user wants to manage notification settings from the notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        // Open app's notification settings
        NotificationCenter.default.post(
            name: .openNotificationSettings,
            object: nil
        )
    }

    // MARK: - Handlers

    private func handlePayload(_ payload: NotificationPayload, inForeground: Bool) async {
        switch payload.type {
        case .message:
            // Navigate to message
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .navigateToMessage,
                    object: nil,
                    userInfo: ["messageId": payload.resourceId ?? ""]
                )
            }

        case .reminder:
            // Handle reminder
            break

        case .update:
            // Handle update notification
            break

        case .unknown:
            break
        }
    }

    private func handleCustomAction(_ identifier: String, userInfo: [AnyHashable: Any]) async {
        switch identifier {
        case "REPLY_ACTION":
            // Handle reply
            break

        case "MARK_READ_ACTION":
            // Mark as read
            break

        case "COMPLETE_ACTION":
            // Complete task
            break

        case "SNOOZE_ACTION":
            // Snooze reminder
            await scheduleSnooze(userInfo: userInfo)

        default:
            print("Unknown action: \(identifier)")
        }
    }

    private func scheduleSnooze(userInfo: [AnyHashable: Any]) async {
        // Re-schedule notification for later
        let content = UNMutableNotificationContent()
        content.title = userInfo["title"] as? String ?? "Reminder"
        content.body = userInfo["body"] as? String ?? ""
        content.sound = .default
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 15 * 60,  // 15 minutes
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openNotificationSettings = Notification.Name("openNotificationSettings")
    static let navigateToMessage = Notification.Name("navigateToMessage")
}
```

## Notification Categories

### Category Registration

```swift
import UserNotifications

enum NotificationCategories {

    // MARK: - Category Identifiers

    enum Identifier: String {
        case message = "MESSAGE_CATEGORY"
        case reminder = "REMINDER_CATEGORY"
        case update = "UPDATE_CATEGORY"
    }

    // MARK: - Action Identifiers

    enum Action: String {
        // Message actions
        case reply = "REPLY_ACTION"
        case markRead = "MARK_READ_ACTION"

        // Reminder actions
        case complete = "COMPLETE_ACTION"
        case snooze = "SNOOZE_ACTION"

        // Update actions
        case viewUpdate = "VIEW_UPDATE_ACTION"
        case dismiss = "DISMISS_ACTION"
    }

    // MARK: - Registration

    static func registerAll() {
        let categories: Set<UNNotificationCategory> = [
            messageCategory,
            reminderCategory,
            updateCategory
        ]

        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }

    // MARK: - Category Definitions

    private static var messageCategory: UNNotificationCategory {
        let replyAction = UNNotificationAction(
            identifier: Action.reply.rawValue,
            title: "Reply",
            options: [.foreground]
        )

        let markReadAction = UNNotificationAction(
            identifier: Action.markRead.rawValue,
            title: "Mark as Read",
            options: []
        )

        return UNNotificationCategory(
            identifier: Identifier.message.rawValue,
            actions: [replyAction, markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }

    private static var reminderCategory: UNNotificationCategory {
        let completeAction = UNNotificationAction(
            identifier: Action.complete.rawValue,
            title: "Complete",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: Action.snooze.rawValue,
            title: "Snooze 15 min",
            options: []
        )

        return UNNotificationCategory(
            identifier: Identifier.reminder.rawValue,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
    }

    private static var updateCategory: UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: Action.viewUpdate.rawValue,
            title: "View",
            options: [.foreground]
        )

        return UNNotificationCategory(
            identifier: Identifier.update.rawValue,
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )
    }
}
```

## Payload Parsing

### Type-Safe Payload

```swift
import Foundation

/// Parsed notification payload.
struct NotificationPayload {
    let type: NotificationType
    let title: String?
    let body: String?
    let resourceId: String?
    let deepLink: URL?
    let imageURL: URL?
    let extra: [String: Any]

    enum NotificationType: String {
        case message
        case reminder
        case update
        case unknown
    }

    init?(userInfo: [AnyHashable: Any]) {
        // Parse APS
        guard let aps = userInfo["aps"] as? [String: Any] else {
            return nil
        }

        // Parse alert
        if let alert = aps["alert"] as? [String: Any] {
            title = alert["title"] as? String
            body = alert["body"] as? String
        } else if let alert = aps["alert"] as? String {
            title = nil
            body = alert
        } else {
            title = nil
            body = nil
        }

        // Parse custom fields
        let typeString = userInfo["type"] as? String ?? "unknown"
        type = NotificationType(rawValue: typeString) ?? .unknown

        resourceId = userInfo["resource_id"] as? String

        if let deepLinkString = userInfo["deep_link"] as? String {
            deepLink = URL(string: deepLinkString)
        } else {
            deepLink = nil
        }

        if let imageString = userInfo["image_url"] as? String {
            imageURL = URL(string: imageString)
        } else {
            imageURL = nil
        }

        // Store extra fields
        var extra: [String: Any] = [:]
        for (key, value) in userInfo {
            if let key = key as? String,
               key != "aps" && key != "type" && key != "resource_id" &&
               key != "deep_link" && key != "image_url" {
                extra[key] = value
            }
        }
        self.extra = extra
    }
}

// MARK: - Expected Payload Format

/*
 Server should send payloads in this format:

 {
   "aps": {
     "alert": {
       "title": "New Message",
       "body": "You have a new message from John"
     },
     "badge": 1,
     "sound": "default",
     "category": "MESSAGE_CATEGORY",
     "mutable-content": 1  // Required for Notification Service Extension
   },
   "type": "message",
   "resource_id": "msg_12345",
   "deep_link": "myapp://messages/msg_12345",
   "image_url": "https://example.com/image.jpg"
 }
 */
```

## Rich Notifications

### Notification Service Extension

```swift
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Download and attach image if URL provided
        if let imageURLString = request.content.userInfo["image_url"] as? String,
           let imageURL = URL(string: imageURLString) {
            downloadAndAttachImage(from: imageURL, to: bestAttemptContent) {
                contentHandler(bestAttemptContent)
            }
        } else {
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Deliver best attempt if time expires
        if let contentHandler, let bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadAndAttachImage(
        from url: URL,
        to content: UNMutableNotificationContent,
        completion: @escaping () -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
            defer { completion() }

            guard let localURL, error == nil else { return }

            // Move to accessible location
            let fileManager = FileManager.default
            let tmpDir = fileManager.temporaryDirectory
            let fileName = url.lastPathComponent
            let destinationURL = tmpDir.appendingPathComponent(fileName)

            try? fileManager.removeItem(at: destinationURL)
            try? fileManager.moveItem(at: localURL, to: destinationURL)

            // Create attachment
            if let attachment = try? UNNotificationAttachment(
                identifier: "image",
                url: destinationURL,
                options: nil
            ) {
                content.attachments = [attachment]
            }
        }
        task.resume()
    }
}
```

## Silent Notifications

### Handling Background Updates

```swift
// In AppDelegate
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any]
) async -> UIBackgroundFetchResult {

    // Check if silent notification
    guard let aps = userInfo["aps"] as? [String: Any],
          aps["content-available"] as? Int == 1 else {
        return .noData
    }

    do {
        // Perform background work
        let updated = try await performBackgroundUpdate(userInfo: userInfo)
        return updated ? .newData : .noData
    } catch {
        return .failed
    }
}

private func performBackgroundUpdate(userInfo: [AnyHashable: Any]) async throws -> Bool {
    // Example: Sync data
    // let syncManager = SyncManager.shared
    // return try await syncManager.syncIfNeeded()
    return true
}
```

### Silent Notification Payload

```json
{
  "aps": {
    "content-available": 1
  },
  "sync_type": "messages",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Local Notifications

### Scheduling

```swift
extension NotificationManager {

    /// Schedule a local notification.
    func scheduleLocalNotification(
        title: String,
        body: String,
        at date: Date,
        category: NotificationCategories.Identifier? = nil,
        userInfo: [String: Any] = [:]
    ) async throws -> String {

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        if let category {
            content.categoryIdentifier = category.rawValue
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let identifier = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
        return identifier
    }

    /// Cancel a scheduled notification.
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Get all pending notifications.
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}
```

## App Delegate Integration

### Complete Setup

```swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Set delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Register categories
        NotificationCategories.registerAll()

        // Check if launched from notification
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            handleLaunchNotification(notification)
        }

        return true
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.didRegister(with: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.didFailToRegister(with: error)
    }

    // MARK: - Background Notifications

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        // Handle silent notifications
        return await handleSilentNotification(userInfo)
    }

    // MARK: - Helpers

    private func handleLaunchNotification(_ userInfo: [AnyHashable: Any]) {
        if let payload = NotificationPayload(userInfo: userInfo) {
            // App was launched from notification
            // Handle deep link or navigation
        }
    }

    private func handleSilentNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let aps = userInfo["aps"] as? [String: Any],
              aps["content-available"] as? Int == 1 else {
            return .noData
        }

        // Perform background work
        return .newData
    }
}
```
