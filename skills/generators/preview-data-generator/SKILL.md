---
name: preview-data-generator
description: Generate sample data and a multi-variant #Preview matrix for SwiftUI views — empty/loading/error/loaded states, light/dark, Dynamic Type, locales/RTL, and devices. Use when the user says "add previews", "sample data for previews", "preview my view in different states", "preview data", "prototype this UI", or wants realistic Xcode canvas data without hand-rolling it.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Preview Data Generator

Generates two tightly-coupled things for a SwiftUI view:

1. **Sample data** tuned for the Xcode canvas — realistic instances *plus* the visual edge cases that break layouts (empty, one item, huge list, long/overflowing strings, missing images, error and loading states).
2. **A `#Preview` matrix** — the variant blocks you'd otherwise hand-write to prototype and QA a view across light/dark, Dynamic Type, locale/RTL, device sizes, and data states.

This is the design-time counterpart to `testing/test-data-factory` (which makes fixtures for the *test suite*). Where a factory already exists, this skill **reuses** `Model.fixture()` instead of inventing parallel data.

## When This Skill Activates

Use this skill when the user:
- Wants sample/mock data for Xcode previews ("what do I put in the preview?")
- Wants to preview a view in multiple states (empty / loading / error / loaded)
- Is prototyping UI and wants light/dark, Dynamic Type, RTL, or device variants
- Says "add previews", "preview matrix", "preview this in dark mode + large text"
- Has a SwiftData `@Model` and needs an in-memory seeded container for previews
- Is on Xcode 16 / iOS 18 and wants shared, cached preview data via `PreviewModifier`

**Just need fixtures for unit tests?** Use `testing/test-data-factory` instead.
**Want screenshot regression tests?** Pair this with `testing/snapshot-test-setup` — the same data + variant matrix feeds snapshot tests.

## Reference Files

Load both before generating:

| File | Purpose |
|------|---------|
| **preview-data-patterns.md** | Sample-data design, the edge-case catalog, SwiftData in-memory seeding, `PreviewModifier` (iOS 18), `@Previewable`, reusing `test-data-factory` |
| **preview-matrix.md** | The variant axes, preview `traits:`, `.environment` overrides, deployment-target fallbacks (`#Preview` vs `PreviewProvider`), data-state previews |

## Pre-Generation Checks

Generators are context-aware. Before writing code, detect:

| Check | How | Why it matters |
|-------|-----|----------------|
| **Deployment target** | Read project/`.xcodeproj` or `Package.swift` | iOS 17+ → `#Preview` macro; iOS 18+ → `PreviewModifier` + `@Previewable`; below 17 → `PreviewProvider` fallback |
| **Target view + its models** | Read the view file; Grep its `init`/properties for model types | Determines which types need sample data |
| **Existing fixtures** | `Grep "static func fixture\|extension .*{ static (let\|var) preview"` | Reuse `Model.fixture()` / existing `.preview` — never duplicate |
| **SwiftData** | `Grep "@Model"` on the model types | Use the in-memory `.modelContainer(inMemory:)` seed pattern, not plain structs |
| **View shape** | Does it take a model, a ViewModel, or fetch its own data? | Drives whether to inject data, a mock VM, or a seeded container |
| **Platform** | iOS / macOS / multiplatform | Device variants and some traits differ |

Ask via AskUserQuestion only what you can't infer — e.g. "Which states matter for this view: empty, loading, error, loaded, or all four?"

## Generation Process

### Step 1: Build the Sample Data

For each model the view needs, generate a `Model.preview` namespace with the realistic case **and the edge cases** (see **preview-data-patterns.md** for the full catalog):

```swift
extension Article {
    /// A typical, realistic instance for the canvas.
    static var preview: Article {
        Article(id: UUID(), title: "Designing for the Smallest Screen",
                author: "Mei Chen", body: String(repeating: "Lorem ipsum. ", count: 40),
                imageURL: URL(string: "https://picsum.photos/seed/1/600/400"),
                readMinutes: 6, isBookmarked: false)
    }

    /// Edge cases that expose layout bugs.
    static var previewLongTitle: Article { .preview.with(title: "An Extraordinarily, Almost Unreasonably Long Headline That Wraps") }
    static var previewNoImage: Article   { .preview.with(imageURL: nil) }
    static var previewList: [Article]    { (1...12).map { .preview.with(id: UUID(), title: "Article \($0)") } }
    static var previewEmpty: [Article]   { [] }
}
```

If `Article.fixture()` already exists (from `test-data-factory`), build `.preview` *on top of it* rather than re-specifying every field.

