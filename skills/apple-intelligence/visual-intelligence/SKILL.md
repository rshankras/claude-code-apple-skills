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

## Deep Linking

Enable users to open specific content from search results.

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

## Testing

1. Build and run on physical device
2. Open Camera or take screenshot
3. Activate Visual Intelligence
4. Point at objects relevant to your app
5. Verify results appear
6. Test tapping results opens your app correctly

## Checklist

- [ ] Import VisualIntelligence and AppIntents
- [ ] Create AppEntity types for searchable content
- [ ] Implement IntentValueQuery
- [ ] Handle both labels and pixelBuffer
- [ ] Create DisplayRepresentation for each entity
- [ ] Implement deep linking URLs
- [ ] Handle URLs in app with onOpenURL
- [ ] Add "More Results" intent if needed
- [ ] Test on physical device
- [ ] Optimize for performance (< 1s response)
- [ ] Localize display text

## References

- [Integrating your app with visual intelligence](https://developer.apple.com/documentation/VisualIntelligence/integrating-your-app-with-visual-intelligence)
- [SemanticContentDescriptor](https://developer.apple.com/documentation/VisualIntelligence/SemanticContentDescriptor)
- [IntentValueQuery](https://developer.apple.com/documentation/AppIntents/IntentValueQuery)
- [DisplayRepresentation](https://developer.apple.com/documentation/AppIntents/DisplayRepresentation)
- [App Intents framework](https://developer.apple.com/documentation/AppIntents)
