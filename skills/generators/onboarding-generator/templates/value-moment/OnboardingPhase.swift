// DEFAULT ARCHITECTURE — value-moment-first onboarding. See
// onboarding-patterns.md for the philosophy and the nine implementation
// lessons this template set encodes.

import Foundation

/// The onboarding state model — one enum case per screen, one decision per
/// case (onboarding-patterns.md's "one decision per screen" rule). Customize
/// the cases to match your app's actual value moment; keep that rule intact
/// when you do.
enum OnboardingPhase: Equatable {
    /// Screen 1 — the only screen every user sees: the value-moment framing
    /// + the ready-now/later fork.
    case branch

    /// Ready-now branch, optional bridge screen before the hand-off into an
    /// existing multi-screen flow. Delete this case (and
    /// `OnboardingReadyNowBridgeView.swift`) if your ready-now action is a
    /// single self-contained screen with no hand-off — call `complete()`
    /// straight from `OnboardingStore.chooseReadyNow()` instead.
    case readyNowBridge

    /// Ready-now branch — the hand-off is in flight; the REAL app is shown,
    /// not onboarding (see `OnboardingRootView`'s usage note). Resolved via
    /// either `OnboardingStore.handoffReturned(valueMomentReached:)` (a real
    /// outcome) or `.abandonToHome()` (the wander-off safety net) — never a
    /// passive poll.
    case awaitingHandoffReturn

    /// Later branch, step 1 — capture a concrete "when."
    case intention

    /// Later branch, step 2 — the reminder + its in-context permission ask.
    case reminder

    /// Onboarding is over. Terminal — every `OnboardingStore` transition
    /// method is a no-op once this is reached (the idempotence guarantee
    /// that makes the wander-off safety net safe to call from anywhere).
    case completed
}

enum OnboardingBranch: Equatable {
    case readyNow
    case later
}

/// The later-branch chip choices for "when." Extend or replace with whatever
/// granularity your value moment needs — the point is a CONCRETE choice a
/// user taps, never a free-text "someday."
enum OnboardingDateChoice: Hashable, CaseIterable {
    case tonight
    case tomorrow
    case weekend
    case custom
}