### Step 2: Build the Preview Matrix

Generate the `#Preview` blocks for the axes that matter (see **preview-matrix.md**). Always include **data states** — that's the UI-prototyping payoff:

```swift
#Preview("Loaded")  { ArticleListView(state: .loaded(Article.previewList)) }
#Preview("Empty")   { ArticleListView(state: .empty) }
#Preview("Loading") { ArticleListView(state: .loading) }
#Preview("Error")   { ArticleListView(state: .error("No connection")) }

#Preview("Dark")        { ArticleListView(state: .loaded(Article.previewList)).preferredColorScheme(.dark) }
#Preview("XXL Text")    { ArticleListView(state: .loaded(Article.previewList)).dynamicTypeSize(.accessibility3) }
#Preview("German / RTL", traits: .sizeThatFitsLayout) {
    ArticleDetailView(article: .previewLongTitle).environment(\.locale, .init(identifier: "de"))
}
```

Scale the matrix to the request — don't emit 20 previews for a label. A reasonable default per view: the relevant **data states** + **dark mode** + **one large Dynamic Type** + (if the view has text that localizes) **one long-language/RTL** check.

### Step 3: Wire Up Infrastructure (when needed)

- **SwiftData view** → generate an in-memory `previewContainer` seeded with sample models, attached via `.modelContainer(previewContainer)`.
- **Xcode 16 / iOS 18** → offer a `PreviewModifier` so the seeded container/data is built **once and cached** across every preview, applied with `#Preview(traits: .modifier(SampleData()))`.
- **View needs `@State`/`@Bindable`** → use `@Previewable` so state lives directly in the `#Preview` body.

### Step 4: Place the Code

- Sample data → `Article+Preview.swift` (one file per model, in the model's group).
- Preview blocks → either appended to the view file (Apple's convention) or a sibling `ArticleListView+Previews.swift` for large matrices. Ask if unsure.
- Wrap preview-only data in `#if DEBUG` so it never ships in release builds.

## Output Format

After generating, always provide:

- **Files created** — full paths (`Article+Preview.swift`, `PreviewSupport.swift`, etc.)
- **Integration steps** — where the `#Preview` blocks went, how to open the canvas
- **Deployment-target notes** — which API was used and why (`#Preview` / `PreviewModifier` / `PreviewProvider`)
- **Testing instructions** — open the canvas, cycle the variants; if pairing with snapshots, how the data feeds `snapshot-test-setup`

## Example Output Summary

```
✅ Generated previews for ArticleListView (iOS 18 target)

Files created:
  • Article+Preview.swift        — .preview, .previewLongTitle, .previewNoImage, .previewList, .previewEmpty
  • PreviewSupport.swift         — SampleData: PreviewModifier (cached in-memory container)
  • ArticleListView+Previews.swift — 7 #Preview blocks (4 states, dark, XXL text, German)

Integration:
  • Reused Article.fixture() from test-data-factory for base fields
  • Open ArticleListView+Previews.swift → canvas shows all 7 variants

API used: #Preview + PreviewModifier (.modifier) — shared container built once, cached.
```

## When NOT to Use This Skill

- **Fixtures for the test suite** → `testing/test-data-factory`
- **Snapshot/regression image tests** → `testing/snapshot-test-setup` (feed it this data)
- **A trivial view with no data** → Xcode's autogenerated `#Preview {}` is enough
- **Locale-only preview helpers** → `generators/localization-setup` already covers locale preview helpers; reuse them

## Cross-Skill Integration

```
generators/persistence-setup   → defines @Model types
        ↓
testing/test-data-factory      → Model.fixture() for tests
        ↓
generators/preview-data-generator (THIS SKILL)
   • reuses .fixture() for canvas data
   • builds the #Preview state/appearance matrix
        ↓
testing/snapshot-test-setup    → renders the same matrix for regression
```

## Deliverables

- [ ] Sample data per model: realistic instance + edge cases (empty, long, missing, list)
- [ ] Existing `.fixture()`/`.preview` reused, not duplicated
- [ ] `#Preview` matrix covering the view's data states + relevant appearance axes
- [ ] Correct API for the deployment target (`#Preview` / `PreviewModifier` / `PreviewProvider`)
- [ ] SwiftData views get a seeded in-memory container
- [ ] Preview-only code guarded with `#if DEBUG`
- [ ] Output summary with files, integration, and testing steps

---

**Generate the data and the variants together.** A preview is only as useful as the data in it — and a view is only proven when you've seen it empty, overflowing, in the dark, and at AX5.
