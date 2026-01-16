import Foundation

/// No-operation analytics implementation.
///
/// Use for:
/// - Unit tests
/// - SwiftUI previews
/// - Users who opted out of analytics
/// - Debug builds (optional)
///
/// Example:
/// ```swift
/// // In tests
/// let analytics: AnalyticsService = NoOpAnalytics()
///
/// // In previews
/// #Preview {
///     ContentView()
///         .environment(\.analytics, NoOpAnalytics())
/// }
///
/// // For user opt-out
/// let analytics: AnalyticsService = userOptedIn ? TelemetryDeckAnalytics(...) : NoOpAnalytics()
/// ```
final class NoOpAnalytics: AnalyticsService, @unchecked Sendable {

    init() {}

    func configure() {
        // No-op
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        // No-op
        #if DEBUG
        // Uncomment to see what would be tracked:
        // print("[Analytics NoOp] \(event.name) - \(properties)")
        #endif
    }

    func setUserProperty(_ key: String, value: String) {
        // No-op
    }

    func setUserID(_ id: String?) {
        // No-op
    }

    func reset() {
        // No-op
    }
}
