---
name: cloudkit-sync
description: Generate CloudKit sync infrastructure using CKSyncEngine with conflict resolution, sharing, and account monitoring. Use when adding iCloud sync to an iOS/macOS app.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# CloudKit Sync Generator

Generate production-ready CloudKit sync infrastructure using `CKSyncEngine` (iOS 17+ / macOS 14+), the modern replacement for manual `CKOperation` chains.

## When This Skill Activates

Use this skill when the user:
- Asks to "add iCloud sync" or "sync data across devices"
- Mentions "CloudKit", "CKSyncEngine", or "cloud sync"
- Wants to "share data between users" via iCloud
- Asks about "conflict resolution" for synced data
- Mentions "CKRecord", "CKShare", or "CKRecordZone"

## Pre-Generation Checks

### 1. Project Context Detection

Before generating, ALWAYS check:

```bash
# Check deployment target (CKSyncEngine requires iOS 17+ / macOS 14+)
grep -r "platform" Package.swift 2>/dev/null || true
grep -r "IPHONEOS_DEPLOYMENT_TARGET\|MACOSX_DEPLOYMENT_TARGET" --include="*.pbxproj" | head -3

# Find existing CloudKit implementations
rg -l "CKSyncEngine\|CKContainer\|CKRecord\|CKOperation" --type swift | head -10

# Check for existing entitlements
find . -name "*.entitlements" -exec cat {} \; 2>/dev/null | grep -i "icloud"

# Check existing persistence layer
rg -l "@Model\|NSManagedObject\|PersistentModel" --type swift | head -5

# Check for existing sync infrastructure
rg "CKSyncEngineDelegate\|CKSubscription\|CKFetchRecordZoneChanges" --type swift | head -5
```

### 2. Compatibility Verification

**CKSyncEngine requires:**
- iOS 17.0+ / macOS 14.0+ / watchOS 10.0+ / tvOS 17.0+
- CloudKit entitlement
- Active iCloud account on device

If deployment target is below iOS 17 / macOS 14, warn the user that CKSyncEngine is not available and suggest either raising the target or using the older CKOperation approach (which this generator does not cover).

### 3. Conflict Detection

If existing CloudKit code is found:
- Ask: Replace existing implementation, extend it, or migrate to CKSyncEngine?

## Configuration Questions

Ask user via AskUserQuestion:

1. **What data needs syncing?**
   - Provide your model types (e.g., Note, Task, Document)
   - What properties does each model have?

