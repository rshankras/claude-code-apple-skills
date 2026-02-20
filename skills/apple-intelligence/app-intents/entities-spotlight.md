# Entities and Spotlight Indexing

Define searchable data entities with `AppEntity` and make them discoverable in Spotlight with `IndexedEntity`, `@Property`, and `CSSearchableIndex`.

## AppEntity Protocol

Every entity must provide an ID, display representations, and a default query.

### Basic Entity

```swift
import AppIntents

struct RecipeEntity: AppEntity {
    var id: String
    var name: String
    var cuisine: String
    var prepTime: Int

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Recipe"),
            numericFormat: "\(placeholder: .int) recipes"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(cuisine) - \(prepTime) min"
        )
    }

    static var defaultQuery = RecipeEntityQuery()
}
```

### Display Representations

Control how entities appear across the system:

```swift
// Text only
var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
        title: "\(name)",
        subtitle: "\(category)"
    )
}

// With image from asset catalog
var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
        title: "\(name)",
        subtitle: "\(formattedPrice)",
        image: .init(named: imageName)
    )
}

// With SF Symbol
var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
        title: "\(name)",
        subtitle: "\(status)",
        image: .init(systemName: "doc.text")
    )
}
```

### TypeDisplayRepresentation

Tells the system how to label this entity type collectively:

```swift
static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(
        name: LocalizedStringResource("Recipe"),
        numericFormat: "\(placeholder: .int) recipes"
    )
}
```

The `numericFormat` is used when Siri says things like "I found 5 recipes."

## Entity Queries

Entities need queries so Siri and Shortcuts can find them. Choose the right query protocol based on how users will discover entities.

### EntityStringQuery (Text Search)

Users type or speak a name to find the entity:

```swift
struct RecipeEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [RecipeEntity] {
        let recipes = await RecipeStore.shared.recipes(for: identifiers)
        return recipes.map { RecipeEntity(from: $0) }
    }

    func entities(matching string: String) async throws -> [RecipeEntity] {
        let recipes = await RecipeStore.shared.search(query: string)
        return recipes.map { RecipeEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [RecipeEntity] {
        let recent = await RecipeStore.shared.recentRecipes(limit: 10)
        return recent.map { RecipeEntity(from: $0) }
    }
}
```

### EntityPropertyQuery (Filter by Properties)

Users filter by specific attributes. Useful when entities have structured, filterable data:

```swift
struct RecipePropertyQuery: EntityPropertyQuery {
    static var properties = QueryProperties {
        Property(\RecipeEntity.$cuisine) {
            EqualToComparator { $0 }
        }
        Property(\RecipeEntity.$prepTime) {
            LessThanOrEqualToComparator { $0 }
        }
    }

    static var sortingOptions = SortingOptions {
        SortableBy(\RecipeEntity.$name)
        SortableBy(\RecipeEntity.$prepTime)
    }

    func entities(
        matching comparators: [NSPredicate],
        mode: ComparatorMode,
        sortedBy: [Sort<RecipeEntity>],
        limit: Int?
    ) async throws -> [RecipeEntity] {
        // Apply comparators to fetch matching entities
        await RecipeStore.shared.query(
            predicates: comparators,
            sorts: sortedBy,
            limit: limit
        )
    }

    func entities(for identifiers: [String]) async throws -> [RecipeEntity] {
        await RecipeStore.shared.recipes(for: identifiers)
            .map { RecipeEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [RecipeEntity] {
        await RecipeStore.shared.recentRecipes(limit: 10)
            .map { RecipeEntity(from: $0) }
    }
}
```

### Query Pattern Selection

| Query Type | Use When | Example |
|------------|----------|---------|
| `EntityStringQuery` | User searches by name/text | "Open recipe Pasta Carbonara" |
| `EntityPropertyQuery` | User filters by attributes | "Show Italian recipes under 30 minutes" |

## IndexedEntity for Spotlight

Make entities appear in Spotlight search results. Requires iOS 18 / macOS 15.

### Conforming to IndexedEntity

