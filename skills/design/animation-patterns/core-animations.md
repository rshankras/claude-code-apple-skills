# Core Animations

Fundamentals of SwiftUI animation: `withAnimation`, spring configurations, completions, transactions, and timing curves.

## withAnimation vs .animation Modifier

Two ways to animate state changes. Use one or the other — never both on the same property.

### withAnimation (Explicit — Preferred)

Wraps a state change and animates all views that depend on that state:

```swift
Button("Toggle") {
    withAnimation(.spring) {
        isExpanded.toggle()
    }
}
```

Use when: you control the state change site (button tap, gesture, event).

### .animation(_:value:) (Implicit)

Watches a value and animates whenever it changes:

```swift
Circle()
    .offset(y: isActive ? -20 : 0)
    .animation(.spring, value: isActive)
```

Use when: the state change comes from somewhere else (parent view, environment, binding).

### Deprecated: .animation Without value:

```swift
// ❌ Deprecated in iOS 15 — animates ALL state changes, causes unexpected behavior
Circle()
    .animation(.spring())

// ✅ Always pass value:
Circle()
    .animation(.spring, value: isActive)
```

## Spring Configurations

Three API generations exist. **Never mix parameter names across generations.**

### Generation 1: Physics Parameters (iOS 13+)

Raw physics model. Rarely needed — hard to reason about visually.

```swift
Spring(mass: 1.0, stiffness: 100.0, damping: 10.0, initialVelocity: 0.0)
```

### Generation 2: Response / Damping Fraction (iOS 13+)

The most common in existing codebases:

```swift
.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
```

| Parameter | Meaning | Range |
|-----------|---------|-------|
| `response` | Duration of one oscillation (seconds) | 0.0+ (0 = instantaneous) |
| `dampingFraction` | How quickly oscillation dies | 0 = forever, 1 = no bounce, >1 = overdamped |
| `blendDuration` | Smoothing when interrupted (usually 0) | 0.0+ |

### Generation 3: Duration / Bounce (iOS 17+)

Simpler API. **Use this for new code targeting iOS 17+.**

```swift
.spring(duration: 0.5, bounce: 0.3)
```

| Parameter | Meaning | Range |
|-----------|---------|-------|
| `duration` | Approximate settling time (seconds) | 0.0+ |
| `bounce` | Bounciness | -1 to 1 (0 = no bounce, negative = overdamped) |

### Spring Presets (iOS 17+)

Use these instead of manual configuration when possible:

```swift
.spring            // Default spring — slight bounce, natural feel
.bouncy            // .spring(duration: 0.5, bounce: 0.3) — playful
.snappy            // .spring(duration: 0.3, bounce: 0.15) — quick, subtle bounce
.smooth            // .spring(duration: 0.5, bounce: 0.0) — no bounce, gentle settle
```

### Migration Table

| Generation 2 | Generation 3 Equivalent |
|--------------|------------------------|
| `.spring(response: 0.5, dampingFraction: 0.7)` | `.spring(duration: 0.5, bounce: 0.3)` |
| `.spring(response: 0.3, dampingFraction: 0.85)` | `.snappy` |
| `.spring(response: 0.5, dampingFraction: 1.0)` | `.smooth` |
| `.spring()` (default) | `.spring` |

### Anti-Patterns

```swift
// ❌ WRONG: Mixing generation 2 and 3 parameter names
.spring(response: 0.5, bounce: 0.3)   // Does NOT compile

// ❌ WRONG: Mixing generation 1 and 2
.spring(mass: 1.0, dampingFraction: 0.7)  // Does NOT compile

// ✅ Pick ONE generation:
.spring(response: 0.5, dampingFraction: 0.7)  // Gen 2
.spring(duration: 0.5, bounce: 0.3)            // Gen 3
.bouncy                                         // Gen 3 preset
```

## Animation Completions (iOS 17+)

Run code after an animation finishes. Uses `withAnimation` with a `completion` closure.

