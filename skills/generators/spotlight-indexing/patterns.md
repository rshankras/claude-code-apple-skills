# Spotlight Indexing Patterns & Best Practices

## CSSearchableItemAttributeSet Content Types

Choose the right `UTType` for your content to get the best Spotlight presentation:

| Content Type | UTType | When to Use | Spotlight Behavior |
|-------------|--------|-------------|-------------------|
| General content | `.content` | Default for most app content | Title + description |
| Text / articles | `.text` | Blog posts, notes, documents | Title + description + text preview |
| Images | `.image` | Photo library, gallery items | Shows thumbnail prominently |
| Audio | `.audio` | Podcasts, music, recordings | Shows playback metadata |
| Video | `.movie` | Video library items | Shows duration, thumbnail |
| Contact | `.contact` | People, profiles | Shows phone/email actions |
| Email | `.emailMessage` | Messages, communications | Shows sender/recipient |
| PDF | `.pdf` | Documents | Shows page count |
| Presentation | `.presentation` | Slides, decks | Shows slide count |

### Setting Content Type

```swift
import UniformTypeIdentifiers

// In SpotlightIndexable conformance
var spotlightContentType: UTType { .text }

// Or with the attribute builder
let attributes = SpotlightAttributeBuilder(contentType: .text)
    .title("My Article")
    .build()
```

### Content-Type-Specific Attributes

Different content types unlock additional attribute fields:

```swift
// For audio/music content
let attributes = CSSearchableItemAttributeSet(contentType: .audio)
attributes.title = "Episode 42: Swift Concurrency"
attributes.artist = "Swift Talk"
attributes.album = "Season 5"
attributes.duration = NSNumber(value: 2400)  // seconds
attributes.audioSampleRate = NSNumber(value: 44100)

// For contact/people content
let attributes = CSSearchableItemAttributeSet(contentType: .contact)
attributes.title = "Jane Smith"
attributes.phoneNumbers = ["+1-555-0123"]
attributes.emailAddresses = ["jane@example.com"]
attributes.organizations = ["Acme Corp"]

// For location-based content
let attributes = CSSearchableItemAttributeSet(contentType: .content)
attributes.title = "Golden Gate Park"
attributes.latitude = NSNumber(value: 37.7694)
attributes.longitude = NSNumber(value: -122.4862)
attributes.namedLocation = "San Francisco, CA"
```

## Batch Indexing Strategies

### Small Datasets (< 100 items)

Index all at once — no batching needed:

```swift
let items = articles.map { $0.toSearchableItem() }
try await CSSearchableIndex.default().indexSearchableItems(items)
```

### Medium Datasets (100 - 1,000 items)

Batch in chunks of 100 to avoid memory spikes:

```swift
actor SpotlightIndexManager {
    private let batchSize = 100

    func index<T: SpotlightIndexable>(items: [T]) async {
        let searchableItems = items.map { $0.toSearchableItem() }

        for startIndex in stride(from: 0, to: searchableItems.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, searchableItems.count)
            let batch = Array(searchableItems[startIndex..<endIndex])

            do {
                try await searchableIndex.indexSearchableItems(batch)
            } catch {
                // Log but continue with remaining batches
                print("Batch index failed at offset \(startIndex): \(error)")
            }
        }
    }
}
```

### Large Datasets (1,000+ items)

Use background processing with progress reporting:

```swift
func reindexAll<T: SpotlightIndexable>(
    items: [T],
    domain: String,
    progress: @escaping (Double) -> Void
) async {
    // 1. Remove all existing items in domain
    try? await searchableIndex.deleteSearchableItems(withDomainIdentifiers: [domain])

    // 2. Index in batches with progress
    let total = items.count
    var indexed = 0

    for startIndex in stride(from: 0, to: total, by: batchSize) {
        let endIndex = min(startIndex + batchSize, total)
        let batch = items[startIndex..<endIndex].map { $0.toSearchableItem() }

        try? await searchableIndex.indexSearchableItems(batch)

        indexed += batch.count
        progress(Double(indexed) / Double(total))

        // Yield to avoid starving other work
        await Task.yield()
    }
}
```

