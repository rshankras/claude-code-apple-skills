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

### The Entity ID Contract

The `id` must be **persistent and re-resolvable** (WWDC25 244). The system stores entity IDs — in saved shortcuts, Spotlight, and suggestions — and calls `entities(for:)` to round-trip them back into entities later, across launches. If an ID can't be resolved later, every saved shortcut referencing it breaks.

```swift
// ❌ Unstable ID -- breaks every saved shortcut after a reorder or rename
var id: String { "\(name)-\(listIndex)" }

// ✅ Persistent identifier from your data layer -- survives renames and reorders
var id: UUID
```

Two entity architectures — choose deliberately (WWDC24 10210): (a) conform your **model type directly** only when the whole model fits in memory; (b) a **separate entity struct that refers to the model** when instances are created on demand or the model has expensive properties your intents don't need.

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

A query's job: turn *questions about entities* into *entities* (WWDC24 10210). Parameter configuration asks exactly two: "what entities are there?" (options list for the picker) and "what entity has this ID?" (rehydrate the saved ID at run time so `perform` receives an entity, never a raw ID).

### Query Capability Ladder

`entities(for identifiers:)` is the one non-negotiable requirement. Add capabilities as needed (WWDC25 244):

1. `suggestedEntities()` — curated list (favorites, recents) shown in pickers before the user types
2. `EnumerableEntityQuery.allEntities()` — small bounded sets
3. `EntityStringQuery.entities(matching:)` — text search
4. `EntityPropertyQuery.entities(matching:mode:sortedBy:limit:)` — filterable/sortable Find actions

`EnumerableEntityQuery` is the conceptually simplest, and when built with the iOS 18 SDK, App Intents derives the more complicated query kinds from it automatically — but `allEntities()` is only valid if **all entities fit in memory** (WWDC24 10210). For large or unbounded sets (or when you can beat the derived behavior), implement the specific sub-protocols instead.

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
| `EnumerableEntityQuery` | All entities fit in memory | Timezones, app tabs |
| `EntityStringQuery` | User searches by name/text | "Open recipe Pasta Carbonara" |
| `EntityPropertyQuery` | User filters by attributes | "Show Italian recipes under 30 minutes" |

## IndexedEntity for Spotlight

Make entities appear in Spotlight search results. Requires iOS 18 / macOS 15.

Adopting `IndexedEntity` with per-property `indexingKey` does triple duty (WWDC25 244, 260):

1. **Semantic Spotlight search** — meaning-based matching over donated entities ("pets" matches cats, dogs, snakes), not just literal text
2. **Auto-generated Shortcuts Find action** — the zero-boilerplate alternative to hand-writing `EnumerableEntityQuery`/`EntityPropertyQuery`
3. **Spotlight parameter filtering** — typing in an intent's parameter field searches indexed entities

Why bother vs a plain `CSSearchableItem`: a searchable item alone can't take action; an indexed entity lets Siri find it *and* run intents on it (WWDC24 10134).

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

Mapping rules (WWDC25 260): `DisplayRepresentation` title/subtitle/image map to Spotlight attributes automatically; other properties map explicitly to a standard Core Spotlight key via `@Property(indexingKey:)`; properties with **no standard Spotlight equivalent use a custom indexing key** (`customIndexingKey`) — e.g. a free-form `notes` property.

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

