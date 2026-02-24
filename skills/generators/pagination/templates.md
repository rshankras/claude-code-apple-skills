# Pagination Code Templates

Production-ready Swift templates for pagination infrastructure. All code targets iOS 17+ / macOS 14+ and uses `@Observable`, modern Swift concurrency, and protocol-based architecture.

## PaginatedResponse.swift

```swift
import Foundation

// MARK: - Offset-Based Response

/// Generic response model for offset-based paginated APIs.
struct OffsetPaginatedResponse<Item: Decodable & Sendable>: Decodable, Sendable {
    let items: [Item]
    let totalItems: Int
    let totalPages: Int
    let currentPage: Int
    let pageSize: Int

    var hasMore: Bool {
        currentPage < totalPages
    }
}

// MARK: - Cursor-Based Response

/// Generic response model for cursor-based paginated APIs.
struct CursorPaginatedResponse<Item: Decodable & Sendable>: Decodable, Sendable {
    let items: [Item]
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

// MARK: - Unified Page Request

/// Represents a request for a page of data.
/// Works for both offset and cursor patterns.
struct PageRequest: Sendable {
    let page: Int
    let size: Int
    let cursor: String?

    /// Create an offset-based page request.
    static func offset(page: Int, size: Int) -> PageRequest {
        PageRequest(page: page, size: size, cursor: nil)
    }

    /// Create a cursor-based page request.
    static func cursor(_ cursor: String?, size: Int) -> PageRequest {
        PageRequest(page: 0, size: size, cursor: cursor)
    }

    /// The first page request.
    static func first(size: Int) -> PageRequest {
        PageRequest(page: 1, size: size, cursor: nil)
    }
}
```

## PaginationState.swift

```swift
import Foundation

/// Represents the current state of pagination.
///
/// Use this enum to drive UI decisions: show spinners, empty states, error views, etc.
enum PaginationState: Equatable, Sendable {
    /// Initial state, no data loaded yet.
    case idle

    /// Loading the first page. Show full-screen spinner.
    case loading

    /// Loading a subsequent page. Show items with bottom spinner.
    case loadingMore

    /// Data loaded successfully. More pages may be available.
    case loaded

    /// An error occurred. Message is displayable to user.
    case error(String)

    /// All pages have been loaded. No more data available.
    case exhausted

    /// Whether a loading operation is in progress.
    var isLoading: Bool {
        self == .loading || self == .loadingMore
    }

    /// Whether items should be visible (loaded, loadingMore, error on subsequent page, exhausted).
    var showItems: Bool {
        switch self {
        case .loaded, .loadingMore, .exhausted: return true
        case .error: return true  // Keep items visible on error
        default: return false
        }
    }
}
```

## PaginatedDataSource.swift

```swift
import Foundation

/// Protocol for paginated data sources.
///
/// Conform to this protocol for each paginated endpoint in your app.
/// The pagination manager calls `fetch` to load pages.
///
/// Example:
/// ```swift
/// struct UsersDataSource: PaginatedDataSource {
///     typealias Item = User
///     let apiClient: APIClient
///
///     func fetch(request: PageRequest) async throws -> PageResult<User> {
///         let response = try await apiClient.request(
///             UsersEndpoint(page: request.page, size: request.size)
///         )
///         return PageResult(
///             items: response.items,
///             hasMore: response.hasMore,
///             nextCursor: nil
///         )
///     }
/// }
/// ```
protocol PaginatedDataSource: Sendable {
    associatedtype Item: Identifiable & Sendable

    /// Fetch a page of items.
    func fetch(request: PageRequest) async throws -> PageResult<Item>
}

/// Searchable variant that accepts a query string.
protocol SearchablePaginatedDataSource: PaginatedDataSource {
    /// Fetch a page of items matching the query.
    func fetch(request: PageRequest, query: String) async throws -> PageResult<Item>
}

/// Result of a single page fetch, unified across offset and cursor patterns.
struct PageResult<Item: Sendable>: Sendable {
    let items: [Item]
    let hasMore: Bool
    let nextCursor: String?
    let totalItems: Int?

    init(items: [Item], hasMore: Bool, nextCursor: String? = nil, totalItems: Int? = nil) {
        self.items = items
        self.hasMore = hasMore
        self.nextCursor = nextCursor
        self.totalItems = totalItems
    }
}
```

## PaginationManager.swift

```swift
import Foundation
import SwiftUI

