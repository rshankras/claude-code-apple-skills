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
| Redesigned SwiftUI instrument | Xcode 26 / Instruments 26 | SKILL.md |
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

### The Redesigned SwiftUI Instrument (Instruments 26 -- WWDC25 306)

Requires Xcode 26 and recent OS releases on the profiled device (trace-recording support lives in the OS). Cmd+I builds Release and opens Instruments; the **SwiftUI template** bundles the SwiftUI instrument, **Time Profiler**, and **Hangs + Hitches** instruments. Start here when the question is "which body is blowing the frame budget."

**Why body time matters:** each frame, the app handles events, runs the bodies of changed views, and must finish before the frame deadline; a body that overruns delays the whole train and the previous frame stays on screen too long -- a hitch. Two failure shapes blow the deadline the same way: (1) one long body update, (2) many individually-fast but unnecessary updates in one frame (WWDC25 306).

**Top-level lanes:**

| Lane | Meaning |
|------|---------|
| Update Groups | When SwiftUI is doing *any* work. If CPU spikes while this lane is empty, the problem is **outside SwiftUI** -- switch to the general profiling skill |
| Long View Body Updates | `body` properties taking too long |
| Long Representable Updates | UIView/UIViewController/NSView representable updates taking too long |
| Other Long Updates | All other long SwiftUI work |

Color coding: long updates are **orange or red by likelihood of contributing to a hitch or hang -- investigate red first**; normal updates are gray. Long updates at the very start of a trace are launch-time initial hierarchy builds -- expected, they won't hitch; don't chase them (WWDC25 306).

**Workflow for a long body:**
1. Expand the SwiftUI track -> select the **View Body Updates** subtrack; the detail pane summarizes every body that ran (process -> module -> view type)
2. Switch the summary dropdown to **Long View Body Updates** to filter to offenders with counts
3. Hover a view name -> arrow -> **Show Updates** -> right-click one -> **Set Inspection Range and Zoom**
4. Select the **Time Profiler** track to see exactly what the CPU did during that one body run (Option-click expands the main-thread stack; Cmd+F to find your body frame)
5. Fix, re-record, and confirm the view vanished from the Long View Body Updates summary

The classic find (the session's demo): a computed property read in `body` created a `NumberFormatter` + `MeasurementFormatter` and formatted a string on every body run, per visible row. Fix: create formatters **once** (stored property on the model/manager), precompute strings into an **ID-keyed cache**, and let `body` do a dictionary lookup (WWDC25 306). See common-pitfalls.md for the general rule.

### Cause & Effect Graph: Why Did Body Run? (WWDC25 306)

Backtraces explain imperative UIKit updates but not SwiftUI -- a SwiftUI backtrace is recursive AttributeGraph frames and never says why *your* view updated. The mechanics: changing `@State` doesn't update views immediately; it creates a **transaction** that marks the state's attribute **outdated**, outdated-ness propagates down dependent attributes as a cheap flag, and at frame time SwiftUI re-evaluates only outdated attributes. So "why did body run?" really means "**what marked my body outdated?**" -- which is exactly what the instrument's **Cause & Effect Graph** answers (hover-arrow on a view name -> Show Cause & Effect Graph):

- Nodes are updates, one icon per kind (view body, state change, gesture, `@Observable` change, environment); **blue nodes = your code / your interactions**; the graph reads left (cause) -> right (effect)
- Edges are labeled **"update"** (caused a re-run) or **"Creation"** (made the view first appear)
- A **dimmed icon** = the view was notified and checked but its **body did not run**
- Selecting a state-change node shows a **backtrace of where the value was set**

The demo bug it exposed: every row's `body` called `isFavorite(landmark)`, which read the shared `landmarks` array on an `@Observable` model -- so **every row depended on the whole array**, and one tap re-ran every visible row's body.

```swift
// ❌ Every row reads the shared array -> @Observable makes every row depend on it
func isFavorite(_ landmark: Landmark) -> Bool {
    favoritesCollection.landmarks.contains(landmark)   // whole-array dependency
}

// ✅ Per-item @Observable view model -> each row depends only on its own flag
@Observable class ViewModel { var isFavorite: Bool = false }

@ObservationIgnored private var viewModels: [Landmark.ID: ViewModel] = [:]
// ^ @ObservationIgnored: don't observe the dictionary itself, only each model

func isFavorite(_ landmark: Landmark) -> Bool {
    viewModel(for: landmark).isFavorite   // body's read = narrow dependency
}
func addFavorite(_ landmark: Landmark) {
    favoritesCollection.landmarks.append(landmark)
    viewModel(for: landmark).isFavorite = true
}
```

Verified in the trace: **2 taps = exactly 2 body updates**. Rule: **make data dependencies as granular as the UI that renders them** (WWDC25 306).

**Environment rule:** `EnvironmentValues` is one value-type struct, and every view using `@Environment` depends on the whole struct. Any environment change notifies all such views; each compares its own key's value -- body only re-runs if it changed, but **the comparison itself costs time in every reading view**. Never store rapidly-changing values (geometry, timers) in the environment (WWDC25 306). The graph distinguishes **External Environment** nodes (changed outside SwiftUI, e.g. color scheme) from **EnvironmentWriter** nodes (changed via `.environment(...)`).

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