The default implementation populates the attribute set from `DisplayRepresentation` only — override `attributeSet` to add real search signal (location fields, keywords from the entity's activities). More attributes mean better search *and* better Siri semantic understanding (WWDC24 10134).

Two more indexing levers (WWDC24 10134):

- **Priority**: all IndexedEntity indexing APIs accept a `priority` — larger value = more important (boost favorites above non-favorites).
- **Existing `CSSearchableItem` pipelines**: call `associateAppEntity(_:)` on the searchable item before indexing — this is what lets semantic search find and act on your already-indexed content without re-plumbing.

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

## Transferable Entities and FileEntity

### Transferable

Conform an `AppEntity` to `Transferable` so Siri/Shortcuts can convert it into standard content types and hand it to other apps' intents — attach to Mail, save a PNG to Photos, append RTF to Notes (WWDC24 10134):

```swift
extension RecipeEntity: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .recipeDocument)   // highest fidelity first
        DataRepresentation(exportedContentType: .rtf) { entity in
            try entity.renderRTF()
        }
        ProxyRepresentation(exporting: \.name)                // plain text last
    }
}
```

Rules (WWDC24 10134):

- **Declare representations highest-fidelity → lowest** (private `Codable` first, then RTF, then plain text/PNG) — Shortcuts picks the best match for the receiver.
- Xcode must understand `transferRepresentation` **at compile time** — no dynamic representations.
- `ProxyRepresentation` may only reference entity properties annotated `@Property`.
- Receiving side: declare `supportedContentTypes` on an `IntentFile` parameter; Siri/Shortcuts then auto-convert any Transferable entity flowing in.

### FileEntity

Use `Transferable` when the entity is a DB/server object exported *as* a file; use `FileEntity` when the file **is** the canonical entity (document-based apps: text docs, images) (WWDC24 10134). FileEntity lets Siri/Shortcuts broker secure direct access so another app's intent can mutate the file **in place** — the owning app detects the change and updates its UI.

- Requirements beyond a normal AppEntity: `supportedContentTypes: [UTType]`, and an `id` of type `FileEntityIdentifier` — created from a URL, or as a **draft identifier when the file doesn't exist yet**.
- The identifier stores URL **bookmark data**, so the entity survives file moves and renames.

## Spotlight on Mac: Visibility Gates

Intents run directly from Spotlight on Mac — but only if they pass two gates (WWDC25 244, 260):

**Gate 1 — the parameter summary rule.** The `parameterSummary` must reference **every required parameter that lacks a default value**. If the intent has no required parameters, the summary may be omitted (the title is used).

```swift
// ✅ Visible -- all required parameters appear in the summary
static var parameterSummary: some ParameterSummary {
    Summary("Create event \(\.$title) from \(\.$startDate) to \(\.$endDate)")
}

// ❌ Hidden -- a required `notes` parameter exists but isn't in the summary.
// Fixes: add it to the summary, make it optional, or give it a default value.
```

**Gate 2 — don't hide the intent.** `isDiscoverable = false`, assistant-only schema flags, or a widget-configuration intent with **no `perform()`** all exclude an intent from Spotlight (WWDC25 260).

Parameter-field UX in Spotlight, in priority order (WWDC25 260):

1. Suggestions: implement `suggestedEntities()` (subset of a large/unbounded set — today's events) or `allEntities()` via `EnumerableEntityQuery` (small bounded sets — timezones)
2. On-screen boost: set `appEntityIdentifier` on the view's `NSUserActivity` so the visible entity tops the suggestions
3. Learned suggestions: conform the intent to `PredictableIntent` for usage-pattern-based ranking
4. Typing in the field: basic filtering is free once suggestions exist; real search needs `EntityStringQuery` or `IndexedEntity`

## Entities and the Use Model Action

Shortcuts' Use Model action runs Apple Intelligence over your entities — Private Cloud Compute, on-device, or ChatGPT backends — with the output type inferred from the downstream action (WWDC25 260). What your app must do to participate:

**Accept `AttributedString` on text parameters.** Model output is rich text (bold/italic/lists/tables); a `String` parameter silently strips that formatting:

```swift
// ❌ Strips model-generated formatting
@Parameter(title: "Text") var text: String

// ✅ Lossless handoff from Use Model output
@Parameter(title: "Text") var text: AttributedString
```

**Entities are passed to the model as JSON**: type name from `TypeDisplayRepresentation.name`, plus `DisplayRepresentation` title/subtitle, plus every exposed `@Property` stringified (WWDC25 260). Consequences:

- Expose the properties you want the model to reason over — unexposed data is invisible to the model.
- Keep `TypeDisplayRepresentation.name` short and literal ("Calendar Event") — it's the model's type hint.
- Whatever string a property renders as in the Shortcuts editor is exactly what the model sees — validate the entity JSON by eyeballing it there.

**Provide a Find action** — that's how users get entities into Use Model (WWDC25 260). Two routes: hand-write `EnumerableEntityQuery`/`EntityPropertyQuery`, or adopt `IndexedEntity` + per-property `indexingKey` and the system generates the Find action for you.

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
