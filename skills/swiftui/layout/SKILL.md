---
name: layout
description: SwiftUI layout beyond stacks — the Layout protocol (when custom layout beats GeometryReader), Grid vs lazy grids, custom containers with sections and container values, and lazy-stack/ScrollView performance rules (what breaks laziness, prefetch discipline, scroll APIs). Use when building custom layouts or containers, fixing lazy-stack jank or memory growth, or wiring programmatic/snapping scrolling.
allowed-tools: [Read, Write, Edit, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
---

# SwiftUI Layout & Containers

The layer between "stacks and spacers" and "it scrolls like butter with 100k rows" — Apple's
Layout protocol, container composition, and the lazy-stack rules from the WWDC26 deep dive.
View identity/data-flow questions route to `swiftui/data-flow`.

## When This Skill Activates

- "Make these buttons equal width" / measurement-dependent layout
- Building a reusable container (custom List/board/carousel) that should accept ForEach + sections
- Lazy stack jank, memory growth, scroll-position bugs, broken scroll targeting
- Programmatic scrolling, paging/snapping, scroll-linked effects
- GeometryReader causing layout loops or mangled sizing

## Custom Layout protocol (not GeometryReader)

Reach for a custom `Layout` whenever you must **measure subviews and feed the measurement back
into layout** — GeometryReader measures its *container* and can't influence the engine
(feedback through state risks layout loops). Canonical case: equal-width buttons.

- `sizeThatFits`: propose `.unspecified` to read each subview's ideal size
  (`subviews.map { $0.sizeThatFits(.unspecified) }`); guard empty subviews;
  `replacingUnspecifiedDimensions()` for nil proposal dimensions.
- `placeSubviews`: never assume origin (0,0) — use `bounds.minX/midX` (non-zero origins are
  what make layouts composable); `place(at:anchor:proposal:)` with a proposal that may differ
  from the ideal size (that's how equal widths happen).
- **Respect spacing preferences**: `subviews[i].spacing.distance(to:along:)`, taking the larger
  of conflicting preferences — matching built-in containers. No hardcoded 8s.
- Per-subview data via `LayoutValueKey` (+ a `layoutValue` convenience modifier), read as
  `subview[Key.self]`.
- Cache only after Instruments shows layout cost — it's an optimization, not a requirement.
- **Switch layouts without killing identity**: `AnyLayout(HStackLayout())` ↔ custom layout with
  `.animation(_:value:)` — SwiftUI sees one changing view, so state survives and it animates.
- Don't build fallbacks into the layout — wrap alternatives in `ViewThatFits`.

## Grid decisions

| Need | Use |
|---|---|
| Static 2D with cross-row alignment | `Grid`/`GridRow` (+ `gridCellColumns` to span, `gridColumnAlignment` per column) |
| Scrollable, large content | `LazyVGrid`/`LazyHGrid` (only visible views load; one axis fixed up front) |
| "First arrangement that fits" | `ViewThatFits` |

## Custom containers (Demystify Containers)

Make containers that compose like `List` does:

- API shape: a trailing `@ViewBuilder var content: Content` — callers can then mix static
  views, `ForEach`, and conditionals.
- Iterate **resolved** children with `ForEach(subviews: content)`; need the whole collection
  (count/chunking)? `Group(subviews: content) { subviews in … }`.
- Internalize **declared vs resolved**: one declared ForEach resolves to N subviews; Group to
  its children; EmptyView to zero; `if` conditionally. Counting declared views is a bug.
- Sections are opt-in: `ForEach(sections: content)`, reading `section.header` /
  `section.content`; check `header.isEmpty` before rendering the slot.
- Per-child customization via container values: `extension ContainerValues { @Entry var … }`,
  set with a convenience modifier, read via `subview.containerValues`. Scoping model:
  **Environment flows down · Preferences flow up · container values reach only the direct
  container.** Setting one on a `Section` styles the whole section.

## Lazy stacks & scrolling performance (WWDC26 rules)

LazyVStack builds views only until the viewport fills; totals and offsets are **estimated**
from average placed-view size and corrected as you scroll. Everything below follows from that:

- **One subview per ForEach element, always.** An `if` inside a row (0-or-1 views) forces the
  stack to keep off-screen views + their `@State` alive to preserve indices — and environment
  changes then re-evaluate off-screen bodies. Filter at the data layer (`@Query` predicate);
  gate auth-type conditions *outside* the stack.
- **Never key logic off absolute scroll offset** in a lazy stack (`onScrollGeometryChange` sees
  estimates) — use `onScrollTargetVisibilityChange(threshold: 0.8)` for visibility triggers.
- **Set up in `init`, not `onAppear`** (`_model = State(initialValue:)`): body runs during
  prefetch; `onAppear` fires only on-screen, throwing prefetch work away and causing
  post-appearance size jumps. Start async loads in `init`/`task`.
- **Don't persist meaningful state in row `@State`** — off-screen views are eventually
  released. Hoist (`@State var highlighted: Set<ID>` outside, `@Binding` down).
- `scrollTransition` transforms must stay inside the original frame (scale ✅; rotations
  escaping the frame make views vanish early).
- Don't drive layout from `onGeometryChange` height feedback (content shoves, targeting
  breaks) — that's the custom `Layout` case above.
- Nest `LazyHStack` inside `LazyVStack` freely (unscrolled rows stay unloaded) — but fix child
  heights (`lineLimit`, explicit frames) in the horizontal stacks.
- `pinnedViews: [.sectionHeaders]` pins headers; infinite scroll = trailing
  `ProgressView().onAppear { fetchNextPage() }` after the ForEach.

## The scroll API map

- Snapping/paging: `scrollTargetLayout()` + `scrollTargetBehavior(.viewAligned/.paging)`.
- Track/control position: `scrollPosition` binding; programmatic `ScrollPosition` +
  `scrollTo(id:)` — works for unloaded targets *if* IDs map to stable one-subview elements.
- Scroll-linked effects: `scrollTransition` (enter/leave viewport) and `visualEffect`
  (geometry without GeometryReader) — details in `design/animation-patterns`.
- Reactions: `onScrollGeometryChange` (fine outside lazy estimation),
  `onScrollVisibilityChange` (autoplay/analytics).
- Performance floor: list/scroll internals were rewritten (WWDC25) — macOS lists ~6× faster at
  100k+ rows, and lazy loading works in nested `ScrollView`+`LazyVStack`; profile with the
  SwiftUI instrument (`performance/swiftui-debugging`).

## Output Format

Layout review: `Symptom | Rule violated | Fix` — check the one-subview-per-element rule first
in any lazy-stack complaint; it explains most jank, memory growth, and targeting bugs.

## References

- https://developer.apple.com/videos/play/wwdc2022/10056/ (Compose custom layouts)
- https://developer.apple.com/videos/play/wwdc2024/10146/ (Demystify SwiftUI containers)
- https://developer.apple.com/videos/play/wwdc2026/321/ (Dive into lazy stacks and scrolling)
- Related skills: `swiftui/data-flow` (identity/ForEach IDs), `performance/swiftui-debugging`, `design/animation-patterns` (scroll-linked effects)
