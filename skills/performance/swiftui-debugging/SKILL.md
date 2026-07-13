---
name: swiftui-debugging
description: Diagnose SwiftUI performance issues including unnecessary re-renders, view identity problems, and slow body evaluations. Use when SwiftUI views are slow, janky, or re-rendering too often.
allowed-tools: [Read, Glob, Grep]
---

# SwiftUI Performance Debugging

Systematic guide for diagnosing and fixing SwiftUI performance problems: unnecessary view re-evaluations, identity issues, expensive body computations, and lazy loading mistakes.

## When This Skill Activates

Use this skill when the user:
- Reports slow or janky SwiftUI views
- Sees excessive view re-renders or body re-evaluations
- Asks about `Self._printChanges()` or view debugging
- Has scrolling performance issues with lists or grids
- Asks why a view keeps updating when nothing changed
- Mentions `@Observable` or `ObservableObject` performance differences
- Wants to understand SwiftUI view identity or diffing
- Uses `AnyView` and asks about performance implications
- Has a hang or stutter traced to SwiftUI rendering

## The Performance Loop

Every investigation follows the same loop: **symptom -> measure -> identify -> optimize -> RE-MEASURE**. The last step is the one people skip -- an "optimization" that was never re-measured is a guess, and SwiftUI guesses are wrong often enough (a fix can shift cost elsewhere) that the loop is not optional. Never close a performance issue on the strength of the diff alone.

## Decision Tree

```
What SwiftUI performance problem are you seeing?
|
+- Views re-render when they should not
|  +- Read body-reevaluation.md
|     +- Self._printChanges() to identify which property changed
|     +- @Observable vs ObservableObject observation differences
|     +- Splitting views to narrow observation scope
|
+- Scrolling is slow / choppy (lists, grids)
|  +- Read lazy-loading.md
|     +- VStack vs LazyVStack, ForEach without lazy container
|     +- List prefetching, grid cell reuse
|
+- Views lose state unexpectedly / animate when they should not
|  +- Read view-identity.md
|     +- Structural vs explicit identity
|     +- .id() misuse, conditional view branching
|
+- Known pitfall (AnyView, DateFormatter in body, etc.)
|  +- Read common-pitfalls.md
|     +- AnyView type erasure, object creation in body
|     +- Over-observation, expensive computations
|
+- General "my SwiftUI app is slow" (unknown cause)
|  +- Start with body-reevaluation.md, then common-pitfalls.md
|  +- Use Instruments SwiftUI template (see Debugging Tools below)
```

## API Availability

| API / Technique | Minimum Version | Reference |
|----------------|-----------------|-----------|
| `Self._printChanges()` | iOS 15 | body-reevaluation.md |
| `@Observable` | iOS 17 / macOS 14 | body-reevaluation.md |
| `@ObservableObject` | iOS 13 | body-reevaluation.md |
| `LazyVStack` / `LazyHStack` | iOS 14 | lazy-loading.md |
| `LazyVGrid` / `LazyHGrid` | iOS 14 | lazy-loading.md |
| `.id()` modifier | iOS 13 | view-identity.md |
| Instruments SwiftUI template | Xcode 14+ | SKILL.md |
| `os_signpost` | iOS 12 | SKILL.md |

## Top 5 Mistakes -- Quick Reference

| # | Mistake | Fix | Details |
|---|---------|-----|---------|
| 1 | Large `ForEach` inside `VStack` or `ScrollView` without lazy container | Wrap in `LazyVStack` -- eager `VStack` creates all views upfront | lazy-loading.md |
| 2 | Using `AnyView` to erase types | Use `@ViewBuilder`, `Group`, or concrete generic types -- `AnyView` defeats diffing | common-pitfalls.md |
| 3 | Creating objects in `body` (`DateFormatter()`, `NumberFormatter()`) | Use `static let` shared instances or `@State` for mutable objects | common-pitfalls.md |
| 4 | Observing entire model when only one property is needed | Split into smaller `@Observable` objects or extract subviews | body-reevaluation.md |
| 5 | Unstable `.id()` values causing full view recreation every render | Use stable identifiers (database IDs, UUIDs), never array indices or random values | view-identity.md |

## Lists, Tables, and ForEach: Identity Is the Cost Model

`List` and `Table` gather **all identifiers eagerly** at load -- even though row *views* are lazy. Cheap, precomputed IDs mean fast loads; an `id:` key path that computes or hashes something expensive runs for every element before anything renders.

**The row-count equation:** rows = elements x views-per-element, and views-per-element must be a **constant** the framework can read without executing your closures.

