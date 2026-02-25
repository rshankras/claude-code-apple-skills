# Spotlight Indexing Code Templates

Production-ready Swift templates for Core Spotlight indexing infrastructure. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## SpotlightIndexable.swift

```swift
import Foundation
import CoreSpotlight

/// Protocol that any model can conform to for Spotlight indexing.
///
/// Provides all the data needed to create a `CSSearchableItem`.
/// Conform your models to this protocol and pass them to `SpotlightIndexManager`.
///
/// Usage:
/// ```swift
/// struct Article: SpotlightIndexable {
///     let id: UUID
///     let title: String
///     let body: String
///
///     var spotlightID: String { id.uuidString }
///     var spotlightTitle: String { title }
///     var spotlightDescription: String { String(body.prefix(300)) }
///     var spotlightKeywords: [String] { ["article"] }
///     var spotlightThumbnailData: Data? { nil }
///     var spotlightDomainIdentifier: String { "com.myapp.articles" }
/// }
/// ```
protocol SpotlightIndexable {
    /// Unique identifier for the searchable item.
    /// Must be stable across app launches (e.g., UUID string).
    var spotlightID: String { get }

    /// Title displayed in Spotlight results.
    var spotlightTitle: String { get }

    /// Description displayed below the title in Spotlight results.
    /// Keep under 300 characters for best display.
    var spotlightDescription: String { get }

    /// Keywords for matching search queries.
    /// Include synonyms and related terms the user might search for.
    var spotlightKeywords: [String] { get }

    /// Optional thumbnail image data (JPEG or PNG).
    /// Keep under 300x300 pixels for performance.
    var spotlightThumbnailData: Data? { get }

    /// Domain identifier for grouping related items.
    /// Enables bulk removal by domain (e.g., "com.myapp.articles").
    var spotlightDomainIdentifier: String { get }

    /// Optional: Content type for the attribute set.
    /// Defaults to general content. Override for specific types.
    var spotlightContentType: UTType { get }

    /// Optional: Expiration date after which the item is removed from the index.
    /// Defaults to nil (no expiration).
    var spotlightExpirationDate: Date? { get }
}

// MARK: - Defaults

extension SpotlightIndexable {
    var spotlightContentType: UTType { .content }
    var spotlightExpirationDate: Date? { nil }
    var spotlightThumbnailData: Data? { nil }
}

// MARK: - CSSearchableItem Conversion

extension SpotlightIndexable {
    /// Creates a `CSSearchableItem` from this model's Spotlight properties.
    func toSearchableItem() -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: spotlightContentType)
        attributes.title = spotlightTitle
        attributes.contentDescription = spotlightDescription
        attributes.keywords = spotlightKeywords
        attributes.thumbnailData = spotlightThumbnailData
        attributes.domainIdentifier = spotlightDomainIdentifier

        let item = CSSearchableItem(
            uniqueIdentifier: spotlightID,
            domainIdentifier: spotlightDomainIdentifier,
            attributeSet: attributes
        )

        item.expirationDate = spotlightExpirationDate

        return item
    }
}
```

## SpotlightIndexManager.swift

```swift
import Foundation
import CoreSpotlight

