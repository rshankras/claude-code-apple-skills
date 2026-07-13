---
name: visual-intelligence
description: Integrate your app with iOS Visual Intelligence for camera-based search and object recognition. Use when adding visual search capabilities.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Visual Intelligence

Integrate your app with iOS Visual Intelligence to let users find app content by pointing their camera at objects.

## When This Skill Activates

- User wants camera-based search in their app
- User asks about visual search integration
- User wants to surface app content in system searches
- User needs to handle visual intelligence queries

## Overview

Visual Intelligence lets users:
1. Point camera at objects or use screenshots
2. System identifies what they're looking at
3. Your app provides matching content
4. Results appear in system UI

Your app implements:
- `IntentValueQuery` to receive search requests
- `AppEntity` types for searchable content
- Display representations for results

## Platform Availability (WWDC26 297)

- Visual Intelligence runs on iOS, iPadOS, and macOS — the same entities, query, and OpenIntent code works unchanged on all three.
- The input mix differs by platform: on iOS it's often **camera captures of physical objects**; on iPad and Mac the primary entry point is **screenshots of digital media**. Your search must handle both content styles.
- On Mac, the input pixel buffer can be **much larger** than what you'd encounter on iPhone — consider whether resizing is necessary before matching.
- Provider ordering in the Visual Intelligence sheet is **system-decided** among available Image Search providers — not something you control.

## Quick Start

### 1. Import Frameworks

```swift
import VisualIntelligence
import AppIntents
```

### 2. Create App Entity

```swift
struct ProductEntity: AppEntity {
    var id: String
    var name: String
    var price: String
    var imageName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Product"),
            numericFormat: "\(placeholder: .int) products"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(price)",
            image: .init(named: imageName)
        )
    }

    // Deep link URL
    var appLinkURL: URL? {
        URL(string: "myapp://product/\(id)")
    }
}
```

### 3. Create Intent Value Query

```swift
struct ProductIntentValueQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [ProductEntity] {
        // Search using labels
        if !input.labels.isEmpty {
            return await searchProducts(matching: input.labels)
        }

        // Search using image
        if let pixelBuffer = input.pixelBuffer {
            return await searchProducts(from: pixelBuffer)
        }

        return []
    }

    private func searchProducts(matching labels: [String]) async -> [ProductEntity] {
        // Search your database using provided labels
        // Return matching products
    }

    private func searchProducts(from pixelBuffer: CVReadOnlyPixelBuffer) async -> [ProductEntity] {
        // Use image recognition on the pixel buffer
        // Return matching products
    }
}
```

## SemanticContentDescriptor

The system provides this object with information about what the user is looking at.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `labels` | `[String]` | Classification labels from Visual Intelligence |
| `pixelBuffer` | `CVReadOnlyPixelBuffer?` | Raw image data |

### Usage Patterns

**Label-based Search:**
```swift
func values(for input: SemanticContentDescriptor) async throws -> [ProductEntity] {
    // Labels like "shoe", "sneaker", "Nike" etc.
    let labels = input.labels

    // Search your content using these labels
    return products.filter { product in
        labels.contains { label in
            product.tags.contains(label.lowercased())
        }
    }
}
```

**Image-based Search:**
```swift
func values(for input: SemanticContentDescriptor) async throws -> [ProductEntity] {
    guard let pixelBuffer = input.pixelBuffer else {
        return []
    }

    // Convert to CGImage for processing
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext()

    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        return []
    }

    // Use your ML model or image matching logic
    return await imageSearch.findMatches(for: cgImage)
}
```

## Multiple Result Types

Use `@UnionValue` when your app has different content types.

Rules (WWDC26 297):

- **An app can have only ONE `IntentValueQuery` that accepts a `SemanticContentDescriptor`.** All result types must flow through that single query — a `@UnionValue` enum with one case per entity type.
- **Every entity type in the union needs its own `OpenIntent`** — without one, results of that type can't appear in image search.
- Think beyond pixel matching: an album matched by image similarity can also surface the artist's **nearby concerts** — be creative about the type of content you return based on the context.

