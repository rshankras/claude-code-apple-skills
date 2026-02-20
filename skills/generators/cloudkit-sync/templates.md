# CloudKit Sync Templates

Code templates for CKSyncEngine-based sync infrastructure. All code targets iOS 17+ / macOS 14+.

## SyncConfiguration

Central configuration for CloudKit container, record zones, and database scope.

```swift
import CloudKit

/// Central configuration for CloudKit sync.
struct SyncConfiguration {
    /// CloudKit container identifier (matches entitlements).
    let containerIdentifier: String

    /// The CKContainer instance.
    var container: CKContainer {
        CKContainer(identifier: containerIdentifier)
    }

    /// The private database.
    var privateDatabase: CKDatabase {
        container.privateCloudDatabase
    }

    /// The shared database (for CKShare-based collaboration).
    var sharedDatabase: CKDatabase {
        container.sharedCloudDatabase
    }

    /// Database scopes to sync.
    let databaseScopes: [CKDatabase.Scope]

    /// Record zone for storing private data.
    static let zoneName = "MyAppZone"
    static let zoneID = CKRecordZone.ID(
        zoneName: zoneName,
        ownerName: CKCurrentUserDefaultName
    )

    /// Conflict resolution strategy.
    let conflictResolver: ConflictResolver

    /// UserDefaults key for persisted sync engine state.
    let stateSerializationKey = "CKSyncEngineStateSerialization"

    // MARK: - Presets

    /// Private-only sync with server-wins conflict resolution.
    static func privateOnly(container: String) -> SyncConfiguration {
        SyncConfiguration(
            containerIdentifier: container,
            databaseScopes: [.private],
            conflictResolver: ConflictResolver(strategy: .serverWins)
        )
    }

    /// Private + shared sync with timestamp-based merge.
    static func withSharing(container: String) -> SyncConfiguration {
        SyncConfiguration(
            containerIdentifier: container,
            databaseScopes: [.private, .shared],
            conflictResolver: ConflictResolver(strategy: .timestampMerge)
        )
    }
}
```

## SyncEngine

The core sync engine wrapping `CKSyncEngine` and implementing `CKSyncEngineDelegate`.

