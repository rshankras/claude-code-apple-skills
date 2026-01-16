import StoreKit
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Manages App Store review prompts with smart timing.
///
/// Usage:
/// ```swift
/// // On app launch/foreground
/// ReviewPromptManager.shared.incrementSession()
///
/// // After positive actions (task completion, etc.)
/// ReviewPromptManager.shared.recordPositiveAction()
/// ReviewPromptManager.shared.requestReviewIfAppropriate()
/// ```
///
/// Configure conditions by setting `ReviewPromptManager.shared.conditions`.
final class ReviewPromptManager {

    // MARK: - Singleton

    static let shared = ReviewPromptManager()

    private init() {}

    // MARK: - Configuration

    /// Conditions that must be met before showing a prompt.
    var conditions = ReviewPromptCondition.default

    #if DEBUG
    /// Set to `true` to always show prompt (debug only).
    var debugAlwaysShow = false
    #endif

    // MARK: - Session Tracking

    /// Increment session count. Call on app launch or foreground.
    func incrementSession() {
        ReviewPromptStorage.incrementSession()

        // Initialize install date on first session
        _ = ReviewPromptStorage.installDate
    }

    // MARK: - Action Tracking

    /// Record a positive user action.
    /// Call when user completes a task, achieves a goal, etc.
    func recordPositiveAction() {
        ReviewPromptStorage.recordPositiveAction()
    }

    // MARK: - Review Request

    /// Request a review if all conditions are met.
    ///
    /// Call this after positive actions, not on every interaction.
    /// The system decides whether to actually show the prompt.
    func requestReviewIfAppropriate() {
        #if DEBUG
        if debugAlwaysShow {
            requestReview()
            return
        }
        #endif

        guard shouldRequestReview() else { return }

        requestReview()
        ReviewPromptStorage.recordPromptShown()
    }

    /// Check if conditions are met for requesting a review.
    func shouldRequestReview() -> Bool {
        // Check platform eligibility first
        guard isAppStoreVersion() else { return false }

        return conditions.isSatisfied(
            sessions: ReviewPromptStorage.sessionCount,
            daysSinceInstall: ReviewPromptStorage.daysSinceInstall,
            positiveActions: ReviewPromptStorage.positiveActionCount,
            daysSinceLastPrompt: ReviewPromptStorage.daysSinceLastPrompt
        )
    }

    // MARK: - Platform Detection

    /// Check if app is running from App Store (not dev/TestFlight).
    private func isAppStoreVersion() -> Bool {
        #if DEBUG
        // Always allow in debug for testing
        return true
        #else
        // Check for App Store receipt
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        let receiptExists = FileManager.default.fileExists(atPath: receiptURL.path)

        #if os(macOS)
        // On macOS, sandboxReceipt indicates development/TestFlight
        if receiptURL.lastPathComponent == "sandboxReceipt" {
            return false
        }
        #endif

        return receiptExists
        #endif
    }

    // MARK: - Review Request Implementation

    private func requestReview() {
        #if os(iOS)
        requestReviewiOS()
        #elseif os(macOS)
        requestReviewmacOS()
        #endif
    }

    #if os(iOS)
    private func requestReviewiOS() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    #endif

    #if os(macOS)
    private func requestReviewmacOS() {
        SKStoreReviewController.requestReview()
    }
    #endif

    // MARK: - Alternative: Direct App Store Link

    /// Open App Store page for writing a review.
    /// Use for macOS direct distribution or custom UI.
    ///
    /// - Parameter appID: Your App Store app ID
    func openAppStoreReviewPage(appID: String) {
        guard let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") else {
            return
        }

        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    // MARK: - Debug/Testing

    /// Reset all tracking data. Use for testing.
    func reset() {
        ReviewPromptStorage.reset()
    }

    /// Get current tracking stats for debugging.
    var debugStats: String {
        """
        Sessions: \(ReviewPromptStorage.sessionCount)
        Days since install: \(ReviewPromptStorage.daysSinceInstall)
        Positive actions: \(ReviewPromptStorage.positiveActionCount)
        Days since last prompt: \(ReviewPromptStorage.daysSinceLastPrompt.map(String.init) ?? "never")
        Should prompt: \(shouldRequestReview())
        """
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

extension View {

    /// Track session on view appear and request review if appropriate.
    ///
    /// Usage:
    /// ```swift
    /// ContentView()
    ///     .trackSessionAndRequestReview()
    /// ```
    func trackSessionAndRequestReview() -> some View {
        onAppear {
            ReviewPromptManager.shared.incrementSession()
        }
    }

    /// Request review after a delay if conditions are met.
    /// Use after positive actions.
    ///
    /// - Parameter delay: Seconds to wait before requesting (default: 1.0)
    func requestReviewIfAppropriate(delay: TimeInterval = 1.0) -> some View {
        onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                ReviewPromptManager.shared.requestReviewIfAppropriate()
            }
        }
    }
}