```swift
@UnionValue
enum SearchResult {
    case product(ProductEntity)
    case category(CategoryEntity)
    case store(StoreEntity)
}

struct VisualSearchQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [SearchResult] {
        var results: [SearchResult] = []

        // Search products
        let products = await productSearch(input.labels)
        results.append(contentsOf: products.map { .product($0) })

        // Search categories
        let categories = await categorySearch(input.labels)
        results.append(contentsOf: categories.map { .category($0) })

        return results
    }
}
```

## Display Representations

Create compelling visual representations for search results.

### Result Card Real Estate (WWDC26 297)

- The search-result card gives about **three lines of text** for a title and subtitle, plus a thumbnail image — put the most important identifying info there (album name + artist).
- With multiple results the sheet uses a **two-column layout**: if you initialize `DisplayRepresentation` with an image **URL**, serve a **thumbnail-sized** image, not the full-resolution asset — smaller images load faster.
- Exception: a **single** result renders its image at the **full width** of the results sheet — don't over-shrink for that case.

```swift
// ❌ Full-res image URLs in DisplayRepresentation for multi-result responses
// ✅ Thumbnail-sized images (two-column sheet); full-width only when returning one result
```

### Basic Display

```swift
var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
        title: "\(name)",
        subtitle: "\(description)",
        image: .init(named: thumbnailName)
    )
}
```

### With System Image

```swift
var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
        title: "\(name)",
        subtitle: "\(category)",
        image: .init(systemName: "tag.fill")
    )
}
```

### Rich Display

```swift
var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
        title: LocalizedStringResource("\(name)"),
        subtitle: LocalizedStringResource("\(formatPrice(price))"),
        image: DisplayRepresentation.Image(named: imageName)
    )
}
```

## On-Device Image Matching (WWDC26 297)

Whether you're searching on device or hitting a server, the same principles apply: **return results fast and ranked**.

Vision-framework pattern:

- **Pre-compute** `GenerateImageFeaturePrintRequest` feature prints for your catalog — never at query time.
- At query time: convert the pixel buffer via VideoToolbox (`VTCreateCGImageFromCVPixelBuffer`), generate one feature print, compare distances.
- Filter with a **maximum distance threshold** to drop dissimilar results, **sort ascending by distance** so the best match is first, and **cap the result count**. Apple's sample signature: `search(matching:limit: Int = 10, maxDistance: Double = 1.0)`.
- Return `[]` when nothing matches or the pixel buffer is absent — the system handles displaying an empty response. ❌ Don't pad with weak matches.

```swift
// ❌ Compute feature prints at query time
// ✅ Pre-compute catalog prints; query = 1 print + threshold + sort + limit
let matches = catalogPrints
    .map { entry in (entry, entry.print.distance(to: queryPrint)) }
    .filter { $0.1 <= maxDistance }
    .sorted { $0.1 < $1.1 }
    .prefix(limit)
```

Vision offers more than feature prints for visual search: text extraction, barcode scanning, face detection, image classification (WWDC26 297).

## Deep Linking

Enable users to open specific content from search results.

### OpenIntent Rules (WWDC26 297)

Tapping a result runs your `OpenIntent` for that entity type, and its `perform()` runs **as the app comes to the foreground**:

- Do navigation in `perform()`; **defer heavy loading until after the view appears**.
- Take people **straight to the content they selected** — no intermediate screens.
- ✅ Reuse the OpenIntent from your existing App Intents adoption — you don't need a separate one just for Visual Intelligence. ❌ Duplicate per-feature OpenIntents.

```swift
// ❌ Heavy loading inside OpenIntent.perform (runs during foregrounding)
// ✅ Navigate only; load after the view appears; reuse one OpenIntent everywhere
```

### URL-based Deep Links