2. **Database scope?**
   - Private only (user's own data across their devices)
   - Private + Shared (enable CKShare for collaboration)

3. **Conflict resolution strategy?**
   - Server-wins (simplest -- always accept server version)
   - Client-wins (always push local version)
   - Timestamp-based merge (most recent modification wins)
   - Custom merge (field-level merge logic)

4. **Existing persistence layer?**
   - SwiftData (will generate CKRecord <-> SwiftData bridging)
   - Core Data (will generate CKRecord <-> NSManagedObject bridging)
   - Custom / in-memory (will generate standalone CKRecord mapping)
   - None yet (will generate lightweight local store + sync)

## Generation Process

### Step 1: Read Templates

Read code templates from this skill:
- `templates.md` - All CKSyncEngine code templates

### Step 2: Create Core Files

Generate these files based on configuration:

**Always generate:**
```
Sources/CloudSync/
├── SyncEngine.swift              # CKSyncEngine setup + CKSyncEngineDelegate
├── SyncConfiguration.swift       # Zone names, container ID, database scope
├── RecordMapping.swift           # CKRecord <-> local model conversion
├── ConflictResolver.swift        # Conflict resolution strategy
├── SyncMonitor.swift             # Account status + sync state observation
└── CloudSyncError.swift          # Typed error handling with CKError mapping
```

**If sharing enabled:**
```
Sources/CloudSync/Sharing/
├── ShareManager.swift            # CKShare creation and management
└── ShareParticipantView.swift    # UICloudSharingController wrapper
```

### Step 3: Determine File Location

Check project structure:
- If `Sources/` exists -> `Sources/CloudSync/`
- If `App/` exists -> `App/CloudSync/`
- Otherwise -> `CloudSync/`

### Step 4: Customize for Project

Adapt templates to match:
- User's model types and property names
- Bundle identifier for CloudKit container ID
- Chosen conflict resolution strategy
- Database scope (private only vs. private + shared)

### Step 5: Entitlements Setup

Generate or update entitlements file with required CloudKit capabilities.

## Entitlements and Capabilities Setup

### Required Xcode Capabilities

1. **iCloud** capability:
   - Check "CloudKit"
   - Add container: `iCloud.com.<team-identifier>.<app-bundle-id>`

2. **Background Modes** (recommended):
   - Check "Remote notifications" (for push-based sync triggers)

### Required Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.yourcompany.yourapp</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

### CloudKit Dashboard Setup

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Select your container
3. Record types are auto-created when you first save a CKRecord of that type during development
4. **Deploy schema to production before App Store release**
5. Indexes are required for queryable fields -- add them in the dashboard

## Output Format

After generation, provide:

### Files Created

```
Sources/CloudSync/
├── SyncEngine.swift              # CKSyncEngine + delegate implementation
├── SyncConfiguration.swift       # Container, zone, and scope config
├── RecordMapping.swift           # CKRecord <-> model bridging
├── ConflictResolver.swift        # Pluggable conflict resolution
├── SyncMonitor.swift             # Account status + sync state
├── CloudSyncError.swift          # Error types with CKError mapping
└── Sharing/                      # (if sharing enabled)
    ├── ShareManager.swift        # CKShare lifecycle
    └── ShareParticipantView.swift
```

### Integration Steps

**1. Initialize the sync engine at app launch:**

```swift
@main
struct MyApp: App {
    @State private var syncEngine = SyncEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(syncEngine)
                .task {
                    await syncEngine.start()
                }
        }
    }
}
```

**2. Send local changes to CloudKit:**

```swift
// After saving a local model
let recordID = CKRecord.ID(recordName: item.id.uuidString, zoneID: SyncConfiguration.zoneID)
syncEngine.addPendingChange(.saveRecord(recordID))
```

**3. Handle incoming changes in your model layer:**

The `SyncEngine` delegate methods automatically call `RecordMapping` to convert fetched `CKRecord` objects into your local model types and persist them.

**4. Monitor sync status in the UI:**

```swift
struct SyncStatusView: View {
    @Environment(SyncMonitor.self) private var syncMonitor

    var body: some View {
        HStack {
            if syncMonitor.isSyncing {
                ProgressView()
                Text("Syncing...")
            } else if let error = syncMonitor.lastError {
                Image(systemName: "exclamationmark.icloud")
                Text(error.localizedDescription)
            } else {
                Image(systemName: "checkmark.icloud")
                Text("Up to date")
            }
        }
    }
}
```

### Testing

**Use a separate CloudKit container for development:**

```swift
#if DEBUG
let containerID = "iCloud.com.yourcompany.yourapp.dev"
#else
let containerID = "iCloud.com.yourcompany.yourapp"
#endif
```

**Test account status handling:**

```swift
@Test
func handlesNoAccountGracefully() async {
    let monitor = SyncMonitor()
    await monitor.handleAccountStatus(.noAccount)
    #expect(monitor.accountAvailable == false)
    #expect(monitor.lastError is CloudSyncError)
}
```

**Test conflict resolution:**

```swift
@Test
func serverWinsConflictResolution() {
    let resolver = ConflictResolver(strategy: .serverWins)
    let serverRecord = makeCKRecord(title: "Server Version", modifiedAt: .now)
    let clientRecord = makeCKRecord(title: "Client Version", modifiedAt: .distantPast)

    let resolved = resolver.resolve(server: serverRecord, client: clientRecord)
    #expect(resolved["title"] == "Server Version")
}
```

## Verification Checklist

After generation, verify:

- [ ] App compiles without errors
- [ ] Entitlements file contains CloudKit container identifier
- [ ] CloudKit container exists in Apple Developer portal
- [ ] CKSyncEngine initializes without crash
- [ ] Local changes appear as pending record zone changes
- [ ] Fetched changes are converted to local models
- [ ] Conflict resolution behaves as configured
- [ ] Account status changes are observed and surfaced to UI
- [ ] (If sharing) CKShare can be created and participants added
- [ ] App handles offline gracefully (queues changes)
- [ ] App handles "no iCloud account" gracefully

## Common Customizations

### Adding a New Synced Model Type

1. Add `CKRecord` field mapping in `RecordMapping.swift`
2. Register the record zone in `SyncConfiguration.swift` (if using a separate zone)
3. Update `nextRecordZoneChangeBatch()` to include pending changes for the new type

### Switching Conflict Resolution

```swift
// Change strategy without touching sync engine code
let resolver = ConflictResolver(strategy: .timestampMerge)
let config = SyncConfiguration(conflictResolver: resolver)
```

### Adding Shared Database Support

1. Set `databaseScope` to include `.shared` in `SyncConfiguration`
2. Add `ShareManager` to handle `CKShare` lifecycle
3. Wrap `UICloudSharingController` for the sharing UI

## Troubleshooting

### Sync Not Working

1. Verify device is signed into iCloud (Settings > Apple Account)
2. Check entitlements match the CloudKit container identifier exactly
3. Confirm container exists in CloudKit Dashboard
4. Look for CKError logs in Console.app -- filter by "CloudKit"
5. Ensure `CKSyncEngine` is started (not just initialized)

### "User Did Not Sign In" Error

- `CKAccountStatus.noAccount` -- prompt user to sign into iCloud
- `CKAccountStatus.restricted` -- parental controls or MDM restriction
- `CKAccountStatus.temporarilyUnavailable` -- retry after delay

### Schema Deployment

- Development schema changes are automatic
- **Production schema must be explicitly deployed** from CloudKit Dashboard
- Schema changes in production are additive only (cannot remove fields)

### Rate Limiting

- CloudKit has per-user rate limits
- `CKError.requestRateLimited` includes `retryAfterSeconds` in `userInfo`
- `CKSyncEngine` handles most retry logic automatically

## References

- **templates.md** -- All code templates for CKSyncEngine infrastructure
- [CKSyncEngine Documentation](https://developer.apple.com/documentation/cloudkit/cksyncengine)
- [CloudKit Overview](https://developer.apple.com/documentation/cloudkit)
- [Sharing CloudKit Data](https://developer.apple.com/documentation/cloudkit/shared_records)
- [CloudKit Dashboard](https://icloud.developer.apple.com/)
