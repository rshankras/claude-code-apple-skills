import UserNotifications

/// Notification categories define the actions available for each notification type.
///
/// Register on app launch:
/// ```swift
/// NotificationCategories.registerAll()
/// ```
///
/// Server should include `category` in APNs payload:
/// ```json
/// {
///   "aps": {
///     "alert": { "title": "New Message", "body": "Hello!" },
///     "category": "MESSAGE_CATEGORY"
///   }
/// }
/// ```
enum NotificationCategories {

    // MARK: - Category Identifiers

    enum Identifier: String, CaseIterable {
        case message = "MESSAGE_CATEGORY"
        case reminder = "REMINDER_CATEGORY"
        case update = "UPDATE_CATEGORY"
        case social = "SOCIAL_CATEGORY"
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
        case view = "VIEW_ACTION"
        case later = "LATER_ACTION"

        // Social actions
        case like = "LIKE_ACTION"
        case comment = "COMMENT_ACTION"
    }

    // MARK: - Registration

    /// Register all notification categories.
    /// Call this on app launch in didFinishLaunchingWithOptions.
    static func registerAll() {
        let categories: Set<UNNotificationCategory> = [
            messageCategory,
            reminderCategory,
            updateCategory,
            socialCategory
        ]

        UNUserNotificationCenter.current().setNotificationCategories(categories)

        #if DEBUG
        print("📋 [Notifications] Registered \(categories.count) categories")
        #endif
    }

    // MARK: - Category Definitions

    /// Message category with reply and mark read actions.
    private static var messageCategory: UNNotificationCategory {
        // Text input action for replies
        let replyAction = UNTextInputNotificationAction(
            identifier: Action.reply.rawValue,
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your reply..."
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
            hiddenPreviewsBodyPlaceholder: "New message",
            categorySummaryFormat: "%u new messages",
            options: [.customDismissAction, .allowInCarPlay]
        )
    }

    /// Reminder category with complete and snooze actions.
    private static var reminderCategory: UNNotificationCategory {
        let completeAction = UNNotificationAction(
            identifier: Action.complete.rawValue,
            title: "Complete",
            options: [.foreground]  // Opens app
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
            hiddenPreviewsBodyPlaceholder: "Reminder",
            options: []
        )
    }

    /// Update category with view and later actions.
    private static var updateCategory: UNNotificationCategory {
        let viewAction = UNNotificationAction(
            identifier: Action.view.rawValue,
            title: "View",
            options: [.foreground]
        )

        let laterAction = UNNotificationAction(
            identifier: Action.later.rawValue,
            title: "Later",
            options: []
        )

        return UNNotificationCategory(
            identifier: Identifier.update.rawValue,
            actions: [viewAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
    }

    /// Social category with like and comment actions.
    private static var socialCategory: UNNotificationCategory {
        let likeAction = UNNotificationAction(
            identifier: Action.like.rawValue,
            title: "❤️ Like",
            options: []
        )

        let commentAction = UNTextInputNotificationAction(
            identifier: Action.comment.rawValue,
            title: "Comment",
            options: [.foreground],
            textInputButtonTitle: "Post",
            textInputPlaceholder: "Write a comment..."
        )

        return UNNotificationCategory(
            identifier: Identifier.social.rawValue,
            actions: [likeAction, commentAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "New activity",
            categorySummaryFormat: "%u new notifications",
            options: [.customDismissAction]
        )
    }
}

// MARK: - Category Summary Formats

/*
 Category Summary Format Specifiers:

 %u - Number of notifications in the group
 %@ - The summary argument from the notification content

 Example:
 - categorySummaryFormat: "%u new messages from %@"
 - With 3 notifications from "John"
 - Shows: "3 new messages from John"

 To set the summary argument:
 content.summaryArgument = "John"
 content.summaryArgumentCount = 3  // Optional, defaults to 1
 */

// MARK: - Action Options Reference

/*
 UNNotificationActionOptions:

 .authenticationRequired - Requires device unlock
 .destructive           - Red text, indicates destructive action
 .foreground           - Opens the app when selected

 UNNotificationCategoryOptions:

 .customDismissAction     - Calls delegate when dismissed
 .allowInCarPlay          - Shows in CarPlay
 .hiddenPreviewsShowTitle - Shows title even when previews hidden
 .hiddenPreviewsShowSubtitle - Shows subtitle even when previews hidden
 .allowAnnouncement       - Siri can announce
 */