```swift
withAnimation(.spring) {
    isExpanded = true
} completion: {
    showContent = true
}
```

Full signature:

```swift
withAnimation(
    _ animation: Animation,
    completionCriteria: AnimationCompletionCriteria = .logicallyComplete,
    _ body: () -> Void,
    completion: @Sendable () -> Void
)
```

### Completion Criteria

| Criteria | Meaning |
|----------|---------|
| `.logicallyComplete` | Fires when animation reaches target (spring may still be settling) |
| `.removed` | Fires when animation is fully removed (spring has fully settled) |

```swift
// Wait for spring to fully settle before enabling interaction
withAnimation(.bouncy, completionCriteria: .removed) {
    cardOffset = .zero
} completion: {
    isInteractive = true
}
```

### Anti-Pattern

```swift
// ❌ WRONG: This modifier does NOT exist
view.onAnimationCompleted(for: offset) { }

// ❌ WRONG: This modifier does NOT exist
view.onAnimationEnd { }

// ✅ Use withAnimation completion:
withAnimation(.default) {
    offset = targetOffset
} completion: {
    handleAnimationDone()
}
```

## Transaction Control

### withTransaction — Override Animation

Replace the animation for a specific state change:

```swift
var transaction = Transaction(animation: .none)
withTransaction(transaction) {
    // This state change happens instantly, no animation
    selectedTab = newTab
}
```

### Disabling Animation

```swift
// Disable animation for a specific change
var transaction = Transaction()
transaction.disablesAnimations = true
withTransaction(transaction) {
    resetPosition()
}

// Or use withAnimation(.none) — simpler for one-off cases (iOS 17+)
withAnimation(.none) {
    resetPosition()
}
```

### transaction Modifier

Override animations on a per-view basis:

```swift
Text(count, format: .number)
    .contentTransition(.numericText())
    .transaction { transaction in
        transaction.animation = .snappy
    }
```

## Timing Curves

Non-spring animations for specific use cases (opacity fades, progress bars).

```swift
.linear                        // Constant speed
.linear(duration: 0.3)         // Constant speed, 0.3s

.easeIn                        // Slow start, fast end
.easeIn(duration: 0.3)

.easeOut                       // Fast start, slow end
.easeOut(duration: 0.3)

.easeInOut                     // Slow start and end
.easeInOut(duration: 0.3)

.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4)  // Custom cubic bezier
```

**When to use timing curves vs springs:**
- Springs: interactive elements, things that feel physical (cards, buttons, toggles)
- `easeInOut`: opacity fades, color transitions
- `linear`: progress indicators, continuous rotation

## Animation Modifiers

Chain these onto any `Animation` value:

```swift
// Repeat forever (for loading spinners, pulsing effects)
.linear(duration: 1.0).repeatForever(autoreverses: false)

// Repeat a fixed number of times
.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)

// Delay before starting
.spring.delay(0.2)

// Change speed (2x faster)
.spring.speed(2.0)
```

### Loading Spinner Example

```swift
struct Spinner: View {
    @State private var isRotating = false

    var body: some View {
        Image(systemName: "arrow.trianglehead.2.clockwise")
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                .linear(duration: 1.0).repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}
```

### Staggered Animation Example

```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemRow(item: item)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(
            .spring.delay(Double(index) * 0.05),
            value: isVisible
        )
}
```

## Common Patterns

### Animate on Appear

```swift
struct AppearAnimation: View {
    @State private var appeared = false

    var body: some View {
        ContentView()
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)
            .onAppear {
                withAnimation(.spring) {
                    appeared = true
                }
            }
    }
}
```

### Animatable Modifier for Custom Properties

For properties SwiftUI doesn't natively animate (like text size, stroke dash):

```swift
struct CountingText: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value))")
    }
}
```

Use `withAnimation` to drive the value change — SwiftUI interpolates `animatableData` each frame.
