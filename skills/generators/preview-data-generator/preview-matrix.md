# The Preview Variant Matrix

Reference for the `preview-data-generator` skill: the axes a view should be previewed across, the APIs to express them, and how to scale the matrix sensibly.

## The Axes

Each axis catches a different class of bug. Pick the ones the view is actually exposed to — don't emit every axis for every view.

| Axis | Variants | Catches | API |
|------|----------|---------|-----|
| **Data state** | loaded · empty · loading · error | The most common prototyping gap | pass state/VM into the view |
| **Appearance** | light · dark | Hardcoded colors, contrast | `.preferredColorScheme(.dark)` |
| **Dynamic Type** | default · AX3 · AX5 | Truncation, overlap, fixed heights | `.dynamicTypeSize(.accessibility5)` |
| **Locale / direction** | long language (de) · RTL (ar/he) · pseudoloc | Layout that assumes English/LTR | `.environment(\.locale,…)` + `.environment(\.layoutDirection, .rightToLeft)` |
| **Device / size** | SE · Pro Max · iPad | Small-screen crowding, wide layouts | canvas device picker / `.fixedLayout` trait |
| **Accessibility** | bold text · high contrast · reduce motion | Inaccessible UI | `.environment(\.legibilityWeight,…)`, `.accessibilityReduceMotion` |
| **Orientation** | portrait · landscape | Constraint breakage | `.landscapeLeft` trait |

## Data-State Previews (the UI-prototype payoff)

This is the axis people most often skip and most need. Drive it through whatever your view reads — an explicit `state` enum, a pinned ViewModel, or a seeded container:

```swift
#Preview("Loaded")  { ArticleListView(state: .loaded(Article.previewList)) }
#Preview("Empty")   { ArticleListView(state: .empty) }
#Preview("Loading") { ArticleListView(state: .loading) }
#Preview("Error")   { ArticleListView(state: .error("No connection")) }
```

If the view owns a ViewModel, use the pinned instances from **preview-data-patterns.md**:

```swift
#Preview("Empty") { ArticleListView(viewModel: .previewEmpty) }
```

## Appearance & Accessibility

```swift
#Preview("Dark")        { ArticleDetailView(article: .preview).preferredColorScheme(.dark) }
#Preview("XXL Text")    { ArticleDetailView(article: .preview).dynamicTypeSize(.accessibility5) }
#Preview("Bold + Dark") { ArticleDetailView(article: .preview).environment(\.legibilityWeight, .bold).preferredColorScheme(.dark) }
```

Prefer the dedicated modifiers (`.dynamicTypeSize`, `.preferredColorScheme`) where they exist; fall back to `.environment(\.…)` for keys without one.

## Locale & RTL

```swift
#Preview("German")  { ArticleDetailView(article: .previewLongTitle).environment(\.locale, .init(identifier: "de")) }
#Preview("Arabic RTL") {
    ArticleDetailView(article: .preview)
        .environment(\.locale, .init(identifier: "ar"))
        .environment(\.layoutDirection, .rightToLeft)
}
```

German/Finnish stress string length; Arabic/Hebrew flip the layout. If the project already has locale preview helpers from `generators/localization-setup`, reuse those instead.

## Layout Traits

Preview traits shape the canvas frame itself:

| Trait | Effect |
|-------|--------|
| `.sizeThatFitsLayout` | Canvas hugs the view — ideal for cells, buttons, small components |
| `.fixedLayout(width:height:)` | Pin an exact size |
| `.landscapeLeft` / `.landscapeRight` / `.portrait` | Force orientation |
| `.modifier(SomeModifier())` | Apply a `PreviewModifier` (e.g. shared sample data) |

```swift
#Preview("Cell", traits: .sizeThatFitsLayout) { ArticleRow(article: .preview) }
#Preview("Landscape", traits: .landscapeLeft) { ArticleDetailView(article: .preview) }
```

Combine traits with sample-data modifiers: `#Preview(traits: .sampleData, .sizeThatFitsLayout) { … }`.

## Device Variants

With the `#Preview` macro, the **canvas device picker** is the primary way to switch devices — you don't need one preview per device. Reserve explicit device previews for views that genuinely differ by size class (e.g. an iPad sidebar layout):

```swift
// Pin a small-screen check when crowding is a real risk:
#Preview("Compact", traits: .fixedLayout(width: 320, height: 568)) {
    ArticleListView(state: .loaded(Article.previewList))
}
```

(Legacy `.previewDevice("iPhone SE (3rd generation)")` only applies under `PreviewProvider` — see fallback below.)

## Deployment-Target Fallbacks

Generate the right API for the project's minimum target:

| Target | Preview API | Shared data |
|--------|-------------|-------------|
| **iOS 18+ / Xcode 16** | `#Preview` + `@Previewable` | `PreviewModifier` (cached) |
| **iOS 17+** | `#Preview` macro | per-preview `.modelContainer(inMemory:)` |
| **below iOS 17** | `PreviewProvider` struct | manual sample injection |

`PreviewProvider` fallback (when the macro isn't available):

```swift
#if DEBUG
struct ArticleListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ArticleListView(state: .loaded(Article.previewList))
                .previewDisplayName("Loaded")
            ArticleListView(state: .empty)
                .previewDisplayName("Empty")
            ArticleListView(state: .loaded(Article.previewList))
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
    }
}
#endif
```

## Scaling the Matrix

Match the output to the view and the request — a preview explosion is as unhelpful as no previews.

| View | Sensible default matrix |
|------|------------------------|
| **Label / small component** | realistic + long string, `traits: .sizeThatFitsLayout` |
| **List / collection** | loaded + empty + (loading/error if it has them) + dark |
| **Detail screen** | loaded + dark + AX5 + one long-language/RTL |
| **Form with state** | default + filled + invalid, `@Previewable` for live input |
| **Full prototype pass** | all data states × {light, dark} + AX5 + RTL |

## Good vs. Bad

#### ✅ Good

```swift
// States first — the prototype payoff — then the appearance checks.
#Preview("Loaded")   { FeedView(state: .loaded(.previewList)) }
#Preview("Empty")    { FeedView(state: .empty) }
#Preview("Error")    { FeedView(state: .error("Offline")) }
#Preview("Dark+AX5") { FeedView(state: .loaded(.previewList)).preferredColorScheme(.dark).dynamicTypeSize(.accessibility5) }
```

#### ❌ Bad

```swift
// One preview, happy path only, network-backed → flaky, proves nothing about empty/dark/large-text.
#Preview { FeedView() }   // fetches live data, single light-mode state
```

#### Why it matters

A view isn't done when it compiles — it's done when you've *seen* it empty, overflowing, in the dark, at AX5, and right-to-left. The matrix turns "looks fine on my iPhone in English" into actual coverage, at design time, before a single test or device build.