### Indexing on Background Queue

For initial sync or large imports, run indexing in a low-priority task:

```swift
func performBackgroundReindex() {
    Task(priority: .utility) {
        let allArticles = await repository.fetchAll()
        await SpotlightIndexManager.shared.reindexAll(
            items: allArticles,
            domain: "com.myapp.articles"
        )
    }
}
```

## Index Maintenance

### When to Reindex

| Trigger | Action |
|---------|--------|
| Item created | Index single item |
| Item updated | Re-index single item (same ID overwrites) |
| Item deleted | Remove by identifier |
| App update with model changes | Full reindex of affected domain |
| Data migration | Full reindex of all domains |
| User logs out | Remove all items |
| User switches account | Remove all, reindex for new account |

### Schema Version Tracking

Detect when a reindex is needed after app updates:

```swift
struct SpotlightSchemaVersion {
    private static let key = "SpotlightIndexSchemaVersion"
    private static let currentVersion = 2  // Increment when attributes change

    static var needsReindex: Bool {
        let stored = UserDefaults.standard.integer(forKey: key)
        return stored < currentVersion
    }

    static func markReindexComplete() {
        UserDefaults.standard.set(currentVersion, forKey: key)
    }
}

// Call on app launch
func checkSpotlightIndex() async {
    if SpotlightSchemaVersion.needsReindex {
        await SpotlightIndexManager.shared.reindexAll(
            items: await fetchAllContent(),
            domain: "com.myapp.content"
        )
        SpotlightSchemaVersion.markReindexComplete()
    }
}
```

### TTL via expirationDate

Set expiration dates on items that become stale:

```swift
extension CSSearchableItem {
    /// Set a time-to-live on this searchable item.
    func withExpiration(days: Int) -> CSSearchableItem {
        self.expirationDate = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: Date()
        )
        return self
    }
}

// Usage: Event expires after the event date
let item = event.toSearchableItem()
    .withExpiration(days: daysUntilEvent + 1)
```

### Cleanup on App Launch

```swift
func cleanupSpotlightIndex() async {
    // Remove items for content that no longer exists
    let indexedIDs = await SpotlightIndexManager.shared.allIndexedIDs()
    let existingIDs = Set(await repository.fetchAllIDs())
    let orphanedIDs = indexedIDs.subtracting(existingIDs)

    if !orphanedIDs.isEmpty {
        await SpotlightIndexManager.shared.remove(identifiers: Array(orphanedIDs))
    }
}
```

## Siri Suggestions Integration

### NSUserActivity for Eligibility

Core Spotlight indexing makes content findable in Spotlight. NSUserActivity makes content eligible for **Siri Suggestions** — proactive recommendations based on user behavior patterns.

```swift
// Create an activity when the user views content
func makeUserActivity(for article: Article) -> NSUserActivity {
    let activity = NSUserActivity(activityType: "com.myapp.viewArticle")
    activity.title = article.title
    activity.isEligibleForSearch = true
    activity.isEligibleForPrediction = true
    activity.keywords = Set(article.tags)
    activity.persistentIdentifier = article.id.uuidString

    // Link to the CSSearchableItem for unified results
    let attributes = CSSearchableItemAttributeSet(contentType: .text)
    attributes.title = article.title
    attributes.contentDescription = String(article.body.prefix(200))
    attributes.relatedUniqueIdentifier = article.id.uuidString
    activity.contentAttributeSet = attributes

    return activity
}
```

### SwiftUI Integration with .userActivity

```swift
struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            Text(article.body)
        }
        .userActivity("com.myapp.viewArticle") { activity in
            activity.title = article.title
            activity.isEligibleForSearch = true
            activity.isEligibleForPrediction = true
            activity.keywords = Set(article.tags)

            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = article.title
            attributes.contentDescription = String(article.body.prefix(200))
            attributes.relatedUniqueIdentifier = article.id.uuidString
            activity.contentAttributeSet = attributes
        }
    }
}
```

### relatedUniqueIdentifier: The Key Connection

