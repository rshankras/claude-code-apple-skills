---
name: test-generator
description: Generate test templates for unit tests, integration tests, and UI tests using Swift Testing and XCTest. Use when adding tests to iOS/macOS apps.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Test Generator

Generate test templates for unit tests, integration tests, and UI tests in iOS/macOS apps.

## When This Skill Activates

Use this skill when the user:
- Asks to "add tests" or "write tests" for their app
- Asks about unit testing, UI testing, or XCTest
- Wants to test ViewModels, services, or repositories
- Mentions TDD or test-driven development
- Asks about Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- Wants mock objects or test helpers
- Asks about snapshot testing or preview tests

## Decision Tree

```
What tests do you need?
|
+-- Unit tests for business logic
|   +-- Swift Testing (@Test, #expect) -- recommended for iOS 16+
|   +-- XCTest -- for iOS 13-15 support or existing XCTest projects
|
+-- Integration tests (component interactions)
|   +-- Protocol-based mocks with dependency injection
|
+-- UI tests
|   +-- XCUITest with Screen Object pattern
|
+-- Snapshot/preview tests
    +-- PreviewSnapshots or swift-snapshot-testing
```

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Identify existing test targets and test runner
- [ ] Detect testing framework already in use (Swift Testing vs XCTest)
- [ ] Verify deployment target (Swift Testing requires iOS 16+ / macOS 13+)
- [ ] Identify project architecture pattern (MVVM, TCA, Repository, etc.)
- [ ] Locate source file directories

### 2. Conflict Detection
Search for existing test infrastructure:
```
Glob: **/*Tests.swift, **/*Tests/**/*.swift, **/*Spec.swift
Grep: "import XCTest" or "import Testing" or "@Suite" or "@Test"
Grep: "MockItemRepository" or "protocol.*Repository" or "class Mock"
```

If existing tests are found:
- Ask user whether to follow the existing framework (XCTest vs Swift Testing) or migrate
- Check for existing mock objects to reuse or extend
- Identify existing test helpers and factories

If a test target already exists:
- Add new tests to the existing target -- do NOT create a new target
- Follow the existing directory structure and naming conventions

### 3. Architecture Detection
```
Grep: "ViewModel" or "Reducer" or "UseCase" or "Repository" or "Service"
Glob: **/*ViewModel.swift, **/*Reducer.swift, **/*Repository.swift
```

This determines which test templates to generate (ViewModel tests, Reducer tests, etc.).

## Configuration Questions

### 1. Testing Framework
- **Swift Testing** (Recommended, iOS 16+) - Modern, expressive syntax
- **XCTest** - Traditional framework, all iOS versions
- **Both** - Mix of frameworks

### 2. Test Types to Generate
- **Unit Tests** - Test individual components in isolation
- **Integration Tests** - Test component interactions
- **UI Tests** - Test user interface and flows
- **All** - Complete test coverage

### 3. Architecture Pattern
- **MVVM** - ViewModel tests
- **TCA** - Reducer tests
- **Repository** - Data layer tests
- **Custom** - Based on project structure

## Generated Files

### Unit Tests
```
Tests/UnitTests/
├── ViewModelTests/
│   └── ItemViewModelTests.swift
├── ServiceTests/
│   └── APIClientTests.swift
└── RepositoryTests/
    └── ItemRepositoryTests.swift
```

### UI Tests
```
Tests/UITests/
├── Screens/
│   └── HomeScreenTests.swift
├── Flows/
│   └── OnboardingFlowTests.swift
└── Helpers/
    └── TestHelpers.swift
```

## Swift Testing (Modern)

### Basic Test Structure

```swift
import Testing
@testable import YourApp

@Suite("Item ViewModel Tests")
struct ItemViewModelTests {

    @Test("loads items successfully")
    func loadsItems() async throws {
        let mockRepository = MockItemRepository()
        let viewModel = ItemViewModel(repository: mockRepository)

        await viewModel.loadItems()

        #expect(viewModel.items.count == 3)
        #expect(viewModel.isLoading == false)
    }

    @Test("handles empty state")
    func handlesEmptyState() async {
        let mockRepository = MockItemRepository(items: [])
        let viewModel = ItemViewModel(repository: mockRepository)

        await viewModel.loadItems()

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.showEmptyState)
    }
}
```

### Parameterized Tests

```swift
@Test("validates email format", arguments: [
    ("valid@email.com", true),
    ("invalid", false),
    ("no@tld", false),
    ("test@domain.co.uk", true)
])
func validatesEmail(email: String, isValid: Bool) {
    #expect(EmailValidator.isValid(email) == isValid)
}
```

## XCTest (Traditional)

### Basic Test Structure

```swift
import XCTest
@testable import YourApp

final class ItemViewModelTests: XCTestCase {

    var sut: ItemViewModel!
    var mockRepository: MockItemRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockItemRepository()
        sut = ItemViewModel(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func testLoadsItems() async throws {
        await sut.loadItems()

        XCTAssertEqual(sut.items.count, 3)
        XCTAssertFalse(sut.isLoading)
    }
}
```

## Test Patterns

### Testing ViewModels

