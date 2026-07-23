// DEFAULT ARCHITECTURE — value-moment-first onboarding.
//
// Root swap, not fullScreenCover/sheet (onboarding-patterns.md Lesson 1) — a
// cover flashes real content underneath for a frame and VoiceOver announces
// it first. This view is swapped in for the app's real root.

import SwiftUI

/// The root-swap target. A tiny `@ViewBuilder`-free `switch` over
/// `OnboardingPhase` — deliberately NOT a `@ViewBuilder` method with many
/// cases (that pattern hangs the type checker past ~5 cases); each case
/// delegates to its own `View` struct instead.
///
/// No `NavigationStack` of its own: this view IS a root, never a pushed
/// destination — never nest a navigation container inside a view that's
/// itself the thing being swapped in.
///
/// Usage in your app's actual root view:
/// ```swift
/// struct ContentView: View {
///     @Environment(AppState.self) private var appState   // your app's durable state
///     @State private var onboardingStore = OnboardingStore()
///
///     // Phase-first gating (Lesson 2) — check the in-memory state machine
///     // FIRST; the durable flag is only the survives-relaunch fallback.
///     private var showOnboarding: Bool {
///         if appState.onboardingCompleted { return false }
///         switch onboardingStore.phase {
///         case .completed, .awaitingHandoffReturn: return false
///         default: return true
///         }
///     }
///
///     var body: some View {
///         Group {
///             if showOnboarding {
///                 OnboardingRootView(store: onboardingStore)
///             } else {
///                 RealAppRootView()   // whatever your app's true root already is
///             }
///         }
///         .onChange(of: onboardingStore.phase) { _, newPhase in
///             guard newPhase == .completed else { return }
///             appState.onboardingCompleted = true   // durable fallback catches up
///         }
///     }
/// }
/// ```
struct OnboardingRootView: View {
    let store: OnboardingStore

    var body: some View {
        Group {
            switch store.phase {
            case .branch:
                OnboardingBranchView(store: store)
            case .readyNowBridge:
                OnboardingReadyNowBridgeView(store: store)
            case .intention:
                OnboardingIntentionView(store: store)
            case .reminder:
                OnboardingReminderView(store: store)
            case .awaitingHandoffReturn, .completed:
                // Never actually shown in practice — the parent routes away
                // (see the usage note above) before this view is even
                // constructed for either phase. Kept only so the switch
                // stays exhaustive with no `default` masking a future
                // `OnboardingPhase` case that forgets a screen.
                Color.clear
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingRootView(store: OnboardingStore(reminderService: PreviewReminderService()))
}

/// A no-op reminder double so previews never touch the real notification
/// permission system.
@MainActor
final class PreviewReminderService: ReminderScheduling {
    func requestAndSchedule(title: String, body: String, fireDate: Date) async -> Bool { true }
}
