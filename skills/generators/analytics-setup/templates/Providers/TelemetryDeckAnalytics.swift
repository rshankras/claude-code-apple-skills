import Foundation
import TelemetryClient

/// TelemetryDeck analytics implementation.
///
/// TelemetryDeck is a privacy-friendly analytics service that doesn't require
/// user consent in most jurisdictions (no cookies, no personal data).
///
/// Setup:
/// 1. Add to Package.swift:
///    .package(url: "https://github.com/TelemetryDeck/SwiftClient", from: "1.0.0")
///
/// 2. Get your App ID from https://dashboard.telemetrydeck.com
///
/// 3. Initialize in App.swift:
///    let analytics: AnalyticsService = TelemetryDeckAnalytics(appID: "YOUR-APP-ID")
///
/// Usage:
/// ```swift
/// analytics.track(.screenViewed(name: "Settings"))
/// analytics.track(.buttonTapped("subscribe"))
/// ```
final class TelemetryDeckAnalytics: AnalyticsService, @unchecked Sendable {

    private let appID: String

    /// Initialize with your TelemetryDeck App ID.
    /// - Parameter appID: Your app ID from TelemetryDeck dashboard
    init(appID: String) {
        self.appID = appID
    }

    func configure() {
        let config = TelemetryManagerConfiguration(appID: appID)
        TelemetryManager.initialize(with: config)
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        var allProperties = event.properties
        for (key, value) in properties {
            allProperties[key] = value
        }

        TelemetryManager.send(event.name, with: allProperties)
    }

    func setUserProperty(_ key: String, value: String) {
        // TelemetryDeck uses default user properties from the SDK
        // Custom properties are sent with each signal
        // Store locally if you need to include in all future events
    }

    func setUserID(_ id: String?) {
        // TelemetryDeck generates anonymous user IDs automatically
        // No need to set explicitly
    }

    func reset() {
        // TelemetryDeck doesn't store user state that needs resetting
    }
}

// MARK: - Configuration Options

extension TelemetryDeckAnalytics {

    /// Create with additional configuration options.
    static func configured(
        appID: String,
        salt: String? = nil,
        testMode: Bool = false
    ) -> TelemetryDeckAnalytics {
        let analytics = TelemetryDeckAnalytics(appID: appID)

        // Configure with options if needed
        var config = TelemetryManagerConfiguration(appID: appID)
        if let salt = salt {
            config.salt = salt
        }
        config.testMode = testMode

        TelemetryManager.initialize(with: config)

        return analytics
    }
}
