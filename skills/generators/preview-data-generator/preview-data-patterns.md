# Preview Sample Data Patterns

Reference for the `preview-data-generator` skill: how to design canvas sample data, the edge cases that matter, SwiftData seeding, and the modern shared-data APIs.

## The Edge-Case Catalog

Test fixtures optimize for *minimal, assertion-friendly* objects. Preview data optimizes for *visual stress* — the cases that expose layout bugs. Generate these for any non-trivial model:

| Case | Why it matters | Example accessor |
|------|----------------|------------------|
| **Realistic** | The happy path you design against | `.preview` |
| **Empty collection** | Empty states are the most-forgotten screen | `.previewEmpty` |
| **Single item** | Lists that assume "many" break at 1 | `.previewOne` |
| **Many items** | Spacing, scrolling, performance | `.previewList` (10-20) |
| **Long strings** | Truncation, wrapping, button overflow | `.previewLongTitle` |
| **Missing/optional** | `nil` image, no subtitle, no avatar | `.previewNoImage` |
| **Extremes** | 0, negative, 9,999+, huge numbers | `.previewMaxedOut` |
| **Loading / Error** | The non-success UI states (see state matrix) | view-level, not model-level |

## Design the `.preview` Namespace

Put canvas data in an `extension` on the model, in a `#if DEBUG` file so it never ships:

```swift
#if DEBUG
import Foundation

extension Article {
    static var preview: Article {
        Article(
            id: UUID(),
            title: "Designing for the Smallest Screen",
            author: "Mei Chen",
            body: String(repeating: "Lorem ipsum dolor sit amet. ", count: 30),
            imageURL: URL(string: "https://picsum.photos/seed/news/600/400"),
            readMinutes: 6,
            isBookmarked: false
        )
    }

    static var previewLongTitle: Article {
        preview.with(title: "An Extraordinarily, Almost Unreasonably Long Headline That Will Wrap Onto Several Lines")
    }
    static var previewNoImage: Article  { preview.with(imageURL: nil) }
    static var previewBookmarked: Article { preview.with(isBookmarked: true) }

    static var previewList: [Article] {
        ["Swift 6 Concurrency", "Liquid Glass in Practice", "Shipping on a Weekend",
         "The 20-Minute Code Review", "Designing Empty States"]
            .map { preview.with(id: UUID(), title: $0) }
    }
    static var previewEmpty: [Article] { [] }
}
#endif
```

### The `.with(...)` helper

A tiny copy-helper keeps edge cases one line each instead of re-specifying every field:

```swift
#if DEBUG
extension Article {
    func with(
        id: UUID? = nil, title: String? = nil, author: String? = nil,
        imageURL: URL?? = nil, isBookmarked: Bool? = nil
    ) -> Article {
        Article(
            id: id ?? self.id,
            title: title ?? self.title,
            author: author ?? self.author,
            body: self.body,
            imageURL: imageURL ?? self.imageURL,   // double optional → can set to nil explicitly
            readMinutes: self.readMinutes,
            isBookmarked: isBookmarked ?? self.isBookmarked
        )
    }
}
#endif
```

## Reuse `test-data-factory`, Don't Duplicate

If the project already has a fixture factory (from `testing/test-data-factory`), build previews **on top of it**:

```swift
#if DEBUG
extension Article {
    // Reuse the factory for base fields; previews only override what's visually interesting.
    static var preview: Article { .fixture(title: "Designing for the Smallest Screen") }
    static var previewList: [Article] { (1...12).map { .fixture(id: UUID(), title: "Article \($0)") } }
}
#endif
```

**Detection:** `Grep "static func fixture"` in the project. If present, prefer it. If absent, generate the `.preview` data standalone (and optionally suggest adding a factory for tests).

## SwiftData: In-Memory Seeded Container

A `@Model`-backed view needs a *container*, not a struct. Build an in-memory one seeded with sample data — it never touches the real store:

```swift
#if DEBUG
import SwiftData

@MainActor
let previewContainer: ModelContainer = {
    let container = try! ModelContainer(
        for: Article.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    for article in Article.previewSeed {
        container.mainContext.insert(article)
    }
    return container
}()
#endif

// Usage:
#Preview {
    ArticleListView()
        .modelContainer(previewContainer)
}
```

## iOS 18 / Xcode 16: `PreviewModifier` (build the data once, cache it)

`PreviewModifier` lets every preview share **one** expensive context (a seeded container, a configured environment) that Xcode builds once and caches — instead of rebuilding per preview:

```swift
#if DEBUG
import SwiftUI
import SwiftData

struct SampleData: PreviewModifier {
    // Built once, cached, shared across all previews that use this modifier.
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: Article.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        Article.previewSeed.forEach { container.mainContext.insert($0) }
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var sampleData: Self { .modifier(SampleData()) }
}
#endif

// Usage — clean and shared:
#Preview(traits: .sampleData) { ArticleListView() }
#Preview("Dark", traits: .sampleData) { ArticleListView().preferredColorScheme(.dark) }
```

## Xcode 16: `@Previewable` for `@State` in previews

When a view needs live `@State`/`@Bindable` (toggles, selection, text), `@Previewable` lets it live directly in the `#Preview` body — no wrapper view:

```swift
#Preview("Interactive") {
    @Previewable @State var query = ""
    SearchBar(text: $query)
}
```

## Mocking a ViewModel for Previews

If the view owns an `@Observable` ViewModel that fetches data, generate a preview instance pinned to a state instead of letting it hit the network:

```swift
#if DEBUG
extension ArticleListViewModel {
    static var previewLoaded: ArticleListViewModel {
        let vm = ArticleListViewModel(service: .noop)
        vm.state = .loaded(Article.previewList)
        return vm
    }
    static var previewEmpty: ArticleListViewModel { let vm = ArticleListViewModel(service: .noop); vm.state = .empty; return vm }
    static var previewError: ArticleListViewModel { let vm = ArticleListViewModel(service: .noop); vm.state = .error("No connection"); return vm }
}
#endif
```

`.noop` is a do-nothing conformance to the view model's service protocol — reuse the same protocol the app already defines for swappable services (see `generators/networking-layer`).

## Rules

- ✅ Always wrap preview data in `#if DEBUG`
- ✅ Reuse `.fixture()` if it exists; otherwise keep `.preview` self-contained
- ✅ Use stable seed strings for image URLs (e.g. `picsum.photos/seed/...`) so previews don't flicker
- ✅ For SwiftData, always `isStoredInMemoryOnly: true` — never seed the real store
- ❌ Don't hit the live network in a preview — pin the ViewModel/service to a state
- ❌ Don't ship preview data — `#if DEBUG` is non-negotiable