/// Actor that manages all Core Spotlight indexing operations.
///
/// Wraps `CSSearchableIndex` with:
/// - Batch indexing for large datasets (configurable batch size)
/// - Safe concurrent access via actor isolation
/// - Domain-based bulk removal
/// - Full reindex support
///
/// Usage:
/// ```swift
/// // Index items
/// await SpotlightIndexManager.shared.index(items: articles)
///
/// // Remove specific items
/// await SpotlightIndexManager.shared.remove(identifiers: ["article-123"])
///
/// // Remove all items in a domain
/// await SpotlightIndexManager.shared.removeAll(domain: "com.myapp.articles")
///
/// // Full reindex
/// await SpotlightIndexManager.shared.reindexAll(items: articles, domain: "com.myapp.articles")
/// ```
actor SpotlightIndexManager {
    static let shared = SpotlightIndexManager()

    private let searchableIndex: CSSearchableIndex
    private let batchSize: Int

    init(
        index: CSSearchableIndex = .default(),
        batchSize: Int = 100
    ) {
        self.searchableIndex = index
        self.batchSize = batchSize
    }

    // MARK: - Index

    /// Index an array of `SpotlightIndexable` items.
    ///
    /// Automatically batches large datasets to avoid memory pressure.
    /// Each batch is indexed in sequence to respect system resources.
    func index<T: SpotlightIndexable>(items: [T]) async {
        guard !items.isEmpty else { return }

        let searchableItems = items.map { $0.toSearchableItem() }

        if searchableItems.count <= batchSize {
            await indexBatch(searchableItems)
        } else {
            // Chunk into batches
            for startIndex in stride(from: 0, to: searchableItems.count, by: batchSize) {
                let endIndex = min(startIndex + batchSize, searchableItems.count)
                let batch = Array(searchableItems[startIndex..<endIndex])
                await indexBatch(batch)
            }
        }
    }

    /// Index a single `SpotlightIndexable` item.
    func index<T: SpotlightIndexable>(item: T) async {
        await indexBatch([item.toSearchableItem()])
    }

    // MARK: - Remove

    /// Remove items by their unique identifiers.
    func remove(identifiers: [String]) async {
        guard !identifiers.isEmpty else { return }
        do {
            try await searchableIndex.deleteSearchableItems(withIdentifiers: identifiers)
        } catch {
            logError("Failed to remove items: \(error.localizedDescription)")
        }
    }

    /// Remove all items in a domain.
    ///
    /// Use this for bulk cleanup, e.g., removing all articles.
    func removeAll(domain: String) async {
        do {
            try await searchableIndex.deleteSearchableItems(withDomainIdentifiers: [domain])
        } catch {
            logError("Failed to remove domain '\(domain)': \(error.localizedDescription)")
        }
    }

    /// Remove all items from the app's Spotlight index.
    func removeAll() async {
        do {
            try await searchableIndex.deleteAllSearchableItems()
        } catch {
            logError("Failed to remove all items: \(error.localizedDescription)")
        }
    }

    // MARK: - Reindex

    /// Remove all items in a domain, then re-index with fresh data.
    ///
    /// Use after data migration or app update when indexed attributes change.
    func reindexAll<T: SpotlightIndexable>(items: [T], domain: String) async {
        await removeAll(domain: domain)
        await index(items: items)
    }

    // MARK: - Private

    private func indexBatch(_ items: [CSSearchableItem]) async {
        do {
            try await searchableIndex.indexSearchableItems(items)
        } catch {
            logError("Failed to index batch of \(items.count) items: \(error.localizedDescription)")
        }
    }

    private func logError(_ message: String) {
        #if DEBUG
        print("[SpotlightIndexManager] \(message)")
        #endif
    }
}
```

## SpotlightAttributeBuilder.swift

```swift
import Foundation
import CoreSpotlight
import UniformTypeIdentifiers

/// Fluent builder for `CSSearchableItemAttributeSet`.
///
/// Provides a chainable API for constructing rich attribute sets
/// when you need more control than `SpotlightIndexable` provides.
///
/// Usage:
/// ```swift
/// let attributes = SpotlightAttributeBuilder(contentType: .text)
///     .title("SwiftUI Navigation Guide")
///     .description("Learn about NavigationStack and NavigationSplitView")
///     .keywords(["swiftui", "navigation", "ios"])
///     .thumbnail(imageData)
///     .url(URL(string: "myapp://articles/123")!)
///     .rating(4.5)
///     .build()
///
/// let item = CSSearchableItem(
///     uniqueIdentifier: "article-123",
///     domainIdentifier: "com.myapp.articles",
///     attributeSet: attributes
/// )
/// ```
struct SpotlightAttributeBuilder {
    private let attributeSet: CSSearchableItemAttributeSet

    init(contentType: UTType = .content) {
        self.attributeSet = CSSearchableItemAttributeSet(contentType: contentType)
    }

    // MARK: - Core Attributes

    /// Set the title displayed in Spotlight results.
    func title(_ value: String) -> SpotlightAttributeBuilder {
        attributeSet.title = value
        return self
    }

    /// Set the description displayed below the title.
    func description(_ value: String) -> SpotlightAttributeBuilder {
        attributeSet.contentDescription = value
        return self
    }

    /// Set keywords for search matching.
    func keywords(_ values: [String]) -> SpotlightAttributeBuilder {
        attributeSet.keywords = values
        return self
    }

    // MARK: - Visual Attributes

    /// Set thumbnail image data (JPEG or PNG, max 300x300 recommended).
    func thumbnail(_ data: Data?) -> SpotlightAttributeBuilder {
        attributeSet.thumbnailData = data
        return self
    }

    /// Set thumbnail from a URL (system fetches the image).
    func thumbnailURL(_ url: URL) -> SpotlightAttributeBuilder {
        attributeSet.thumbnailURL = url
        return self
    }

    // MARK: - Content Type Attributes

    /// Set a content URL for the item.
    func url(_ value: URL) -> SpotlightAttributeBuilder {
        attributeSet.url = value
        return self
    }

    /// Set the content type identifier.
    func contentType(_ type: UTType) -> SpotlightAttributeBuilder {
        attributeSet.contentType = type.identifier
        return self
    }

    // MARK: - Metadata Attributes

    /// Set a star rating (0.0 to 5.0, displayed as stars in Spotlight).
    func rating(_ value: Double) -> SpotlightAttributeBuilder {
        attributeSet.rating = NSNumber(value: value)
        return self
    }

