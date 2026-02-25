---
name: spotlight-indexing
description: Generates Core Spotlight indexing infrastructure for making app content searchable via system Spotlight with rich attributes and deep link integration. Use when user wants to index content for Spotlight search, Siri suggestions, or system-wide searchability.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Spotlight Indexing Generator

Generate production Core Spotlight indexing infrastructure — makes app content searchable via Spotlight (and Siri suggestions). Indexes items with rich attributes, handles search continuation into your app, and manages index lifecycle.

## When This Skill Activates

Use this skill when the user:
- Asks to "add spotlight search" or "spotlight indexing"
- Mentions "core spotlight" or "CSSearchableItem"
- Wants to make "searchable content" or "index content" for system search
- Asks about "system search" integration or "Siri suggestions"
- Wants content to appear in Spotlight results
- Mentions "NSUserActivity" for search or handoff

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Existing CoreSpotlight Detection
Search for existing Spotlight code:
```
Glob: **/*Spotlight*.swift, **/*Searchable*.swift, **/*CSSearchable*.swift
Grep: "CoreSpotlight" or "CSSearchableIndex" or "CSSearchableItem"
```

If existing Spotlight code found:
- Ask if user wants to replace or augment it
- If augmenting, identify what's missing and generate only those pieces

### 3. Deep Linking Detection
Search for existing deep link or navigation setup:
```
Grep: "NavigationPath" or "onOpenURL" or "NSUserActivity" or "DeepLink"
```

If deep linking exists:
- Integrate SpotlightSearchHandler with existing router
- If not, generate standalone handler with guidance on wiring it up

### 4. Entitlements Check
Verify CoreSpotlight doesn't require special entitlements (it doesn't — it's a standard framework), but check if the app uses App Groups for shared index across extensions.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Content types to index?**
   - Articles / blog posts (titles, body text, authors)
   - Products (name, description, price, images)
   - Contacts / people (name, phone, email)
   - Tasks / reminders (title, due date, priority)
   - Custom (user describes their model)

2. **Include thumbnails?**
   - Yes — index thumbnail images alongside text attributes
   - No — text-only attributes (smaller index, faster)

3. **Indexing strategy?**
   - Batch indexing (index all content at once, e.g., on first launch or sync)
   - Incremental indexing (index items as they're created/updated/deleted)
   - Both (batch for initial load, incremental for changes)

4. **Include Siri suggestions / shortcuts?**
   - Yes — make content eligible for Siri suggestions and predictions
   - No — Spotlight search only

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.
Read `patterns.md` for architecture guidance and best practices.

### Step 2: Create Core Files
Generate these files:
1. `SpotlightIndexable.swift` — Protocol any model can conform to
2. `SpotlightIndexManager.swift` — Actor wrapping CSSearchableIndex with batching
3. `SpotlightAttributeBuilder.swift` — Fluent builder for CSSearchableItemAttributeSet

### Step 3: Create Integration Files
4. `SpotlightSearchHandler.swift` — Handles NSUserActivity continuation from Spotlight taps

### Step 4: Create Optional Files
Based on configuration:
- `SpotlightSyncModifier.swift` — If incremental indexing selected (ViewModifier for auto index/deindex)
- Add NSUserActivity + eligibleForSearch if Siri suggestions selected

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/SpotlightIndexing/`
- If `App/` exists -> `App/SpotlightIndexing/`
- Otherwise -> `SpotlightIndexing/`

## Output Format

After generation, provide:

### Files Created
```
SpotlightIndexing/
├── SpotlightIndexable.swift        # Protocol for indexable models
├── SpotlightIndexManager.swift     # Actor-based index management
├── SpotlightAttributeBuilder.swift # Fluent attribute builder
├── SpotlightSearchHandler.swift    # Handle Spotlight tap continuation
└── SpotlightSyncModifier.swift     # Auto index/deindex ViewModifier (optional)
```

### Integration with Content Creation/Update

**Make a model searchable:**
```swift
// Conform your model to SpotlightIndexable
struct Article: SpotlightIndexable {
    let id: UUID
    let title: String
    let body: String
    let author: String
    let tags: [String]

    var spotlightID: String { id.uuidString }
    var spotlightTitle: String { title }
    var spotlightDescription: String { String(body.prefix(300)) }
    var spotlightKeywords: [String] { tags + [author] }
    var spotlightThumbnailData: Data? { nil }
    var spotlightDomainIdentifier: String { "com.myapp.articles" }
}
```

**Index on create, remove on delete:**
```swift
func createArticle(_ article: Article) async throws {
    try await repository.save(article)
    await SpotlightIndexManager.shared.index(items: [article])
}

func deleteArticle(_ article: Article) async throws {
    try await repository.delete(article)
    await SpotlightIndexManager.shared.remove(identifiers: [article.spotlightID])
}
```

**Batch reindex (e.g., on first launch):**
```swift
func reindexAllContent() async {
    let articles = await repository.fetchAll()
    await SpotlightIndexManager.shared.reindexAll(items: articles, domain: "com.myapp.articles")
}
```

**Handle Spotlight tap (App or Scene delegate):**
```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    SpotlightSearchHandler.shared.handle(activity)
                }
        }
    }
}
```

**Auto index/deindex with ViewModifier:**
```swift
struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            Text(article.body)
        }
        .spotlightIndexed(article)  // Indexes on appear, deindexes on disappear
    }
}
```

### Testing

```swift
@Test
func indexAndRetrieveItem() async throws {
    let manager = SpotlightIndexManager(index: MockSearchableIndex())
    let article = Article(id: UUID(), title: "Test", body: "Body", author: "Author", tags: ["swift"])

    await manager.index(items: [article])
    #expect(manager.indexedCount == 1)
}

