# Persistence Patterns

Best practices for implementing data persistence in iOS and macOS apps using SwiftData.

## SwiftData Fundamentals

### Model Definition

```swift
import SwiftData

@Model
final class Item {
    // Stored properties
    var title: String
    var timestamp: Date
    var isCompleted: Bool

    // Transient (not persisted)
    @Transient var isSelected: Bool = false

    // Unique constraint
    @Attribute(.unique) var identifier: UUID

    // Relationships
    @Relationship(deleteRule: .cascade) var tags: [Tag]
    @Relationship(inverse: \Project.items) var project: Project?

    init(title: String) {
        self.identifier = UUID()
        self.title = title
        self.timestamp = .now
        self.isCompleted = false
    }
}
```

### Model Attributes

```swift
@Model
final class Document {
    // Unique constraint
    @Attribute(.unique) var id: UUID

    // External storage for large data
    @Attribute(.externalStorage) var imageData: Data?

    // Encrypted (automatically uses Data Protection)
    @Attribute(.allowsCloudEncryption) var sensitiveData: String?

    // Spotlight indexing
    @Attribute(.spotlight) var searchableTitle: String

    // Preserve value on deletion (for soft delete)
    @Attribute(.preserveValueOnDeletion) var deletedAt: Date?
}
```

### Relationships

```swift
@Model
final class Project {
    var name: String

    // One-to-many with cascade delete
    @Relationship(deleteRule: .cascade)
    var items: [Item] = []

    // One-to-one (optional)
    @Relationship
    var owner: User?

    // Many-to-many
    @Relationship
    var collaborators: [User] = []
}

@Model
final class Item {
    var title: String

    // Inverse relationship (required for bidirectional)
    @Relationship(inverse: \Project.items)
    var project: Project?
}
```

## Repository Pattern

### Protocol Definition

```swift
protocol Repository<T>: Sendable {
    associatedtype T: PersistentModel

    func fetch(
        predicate: Predicate<T>?,
        sortBy: [SortDescriptor<T>]
    ) async throws -> [T]

    func fetchOne(predicate: Predicate<T>) async throws -> T?

    func insert(_ item: T) async throws
    func delete(_ item: T) async throws
    func save() async throws
}

extension Repository {
    func fetch(sortBy: [SortDescriptor<T>] = []) async throws -> [T] {
        try await fetch(predicate: nil, sortBy: sortBy)
    }
}
```

### SwiftData Implementation

```swift
@MainActor
final class SwiftDataRepository<T: PersistentModel>: Repository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetch(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) async throws -> [T] {
        let descriptor = FetchDescriptor<T>(
            predicate: predicate,
            sortBy: sortBy
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchOne(predicate: Predicate<T>) async throws -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func insert(_ item: T) async throws {
        modelContext.insert(item)
        try save()
    }

    func delete(_ item: T) async throws {
        modelContext.delete(item)
        try save()
    }

    func save() async throws {
        try modelContext.save()
    }
}
```

### Usage in Views

```swift
struct ItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }

    private func deleteItem(_ item: Item) {
        modelContext.delete(item)
    }
}
```

## Container Configuration

### Basic Setup

```swift
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let schema = Schema([
            Item.self,
            Project.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

### With iCloud Sync

```swift
@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        let schema = Schema([Item.self])

        // CloudKit configuration
        let cloudConfig = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.yourcompany.yourapp")
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: cloudConfig
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
```

### Multiple Configurations

```swift
// Separate local and synced stores
let localConfig = ModelConfiguration(
    "Local",
    schema: Schema([CachedData.self]),
    cloudKitDatabase: .none
)

let syncedConfig = ModelConfiguration(
    "Synced",
    schema: Schema([UserDocument.self]),
    cloudKitDatabase: .private("iCloud.com.yourapp")
)

let container = try ModelContainer(
    for: Schema([CachedData.self, UserDocument.self]),
    configurations: localConfig, syncedConfig
)
```

## Querying Data

### Using @Query

```swift
struct ContentView: View {
    // Simple query
    @Query private var items: [Item]

    // With sorting
    @Query(sort: \Item.timestamp, order: .reverse)
    private var sortedItems: [Item]

    // With predicate
    @Query(filter: #Predicate<Item> { $0.isCompleted == false })
    private var pendingItems: [Item]

    // With both
    @Query(
        filter: #Predicate<Item> { $0.isCompleted == false },
        sort: \Item.timestamp,
        order: .reverse
    )
    private var pendingSortedItems: [Item]

    // With animation
    @Query(sort: \Item.timestamp, animation: .default)
    private var animatedItems: [Item]
}
```

### Dynamic Queries

```swift
struct FilteredItemsView: View {
    @Query private var items: [Item]

    let showCompleted: Bool

