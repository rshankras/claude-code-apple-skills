---
name: pagination
description: Generates pagination infrastructure with offset or cursor-based patterns, infinite scroll, and search support. Use when user wants to add paginated lists, infinite scrolling, or load-more functionality.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Pagination Generator

Generate production pagination infrastructure supporting offset-based and cursor-based APIs, with infinite scroll SwiftUI views, state machine management, and optional search integration.

## When This Skill Activates

Use this skill when the user:
- Asks to "add pagination" or "paginate a list"
- Wants "infinite scroll" or "load more" functionality
- Mentions "cursor-based pagination" or "offset pagination"
- Asks about "paginated API" or "loading pages of data"
- Wants "search with pagination"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 17+ / macOS 14+ for @Observable)
- [ ] Search for existing pagination implementations
- [ ] Identify source file locations

### 2. Networking Layer Detection
Search for existing networking code:
```
Glob: **/*API*.swift, **/*Client*.swift, **/*Endpoint*.swift
Grep: "APIClient" or "APIEndpoint"
```

If `networking-layer` generator was used, detect the `APIEndpoint` protocol and generate data sources that conform to it.

### 3. Conflict Detection
Search for existing pagination:
```
Glob: **/*Pagina*.swift, **/*LoadMore*.swift
Grep: "PaginationState" or "loadNextPage" or "hasMorePages"
```

If found, ask user whether to replace or extend.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Pagination style?**
   - Offset-based (page number + page size) — most common for REST APIs
   - Cursor-based (opaque cursor token) — better for real-time data, social feeds

2. **Loading trigger?**
   - Infinite scroll (auto-load when near bottom) — recommended
   - Manual "Load More" button
   - Both (infinite scroll with manual fallback on error)

3. **Additional features?** (multi-select)
   - Search with pagination (debounced, resets on query change)
   - Pull-to-refresh
   - Empty/error/loading state views

4. **Data source pattern?**
   - Generic (works with any Codable model)
   - Protocol-based (define per-endpoint data sources)

## Generation Process

### Step 1: Read Templates
Read `pagination-patterns.md` for architecture guidance.
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `PaginatedResponse.swift` — Generic response models for offset and cursor
2. `PaginationState.swift` — State machine (idle, loading, loaded, error, exhausted)
3. `PaginatedDataSource.swift` — Protocol endpoints conform to
4. `PaginationManager.swift` — @Observable manager with state transitions

### Step 3: Create Optional Files
Based on configuration:
- `SearchablePaginationManager.swift` — If search selected
- `Views/PaginatedList.swift` — Infinite scroll SwiftUI wrapper
- `Views/LoadMoreButton.swift` — Manual load-more button
- `Views/PaginationStateView.swift` — Empty/loading/error state views

### Step 4: Determine File Location
Check project structure:
- If `Sources/` exists → `Sources/Pagination/`
- If `App/` exists → `App/Pagination/`
- Otherwise → `Pagination/`

## Output Format

After generation, provide:

### Files Created
```
Pagination/
├── PaginatedResponse.swift           # Generic response models
├── PaginationState.swift             # State machine enum
├── PaginatedDataSource.swift         # Data source protocol
├── PaginationManager.swift           # @Observable manager
├── SearchablePaginationManager.swift # Optional: search + pagination
└── Views/
    ├── PaginatedList.swift           # Infinite scroll wrapper
    ├── LoadMoreButton.swift          # Manual load-more
    └── PaginationStateView.swift     # Empty/loading/error states
```

### Integration Steps

**Define a data source:**
```swift
struct UsersDataSource: PaginatedDataSource {
    typealias Item = User

    let apiClient: APIClient

    func fetch(page: PageRequest) async throws -> PaginatedResponse<User> {
        try await apiClient.request(UsersEndpoint(page: page.page, size: page.size))
    }
}
```

**Use PaginationManager in a view model:**
```swift
@Observable
final class UsersViewModel {
    let pagination: PaginationManager<UsersDataSource>

    init(apiClient: APIClient) {
        pagination = PaginationManager(
            dataSource: UsersDataSource(apiClient: apiClient)
        )
    }
}
```

**With SwiftUI (infinite scroll):**
```swift
struct UsersListView: View {
    @State private var viewModel = UsersViewModel()

    var body: some View {
        PaginatedList(manager: viewModel.pagination) { user in
            UserRow(user: user)
        }
        .task {
            await viewModel.pagination.loadFirstPage()
        }
    }
}
```

**With search:**
```swift
struct SearchableUsersView: View {
    @State private var searchManager = SearchablePaginationManager(
        dataSource: UsersDataSource()
    )

    var body: some View {
        PaginatedList(manager: searchManager.pagination) { user in
            UserRow(user: user)
        }
        .searchable(text: $searchManager.query)
    }
}
```

### Testing

```swift
@Test
func loadFirstPagePopulatesItems() async throws {
    let mockSource = MockDataSource(items: User.mockList(count: 20))
    let manager = PaginationManager(dataSource: mockSource, pageSize: 10)

    await manager.loadFirstPage()

    #expect(manager.items.count == 10)
    #expect(manager.state == .loaded)
    #expect(manager.hasMore == true)
}

@Test
func loadAllPagesReachesExhausted() async throws {
    let mockSource = MockDataSource(items: User.mockList(count: 15))
    let manager = PaginationManager(dataSource: mockSource, pageSize: 10)

    await manager.loadFirstPage()
    await manager.loadNextPage()

    #expect(manager.items.count == 15)
    #expect(manager.state == .exhausted)
}
```

## References

- **pagination-patterns.md** — Offset vs cursor comparison, state machine, threshold prefetching
- **templates.md** — All production Swift templates
- Related: `generators/networking-layer` — Base networking layer for data sources
- Related: `generators/http-cache` — Cache paginated responses
