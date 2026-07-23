// DEFAULT ARCHITECTURE — value-moment-first onboarding.

import Foundation
import OSLog

/// Plain `@Observable` coordinator — **not** a View. Owns only BUSINESS
/// state (phase, branch, the captured "when," whether a reminder landed);
/// the actual navigation side effects (routing into the real feature,
/// marking the app's durable "onboarding completed" flag, presetting a
/// router's path so there's never a flash of the real home screen) belong to
/// the SwiftUI screens themselves, which already sit inside the environment
/// that owns your app's router/state. Keeping navigation OUT of this file is
/// what makes the whole state machine unit-testable with nothing but
/// Foundation — mirror whatever store pattern the rest of the app already
/// uses for this class.
@MainActor
@Observable
final class OnboardingStore {

    // MARK: - State

    private(set) var phase: OnboardingPhase = .branch
    private(set) var branch: OnboardingBranch?
    private(set) var intentionDate: Date?
    private(set) var reminderScheduled = false
    private(set) var reminderDenied = false

    // MARK: - Dependencies (injectable — the unit-test seam)

    private let clock: () -> Date
    private let reminderService: ReminderScheduling
    private let defaults: UserDefaults

    private static let log = Logger(subsystem: "com.yourapp", category: "Onboarding")

    init(
        clock: @escaping () -> Date = Date.init,
        reminderService: ReminderScheduling = OnboardingReminderService(),
        defaults: UserDefaults = .standard
    ) {
        self.clock = clock
        self.reminderService = reminderService
        self.defaults = defaults
        OnboardingInstrumentation.recordStarted(now: clock(), defaults: defaults)
    }

    // MARK: - Screen 1 (branch)

    func chooseReadyNow() {
        guard phase == .branch else { return }
        branch = .readyNow
        OnboardingInstrumentation.recordBranch(.readyNow, defaults: defaults)
        phase = .readyNowBridge
        // Self-contained ready-now action (no hand-off, no bridge screen)?
        // Call `complete()` here instead, and delete `.readyNowBridge`/
        // `.awaitingHandoffReturn` from OnboardingPhase.
    }

    func chooseLater() {
        guard phase == .branch else { return }
        branch = .later
        OnboardingInstrumentation.recordBranch(.later, defaults: defaults)
        phase = .intention
    }

    /// The quiet escape hatch — reachable from screen 1 only (the branch
    /// choice already commits once made).
    func skipOnboarding() {
        guard phase == .branch else { return }
        OnboardingInstrumentation.recordBranch(.skipped, defaults: defaults)
        complete()
    }

    // MARK: - Ready-now hand-off (delete this section if you deleted the bridge phase)

    func beginHandoff() {
        guard phase == .readyNowBridge else { return }
        phase = .awaitingHandoffReturn
    }

    /// The hand-off resolved to a real outcome — see onboarding-patterns.md
    /// Lesson 4. `valueMomentReached` should reflect whatever the real
    /// feature's flow actually did, not just "the sheet closed."
    func handoffReturned(valueMomentReached: Bool) {
        guard phase == .awaitingHandoffReturn else { return }
        if valueMomentReached {
            OnboardingInstrumentation.recordValueMomentIfNeeded(now: clock(), defaults: defaults)
        }
        complete()
    }

    /// The wander-off safety net — the user backed out of the hand-off
    /// without it ever resolving through `handoffReturned(valueMomentReached:)`.
    /// NEVER re-interrupts; completes quietly in the background.
    func abandonToHome() {
        guard phase == .awaitingHandoffReturn else { return }
        Self.log.info("hand-off abandoned — completing onboarding silently")
        complete()
    }

    // MARK: - Later branch, step 1 (when)

    /// Pure — testable with an injected `now`/`Calendar`, no device/timezone
    /// dependency. See onboarding-patterns.md Lesson 7's Saturday boundary
    /// case: chosen ON a Saturday, `.weekend` must resolve to the NEXT
    /// Saturday, not today.
    static func defaultDate(
        for choice: OnboardingDateChoice,
        customDate: Date? = nil,
        now: Date,
        calendar: Calendar = .current
    ) -> Date {
        switch choice {
        case .tonight:
            return sevenPM(on: now, calendar: calendar)
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            return sevenPM(on: tomorrow, calendar: calendar)
        case .weekend:
            return sevenPM(on: nextSaturday(after: now, calendar: calendar), calendar: calendar)
        case .custom:
            return sevenPM(on: customDate ?? now, calendar: calendar)
        }
    }

    private static func sevenPM(on day: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: 19, minute: 0, second: 0, of: day) ?? day
    }

    /// "This weekend" = the NEXT Saturday, always looking forward — even
    /// when `now` itself falls on a Saturday, "next" means seven days out,
    /// not today (today's plan is "tonight," not "this weekend"). Gregorian
    /// weekday numbering: Sunday=1 ... Saturday=7.
    private static func nextSaturday(after date: Date, calendar: Calendar) -> Date {
        let saturday = 7
        let today = calendar.component(.weekday, from: date)
        var daysAhead = (saturday - today + 7) % 7
        if daysAhead == 0 { daysAhead = 7 }
        return calendar.date(byAdding: .day, value: daysAhead, to: date) ?? date
    }

    func confirmIntentionDate(_ date: Date) {
        guard phase == .intention else { return }
        intentionDate = date
        phase = .reminder
    }

    // MARK: - Later branch, step 2 (reminder + in-context permission)

    /// Requests notification authorization RIGHT HERE (never earlier) and
    /// schedules the local reminder. Denial is graceful: the plan is already
    /// saved regardless of this outcome, and onboarding completes exactly
    /// the same either way.
    func requestReminder() async {
        guard phase == .reminder, let intentionDate else {
            complete()
            return
        }
        let granted = await reminderService.requestAndSchedule(
            title: "Your plan is ready",
            body: "Come back and pick up right where you left off.",
            fireDate: intentionDate
        )
        reminderScheduled = granted
        reminderDenied = !granted
        complete()
    }

    /// Proceeds without ever touching the notification permission (the
    /// sequencing guarantee: authorization is asked ONLY on an explicit
    /// "Remind me" tap).
    func declineReminder() {
        guard phase == .reminder else { return }
        complete()
    }

    // MARK: - Completion (idempotent — the never-re-interrupt guarantee)

    private func complete() {
        guard phase != .completed else { return }
        phase = .completed
        OnboardingInstrumentation.recordCompleted(now: clock(), defaults: defaults)
    }
}
