---
name: test-data-factory
description: Generate test fixture factories for your models. Builder pattern and static factories for zero-boilerplate test data. Use when tests need sample data setup.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Test Data Factory

Generate factory helpers that make creating test data effortless. Eliminates boilerplate in test setup so writing tests has zero friction.

## When This Skill Activates

Use this skill when the user:
- Has repetitive test setup code
- Asks for "test fixtures" or "test factories" or "sample data"
- Wants to reduce boilerplate in tests
- Says "my tests have too much setup"
- Is building a test suite and needs realistic sample data
- Mentions "builder pattern" for tests

## Why Test Factories

```swift
// ❌ Without factory — every test repeats this
let item = Item(
    id: UUID(),
    title: "Test Item",
    description: "A test description",
    category: .general,
    createdAt: Date(),
    updatedAt: Date(),
    isFavorite: false,
    tags: [],
    author: User(id: UUID(), name: "Test User", email: "test@test.com")
)

// ✅ With factory — one line, override only what matters
let item = Item.fixture()
let favoriteItem = Item.fixture(isFavorite: true)
let taggedItem = Item.fixture(tags: ["swift", "testing"])
```

## Process

### Phase 1: Discover Models

```
Glob: **/*.swift (in source targets)
Grep: "struct.*:.*Identifiable|class.*:.*Identifiable|@Model"
Grep: "struct.*:.*Codable|struct.*:.*Sendable"
```

Identify models that appear in test files:
```
Grep: "let.*=.*Model(" in test targets (manual construction)
```

### Phase 2: Choose Factory Pattern

Ask via AskUserQuestion:

1. **Factory style?**
   - Static factory methods (simpler, recommended)
   - Builder pattern (more flexible, for complex models)
   - Both

2. **Where to add?**
   - Test target extension (recommended — keeps production code clean)
   - Shared test helper file

### Phase 3: Generate Factories

#### Pattern 1: Static Factory Extension

```swift
// Tests/Factories/Item+Factory.swift

import Foundation
@testable import YourApp

extension Item {
    /// Creates a test fixture with sensible defaults.
    /// Override only the properties relevant to your test.
    static func fixture(
        id: UUID = UUID(),
        title: String = "Test Item",
        description: String = "A test description",
        category: Category = .general,
        createdAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        updatedAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
        isFavorite: Bool = false,
        tags: [String] = [],
        author: User = .fixture()
    ) -> Item {
        Item(
            id: id,
            title: title,
            description: description,
            category: category,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isFavorite: isFavorite,
            tags: tags,
            author: author
        )
    }

    /// Named fixtures for common test scenarios
    static var sample: Item { .fixture() }
    static var favorite: Item { .fixture(isFavorite: true) }
    static var empty: Item { .fixture(title: "", description: "") }

    /// Collection fixtures
    static var sampleList: [Item] {
        [
            .fixture(id: UUID(), title: "First Item", category: .work),
            .fixture(id: UUID(), title: "Second Item", category: .personal),
            .fixture(id: UUID(), title: "Third Item", category: .general)
        ]
    }
}

extension User {
    static func fixture(
        id: UUID = UUID(),
        name: String = "Test User",
        email: String = "test@example.com"
    ) -> User {
        User(id: id, name: name, email: email)
    }

    static var sample: User { .fixture() }
}
```

#### Pattern 2: Builder Pattern

For models with many optional fields or complex relationships:

```swift
// Tests/Factories/ItemBuilder.swift

@testable import YourApp

final class ItemBuilder {
    private var id: UUID = UUID()
    private var title: String = "Test Item"
    private var description: String = "A test description"
    private var category: Category = .general
    private var createdAt: Date = .init(timeIntervalSince1970: 1_700_000_000)
    private var isFavorite: Bool = false
    private var tags: [String] = []
    private var author: User = .fixture()

    @discardableResult
    func with(title: String) -> Self {
        self.title = title
        return self
    }

    @discardableResult
    func with(category: Category) -> Self {
        self.category = category
        return self
    }

    @discardableResult
    func favorited() -> Self {
        self.isFavorite = true
        return self
    }

    @discardableResult
    func with(tags: [String]) -> Self {
        self.tags = tags
        return self
    }

    @discardableResult
    func authored(by user: User) -> Self {
        self.author = user
        return self
    }

    func build() -> Item {
        Item(
            id: id,
            title: title,
            description: description,
            category: category,
            createdAt: createdAt,
            updatedAt: createdAt,
            isFavorite: isFavorite,
            tags: tags,
            author: author
        )
    }
}

// Usage:
let item = ItemBuilder()
    .with(title: "Important")
    .with(category: .work)
    .favorited()
    .build()
```

