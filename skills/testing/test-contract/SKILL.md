---
name: test-contract
description: Generate protocol/interface test suites that any implementation must pass. Define the contract once, test every implementation. Use when designing protocols or swapping implementations.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Test Contract

Define behavioral contracts as test suites. Any class conforming to a protocol must pass the contract tests. Ensures consistent behavior across implementations — human-written, AI-generated, or mock.

## When This Skill Activates

Use this skill when the user:
- Designs a protocol and wants to ensure conformance quality
- Has multiple implementations of the same interface (e.g., real + mock + in-memory)
- Says "test the protocol" or "contract test"
- Wants to swap implementations safely (e.g., CoreData → SwiftData)
- Wants to ensure AI-generated implementations meet the spec

## Why Contract Tests

```
Protocol: DataStore
  ├── SQLiteDataStore  → must pass contract tests
  ├── InMemoryDataStore → must pass contract tests
  ├── MockDataStore    → must pass contract tests
  └── CloudDataStore   → must pass contract tests
```

Write the contract once. Every implementation proves it works by passing the same tests.

## Process

### Phase 1: Identify the Protocol

```
Grep: "protocol.*\\{" to find protocols
Read: protocol definition
```

Understand:
- [ ] All required methods and properties
- [ ] Expected behavior for each method
- [ ] Error conditions and edge cases
- [ ] Thread safety requirements
- [ ] State invariants (e.g., count matches items.count)

### Phase 2: Define Contract Behaviors

For each protocol method, define required behaviors:

```markdown
## DataStore Contract

### save(_ item:)
- Saving a new item increases count by 1
- Saving an existing item (same ID) updates it, count unchanged
- Saved item is retrievable by ID
- Throws on invalid item (empty title)

### fetch(id:)
- Returns item when it exists
- Returns nil when item doesn't exist
- Returns most recently saved version

### delete(id:)
- Deleting existing item decreases count by 1
- Deleting non-existent item does nothing (no throw)
- Deleted item is no longer fetchable

### fetchAll()
- Returns all saved items
- Returns empty array when store is empty
- Items are in consistent order (insertion or specified)

### Invariants
- count == fetchAll().count (always)
- save then fetch returns same item
- delete then fetch returns nil
```

### Phase 3: Generate Contract Test Suite

#### Pattern: Generic Test Suite

```swift
import Testing

/// Contract tests for any DataStore implementation.
/// Subclass or call with your concrete implementation.
struct DataStoreContractTests<Store: DataStore> {

    let makeStore: () -> Store

    init(makeStore: @escaping () -> Store) {
        self.makeStore = makeStore
    }

    // MARK: - save(_ item:)

    @Test("save increases count")
    func saveIncreasesCount() async throws {
        let store = makeStore()
        let item = Item(id: "1", title: "Test")

        try await store.save(item)

        #expect(store.count == 1)
    }

    @Test("save then fetch returns same item")
    func saveAndFetch() async throws {
        let store = makeStore()
        let item = Item(id: "1", title: "Test")

        try await store.save(item)
        let fetched = try await store.fetch(id: "1")

        #expect(fetched?.title == "Test")
    }

    @Test("save existing item updates it")
    func saveUpdates() async throws {
        let store = makeStore()
        try await store.save(Item(id: "1", title: "Original"))
        try await store.save(Item(id: "1", title: "Updated"))

        let fetched = try await store.fetch(id: "1")

        #expect(fetched?.title == "Updated")
        #expect(store.count == 1)
    }

    @Test("save throws on invalid item")
    func saveInvalidThrows() async {
        let store = makeStore()
        let invalid = Item(id: "1", title: "")

        await #expect(throws: DataStoreError.invalidItem) {
            try await store.save(invalid)
        }
    }

    // MARK: - fetch(id:)

    @Test("fetch returns nil for non-existent ID")
    func fetchNonExistent() async throws {
        let store = makeStore()

        let result = try await store.fetch(id: "nonexistent")

        #expect(result == nil)
    }

    // MARK: - delete(id:)

    @Test("delete removes item")
    func deleteRemoves() async throws {
        let store = makeStore()
        try await store.save(Item(id: "1", title: "Test"))

        try await store.delete(id: "1")

        #expect(store.count == 0)
        let fetched = try await store.fetch(id: "1")
        #expect(fetched == nil)
    }

    @Test("delete non-existent does nothing")
    func deleteNonExistent() async throws {
        let store = makeStore()

        try await store.delete(id: "nonexistent")

        #expect(store.count == 0)
    }

    // MARK: - fetchAll()

    @Test("fetchAll returns all items")
    func fetchAll() async throws {
        let store = makeStore()
        try await store.save(Item(id: "1", title: "A"))
        try await store.save(Item(id: "2", title: "B"))

        let all = try await store.fetchAll()

        #expect(all.count == 2)
    }

    @Test("fetchAll returns empty when store is empty")
    func fetchAllEmpty() async throws {
        let store = makeStore()

        let all = try await store.fetchAll()

        #expect(all.isEmpty)
    }

    // MARK: - Invariants

    @Test("count matches fetchAll count")
    func countInvariant() async throws {
        let store = makeStore()
        try await store.save(Item(id: "1", title: "A"))
        try await store.save(Item(id: "2", title: "B"))
        try await store.delete(id: "1")

        let all = try await store.fetchAll()

        #expect(store.count == all.count)
    }
}
```