```swift
@Suite("ViewModel Tests")
struct ViewModelTests {

    @Test("state transitions correctly")
    func stateTransitions() async {
        let vm = ItemViewModel(repository: MockItemRepository())

        #expect(vm.state == .idle)

        await vm.loadItems()

        #expect(vm.state == .loaded)
    }

    @Test("error handling")
    func errorHandling() async {
        let failingRepo = MockItemRepository(shouldFail: true)
        let vm = ItemViewModel(repository: failingRepo)

        await vm.loadItems()

        #expect(vm.state == .error)
        #expect(vm.errorMessage != nil)
    }
}
```

### Testing Async Code

```swift
@Test("fetches data asynchronously")
func fetchesData() async throws {
    let service = APIService()

    let result = try await service.fetchItems()

    #expect(result.count > 0)
}

@Test("times out appropriately")
func timesOut() async {
    await #expect(throws: TimeoutError.self) {
        try await withTimeout(seconds: 1) {
            try await Task.sleep(for: .seconds(5))
        }
    }
}
```

## Mock Creation

### Protocol-Based Mocks

```swift
protocol ItemRepository {
    func fetchItems() async throws -> [Item]
    func saveItem(_ item: Item) async throws
}

final class MockItemRepository: ItemRepository {
    var items: [Item] = []
    var shouldFail = false
    var saveCallCount = 0

    func fetchItems() async throws -> [Item] {
        if shouldFail {
            throw TestError.mockFailure
        }
        return items
    }

    func saveItem(_ item: Item) async throws {
        saveCallCount += 1
        items.append(item)
    }
}
```

## UI Testing

### Screen Object Pattern

```swift
import XCTest

final class HomeScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    var itemList: XCUIElement {
        app.collectionViews["itemList"]
    }

    var addButton: XCUIElement {
        app.buttons["addItem"]
    }

    func tapItem(at index: Int) {
        itemList.cells.element(boundBy: index).tap()
    }

    func addNewItem(title: String) {
        addButton.tap()
        app.textFields["itemTitle"].tap()
        app.textFields["itemTitle"].typeText(title)
        app.buttons["save"].tap()
    }
}
```

## Integration Steps

### 1. Add Test Target

In Xcode:
1. File > New > Target
2. Choose "Unit Testing Bundle" or "UI Testing Bundle"
3. Name appropriately (e.g., `YourAppTests`)

### 2. Configure Test Scheme

1. Edit Scheme > Test
2. Add test targets
3. Configure code coverage

### 3. Run Tests

```bash
# Command line
xcodebuild test -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 16'

# With coverage
xcodebuild test -scheme YourApp -enableCodeCoverage YES
```

## Best Practices

1. **Test one thing per test** - Clear, focused tests
2. **Use descriptive names** - Tests as documentation
3. **Arrange-Act-Assert** - Clear test structure
4. **Mock external dependencies** - Isolate units
5. **Test edge cases** - Empty, nil, error states
6. **Keep tests fast** - No real network/disk

## Top 5 Mistakes

| # | Mistake | Why It's Wrong | Fix |
|---|---------|---------------|-----|
| 1 | Testing implementation details instead of behavior | Tests break on every refactor, providing no safety net | Test public API and observable outcomes, not internal state |
| 2 | Sharing mutable state between tests | Tests pass individually but fail when run together (order-dependent) | Create fresh instances in each test; use `init()` in `@Suite` structs or `setUp()` in XCTest |
| 3 | Using `XCTAssertTrue(result != nil)` instead of `XCTUnwrap` | Failure message is useless ("XCTAssertTrue failed") with no context | Use `let value = try XCTUnwrap(result)` or `#expect(result != nil)` with Swift Testing |
| 4 | Not testing error paths | Only happy-path coverage; errors crash in production | Always test with `shouldFail = true` mocks and verify error state |
| 5 | Real network calls in unit tests | Tests are slow, flaky, and fail offline | Use protocol-based mocks; reserve real network calls for integration test schemes |

## Review Checklist

Before finishing test generation, verify:

- [ ] **Naming**: Test names describe the behavior, not the method (`loadsItemsSuccessfully` not `testLoadItems`)
- [ ] **Isolation**: Each test creates its own dependencies -- no shared mutable state
- [ ] **No real I/O**: Unit tests use mocks for network, disk, and database
- [ ] **Async handling**: Async tests use `async throws` (Swift Testing) or `async throws` with expectations (XCTest)
- [ ] **Error paths tested**: At least one test per function verifies error/failure behavior
- [ ] **Edge cases**: Empty collections, nil optionals, boundary values are tested
- [ ] **Assertions are specific**: Using `#expect(items.count == 3)` not `#expect(!items.isEmpty)`
- [ ] **Mock call verification**: Mocks track call counts and received arguments where needed
- [ ] **No force unwraps in tests**: Use `try #require()` (Swift Testing) or `XCTUnwrap` (XCTest)
- [ ] **Tests compile and run**: Verify with `xcodebuild test` or Xcode test navigator

## References

- **templates.md** -- Production-ready code templates for test suites, mocks, and helpers
- [Swift Testing](https://developer.apple.com/documentation/testing)
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
