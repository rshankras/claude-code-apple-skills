import SwiftUI

/// View modifier for easy onboarding integration.
///
/// Usage:
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .onboarding()
///         }
///     }
/// }
/// ```
///
/// The onboarding will automatically show on first launch
/// and won't appear again after completion.
struct OnboardingModifier: ViewModifier {
    @State private var showOnboarding = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Check on appear to handle app state restoration
                if !OnboardingStorage.hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
    }
}

// MARK: - View Extension

extension View {

    /// Shows onboarding on first app launch.
    ///
    /// The onboarding is presented as a full screen cover and
    /// won't appear again after completion.
    ///
    /// Usage:
    /// ```swift
    /// ContentView()
    ///     .onboarding()
    /// ```
    func onboarding() -> some View {
        modifier(OnboardingModifier())
    }
}

// MARK: - Preview

#Preview("With Onboarding") {
    // Reset for preview
    let _ = OnboardingStorage.reset()

    return Text("Main Content")
        .onboarding()
}
