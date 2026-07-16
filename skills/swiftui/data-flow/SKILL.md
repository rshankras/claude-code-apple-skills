---
name: data-flow
description: SwiftUI's actual mental model — view identity, lifetime, and dependencies (the Demystify canon), state ownership decision rules, Observation's per-property tracking, body-performance discipline, and the main-actor concurrency contract. Use when state resets mysteriously, views re-render too often, animations glitch between branches, choosing @State vs @Bindable vs plain property, or debugging "why did body run."
allowed-tools: [Read, Write, Edit, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# SwiftUI Data Flow

Nearly every confusing SwiftUI bug — state that resets, animations that crossfade instead of
move, lists that flash, bodies that run constantly — traces to identity, lifetime, or
dependencies. This is Apple's own mental model (the Demystify sessions + Data Essentials +
Observation), current through the WWDC26 `@State` macro.

## When This Skill Activates

- "@State resets when…" / state loses its value on a condition change
- Views re-render too often; animations crossfade when they should move
- Lists flashing, rows reordering wrongly, `ForEach` misbehaving
- Choosing between `@State`, `@Binding`, `@Bindable`, `@Environment`, plain property
- Debugging with `Self._printChanges()`; concurrency warnings in view code

## Identity: the root concept

SwiftUI sees three things: **identity, lifetime, dependencies**. Views with the same identity
are "different states of the same conceptual UI element"; distinct identities are distinct views.

- **Structural identity** = type + position in the hierarchy. An `if/else` creates **two
  identities** (`_ConditionalContent`) — flipping the branch destroys/recreates the view: state
  resets, transitions crossfade instead of animating.
