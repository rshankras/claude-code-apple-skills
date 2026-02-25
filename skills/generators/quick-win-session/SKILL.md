---
name: quick-win-session
description: Generates guided first-action flows that help users achieve a meaningful result within 60 seconds to boost retention. Use when user wants quick win onboarding, time-to-value optimization, or first success moments.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Quick Win Session Generator

Generate a "quick win" session system that guides users to complete a meaningful action within their first 60 seconds. Reduces time-to-value by surfacing the simplest high-impact task, walking the user through it step by step, and celebrating completion. Critical for onboarding retention — users who achieve a quick win in the first minute are significantly more likely to return.

## When This Skill Activates

Use this skill when the user:
- Asks about "quick win" flows or "first action" experiences
- Wants to reduce "time to value" or "time to first success"
- Mentions "guided first task" or "onboarding action"
- Asks about a "first success moment" or "activation metric"
- Wants to "get users to do something useful immediately"
- Mentions "new user activation" or "onboarding retention"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (iOS 17+ / macOS 14+ required for @Observable)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Identify source file locations

### 2. Existing Onboarding Detection
Search for existing onboarding code:
```
Glob: **/*Onboarding*.swift, **/*Welcome*.swift, **/*QuickWin*.swift, **/*FirstRun*.swift
Grep: "onboarding" or "firstLaunch" or "hasCompletedSetup" or "isNewUser"
```

If existing onboarding found:
- Ask if quick win should run after the existing onboarding or replace it
- If running after, integrate as the next step in the onboarding flow

### 3. User State Tracking Detection
Search for existing user defaults or state tracking:
```
Grep: "UserDefaults" or "@AppStorage" or "isFirstLaunch"
```

Determine how to persist quick win completion status (UserDefaults, AppStorage, SwiftData, etc.).

## Configuration Questions

Ask user via AskUserQuestion:

1. **Quick win type?**
   - Create first item (e.g., first note, first task, first photo)
   - Complete profile (fill in name, avatar, preferences)
   - Import data (bring in existing content from another source)
   - Explore feature (guided tour of the single most valuable feature)

2. **Guidance style?**
   - Step-by-step overlay (instruction cards at top, progress dots)
   - Spotlight hints (dim screen, cut out spotlight on target element)
   - Coach marks (tooltip arrows pointing at UI elements)

3. **Celebrate on completion?**
   - Yes — animated checkmark, congratulations message, time stat
   - Minimal — brief success banner, auto-dismiss
   - No — silently mark as complete

4. **Track as activation metric?**
   - Yes — log completion time, step-by-step progress, abandonment point
   - No — just persist completed/not completed

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `QuickWinTask.swift` — Model for a quick win task and its steps
2. `QuickWinSession.swift` — @Observable session manager: task selection, step tracking, timing, completion

### Step 3: Create UI Files
3. `QuickWinGuideView.swift` — Overlay that shows instructions and progress
4. `SpotlightHintView.swift` — Spotlight cutout overlay with callout arrow
5. `QuickWinCelebrationView.swift` — Completion celebration with stats

### Step 4: Create Integration File
6. `QuickWinModifier.swift` — ViewModifier that triggers the quick win for new users

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists → `Sources/QuickWin/`
- If `App/` exists → `App/QuickWin/`
- Otherwise → `QuickWin/`

## Output Format

After generation, provide:

### Files Created
```
QuickWin/
├── QuickWinTask.swift           # Task model with steps
├── QuickWinSession.swift        # Session manager (progress, timing)
├── QuickWinGuideView.swift      # Step-by-step overlay UI
├── SpotlightHintView.swift      # Spotlight cutout with callout
├── QuickWinCelebrationView.swift # Completion celebration
└── QuickWinModifier.swift       # ViewModifier for root view
```

### Integration After Onboarding

**Attach to your root view:**
```swift
// In your main ContentView or post-onboarding view
ContentView()
    .quickWinSession(task: .createFirstNote)
```

