import Foundation

/// Conditions that must be met before showing a review prompt.
///
/// Configure these thresholds based on your app's usage patterns.
/// More engaged users are more likely to leave positive reviews.
struct ReviewPromptCondition {

    /// Minimum number of app sessions before prompting.
    /// Default: 3 (user has returned multiple times)
    let minimumSessions: Int

    /// Minimum days since first launch before prompting.
    /// Default: 3 (user has had time to evaluate)
    let minimumDays: Int

    /// Minimum positive actions before prompting.
    /// Default: 5 (user has accomplished things)
    let minimumPositiveActions: Int

    /// Minimum days between review prompts.
    /// Default: 60 (Apple limits to 3/year anyway)
    let cooldownDays: Int

    /// Default conditions suitable for most apps.
    static let `default` = ReviewPromptCondition(
        minimumSessions: 3,
        minimumDays: 3,
        minimumPositiveActions: 5,
        cooldownDays: 60
    )

    /// More conservative conditions for apps with longer engagement cycles.
    static let conservative = ReviewPromptCondition(
        minimumSessions: 5,
        minimumDays: 7,
        minimumPositiveActions: 10,
        cooldownDays: 90
    )

    /// More aggressive conditions for apps with quick value delivery.
    /// Use with caution - may annoy users if value isn't immediately clear.
    static let eager = ReviewPromptCondition(
        minimumSessions: 2,
        minimumDays: 1,
        minimumPositiveActions: 3,
        cooldownDays: 45
    )
}

// MARK: - Condition Checking

extension ReviewPromptCondition {

    /// Check if all conditions are met.
    func isSatisfied(
        sessions: Int,
        daysSinceInstall: Int,
        positiveActions: Int,
        daysSinceLastPrompt: Int?
    ) -> Bool {
        // Check minimum thresholds
        guard sessions >= minimumSessions else { return false }
        guard daysSinceInstall >= minimumDays else { return false }
        guard positiveActions >= minimumPositiveActions else { return false }

        // Check cooldown
        if let daysSinceLastPrompt = daysSinceLastPrompt {
            guard daysSinceLastPrompt >= cooldownDays else { return false }
        }

        return true
    }
}
