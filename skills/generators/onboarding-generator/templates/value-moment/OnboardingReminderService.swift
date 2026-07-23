// DEFAULT ARCHITECTURE — value-moment-first onboarding.
//
// Implementation intentions are LOCAL notifications (onboarding-patterns.md
// Lesson 6) — no push capability, no server required.

import Foundation
import OSLog
import UserNotifications

// MARK: - Live wrapper seam

/// The one seam this file's service talks through — thin enough that the
/// live implementation is a pure pass-through to `UNUserNotificationCenter`,
/// wide enough that a test double never needs the real framework type at
/// all. Keep this the ONLY file in your app target that imports
/// `UserNotifications` — a grep-able contract makes drift visible.
protocol NotificationScheduling: Sendable {
    /// Shows the system permission alert. Returns whether it was granted; a
    /// request that throws is treated as "not granted" by the caller — never
    /// a crash, never a blocking failure.
    func requestAuthorization() async throws -> Bool

    /// Schedules (or REPLACES, if `id` already has a pending request) a
    /// local notification for `fireDate`.
    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) async throws

    /// Cancels a pending request by identifier. A no-op if none is pending.
    func cancelNotification(id: String)
}

struct LiveNotificationCenter: NotificationScheduling {
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

// MARK: - ReminderScheduling (the seam OnboardingStore holds)

/// `OnboardingStore`'s reminder seam — narrow enough that its own tests
/// inject a fake with no `UserNotifications` dependency at all.
@MainActor
protocol ReminderScheduling: AnyObject {
    /// Request authorization THEN schedule, in that order, never the
    /// reverse — this should be the ONLY call site that ever touches the
    /// system permission alert, so authorization is always asked in context
    /// (the reminder step), never primed cold at launch. Returns whether the
    /// reminder actually got scheduled — `false` on denial or a scheduling
    /// failure; either way the caller's plan stays saved regardless of this
    /// result.
    @discardableResult
    func requestAndSchedule(title: String, body: String, fireDate: Date) async -> Bool
}

// MARK: - OnboardingReminderService

@MainActor
final class OnboardingReminderService: ReminderScheduling {

    /// Replace with your own identifier scheme if the app can have more than
    /// one plan pending at a time — a single stable identifier means a later
    /// call REPLACES rather than stacking duplicates.
    static let reminderIdentifier = "onboardingReminder"

    private let center: NotificationScheduling
    private static let log = Logger(subsystem: "com.yourapp", category: "OnboardingReminder")

    init(center: NotificationScheduling = LiveNotificationCenter()) {
        self.center = center
    }

    @discardableResult
    func requestAndSchedule(title: String, body: String, fireDate: Date) async -> Bool {
        do {
            let granted = try await center.requestAuthorization()
            guard granted else {
                Self.log.info("reminder authorization denied — plan stays saved, no local notification")
                return false
            }
            try await center.scheduleNotification(
                id: Self.reminderIdentifier, title: title, body: body, fireDate: fireDate
            )
            Self.log.info("reminder scheduled")
            return true
        } catch {
            Self.log.error("reminder request/schedule failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
