# Onboarding Patterns — Value-Moment-First (Default) and Carousel (Fallback)

## The Philosophy: Onboarding Is a Race to the Value Moment

The **value moment** is the first time a user *experiences* the outcome the app promises — felt, never explained. "Saw a screen describing the feature" is not a value moment. "The feature happened to them, and they saw the result" is.

If onboarding ends before the user felt the value moment, it didn't finish — it just stopped. A flow that walks a user through five polished screens and drops them on an empty home screen has not "completed onboarding" in any sense that matters; it has produced a user who now has to go find the value on their own, cold, with no more goodwill than they arrived with.

### Two Halves

Onboarding has (up to) two halves, and they are judged differently:

1. **Pre-purchase** — personalize → paywall. Its job is to get a qualified user to a purchase decision with the fewest, most honest steps. This half is a **funnel**; the metric is conversion to purchase.
2. **Post-purchase first-run** — everything after the transaction. This half decides trial conversion and renewals, because a subscriber who never felt the value moment cancels before the first renewal regardless of how good the product actually is. This half is not a funnel to a purchase; it's a race to a feeling.

**For free-first apps (no launch paywall), the second half *is* the whole flow.** There is no purchase to sit between "personalize" and "value" — the user goes straight from first launch to the value-moment race. Treat purchase, where it exists, as the starting line for the half that actually determines retention — not the finish line for onboarding as a whole.

### The One Branch Question

Immediately after purchase (or immediately after launch, for free-first apps), ask exactly one question — as a *decision*, not as UI copy: **can this person experience the value moment right now, or only later?**

- **Ready now** → the shortest possible path to the value moment. Nothing else. No extra screens, no setup, no "let's get to know you first" — those all belong on the other branch, if anywhere.
- **Later** (they're missing something the value moment needs — people aren't in the room yet, the data isn't ready, the event hasn't happened) → capture an **implementation intention**: a concrete *when* ("Tuesday 6pm"), never a vague "someday" or a silent assumption that they'll remember to come back. Schedule a reminder against that specific plan. Then, and only then, any setup that doesn't need the value moment itself.

### Four Rules

- **No theater.** Every question in the flow must change the path the user takes. If a question's answer doesn't alter what happens next, it isn't onboarding, it's decoration — cut it.
- **One decision per screen.** A screen that asks two things (a preference *and* a permission, a fork *and* a name field) forces the user to context-switch mid-screen and makes both decisions worse. Split it.
- **Permissions are asked in context**, with the reason the user just created — never cold on first launch, before the user has any reason to say yes.
- **Setup lives on the "later" branch only.** A ready-now user who can experience the value moment immediately should never see a setup screen first. Setup is what fills the gap while a later-user waits for their moment, not a toll every user pays.

## Instrumentation: Value-Moment Reach Rate Is The North Star

Measure **value-moment reach rate** — the percentage of new users who reach the value moment in their first session — plus **time-to-reach** and **drop-off per screen**. Do not measure "flow completion." A user who reached the value moment and left is a retention win; a user who tapped "Get Started" on every screen and never felt anything is a loss wearing a 100%-completion costume.

Define the value moment as a **tracked event**, explicitly, the same way you'd define any other product event — not as an inferred side effect of "onboarding finished." If you can't point to the line of code that fires when a user reaches it, you don't have a value moment defined; you have a hope.

This is achievable with zero analytics infrastructure (see Lesson 8) — the absence of an analytics SDK is never a reason to skip measuring reach rate.

## The Nine Implementation Lessons

Battle-tested against a real Shipaton-timeline app (see the worked example below). Each lesson below is a place the classic advice ("keep it short," "make it skippable") turns out to be necessary but not sufficient — these are the mechanics that make a value-moment-first flow actually survive contact with SwiftUI, VoiceOver, and an existing UI test suite.

### 1. Root Swap, Not `fullScreenCover`/`sheet`

A cover or sheet presents *over* the real content — the home screen renders underneath for at least one frame before the cover animates up, and VoiceOver announces that underlying content first. Neither is acceptable for a first-run experience: a user (sighted or not) briefly sees or hears the very thing onboarding exists to set up correctly.

Swap the top-level view instead, so onboarding and the real app root are never both constructed for the same app state.

#### ❌ Anti-pattern
```swift
struct MyApp: App {
    @AppStorage("hasCompletedOnboarding") private var completed = false
    var body: some Scene {
        WindowGroup {
            ContentView()   // renders first — flashes underneath, VoiceOver announces it
                .fullScreenCover(isPresented: .constant(!completed)) {
                    OnboardingRootView()
                }
        }
    }
}
```

#### ✅ Good pattern
```swift
struct ContentView: View {
    @State private var onboardingStore = OnboardingStore()
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingRootView(store: onboardingStore)
            } else {
                RealAppRootView()
            }
        }
    }
}
```