```swift
import CloudKit
import os.log

/// Manages CloudKit sync using CKSyncEngine.
@Observable
@MainActor
final class SyncEngine {

    // MARK: - Properties

    private var syncEngine: CKSyncEngine?
    private let configuration: SyncConfiguration
    private let recordMapper: RecordMapping
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CloudSync", category: "SyncEngine")

    /// Track record IDs with pending local changes.
    private var pendingSaves: Set<CKRecord.ID> = []
    private var pendingDeletions: Set<CKRecord.ID> = []

    /// Observable sync state.
    private(set) var isSyncing = false
    private(set) var lastSyncDate: Date?
    private(set) var lastError: CloudSyncError?

    // MARK: - Initialization

    init(
        configuration: SyncConfiguration = .privateOnly(container: "iCloud.com.yourcompany.yourapp"),
        recordMapper: RecordMapping = RecordMapping()
    ) {
        self.configuration = configuration
        self.recordMapper = recordMapper
    }

    // MARK: - Lifecycle

    /// Start the sync engine. Call this once at app launch.
    func start() async {
        guard syncEngine == nil else {
            logger.warning("SyncEngine already started")
            return
        }

        // Restore persisted state if available
        let savedState = loadSavedState()

        let config = CKSyncEngine.Configuration(
            database: configuration.privateDatabase,
            stateSerialization: savedState,
            delegate: self
        )

        let engine = CKSyncEngine(config)
        self.syncEngine = engine

        logger.info("CKSyncEngine started")
    }

    /// Stop the sync engine. Call this when the user signs out of iCloud.
    func stop() {
        syncEngine = nil
        pendingSaves.removeAll()
        pendingDeletions.removeAll()
        logger.info("CKSyncEngine stopped")
    }

    // MARK: - Pending Changes

    /// Enqueue a record save. Call this after modifying a local model.
    func addPendingSave(_ recordID: CKRecord.ID) {
        pendingSaves.insert(recordID)
        syncEngine?.state.add(pendingRecordZoneChanges: [
            .saveRecord(recordID)
        ])
        logger.debug("Queued save for \(recordID.recordName)")
    }

    /// Enqueue a record deletion. Call this after deleting a local model.
    func addPendingDeletion(_ recordID: CKRecord.ID) {
        pendingDeletions.insert(recordID)
        syncEngine?.state.add(pendingRecordZoneChanges: [
            .deleteRecord(recordID)
        ])
        logger.debug("Queued deletion for \(recordID.recordName)")
    }

    // MARK: - State Persistence

    /// Save CKSyncEngine state serialization to UserDefaults.
    private func saveState(_ stateSerialization: CKSyncEngine.State.Serialization) {
        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: stateSerialization,
                requiringSecureCoding: true
            )
            UserDefaults.standard.set(data, forKey: configuration.stateSerializationKey)
            logger.debug("Saved sync engine state")
        } catch {
            logger.error("Failed to save sync engine state: \(error.localizedDescription)")
        }
    }

    /// Load saved CKSyncEngine state serialization from UserDefaults.
    private func loadSavedState() -> CKSyncEngine.State.Serialization? {
        guard let data = UserDefaults.standard.data(forKey: configuration.stateSerializationKey) else {
            return nil
        }
        do {
            let state = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: CKSyncEngine.State.Serialization.self,
                from: data
            )
            return state
        } catch {
            logger.error("Failed to load sync engine state: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Zone Management

    /// Ensure the custom record zone exists.
    private func createZoneIfNeeded() async {
        let zone = CKRecordZone(zoneID: SyncConfiguration.zoneID)
        do {
            _ = try await configuration.privateDatabase.save(zone)
            logger.info("Record zone created or already exists: \(SyncConfiguration.zoneName)")
        } catch let error as CKError where error.code == .serverRejectedRequest {
            // Zone already exists -- this is fine
            logger.debug("Record zone already exists")
        } catch {
            logger.error("Failed to create record zone: \(error.localizedDescription)")
        }
    }
}

// MARK: - CKSyncEngineDelegate

extension SyncEngine: CKSyncEngineDelegate {

    nonisolated func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) {
        Task { @MainActor in
            await handleEventOnMainActor(event, syncEngine: syncEngine)
        }
    }

    private func handleEventOnMainActor(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {

        case .stateUpdate(let stateUpdate):
            saveState(stateUpdate.stateSerialization)

        case .accountChange(let accountChange):
            handleAccountChange(accountChange)

        case .fetchedDatabaseChanges(let fetchedChanges):
            handleFetchedDatabaseChanges(fetchedChanges)

        case .fetchedRecordZoneChanges(let fetchedChanges):
            await handleFetchedRecordZoneChanges(fetchedChanges)

        case .sentRecordZoneChanges(let sentChanges):
            handleSentRecordZoneChanges(sentChanges)

        case .sentDatabaseChanges(let sentChanges):
            handleSentDatabaseChanges(sentChanges)

        case .willFetchChanges:
            isSyncing = true

        case .didFetchChanges:
            isSyncing = false
            lastSyncDate = Date()

        case .willSendChanges:
            isSyncing = true

        case .didSendChanges:
            isSyncing = false
            lastSyncDate = Date()

        case .willFetchRecordZoneChanges:
            break

        case .didFetchRecordZoneChanges:
            break

        @unknown default:
            logger.warning("Unhandled CKSyncEngine event: \(String(describing: event))")
        }
    }

    nonisolated func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        await nextRecordZoneChangeBatchOnMainActor(context, syncEngine: syncEngine)
    }

    @MainActor
    private func nextRecordZoneChangeBatchOnMainActor(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {

        let pendingChanges = syncEngine.state.pendingRecordZoneChanges

        // Build the batch from pending changes
        let batch = await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pendingChanges) { recordID in
            // Convert local model to CKRecord for saving
            if self.pendingSaves.contains(recordID) {
                return self.recordMapper.record(for: recordID, zoneID: SyncConfiguration.zoneID)
            }
            return nil
        }

        return batch
    }

    // MARK: - Event Handlers

    private func handleAccountChange(_ event: CKSyncEngine.Event.AccountChange) {
        switch event.changeType {
        case .signIn:
            logger.info("User signed into iCloud")
            Task { await createZoneIfNeeded() }

        case .signOut:
            logger.info("User signed out of iCloud")
            lastError = CloudSyncError.accountUnavailable

        case .switchAccounts:
            logger.info("iCloud account switched")
            // Clear local cache and re-sync
            pendingSaves.removeAll()
            pendingDeletions.removeAll()

        @unknown default:
            break
        }
    }

    private func handleFetchedDatabaseChanges(_ event: CKSyncEngine.Event.FetchedDatabaseChanges) {
        for modification in event.modifications {
            logger.debug("Zone modified: \(modification.zoneID.zoneName)")
        }
        for deletion in event.deletions {
            logger.debug("Zone deleted: \(deletion.zoneID.zoneName)")
        }
    }

    private func handleFetchedRecordZoneChanges(_ event: CKSyncEngine.Event.FetchedRecordZoneChanges) async {
        // Handle fetched record modifications
        for modification in event.modifications {
            let record = modification.record
            logger.debug("Fetched record: \(record.recordType) / \(record.recordID.recordName)")

            // Convert CKRecord to local model and persist
            do {
                try recordMapper.applyFetchedRecord(record)
            } catch {
                logger.error("Failed to apply fetched record: \(error.localizedDescription)")
            }
        }

        // Handle fetched record deletions
        for deletion in event.deletions {
            let recordID = deletion.recordID
            logger.debug("Record deleted remotely: \(recordID.recordName)")

            do {
                try recordMapper.applyFetchedDeletion(recordID)
            } catch {
                logger.error("Failed to apply fetched deletion: \(error.localizedDescription)")
            }
        }
    }

    private func handleSentRecordZoneChanges(_ event: CKSyncEngine.Event.SentRecordZoneChanges) {
        // Handle successfully saved records
        for savedRecord in event.savedRecords {
            let recordID = savedRecord.recordID
            pendingSaves.remove(recordID)
            logger.debug("Record saved to CloudKit: \(recordID.recordName)")

            // Update local model with server record's system fields
            // (change tag, modification date, etc.)
            try? recordMapper.updateSystemFields(from: savedRecord)
        }

        // Handle successfully deleted records
        for deletedRecordID in event.deletedRecordIDs {
            pendingDeletions.remove(deletedRecordID)
            logger.debug("Record deleted from CloudKit: \(deletedRecordID.recordName)")
        }

        // Handle failures
        for failedSave in event.failedRecordSaves {
            let recordID = failedSave.record.recordID
            let error = failedSave.error

            logger.error("Failed to save record \(recordID.recordName): \(error.localizedDescription)")

            handleRecordSaveError(error, recordID: recordID, serverRecord: failedSave.record)
        }
    }

    private func handleSentDatabaseChanges(_ event: CKSyncEngine.Event.SentDatabaseChanges) {
        for failedZoneSave in event.failedZoneSaves {
            logger.error("Failed to save zone: \(failedZoneSave.error.localizedDescription)")
        }
    }

    // MARK: - Error Handling

    private func handleRecordSaveError(_ error: CKError, recordID: CKRecord.ID, serverRecord: CKRecord) {
        switch error.code {

        case .serverRecordChanged:
            // Conflict -- the server has a newer version
            if let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
                let resolved = configuration.conflictResolver.resolve(
                    server: serverRecord,
                    client: recordMapper.record(for: recordID, zoneID: SyncConfiguration.zoneID)
                )
                if let resolved {
                    // Re-queue the resolved record
                    try? recordMapper.cacheResolvedRecord(resolved)
                    addPendingSave(recordID)
                }
            }

        case .zoneNotFound:
            // Zone was deleted -- recreate it
            Task { await createZoneIfNeeded() }

        case .unknownItem:
            // Record does not exist on server -- treat as new save
            pendingSaves.remove(recordID)
            addPendingSave(recordID)

        case .networkUnavailable, .networkFailure:
            // Leave in pending -- CKSyncEngine will retry automatically
            lastError = .networkUnavailable

        case .requestRateLimited:
            // CKSyncEngine handles backoff automatically
            if let retryAfter = error.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
                logger.warning("Rate limited. Retry after \(retryAfter)s")
            }

        case .quotaExceeded:
            lastError = .quotaExceeded
            logger.error("CloudKit quota exceeded")

        case .notAuthenticated:
            lastError = .accountUnavailable

        default:
            lastError = .syncFailed(error)
            logger.error("Unhandled CKError: \(error.code.rawValue) - \(error.localizedDescription)")
        }
    }
}
```

