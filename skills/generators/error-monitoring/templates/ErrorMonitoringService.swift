import Foundation
import SwiftUI

/// Protocol for error monitoring services.
///
/// Provides a consistent interface for capturing errors, messages,
/// and breadcrumbs across different providers (Sentry, Crashlytics, etc.).
///
/// Usage:
/// ```swift
/// // Capture an error
/// errorMonitoring.captureError(error)
///
/// // Capture with context
/// let context = ErrorContext(tags: ["feature": "checkout"])
/// errorMonitoring.captureError(error, context: context)
///
/// // Add breadcrumb
/// errorMonitoring.addBreadcrumb(
///     Breadcrumb(category: "navigation", message: "Opened settings")
/// )
/// ```
protocol ErrorMonitoringService: Sendable {

    /// Configure the error monitoring service.
    /// Call once at app launch.
    func configure()

    /// Capture an error with optional context.
    func captureError(_ error: Error, context: ErrorContext?)

    /// Capture a message with severity level.
    func captureMessage(_ message: String, level: ErrorLevel)

    /// Add a breadcrumb for debugging context.
    func addBreadcrumb(_ breadcrumb: Breadcrumb)

    /// Set the current user (use anonymized IDs only).
    func setUser(_ user: MonitoringUser?)

    /// Clear user and session data.
    /// Call on logout.
    func reset()
}

// MARK: - Default Implementations

extension ErrorMonitoringService {

    /// Capture an error without additional context.
    func captureError(_ error: Error) {
        captureError(error, context: nil)
    }
}

// MARK: - Error Level

/// Severity level for captured messages.
enum ErrorLevel: String, Sendable, CaseIterable {
    case debug      // Development debugging
    case info       // Informational
    case warning    // Unexpected but not critical
    case error      // Error affecting user experience
    case fatal      // Critical failure / crash
}

// MARK: - Monitoring User

/// User information for error reports.
/// Use anonymized IDs only - never include PII.
struct MonitoringUser: Sendable, Equatable {
    /// Anonymized user identifier (hash of real ID).
    let id: String

    /// Optional username (if user consents to sharing).
    let username: String?

    /// User segment (e.g., "free", "premium").
    let segment: String?

    init(id: String, username: String? = nil, segment: String? = nil) {
        self.id = id
        self.username = username
        self.segment = segment
    }
}

// MARK: - Central Access

/// Central access point for error monitoring.
///
/// Usage:
/// ```swift
/// // At app launch
/// ErrorMonitoring.shared.configure()
///
/// // Capture errors
/// ErrorMonitoring.shared.service.captureError(error)
/// ```
@MainActor
final class ErrorMonitoring {

    static let shared = ErrorMonitoring()

    /// The active error monitoring service.
    /// Change this to swap providers:
    /// - `SentryErrorMonitoring()` for Sentry
    /// - `CrashlyticsErrorMonitoring()` for Firebase
    /// - `NoOpErrorMonitoring()` for testing/privacy
    #if DEBUG
    let service: ErrorMonitoringService = NoOpErrorMonitoring()
    #else
    let service: ErrorMonitoringService = NoOpErrorMonitoring()
    // TODO: Replace with your provider:
    // let service: ErrorMonitoringService = SentryErrorMonitoring()
    #endif

    private init() {}

    /// Configure error monitoring. Call once at app launch.
    func configure() {
        service.configure()
    }
}

// MARK: - Environment Key

private struct ErrorMonitoringKey: EnvironmentKey {
    static let defaultValue: ErrorMonitoringService = NoOpErrorMonitoring()
}

extension EnvironmentValues {
    /// Error monitoring service for capturing errors.
    var errorMonitoring: ErrorMonitoringService {
        get { self[ErrorMonitoringKey.self] }
        set { self[ErrorMonitoringKey.self] = newValue }
    }
}