#### Pattern 3: Sequence Factories

For generating unique test data in loops:

```swift
extension Item {
    /// Creates N unique items with sequential titles
    static func fixtures(count: Int) -> [Item] {
        (0..<count).map { index in
            .fixture(
                id: UUID(),
                title: "Item \(index + 1)"
            )
        }
    }

    /// Creates items matching specific states for state-based testing
    static var allStates: [Item] {
        [
            .fixture(title: "Draft", category: .draft),
            .fixture(title: "Active", category: .active),
            .fixture(title: "Archived", category: .archived),
            .fixture(title: "Deleted", category: .deleted)
        ]
    }
}
```

### Phase 4: Generate Date/Time Helpers

Tests with dates are notoriously flaky. Provide fixed dates:

```swift
// Tests/Factories/Date+Factory.swift

extension Date {
    /// Fixed reference dates for deterministic tests
    static let testReference = Date(timeIntervalSince1970: 1_700_000_000)  // 2023-11-14
    static let testYesterday = testReference.addingTimeInterval(-86_400)
    static let testLastWeek = testReference.addingTimeInterval(-604_800)
    static let testNextMonth = testReference.addingTimeInterval(2_592_000)

    /// Create a date relative to test reference
    static func testDate(daysFromReference days: Int) -> Date {
        testReference.addingTimeInterval(TimeInterval(days * 86_400))
    }
}
```

### Phase 5: Generate Mock Response Factories

For network/API testing:

```swift
// Tests/Factories/APIResponse+Factory.swift

extension APIResponse where T == [Item] {
    static func success(items: [Item] = Item.sampleList) -> APIResponse {
        APIResponse(data: items, statusCode: 200, error: nil)
    }

    static func empty() -> APIResponse {
        APIResponse(data: [], statusCode: 200, error: nil)
    }

    static func error(_ error: APIError = .serverError) -> APIResponse {
        APIResponse(data: nil, statusCode: 500, error: error)
    }

    static func notFound() -> APIResponse {
        APIResponse(data: nil, statusCode: 404, error: .notFound)
    }
}
```

## Factory Design Rules

### Defaults Should Be

| Property Type | Default Strategy |
|--------------|-----------------|
| UUID | `UUID()` (unique per call) |
| String | Descriptive placeholder (`"Test Item"`) |
| Date | Fixed timestamp (not `Date()` — causes flaky tests) |
| Bool | `false` (opt-in to special states) |
| Array | Empty `[]` (opt-in to populated) |
| Optional | `nil` (opt-in to having a value) |
| Enum | Most common/default case |
| Nested model | That model's `.fixture()` |

### Naming Conventions

```swift
// Static factory — use .fixture() for customizable, .sample for quick
Item.fixture(title: "Custom")   // Customizable
Item.sample                     // Quick default
Item.sampleList                 // Collection

// Named scenarios
Item.favorite                   // Specific state
Item.expired                    // Specific state
Item.empty                      // Edge case

// Builder — use descriptive method names
ItemBuilder().favorited().build()
ItemBuilder().with(title: "X").build()
```

## Output Format

```markdown
## Test Data Factories Generated

### Models Covered
| Model | Factory Type | Named Fixtures | Collection Fixtures |
|-------|-------------|----------------|-------------------|
| Item | Static + Builder | sample, favorite, empty | sampleList, fixtures(count:) |
| User | Static | sample | — |
| APIResponse | Static | success, empty, error | — |

### Files Created
- `Tests/Factories/Item+Factory.swift`
- `Tests/Factories/User+Factory.swift`
- `Tests/Factories/ItemBuilder.swift`
- `Tests/Factories/Date+Factory.swift`
- `Tests/Factories/APIResponse+Factory.swift`

### Usage Example
```swift
// Before (30 lines of setup)
let user = User(id: UUID(), name: "Test", email: "t@t.com")
let item = Item(id: UUID(), title: "T", description: "D", ...)

// After (1 line)
let item = Item.fixture(isFavorite: true)
```
```

## References

- `generators/test-generator/` — generates tests that use these factories
- `testing/tdd-feature/` — TDD workflow benefits from low-friction factories
- `testing/integration-test-scaffold/` — integration tests need realistic data
