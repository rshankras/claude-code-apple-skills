import Foundation
import SwiftData

/// Generic repository protocol for data access.
///
/// Provides abstraction over SwiftData for:
/// - Testability (mock implementations)
/// - Separation of concerns
/// - Consistent data access patterns
///
/// Usage:
/// ```swift
/// let repository: any Repository<Item> = SwiftDataRepository(modelContext: context)
/// let items = try await repository.fetch(sortBy: [SortDescriptor(\.timestamp)])
/// ```
protocol Repository<T>: Sendable {
    associatedtype T: PersistentModel

    /// Fetch all items matching the predicate.
    func fetch(
        predicate: Predicate<T>?,
        sortBy: [SortDescriptor<T>]
    ) async throws -> [T]

    /// Fetch a single item matching the predicate.
    func fetchOne(predicate: Predicate<T>) async throws -> T?

    /// Count items matching the predicate.
    func count(predicate: Predicate<T>?) async throws -> Int

    /// Insert a new item.
    func insert(_ item: T) async throws

    /// Delete an item.
    func delete(_ item: T) async throws

    /// Delete all items matching the predicate.
    func deleteAll(predicate: Predicate<T>?) async throws

    /// Save pending changes.
    func save() async throws
}

// MARK: - Default Implementations

extension Repository {

    /// Fetch all items with default sorting.
    func fetch(sortBy: [SortDescriptor<T>] = []) async throws -> [T] {
        try await fetch(predicate: nil, sortBy: sortBy)
    }

    /// Fetch all items.
    func fetchAll() async throws -> [T] {
        try await fetch(predicate: nil, sortBy: [])
    }

    /// Count all items.
    func countAll() async throws -> Int {
        try await count(predicate: nil)
    }

    /// Delete all items.
    func deleteAll() async throws {
        try await deleteAll(predicate: nil)
    }
}

// MARK: - Repository Error

/// Errors that can occur during repository operations.
enum RepositoryError: Error, LocalizedError {
    case fetchFailed(Error)
    case insertFailed(Error)
    case deleteFailed(Error)
    case saveFailed(Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .insertFailed(let error):
            return "Failed to insert data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .notFound:
            return "Item not found"
        }
    }
}