    /// Set the content creation date.
    func creationDate(_ date: Date) -> SpotlightAttributeBuilder {
        attributeSet.contentCreationDate = date
        return self
    }

    /// Set the content modification date.
    func modificationDate(_ date: Date) -> SpotlightAttributeBuilder {
        attributeSet.contentModificationDate = date
        return self
    }

    /// Set the display name (alternative to title for file-like items).
    func displayName(_ value: String) -> SpotlightAttributeBuilder {
        attributeSet.displayName = value
        return self
    }

    /// Set the domain identifier.
    func domainIdentifier(_ value: String) -> SpotlightAttributeBuilder {
        attributeSet.domainIdentifier = value
        return self
    }

    // MARK: - People / Contact Attributes

    /// Set author names.
    func authors(_ values: [String]) -> SpotlightAttributeBuilder {
        attributeSet.authorNames = values
        return self
    }

    /// Set phone numbers (for contact-type items).
    func phoneNumbers(_ values: [String]) -> SpotlightAttributeBuilder {
        attributeSet.phoneNumbers = values
        return self
    }

    /// Set email addresses (for contact-type items).
    func emailAddresses(_ values: [String]) -> SpotlightAttributeBuilder {
        attributeSet.emailAddresses = values
        return self
    }

    // MARK: - Location Attributes

    /// Set latitude for location-based items.
    func latitude(_ value: Double) -> SpotlightAttributeBuilder {
        attributeSet.latitude = NSNumber(value: value)
        return self
    }

    /// Set longitude for location-based items.
    func longitude(_ value: Double) -> SpotlightAttributeBuilder {
        attributeSet.longitude = NSNumber(value: value)
        return self
    }

    /// Set named location (e.g., "San Francisco, CA").
    func namedLocation(_ value: String) -> SpotlightAttributeBuilder {
        attributeSet.namedLocation = value
        return self
    }

    // MARK: - Build

    /// Build and return the configured `CSSearchableItemAttributeSet`.
    func build() -> CSSearchableItemAttributeSet {
        attributeSet
    }
}
```

## SpotlightSearchHandler.swift

```swift
import Foundation
import CoreSpotlight

/// Handles app continuation from Spotlight search result taps.
///
/// When a user taps a Spotlight result, the system delivers an
/// `NSUserActivity` with `activityType == CSSearchableItemActionType`.
/// This handler extracts the item identifier and routes to the
/// appropriate view.
///
/// ## SwiftUI Integration
///
/// ```swift
/// @main
/// struct MyApp: App {
///     @State private var navigationPath = NavigationPath()
///
///     var body: some Scene {
///         WindowGroup {
///             NavigationStack(path: $navigationPath) {
///                 ContentView()
///                     .navigationDestination(for: SpotlightDestination.self) { dest in
///                         DetailView(id: dest.itemID)
///                     }
///             }
///             .onContinueUserActivity(CSSearchableItemActionType) { activity in
///                 if let destination = SpotlightSearchHandler.shared.destination(from: activity) {
///                     navigationPath.append(destination)
///                 }
///             }
///         }
///     }
/// }
/// ```
///
/// ## UIKit Integration (SceneDelegate)
///
/// ```swift
/// func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
///     if let itemID = SpotlightSearchHandler.shared.extractItemID(from: userActivity) {
///         navigate(to: itemID)
///     }
/// }
/// ```
@Observable
final class SpotlightSearchHandler {
    static let shared = SpotlightSearchHandler()

    /// The most recently received item ID from a Spotlight tap.
    /// Observe this to react to Spotlight navigation.
    private(set) var pendingItemID: String?

    // MARK: - Extract

    /// Extract the searchable item identifier from a Spotlight user activity.
    ///
    /// Returns `nil` if the activity is not a Spotlight search continuation
    /// or if the identifier is missing.
    func extractItemID(from activity: NSUserActivity) -> String? {
        guard activity.activityType == CSSearchableItemActionType else { return nil }
        return activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
    }

    /// Extract a query string if the user launched the app from Spotlight
    /// with a search query (iOS 16+).
    func extractQuery(from activity: NSUserActivity) -> String? {
        guard activity.activityType == CSQueryContinuationActionType else { return nil }
        return activity.userInfo?[CSSearchQueryString] as? String
    }

    // MARK: - Handle

    /// Handle a Spotlight continuation activity.
    ///
    /// Extracts the item ID and stores it as `pendingItemID` for observation.
    /// Returns the extracted item ID, or nil if not a valid Spotlight activity.
    @discardableResult
    func handle(_ activity: NSUserActivity) -> String? {
        if let itemID = extractItemID(from: activity) {
            pendingItemID = itemID
            return itemID
        }
        return nil
    }