Setting `relatedUniqueIdentifier` on the NSUserActivity's `contentAttributeSet` links it to the corresponding `CSSearchableItem`. This prevents duplicate results in Spotlight — the system shows one result backed by both the indexed item and the activity.

```swift
// CSSearchableItem with ID "article-123"
let item = CSSearchableItem(
    uniqueIdentifier: "article-123",
    domainIdentifier: "com.myapp.articles",
    attributeSet: attributes
)

// NSUserActivity links to the same item
attributes.relatedUniqueIdentifier = "article-123"
activity.contentAttributeSet = attributes
```

### Siri Shortcuts Integration (iOS 16+)

For deeper Siri integration, combine with App Intents:

```swift
import AppIntents

struct OpenArticleIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Article"
    static var description = IntentDescription("Opens a specific article")

    @Parameter(title: "Article")
    var article: ArticleEntity

    func perform() async throws -> some IntentResult {
        // Navigate to article
        return .result()
    }
}

// Donate when user views an article
func donateIntent(for article: Article) {
    let intent = OpenArticleIntent()
    intent.article = ArticleEntity(article: article)
    // System automatically creates a shortcut suggestion
}
```

## On-Device Search Ranking

### How Apple Ranks Spotlight Results

Apple uses several signals to rank results from your app:

1. **Engagement frequency** — Items the user taps on more often rank higher
2. **Recency** — Recently indexed or viewed items rank higher
3. **Title match quality** — Exact title matches rank above keyword matches
4. **Content type relevance** — Matching the user's likely intent
5. **NSUserActivity signals** — Items with user activity + prediction eligibility get boosted

### Improving Your Ranking

```swift
// DO: Use descriptive, searchable titles
attributes.title = "Chocolate Chip Cookie Recipe"  // ✅ Specific, searchable

// DON'T: Use generic titles
attributes.title = "Recipe #42"  // ❌ Not useful for search

// DO: Include rich keywords
attributes.keywords = ["chocolate", "cookie", "baking", "dessert", "recipe"]

// DO: Set content description for fallback matching
attributes.contentDescription = "Classic homemade chocolate chip cookies with brown butter..."

// DO: Use relatedUniqueIdentifier to unify CSSearchableItem + NSUserActivity
// This ensures engagement signals are combined, not split
```

### Engagement Signals

The system tracks when users tap your Spotlight results. Items that are tapped more often naturally rise in ranking. You cannot directly manipulate this, but you can:

- Index only high-quality, relevant content
- Keep titles clear and descriptive
- Remove stale content that users would never tap
- Use thumbnails to make results visually appealing

## Privacy Considerations

### What Gets Indexed

Core Spotlight indexes are **on-device only**. Indexed content is:
- Stored locally on the user's device
- Not uploaded to Apple servers
- Not shared across devices (unless you re-index on each device)
- Automatically removed when the app is deleted

### What to Index vs. Keep Private

```swift
// ✅ Safe to index — user-facing content
attributes.title = article.title
attributes.contentDescription = article.summary
attributes.keywords = article.tags

// ❌ Never index — sensitive data
// attributes.contentDescription = user.socialSecurityNumber
// attributes.keywords = [user.password, user.apiKey]

// ⚠️ Be careful — potentially sensitive
// Consider a user setting to opt-out of indexing
attributes.contentDescription = message.preview  // Private messages?
```

### User Deletion Handling

When a user deletes content, always remove it from the index:

```swift
func deleteContent(_ item: ContentItem) async {
    // 1. Delete from your data store
    await dataStore.delete(item)

    // 2. Remove from Spotlight index
    await SpotlightIndexManager.shared.remove(identifiers: [item.spotlightID])
}
```

### Account Logout / Switch

```swift
func handleLogout() async {
    // Remove ALL indexed content for this user
    await SpotlightIndexManager.shared.removeAll()
}

func handleAccountSwitch(newAccount: Account) async {
    // Remove old account's content
    await SpotlightIndexManager.shared.removeAll()

    // Re-index new account's content
    let content = await fetchContent(for: newAccount)
    await SpotlightIndexManager.shared.index(items: content)
}
```

### Opt-Out Setting

Provide users a way to disable Spotlight indexing:

