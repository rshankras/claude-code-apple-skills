import Foundation

/// Onboarding persistence and configuration.
///
/// Use `hasCompletedOnboarding` to check/set onboarding status.
/// Increment `currentOnboardingVersion` to show onboarding again
/// after a major app update.
enum OnboardingStorage {

    // MARK: - Configuration

    /// The current onboarding version.
    /// Increment this to show onboarding again after major updates.
    private static let currentOnboardingVersion = 1

    /// The UserDefaults key for storing completion status.
    private static let completedVersionKey = "onboardingCompletedVersion"

    // MARK: - Public API

    /// Whether the user has completed onboarding for the current version.
    ///
    /// Set to `true` when onboarding is completed.
    /// Returns `false` if the user hasn't completed onboarding
    /// or if a new onboarding version is available.
    static var hasCompletedOnboarding: Bool {
        get {
            let completedVersion = UserDefaults.standard.integer(forKey: completedVersionKey)
            return completedVersion >= currentOnboardingVersion
        }
        set {
            let version = newValue ? currentOnboardingVersion : 0
            UserDefaults.standard.set(version, forKey: completedVersionKey)
        }
    }

    /// Reset onboarding status (for testing/debugging).
    static func reset() {
        UserDefaults.standard.removeObject(forKey: completedVersionKey)
    }
}

// MARK: - Usage Example

/*

 // Check if should show onboarding:
 if !OnboardingStorage.hasCompletedOnboarding {
     showOnboarding = true
 }

 // Mark as completed:
 OnboardingStorage.hasCompletedOnboarding = true

 // Reset for testing:
 OnboardingStorage.reset()

 // To show onboarding again after app update:
 // 1. Increment `currentOnboardingVersion` above
 // 2. Users will see onboarding again on next launch

 */