    /// Clear the pending item after navigation is complete.
    func clearPending() {
        pendingItemID = nil
    }
}

// MARK: - Navigation Destination

/// A Hashable destination for use with `NavigationStack` and `.navigationDestination`.
struct SpotlightDestination: Hashable {
    let itemID: String
    let domain: String?

    init(itemID: String, domain: String? = nil) {
        self.itemID = itemID
        self.domain = domain
    }
}

extension SpotlightSearchHandler {
    /// Create a `SpotlightDestination` from a Spotlight user activity.
    ///
    /// Use with `NavigationStack`:
    /// ```swift
    /// .navigationDestination(for: SpotlightDestination.self) { dest in
    ///     resolveView(for: dest)
    /// }
    /// ```
    func destination(from activity: NSUserActivity) -> SpotlightDestination? {
        guard let itemID = extractItemID(from: activity) else { return nil }
        return SpotlightDestination(itemID: itemID)
    }
}
```

## SpotlightSyncModifier.swift

```swift
import SwiftUI
import CoreSpotlight

/// ViewModifier that automatically indexes content when a view appears
/// and optionally deindexes when it disappears.
///
/// Usage:
/// ```swift
/// // Index when view appears
/// ArticleDetailView(article: article)
///     .spotlightIndexed(article)
///
/// // Index on appear, deindex on disappear
/// ArticleDetailView(article: article)
///     .spotlightIndexed(article, removeOnDisappear: true)
/// ```
struct SpotlightSyncModifier<T: SpotlightIndexable>: ViewModifier {
    let item: T
    let removeOnDisappear: Bool

    func body(content: Content) -> some View {
        content
            .task {
                await SpotlightIndexManager.shared.index(item: item)
            }
            .onDisappear {
                if removeOnDisappear {
                    Task {
                        await SpotlightIndexManager.shared.remove(identifiers: [item.spotlightID])
                    }
                }
            }
    }
}

extension View {
    /// Index this content in Spotlight when the view appears.
    ///
    /// - Parameters:
    ///   - item: The `SpotlightIndexable` item to index.
    ///   - removeOnDisappear: If `true`, removes the item from the index when the view disappears.
    ///     Defaults to `false` (items remain indexed after viewing).
    func spotlightIndexed<T: SpotlightIndexable>(
        _ item: T,
        removeOnDisappear: Bool = false
    ) -> some View {
        modifier(SpotlightSyncModifier(item: item, removeOnDisappear: removeOnDisappear))
    }
}

// MARK: - Siri Suggestions Activity Modifier

/// ViewModifier that creates an NSUserActivity for Siri suggestions.
///
/// Makes content eligible for Siri suggestions and Spotlight search
/// via the user activity system (complementary to CSSearchableItem indexing).
///
/// Usage:
/// ```swift
/// ArticleView(article: article)
///     .spotlightActivity(
///         id: article.id.uuidString,
///         title: article.title,
///         description: article.body.prefix(200),
///         keywords: article.tags,
///         eligibleForPrediction: true
///     )
/// ```
struct SpotlightActivityModifier: ViewModifier {
    let id: String
    let activityType: String
    let title: String
    let description: String?
    let keywords: Set<String>
    let eligibleForPrediction: Bool

    func body(content: Content) -> some View {
        content
            .userActivity(activityType) { activity in
                activity.title = title
                activity.isEligibleForSearch = true
                activity.isEligibleForPrediction = eligibleForPrediction
                activity.keywords = keywords
                activity.contentAttributeSet = {
                    let attributes = CSSearchableItemAttributeSet(contentType: .content)
                    attributes.title = title
                    attributes.contentDescription = description
                    attributes.keywords = Array(keywords)
                    attributes.relatedUniqueIdentifier = id
                    return attributes
                }()
            }
    }
}

extension View {
    /// Advertise this content as a Siri suggestion and Spotlight result
    /// via NSUserActivity.
    ///
    /// - Parameters:
    ///   - id: Unique identifier matching the CSSearchableItem's uniqueIdentifier.
    ///   - activityType: The activity type (use reverse-DNS, e.g., "com.myapp.viewArticle").
    ///   - title: Display title for the suggestion.
    ///   - description: Optional description text.
    ///   - keywords: Search keywords.
    ///   - eligibleForPrediction: Whether Siri can proactively suggest this content.
    func spotlightActivity(
        id: String,
        activityType: String = "com.myapp.viewItem",
        title: String,
        description: String? = nil,
        keywords: Set<String> = [],
        eligibleForPrediction: Bool = true
    ) -> some View {
        modifier(SpotlightActivityModifier(
            id: id,
            activityType: activityType,
            title: title,
            description: description,
            keywords: keywords,
            eligibleForPrediction: eligibleForPrediction
        ))
    }
}
```
