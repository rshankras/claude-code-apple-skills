---
name: onboarding-generator
description: Generates value-moment-first onboarding flows for iOS/macOS apps — the default architecture races a new user to the first felt experience of the app's promised outcome, branching on whether they can experience it right now or need to plan for later. The classic paged welcome-carousel tour is an explicit fallback for genuinely explain-first apps. Use when user wants to add onboarding, welcome screens, first-launch experience, or improve activation/trial conversion.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
last_verified: 2026-07-23
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# Onboarding Generator

Generate onboarding whose job is to get a new user to the **value moment** — the first time they *experience* (never just read about) the outcome the app promises — as fast as their situation allows.

**Default architecture: value-moment-first, branching on readiness.** The user answers one question ("can you do this right now?"), and the path is either the shortest possible route to the value moment, or a captured plan to reach it later. **Fallback architecture: the classic paged welcome carousel** — generate it only when Step 0 below confirms the app is genuinely explain-first.

Read `onboarding-patterns.md` for the full philosophy, the nine implementation lessons (each with a code sketch), and a worked case study.

## When This Skill Activates

Use this skill when the user:
- Asks to "add onboarding" or "create onboarding"
- Mentions "welcome screens" or "first launch"
- Wants to "show intro on first launch"
- Asks about "onboarding flow" or "tutorial screens"
- Wants to improve "activation," "time-to-value," or "trial conversion"
- Asks "why do users churn right after signup/purchase" (post-purchase first-run is half of this skill)

## Before Anything Else: What Is The Value Moment?

This is the question that decides every downstream choice — ask it before any configuration question. If the requester can't answer it, help them find it: it's the first specific instant a user *feels* the outcome, not a feature list. "Sees a demo of X" is not a value moment; "actually did X and saw the result" is.

Onboarding that ends before the user felt the value moment didn't finish — it just stopped.

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (`@Observable` needs iOS 17+/macOS 14+; fall back to `ObservableObject` below that)
- [ ] Identify the app's core feature and its existing entry point — the value moment almost always lives inside a feature that already exists (or is being built alongside this flow); this skill wires into it, it does not rebuild it (see `onboarding-patterns.md` Lesson 3)
- [ ] Check whether the app has a launch paywall (`Glob: **/*Paywall*.swift, **/*StoreKit*.swift`, or an installed `generators/paywall-generator` output) — determines free-first vs paywalled-first in Configuration Question 2
- [ ] Check for `UNUserNotificationCenter` usage already in the project — reuse the existing permission seam if one exists rather than creating a second

### 2. Conflict Detection
```
Glob: **/*Onboarding*.swift, **/*Welcome*.swift
Grep: "hasCompletedOnboarding" or "isFirstLaunch" or "onboardingCompleted"
```

If found, ask the user:
- Replace existing onboarding?
- Keep existing, add the value-moment flow as a new post-purchase/post-launch stage?

### 3. Overlap Check — `generators/quick-win-session`
If the project already has a quick-win-session installation, don't generate a second guided-first-action system. Ask whether the existing quick-win session already *is* the ready-now path (often it is — fold this flow's branch question and later-path in around it) or whether the two should stay separate stages.

## Configuration Questions

Ask user via AskUserQuestion:

1. **What's the value moment?** (free text) — the first specific instant the user experiences the app's promise. Push back on feature descriptions ("a calendar sync feature") until you get an outcome ("saw their two calendars merged into one").

2. **Free-first or paywalled-first?**
   - Free-first (no launch paywall) — this flow **is** the whole onboarding
   - Paywalled-first — personalize → paywall happens before this flow starts; this flow begins at first-run-after-purchase (the half that decides trial conversion and renewals)

3. **What's the ready-now action?** — the shortest real path to the value moment when the user can experience it immediately. Must name an *existing* feature/screen to reuse, never a new one built just for onboarding.