## RecordMapping

Converts between local models and `CKRecord` objects. Customize this for your model types.

```swift
import CloudKit

/// Maps between local models and CKRecord objects.
///
/// Customize this class for your specific model types.
/// Each model type corresponds to a CKRecord record type.
final class RecordMapping {

    // MARK: - Record Type Constants

    enum RecordType {
        static let item = "Item"
        // Add more record types as needed:
        // static let project = "Project"
    }

    // MARK: - Field Constants

    /// CKRecord field keys for the Item type.
    enum ItemFields {
        static let title = "title"
        static let content = "content"
        static let createdAt = "createdAt"
        static let modifiedAt = "modifiedAt"
        static let isCompleted = "isCompleted"
    }

    // MARK: - Local Cache

    /// In-memory cache of records pending save.
    /// Replace this with your actual persistence layer (SwiftData, Core Data, etc.).
    private var localRecordCache: [CKRecord.ID: CKRecord] = [:]

    // MARK: - Model -> CKRecord

    /// Build a CKRecord for a given record ID.
    /// In production, fetch the local model by ID and map its fields.
    func record(for recordID: CKRecord.ID, zoneID: CKRecordZone.ID) -> CKRecord? {
        // Return cached record if available (e.g., after conflict resolution)
        if let cached = localRecordCache[recordID] {
            return cached
        }

        // TODO: Replace with your persistence layer lookup.
        // Example for a hypothetical Item model:
        //
        // guard let item = localStore.fetchItem(id: recordID.recordName) else {
        //     return nil
        // }
        // return mapItemToRecord(item, recordID: recordID, zoneID: zoneID)

        return nil
    }

    /// Convert a local Item model to a CKRecord.
    ///
    /// Example -- replace `ItemModel` with your actual model type:
    /// ```swift
    /// func mapItemToRecord(_ item: ItemModel, recordID: CKRecord.ID, zoneID: CKRecordZone.ID) -> CKRecord {
    ///     let record = CKRecord(recordType: RecordType.item, recordID: recordID)
    ///     record[ItemFields.title] = item.title as CKRecordValue
    ///     record[ItemFields.content] = item.content as CKRecordValue
    ///     record[ItemFields.createdAt] = item.createdAt as CKRecordValue
    ///     record[ItemFields.modifiedAt] = item.modifiedAt as CKRecordValue
    ///     record[ItemFields.isCompleted] = (item.isCompleted ? 1 : 0) as CKRecordValue
    ///     return record
    /// }
    /// ```

    // MARK: - CKRecord -> Model

    /// Apply a fetched CKRecord to the local persistence layer.
    func applyFetchedRecord(_ record: CKRecord) throws {
        let recordType = record.recordType
        let recordID = record.recordID

        switch recordType {
        case RecordType.item:
            try applyFetchedItem(record)

        default:
            throw CloudSyncError.unknownRecordType(recordType)
        }
    }

    /// Convert a CKRecord into a local Item and persist it.
    private func applyFetchedItem(_ record: CKRecord) throws {
        let id = record.recordID.recordName
        let title = record[ItemFields.title] as? String ?? ""
        let content = record[ItemFields.content] as? String ?? ""
        let createdAt = record[ItemFields.createdAt] as? Date ?? Date()
        let modifiedAt = record[ItemFields.modifiedAt] as? Date ?? Date()
        let isCompleted = (record[ItemFields.isCompleted] as? Int64 ?? 0) == 1

        // TODO: Replace with your persistence layer save.
        // Example:
        // if let existing = localStore.fetchItem(id: id) {
        //     existing.title = title
        //     existing.content = content
        //     existing.modifiedAt = modifiedAt
        //     existing.isCompleted = isCompleted
        //     try localStore.save()
        // } else {
        //     let newItem = ItemModel(id: id, title: title, content: content,
        //                             createdAt: createdAt, modifiedAt: modifiedAt,
        //                             isCompleted: isCompleted)
        //     try localStore.insert(newItem)
        // }
    }

    // MARK: - Deletions

    /// Apply a fetched record deletion to the local persistence layer.
    func applyFetchedDeletion(_ recordID: CKRecord.ID) throws {
        let id = recordID.recordName
        localRecordCache.removeValue(forKey: recordID)

        // TODO: Replace with your persistence layer deletion.
        // Example:
        // if let item = localStore.fetchItem(id: id) {
        //     try localStore.delete(item)
        // }
    }

    // MARK: - System Fields

    /// Update local model with server-assigned system fields after a successful save.
    func updateSystemFields(from record: CKRecord) throws {
        localRecordCache.removeValue(forKey: record.recordID)

        // TODO: Store the encoded system fields for future saves.
        // This preserves the change tag so CloudKit can detect conflicts.
        //
        // let data = NSMutableData()
        // let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        // record.encodeSystemFields(with: archiver)
        // archiver.finishEncoding()
        // localStore.saveSystemFields(archiver.encodedData, for: record.recordID.recordName)
    }

    // MARK: - Conflict Resolution Cache

    /// Temporarily cache a resolved record so it can be re-sent.
    func cacheResolvedRecord(_ record: CKRecord) throws {
        localRecordCache[record.recordID] = record
    }
}
```

## ConflictResolver

Pluggable conflict resolution strategies for when the server and client records diverge.

```swift
import CloudKit

