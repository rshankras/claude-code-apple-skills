// DEFAULT ARCHITECTURE — value-moment-first onboarding.
//
// Later branch, step 1 — "When can you do this?" ONE decision (which chip),
// with an optional fine-tuning control WITHIN that choice — never a second
// decision (onboarding-patterns.md's "one decision per screen" rule). Every
// chip resolves to a concrete date+time via
// `OnboardingStore.defaultDate(for:now:)` (pure, unit-tested); this view
// only seeds its `@State` from that function and lets the user adjust the
// time before confirming.

import SwiftUI

struct OnboardingIntentionView: View {
    let store: OnboardingStore

    @State private var selectedChoice: OnboardingDateChoice?
    @State private var chosenDate: Date = .now
    @State private var customDay: Date = .now

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // TODO: phrase this around your actual "later" scenario —
                // e.g. "When will your data be ready?" / "When's the event?"
                Text("When can you do this?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                VStack(spacing: 12) {
                    ForEach(OnboardingDateChoice.allCases, id: \.self) { choice in
                        OnboardingDateChoiceChip(
                            choice: choice,
                            isSelected: selectedChoice == choice,
                            action: { select(choice) }
                        )
                    }
                }

                if selectedChoice != nil {
                    fineTuning
                    confirmButton
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var fineTuning: some View {
        VStack(alignment: .leading, spacing: 14) {
            if selectedChoice == .custom {
                DatePicker("Date", selection: $customDay, in: Date.now..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .onChange(of: customDay) { _, newDay in
                        chosenDate = OnboardingStore.defaultDate(for: .custom, customDate: newDay, now: .now)
                    }
                    .accessibilityIdentifier("onboardingCustomDatePicker")
            }
            DatePicker("Time", selection: $chosenDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .accessibilityIdentifier("onboardingTimeWheel")
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var confirmButton: some View {
        Button("Continue") {
            store.confirmIntentionDate(chosenDate)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("onboardingConfirmDateButton")
    }

    private func select(_ choice: OnboardingDateChoice) {
        selectedChoice = choice
        chosenDate = OnboardingStore.defaultDate(for: choice, customDate: customDay, now: .now)
    }
}

// MARK: - Date chip

private extension OnboardingDateChoice {
    var title: String {
        switch self {
        case .tonight:  return "Tonight"
        case .tomorrow: return "Tomorrow"
        case .weekend:  return "This weekend"
        case .custom:   return "Pick a date"
        }
    }
}

struct OnboardingDateChoiceChip: View {
    let choice: OnboardingDateChoice
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(choice.title)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(
                isSelected ? Color.accentColor.opacity(0.15) : Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("onboardingDateChip.\(choice.title)")
    }
}

// MARK: - Preview

#Preview {
    let store = OnboardingStore(reminderService: PreviewReminderService())
    store.chooseLater()
    return OnboardingIntentionView(store: store)
}