    init(showCompleted: Bool) {
        self.showCompleted = showCompleted

        let predicate: Predicate<Item>? = showCompleted
            ? nil
            : #Predicate { $0.isCompleted == false }

        _items = Query(
            filter: predicate,
            sort: \Item.timestamp,
            order: .reverse
        )
    }

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### Fetch Descriptors

```swift
func fetchRecentItems(context: ModelContext) throws -> [Item] {
    let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now)!

    let descriptor = FetchDescriptor<Item>(
        predicate: #Predicate { $0.timestamp > oneWeekAgo },
        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )

    return try context.fetch(descriptor)
}

// With pagination
func fetchItemsPage(page: Int, pageSize: Int, context: ModelContext) throws -> [Item] {
    var descriptor = FetchDescriptor<Item>(
        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    descriptor.fetchOffset = page * pageSize
    descriptor.fetchLimit = pageSize

    return try context.fetch(descriptor)
}
```

## iCloud Sync Patterns

### Sync Status Monitoring

```swift
@Observable
final class SyncStatus {
    static let shared = SyncStatus()

    private(set) var isSyncing = false
    private(set) var lastSyncDate: Date?
    private(set) var error: Error?

    private init() {
        // Monitor CloudKit account status
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAccountStatus()
            }
        }
    }

    @MainActor
    func checkAccountStatus() async {
        do {
            let status = try await CKContainer.default().accountStatus()
            // Handle status changes
        } catch {
            self.error = error
        }
    }
}
```

### Conflict Resolution

SwiftData with CloudKit uses "last writer wins" by default. For custom resolution:

```swift
@Model
final class Document {
    var content: String
    var lastModified: Date
    var deviceID: String  // Track which device modified

    // Version tracking for conflict detection
    var version: Int

    func merge(with other: Document) -> Document {
        // Custom merge logic
        if self.lastModified > other.lastModified {
            return self
        } else {
            return other
        }
    }
}
```

### Handling Offline Mode

```swift
@Observable
final class DataManager {
    private let modelContext: ModelContext
    private let networkMonitor = NWPathMonitor()

    var isOnline = true

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: .global())
    }

    func saveItem(_ item: Item) throws {
        modelContext.insert(item)
        try modelContext.save()

        // SwiftData automatically syncs when online
        // No manual sync needed
    }
}
```

## Migration Strategies

### Lightweight Migration (Automatic)

SwiftData handles these automatically:
- Adding new properties (with defaults)
- Removing properties
- Renaming models/properties (with `@Attribute(originalName:)`)

```swift
@Model
final class Item {
    var title: String

    // Renamed from "done" to "isCompleted"
    @Attribute(originalName: "done")
    var isCompleted: Bool

    // New property with default
    var priority: Int = 0
}
```

### Versioned Schemas

```swift
enum ItemSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ItemV1.self]
    }

    @Model
    final class ItemV1 {
        var title: String
    }
}

enum ItemSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Item.self]  // Current model
    }
}

// Migration plan
enum ItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ItemSchemaV1.self, ItemSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: ItemSchemaV1.self,
        toVersion: ItemSchemaV2.self
    )
}
```

## Performance Best Practices

### Batch Operations

```swift
func batchInsert(items: [Item], context: ModelContext) throws {
    for item in items {
        context.insert(item)
    }
    // Single save for all inserts
    try context.save()
}

func batchDelete(predicate: Predicate<Item>, context: ModelContext) throws {
    try context.delete(model: Item.self, where: predicate)
}
```

### Prefetching Relationships

```swift
var descriptor = FetchDescriptor<Project>()
descriptor.relationshipKeyPathsForPrefetching = [\Project.items]

let projects = try context.fetch(descriptor)
// items are already loaded, no additional fetches needed
```

### Background Processing

```swift
actor BackgroundPersistence {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func importData(_ data: [ImportItem]) async throws {
        let context = ModelContext(container)

        for item in data {
            let newItem = Item(title: item.title)
            context.insert(newItem)
        }

        try context.save()
    }
}
```

## Testing

### In-Memory Container

```swift
@MainActor
func makePreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, configurations: config)

    // Add sample data
    let context = container.mainContext
    context.insert(Item(title: "Sample Item"))
    try! context.save()

    return container
}

#Preview {
    ContentView()
        .modelContainer(makePreviewContainer())
}
```

### Mock Repository

```swift
final class MockItemRepository: Repository {
    typealias T = Item

    var items: [Item] = []
    var insertCalled = false
    var deleteCalled = false

    func fetch(predicate: Predicate<Item>?, sortBy: [SortDescriptor<Item>]) async throws -> [Item] {
        items
    }

    func fetchOne(predicate: Predicate<Item>) async throws -> Item? {
        items.first
    }

    func insert(_ item: Item) async throws {
        insertCalled = true
        items.append(item)
    }

    func delete(_ item: Item) async throws {
        deleteCalled = true
        items.removeAll { $0.id == item.id }
    }

    func save() async throws {}
}
```