### 2. Phase-First Gating

The visual gate must check the **in-memory** onboarding state machine synchronously *first*; a durable `@AppStorage`/`UserDefaults` flag is only the survives-relaunch fallback. If the gate depends solely on the reactive write of the durable flag, there's a real window — one SwiftUI update cycle — where onboarding can flash back *over* live content on an abandon path (the user already mid-round in the real feature, and a delayed persistence write hasn't caught up yet).

#### ✅ Good pattern
```swift
private var showOnboarding: Bool {
    if appState.onboardingCompleted { return false }        // durable fallback
    switch onboardingStore.phase {                            // in-memory, checked FIRST
    case .completed, .awaitingHandoffReturn: return false     // resolved the instant the phase changes
    default: return true
    }
}
```
The `.onChange(of: onboardingStore.phase)` that writes `appState.onboardingCompleted = true` exists purely so the choice survives a relaunch — it is never load-bearing for the visual swap itself.

### 3. Reuse The Real Feature As The Value Moment

Never build a replica of the value-moment feature inside onboarding — a scripted demo that only looks like the real thing drifts the moment the real feature changes, and it isn't Guideline-2.3.1-safe if it doesn't exercise real functionality. Extract the feature's existing entry plumbing into **one shared implementation** that both the real app and onboarding call.

#### ❌ Anti-pattern
```swift
// A second, onboarding-only copy of the deck builder — now two things to maintain,
// and the user's "value moment" isn't even the real feature.
struct OnboardingDeckPreviewView: View { /* reimplements deck generation UI */ }
```

#### ✅ Good pattern
```swift
// Onboarding calls the SAME shortcut the real app's home screen uses.
router.openRealFeatureShortcut(appState: appState, in: modelContext)
```

### 4. Resume Mechanics For A Value Moment That Lives In An Existing Flow

When the ready-now action hands off into a multi-screen existing flow (not a single self-contained screen), two mechanisms are required together:

- A **one-shot completion callback**, armed *before* the hand-off, so the existing flow can report back what happened without onboarding needing to know its internals.
- A **wander-off safety net** — the user backs out of the existing flow without ever resolving it (dismissed a sheet, navigated all the way back to Home). This must **silently complete onboarding**, never re-interrupt and never trap the user in a loop they can't escape.

#### ✅ Good pattern
```swift
func beginHandoff() {
    store.beginHandoff()
    router.onRealFeatureFinished = { outcome in           // one-shot callback, armed pre-handoff
        store.handoffReturned(valueMomentReached: outcome.reachedValueMoment)
    }
    router.presetPathIntoRealFeature(...)
}

.onChange(of: router.path) { _, newPath in                 // wander-off safety net
    guard store.phase == .awaitingHandoffReturn, newPath.isEmpty else { return }
    store.abandonToHome()   // completes quietly — never re-shows onboarding
}
```

### 5. The UI-Test Landmine

Adding this flow breaks the first screen of **every existing UI test** — they all assume launch lands on the real home screen, and now it doesn't. This is not an edge case to discover later; treat it as a required generation step (see SKILL.md Step 4), not an optional cleanup.

Auto-suppress onboarding under the project's existing test-mode launch argument, and add one **new, dedicated** argument for onboarding's own tests to opt back in:

#### ✅ Good pattern
```swift
static var showOnboardingOverride: Bool {
    ProcessInfo.processInfo.arguments.contains("-uiTestShowOnboarding")
}
// Under the existing test-mode gate, at launch:
appState.onboardingCompleted = !UITestSupport.showOnboardingOverride
```
Every pre-existing test flow now launches exactly as it did before this flow existed; a future onboarding-specific test passes `-uiTestShowOnboarding` deliberately.

### 6. Implementation Intentions Are Local Notifications

The "later" branch's reminder is a `UNUserNotificationCenter` **local** notification — no push capability, no server required. Request authorization at the reminder step, using the user's *own just-created plan* as the reason ("remind me Tuesday at 6pm" — not a generic "enable notifications?"). The denial path must still save the plan; a "no" to notifications is not a "no" to the plan itself.

Keep a thin injectable protocol seam over the notification center so callers' tests never import `UserNotifications` at all.

#### ✅ Good pattern
```swift
protocol NotificationScheduling: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) async throws
}

@MainActor
protocol ReminderScheduling: AnyObject {
    @discardableResult
    func requestAndSchedule(title: String, body: String, fireDate: Date) async -> Bool
}

final class OnboardingReminderService: ReminderScheduling {
    private let center: NotificationScheduling
    init(center: NotificationScheduling = LiveNotificationCenter()) { self.center = center }

    @discardableResult
    func requestAndSchedule(title: String, body: String, fireDate: Date) async -> Bool {
        guard let granted = try? await center.requestAuthorization(), granted else { return false }
        try? await center.scheduleNotification(id: "onboardingReminder", title: title, body: body, fireDate: fireDate)
        return true
        // Plan stays saved regardless of the return value — see the store's caller.
    }
}
```