/// Resolves conflicts between server and client versions of a record.
final class ConflictResolver {

    /// Available conflict resolution strategies.
    enum Strategy {
        /// Always accept the server version. Simplest approach.
        case serverWins

        /// Always push the client version. Use with caution.
        case clientWins

        /// Compare modification timestamps; most recent version wins.
        case timestampMerge

        /// Custom merge function for field-level resolution.
        case custom((CKRecord, CKRecord?) -> CKRecord)
    }

    let strategy: Strategy

    init(strategy: Strategy) {
        self.strategy = strategy
    }

    /// Resolve a conflict between the server record and the client record.
    ///
    /// - Parameters:
    ///   - server: The server's version of the record (from CKError.serverRecordChanged).
    ///   - client: The client's version of the record (may be nil if not found locally).
    /// - Returns: The resolved record to save, or nil to accept the server version as-is.
    func resolve(server: CKRecord, client: CKRecord?) -> CKRecord? {
        switch strategy {
        case .serverWins:
            return resolveServerWins(server: server)

        case .clientWins:
            return resolveClientWins(server: server, client: client)

        case .timestampMerge:
            return resolveTimestampMerge(server: server, client: client)

        case .custom(let merger):
            return merger(server, client)
        }
    }

    // MARK: - Strategy Implementations

