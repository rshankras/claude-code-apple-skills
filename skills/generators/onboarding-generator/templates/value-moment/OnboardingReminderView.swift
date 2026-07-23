// DEFAULT ARCHITECTURE — value-moment-first onboarding.
//
// Later branch, step 2 — the reminder ask, phrased in the user's OWN plan
// ("want a nudge at <their chosen moment>?"), with the notification
// permission requested RIGHT HERE — never earlier, never cold at launch
// (onboarding-patterns.md Lesson 6 / OnboardingReminderService). "No thanks"
// proceeds without ever touching the permission system. Either way the plan
// is already saved (`OnboardingStore.confirmIntentionDate` ran on the
// previous screen) — this step can only ADD a nudge, never take the plan
// away.

import SwiftUI

struct OnboardingReminderView: View {
    let store: OnboardingStore

    // TODO: add your app's router if you need to reset its path here before
    // completion hands off — see the note in `remindMe()`/`noThanks()`.
    // @Environment(Router.self) private var router

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Text("We'll have it ready.")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if let intentionDate = store.intentionDate {
                Text("Want a nudge \(intentionDate.formatted(nudgeFormat))?")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                Button {
                    remindMe()
                } label: {
                    if isRequesting {
                        ProgressView()
                    } else {
                        Text("Remind me")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequesting)
                .accessibilityIdentifier("onboardingRemindMeButton")

                Button("No thanks") {
                    noThanks()
                }
                .buttonStyle(.bordered)
                .disabled(isRequesting)
                .accessibilityIdentifier("onboardingNoThanksButton")
            }
            .padding(.top, 24)
        }
        .padding(24)
    }

    private var nudgeFormat: Date.FormatStyle {
        .dateTime.weekday(.wide).month(.abbreviated).day().hour().minute()
    }

    private func remindMe() {
        // TODO: reset your router's path to empty here (before the async
        // work below resolves) so that once `store.phase` reaches
        // `.completed`, the real app lands cleanly on its home screen —
        // never wherever this flow's detours left a NavigationStack.
        isRequesting = true
        Task {
            await store.requestReminder()
            isRequesting = false
        }
    }

    private func noThanks() {
        // TODO: same router-path reset as `remindMe()`.
        store.declineReminder()
    }
}

// MARK: - Preview

#Preview {
    let store = OnboardingStore(reminderService: PreviewReminderService())
    store.chooseLater()
    store.confirmIntentionDate(.now.addingTimeInterval(3 * 24 * 60 * 60))
    return OnboardingReminderView(store: store)
}
