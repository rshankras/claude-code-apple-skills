---
name: animation-patterns
description: SwiftUI animation patterns including springs, transitions, PhaseAnimator, KeyframeAnimator, and SF Symbol effects. Use when implementing, reviewing, or fixing animation code on iOS/macOS.
allowed-tools: [Read, Glob, Grep]
---

# Animation Patterns

Correct API shapes and patterns for SwiftUI animations. Prevents the most common mistakes: mixed spring parameter generations, wrong PhaseAnimator/KeyframeAnimator closure signatures, and using matchedGeometryEffect where matchedTransitionSource is needed.

## When This Skill Activates

Use this skill when the user:
- Asks to add, fix, or review **animation** code
- Mentions **spring**, **bounce**, or **snappy** animations
- Wants **view transitions** (insertion/removal, hero, zoom)
- Asks about **PhaseAnimator** or **KeyframeAnimator**
- Wants **SF Symbol effects** (bounce, pulse, wiggle, breathe)
- Mentions **matchedGeometryEffect** or **matchedTransitionSource**
- Asks about **reduce motion** / animation accessibility
- Wants to sequence or chain animations
- Mentions **withAnimation**, **animation completions**, or **Transaction**

## Decision Tree

Choose the right reference file based on what the user needs:

```
What are you animating?
│
├─ A state change (opacity, position, color)
│  └─ → core-animations.md
│     ├─ withAnimation { } — explicit animation
│     ├─ .animation(_:value:) — implicit animation
│     └─ Spring configuration — .spring, .bouncy, .snappy, .smooth
│
├─ A multi-step / sequenced animation
│  └─ → phase-keyframe-animators.md (PhaseAnimator)
│     └─ Cycles through discrete phases automatically or on trigger
│
├─ A complex multi-property animation (scale + rotation + offset)
│  └─ → phase-keyframe-animators.md (KeyframeAnimator)
│     └─ Timeline-based keyframes with per-property tracks
│
├─ A view appearing / disappearing
│  └─ → transitions.md
│     ├─ .transition() — insertion/removal
│     ├─ .contentTransition() — text/symbol changes
│     └─ .asymmetric() — different in/out
│
├─ A hero / zoom navigation transition
│  └─ → transitions.md (matchedTransitionSource section)
│     ├─ iOS 18+: matchedTransitionSource + .navigationTransition(.zoom)
│     ├─ UIKit: preferredTransition = .zoom (capture stable IDs, never views)
│     └─ iOS 14+: matchedGeometryEffect (NOT for NavigationStack)
│
├─ A UIKit view driven by SwiftUI state or gestures
│  └─ → transitions.md (Bridging UIKit and SwiftUI Animations)
│     └─ UIView.animate(.spring(...)) / context.animate in updateUIView
│
├─ An SF Symbol animation
│  └─ → symbol-effects.md
│     └─ .symbolEffect(.bounce), .pulse, .wiggle, .breathe, .rotate
│
└─ Spring physics / timing configuration
   └─ → core-animations.md (Spring Configurations section)
```

## API Availability

| API | Minimum Version | Reference |
|-----|----------------|-----------|
| `withAnimation` | iOS 13 | core-animations.md |
| `.animation(_:value:)` | iOS 13 | core-animations.md |
| `.spring(response:dampingFraction:)` | iOS 13 | core-animations.md |
| `.matchedGeometryEffect` | iOS 14 | transitions.md |
| `.transition(.push(from:))` | iOS 16 | transitions.md |
| `.contentTransition(.numericText())` | iOS 16 | transitions.md |
| `PhaseAnimator` | iOS 17 | phase-keyframe-animators.md |
| `KeyframeAnimator` | iOS 17 | phase-keyframe-animators.md |
| `.spring(duration:bounce:)` | iOS 17 | core-animations.md |
| Spring presets (`.bouncy`, `.snappy`, `.smooth`) | iOS 17 | core-animations.md |
| `withAnimation(_:completionCriteria:_:completion:)` | iOS 17 | core-animations.md |
| `.symbolEffect()` | iOS 17 | symbol-effects.md |
| `.transition(.blurReplace)` | iOS 17 | transitions.md |
| `.contentTransition(.symbolEffect(.replace))` | iOS 17 | transitions.md |
| `.matchedTransitionSource` | iOS 18 | transitions.md |
| `.navigationTransition(.zoom)` — push, sheet, fullScreenCover | iOS 18 | transitions.md |
| `UIViewController.preferredTransition = .zoom` | iOS 18 | transitions.md |
| `UIView.animate(_: Animation)` / `context.animate` | iOS 18 | transitions.md |

## Top 5 Mistakes — Quick Reference

| # | Mistake | Fix | Details |
|---|---------|-----|---------|
| 1 | `spring(response:bounce:)` — mixing parameter generations | Use either `spring(response:dampingFraction:)` (iOS 13) or `spring(duration:bounce:)` (iOS 17) | core-animations.md |
| 2 | `.animation(.spring())` without `value:` parameter | Always pass `value:` — the no-value variant is deprecated (iOS 15) | core-animations.md |
| 3 | Wrong PhaseAnimator closure signature | `PhaseAnimator(phases) { content, phase in }` — not `{ phase in }` | phase-keyframe-animators.md |
| 4 | Using `matchedGeometryEffect` for NavigationStack transitions | Use `matchedTransitionSource` + `.navigationTransition(.zoom)` on iOS 18+ | transitions.md |
| 5 | Using `withAnimation` for SF Symbol effects | Use `.symbolEffect()` modifier instead | symbol-effects.md |

## Review Checklist

When reviewing animation code, verify:

- [ ] **Reduce motion** — animations respect `AccessibilityMotionEffect` or `UIAccessibility.isReduceMotionEnabled`; provide non-motion alternatives
- [ ] **Duration limits** — no animation exceeds ~0.5s for UI feedback; longer only for decorative/ambient effects
- [ ] **Spring vs linear** — springs for interactive/physical motion; linear/easeInOut only for opacity fades or progress indicators
- [ ] **No deprecated APIs** — `.animation(.spring())` without `value:` is deprecated; `.animation(nil)` is replaced by `withTransaction`
- [ ] **Correct spring generation** — parameter names match the same API generation (never mix `response` with `bounce`)
- [ ] **Completion handlers** — using `withAnimation(_:completionCriteria:_:completion:)` (iOS 17+), not inventing `.onAnimationCompleted`
- [ ] **Transition scope** — `.transition()` only affects views inside `if`/`switch` controlled by state; not for views that are always present

## Reference Files

| File | Content |
|------|---------|
| [core-animations.md](core-animations.md) | withAnimation, springs, completions, transactions, timing curves, fluid-interface principles (momentum projection, rubber-banding, hysteresis) |
| [phase-keyframe-animators.md](phase-keyframe-animators.md) | PhaseAnimator, KeyframeAnimator, custom animations |
| [transitions.md](transitions.md) | View transitions, matched geometry, navigation/zoom transitions (SwiftUI + UIKit), interruptibility, UIKit↔SwiftUI bridging, gesture-driven springs |
| [symbol-effects.md](symbol-effects.md) | SF Symbol effects, accessibility |
