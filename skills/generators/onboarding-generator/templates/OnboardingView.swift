import SwiftUI

/// Main onboarding view with paged navigation.
///
/// Usage:
/// ```swift
/// // Option 1: Full screen cover
/// .fullScreenCover(isPresented: $showOnboarding) {
///     OnboardingView()
/// }
///
/// // Option 2: View modifier (recommended)
/// ContentView()
///     .onboarding()
/// ```
struct OnboardingView: View {

    // MARK: - Configuration

    /// The onboarding pages to display.
    /// Customize this with your app's content.
    private let pages = OnboardingPage.samplePages

    /// Whether to show a skip button.
    private let showSkipButton = true

    // MARK: - State

    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            if showSkipButton {
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundStyle(.secondary)
                    .padding()
                }
            }

            // Pages
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Get Started button (shown on last page)
            VStack {
                if currentPage == pages.count - 1 {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(height: 80)
            .animation(.easeInOut, value: currentPage)

            // Safe area padding
            Spacer()
                .frame(height: 20)
        }
        .background(Color(uiColor: .systemBackground))
        .interactiveDismissDisabled()  // Prevent accidental dismiss
    }

    // MARK: - Actions

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}

#Preview("Dark Mode") {
    OnboardingView()
        .preferredColorScheme(.dark)
}

// Note: For macOS, replace `Color(uiColor:)` with `Color(nsColor:)`
// and consider adjusting the layout for larger screens.
