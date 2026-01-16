import Foundation
// import Sentry  // Uncomment after adding Sentry SDK

/// Sentry implementation of ErrorMonitoringService.
///
/// Prerequisites:
/// 1. Add Sentry SDK to Package.swift:
///    `.package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0")`
/// 2. Get DSN from Sentry dashboard
/// 3. Uncomment the import and implementation below
///
/// Usage:
/// ```swift
/// let service: ErrorMonitoringService = SentryErrorMonitoring()
/// service.configure()  // Call at app launch
/// ```
final class SentryErrorMonitoring: ErrorMonitoringService, @unchecked Sendable {

    // MARK: - Configuration

    /// Your Sentry DSN from Project Settings > Client Keys
    private let dsn = "YOUR_SENTRY_DSN_HERE"

    /// Sample rate for error events (0.0 to 1.0)
    private let sampleRate: Float = 1.0

    /// Sample rate for performance traces (0.0 to 1.0)
    private let tracesSampleRate: Float = 0.1

    // MARK: - ErrorMonitoringService

    func configure() {
        // TODO: Uncomment after adding Sentry SDK
        /*
        SentrySDK.start { options in
            options.dsn = self.dsn
            options.sampleRate = NSNumber(value: self.sampleRate)
            options.tracesSampleRate = NSNumber(value: self.tracesSampleRate)

            // Enable automatic breadcrumbs
            options.enableAutoBreadcrumbTracking = true
            options.enableUIViewControllerTracing = true
            options.enableNetworkTracking = true

            // Set release version
            options.releaseName = self.releaseVersion

            // Debug mode (disable in production)
            #if DEBUG
            options.debug = true
            #endif

            // Set environment
            #if DEBUG
            options.environment = "development"
            #else
            options.environment = "production"
            #endif
        }
        */

        print("[Sentry] Would configure with DSN: \(dsn.prefix(20))...")
    }

    func captureError(_ error: Error, context: ErrorContext?) {
        // TODO: Uncomment after adding Sentry SDK
        /*
        SentrySDK.capture(error: error) { scope in
            if let context {
                // Add tags
                for (key, value) in context.tags {
                    scope.setTag(value: value, key: key)
                }

                // Add extra data
                for (key, value) in context.extra {
                    scope.setExtra(value: value, key: key)
                }

                // Set custom fingerprint
                if let fingerprint = context.fingerprint {
                    scope.setFingerprint(fingerprint)
                }
            }
        }
        */

        print("[Sentry] Would capture error: \(error)")
    }

    func captureMessage(_ message: String, level: ErrorLevel) {
        // TODO: Uncomment after adding Sentry SDK
        /*
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level.sentryLevel)
        }
        */

        print("[Sentry] Would capture \(level.rawValue): \(message)")
    }

    func addBreadcrumb(_ breadcrumb: Breadcrumb) {
        // TODO: Uncomment after adding Sentry SDK
        /*
        let sentryBreadcrumb = Sentry.Breadcrumb()
        sentryBreadcrumb.category = breadcrumb.category
        sentryBreadcrumb.message = breadcrumb.message
        sentryBreadcrumb.level = breadcrumb.level.sentryLevel
        sentryBreadcrumb.timestamp = breadcrumb.timestamp

        if let data = breadcrumb.data {
            sentryBreadcrumb.data = data
        }

        SentrySDK.addBreadcrumb(sentryBreadcrumb)
        */

        print("[Sentry] Would add breadcrumb: [\(breadcrumb.category)] \(breadcrumb.message)")
    }

    func setUser(_ user: MonitoringUser?) {
        // TODO: Uncomment after adding Sentry SDK
        /*
        if let user {
            let sentryUser = Sentry.User()
            sentryUser.userId = user.id
            sentryUser.username = user.username
            sentryUser.segment = user.segment
            SentrySDK.setUser(sentryUser)
        } else {
            SentrySDK.setUser(nil)
        }
        */

        if let user {
            print("[Sentry] Would set user: \(user.id)")
        } else {
            print("[Sentry] Would clear user")
        }
    }

    func reset() {
        // TODO: Uncomment after adding Sentry SDK
        /*
        SentrySDK.setUser(nil)
        SentrySDK.configureScope { scope in
            scope.clear()
        }
        */

        print("[Sentry] Would reset session")
    }

    // MARK: - Helpers

    private var releaseVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        return "\(bundleID)@\(version)+\(build)"
    }
}

// MARK: - Sentry Level Mapping

/*
// Uncomment after adding Sentry SDK
extension ErrorLevel {
    var sentryLevel: SentryLevel {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .fatal: return .fatal
        }
    }
}
*/