**Define your app's quick win task:**
```swift
extension QuickWinTask {
    static let createFirstNote = QuickWinTask(
        id: "create-first-note",
        title: "Create Your First Note",
        description: "Let's get started — it only takes a few seconds.",
        estimatedSeconds: 30,
        steps: [
            QuickWinStep(instruction: "Tap the + button to create a new note", actionType: .tap, targetView: "addButton"),
            QuickWinStep(instruction: "Type a title for your note", actionType: .input, targetView: "titleField"),
            QuickWinStep(instruction: "Tap Done to save", actionType: .tap, targetView: "doneButton")
        ],
        completionCriteria: "firstNoteCreated",
        iconName: "note.text.badge.plus"
    )
}
```

**With spotlight hints:**
```swift
// Mark target views for spotlight
TextField("Title", text: $title)
    .quickWinTarget(id: "titleField")

Button("Done") { save() }
    .quickWinTarget(id: "doneButton")
```

**Start session programmatically (after existing onboarding):**
```swift
struct PostOnboardingView: View {
    @State private var session = QuickWinSession()

    var body: some View {
        MainView()
            .onAppear {
                if !session.hasCompletedQuickWin {
                    session.start(task: .createFirstNote)
                }
            }
            .quickWinOverlay(session: session)
    }
}
```

### Testing

```swift
@Test
func quickWinSessionTracksProgress() async {
    let session = QuickWinSession(storage: MockStorage())
    let task = QuickWinTask.testTask(stepCount: 3)

    session.start(task: task)
    #expect(session.currentStepIndex == 0)
    #expect(session.isActive)

    session.completeCurrentStep()
    #expect(session.currentStepIndex == 1)

    session.completeCurrentStep()
    #expect(session.currentStepIndex == 2)

    session.completeCurrentStep()
    #expect(session.isCompleted)
    #expect(session.isActive == false)
}

@Test
func quickWinRecordsCompletionTime() async {
    let session = QuickWinSession(storage: MockStorage())
    let task = QuickWinTask.testTask(stepCount: 1)

    session.start(task: task)
    // Simulate time passing
    try? await Task.sleep(for: .milliseconds(500))
    session.completeCurrentStep()

    #expect(session.completionTimeSeconds > 0)
    #expect(session.completionTimeSeconds < 5)
}

@Test
func quickWinSkipsForReturningUsers() async {
    let storage = MockStorage()
    storage.set(true, forKey: "quickWin_create-first-note_completed")

    let session = QuickWinSession(storage: storage)
    session.start(task: .createFirstNote)

    #expect(session.isActive == false) // Already completed, skip
}

@Test
func quickWinHandlesAbandonment() async {
    let session = QuickWinSession(storage: MockStorage())
    let task = QuickWinTask.testTask(stepCount: 3)

    session.start(task: task)
    session.completeCurrentStep()
    session.abandon()

    #expect(session.isActive == false)
    #expect(session.isCompleted == false)
    #expect(session.abandonedAtStep == 1)
}
```

## Common Patterns

### Start Quick Win Session
```swift
// After onboarding completes
session.start(task: .createFirstNote)
```

### Show Guided Steps
```swift
// Session automatically advances through steps
// Each step shows instruction + highlights target
QuickWinGuideView(session: session)
```

### Celebrate Completion
```swift
// Automatically shown when all steps complete
QuickWinCelebrationView(
    taskTitle: session.completedTask?.title ?? "",
    completionTime: session.completionTimeSeconds
)
```

## Gotchas

- **Don't block experienced users** — Always check completion status before showing. Provide a "Skip" button. Never show again after completion or dismissal.
- **Make it genuinely useful, not just a tutorial** — The quick win should produce a real artifact (a note, a list item, an imported file). Users should feel they accomplished something, not that they watched a demo.
- **Handle interruptions gracefully** — If the user backgrounds the app, navigates away, or receives a notification mid-session, persist progress and resume where they left off.
- **Different quick wins for different user types** — A power user migrating from another app needs a different quick win (import data) than a brand-new user (create first item). Detect context and choose accordingly.
- **Keep it under 60 seconds** — If a quick win takes longer, it's not quick. Trim steps ruthlessly. Three steps is ideal, five is the maximum.
- **Test with real timing** — Run the flow yourself with a stopwatch. If it feels slow, it is slow.

## References

- **templates.md** — All production Swift templates
- Related: `generators/onboarding-generator` — Full onboarding flow generation
- Related: `generators/milestone-celebration` — Celebration UI for achievements beyond first action