```swift
import AppIntents
import CoreSpotlight

struct RecipeEntity: IndexedEntity {
    var id: String

    @Property(title: "Name")
    var name: String

    @Property(title: "Cuisine")
    var cuisine: String

    @Property(title: "Prep Time")
    var prepTime: Int

    @Property(title: "Ingredients")
    var ingredients: [String]

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Recipe"),
            numericFormat: "\(placeholder: .int) recipes"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(cuisine) - \(prepTime) min"
        )
    }

    static var defaultQuery = RecipeEntityQuery()
}
```

### The @Property Macro

`@Property` declares entity fields and provides metadata for the system:

```swift
// Basic property
@Property(title: "Name")
var name: String

// Property with indexing key for Spotlight
@Property(title: "Author", indexingKey: \.authorNames)
var author: String

// Property with content type hint
@Property(title: "URL", indexingKey: \.url)
var websiteURL: URL?
```

### Indexing Keys

The `indexingKey` maps your property to a `CSSearchableItemAttributeSet` key path, telling Spotlight how to index the value:

```swift
struct ArticleEntity: IndexedEntity {
    var id: String

    @Property(title: "Title", indexingKey: \.title)
    var title: String

    @Property(title: "Summary", indexingKey: \.contentDescription)
    var summary: String

    @Property(title: "Author", indexingKey: \.authorNames)
    var author: String

    @Property(title: "Date", indexingKey: \.contentCreationDate)
    var publishDate: Date

    @Property(title: "URL", indexingKey: \.url)
    var articleURL: URL?

    // ...display representations and defaultQuery
}
```

Common `CSSearchableItemAttributeSet` key paths:

| Key Path | Type | Purpose |
|----------|------|---------|
| `\.title` | `String?` | Primary display title |
| `\.contentDescription` | `String?` | Summary text |
| `\.authorNames` | `[String]?` | Author names |
| `\.contentCreationDate` | `Date?` | Creation date |
| `\.contentModificationDate` | `Date?` | Last modified date |
| `\.url` | `URL?` | Associated URL |
| `\.thumbnailData` | `Data?` | Thumbnail image data |
| `\.keywords` | `[String]?` | Searchable keywords |
| `\.contentType` | `String?` | UTI content type |

### Attribute Sets for Rich Metadata

For additional metadata beyond `@Property` indexing keys, provide a `CSSearchableItemAttributeSet`:

```swift
extension RecipeEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.title = name
        attributes.contentDescription = "A \(cuisine) recipe ready in \(prepTime) minutes"
        attributes.keywords = ingredients
        if let imageData = loadThumbnail() {
            attributes.thumbnailData = imageData
        }
        return attributes
    }
}
```

## Triggering Indexing

After creating, updating, or deleting entities, tell Spotlight to reindex.

### Index All Entities of a Type

```swift
// Reindex all recipes
try await CSSearchableIndex.default().indexAppEntities(of: RecipeEntity.self)
```

### Delete Entities from Index

```swift
// Remove all entities of a type
try await CSSearchableIndex.default().deleteAppEntities(of: RecipeEntity.self)

// Remove specific entities by ID
try await CSSearchableIndex.default().deleteAppEntities(
    of: RecipeEntity.self,
    identifiers: ["recipe-123", "recipe-456"]
)
```

### When to Reindex

Call `indexAppEntities()` at these points:

```swift
// After saving new or updated content
func saveRecipe(_ recipe: Recipe) async throws {
    try await database.save(recipe)
    try await CSSearchableIndex.default().indexAppEntities(of: RecipeEntity.self)
}

// After deleting content
func deleteRecipe(_ id: String) async throws {
    try await database.delete(id)
    try await CSSearchableIndex.default().indexAppEntities(of: RecipeEntity.self)
}

// On app launch if data may have changed externally
func applicationDidFinishLaunching() {
    Task {
        try? await CSSearchableIndex.default().indexAppEntities(of: RecipeEntity.self)
    }
}
```

## Patterns

### ✅ Good Patterns

```swift
// Entity with complete metadata for Spotlight
struct NoteEntity: IndexedEntity {
    var id: String

    @Property(title: "Title", indexingKey: \.title)
    var title: String

    @Property(title: "Content", indexingKey: \.contentDescription)
    var body: String

    @Property(title: "Modified", indexingKey: \.contentModificationDate)
    var modifiedDate: Date

    @Property(title: "Tags", indexingKey: \.keywords)
    var tags: [String]

    static var defaultQuery = NoteEntityQuery()
    // ...display representations
}

// Reindex after every mutation
func save(_ note: Note) async throws {
    try await database.save(note)
    try await CSSearchableIndex.default().indexAppEntities(of: NoteEntity.self)
}
```