### 7. Chip → Concrete-Date Resolution Needs An Injectable Clock

Turning a chip ("tonight," "tomorrow," "this weekend") into an actual `Date` is pure logic that must be independently testable — including the boundary case where "this weekend" is chosen **on** a Saturday (it must resolve to the *next* Saturday, not today; today's plan is "tonight," not "this weekend"). Inject `now: Date` (or a `() -> Date` clock) rather than calling `Date()`/`.now` inside the resolver.

#### ✅ Good pattern
```swift
static func defaultDate(for choice: DateChoice, now: Date, calendar: Calendar = .current) -> Date {
    switch choice {
    case .tonight:  return sevenPM(on: now, calendar: calendar)
    case .tomorrow: return sevenPM(on: calendar.date(byAdding: .day, value: 1, to: now) ?? now, calendar: calendar)
    case .weekend:  return sevenPM(on: nextSaturday(after: now, calendar: calendar), calendar: calendar)
    }
}

// Boundary test this function must pass:
// now = a Saturday 3pm -> .weekend resolves to NEXT Saturday (7 days out), never today.
```

### 8. Reach-Rate Instrumentation Works Even In No-Analytics Apps

A privacy-first app with zero third-party SDKs can still measure reach rate: local-only markers in `UserDefaults` (`startedAt` / `branch` / `valueMomentAt` / `completedAt` timestamps) plus `os.Logger` lines a developer can read via Console/`defaults read` on a TestFlight device. Every write must be **idempotent** — first stamp wins — so a relaunch that restarts onboarding, or a duplicate call from a slow tap, never overwrites a real, earlier, more meaningful timestamp.

#### ✅ Good pattern
```swift
enum OnboardingInstrumentation {
    static func recordValueMomentIfNeeded(now: Date, defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: "valueMomentAt") == nil else { return }   // idempotent
        defaults.set(now.timeIntervalSince1970, forKey: "valueMomentAt")
        Logger(subsystem: "com.yourapp", category: "Onboarding").info("value moment reached")
    }
}
```
Wire the same call sites into a real analytics provider later — the local markers and an analytics event are not mutually exclusive, and the local markers work on day one with no vendor integration.

### 9. Close The Loop On The "Later" Branch

Capturing a plan and never mentioning it again is a leak — the user did the work of committing to a *when* and the app should visibly remember it. After landing, surface the captured plan on the app's home surface: a small chip/badge with the planned date that reopens the ready-now path directly when tapped. Prune it once the date passes — a chip for a date that already happened is worse than no chip.

#### ✅ Good pattern
```swift
// On the home surface:
if let plannedAt = appState.plannedIntentionDate {
    PlannedIntentionChip(date: plannedAt) { /* reopen the ready-now action directly */ }
}

// Self-heals on next visit — no timer needed if the home surface has a natural revisit point:
func prunePlannedIntentionIfExpired(now: Date = .now) {
    guard let plannedIntentionDate, plannedIntentionDate <= now else { return }
    self.plannedIntentionDate = nil
}
```

## Carousel Fallback: When (And How) To Use It Instead

Generate this **only** when SKILL.md's Step 0 test says the app is genuinely explain-first — the domain itself requires orientation before any interaction is legible, and no amount of contextual UI fixes that (a professional tool with unavoidable jargon, a multi-role enterprise workflow with no single "try it" action). "We have a lot to say" is not a qualifying reason.

### Design Principles (Fallback Only)
- **3–4 screens, never more than 5** — this is a compromise architecture already; don't compound it with length.
- **Explain benefits, not features** — "save time," not "has a calendar sync feature," even here.
- **Always skippable** — a user who already knows the domain shouldn't be forced through it.

### Navigation Patterns

**Paged (swipe)** — best for visual, image-heavy content:
```swift
TabView(selection: $currentPage) {
    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
        OnboardingPageView(page: page).tag(index)
    }
}
.tabViewStyle(.page(indexDisplayMode: .always))
```

**Stepped (buttons)** — best for permission requests or sequential setup (still: only request permissions in context, even inside a carousel):
```swift
HStack {
    if currentPage > 0 { Button("Back") { withAnimation { currentPage -= 1 } } }
    Spacer()
    Button(isLastPage ? "Get Started" : "Next") {
        withAnimation { isLastPage ? completeOnboarding() : (currentPage += 1) }
    }
    .buttonStyle(.borderedProminent)
}
```

### Persistence
```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
```
Use a versioned key (`onboardingCompletedVersion`) instead if a major update should show the carousel again.

### Presentation

Even in the fallback architecture, apply Lesson 1: a root swap (`if !hasCompletedOnboarding { OnboardingView() } else { RealAppRootView() }`) reads better than a cover, though a `.sheet(isPresented:)` with `.interactiveDismissDisabled()` is an acceptable compromise on macOS, where sheets are the native modal idiom.

### Accessibility (Non-Negotiable In Either Architecture)
```swift
OnboardingPageView(page: page)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(page.title). \(page.description)")
    .accessibilityHint("Page \(index + 1) of \(pages.count)")

Text(page.title).font(.title).minimumScaleFactor(0.7).lineLimit(2)   // Dynamic Type room

@Environment(\.accessibilityReduceMotion) var reduceMotion
.animation(reduceMotion ? nil : .easeInOut, value: currentPage)
```

### Anti-Patterns To Avoid (Fallback Architecture)
- More than 5 screens, or walls of text
- Requiring all permissions upfront, cold, disconnected from any reason
- Unskippable with no genuine reason
- Showing the carousel again on every routine app update (only on major version jumps, deliberately)

## Worked Example: Antics

A real Shipaton-timeline app (a one-phone party-game host app) validated all nine lessons together. The domain: a host either has their people around them right now, or is planning a party for later.

**Branch question (screen 1).** One hero screen asks "Got your people around you right now?" with two option cards — "We're together now" and "Party's coming up" — plus a quiet "Just looking around" escape hatch. Each card commits the branch and moves immediately; there is no screen before this one.

**Ready-now branch.** Choosing "together now" exits onboarding entirely and hands straight into the app's real occasion-picker flow — the value moment (a completed game round) lives inside the app's existing gameplay, not inside onboarding, so onboarding's job here is exactly one tap and then getting out of the way (Lesson 3).

**Later branch → deck value moment with resume (Lessons 3 + 4).** "Party's coming up" leads to one bridge screen ("Let's make tonight's deck"), then a single button hands off into the app's *existing* AI deck-builder shortcut — the same entry point the home screen's own "Make a deck about your group" button uses, never a second implementation. A one-shot callback is armed before hand-off; the deck-builder's own multi-screen flow (team setup → picker → generation) resolves back through it. If the host instead starts playing immediately from inside that flow, the wander-off safety net completes onboarding silently rather than yanking them back.

**Date capture (Lesson 7).** Once the deck exists, "When's the party?" offers four chips (tonight / tomorrow / this weekend / pick a date) resolved through a pure, `now`-injected function, with a compact time wheel to fine-tune *within* the chosen chip — never a second decision. The "this weekend" boundary case (chosen on a Saturday) resolves to the next Saturday, verified by a unit test with an injected clock.

**Contextual local reminder (Lesson 6).** The very next screen phrases the ask in the host's own plan — "Want a nudge Saturday at 7:00 PM?" — and requests notification authorization only when "Remind me" is tapped, never earlier. "No thanks" proceeds without ever touching the permission system; either way, the party date the host chose one screen earlier is already saved, so this step can only add a nudge, never take the plan away.

**Planned-party chip (Lesson 9).** Back on the home screen, a `PlannedPartyChip` shows the committed date and reopens the deck-builder shortcut in one tap. It's pruned automatically the moment the home screen is revisited after the date has passed.

**Root swap + phase-first gate (Lessons 1 + 2).** The app's root view is a two-way switch between the onboarding flow and the real app shell, gated first on the in-memory state-machine phase and only secondarily on a durable flag — specifically so the wander-off safety net's silent completion (Lesson 4) can never risk a one-frame flash of onboarding back over a round the host has already started.

**UI-test suppression (Lesson 5).** Every pre-existing UI test flow launches with the durable "onboarding completed" flag pre-set, unless a dedicated new launch argument opts back in — so eighteen existing test flows kept passing unmodified the moment this flow shipped.

**Local-only reach-rate instrumentation (Lesson 8).** Four idempotent `UserDefaults` timestamps (`startedAt`/`branch`/`valueMomentAt`/`completedAt`) plus `os.Logger` lines — no analytics SDK exists in this app at all (privacy-first, local-only by design), and the product still has a real answer to "what's our value-moment reach rate."

## References

- Apple: [`UNUserNotificationCenter`](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter) — local notification scheduling for the "later" branch's reminder
- Apple: [Human Interface Guidelines — Onboarding](https://developer.apple.com/design/human-interface-guidelines/) — platform conventions for first-run experiences
- Related: `generators/quick-win-session` — guided first-action UI; the ready-now branch's hand-off target may already be one
- Related: `generators/permission-priming` — deeper pre-permission patterns for the reminder step
- Related: `generators/paywall-generator` — the pre-purchase half of the flow for paywalled-first apps
