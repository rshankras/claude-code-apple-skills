---
name: milestone-celebration
description: Generates achievement celebration UI with confetti animations, badge unlocks, progress milestones, haptic feedback, and optional share-to-social. Use when user wants to celebrate achievements, show confetti, display milestone badges, or trigger rewards on key thresholds.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Milestone Celebration Generator

Generate a production milestone celebration system with confetti particle animations via `CAEmitterLayer`, achievement badge views with locked/unlocked states, a celebration overlay with spring animations, haptic feedback, and optional shareable achievement cards — all triggered automatically when users hit key thresholds.

## When This Skill Activates

Use this skill when the user:
- Asks to "add celebrations" or "celebrate achievements"
- Wants "confetti animation" or "particle effects for milestones"
- Mentions "achievement badges" or "badge unlock animation"
- Asks about "milestone rewards" or "progress milestones"
- Wants to "celebrate achievement" or "trigger celebration on threshold"
- Asks about "level-up animation" or "gamification celebrations"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 17+ / macOS 14+ for `@Observable`, spring animations, `sensoryFeedback`)
- [ ] Check for `UIKit` availability (iOS — `CAEmitterLayer` for confetti, haptics)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing celebration/animation code:
```
Glob: **/*Confetti*.swift, **/*Celebration*.swift, **/*Achievement*.swift, **/*Milestone*.swift, **/*Badge*.swift
Grep: "CAEmitterLayer" or "CAEmitterCell" or "UINotificationFeedbackGenerator" or "confetti" or "celebration"
```

If existing celebration or gamification library found (e.g., custom confetti, third-party particle libraries):
- Ask if user wants to replace or integrate with it
- If keeping, advise on best practices instead of generating

### 3. Platform Detection
Determine if generating for iOS (UIKit-based confetti + haptics) or macOS (Core Animation confetti, no haptics) or both (cross-platform with feature gates).

## Configuration Questions

Ask user via AskUserQuestion:

1. **Celebration type?** (multi-select)
   - Confetti burst (full-screen particle animation)
   - Badge unlock (icon reveal with glow animation)
   - Level-up (progress ring fill + title transition)
   - Custom (user defines their own celebration style)

2. **Haptic feedback?**
   - Yes — success haptic on celebration trigger (recommended)
   - No — silent celebrations only

3. **Shareable achievement card?**
   - Yes — render achievement as image for social sharing via `ShareLink`
   - No — in-app celebration only

4. **Sound effects?**
   - Yes — play system sound or bundled audio on celebration
   - No — visual only

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `Milestone.swift` — Model with id, title, description, threshold, icon, unlock state. `Codable` + `Sendable`.
2. `MilestoneTracker.swift` — `@Observable` class tracking progress toward milestones, checking thresholds, triggering celebrations. Persists unlock state via `UserDefaults` or file storage.
3. `ConfettiView.swift` — `UIViewRepresentable` wrapping `CAEmitterLayer` for confetti particle animation. Configurable colors, duration, density. Respects Reduce Motion.

### Step 3: Create UI Files
4. `CelebrationOverlay.swift` — Full-screen overlay combining confetti + badge reveal + congratulations message. Auto-dismisses after configurable duration. Uses `withAnimation(.spring)`.
5. `MilestoneBadgeView.swift` — Individual badge view with locked/unlocked states, SF Symbol icon, progress ring for partial progress.
6. `MilestoneCollectionView.swift` — Grid layout of all milestones showing locked/unlocked state with progress indicators.

### Step 4: Create Optional Files
Based on configuration:
- `HapticManager.swift` — If haptic feedback selected (thin wrapper around `UINotificationFeedbackGenerator` / `UIImpactFeedbackGenerator`)
- `ShareableMilestoneCard.swift` — If shareable selected (renders milestone as image via `ImageRenderer` + `ShareLink`)

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/MilestoneCelebration/`
- If `App/` exists -> `App/MilestoneCelebration/`
- Otherwise -> `MilestoneCelebration/`

## Output Format

After generation, provide:

### Files Created
```
MilestoneCelebration/
├── Milestone.swift              # Model with threshold, icon, unlock state
├── MilestoneTracker.swift       # @Observable tracker with persistence
├── ConfettiView.swift           # CAEmitterLayer confetti animation
├── CelebrationOverlay.swift     # Full-screen celebration overlay
├── MilestoneBadgeView.swift     # Badge with locked/unlocked + progress ring
├── MilestoneCollectionView.swift # Grid of all milestones
├── HapticManager.swift          # Celebration haptics (optional)
└── ShareableMilestoneCard.swift # Achievement share card (optional)
```

### Integration Steps

**Trigger celebration on threshold:**
```swift
struct WorkoutCompleteView: View {
    @State private var tracker = MilestoneTracker()
    @State private var celebratingMilestone: Milestone?

    var body: some View {
        VStack {
            // ... workout summary content ...

            Button("Save Workout") {
                saveWorkout()
                let newCount = totalWorkouts + 1
                if let milestone = tracker.checkThreshold(value: newCount, category: .workouts) {
                    celebratingMilestone = milestone
                }
            }
        }
        .overlay {
            if let milestone = celebratingMilestone {
                CelebrationOverlay(milestone: milestone) {
                    celebratingMilestone = nil
                }
            }
        }
    }
}
```

**Badge collection screen:**
```swift
struct ProfileView: View {
    @State private var tracker = MilestoneTracker()

