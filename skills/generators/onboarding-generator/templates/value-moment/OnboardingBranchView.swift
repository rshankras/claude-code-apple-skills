// DEFAULT ARCHITECTURE — value-moment-first onboarding.
//
// Screen 1 — the only screen every user sees. Replace the placeholder copy
// and iconography with your app's own hero content; keep the branch
// question itself framed around the value moment, not a generic "welcome."

import SwiftUI

struct OnboardingBranchView: View {
    let store: OnboardingStore

    // TODO: add your app's own router/state environment objects here — the
    // navigation side effects for BOTH choices belong in this view, never in
    // OnboardingStore (see onboarding-patterns.md's "why Router never
    // appears in the store" note).
    // @Environment(AppState.self) private var appState
    // @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                hero
                    .padding(.top, 24)

                // TODO: replace with a question framed around YOUR value
                // moment — e.g. "Got everything you need right now?" /
                // "Ready to import your data?" — not a generic "get started."
                Text("Can you do this right now?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 16) {
                    OnboardingOptionCard(
                        title: "Yes, right now",
                        subtitle: "Jump straight to the shortest path to your first result.",
                        action: chooseReadyNow
                    )
                    .accessibilityIdentifier("onboardingReadyNowCard")

                    OnboardingOptionCard(
                        title: "Not yet — planning ahead",
                        subtitle: "Set a plan for when you're ready.",
                        action: chooseLater
                    )
                    .accessibilityIdentifier("onboardingLaterCard")
                }

                Button {
                    store.skipOnboarding()
                    // TODO: reset your router's path here too, in the SAME
                    // synchronous action — nothing has navigated yet at this
                    // point, but keep this explicit so it stays correct if a
                    // future screen reorders the fork.
                } label: {
                    Text("Just looking around")
                        .foregroundStyle(.tertiary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("onboardingSkipButton")
                .accessibilityHint("Skips setup and goes straight to the app.")
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Your App Name")
                .font(.largeTitle.bold())
            Text("Your one-line value proposition.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func chooseReadyNow() {
        store.chooseReadyNow()
        // The root view's phase switch now shows
        // OnboardingReadyNowBridgeView automatically. If you deleted the
        // bridge phase because your ready-now action is a single
        // self-contained screen, navigate directly here instead.
    }

    private func chooseLater() {
        store.chooseLater()
    }
}

// MARK: - Option card (data-driven, reusable for any two-choice fork)

struct OnboardingOptionCard: View {
    let title: String
    let subtitle: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            // secondarySystemBackground, not tertiary — tertiary is pure
            // white in light mode and the card reads as invisible on a
            // systemBackground screen.
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Preview

#Preview {
    OnboardingBranchView(store: OnboardingStore(reminderService: PreviewReminderService()))
}

// Note: For macOS, replace `Color(uiColor:)` with `Color(nsColor:
// .controlBackgroundColor)` and adjust the layout for larger screens.
