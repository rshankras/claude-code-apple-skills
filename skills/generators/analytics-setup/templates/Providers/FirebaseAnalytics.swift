import Foundation
import FirebaseCore
import FirebaseAnalytics

/// Firebase Analytics implementation.
///
/// Firebase Analytics provides comprehensive analytics with Google's infrastructure.
/// Note: May require user consent in EU/GDPR jurisdictions.
///
/// Setup:
/// 1. Add to Package.swift:
///    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
///    // Add FirebaseAnalytics product
///
/// 2. Download GoogleService-Info.plist from Firebase Console
///    and add to your app target
///
/// 3. Initialize in App.swift:
///    let analytics: AnalyticsService = FirebaseAnalytics()
///
/// Usage:
/// ```swift
/// analytics.track(.screenViewed(name: "Settings"))
/// analytics.track(.buttonTapped("subscribe"))
/// ```
final class FirebaseAnalyticsService: AnalyticsService, @unchecked Sendable {

    init() {}

    func configure() {
        // FirebaseApp.configure() should be called once at app launch
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    func track(_ event: AnalyticsEvent, properties: [String: String]) {
        var parameters: [String: Any] = event.properties
        for (key, value) in properties {
            parameters[key] = value
        }

        Analytics.logEvent(event.firebaseName, parameters: parameters.isEmpty ? nil : parameters)
    }

    func setUserProperty(_ key: String, value: String) {
        Analytics.setUserProperty(value, forName: key)
    }

    func setUserID(_ id: String?) {
        Analytics.setUserID(id)
    }

    func reset() {
        Analytics.setUserID(nil)
        Analytics.resetAnalyticsData()
    }
}

// MARK: - Firebase Event Names

extension AnalyticsEvent {

    /// Firebase-compatible event name.
    /// Firebase has specific naming requirements and reserved event names.
    var firebaseName: String {
        switch self {
        case .appLaunched:
            return "app_open" // Firebase reserved event
        case .screenViewed:
            return AnalyticsEventScreenView // Firebase reserved event
        case .buttonTapped:
            return "button_tap"
        case .featureUsed:
            return "feature_use"
        case .searchPerformed:
            return AnalyticsEventSearch // Firebase reserved event
        case .errorOccurred:
            return "app_error"
        case .custom(let name, _):
            return name
        default:
            return name.replacingOccurrences(of: "-", with: "_")
        }
    }
}

// MARK: - Consent Management

extension FirebaseAnalyticsService {

    /// Set analytics collection based on user consent.
    /// Call this when user grants or revokes consent.
    static func setAnalyticsCollectionEnabled(_ enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }
}
