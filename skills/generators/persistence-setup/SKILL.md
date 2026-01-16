---
name: persistence-setup
description: Generates SwiftData or CoreData persistence layer with optional iCloud sync. Use when user wants to add local storage, data persistence, or cloud sync.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Persistence Setup Generator

Generates a production-ready persistence layer using SwiftData (iOS 17+) or CoreData with optional iCloud (CloudKit) sync.

## When This Skill Activates

- User asks to "add persistence" or "set up data storage"
- User mentions "SwiftData", "CoreData", or "local storage"
- User wants to "sync data to iCloud" or "enable cloud sync"
- User asks about "offline storage" or "data models"

## Pre-Generation Checks (CRITICAL)

### 1. Project Context Detection

Before generating, ALWAYS check:

```bash
# Check deployment target
cat Package.swift | grep -i "platform"
# Or check project.pbxproj

# Find existing persistence implementations
rg -l "ModelContainer|NSPersistentContainer|@Model|@Entity" --type swift

# Check for existing SwiftData models
rg "@Model" --type swift | head -5

# Check for CoreData stack
rg "NSManagedObjectContext|NSPersistentStore" --type swift | head -5

# Check existing entitlements for iCloud
cat *.entitlements 2>/dev/null | grep -i "icloud"
```

### 2. Framework Selection

**Use SwiftData if:**
- Deployment target is iOS 17+ / macOS 14+
- User explicitly requests SwiftData
- No existing CoreData implementation

**Use CoreData if:**
- Deployment target < iOS 17
- Existing CoreData stack present
- User explicitly requests CoreData

### 3. Conflict Detection

If existing persistence found:
- Ask: Extend existing, migrate to SwiftData, or create separate?

## Configuration Questions

Ask user via AskUserQuestion:

1. **Framework choice?**
   - SwiftData (iOS 17+, recommended)
   - CoreData (older targets)

2. **Enable iCloud sync?**
   - Yes (requires CloudKit entitlement)
   - No (local only)

3. **Generate example model?**
   - Yes (with sample Item model)
   - No (just infrastructure)

## Generation Process

### Step 1: Create Core Files

**Always generate:**
```
Sources/Persistence/
├── PersistenceController.swift    # Container setup
├── Repository.swift               # Repository protocol
└── SwiftDataRepository.swift      # Concrete implementation
```

**If example model requested:**
```
Sources/Persistence/Models/
└── Item.swift                     # Sample @Model
```

**If iCloud enabled:**
```
Sources/Persistence/CloudSync/
├── CloudKitConfiguration.swift    # Container identifier
└── SyncStatus.swift               # Sync monitoring
```

### Step 2: Read Templates

Read templates from this skill:
- `templates/PersistenceController.swift`
- `templates/Repository.swift`
- `templates/SwiftDataRepository.swift`
- `templates/ExampleModel.swift`
- `templates/CloudKitConfiguration.swift` (if iCloud)
- `templates/SyncStatus.swift` (if iCloud)

### Step 3: Customize for Project

Adapt templates to match:
- Project naming conventions
- Existing model patterns
- Bundle identifier for CloudKit container

### Step 4: Integration

**Basic Integration:**
```swift
@main
struct MyApp: App {
    let container = PersistenceController.shared.container

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
```

**With iCloud sync:**
```swift
@main
struct MyApp: App {
    let container = PersistenceController.shared.container

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(\.syncStatus, SyncStatus.shared)
        }
    }
}
```

## iCloud Sync Setup

### Required Capabilities (Xcode)

1. **iCloud** capability:
   - Check "CloudKit"
   - Add container: `iCloud.com.yourcompany.yourapp`

2. **Background Modes** (optional, for background sync):
   - Check "Remote notifications"

### Required Entitlements

```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.yourcompany.yourapp</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### CloudKit Dashboard Setup

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Select your container
3. Schema is auto-created from @Model classes
4. Deploy schema to production before release

## Generated Code Patterns

### Repository Protocol
```swift
protocol Repository<T>: Sendable {
    associatedtype T: PersistentModel

    func fetch(predicate: Predicate<T>?, sortBy: [SortDescriptor<T>]) async throws -> [T]
    func insert(_ item: T) async throws
    func delete(_ item: T) async throws
    func save() async throws
}
```

### SwiftData Model
```swift
@Model
final class Item {
    var title: String
    var timestamp: Date
    var isCompleted: Bool

    init(title: String, timestamp: Date = .now, isCompleted: Bool = false) {
        self.title = title
        self.timestamp = timestamp
        self.isCompleted = isCompleted
    }
}
```

### Container with CloudKit
```swift
let container = try ModelContainer(
    for: Item.self,
    configurations: ModelConfiguration(
        cloudKitDatabase: .private("iCloud.com.yourcompany.yourapp")
    )
)
```

## Verification Checklist

After generation, verify:

- [ ] App launches without crashes
- [ ] Data persists between app launches
- [ ] Models compile without errors
- [ ] (If iCloud) CloudKit container exists in dashboard
- [ ] (If iCloud) Data syncs between devices
- [ ] Repository pattern allows easy testing

## Common Customizations

### Adding New Models
```swift
@Model
final class Project {
    var name: String
    @Relationship(deleteRule: .cascade) var items: [Item]

    init(name: String, items: [Item] = []) {
        self.name = name
        self.items = items
    }
}

// Update container
let container = try ModelContainer(for: Item.self, Project.self)
```

### Custom Fetch Descriptors
```swift
let descriptor = FetchDescriptor<Item>(
    predicate: #Predicate { $0.isCompleted == false },
    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
)
let items = try modelContext.fetch(descriptor)
```

### Migration (SwiftData)
```swift
// SwiftData handles lightweight migrations automatically
// For complex migrations, use VersionedSchema

enum ItemSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Item.self] }
}
```

## Troubleshooting

### iCloud Sync Not Working

1. **Check entitlements** match CloudKit container
2. **Verify** CloudKit Dashboard shows your container
3. **Check** device is signed into iCloud
4. **Deploy schema** to production if testing on release build

### Data Not Persisting

1. **Verify** `modelContainer` modifier is on root view
2. **Check** `save()` is called after modifications
3. **Look for errors** in Console.app

### CloudKit Quota Exceeded

- Default quota is generous (free tier: 100MB asset storage)
- Consider pruning old data
- Use `cloudKitDatabase: .automatic` for shared containers

## Related Skills

- `networking-layer` - For remote API data alongside local cache
- `settings-screen` - Often uses @AppStorage (simpler persistence)

## References

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [Syncing Model Data Across Devices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)
