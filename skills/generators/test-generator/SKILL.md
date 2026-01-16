# Test Generator

Generate test templates for unit tests, integration tests, and UI tests in iOS/macOS apps.

## When to Use

- User wants to add tests to their app
- User asks about unit testing, UI testing, or XCTest
- User wants to test ViewModels, services, or repositories
- User mentions TDD or test-driven development

## Pre-Generation Checks

Before generating, verify:

1. **Existing Test Targets**
   ```bash
   # Check for test targets
   find . -name "*Tests" -type d | head -5
   grep -r "testTarget" Package.swift 2>/dev/null
   ```

2. **Testing Frameworks**
   ```bash
   # Check for Swift Testing or XCTest usage
   grep -r "import XCTest\|import Testing" --include="*.swift" | head -5
   ```

3. **Project Architecture**
   ```bash
   # Identify patterns (MVVM, TCA, etc.)
   grep -r "ViewModel\|Reducer\|UseCase" --include="*.swift" | head -5
   ```

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

## References

- [Swift Testing](https://developer.apple.com/documentation/testing)
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
