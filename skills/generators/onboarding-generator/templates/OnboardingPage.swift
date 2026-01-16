import SwiftUI

/// Data model for an onboarding page.
///
/// Customize the pages array in OnboardingView or OnboardingStorage
/// with your app's content.
struct OnboardingPage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String  // SF Symbol name or asset name
    let accentColor: Color

    init(
        title: String,
        description: String,
        imageName: String,
        accentColor: Color = .accentColor
    ) {
        self.title = title
        self.description = description
        self.imageName = imageName
        self.accentColor = accentColor
    }
}

// MARK: - Sample Pages

extension OnboardingPage {

    /// Sample pages for preview and testing.
    /// Replace with your actual onboarding content.
    static let samplePages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome",
            description: "Thank you for downloading our app. Let's get you started with a quick tour.",
            imageName: "hand.wave.fill",
            accentColor: .blue
        ),
        OnboardingPage(
            title: "Stay Organized",
            description: "Keep track of everything that matters to you in one place.",
            imageName: "checklist",
            accentColor: .green
        ),
        OnboardingPage(
            title: "Sync Everywhere",
            description: "Your data syncs seamlessly across all your Apple devices.",
            imageName: "icloud.fill",
            accentColor: .purple
        ),
        OnboardingPage(
            title: "Get Started",
            description: "You're all set! Tap the button below to start using the app.",
            imageName: "arrow.right.circle.fill",
            accentColor: .orange
        )
    ]
}