4. **What does "later" capture?** — the concrete implementation intention (a specific *when*, e.g. "Tuesday 6pm," never "someday"), and what happens with it: a local reminder, a home-surface chip, both?

5. **Architecture override — is this genuinely explain-first?** Default is no (value-moment-first). Only say yes if Step 0's test below is met. This is the one question that routes to the carousel fallback instead.

## Generation Process

### Step 0: Confirm The Architecture (do this before writing any file)

Run this test:

> Would skipping straight to the value moment leave the user unable to understand what they're looking at, in a way no amount of contextual UI (tooltips, empty-state copy, a single explainer inline) could fix — because the domain itself requires orientation (e.g., a professional tool with domain-specific jargon, a multi-role enterprise workflow)?

- **No** (the overwhelming default) → generate the value-moment-first flow (Steps 1–5).
- **Yes** → generate the carousel fallback (Step 6). "We have a lot to say" is not a yes — trim the copy instead.

### Step 1: Create Core Files (Value-Moment Default)

Read `templates/value-moment/` for production Swift code, then generate:
1. `OnboardingPhase.swift` — the phase/branch state model (one enum case per screen; every case maps to exactly one decision)
2. `OnboardingStore.swift` — `@Observable` coordinator (plain object, **not** a View — see `onboarding-patterns.md` Lesson 1's testability point). Owns phase transitions, the branch, the captured "when," and calls into instrumentation. No navigation/routing types inside it — the app's existing router/state owns side effects, this store owns only business state.
3. `OnboardingRootView.swift` — the phase switch. No `NavigationStack` of its own (this view *is* a root, never a pushed destination — see the global SwiftUI-patterns rule against nesting nav containers).
4. `OnboardingBranchView.swift` — screen 1: value-moment framing + the ready-now/later fork. This is the only screen every user sees.
5. `OnboardingReadyNowBridgeView.swift` — the ready-now hand-off into the real feature, with resume-callback wiring (Lesson 3 + Lesson 4)
6. `OnboardingIntentionView.swift` — later path: capture the concrete "when" via chips, resolved through a pure, injectable-clock function (Lesson 7)
7. `OnboardingReminderView.swift` + `OnboardingReminderService.swift` — later path: the contextual local-notification permission ask (Lesson 6)
8. `OnboardingInstrumentation.swift` — value-moment reach-rate markers (Lesson 8)

### Step 2: Wire The Root Swap (Lesson 1 — required)

Onboarding replaces the app's root view; it is never a `.fullScreenCover`/`.sheet` over the real content. Show the requester this shape and adapt it to their app's actual root:

```swift
struct ContentView: View {
    @State private var onboardingStore = OnboardingStore()

    private var showOnboarding: Bool {
        // Phase-first (Lesson 2): check the in-memory state machine FIRST;
        // the durable flag is only the survives-relaunch fallback.
        if appState.onboardingCompleted { return false }
        return onboardingStore.phase != .completed && onboardingStore.phase != .awaitingHandoffReturn
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingRootView(store: onboardingStore)
            } else {
                RealAppRootView()   // whatever the app's true root already is
            }
        }
        .onChange(of: onboardingStore.phase) { _, newPhase in
            guard newPhase == .completed else { return }
            appState.onboardingCompleted = true   // durable fallback catches up
        }
    }
}
```

### Step 3: Wire Resume Mechanics (Lesson 4 — required whenever the ready-now action hands off into an existing multi-screen flow)

Arm a one-shot completion callback before the hand-off, plus a wander-off safety net that completes onboarding silently if the user backs out without resolving:

```swift
func beginReadyNowHandoff() {
    store.beginHandoff()
    router.presetPathIntoRealFeature(...)          // land straight on the feature, never Home
    router.onRealFeatureFinished = { outcome in
        store.handoffReturned(valueMomentReached: outcome.reachedValueMoment)
    }
}

// Safety net — user backed all the way out without the callback firing.
.onChange(of: router.path) { _, newPath in
    guard store.phase == .awaitingHandoffReturn, newPath.isEmpty else { return }
    store.abandonToHome()   // NEVER re-interrupts; completes quietly
}
```

### Step 4: Suppress Onboarding In Existing UI Tests (Lesson 5 — required step, not optional)

Adding this flow will break the first screen of every existing UI test that assumes it lands on the app's real home screen. Before finishing generation:

1. Find the project's UI-test launch-argument gate (`ProcessInfo.processInfo.arguments`), usually in a `UITestSupport`-style file.
2. Add an onboarding-suppression default: existing test launches pre-set the durable completed flag unless a **new**, dedicated argument opts back in.

```swift
static var showOnboardingOverride: Bool {
    ProcessInfo.processInfo.arguments.contains("-uiTestShowOnboarding")
}
// At app launch, under the existing test-mode gate:
appState.onboardingCompleted = !UITestSupport.showOnboardingOverride
```
3. Tell the requester explicitly which existing test target this touches and that a dedicated onboarding UI test should pass `-uiTestShowOnboarding` to exercise the real flow.

### Step 5: Close The Loop On The "Later" Branch (Lesson 9)

After the plan lands, surface it on the app's home surface — a small chip/badge carrying the planned date/action that reopens the flow when tapped — and prune it once the date passes:

```swift
if let plannedAt = appState.plannedIntentionDate {
    PlannedIntentionChip(date: plannedAt) { /* reopen the ready-now path directly */ }
}
// Called from wherever the home surface is revisited:
func prunePlannedIntentionIfExpired(now: Date = .now) {
    guard let plannedIntentionDate, plannedIntentionDate <= now else { return }
    self.plannedIntentionDate = nil
}
```

### Step 6: Carousel Fallback (only if Step 0 said yes)

Read `templates/carousel-fallback/` and the "Carousel Fallback" section of `onboarding-patterns.md`. Generate:
1. `OnboardingView.swift` — main paged/stepped container
2. `OnboardingPageView.swift` — individual page template
3. `OnboardingPage.swift` — page data model
4. `OnboardingStorage.swift` — persistence
5. `OnboardingModifier.swift` — view modifier for integration

Ask the same navigation-style/skip/presentation configuration questions as before (paged vs stepped, 2–5 screens, skip option, full-screen cover vs inline). Even here: still apply the root-swap and UI-test-suppression steps above — the presentation mechanics change, the anti-flash and anti-broken-test requirements don't.

### Step 7: Determine File Location

Check project structure:
- If `Sources/` exists → `Sources/Onboarding/`
- If `App/` exists → `App/Onboarding/`
- Otherwise → `Onboarding/`

## The Audit Checklist

Run this before calling generation done — on a fresh flow, and again any time onboarding is later touched. If any answer is "no," the flow needs work before it ships:

1. **Can a ready-now user reach the value moment in under two minutes?**
2. **Is there any screen that purely explains a feature**, rather than letting the user experience it or make a path-changing decision?
3. **Does the flow actually branch on readiness** — or does every user see the same steps regardless of their answer to the ready-now/later question?
4. **For later-users, is a concrete plan captured** — a specific *when* — never a vague "someday" with no follow-up?
5. **Is the notification permission request attached to a reason the user just created** (their own chosen date/task), never asked cold at first launch?
6. **Do you know your value-moment reach rate?** Is the value moment defined as a tracked event at all — reach rate, time-to-reach, and per-screen drop-off — or is the only number you have "% who tapped through onboarding"?

## Output Format

After generation, provide:

### Files Created — Value-Moment Default
```
Onboarding/
├── OnboardingPhase.swift              # Phase/branch state model
├── OnboardingStore.swift              # @Observable coordinator (business state only)
├── OnboardingRootView.swift           # Phase switch — the root-swap target
├── OnboardingBranchView.swift         # Screen 1: value-moment framing + fork
├── OnboardingReadyNowBridgeView.swift # Ready-now hand-off + resume wiring
├── OnboardingIntentionView.swift      # Later: concrete "when" capture
├── OnboardingReminderView.swift       # Later: contextual permission ask
├── OnboardingReminderService.swift    # Local-notification seam (protocol + live impl)
└── OnboardingInstrumentation.swift    # Value-moment reach-rate markers
```

### Files Created — Carousel Fallback
```
Onboarding/
├── OnboardingView.swift        # Main container
├── OnboardingPageView.swift    # Page template
├── OnboardingPage.swift        # Data model
├── OnboardingStorage.swift     # @AppStorage persistence
└── OnboardingModifier.swift    # .onboarding() modifier
```

### Integration Steps

**Root swap (both architectures):**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()   // ContentView itself performs the root swap — see Step 2
        }
    }
}
```

**Value-moment: define the app's own phases and hand-offs** in `OnboardingPhase.swift`/`OnboardingStore.swift` — the template ships a two-phase (ready-now / later) skeleton; add or remove phases to match the actual value moment, keeping one decision per phase.

**Carousel fallback: add pages** as before —
```swift
static let pages: [OnboardingPage] = [
    OnboardingPage(title: "Welcome", description: "...", imageName: "hand.wave", accentColor: .blue),
]
```

### Testing Instructions

**Value-moment flow:**
1. Delete app from simulator/device (resets `UserDefaults`)
2. Fresh launch → answer "ready now" → confirm the value moment is reached in the fewest possible taps, using the real feature (not a replica)
3. Fresh launch → answer "later" → confirm a concrete date/time is captured, the permission prompt appears only after tapping the reminder CTA, and denial still saves the plan
4. Force-quit mid-flow (after screen 1, before completion) → relaunch → confirm the phase-first gate resumes onboarding rather than flashing real content
5. During the ready-now hand-off, back out without resolving the destination screen → confirm onboarding completes silently (no re-interrupt, no trap)
6. Let the "later" date pass → revisit the home surface → confirm the planned-intention chip is pruned
7. Run the project's existing UI test suite → confirm no regressions from onboarding intercepting their first screen (Step 4)

**Carousel fallback:** unchanged from the classic flow — delete app, confirm it shows once, confirm it doesn't reappear after completion.

### Debug/Testing Reset
```swift
// Add to Settings or debug menu
Button("Reset Onboarding") {
    UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    OnboardingInstrumentation.resetForTesting(defaults: .standard)   // value-moment flow only
}
```

## Instrumentation: Reach Rate Is The North Star

Track **value-moment reach rate** — percentage of new users who reach the value moment in their first session, time-to-reach, and per-screen drop-off — not flow completion. A user who reached the value moment and closed the app is a win; a user who tapped through every screen and never felt it is not.

This works even in apps with no analytics SDK: local-only markers (`UserDefaults` timestamps for `startedAt`/`branch`/`valueMomentAt`/`completedAt`) plus `os.Logger`, every write idempotent (first stamp wins) so re-entrant paths never overwrite a real timestamp with a later, less meaningful one. See `onboarding-patterns.md` Lesson 8 for the full pattern; wire into a real analytics provider (e.g. an installed `generators/analytics-setup` output) when one exists.

## References

- **onboarding-patterns.md** — the full philosophy, all nine implementation lessons with code sketches, the carousel fallback's design patterns, and a worked case study
- **templates/value-moment/** — default architecture templates
- **templates/carousel-fallback/** — classic paged/stepped tour templates, for explain-first apps only
- Related: `generators/quick-win-session` — guided first-action UI; check for overlap before generating both (see Pre-Generation Check 3)
- Related: `generators/permission-priming` — deeper priming patterns if the reminder step needs more than a single contextual ask
- Related: `generators/paywall-generator` — the pre-purchase half of the flow for paywalled-first apps
- Related: `generators/push-notifications` — remote push infrastructure, distinct from this skill's local-only reminder (no server involved)
