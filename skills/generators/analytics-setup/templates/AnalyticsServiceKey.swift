import SwiftUI

/// SwiftUI Environment key for analytics service.
///
/// Usage:
/// ```swift
/// // In App.swift
/// ContentView()
///     .environment(\.analytics, TelemetryDeckAnalytics(appID: "..."))
///
/// // In any View
/// struct MyView: View {
///     @Environment(\.analytics) private var analytics
///
///     var body: some View {
///         Button("Action") {
///             analytics.track(.buttonTapped("action"))
///         }
///     }
/// }
/// ```
private struct AnalyticsServiceKey: EnvironmentKey {
    static let defaultValue: AnalyticsService = NoOpAnalytics()
}

extension EnvironmentValues {
    var analytics: AnalyticsService {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}

// MARK: - Screen Tracking Modifier

/// View modifier for automatic screen tracking.
///
/// Usage:
/// ```swift
/// SettingsView()
///     .trackScreen("Settings")
/// ```
struct AnalyticsScreenModifier: ViewModifier {
    let screenName: String
    @Environment(\.analytics) private var analytics

    func body(content: Content) -> some View {
        content.onAppear {
            analytics.track(.screenViewed(name: screenName))
        }
    }
}

extension View {
    /// Track when this screen appears.
    func trackScreen(_ name: String) -> some View {
        modifier(AnalyticsScreenModifier(screenName: name))
    }
}