/// Manages paginated data loading with state machine transitions.
///
/// Generic over any `PaginatedDataSource`. Handles:
/// - First page loading
/// - Subsequent page loading (append)
/// - Refresh (reset and reload)
/// - Error handling with retry
/// - Threshold-based prefetching
@Observable
final class PaginationManager<Source: PaginatedDataSource>: @unchecked Sendable {
    // MARK: - Public State

    /// The accumulated items across all loaded pages.
    private(set) var items: [Source.Item] = []

    /// Current pagination state.
    private(set) var state: PaginationState = .idle

    /// Whether more pages are available.
    private(set) var hasMore: Bool = true

    /// Total item count from server (offset-based only).
    private(set) var totalItems: Int?

    // MARK: - Configuration

    /// Number of items per page.
    let pageSize: Int

    /// Number of items from the bottom to trigger prefetch.
    let prefetchThreshold: Int

    // MARK: - Private

    private let dataSource: Source
    private var currentPage: Int = 0
    private var nextCursor: String?
    private var currentTask: Task<Void, Never>?

    init(dataSource: Source, pageSize: Int = 20, prefetchThreshold: Int = 5) {
        self.dataSource = dataSource
        self.pageSize = pageSize
        self.prefetchThreshold = prefetchThreshold
    }

    // MARK: - Public API

    /// Load the first page of data. Resets any existing state.
    func loadFirstPage() async {
        guard state != .loading else { return }

        currentTask?.cancel()
        items.removeAll()
        currentPage = 0
        nextCursor = nil
        hasMore = true
        state = .loading

        await loadPage()
    }

    /// Load the next page. No-op if already loading or exhausted.
    func loadNextPage() async {
        guard state == .loaded, hasMore else { return }

        state = .loadingMore
        await loadPage()
    }

    /// Refresh: reset everything and reload from the first page.
    func refresh() async {
        state = .idle
        await loadFirstPage()
    }

    /// Call from `onAppear` of list items to trigger prefetch.
    func onItemAppear(_ item: Source.Item) {
        guard state == .loaded, hasMore else { return }

        guard let index = items.firstIndex(where: { $0.id == item.id }),
              index >= items.count - prefetchThreshold else {
            return
        }

        Task { await loadNextPage() }
    }

    /// Retry after an error.
    func retry() async {
        if items.isEmpty {
            await loadFirstPage()
        } else {
            state = .loaded
            await loadNextPage()
        }
    }

    /// Reset to idle state with no items.
    func reset() {
        currentTask?.cancel()
        items.removeAll()
        currentPage = 0
        nextCursor = nil
        hasMore = true
        state = .idle
    }

    // MARK: - Private

    private func loadPage() async {
        currentTask?.cancel()

        let task = Task { [currentPage, nextCursor, pageSize] in
            do {
                let request: PageRequest
                if let cursor = nextCursor {
                    request = .cursor(cursor, size: pageSize)
                } else {
                    request = .offset(page: currentPage + 1, size: pageSize)
                }

                let result = try await dataSource.fetch(request: request)

                try Task.checkCancellation()

                items.append(contentsOf: result.items)
                self.currentPage += 1
                self.nextCursor = result.nextCursor
                self.hasMore = result.hasMore
                self.totalItems = result.totalItems
                self.state = result.hasMore ? .loaded : .exhausted
            } catch is CancellationError {
                // Ignore cancellation
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }

        currentTask = task
        await task.value
    }
}
```

## SearchablePaginationManager.swift

```swift
import Foundation

/// Adds debounced search to pagination.
///
/// Wraps a `PaginationManager` and resets pagination when the search query changes.
/// Debounces keystrokes to avoid excessive API calls.
@Observable
final class SearchablePaginationManager<Source: SearchablePaginatedDataSource> {
    /// The current search query. Setting this debounces and triggers a new search.
    var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            debounceAndSearch()
        }
    }

    /// The underlying pagination manager.
    let pagination: PaginationManager<SearchDataSourceAdapter<Source>>

    /// Debounce interval in milliseconds.
    let debounceMilliseconds: Int

    private var debounceTask: Task<Void, Never>?
    private let adapter: SearchDataSourceAdapter<Source>

    init(dataSource: Source, pageSize: Int = 20, debounceMilliseconds: Int = 300) {
        self.adapter = SearchDataSourceAdapter(source: dataSource)
        self.pagination = PaginationManager(dataSource: adapter, pageSize: pageSize)
        self.debounceMilliseconds = debounceMilliseconds
    }

    /// Clear search and reload without query.
    func clearSearch() {
        query = ""
        adapter.currentQuery = ""
        Task { await pagination.refresh() }
    }

    private func debounceAndSearch() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(debounceMilliseconds))
            guard !Task.isCancelled else { return }
            adapter.currentQuery = query
            await pagination.refresh()
        }
    }
}

