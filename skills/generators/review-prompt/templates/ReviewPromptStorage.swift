import Foundation

/// Persistent storage for review prompt tracking.
///
/// Tracks session count, install date, positive actions, and last prompt date
/// to determine when to show review prompts.
enum ReviewPromptStorage {

    // MARK: - Keys

    private enum Keys {
        static let sessionCount = "reviewPrompt.sessionCount"
        static let installDate = "reviewPrompt.installDate"
        static let positiveActionCount = "reviewPrompt.positiveActionCount"
        static let lastPromptDate = "reviewPrompt.lastPromptDate"
    }

    // MARK: - Session Count

    /// Number of app sessions (launches/foreground events).
    static var sessionCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.sessionCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.sessionCount) }
    }

    /// Increment session count. Call on app launch or foreground.
    static func incrementSession() {
        sessionCount += 1
    }

    // MARK: - Install Date

    /// Date of first app launch.
    static var installDate: Date {
        get {
            if let date = UserDefaults.standard.object(forKey: Keys.installDate) as? Date {
                return date
            }
            // First access - set to now
            let now = Date()
            UserDefaults.standard.set(now, forKey: Keys.installDate)
            return now
        }
    }

    /// Days since first launch.
    static var daysSinceInstall: Int {
        Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
    }

    // MARK: - Positive Actions

    /// Count of positive user actions (task completions, etc.).
    static var positiveActionCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.positiveActionCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.positiveActionCount) }
    }

    /// Record a positive action. Call when user accomplishes something.
    static func recordPositiveAction() {
        positiveActionCount += 1
    }

    // MARK: - Last Prompt Date

    /// Date of last review prompt attempt.
    static var lastPromptDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastPromptDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastPromptDate) }
    }

    /// Days since last prompt (nil if never prompted).
    static var daysSinceLastPrompt: Int? {
        guard let lastDate = lastPromptDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }

    /// Record that a prompt was shown.
    static func recordPromptShown() {
        lastPromptDate = Date()
    }

    // MARK: - Reset (Testing)

    /// Reset all tracking data. Use for testing.
    static func reset() {
        UserDefaults.standard.removeObject(forKey: Keys.sessionCount)
        UserDefaults.standard.removeObject(forKey: Keys.installDate)
        UserDefaults.standard.removeObject(forKey: Keys.positiveActionCount)
        UserDefaults.standard.removeObject(forKey: Keys.lastPromptDate)
    }
}
