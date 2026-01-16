import SwiftUI

/// Individual page view for onboarding.
///
/// Displays the content for a single onboarding step with
/// icon, title, and description.
struct OnboardingPageView: View {
    let page: OnboardingPage

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundStyle(page.accentColor)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            // Text Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.description)")
    }
}

// MARK: - Preview

#Preview {
    OnboardingPageView(page: OnboardingPage.samplePages[0])
}

#Preview("Dark Mode") {
    OnboardingPageView(page: OnboardingPage.samplePages[1])
        .preferredColorScheme(.dark)
}
