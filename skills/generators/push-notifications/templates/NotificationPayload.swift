import Foundation

/// Type-safe representation of a push notification payload.
///
/// Expected server payload format:
/// ```json
/// {
///   "aps": {
///     "alert": {
///       "title": "Notification Title",
///       "body": "Notification body text"
///     },
///     "badge": 1,
///     "sound": "default",
///     "category": "MESSAGE_CATEGORY",
///     "mutable-content": 1
///   },
///   "type": "message",
///   "resource_id": "msg_12345",
///   "deep_link": "myapp://messages/msg_12345",
///   "image_url": "https://example.com/image.jpg",
///   "custom_field": "custom_value"
/// }
/// ```
struct NotificationPayload: Sendable {

    // MARK: - Types

    /// Notification type for routing.
    enum NotificationType: String, Sendable {
        case message
        case reminder
        case update
        case social
        case promo
        case unknown
    }

    // MARK: - Properties

    /// Type of notification for routing.
    let type: NotificationType

    /// Notification title from alert.
    let title: String?

    /// Notification body from alert.
    let body: String?

    /// Subtitle from alert.
    let subtitle: String?

    /// Resource identifier for deep linking.
    let resourceId: String?

    /// Deep link URL.
    let deepLink: URL?

    /// Image URL for rich notifications.
    let imageURL: URL?

    /// Badge count.
    let badge: Int?

    /// Category identifier.
    let category: String?

    /// Thread identifier for grouping.
    let threadId: String?

    /// Any extra custom fields.
    let extra: [String: Any]

    /// Original userInfo dictionary.
    let rawUserInfo: [AnyHashable: Any]

    // MARK: - Initialization

    init?(userInfo: [AnyHashable: Any]) {
        rawUserInfo = userInfo

        // Parse APS dictionary
        guard let aps = userInfo["aps"] as? [String: Any] else {
            return nil
        }

        // Parse alert
        if let alert = aps["alert"] as? [String: Any] {
            title = alert["title"] as? String
            body = alert["body"] as? String
            subtitle = alert["subtitle"] as? String
        } else if let alertString = aps["alert"] as? String {
            title = nil
            body = alertString
            subtitle = nil
        } else {
            title = nil
            body = nil
            subtitle = nil
        }

        // Parse badge
        badge = aps["badge"] as? Int

        // Parse category
        category = aps["category"] as? String

        // Parse thread ID
        threadId = aps["thread-id"] as? String

        // Parse custom fields
        let typeString = userInfo["type"] as? String ?? "unknown"
        type = NotificationType(rawValue: typeString) ?? .unknown

        resourceId = userInfo["resource_id"] as? String
            ?? userInfo["resourceId"] as? String
            ?? userInfo["id"] as? String

        if let deepLinkString = userInfo["deep_link"] as? String
            ?? userInfo["deepLink"] as? String
            ?? userInfo["url"] as? String {
            deepLink = URL(string: deepLinkString)
        } else {
            deepLink = nil
        }

        if let imageString = userInfo["image_url"] as? String
            ?? userInfo["imageUrl"] as? String
            ?? userInfo["image"] as? String {
            imageURL = URL(string: imageString)
        } else {
            imageURL = nil
        }

        // Collect extra fields
        let reservedKeys: Set<String> = [
            "aps", "type", "resource_id", "resourceId", "id",
            "deep_link", "deepLink", "url",
            "image_url", "imageUrl", "image"
        ]

        var extra: [String: Any] = [:]
        for (key, value) in userInfo {
            if let key = key as? String, !reservedKeys.contains(key) {
                extra[key] = value
            }
        }
        self.extra = extra
    }
}

// MARK: - Convenience Accessors

extension NotificationPayload {

    /// Check if this is a silent notification.
    var isSilent: Bool {
        guard let aps = rawUserInfo["aps"] as? [String: Any] else {
            return false
        }
        return aps["content-available"] as? Int == 1 && title == nil && body == nil
    }

    /// Check if this notification has rich content (image).
    var hasRichContent: Bool {
        imageURL != nil
    }

    /// Get a typed extra value.
    func extra<T>(_ key: String, as type: T.Type = T.self) -> T? {
        extra[key] as? T
    }
}

// MARK: - Debug Description

extension NotificationPayload: CustomDebugStringConvertible {

    var debugDescription: String {
        """
        NotificationPayload:
          type: \(type.rawValue)
          title: \(title ?? "nil")
          body: \(body ?? "nil")
          resourceId: \(resourceId ?? "nil")
          deepLink: \(deepLink?.absoluteString ?? "nil")
          imageURL: \(imageURL?.absoluteString ?? "nil")
          badge: \(badge.map { String($0) } ?? "nil")
          category: \(category ?? "nil")
          isSilent: \(isSilent)
          extra: \(extra.keys.joined(separator: ", "))
        """
    }
}

// MARK: - Example Payloads

/*
 Message notification:
 {
   "aps": {
     "alert": { "title": "John", "body": "Hey, how are you?" },
     "badge": 1,
     "sound": "default",
     "category": "MESSAGE_CATEGORY",
     "thread-id": "conversation_123"
   },
   "type": "message",
   "resource_id": "msg_456",
   "deep_link": "myapp://messages/msg_456"
 }

 Reminder notification:
 {
   "aps": {
     "alert": { "title": "Reminder", "body": "Meeting in 15 minutes" },
     "sound": "default",
     "category": "REMINDER_CATEGORY"
   },
   "type": "reminder",
   "resource_id": "reminder_789",
   "meeting_id": "meeting_123"
 }

 Silent notification (background update):
 {
   "aps": {
     "content-available": 1
   },
   "type": "sync",
   "sync_type": "messages",
   "timestamp": "2024-01-15T10:30:00Z"
 }

 Rich notification (with image):
 {
   "aps": {
     "alert": { "title": "New Photo", "body": "Alice shared a photo" },
     "sound": "default",
     "mutable-content": 1
   },
   "type": "social",
   "resource_id": "photo_123",
   "image_url": "https://example.com/photos/preview.jpg"
 }
 */