#### Running Contract Tests Per Implementation

```swift
@Suite("InMemoryDataStore Contract")
struct InMemoryDataStoreContractTests {
    let contract = DataStoreContractTests { InMemoryDataStore() }

    @Test("save increases count")
    func saveIncreasesCount() async throws {
        try await contract.saveIncreasesCount()
    }

    @Test("save then fetch returns same item")
    func saveAndFetch() async throws {
        try await contract.saveAndFetch()
    }

    // ... all contract tests
}

@Suite("SQLiteDataStore Contract")
struct SQLiteDataStoreContractTests {
    let contract = DataStoreContractTests { SQLiteDataStore(path: ":memory:") }

    @Test("save increases count")
    func saveIncreasesCount() async throws {
        try await contract.saveIncreasesCount()
    }

    // ... all contract tests
}
```

#### Alternative: Parameterized by Implementation

```swift
@Suite("DataStore Contract")
struct DataStoreContractSuite {

    enum StoreType: String, CaseIterable {
        case inMemory, sqlite, cloud
    }

    func makeStore(_ type: StoreType) -> any DataStore {
        switch type {
        case .inMemory: return InMemoryDataStore()
        case .sqlite: return SQLiteDataStore(path: ":memory:")
        case .cloud: return MockCloudDataStore()
        }
    }

    @Test("save increases count", arguments: StoreType.allCases)
    func saveIncreasesCount(type: StoreType) async throws {
        let store = makeStore(type)
        try await store.save(Item(id: "1", title: "Test"))
        #expect(store.count == 1)
    }

    @Test("fetch non-existent returns nil", arguments: StoreType.allCases)
    func fetchNonExistent(type: StoreType) async throws {
        let store = makeStore(type)
        let result = try await store.fetch(id: "nonexistent")
        #expect(result == nil)
    }
}
```

## Common Contract Categories

### Repository / Data Store
- CRUD operations (create, read, update, delete)
- Query/filter behavior
- Ordering guarantees
- Uniqueness constraints
- Empty state handling

### Network Client
- Successful response parsing
- Error response handling (4xx, 5xx)
- Timeout behavior
- Retry logic
- Request construction (headers, body)

### Cache
- Store and retrieve
- Expiration/TTL
- Eviction policy (LRU, size limit)
- Thread safety
- Persistence across init

### Authentication
- Login with valid credentials
- Reject invalid credentials
- Token refresh
- Session expiration
- Logout clears state

## Output Format

```markdown
## Contract Tests: [Protocol Name]

### Protocol
```swift
protocol DataStore { ... }
```

### Behaviors Tested
| Behavior | Tests | Edge Cases |
|----------|-------|------------|
| save | 3 | empty title, duplicate ID |
| fetch | 2 | non-existent ID |
| delete | 2 | non-existent ID |
| fetchAll | 2 | empty store |
| invariants | 1 | count consistency |

### Implementations Tested
- [x] InMemoryDataStore — all passing
- [x] SQLiteDataStore — all passing
- [ ] CloudDataStore — pending implementation

### Files Created
- `Tests/Contracts/DataStoreContractTests.swift`
- `Tests/Contracts/InMemoryDataStoreContractTests.swift`
```

## References

- `testing/tdd-feature/` — for TDD workflow using contract tests
- `generators/test-generator/` — for standard test generation
- Design by Contract (Bertrand Meyer) — theoretical foundation