    /// Server-wins: accept the server record. No re-save needed.
    private func resolveServerWins(server: CKRecord) -> CKRecord? {
        // Return nil to indicate "accept server version, do not re-save"
        return nil
    }

    /// Client-wins: apply client field values onto the server record (preserving server system fields).
    private func resolveClientWins(server: CKRecord, client: CKRecord?) -> CKRecord? {
        guard let client else { return nil }

        // Copy client field values onto the server record.
        // The server record has the correct change tag for the next save.
        for key in client.allKeys() {
            server[key] = client[key]
        }
        return server
    }

    /// Timestamp merge: the record with the most recent modification date wins.
    private func resolveTimestampMerge(server: CKRecord, client: CKRecord?) -> CKRecord? {
        guard let client else { return nil }

        let serverDate = server.modificationDate ?? .distantPast
        let clientDate = client.modificationDate ?? .distantPast

        if clientDate > serverDate {
            // Client is newer -- apply client values onto server record
            for key in client.allKeys() {
                server[key] = client[key]
            }
            return server
        } else {
            // Server is newer or equal -- accept server version
            return nil
        }
    }
}
```

## SyncMonitor

Observes iCloud account status and exposes sync state for UI.

```swift
import CloudKit
import os.log

/// Monitors iCloud account status and sync health.
@Observable
@MainActor
final class SyncMonitor {

    // MARK: - Observable State

    private(set) var accountAvailable = false
    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    private(set) var isSyncing = false
    private(set) var lastSyncDate: Date?
    private(set) var lastError: CloudSyncError?