```swift
struct SettingsView: View {
    @AppStorage("spotlightIndexingEnabled") private var indexingEnabled = true

    var body: some View {
        Toggle("Show in Spotlight Search", isOn: $indexingEnabled)
            .onChange(of: indexingEnabled) { _, newValue in
                Task {
                    if !newValue {
                        await SpotlightIndexManager.shared.removeAll()
                    } else {
                        await reindexAllContent()
                    }
                }
            }
    }
}
```

## Testing Spotlight Indexing

### CSSearchQuery for Verification

Use `CSSearchQuery` to verify items are correctly indexed:

```swift
import CoreSpotlight
import Testing

@Test
func articleIsIndexedWithCorrectAttributes() async throws {
    let article = Article(
        id: UUID(),
        title: "Test Article",
        body: "This is the body",
        author: "Author",
        tags: ["swift", "ios"]
    )

    // Index the item
    await SpotlightIndexManager.shared.index(item: article)

    // Wait briefly for indexing to complete
    try await Task.sleep(for: .milliseconds(500))

    // Query for it
    let results = try await searchSpotlight(query: "Test Article")
    #expect(results.contains(where: { $0 == article.spotlightID }))
}

func searchSpotlight(query: String) async throws -> [String] {
    try await withCheckedThrowingContinuation { continuation in
        var foundIdentifiers: [String] = []

        let query = CSSearchQuery(
            queryString: query,
            queryContext: .init()
        )

        query.foundItemsHandler = { items in
            foundIdentifiers.append(contentsOf: items.map(\.uniqueIdentifier))
        }

        query.completionHandler = { error in
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: foundIdentifiers)
            }
        }

        query.start()
    }
}
```

### Mock CSSearchableIndex for Unit Tests

```swift
/// Mock index that records operations for test verification.
final class MockSearchableIndex: CSSearchableIndex {
    var indexedItems: [CSSearchableItem] = []
    var removedIdentifiers: [String] = []
    var removedDomains: [String] = []
    var indexCallCount = 0
    var removeCallCount = 0
    var didRemoveAll = false

    override func indexSearchableItems(_ items: [CSSearchableItem]) async throws {
        indexedItems.append(contentsOf: items)
        indexCallCount += 1
    }

    override func deleteSearchableItems(withIdentifiers identifiers: [String]) async throws {
        removedIdentifiers.append(contentsOf: identifiers)
        removeCallCount += 1
    }

    override func deleteSearchableItems(withDomainIdentifiers domainIdentifiers: [String]) async throws {
        removedDomains.append(contentsOf: domainIdentifiers)
        removeCallCount += 1
    }

    override func deleteAllSearchableItems() async throws {
        indexedItems.removeAll()
        didRemoveAll = true
    }
}
```

### Testing SpotlightSearchHandler

```swift
@Test
func extractsItemIDFromSpotlightActivity() {
    let handler = SpotlightSearchHandler()
    let activity = NSUserActivity(activityType: CSSearchableItemActionType)
    activity.userInfo = [CSSearchableItemActivityIdentifier: "article-123"]

    let itemID = handler.extractItemID(from: activity)
    #expect(itemID == "article-123")
}

@Test
func returnsNilForNonSpotlightActivity() {
    let handler = SpotlightSearchHandler()
    let activity = NSUserActivity(activityType: "com.myapp.other")

    let itemID = handler.extractItemID(from: activity)
    #expect(itemID == nil)
}

@Test
func extractsQueryFromContinuation() {
    let handler = SpotlightSearchHandler()
    let activity = NSUserActivity(activityType: CSQueryContinuationActionType)
    activity.userInfo = [CSSearchQueryString: "chocolate cookies"]

    let query = handler.extractQuery(from: activity)
    #expect(query == "chocolate cookies")
}

@Test
func handleSetssPendingItemID() {
    let handler = SpotlightSearchHandler()
    let activity = NSUserActivity(activityType: CSSearchableItemActionType)
    activity.userInfo = [CSSearchableItemActivityIdentifier: "product-456"]

    let result = handler.handle(activity)
    #expect(result == "product-456")
    #expect(handler.pendingItemID == "product-456")
}
```