- **Explicit identity** = `id:` in ForEach or `.id(_:)` (also the target for
  `ScrollViewReader.scrollTo`). Changing an explicit id is a new identity — new lifetime,
  fresh state. (That's the `.id(item.id)` force-refresh trick — use it knowingly.)
- **The inert-modifier rule** (the most under-used fix): prefer one view whose modifiers vary
  over branching —

  ```swift
  // ❌ two identities; state resets, transition crossfades
  if expired { content.opacity(0.3) } else { content }
  // ✅ one identity; cheap, pruned when inert
  content.opacity(expired ? 0.3 : 1.0)
  ```

  Inert values (opacity 1, padding 0) cost nothing. "By default, try to preserve identity."
- Conditionally include a view *inside* a stack rather than conditionally wrapping the stack.

## Lifetime: state is tied to identity

- View **values** are ephemeral — created for comparison, then destroyed. Never rely on the
  struct instance; identity provides continuity.
- "Whenever the identity changes, the state is replaced" — `@State`/`@StateObject` storage
  tears down and reinitializes. If state "randomly resets," find the identity change.
- WWDC26: `@State` is a macro with **lazy initialization of `@Observable` classes** (backported
  to iOS 17) — the stored object initializes once per lifetime, not on every view-value init.
  Remove default values when also assigning in `init` (source-breaking edge).

## ForEach identifier rules (the flashing-list checklist)

- **Stable** — never `var id = UUID()` computed per access (everything flashes/reanimates).
- **Not indices** — insert-at-front reads as insert-at-end; rows animate wrongly.
- **Unique** — duplicate IDs drop rows.
- Use persistent/database-derived IDs; that's what `Identifiable` is for. Range ForEach
  (`0..<n`) only with a constant range.
- **Constant views per element**: an `if` filter inside ForEach (0-or-1 views) or `AnyView`
  forces List to resolve every row just to count them. Filter in the **data**, and cache the
  filtered collection in the model — an inline `.filter` re-runs linearly on every body.
- List/Table gather all identifiers **eagerly** — cheap IDs = fast loads.

## Dependencies: the graph, not the tree

- Every piece of data read in body is a dependency; only views whose dependency changed
  re-run, and value comparison prunes unchanged subtrees. Stable identity is "the backbone of
  the dependency graph."
- **Scope dependencies tightly**: pass the subview what it renders (the `Image`, not the whole
  model). Extracting subviews is free — "breaking up one view into multiple doesn't hurt
  performance" — and shrinks invalidation scope.
- **Observation** (`@Observable`) tracks **per property, per instance** — a view re-renders only
  when a property it actually *read* changes, including through computed properties, arrays,
  optionals, and nesting.
- Migration from `ObservableObject`: drop conformance + `@Published` → `@Observable`;
  `@ObservedObject` → delete or `@Bindable`; `@EnvironmentObject` → `@Environment`.
  Invalidation narrows from whole-object to read-properties — a free performance win.

## State ownership: the decision rules

Ask Apple's three questions: what data does the view need · how does it manipulate it ·
**where does truth live?**

| Situation | Use |
|---|---|
| Display-only, parent owns it | plain `let` property |
| Transient, view-local UI state | `@State` (group related fields into one struct with mutating methods) |
| Write access to someone else's truth | `@Binding` (bindings compose: `$config.note`) |
| Observable model owned by this view | `@State` (lazy-init since WWDC26 macro) |
| Observable model, needs `$model.field` bindings only | `@Bindable` |
| Observable model, globally available | `@Environment` |
| Observable model, none of the above | plain property |

- ❌ Never allocate a reference-type model inline as an `@ObservedObject` default — every
  re-run reallocates it (heap churn, data loss); use `@StateObject` or `@State` + `@Observable`.
- ❌ Two siblings each holding `@State` for the same value desync — lift state to the container
  and hand children Bindings.
- `@SceneStorage` (restoration state, per window) and `@AppStorage` (settings) are stores
  *next to* your model, not the model. Limit total sources of truth.

## Body discipline

- Body must be a pure function, free of side effects — no allocation, I/O, filtering, or
  string-building; move loading to `.task { await … }`.
- Debug why body ran with `Self._printChanges()` (or `expression Self._printChanges()` at an
  LLDB breakpoint): `@self` = view value changed; a named property = that dependency changed.
  Debug-only — never ship it. Deeper workflow: `performance/swiftui-debugging`.
- ❌ `AnyView` hides structure from SwiftUI (worse diagnostics/performance) — use
  `@ViewBuilder` helpers and `switch` instead.

## Concurrency contract (WWDC25)

- `View` is `@MainActor`: body, `@State`, members, and `Task { }` created in body are all
  main-actor — most view code needs zero annotations (and Swift 6.2's default-isolation mode
  removes the rest).
- SwiftUI runs some of *your* closures off-main — `Shape.path(in:)`, `Layout` methods,
  `visualEffect`, `onGeometryChange` — that's why they're `Sendable`. Don't touch
  `self.someState` there; **copy the value in the capture list** (`[pulse]`) and compute from
  the proxies SwiftUI hands you.
- Every `await` can resume after the frame deadline, so time-sensitive state (gesture/scroll
  reactions, button loading indicators) must mutate synchronously *before* starting async work.
  Bridge UI↔async through a piece of state; keep view `Task`s minimal ("inform the model") so
  async logic stays unit-testable.

## Output Format

Data-flow review: `Symptom | Root cause (identity / lifetime / dependency / ownership) | Fix`
— check identity first; it explains most of the rest.

## References

- https://developer.apple.com/videos/play/wwdc2021/10022/ (Demystify SwiftUI — the canon)
- https://developer.apple.com/videos/play/wwdc2020/10040/ (Data Essentials)
- https://developer.apple.com/videos/play/wwdc2023/10149/ (Discover Observation)
- https://developer.apple.com/videos/play/wwdc2023/10160/ (Demystify SwiftUI performance)
- https://developer.apple.com/videos/play/wwdc2025/266/ (Explore concurrency in SwiftUI)
- Related skills: `performance/swiftui-debugging` (Instruments workflow), `swiftui/layout`, `swift/concurrency-patterns`, `ios/coding-best-practices`