- ❌ No `if` filters and no `AnyView` inside `ForEach` -- both make views-per-element non-constant, forcing SwiftUI to run every closure just to count rows (and defeating `List`'s constant-count optimizations).
- ✅ Filter in the data, not the view -- and **cache the filtered collection in the model**: an inline `items.filter { ... }` in `body` re-runs linearly on every single body evaluation.
- ✅ `listRowBackground` (and row modifiers generally) go *after* the row's stack, not inside the `ForEach` content per-branch.
- ✅ For `Table`, prefer the streamlined `ForEach(collection)` initializer (no `id:`, no per-row closure gymnastics) -- it keeps row counts statically constant.

## Common Slow-Update Causes

When a body or update shows up slow in the profile, it is almost always one of these:

1. **Expensive dynamic-property initialization** -- e.g. a `@StateObject`/`@State` object doing I/O in its initializer
2. **Work in `body`** -- string interpolation/formatting, sorting, filtering
3. **Heap allocations in `body`** -- formatters, predicates, intermediate arrays
4. **Bundle/resource lookups in `body`** -- `Bundle.main` searches, decoding images synchronously

Move loading and expensive derivation to `.task` (or the model), then re-measure.

**Scope dependencies tightly -- but not obsessively.** Pass the child view the `Image` it renders, not the whole model object, so unrelated model changes stop invalidating it. Don't over-rotate: splitting a huge struct into dozens of single-property parameters costs more in plumbing than it saves. `@Observable` already narrows invalidation to the properties a body actually *reads* -- lean on that first.

## Debugging Tools

### Self._printChanges()

Add to any view body to see what triggered re-evaluation:

```swift
var body: some View {
    let _ = Self._printChanges()
    // ... view content
}
```

Output reads: `ViewName: @self, @identity, _propertyName changed.` Shorthand: `@self` = the view's *value* changed (parent rebuilt it), a named property = that specific dependency changed. See body-reevaluation.md for the full interpretation guide.

Also callable from LLDB without editing code -- pause in a view context and run:

```
(lldb) expression Self._printChanges()
```

It is debug-only API with real runtime cost: use it during an investigation, then delete it. Never ship it.

### Instruments SwiftUI Template

1. **Xcode > Product > Profile** (Cmd+I)
2. Choose **SwiftUI** template (includes View Body, View Properties, Core Animation Commits)
3. Record, reproduce the slow interaction, stop
4. **View Body** lane shows which views had their body evaluated and how often
5. **View Properties** lane shows which properties changed

The redesigned SwiftUI instrument (WWDC25, Instruments 26) upgrades this workflow: it surfaces **long body evaluations** and **long view updates** directly as flagged intervals, with per-update cause analysis -- start there when the question is "which body is blowing the frame budget."

### os_signpost for Custom Measurement

```swift
import os

private let perfLog = OSLog(subsystem: "com.app.perf", category: "SwiftUI")

var body: some View {
    let _ = os_signpost(.event, log: perfLog, name: "MyView.body")
    // ... view content
}
```

View in Instruments with the **os_signpost** instrument to count body evaluations per second.

## Review Checklist

### View Identity
- [ ] No unstable `.id()` values (random, Date(), array index on mutable arrays)
- [ ] Conditional branches (`if`/`else`) do not cause unnecessary view destruction
- [ ] `ForEach` uses stable, unique identifiers from the model

### Body Re-evaluation
- [ ] Views observe only the properties they actually use
- [ ] `@Observable` classes preferred over `ObservableObject` (iOS 17+)
- [ ] No unnecessary `@State` changes that trigger body re-evaluation
- [ ] Large views split into smaller subviews to narrow observation scope

### Lazy Loading
- [ ] Large collections use `LazyVStack` / `LazyHStack`, not `VStack` / `HStack`
- [ ] `List` or lazy stack used for 50+ items
- [ ] No `.frame(maxHeight: .infinity)` on children inside lazy containers (defeats laziness)

### Common Pitfalls
- [ ] No `AnyView` type erasure (use `@ViewBuilder` or `Group`)
- [ ] No object allocation in `body` (`DateFormatter`, `NSPredicate`, view models)
- [ ] Expensive computations moved to background with `task { }` or `Task.detached`
- [ ] Images use `AsyncImage` or `.resizable()` with proper sizing, not raw `UIImage` decoding in body

## Reference Files

| File | Content |
|------|---------|
| [view-identity.md](view-identity.md) | Structural vs explicit identity, `.id()` usage, conditional branching |
| [body-reevaluation.md](body-reevaluation.md) | What triggers body, `_printChanges()`, `@Observable` vs `ObservableObject` |
| [lazy-loading.md](lazy-loading.md) | Lazy vs eager containers, `List`, `ForEach`, grid performance |
| [common-pitfalls.md](common-pitfalls.md) | `AnyView`, object creation in body, over-observation, expensive computations |
| [../profiling/SKILL.md](../profiling/SKILL.md) | General Instruments profiling (Time Profiler, Memory, Energy) |
| [../../swiftui/data-flow/SKILL.md](../../swiftui/data-flow/SKILL.md) | The identity/lifetime mental model behind all of the above -- read it when fixes feel like guesswork |