/// Adapts a `SearchablePaginatedDataSource` to a regular `PaginatedDataSource`
/// by injecting the current query into fetch calls.
final class SearchDataSourceAdapter<Source: SearchablePaginatedDataSource>: PaginatedDataSource, @unchecked Sendable {
    typealias Item = Source.Item

    var currentQuery: String = ""
    private let source: Source

    init(source: Source) {
        self.source = source
    }

    func fetch(request: PageRequest) async throws -> PageResult<Source.Item> {
        try await source.fetch(request: request, query: currentQuery)
    }
}
```

## Views/PaginatedList.swift

```swift
import SwiftUI

/// A SwiftUI List with built-in pagination support.
///
/// Automatically loads the next page when the user scrolls near the bottom.
/// Shows appropriate states for loading, empty, error, and exhausted.
///
/// Usage:
/// ```swift
/// PaginatedList(manager: viewModel.pagination) { user in
///     UserRow(user: user)
/// }
/// ```
struct PaginatedList<Source: PaginatedDataSource, RowContent: View>: View {
    let manager: PaginationManager<Source>
    let rowContent: (Source.Item) -> RowContent

    init(
        manager: PaginationManager<Source>,
        @ViewBuilder rowContent: @escaping (Source.Item) -> RowContent
    ) {
        self.manager = manager
        self.rowContent = rowContent
    }

    var body: some View {
        Group {
            switch manager.state {
            case .idle:
                Color.clear

            case .loading:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .error(let message) where manager.items.isEmpty:
                PaginationErrorView(message: message) {
                    Task { await manager.retry() }
                }

            default:
                listContent
            }
        }
        .refreshable {
            await manager.refresh()
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if manager.items.isEmpty && manager.state == .loaded {
            ContentUnavailableView(
                "No Results",
                systemImage: "tray",
                description: Text("Nothing to show")
            )
        } else {
            List {
                ForEach(manager.items) { item in
                    rowContent(item)
                        .onAppear { manager.onItemAppear(item) }
                }

                footerView
            }
        }
    }

    @ViewBuilder
    private var footerView: some View {
        switch manager.state {
        case .loadingMore:
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .listRowSeparator(.hidden)

        case .error(let message):
            PaginationErrorBanner(message: message) {
                Task { await manager.retry() }
            }
            .listRowSeparator(.hidden)

        case .exhausted:
            Text("No more results")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)

        default:
            EmptyView()
        }
    }
}
```

## Views/LoadMoreButton.swift

```swift
import SwiftUI

/// A manual "Load More" button for pagination.
///
/// Use instead of or alongside infinite scroll.
struct LoadMoreButton<Source: PaginatedDataSource>: View {
    let manager: PaginationManager<Source>

    var body: some View {
        if manager.hasMore && manager.state == .loaded {
            Button {
                Task { await manager.loadNextPage() }
            } label: {
                Text("Load More")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .padding()
        } else if manager.state == .loadingMore {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
}
```

## Views/PaginationStateView.swift

```swift
import SwiftUI

/// Full-screen error view with retry button.
struct PaginationErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
        }
    }
}

/// Inline error banner for errors on subsequent pages.
/// Shows at the bottom of the list, preserving loaded items.
struct PaginationErrorBanner: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

/// Skeleton loading placeholder for initial page load.
struct PaginationSkeletonView: View {
    let rowCount: Int

    init(rowCount: Int = 8) {
        self.rowCount = rowCount
    }

    var body: some View {
        List {
            ForEach(0..<rowCount, id: \.self) { _ in
                SkeletonRow()
                    .redacted(reason: .placeholder)
            }
        }
    }
}

private struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 14)
                    .frame(maxWidth: 200)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 12)
                    .frame(maxWidth: 140)
            }
        }
        .padding(.vertical, 4)
    }
}
```