    // MARK: - Private

    private let container: CKContainer
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CloudSync", category: "SyncMonitor")

    // MARK: - Initialization

    init(containerIdentifier: String = "iCloud.com.yourcompany.yourapp") {
        self.container = CKContainer(identifier: containerIdentifier)

        // Observe account changes
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshAccountStatus()
            }
        }
    }

    // MARK: - Account Status

    /// Check the current iCloud account status.
    func refreshAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            await handleAccountStatus(status)
        } catch {
            logger.error("Failed to check account status: \(error.localizedDescription)")
            lastError = .accountCheckFailed(error)
            accountAvailable = false
        }
    }

    /// Handle an account status result.
    func handleAccountStatus(_ status: CKAccountStatus) async {
        accountStatus = status

        switch status {
        case .available:
            accountAvailable = true
            lastError = nil
            logger.info("iCloud account available")

        case .noAccount:
            accountAvailable = false
            lastError = .accountUnavailable
            logger.warning("No iCloud account")

        case .restricted:
            accountAvailable = false
            lastError = .accountRestricted
            logger.warning("iCloud account restricted")

        case .couldNotDetermine:
            accountAvailable = false
            lastError = .accountCheckFailed(nil)
            logger.warning("Could not determine iCloud account status")

        case .temporarilyUnavailable:
            accountAvailable = false
            lastError = .accountTemporarilyUnavailable
            logger.warning("iCloud account temporarily unavailable")

        @unknown default:
            accountAvailable = false
            logger.warning("Unknown iCloud account status: \(String(describing: status))")
        }
    }

    // MARK: - Sync State Updates

    /// Call this from SyncEngine when sync activity changes.
    func updateSyncState(isSyncing: Bool) {
        self.isSyncing = isSyncing
        if !isSyncing {
            lastSyncDate = Date()
        }
    }

    /// Call this from SyncEngine when a sync error occurs.
    func reportError(_ error: CloudSyncError) {
        lastError = error
    }

    /// Clear the last error (e.g., after user acknowledges it).
    func clearError() {
        lastError = nil
    }
}
```

## CloudSyncError

Typed errors with CKError code mapping.

```swift
import CloudKit

/// Typed errors for CloudKit sync operations.
enum CloudSyncError: Error, LocalizedError {
    /// No iCloud account signed in on device.
    case accountUnavailable

    /// iCloud account restricted by parental controls or MDM.
    case accountRestricted

    /// iCloud account temporarily unavailable. Retry later.
    case accountTemporarilyUnavailable

    /// Failed to check account status.
    case accountCheckFailed(Error?)

    /// Network is unavailable.
    case networkUnavailable

    /// CloudKit storage quota exceeded.
    case quotaExceeded

    /// Record zone not found on server.
    case zoneNotFound

    /// Server rejected the record (conflict).
    case serverRecordChanged(serverRecord: CKRecord)

    /// Unknown CKRecord type fetched.
    case unknownRecordType(String)

    /// Generic sync failure wrapping a CKError.
    case syncFailed(CKError)

    /// Generic failure wrapping any error.
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .accountUnavailable:
            return "iCloud account not available. Sign in to iCloud in Settings to enable sync."
        case .accountRestricted:
            return "iCloud access is restricted on this device."
        case .accountTemporarilyUnavailable:
            return "iCloud is temporarily unavailable. Sync will resume automatically."
        case .accountCheckFailed(let error):
            return "Could not check iCloud status: \(error?.localizedDescription ?? "unknown error")"
        case .networkUnavailable:
            return "Network unavailable. Changes will sync when connectivity is restored."
        case .quotaExceeded:
            return "iCloud storage is full. Free up space to continue syncing."
        case .zoneNotFound:
            return "Sync zone not found. It will be recreated automatically."
        case .serverRecordChanged:
            return "A newer version exists on the server. The conflict has been resolved."
        case .unknownRecordType(let type):
            return "Unknown record type received: \(type)"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .underlying(let error):
            return "Sync error: \(error.localizedDescription)"
        }
    }

    // MARK: - CKError Mapping

    /// Create a CloudSyncError from a CKError.
    static func from(_ error: CKError) -> CloudSyncError {
        switch error.code {
        case .notAuthenticated:
            return .accountUnavailable
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .quotaExceeded:
            return .quotaExceeded
        case .zoneNotFound:
            return .zoneNotFound
        case .serverRecordChanged:
            if let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
                return .serverRecordChanged(serverRecord: serverRecord)
            }
            return .syncFailed(error)
        case .requestRateLimited:
            // CKSyncEngine handles retry automatically
            return .syncFailed(error)
        default:
            return .syncFailed(error)
        }
    }
}
```

## ShareManager (Optional -- Sharing)

Manages CKShare creation and participant management for collaborative features.

```swift
import CloudKit
import SwiftUI

