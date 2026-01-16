import OSLog

/// Centralized logging for the app using Apple's unified logging system.
///
/// Usage:
/// ```swift
/// AppLogger.network.info("Request started")
/// AppLogger.auth.debug("User: \(email, privacy: .private)")
/// AppLogger.data.error("Save failed: \(error)")
/// ```
///
/// Privacy Levels:
/// - `.public` - Safe to log (IDs, counts, status codes)
/// - `.private` - Redacted in release (emails, names) - DEFAULT
/// - `.sensitive` - Always redacted (passwords, tokens)
///
/// Log Levels:
/// - `.debug` - Development only (compiled out in release)
/// - `.info` - General information
/// - `.notice` - Important events (persisted)
/// - `.warning` - Potential issues (persisted)
/// - `.error` - Errors (persisted)
/// - `.fault` - Critical failures (persisted, highlighted)
///
enum AppLogger {

    /// The subsystem identifier, typically the app's bundle identifier.
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.app"

    // MARK: - Core Categories

    /// General logging for miscellaneous events.
    static let general = Logger(subsystem: subsystem, category: "General")

    // MARK: - Networking

    /// Network requests, responses, and connectivity.
    static let network = Logger(subsystem: subsystem, category: "Network")

    // MARK: - Authentication & User

    /// Authentication, login, logout, session management.
    static let auth = Logger(subsystem: subsystem, category: "Auth")

    // MARK: - Data & Persistence

    /// Data operations, persistence, caching.
    static let data = Logger(subsystem: subsystem, category: "Data")

    // MARK: - User Interface

    /// UI events, navigation, view lifecycle.
    static let ui = Logger(subsystem: subsystem, category: "UI")

    // MARK: - Performance

    /// Performance measurements and profiling.
    static let performance = Logger(subsystem: subsystem, category: "Performance")
}

// MARK: - Usage Examples

/*

 // Basic logging
 AppLogger.general.info("App launched")

 // With privacy for user data
 AppLogger.auth.info("User signed in: \(email, privacy: .private)")

 // Error logging
 AppLogger.network.error("Request failed: \(error.localizedDescription)")

 // Debug (compiled out in release)
 AppLogger.data.debug("Loaded \(items.count, privacy: .public) items")

 // Sensitive data (always redacted)
 AppLogger.auth.debug("Token: \(token, privacy: .sensitive)")

 // Hash for correlation without exposing data
 AppLogger.auth.info("User ID: \(userId, privacy: .private(mask: .hash))")

 // Formatted numbers
 AppLogger.performance.info("Duration: \(seconds, format: .fixed(precision: 2))s")

 */

// MARK: - Console.app Filtering

/*

 To view logs in Console.app:
 1. Open Console.app
 2. Select your device or simulator
 3. In the search field, filter by:
    - subsystem:com.yourapp
    - category:Network
    - type:error

 Terminal streaming:
 log stream --predicate 'subsystem == "com.yourapp"' --level debug

 */
