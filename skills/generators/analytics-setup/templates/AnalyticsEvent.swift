import Foundation

/// App analytics events.
///
/// Add your app-specific events here. Use past tense for completed actions.
///
/// Example usage:
/// ```swift
/// analytics.track(.screenViewed(name: "Settings"))
/// analytics.track(.buttonTapped("subscribe"))
/// analytics.track(.featureUsed("dark_mode"))
/// ```
enum AnalyticsEvent: Sendable {

    // MARK: - App Lifecycle

    /// App launched (cold start)
    case appLaunched

    /// App moved to background
    case appBackgrounded

    /// App returned to foreground
    case appForegrounded

    // MARK: - Navigation

    /// Screen was viewed
    case screenViewed(name: String)

    // MARK: - User Actions

    /// Button was tapped
    case buttonTapped(name: String)

    /// Feature was used/enabled
    case featureUsed(name: String)

    /// Search performed
    case searchPerformed(query: String)

    // MARK: - Errors

    /// Error occurred
    case errorOccurred(domain: String, code: Int)

    // MARK: - Custom Events

    /// Custom event with properties
    case custom(name: String, properties: [String: String])

    // MARK: - Add Your Events Below

    // Example:
    // case itemCreated(type: String)
    // case itemDeleted(type: String)
    // case subscriptionStarted(plan: String)
    // case settingsChanged(setting: String, value: String)
}

// MARK: - Event Names

extension AnalyticsEvent {

    /// The event name string used for tracking.
    var name: String {
        switch self {
        case .appLaunched:
            return "app_launched"
        case .appBackgrounded:
            return "app_backgrounded"
        case .appForegrounded:
            return "app_foregrounded"
        case .screenViewed(let name):
            return "screen_viewed_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
        case .buttonTapped(let name):
            return "button_tapped_\(name.lowercased())"
        case .featureUsed(let name):
            return "feature_used_\(name.lowercased())"
        case .searchPerformed:
            return "search_performed"
        case .errorOccurred(let domain, let code):
            return "error_\(domain.lowercased())_\(code)"
        case .custom(let name, _):
            return name
        }
    }

    /// Additional properties for the event.
    var properties: [String: String] {
        switch self {
        case .screenViewed(let name):
            return ["screen_name": name]
        case .buttonTapped(let name):
            return ["button_name": name]
        case .featureUsed(let name):
            return ["feature_name": name]
        case .searchPerformed(let query):
            // Don't track exact query for privacy - just that search was used
            return ["query_length": String(query.count)]
        case .errorOccurred(let domain, let code):
            return ["error_domain": domain, "error_code": String(code)]
        case .custom(_, let properties):
            return properties
        default:
            return [:]
        }
    }
}