```swift
struct ProductEntity: AppEntity {
    // ... other properties

    var appLinkURL: URL? {
        URL(string: "myapp://product/\(id)")
    }
}
```

### Handle in App

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "myapp" else { return }

        switch url.host {
        case "product":
            let id = url.lastPathComponent
            navigationState.showProduct(id: id)
        default:
            break
        }
    }
}
```

## "More Results" Button

Provide access to additional results beyond the initial set.

```swift
struct ViewMoreProductsIntent: AppIntent, VisualIntelligenceSearchIntent {
    static var title: LocalizedStringResource = "View More Products"

    @Parameter(title: "Semantic Content")
    var semanticContent: SemanticContentDescriptor

    func perform() async throws -> some IntentResult {
        // Store search context for your app
        SearchContext.shared.currentSearch = semanticContent.labels

        // Return empty result - system will open your app
        return .result()
    }
}
```

### semanticContentSearch Schema (WWDC26 297)

The schema-based form: conform to `.visualIntelligence.semanticContentSearch` and the system supplies the `semanticContent` property automatically:

```swift
@AppIntent(schema: .visualIntelligence.semanticContentSearch)
struct SemanticContentSearchIntent: AppIntent {
    static let openAppWhenRun: Bool = true

    var semanticContent: SemanticContentDescriptor

    func perform() async throws -> some IntentResult {
        let results = try await library.search(matching: semanticContent)
        await MainActor.run { AppState.shared.openSearch(with: results) }
        return .result()
    }
}
```

Rules (WWDC26 297):

- **Pre-populate** the in-app search view from the captured context — never land people on a blank search screen.
- Use the in-app surface to expose what the Visual Intelligence sheet can't: filters, categories, the full depth of your content.

## Complete Example

```swift
import SwiftUI
import AppIntents
import VisualIntelligence

// MARK: - Entities

struct RecipeEntity: AppEntity {
    var id: String
    var name: String
    var cuisine: String
    var prepTime: String
    var imageName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Recipe"),
            numericFormat: "\(placeholder: .int) recipes"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(cuisine) · \(prepTime)",
            image: .init(named: imageName)
        )
    }

    var appLinkURL: URL? {
        URL(string: "recipes://recipe/\(id)")
    }
}

// MARK: - Intent Value Query

struct RecipeVisualSearchQuery: IntentValueQuery {
    @Dependency var recipeStore: RecipeStore

    func values(for input: SemanticContentDescriptor) async throws -> [RecipeEntity] {
        // Use labels to find recipes
        // Labels might include: "pasta", "tomato", "Italian", etc.
        let matchingRecipes = await recipeStore.search(
            ingredients: input.labels,
            limit: 15
        )

        return matchingRecipes.map { recipe in
            RecipeEntity(
                id: recipe.id,
                name: recipe.name,
                cuisine: recipe.cuisine,
                prepTime: recipe.prepTimeFormatted,
                imageName: recipe.thumbnailName
            )
        }
    }
}

// MARK: - More Results Intent

struct ViewMoreRecipesIntent: AppIntent, VisualIntelligenceSearchIntent {
    static var title: LocalizedStringResource = "View More Recipes"

    @Parameter(title: "Semantic Content")
    var semanticContent: SemanticContentDescriptor

    func perform() async throws -> some IntentResult {
        // Save search context
        await MainActor.run {
            RecipeSearchState.shared.searchTerms = semanticContent.labels
        }
        return .result()
    }
}

// MARK: - Recipe Store

@Observable
class RecipeStore {
    private var recipes: [Recipe] = []

