import Foundation

/// Context information for error reports.
///
/// Includes breadcrumbs, tags, and extra data to help debug issues.
///
/// Usage:
/// ```swift
/// let context = ErrorContext(
///     tags: ["feature": "checkout", "step": "payment"],
///     extra: ["cart_items": 3, "total": 99.99]
/// )
/// errorMonitoring.captureError(error, context: context)
/// ```
struct ErrorContext: Sendable {

    /// Indexed tags for filtering (string values only).
    var tags: [String: String]

    /// Additional data for debugging.
    var extra: [String: any Sendable]

    /// Custom fingerprint for error grouping.
    /// Errors with the same fingerprint are grouped together.
    var fingerprint: [String]?

    init(
        tags: [String: String] = [:],
        extra: [String: any Sendable] = [:],
        fingerprint: [String]? = nil
    ) {
        self.tags = tags
        self.extra = extra
        self.fingerprint = fingerprint
    }
}

// MARK: - Builder Pattern

extension ErrorContext {

    /// Add a tag.
    func tag(_ key: String, _ value: String) -> ErrorContext {
        var copy = self
        copy.tags[key] = value
        return copy
    }

    /// Add extra data.
    func with(_ key: String, _ value: any Sendable) -> ErrorContext {
        var copy = self
        copy.extra[key] = value
        return copy
    }

    /// Set custom fingerprint.
    func fingerprinted(_ values: String...) -> ErrorContext {
        var copy = self
        copy.fingerprint = values
        return copy
    }
}

// MARK: - Breadcrumb

/// A breadcrumb represents an event that happened before an error.
///
/// Breadcrumbs provide a trail of events leading to errors,
/// helping with debugging.
///
/// Usage:
/// ```swift
/// // UI event
/// let breadcrumb = Breadcrumb(
///     category: "ui",
///     message: "User tapped checkout button"
/// )
///
/// // Network event
/// let breadcrumb = Breadcrumb(
///     category: "network",
///     message: "API request completed",
///     data: ["endpoint": "/api/orders", "status": "200"]
/// )
/// ```
struct Breadcrumb: Sendable {

    /// When the event occurred.
    let timestamp: Date

    /// Category of the event (e.g., "navigation", "ui", "network", "user").
    let category: String

    /// Human-readable description.
    let message: String

    /// Severity level.
    let level: ErrorLevel

    /// Additional data.
    let data: [String: String]?

    init(
        category: String,
        message: String,
        level: ErrorLevel = .info,
        data: [String: String]? = nil
    ) {
        self.timestamp = .now
        self.category = category
        self.message = message
        self.level = level
        self.data = data
    }
}

// MARK: - Common Breadcrumb Categories

extension Breadcrumb {

    /// Navigation breadcrumb (screen changes).
    static func navigation(_ screenName: String) -> Breadcrumb {
        Breadcrumb(
            category: "navigation",
            message: "Viewed \(screenName)"
        )
    }

    /// UI interaction breadcrumb.
    static func ui(_ action: String, element: String? = nil) -> Breadcrumb {
        var data: [String: String]? = nil
        if let element {
            data = ["element": element]
        }
        return Breadcrumb(
            category: "ui",
            message: action,
            data: data
        )
    }

    /// Network request breadcrumb.
    static func network(
        method: String,
        url: String,
        statusCode: Int? = nil
    ) -> Breadcrumb {
        var data = ["method": method, "url": url]
        if let statusCode {
            data["status"] = String(statusCode)
        }
        return Breadcrumb(
            category: "network",
            message: "\(method) \(url)",
            data: data
        )
    }

    /// User action breadcrumb.
    static func user(_ action: String, data: [String: String]? = nil) -> Breadcrumb {
        Breadcrumb(
            category: "user",
            message: action,
            data: data
        )
    }

    /// State change breadcrumb.
    static func state(_ description: String, data: [String: String]? = nil) -> Breadcrumb {
        Breadcrumb(
            category: "state",
            message: description,
            data: data
        )
    }

    /// Error breadcrumb (for non-fatal errors).
    static func error(_ description: String) -> Breadcrumb {
        Breadcrumb(
            category: "error",
            message: description,
            level: .error
        )
    }
}

// MARK: - SwiftUI Navigation Tracking

import SwiftUI

extension View {

    /// Automatically add navigation breadcrumb when view appears.
    func trackScreen(_ name: String) -> some View {
        onAppear {
            Task { @MainActor in
                ErrorMonitoring.shared.service.addBreadcrumb(.navigation(name))
            }
        }
    }
}
