import Foundation
// import FirebaseCrashlytics  // Uncomment after adding Firebase SDK
// import FirebaseCore

/// Firebase Crashlytics implementation of ErrorMonitoringService.
///
/// Prerequisites:
/// 1. Add Firebase SDK via SPM or CocoaPods
/// 2. Download GoogleService-Info.plist from Firebase Console
/// 3. Enable Crashlytics in Firebase Console
/// 4. Uncomment the imports and implementation below
///
/// Usage:
/// ```swift
/// let service: ErrorMonitoringService = CrashlyticsErrorMonitoring()
/// service.configure()  // Call at app launch
/// ```
final class CrashlyticsErrorMonitoring: ErrorMonitoringService, @unchecked Sendable {

    // MARK: - ErrorMonitoringService

    func configure() {
        // TODO: Uncomment after adding Firebase SDK
        /*
        // Configure Firebase (if not already done)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Enable collection (respect user preference)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

        // Set custom keys
        Crashlytics.crashlytics().setCustomValue(releaseVersion, forKey: "app_version")

        #if DEBUG
        // Disable in debug builds to avoid noise
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #endif
        */

        print("[Crashlytics] Would configure Firebase Crashlytics")
    }

    func captureError(_ error: Error, context: ErrorContext?) {
        // TODO: Uncomment after adding Firebase SDK
        /*
        let nsError = error as NSError

        // Record error with context
        Crashlytics.crashlytics().record(error: nsError, userInfo: buildUserInfo(context))

        // Also set custom keys from tags
        if let context {
            for (key, value) in context.tags {
                Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            }
        }
        */

        print("[Crashlytics] Would record error: \(error)")
    }

    func captureMessage(_ message: String, level: ErrorLevel) {
        // TODO: Uncomment after adding Firebase SDK
        /*
        // Crashlytics uses log() for non-fatal messages
        Crashlytics.crashlytics().log("\(level.rawValue.uppercased()): \(message)")

        // For fatal level, also record as exception
        if level == .fatal {
            let error = NSError(
                domain: "AppError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
            Crashlytics.crashlytics().record(error: error)
        }
        */

        print("[Crashlytics] Would log \(level.rawValue): \(message)")
    }

    func addBreadcrumb(_ breadcrumb: Breadcrumb) {
        // TODO: Uncomment after adding Firebase SDK
        /*
        // Crashlytics uses log() for breadcrumbs
        let message = "[\(breadcrumb.category)] \(breadcrumb.message)"
        Crashlytics.crashlytics().log(message)

        // Add data as custom keys if present
        if let data = breadcrumb.data {
            for (key, value) in data {
                Crashlytics.crashlytics().setCustomValue(
                    value,
                    forKey: "breadcrumb_\(key)"
                )
            }
        }
        */

        print("[Crashlytics] Would log breadcrumb: [\(breadcrumb.category)] \(breadcrumb.message)")
    }

    func setUser(_ user: MonitoringUser?) {
        // TODO: Uncomment after adding Firebase SDK
        /*
        if let user {
            Crashlytics.crashlytics().setUserID(user.id)

            if let segment = user.segment {
                Crashlytics.crashlytics().setCustomValue(segment, forKey: "user_segment")
            }

            if let username = user.username {
                Crashlytics.crashlytics().setCustomValue(username, forKey: "username")
            }
        } else {
            Crashlytics.crashlytics().setUserID("")
        }
        */

        if let user {
            print("[Crashlytics] Would set user ID: \(user.id)")
        } else {
            print("[Crashlytics] Would clear user ID")
        }
    }

    func reset() {
        // TODO: Uncomment after adding Firebase SDK
        /*
        Crashlytics.crashlytics().setUserID("")

        // Clear custom keys
        // Note: Crashlytics doesn't have a clear all method
        // Set known keys to empty
        Crashlytics.crashlytics().setCustomValue("", forKey: "user_segment")
        Crashlytics.crashlytics().setCustomValue("", forKey: "username")
        */

        print("[Crashlytics] Would reset user data")
    }

    // MARK: - Helpers

    private var releaseVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }

    private func buildUserInfo(_ context: ErrorContext?) -> [String: Any] {
        var userInfo: [String: Any] = [:]

        if let context {
            // Add tags
            for (key, value) in context.tags {
                userInfo["tag_\(key)"] = value
            }

            // Add extra (converted to strings for NSError userInfo)
            for (key, value) in context.extra {
                userInfo["extra_\(key)"] = String(describing: value)
            }
        }

        return userInfo
    }
}

// MARK: - Crashlytics Collection Control

extension CrashlyticsErrorMonitoring {

    /// Enable or disable crash collection (for user consent).
    func setCollectionEnabled(_ enabled: Bool) {
        // TODO: Uncomment after adding Firebase SDK
        /*
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
        */

        print("[Crashlytics] Would set collection enabled: \(enabled)")
    }

    /// Check if crash collection is enabled.
    var isCollectionEnabled: Bool {
        // TODO: Uncomment after adding Firebase SDK
        /*
        return Crashlytics.crashlytics().isCrashlyticsCollectionEnabled()
        */

        return true
    }
}