/// Manages CloudKit sharing (CKShare) for record collaboration.
@Observable
@MainActor
final class ShareManager {

    // MARK: - Properties

    private let container: CKContainer
    private let database: CKDatabase
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CloudSync", category: "ShareManager")

    private(set) var activeShares: [CKRecord.ID: CKShare] = [:]

    // MARK: - Initialization

    init(configuration: SyncConfiguration) {
        self.container = configuration.container
        self.database = configuration.privateDatabase
    }

    // MARK: - Create Share

    /// Create a CKShare for a record, enabling collaboration.
    ///
    /// - Parameters:
    ///   - recordID: The record to share.
    ///   - title: Display title for the share invitation.
    ///   - permission: Default permission for new participants.
    /// - Returns: The created CKShare.
    func createShare(
        for recordID: CKRecord.ID,
        title: String,
        permission: CKShare.ParticipantPermission = .readWrite
    ) async throws -> CKShare {

        // Fetch the record to share
        let record = try await database.record(for: recordID)

        // Create the share
        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = title as CKRecordValue
        share.publicPermission = .none // Require explicit invitation

        // Save both the share and the root record
        let modifyOperation = CKModifyRecordsOperation(
            recordsToSave: [share, record],
            recordIDsToDelete: nil
        )
        modifyOperation.qualityOfService = .userInitiated

        try await database.modifyRecords(saving: [share, record], deleting: [])

        activeShares[recordID] = share
        logger.info("Created share for record: \(recordID.recordName)")

        return share
    }

    // MARK: - Fetch Existing Share

    /// Fetch an existing share for a record.
    func fetchShare(for recordID: CKRecord.ID) async throws -> CKShare? {
        let record = try await database.record(for: recordID)

        guard let shareReference = record.share else {
            return nil
        }

        let share = try await database.record(for: shareReference.recordID) as? CKShare
        if let share {
            activeShares[recordID] = share
        }
        return share
    }

    // MARK: - Add Participant

    /// Look up and add a participant by email address.
    func addParticipant(
        email: String,
        to share: CKShare,
        permission: CKShare.ParticipantPermission = .readWrite
    ) async throws {

        let lookupInfo = CKUserIdentity.LookupInfo(emailAddress: email)
        let participants = try await container.shareParticipants(matching: [lookupInfo])

        guard let participant = participants.first else {
            throw CloudSyncError.underlying(
                NSError(domain: "ShareManager", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "No iCloud user found for \(email)"])
            )
        }

        participant.permission = permission
        participant.role = .privateUser
        share.addParticipant(participant)

        // Save the updated share
        try await database.modifyRecords(saving: [share], deleting: [])
        logger.info("Added participant \(email) to share")
    }

    // MARK: - Remove Participant

    /// Remove a participant from a share.
    func removeParticipant(_ participant: CKShare.Participant, from share: CKShare) async throws {
        share.removeParticipant(participant)
        try await database.modifyRecords(saving: [share], deleting: [])
        logger.info("Removed participant from share")
    }

    // MARK: - Delete Share

    /// Stop sharing a record.
    func deleteShare(for recordID: CKRecord.ID) async throws {
        guard let share = activeShares[recordID] else {
            throw CloudSyncError.underlying(
                NSError(domain: "ShareManager", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "No active share for this record"])
            )
        }

        try await database.modifyRecords(saving: [], deleting: [share.recordID])
        activeShares.removeValue(forKey: recordID)
        logger.info("Deleted share for record: \(recordID.recordName)")
    }

    // MARK: - Accept Share

    /// Accept a share invitation (called from the share URL handler).
    func acceptShare(_ metadata: CKShare.Metadata) async throws {
        try await container.accept(metadata)
        logger.info("Accepted share invitation")
    }
}
```

## ShareParticipantView (Optional -- Sharing UI)

SwiftUI wrapper for the system sharing UI.

### iOS (UICloudSharingController)

```swift
import SwiftUI
import CloudKit

