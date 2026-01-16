import Foundation
import SwiftData

/// SwiftData implementation of the Repository protocol.
///
/// Usage:
/// ```swift
/// let context = PersistenceController.shared.mainContext
/// let repository = SwiftDataRepository<Item>(modelContext: context)
///
/// // Fetch items
/// let items = try await repository.fetch(
///     predicate: #Predicate { $0.isCompleted == false },
///     sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
/// )
///
/// // Insert
/// let newItem = Item(title: "New Task")
/// try await repository.insert(newItem)
/// ```
@MainActor
final class SwiftDataRepository<T: PersistentModel>: Repository {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch

    func fetch(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) async throws -> [T] {
        let descriptor = FetchDescriptor<T>(
            predicate: predicate,
            sortBy: sortBy
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }

    func fetchOne(predicate: Predicate<T>) async throws -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }

    // MARK: - Count

    func count(predicate: Predicate<T>? = nil) async throws -> Int {
        let descriptor = FetchDescriptor<T>(predicate: predicate)

        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }

    // MARK: - Insert

    func insert(_ item: T) async throws {
        modelContext.insert(item)
        try await save()
    }

    // MARK: - Delete

    func delete(_ item: T) async throws {
        modelContext.delete(item)
        try await save()
    }

    func deleteAll(predicate: Predicate<T>? = nil) async throws {
        do {
            try modelContext.delete(model: T.self, where: predicate)
            try await save()
        } catch {
            throw RepositoryError.deleteFailed(error)
        }
    }

    // MARK: - Save

    func save() async throws {
        guard modelContext.hasChanges else { return }

        do {
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }
}

// MARK: - Pagination Support

extension SwiftDataRepository {

    /// Fetch items with pagination.
    func fetchPage(
        page: Int,
        pageSize: Int,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) async throws -> [T] {
        var descriptor = FetchDescriptor<T>(
            predicate: predicate,
            sortBy: sortBy
        )
        descriptor.fetchOffset = page * pageSize
        descriptor.fetchLimit = pageSize

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw RepositoryError.fetchFailed(error)
        }
    }
}

// MARK: - Batch Operations

extension SwiftDataRepository {

    /// Insert multiple items efficiently.
    func insertBatch(_ items: [T]) async throws {
        for item in items {
            modelContext.insert(item)
        }
        try await save()
    }

    /// Update items matching predicate using a transform.
    func updateBatch(
        predicate: Predicate<T>? = nil,
        transform: (T) -> Void
    ) async throws {
        let items = try await fetch(predicate: predicate, sortBy: [])
        for item in items {
            transform(item)
        }
        try await save()
    }
}
