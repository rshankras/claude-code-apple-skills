import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

/// Central manager for push notification registration and handling.
///
/// Usage:
/// ```swift
/// // Request permission
/// let granted = try await NotificationManager.shared.requestAuthorization()
///
/// // Register for remote notifications
/// if granted {
///     NotificationManager.shared.registerForRemoteNotifications()
/// }
///
/// // Schedule local notification
/// try await NotificationManager.shared.scheduleLocalNotification(
///     title: "Reminder",
///     body: "Don't forget!",
///     at: Date().addingTimeInterval(3600)
/// )
/// ```
@MainActor
@Observable
final class NotificationManager {

    // MARK: - Singleton

    static let shared = NotificationManager()

    // MARK: - Properties

    /// Current authorization status.
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Device token for remote notifications (hex string).
    private(set) var deviceToken: String?

    /// Whether notifications are enabled.
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }

    /// Whether notifications are provisionally authorized.
    var isProvisional: Bool {
        authorizationStatus == .provisional
    }

    // MARK: - Initialization

    private init() {
        Task {
            await refreshAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request notification authorization from the user.
    ///
    /// - Parameter options: Authorization options (defaults to alert, badge, sound).
    /// - Returns: Whether authorization was granted.
    @discardableResult
    func requestAuthorization(
        options: UNAuthorizationOptions = [.alert, .badge, .sound]
    ) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: options)

        await refreshAuthorizationStatus()

        return granted
    }

    /// Request provisional authorization (iOS 12+).
    /// Notifications are delivered quietly without prompting the user.
    @discardableResult
    func requestProvisionalAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        return try await requestAuthorization(options: options)
    }

    /// Refresh the current authorization status.
    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Check if a specific notification setting is enabled.
    func isSettingEnabled(_ keyPath: KeyPath<UNNotificationSettings, UNNotificationSetting>) async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings[keyPath: keyPath] == .enabled
    }

    // MARK: - Remote Notification Registration

    /// Register for remote notifications.
    func registerForRemoteNotifications() {
        #if canImport(UIKit) && !os(watchOS)
        UIApplication.shared.registerForRemoteNotifications()
        #endif
    }

    /// Unregister from remote notifications.
    func unregisterForRemoteNotifications() {
        #if canImport(UIKit) && !os(watchOS)
        UIApplication.shared.unregisterForRemoteNotifications()
        #endif
        deviceToken = nil
    }

    /// Called by AppDelegate when registration succeeds.
    func didRegisterForRemoteNotifications(with deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token

        #if DEBUG
        print("📱 [Notifications] Device token: \(token)")
        #endif

        // Send token to server
        Task {
            await sendTokenToServer(token)
        }
    }

    /// Called by AppDelegate when registration fails.
    func didFailToRegisterForRemoteNotifications(with error: Error) {
        #if DEBUG
        print("❌ [Notifications] Registration failed: \(error.localizedDescription)")
        #endif
    }

    // MARK: - Server Communication

    private func sendTokenToServer(_ token: String) async {
        // TODO: Implement your server token registration
        // Example:
        // do {
        //     try await APIClient.shared.registerDeviceToken(token)
        // } catch {
        //     print("Failed to register token with server: \(error)")
        // }
    }

    // MARK: - Badge Management

    /// Clear the app badge.
    func clearBadge() async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(0)
        } catch {
            #if DEBUG
            print("⚠️ [Notifications] Failed to clear badge: \(error)")
            #endif
        }
    }

    /// Set the app badge count.
    func setBadge(_ count: Int) async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
        } catch {
            #if DEBUG
            print("⚠️ [Notifications] Failed to set badge: \(error)")
            #endif
        }
    }

    // MARK: - Local Notifications

    /// Schedule a local notification.
    ///
    /// - Parameters:
    ///   - title: Notification title.
    ///   - body: Notification body.
    ///   - date: When to deliver the notification.
    ///   - category: Optional category identifier for actions.
    ///   - userInfo: Additional data to include.
    /// - Returns: The notification identifier (for cancellation).
    @discardableResult
    func scheduleLocalNotification(
        title: String,
        body: String,
        at date: Date,
        category: String? = nil,
        userInfo: [String: Any] = [:]
    ) async throws -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        if let category {
            content.categoryIdentifier = category
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
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

        #if DEBUG
        print("📅 [Notifications] Scheduled: \(identifier) for \(date)")
        #endif

        return identifier
    }

    /// Schedule a notification with a time interval.
    @discardableResult
    func scheduleLocalNotification(
        title: String,
        body: String,
        in timeInterval: TimeInterval,
        category: String? = nil,
        userInfo: [String: Any] = [:]
    ) async throws -> String {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        if let category {
            content.categoryIdentifier = category
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
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

    /// Cancel all pending notifications.
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Get all pending notification requests.
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    /// Get all delivered notifications.
    func getDeliveredNotifications() async -> [UNNotification] {
        await UNUserNotificationCenter.current().deliveredNotifications()
    }

    /// Remove specific delivered notifications.
    func removeDeliveredNotifications(identifiers: [String]) {
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    /// Remove all delivered notifications.
    func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - Settings URL Helper

extension NotificationManager {

    /// Open system notification settings for this app.
    func openNotificationSettings() {
        #if canImport(UIKit) && !os(watchOS)
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }

        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
        #endif
    }
}