### ❌ Anti-Patterns

```swift
// Missing defaultQuery -- entity cannot be resolved
struct BrokenEntity: AppEntity {
    var id: String
    var name: String
    // No defaultQuery, no display representations
}

// Properties without indexing keys -- Spotlight cannot search these
struct WeakEntity: IndexedEntity {
    var id: String

    @Property(title: "Title")
    var title: String  // Not indexed -- missing indexingKey

    @Property(title: "Body")
    var body: String  // Not indexed -- missing indexingKey
}

// Never reindexing after data changes
func save(_ note: Note) async throws {
    try await database.save(note)
    // Spotlight still shows stale data
}
```

## Complete Example: Bookmark Manager

```swift
import AppIntents
import CoreSpotlight

// MARK: - Entity

struct BookmarkEntity: IndexedEntity {
    var id: String

    @Property(title: "Title", indexingKey: \.title)
    var title: String

    @Property(title: "URL", indexingKey: \.url)
    var url: URL

    @Property(title: "Description", indexingKey: \.contentDescription)
    var summary: String

    @Property(title: "Tags", indexingKey: \.keywords)
    var tags: [String]

    @Property(title: "Added", indexingKey: \.contentCreationDate)
    var dateAdded: Date

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Bookmark"),
            numericFormat: "\(placeholder: .int) bookmarks"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(url.host ?? url.absoluteString)",
            image: .init(systemName: "bookmark.fill")
        )
    }

    static var defaultQuery = BookmarkEntityQuery()
}

// MARK: - Query

struct BookmarkEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [BookmarkEntity] {
        let bookmarks = await BookmarkStore.shared.bookmarks(for: identifiers)
        return bookmarks.map { BookmarkEntity(from: $0) }
    }

    func entities(matching string: String) async throws -> [BookmarkEntity] {
        let bookmarks = await BookmarkStore.shared.search(query: string)
        return bookmarks.map { BookmarkEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [BookmarkEntity] {
        let recent = await BookmarkStore.shared.recentBookmarks(limit: 15)
        return recent.map { BookmarkEntity(from: $0) }
    }
}

// MARK: - Indexing

enum BookmarkIndexer {
    static func reindex() async throws {
        try await CSSearchableIndex.default().indexAppEntities(
            of: BookmarkEntity.self
        )
    }

    static func clearIndex() async throws {
        try await CSSearchableIndex.default().deleteAppEntities(
            of: BookmarkEntity.self
        )
    }
}

// MARK: - Intent

struct SaveBookmarkIntent: AppIntent {
    static var title: LocalizedStringResource = "Save Bookmark"
    static var description: IntentDescription = "Saves a URL as a bookmark"

    @Parameter(title: "URL")
    var url: URL

    @Parameter(title: "Title")
    var bookmarkTitle: String

    @Parameter(title: "Tags")
    var tags: [String]?

    func perform() async throws -> some IntentResult & ReturnsValue<BookmarkEntity> & ProvidesDialog {
        let bookmark = try await BookmarkStore.shared.save(
            url: url,
            title: bookmarkTitle,
            tags: tags ?? []
        )

        // Reindex so Spotlight picks up the new bookmark
        try await BookmarkIndexer.reindex()

        let entity = BookmarkEntity(from: bookmark)
        return .result(
            value: entity,
            dialog: "Saved bookmark: \(bookmarkTitle)"
        )
    }
}
```

## References

- [AppEntity protocol](https://developer.apple.com/documentation/AppIntents/AppEntity)
- [IndexedEntity protocol](https://developer.apple.com/documentation/AppIntents/IndexedEntity)
- [CSSearchableIndex](https://developer.apple.com/documentation/CoreSpotlight/CSSearchableIndex)
- [CSSearchableItemAttributeSet](https://developer.apple.com/documentation/CoreSpotlight/CSSearchableItemAttributeSet)
- [EntityStringQuery](https://developer.apple.com/documentation/AppIntents/EntityStringQuery)
- [EntityPropertyQuery](https://developer.apple.com/documentation/AppIntents/EntityPropertyQuery)