    func search(ingredients: [String], limit: Int) async -> [Recipe] {
        recipes
            .filter { recipe in
                ingredients.contains { ingredient in
                    recipe.ingredients.contains { recipeIngredient in
                        recipeIngredient.lowercased().contains(ingredient.lowercased())
                    }
                }
            }
            .prefix(limit)
            .map { $0 }
    }
}
```

## Best Practices

### Performance

- Return results quickly (< 1 second)
- Limit initial results (10-20 items)
- Use "More Results" for additional content
- Cache search indexes for fast lookup

```swift
func values(for input: SemanticContentDescriptor) async throws -> [ProductEntity] {
    // Limit results for quick response
    let results = await search(input.labels)
    return Array(results.prefix(15))
}
```

### Relevance

- Prioritize exact matches
- Consider context (location, time)
- Filter low-confidence matches

```swift
func values(for input: SemanticContentDescriptor) async throws -> [ProductEntity] {
    let results = await search(input.labels)

    // Sort by relevance score
    return results
        .filter { $0.relevanceScore > 0.5 }
        .sorted { $0.relevanceScore > $1.relevanceScore }
        .prefix(15)
        .map { $0 }
}
```

### Quality Representations

- Use clear, concise titles
- Include helpful subtitles
- Provide relevant thumbnails
- Localize all text

```swift
var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
        title: LocalizedStringResource(stringLiteral: name),
        subtitle: LocalizedStringResource(
            stringLiteral: "\(category) · \(formattedPrice)"
        ),
        image: .init(named: thumbnailName)
    )
}
```

## Receiving Visual Intelligence Data (WWDC26 297)

Two integration directions: your app **provides** results (everything above), and your app **receives** data Visual Intelligence writes into shared system stores:

| Visual Intelligence system action | Store | Your app reads via |
|-----------------------------------|-------|--------------------|
| Create calendar events — including multiple events at once | EventKit | `EKEventStore` |
| Add to contacts | Contacts | `CNContactStore` |
| Log medical device readings (blood pressure monitors, glucose meters, weight scales) | HealthKit | `HKHealthStore` |

If your app already reads from these stores, Visual Intelligence becomes a source of input automatically — zero VI-specific code. One requirement: **observe change notifications** so VI-created data appears without a relaunch. EventKit pattern from Apple's sample: `requestFullAccessToEvents()` → fetch with a predicate (a 90-day window) → observe `.EKEventStoreChanged` notifications and refetch.

## Testing

1. Build and run on physical device
2. Open Camera or take screenshot
3. Activate Visual Intelligence
4. Point at objects relevant to your app
5. Verify results appear
6. Test tapping results opens your app correctly
7. On iPad and Mac, test with screenshots of digital media — the primary entry point there (WWDC26 297)

## Checklist

- [ ] Import VisualIntelligence and AppIntents
- [ ] Create AppEntity types for searchable content
- [ ] Implement IntentValueQuery
- [ ] Handle both labels and pixelBuffer
- [ ] Create DisplayRepresentation for each entity
- [ ] Implement deep linking URLs
- [ ] Handle URLs in app with onOpenURL
- [ ] Add "More Results" intent if needed — pre-populated, never a blank search screen
- [ ] Only one SemanticContentDescriptor-accepting IntentValueQuery in the app (WWDC26 297)
- [ ] OpenIntent per entity type; navigation only in `perform()`, heavy loading deferred (WWDC26 297)
- [ ] Thumbnail-sized display images for multi-result responses (WWDC26 297)
- [ ] Return `[]` when nothing matches — no weak-match padding (WWDC26 297)
- [ ] Feature prints pre-computed, results filtered by max distance and sorted best-first (WWDC26 297)
- [ ] Test on physical device
- [ ] Optimize for performance (< 1s response)
- [ ] Localize display text

## References

- [Integrating your app with visual intelligence](https://developer.apple.com/documentation/VisualIntelligence/integrating-your-app-with-visual-intelligence)
- [SemanticContentDescriptor](https://developer.apple.com/documentation/VisualIntelligence/SemanticContentDescriptor)
- [IntentValueQuery](https://developer.apple.com/documentation/AppIntents/IntentValueQuery)
- [DisplayRepresentation](https://developer.apple.com/documentation/AppIntents/DisplayRepresentation)
- [App Intents framework](https://developer.apple.com/documentation/AppIntents)
