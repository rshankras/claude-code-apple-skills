import Foundation
import UserNotifications

/// Handles notification presentation and user responses.
///
/// Setup in AppDelegate:
/// ```swift
/// func application(_ application: UIApplication, didFinishLaunchingWithOptions...) -> Bool {
///     UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
///     NotificationCategories.registerAll()
///     return true
/// }
/// ```
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = NotificationDelegate()

    // MARK: - Handlers

    /// Custom handler for notification tap. Set this to handle navigation.
    var onNotificationTap: ((NotificationPayload) async -> Void)?

    /// Custom handler for notification actions. Set this to handle action buttons.
    var onNotificationAction: ((String, NotificationPayload) async -> Void)?

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification arrives while app is in foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {

        let userInfo = notification.request.content.userInfo

        #if DEBUG
        print("📬 [Notifications] Received in foreground")
        print("   Title: \(notification.request.content.title)")
        print("   Body: \(notification.request.content.body)")
        #endif

        // Parse and optionally handle
        if let payload = NotificationPayload(userInfo: userInfo) {
            // You can choose to handle silently or show banner
            // For example, don't show banner if user is already viewing related content
            // return []
            _ = payload  // Suppress unused warning
        }

        // Show notification banner, sound, and badge
        return [.banner, .sound, .badge, .list]
    }

    /// Called when user interacts with a notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {

        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        #if DEBUG
        print("📬 [Notifications] User responded")
        print("   Action: \(actionIdentifier)")
        #endif

        guard let payload = NotificationPayload(userInfo: userInfo) else {
            return
        }

        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            await handleNotificationTap(payload)

        case UNNotificationDismissActionIdentifier:
            // User dismissed (only if category has .customDismissAction)
            #if DEBUG
            print("   User dismissed notification")
            #endif

        default:
            // Custom action button
            await handleCustomAction(actionIdentifier, payload: payload, response: response)
        }
    }

    /// Called when user opens notification settings from notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        openSettingsFor notification: UNNotification?
    ) {
        // Post notification for app to handle
        NotificationCenter.default.post(
            name: .openNotificationSettings,
            object: nil
        )
    }

    // MARK: - Handlers

    private func handleNotificationTap(_ payload: NotificationPayload) async {
        // Use custom handler if set
        if let handler = onNotificationTap {
            await handler(payload)
            return
        }

        // Default handling based on type
        await MainActor.run {
            switch payload.type {
            case .message:
                if let resourceId = payload.resourceId {
                    NotificationCenter.default.post(
                        name: .navigateToMessage,
                        object: nil,
                        userInfo: ["messageId": resourceId]
                    )
                }

            case .reminder:
                if let resourceId = payload.resourceId {
                    NotificationCenter.default.post(
                        name: .navigateToReminder,
                        object: nil,
                        userInfo: ["reminderId": resourceId]
                    )
                }

            case .update:
                NotificationCenter.default.post(
                    name: .showUpdateDetails,
                    object: nil,
                    userInfo: payload.extra
                )

            case .unknown:
                // Handle deep link if available
                if let deepLink = payload.deepLink {
                    NotificationCenter.default.post(
                        name: .handleDeepLink,
                        object: nil,
                        userInfo: ["url": deepLink]
                    )
                }
            }
        }
    }

    private func handleCustomAction(
        _ identifier: String,
        payload: NotificationPayload,
        response: UNNotificationResponse
    ) async {
        // Use custom handler if set
        if let handler = onNotificationAction {
            await handler(identifier, payload)
            return
        }

        // Default action handling
        switch identifier {
        case NotificationCategories.Action.reply.rawValue:
            // Handle text input reply
            if let textResponse = response as? UNTextInputNotificationResponse {
                await handleReply(text: textResponse.userText, payload: payload)
            }

        case NotificationCategories.Action.markRead.rawValue:
            await markAsRead(payload: payload)

        case NotificationCategories.Action.complete.rawValue:
            await completeTask(payload: payload)

        case NotificationCategories.Action.snooze.rawValue:
            await snoozeReminder(payload: payload)

        default:
            #if DEBUG
            print("⚠️ [Notifications] Unknown action: \(identifier)")
            #endif
        }
    }

    // MARK: - Action Implementations

    private func handleReply(text: String, payload: NotificationPayload) async {
        #if DEBUG
        print("💬 [Notifications] Reply: \(text)")
        #endif

        // TODO: Send reply to server
        // await APIClient.shared.sendReply(to: payload.resourceId, text: text)
    }

    private func markAsRead(payload: NotificationPayload) async {
        #if DEBUG
        print("✓ [Notifications] Mark as read: \(payload.resourceId ?? "unknown")")
        #endif

        // TODO: Mark as read on server
        // await APIClient.shared.markAsRead(payload.resourceId)
    }

    private func completeTask(payload: NotificationPayload) async {
        #if DEBUG
        print("✓ [Notifications] Complete task: \(payload.resourceId ?? "unknown")")
        #endif

        // TODO: Complete task on server
        // await APIClient.shared.completeTask(payload.resourceId)
    }

    private func snoozeReminder(payload: NotificationPayload) async {
        #if DEBUG
        print("⏰ [Notifications] Snooze: \(payload.resourceId ?? "unknown")")
        #endif

        // Reschedule notification for 15 minutes later
        do {
            try await NotificationManager.shared.scheduleLocalNotification(
                title: payload.title ?? "Reminder",
                body: payload.body ?? "",
                in: 15 * 60,  // 15 minutes
                category: NotificationCategories.Identifier.reminder.rawValue,
                userInfo: payload.extra
            )
        } catch {
            #if DEBUG
            print("⚠️ [Notifications] Failed to snooze: \(error)")
            #endif
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user wants to open notification settings.
    static let openNotificationSettings = Notification.Name("openNotificationSettings")

    /// Posted when navigating to a message from notification.
    static let navigateToMessage = Notification.Name("navigateToMessage")

    /// Posted when navigating to a reminder from notification.
    static let navigateToReminder = Notification.Name("navigateToReminder")

    /// Posted when showing update details from notification.
    static let showUpdateDetails = Notification.Name("showUpdateDetails")

    /// Posted when handling a deep link from notification.
    static let handleDeepLink = Notification.Name("handleDeepLink")
}