    var body: some View {
        NavigationStack {
            ScrollView {
                MilestoneCollectionView(
                    milestones: tracker.allMilestones,
                    columns: 3
                )
            }
            .navigationTitle("Achievements")
        }
    }
}
```

**Share an achievement:**
```swift
struct MilestoneDetailView: View {
    let milestone: Milestone
    @State private var showShareCard = false

    var body: some View {
        VStack {
            MilestoneBadgeView(milestone: milestone, size: .large)
            Text(milestone.title).font(.title2.bold())
            Text(milestone.milestoneDescription).foregroundStyle(.secondary)

            if milestone.isUnlocked {
                Button("Share Achievement") {
                    showShareCard = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showShareCard) {
            ShareableMilestoneCard(milestone: milestone, brandName: "FitApp")
        }
    }
}
```

### Testing

```swift
@Test
func milestoneUnlocksAtThreshold() {
    let tracker = MilestoneTracker(store: InMemoryMilestoneStore())
    let milestone = Milestone(
        id: "first-10",
        title: "First 10",
        milestoneDescription: "Complete 10 workouts",
        threshold: 10,
        iconName: "flame.fill"
    )
    tracker.register(milestone)

    let result = tracker.checkThreshold(value: 10, for: milestone.id)
    #expect(result != nil)
    #expect(result?.isUnlocked == true)
    #expect(result?.unlockedDate != nil)
}

@Test
func milestoneDoesNotUnlockBelowThreshold() {
    let tracker = MilestoneTracker(store: InMemoryMilestoneStore())
    let milestone = Milestone(
        id: "first-10",
        title: "First 10",
        milestoneDescription: "Complete 10 workouts",
        threshold: 10,
        iconName: "flame.fill"
    )
    tracker.register(milestone)

    let result = tracker.checkThreshold(value: 9, for: milestone.id)
    #expect(result == nil)
}

@Test
func confettiRespectsReduceMotion() {
    // When Reduce Motion is enabled, ConfettiView should not emit particles
    let config = ConfettiConfiguration(reduceMotionOverride: true)
    #expect(config.shouldAnimate == false)
}

@Test
func celebrationOverlayAutoDismisses() async throws {
    // Verify overlay dismisses after the configured duration
    let expectation = XCTestExpectation(description: "Dismissed")
    let duration: TimeInterval = 0.5
    // Test that the onDismiss callback fires after duration
}
```

## Common Patterns

### Trigger Celebration on Threshold
Best for: fitness, learning, productivity apps.
- Define milestones with numeric thresholds (10 workouts, 100 pages read, 7-day streak)
- `MilestoneTracker` checks values against registered milestones
- Celebration fires only on the first crossing — subsequent calls are no-ops
- Persist unlock state so celebrations do not repeat

### Badge Collection View
Best for: gamification, loyalty, progression systems.
- Grid of all milestones: locked ones are dimmed/grayscale, unlocked ones are vibrant
- Progress ring shows how close user is to unlocking each badge
- Tapping a badge shows detail view with full description and share option
- Counter showing "12 of 20 unlocked" at the top

### Share Achievement
Best for: social apps, fitness, competitions.
- Render the unlocked badge + title + metric as a shareable image
- Use `ImageRenderer` at `@2x` scale for Retina quality
- Include app branding and optional QR code for deep linking
- Integrate with `ShareLink` for native share sheet

## Gotchas

### CAEmitterLayer Performance on Older Devices
- Confetti with many particles (200+) can drop frames on A11 and older chips
- Cap `birthRate` at 50-80 for smooth 60fps on most devices
- Use `emitterCells` with only 3-5 distinct shapes to reduce GPU draw calls
- Stop emission after burst duration — do not leave the emitter running indefinitely
- Profile with Instruments (Core Animation template) if users report frame drops

### Reduce Motion Accessibility
- Always check `UIAccessibility.isReduceMotionEnabled` before starting particle animations
- When Reduce Motion is on: skip confetti, show a static badge reveal or a simple fade-in instead
- Use `@Environment(\.accessibilityReduceMotion)` in SwiftUI for reactive updates
- Provide an equally rewarding experience without animation — the badge reveal and message still appear

### Haptic Feedback on Non-Supporting Devices
- `UINotificationFeedbackGenerator` is a no-op on devices without a Taptic Engine (e.g., iPod touch, iPad)
- Always guard with `CHHapticEngine.capabilitiesForHardware().supportsHaptics` before preparing generators
- On macOS, haptics are not available — gate with `#if canImport(UIKit)` and `#if os(iOS)`
- Use `.sensoryFeedback(.success, trigger:)` modifier on iOS 17+ for a simpler SwiftUI-native approach

### Sound Effect Considerations
- Use `AudioServicesPlaySystemSound` for lightweight celebration sounds (no audio session needed)
- Respect the device silent/mute switch — `AudioServicesPlaySystemSound` honors it automatically
- For custom sounds, keep files under 30 seconds and use CAF or WAV format
- Do not play sounds when Reduce Motion is enabled (some users enable it for sensory reasons)

### Persistence Edge Cases
- If the app is terminated between unlocking a milestone and persisting it, the user may see the celebration again
- Use `UserDefaults` for simple unlock flags or a lightweight JSON file for full milestone state
- For `SwiftData` or `CoreData` apps, consider storing unlock state alongside the user's data model
- Sync unlock state via CloudKit if the app supports multiple devices

## References

- **templates.md** — All production Swift templates
- Related: `generators/streak-tracker` — Streak tracking pairs naturally with milestone celebrations
- Related: `generators/share-card` — Shareable achievement card rendering and social sharing
- Related: `generators/variable-rewards` — Variable reward schedules for deeper engagement
