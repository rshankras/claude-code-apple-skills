// DEFAULT ARCHITECTURE — value-moment-first onboarding.
//
// Only needed when the ready-now action hands off into an EXISTING
// multi-screen flow rather than being a single self-contained screen
// (onboarding-patterns.md Lesson 3 + Lesson 4). If your value moment is
// reachable in one screen, DELETE this file, `.readyNowBridge` and
// `.awaitingHandoffReturn` from `OnboardingPhase`, and drive completion
// directly from `OnboardingBranchView.chooseReadyNow()`.
//
// This screen's only job is the ONE tap that hands off — never duplicate
// any part of the real feature's UI here. Reuse the app's EXISTING entry
// point into that feature (the same one a returning user's home screen
// already uses), not a new onboarding-only copy.

import SwiftUI

struct OnboardingReadyNowBridgeView: View {
    let store: OnboardingStore

    // TODO: add your app's real router/state environment objects.
    // @Environment(AppState.self) private var appState
    // @Environment(Router.self) private var router

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🎬")
                .font(.system(size: 64))
                .accessibilityHidden(true)

            // TODO: name the real thing that's about to happen — not a
            // generic "let's get started."
            Text("Let's get you there")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("One tap and you'll be doing the real thing — not a preview of it.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Let's go") {
                beginHandoff()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            .accessibilityIdentifier("onboardingBeginHandoffButton")

            Spacer()
        }
        .padding(24)
    }

    private func beginHandoff() {
        store.beginHandoff()

        // TODO — the following must run in ONE synchronous action (no
        // `await` in between), so there is no frame where the store says
        // "showing the real app" but the router hasn't caught up yet:
        //
        // 1. Preset the router's path so the real feature is already
        //    showing the instant it mounts — never a flash of the app's
        //    home screen:
        //      router.presetPathIntoRealFeature(appState: appState, in: modelContext)
        //
        // 2. Arm the one-shot completion callback the real feature's flow
        //    resolves through when it finishes (Lesson 4):
        //      router.onRealFeatureFinished = { outcome in
        //          store.handoffReturned(valueMomentReached: outcome.reachedValueMoment)
        //      }
        //
        // 3. The wander-off safety net lives on the PARENT view that hosts
        //    the router's path (your app's ContentView-equivalent), not
        //    here — see OnboardingRootView.swift's usage note:
        //      .onChange(of: router.path) { _, newPath in
        //          guard store.phase == .awaitingHandoffReturn, newPath.isEmpty else { return }
        //          store.abandonToHome()
        //      }
    }
}

// MARK: - Preview

#Preview {
    let store = OnboardingStore(reminderService: PreviewReminderService())
    store.chooseReadyNow()
    return OnboardingReadyNowBridgeView(store: store)
}
