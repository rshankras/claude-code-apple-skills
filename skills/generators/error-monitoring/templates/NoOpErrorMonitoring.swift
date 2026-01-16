import Foundation

/// No-op implementation of ErrorMonitoringService.
///
/// Use this for:
/// - Debug/development builds
/// - Users who opt out of crash reporting
/// - Unit tests
/// - Privacy-focused mode
///
/// Usage:
/// ```swift
/// let service: ErrorMonitoringService = NoOpErrorMonitoring()
/// service.captureError(error)  // Does nothing
/// ```
final class NoOpErrorMonitoring: ErrorMonitoringService, Sendable {

    // MARK: - Configuration

    func configure() {
        // No-op
        #if DEBUG
        print("[ErrorMonitoring] NoOp mode - errors will not be reported")
        #endif
    }

    // MARK: - Error Capture

    func captureError(_ error: Error, context: ErrorContext?) {
        #if DEBUG
        print("[ErrorMonitoring] Would capture error: \(error)")
        if let context {
            if !context.tags.isEmpty {
                print("  Tags: \(context.tags)")
            }
        }
        #endif
    }

    func captureMessage(_ message: String, level: ErrorLevel) {
        #if DEBUG
        print("[ErrorMonitoring] Would capture \(level.rawValue): \(message)")
        #endif
    }

    // MARK: - Breadcrumbs

    func addBreadcrumb(_ breadcrumb: Breadcrumb) {
        #if DEBUG
        print("[ErrorMonitoring] Breadcrumb: [\(breadcrumb.category)] \(breadcrumb.message)")
        #endif
    }

    // MARK: - User

    func setUser(_ user: MonitoringUser?) {
        #if DEBUG
        if let user {
            print("[ErrorMonitoring] Would set user: \(user.id)")
        } else {
            print("[ErrorMonitoring] Would clear user")
        }
        #endif
    }

    func reset() {
        #if DEBUG
        print("[ErrorMonitoring] Would reset session")
        #endif
    }
}

// MARK: - Debug Error Monitoring

#if DEBUG
/// Debug implementation that prints all events to console.
///
/// Useful during development to verify error capture is working.
final class DebugErrorMonitoring: ErrorMonitoringService, Sendable {

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    func configure() {
        print("🔧 [ErrorMonitoring] Debug mode configured")
    }

    func captureError(_ error: Error, context: ErrorContext?) {
        let timestamp = dateFormatter.string(from: .now)
        print("🔴 [\(timestamp)] ERROR: \(error)")
        print("   Type: \(type(of: error))")

        if let localizedError = error as? LocalizedError {
            if let description = localizedError.errorDescription {
                print("   Description: \(description)")
            }
            if let reason = localizedError.failureReason {
                print("   Reason: \(reason)")
            }
            if let recovery = localizedError.recoverySuggestion {
                print("   Recovery: \(recovery)")
            }
        }

        if let context {
            if !context.tags.isEmpty {
                print("   Tags: \(context.tags)")
            }
            if !context.extra.isEmpty {
                print("   Extra: \(context.extra)")
            }
        }
    }

    func captureMessage(_ message: String, level: ErrorLevel) {
        let timestamp = dateFormatter.string(from: .now)
        let emoji = switch level {
        case .debug: "🔍"
        case .info: "ℹ️"
        case .warning: "⚠️"
        case .error: "🔴"
        case .fatal: "💀"
        }
        print("\(emoji) [\(timestamp)] \(level.rawValue.uppercased()): \(message)")
    }

    func addBreadcrumb(_ breadcrumb: Breadcrumb) {
        let timestamp = dateFormatter.string(from: breadcrumb.timestamp)
        print("🍞 [\(timestamp)] [\(breadcrumb.category)] \(breadcrumb.message)")
        if let data = breadcrumb.data, !data.isEmpty {
            print("   Data: \(data)")
        }
    }

    func setUser(_ user: MonitoringUser?) {
        if let user {
            print("👤 Set user: id=\(user.id), segment=\(user.segment ?? "none")")
        } else {
            print("👤 Cleared user")
        }
    }

    func reset() {
        print("🔄 Session reset")
    }
}
#endif
