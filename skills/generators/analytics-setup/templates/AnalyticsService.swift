import Foundation

/// Protocol defining the analytics service interface.
///
/// This protocol allows swapping analytics providers without changing app code.
/// Use `NoOpAnalytics` for testing and previews.
///
/// Example:
/// ```swift
/// // In App.swift
/// let analytics: AnalyticsService = TelemetryDeckAnalytics(appID: "...")
///
/// // To swap providers, change ONE line:
/// let analytics: AnalyticsService = FirebaseAnalytics()
/// ```
protocol AnalyticsService: Sendable {

    /// Configure the analytics service. Call once at app launch.
    func configure()

    /// Track an event.
    func track(_ event: AnalyticsEvent)

    /// Track an event with additional properties.
    func track(_ event: AnalyticsEvent, properties: [String: String])

    /// Set a user property that persists across sessions.
    func setUserProperty(_ key: String, value: String)

    /// Set the user ID for attribution. Pass nil to clear.
    func setUserID(_ id: String?)

    /// Reset all user data. Call on logout.
    func reset()
}

// MARK: - Default Implementations

extension AnalyticsService {

    func track(_ event: AnalyticsEvent) {
        track(event, properties: [:])
    }

    func setUserID(_ id: String?) {
        // Optional - not all providers support this
    }

    func reset() {
        // Default no-op
    }
}

// MARK: - Common User Property Keys

enum AnalyticsUserProperty {
    static let appVersion = "app_version"
    static let subscriptionStatus = "subscription_status"
    static let theme = "theme"

    // Add your custom properties here
}