### Testing the SpotlightIndexable Protocol

```swift
struct TestItem: SpotlightIndexable {
    let spotlightID: String
    let spotlightTitle: String
    let spotlightDescription: String
    let spotlightKeywords: [String]
    let spotlightDomainIdentifier: String
}

@Test
func toSearchableItemSetsAllAttributes() {
    let item = TestItem(
        spotlightID: "test-1",
        spotlightTitle: "Test Title",
        spotlightDescription: "Test Description",
        spotlightKeywords: ["keyword1", "keyword2"],
        spotlightDomainIdentifier: "com.test.items"
    )

    let searchableItem = item.toSearchableItem()

    #expect(searchableItem.uniqueIdentifier == "test-1")
    #expect(searchableItem.domainIdentifier == "com.test.items")
    #expect(searchableItem.attributeSet.title == "Test Title")
    #expect(searchableItem.attributeSet.contentDescription == "Test Description")
    #expect(searchableItem.attributeSet.keywords == ["keyword1", "keyword2"])
}

@Test
func batchIndexSplitsIntoChunks() async {
    let mockIndex = MockSearchableIndex(name: "test")
    let manager = SpotlightIndexManager(index: mockIndex, batchSize: 10)

    let items = (0..<25).map {
        TestItem(
            spotlightID: "item-\($0)",
            spotlightTitle: "Item \($0)",
            spotlightDescription: "Description \($0)",
            spotlightKeywords: [],
            spotlightDomainIdentifier: "com.test"
        )
    }

    await manager.index(items: items)

    #expect(mockIndex.indexCallCount == 3)  // 10 + 10 + 5
    #expect(mockIndex.indexedItems.count == 25)
}
```

### Spotlight Debug in Settings

On a real device, you can verify indexing in Settings:
1. **Settings > Developer > Core Spotlight** (requires Developer Mode)
2. View indexed items per app
3. See item counts and domain breakdowns
4. Manually trigger reindex

In the Simulator:
- Use `CSSearchQuery` programmatically (shown above)
- Check Console.app for CoreSpotlight log messages
- Filter by `subsystem:com.apple.CoreSpotlight`

## Anti-Patterns to Avoid

### Don't Index Everything

```swift
// ❌ Indexing every database row
for row in database.allRows() {
    await index(row)  // 100,000 items = slow, wasteful
}

// ✅ Index only user-relevant content
let recentItems = database.items(limit: 5000, sortedBy: .lastAccessed)
await index(recentItems)
```

### Don't Index on the Main Thread

```swift
// ❌ Blocks UI during indexing
func viewDidAppear() {
    let items = fetchItems().map { $0.toSearchableItem() }
    try? CSSearchableIndex.default().indexSearchableItems(items)  // Synchronous!
}

// ✅ Use async/await off the main thread
func viewDidAppear() {
    Task {
        await SpotlightIndexManager.shared.index(items: fetchItems())
    }
}
```

### Don't Forget to Remove Deleted Content

```swift
// ❌ Content deleted but still appears in Spotlight
func delete(_ item: Item) {
    database.delete(item)
    // Forgot to remove from Spotlight!
}

// ✅ Always pair delete with index removal
func delete(_ item: Item) async {
    database.delete(item)
    await SpotlightIndexManager.shared.remove(identifiers: [item.spotlightID])
}
```

### Don't Use Large Thumbnails

```swift
// ❌ Full-size photo as thumbnail (10 MB)
attributes.thumbnailData = photo.fullSizeJPEGData

// ✅ Compressed, resized thumbnail (< 50 KB)
attributes.thumbnailData = photo.thumbnailData(maxSize: CGSize(width: 300, height: 300))
```

### Don't Ignore Errors Silently in Production

```swift
// ❌ Swallowing errors completely
try? await index.indexSearchableItems(items)

// ✅ Log errors for diagnostics
do {
    try await index.indexSearchableItems(items)
} catch {
    Logger.spotlight.error("Index failed: \(error.localizedDescription)")
    // Consider retry logic for transient failures
}
```