@Test
func batchIndexChunksCorrectly() async throws {
    let mockIndex = MockSearchableIndex()
    let manager = SpotlightIndexManager(index: mockIndex, batchSize: 10)
    let items = (0..<25).map { makeArticle(index: $0) }

    await manager.index(items: items)
    #expect(mockIndex.indexCallCount == 3)  // 10 + 10 + 5
}

@Test
func handleSpotlightContinuation() async throws {
    let handler = SpotlightSearchHandler()
    let activity = NSUserActivity(activityType: CSSearchableItemActionType)
    activity.userInfo = [CSSearchableItemActivityIdentifier: "article-123"]

    let itemID = handler.extractItemID(from: activity)
    #expect(itemID == "article-123")
}
```

## Common Patterns

### Index Item on Create
Every time a model is created or updated, index it immediately:
```swift
await SpotlightIndexManager.shared.index(items: [newItem])
```

### Remove on Delete
When content is deleted, remove it from the index:
```swift
await SpotlightIndexManager.shared.remove(identifiers: [item.spotlightID])
```

### Batch Reindex
After app update or data migration, reindex all content:
```swift
await SpotlightIndexManager.shared.reindexAll(items: allItems, domain: "com.myapp.articles")
```

### Handle Search Continuation
When user taps a Spotlight result, the app receives an NSUserActivity. Extract the item ID and navigate:
```swift
.onContinueUserActivity(CSSearchableItemActionType) { activity in
    if let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
        navigationPath.append(Route.detail(id: id))
    }
}
```

## Gotchas

### Index Size Limits
- CSSearchableIndex has no hard documented limit, but Apple recommends keeping index under ~10,000 items for best performance
- For very large datasets, index only the most relevant/recent items
- Use `expirationDate` on CSSearchableItem to auto-expire stale entries

### Thumbnail Size for Performance
- Keep thumbnails small: 300x300 pixels max, JPEG compressed
- Large thumbnails slow down indexing and increase on-disk index size
- Use `Data` (JPEG/PNG) not full PlatformImage objects

### CSSearchableIndex.default() Thread Safety
- `CSSearchableIndex.default()` returns a singleton but its methods are NOT actor-isolated
- Wrap all calls in an actor (SpotlightIndexManager) to prevent data races
- Never call `indexSearchableItems` from multiple threads simultaneously

### Handling App Launch from Spotlight Tap
- The app may be cold-launched — ensure navigation state is ready before handling the activity
- Use `.onContinueUserActivity` in SwiftUI, not `application(_:continue:)` alone
- The activity type is `CSSearchableItemActionType` (a constant from CoreSpotlight)

### Index Maintenance on App Update
- After a data model change, old indexed items may have stale attributes
- Call `removeAll(domain:)` then re-index on first launch after update
- Store indexed schema version in UserDefaults to detect when reindex is needed

### Domain Identifiers
- Always set `domainIdentifier` on items — it allows bulk removal by domain
- Use reverse-DNS style: `"com.myapp.articles"`, `"com.myapp.products"`
- Without domains, you can only remove by individual identifier or remove everything

## References

- **templates.md** — All production Swift templates for Spotlight indexing
- **patterns.md** — CSSearchableItemAttributeSet content types, batch strategies, Siri suggestions, testing
- Related: `generators/deep-linking` — Deep link routing from Spotlight taps