/// SwiftUI wrapper for UICloudSharingController (iOS).
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowReadOnly]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            // Handle error
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "Shared Item"
        }
    }
}
```

### macOS (NSSharingServicePicker)

```swift
import SwiftUI
import CloudKit

/// SwiftUI wrapper for CloudKit sharing on macOS.
struct CloudSharingViewMac: NSViewRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    /// Present sharing UI from a button action.
    static func presentSharing(
        share: CKShare,
        container: CKContainer,
        from view: NSView
    ) {
        let sharingService = NSSharingService(named: .cloudSharing)
        let items: [Any] = [share]

        let picker = NSSharingServicePicker(items: items)
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }
}
```

## System Fields Encoding Helper

Utility for encoding and decoding CKRecord system fields, which is essential for preserving change tags across save operations.

```swift
import CloudKit

/// Encodes and decodes CKRecord system fields for local persistence.
///
/// System fields include the record's change tag, creation date,
/// and modification date. Preserving these is required for CloudKit
/// to detect conflicts on subsequent saves.
enum RecordSystemFieldsEncoder {

    /// Encode a CKRecord's system fields to Data for local storage.
    static func encode(_ record: CKRecord) -> Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: archiver)
        archiver.finishEncoding()
        return archiver.encodedData
    }

    /// Decode system fields from Data and create a CKRecord with those fields.
    ///
    /// Use this when preparing a record for re-save: it restores the change tag
    /// so CloudKit can detect whether the record has been modified on the server
    /// since the last fetch.
    static func decode(_ data: Data) -> CKRecord? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else {
            return nil
        }
        unarchiver.requiresSecureCoding = true
        let record = CKRecord(coder: unarchiver)
        unarchiver.finishDecoding()
        return record
    }
}
```

## Anti-Patterns to Avoid

### Do Not Use CKOperation Chains Directly

```swift
// ❌ Wrong -- old pattern, replaced by CKSyncEngine
let fetchOperation = CKFetchRecordZoneChangesOperation(...)
let modifyOperation = CKModifyRecordsOperation(...)
fetchOperation.addDependency(modifyOperation)
database.add(fetchOperation)
database.add(modifyOperation)

// ✅ Right -- use CKSyncEngine
let engine = CKSyncEngine(config)
engine.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
// CKSyncEngine handles fetch/send scheduling automatically
```

### Do Not Ignore System Fields

```swift
// ❌ Wrong -- creates a new record without preserving change tag
let record = CKRecord(recordType: "Item", recordID: recordID)
record["title"] = "Updated"
// This will always conflict with the server version

// ✅ Right -- restore system fields from last fetch
let record = RecordSystemFieldsEncoder.decode(savedSystemFieldsData)!
record["title"] = "Updated"
// Change tag matches server, so CloudKit detects real conflicts only
```

### Do Not Poll for Changes

```swift
// ❌ Wrong -- manual polling
Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
    self.fetchChanges()
}

// ✅ Right -- CKSyncEngine handles change fetching via push notifications
// Just start the engine and it manages the schedule
```

### Do Not Block on Sync

```swift
// ❌ Wrong -- waiting for sync before showing UI
func viewDidLoad() {
    await syncEngine.syncAllData()  // Blocks UI
    loadItems()
}

// ✅ Right -- show local data immediately, sync in background
func viewDidLoad() {
    loadItems()  // Show local data immediately
    // CKSyncEngine syncs in the background and triggers updates
}
```

### Do Not Hardcode Container Identifiers in Multiple Places

```swift
// ❌ Wrong -- container ID scattered across files
let container = CKContainer(identifier: "iCloud.com.mycompany.myapp")
// ... in another file ...
let otherContainer = CKContainer(identifier: "iCloud.com.mycompany.myapp")

// ✅ Right -- single source of truth
let container = SyncConfiguration.default.container
```
