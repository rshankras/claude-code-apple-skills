# Testing Patterns

Best practices for testing iOS/macOS apps with Swift Testing and XCTest.

## Swift Testing Framework (iOS 16+)

### Test Suite Structure

```swift
import Testing
@testable import YourApp

/// Group related tests with @Suite
@Suite("User Authentication Tests")
struct AuthenticationTests {

    // Shared setup for all tests in suite
    let authService: AuthService

    init() {
        authService = AuthService(client: MockAPIClient())
    }

    @Test("successful login with valid credentials")
    func successfulLogin() async throws {
        let result = try await authService.login(
            email: "test@example.com",
            password: "password123"
        )

        #expect(result.isAuthenticated)
        #expect(result.user.email == "test@example.com")
    }

    @Test("fails with invalid credentials")
    func failsWithInvalidCredentials() async {
        await #expect(throws: AuthError.invalidCredentials) {
            try await authService.login(
                email: "test@example.com",
                password: "wrong"
            )
        }
    }
}
```

### Parameterized Tests

```swift
@Suite("Validation Tests")
struct ValidationTests {

    @Test("email validation", arguments: [
        ("valid@email.com", true),
        ("user@domain.co.uk", true),
        ("name+tag@example.org", true),
        ("invalid", false),
        ("@nodomain.com", false),
        ("spaces in@email.com", false),
        ("", false)
    ])
    func emailValidation(email: String, expectedValid: Bool) {
        let result = Validator.isValidEmail(email)
        #expect(result == expectedValid, "Email '\(email)' validation failed")
    }

    @Test("password strength", arguments: [
        ("weak", PasswordStrength.weak),
        ("Medium1", .medium),
        ("Strong1!", .strong),
        ("VeryStr0ng!Pass", .strong)
    ])
    func passwordStrength(password: String, expected: PasswordStrength) {
        #expect(Validator.passwordStrength(password) == expected)
    }
}
```

### Test Traits

```swift
@Suite("Feature Tests")
struct FeatureTests {

    @Test("premium feature access", .tags(.premium))
    func premiumFeatureAccess() async throws {
        // Test premium feature
    }

    @Test("slow integration test", .timeLimit(.minutes(5)))
    func slowIntegrationTest() async throws {
        // Long-running test
    }

    @Test("disabled pending fix", .disabled("Waiting for API fix"))
    func disabledTest() {
        // Won't run
    }

    @Test("iOS only", .enabled(if: ProcessInfo.processInfo.isMacCatalystApp == false))
    func iOSOnlyTest() {
        // Only runs on iOS
    }
}

extension Tag {
    @Tag static var premium: Self
    @Tag static var integration: Self
    @Tag static var slow: Self
}
```

### Expectations

```swift
@Suite("Expectations")
struct ExpectationTests {

    @Test("basic expectations")
    func basicExpectations() {
        let value = 42

        #expect(value == 42)
        #expect(value > 0)
        #expect(value != 0)
    }

    @Test("optional expectations")
    func optionalExpectations() throws {
        let optional: String? = "hello"

        // Unwrap and continue
        let unwrapped = try #require(optional)
        #expect(unwrapped == "hello")

        // Check nil
        let nilValue: String? = nil
        #expect(nilValue == nil)
    }

    @Test("collection expectations")
    func collectionExpectations() {
        let items = ["a", "b", "c"]

        #expect(items.count == 3)
        #expect(items.contains("b"))
        #expect(!items.isEmpty)
    }

    @Test("throwing expectations")
    func throwingExpectations() async {
        await #expect(throws: NetworkError.self) {
            try await failingOperation()
        }

        // Specific error
        await #expect(throws: NetworkError.timeout) {
            try await timeoutOperation()
        }
    }
}
```

## XCTest Framework

### Test Case Structure

```swift
import XCTest
@testable import YourApp

final class ItemViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: ItemViewModel!  // System Under Test
    private var mockRepository: MockItemRepository!

    // MARK: - Setup & Teardown

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

    // MARK: - Tests

    func test_loadItems_whenSuccessful_updatesItems() async throws {
        // Arrange
        mockRepository.items = [Item(id: "1", name: "Test")]

        // Act
        await sut.loadItems()

        // Assert
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items.first?.name, "Test")
    }

    func test_loadItems_whenFails_showsError() async {
        // Arrange
        mockRepository.shouldFail = true

        // Act
        await sut.loadItems()

        // Assert
        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
    }
}
```

### Async Testing

```swift
final class AsyncTests: XCTestCase {

    func test_asyncOperation_completesSuccessfully() async throws {
        let service = DataService()

        let result = try await service.fetchData()

        XCTAssertFalse(result.isEmpty)
    }

    func test_asyncOperation_withTimeout() async throws {
        let expectation = expectation(description: "Data loaded")

        Task {
            _ = try await service.fetchData()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }
}
```

## Mock Objects

### Protocol-Based Mocking

```swift
// Protocol
protocol ItemRepository: Sendable {
    func fetchItems() async throws -> [Item]
    func saveItem(_ item: Item) async throws
    func deleteItem(id: String) async throws
}

// Mock Implementation
final class MockItemRepository: ItemRepository, @unchecked Sendable {

    // Configurable state
    var items: [Item] = []
    var shouldFail = false
    var error: Error = MockError.general

    // Call tracking
    var fetchCallCount = 0
    var saveCallCount = 0
    var deleteCallCount = 0
    var lastSavedItem: Item?
    var lastDeletedId: String?

    func fetchItems() async throws -> [Item] {
        fetchCallCount += 1
        if shouldFail { throw error }
        return items
    }

    func saveItem(_ item: Item) async throws {
        saveCallCount += 1
        lastSavedItem = item
        if shouldFail { throw error }
        items.append(item)
    }

    func deleteItem(id: String) async throws {
        deleteCallCount += 1
        lastDeletedId = id
        if shouldFail { throw error }
        items.removeAll { $0.id == id }
    }

    func reset() {
        items = []
        shouldFail = false
        fetchCallCount = 0
        saveCallCount = 0
        deleteCallCount = 0
        lastSavedItem = nil
        lastDeletedId = nil
    }
}

enum MockError: Error {
    case general
    case network
    case notFound
}
```

### Spy Pattern

```swift
final class SpyAnalytics: AnalyticsService {
    var trackedEvents: [(name: String, properties: [String: Any])] = []

    func track(event: String, properties: [String: Any]) {
        trackedEvents.append((event, properties))
    }

    func hasTracked(event: String) -> Bool {
        trackedEvents.contains { $0.name == event }
    }

    func eventCount(for event: String) -> Int {
        trackedEvents.filter { $0.name == event }.count
    }
}
```

## ViewModel Testing

### Testing State Changes

```swift
@Suite("ItemViewModel State Tests")
struct ItemViewModelStateTests {

    @Test("initial state is idle")
    func initialState() {
        let vm = ItemViewModel(repository: MockItemRepository())
        #expect(vm.state == .idle)
    }

    @Test("loading state during fetch")
    func loadingState() async {
        let slowRepo = SlowMockRepository(delay: 0.1)
        let vm = ItemViewModel(repository: slowRepo)

        async let loadTask = vm.loadItems()

        // Check loading state
        try? await Task.sleep(for: .milliseconds(50))
        #expect(vm.state == .loading)

        await loadTask
        #expect(vm.state == .loaded)
    }

    @Test("error state on failure")
    func errorState() async {
        let failingRepo = MockItemRepository(shouldFail: true)
        let vm = ItemViewModel(repository: failingRepo)

        await vm.loadItems()

        #expect(vm.state == .error)
    }
}
```

### Testing User Actions

```swift
@Suite("User Action Tests")
struct UserActionTests {

    @Test("adding item updates list")
    func addingItem() async throws {
        let repo = MockItemRepository()
        let vm = ItemViewModel(repository: repo)

        await vm.addItem(title: "New Item")

        #expect(vm.items.count == 1)
        #expect(vm.items.first?.title == "New Item")
        #expect(repo.saveCallCount == 1)
    }

    @Test("deleting item removes from list")
    func deletingItem() async throws {
        let repo = MockItemRepository(items: [
            Item(id: "1", title: "Item 1"),
            Item(id: "2", title: "Item 2")
        ])
        let vm = ItemViewModel(repository: repo)
        await vm.loadItems()

        await vm.deleteItem(id: "1")

        #expect(vm.items.count == 1)
        #expect(vm.items.first?.id == "2")
    }
}
```

## UI Testing

### Page Object Pattern

```swift
import XCTest

// Base screen
class BaseScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }
}

// Home screen
class HomeScreen: BaseScreen {

    var itemList: XCUIElement {
        app.collectionViews["itemList"]
    }

    var addButton: XCUIElement {
        app.buttons["addButton"]
    }

    var itemCells: XCUIElementQuery {
        itemList.cells
    }

    @discardableResult
    func tapAddButton() -> AddItemScreen {
        addButton.tap()
        return AddItemScreen(app: app)
    }

    func tapItem(at index: Int) -> ItemDetailScreen {
        itemCells.element(boundBy: index).tap()
        return ItemDetailScreen(app: app)
    }

    func itemCount() -> Int {
        itemCells.count
    }
}

// Add item screen
class AddItemScreen: BaseScreen {

    var titleField: XCUIElement {
        app.textFields["titleField"]
    }

    var saveButton: XCUIElement {
        app.buttons["saveButton"]
    }

    func enterTitle(_ title: String) -> Self {
        titleField.tap()
        titleField.typeText(title)
        return self
    }

    @discardableResult
    func tapSave() -> HomeScreen {
        saveButton.tap()
        return HomeScreen(app: app)
    }
}
```

### UI Test Cases

```swift
import XCTest

final class ItemFlowUITests: XCTestCase {

    var app: XCUIApplication!
    var homeScreen: HomeScreen!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        homeScreen = HomeScreen(app: app)
    }

    func test_addItem_flow() {
        // Initial state
        let initialCount = homeScreen.itemCount()

        // Add new item
        homeScreen
            .tapAddButton()
            .enterTitle("Test Item")
            .tapSave()

        // Verify
        XCTAssertEqual(homeScreen.itemCount(), initialCount + 1)
    }

    func test_viewItemDetail_flow() {
        // Tap first item
        let detailScreen = homeScreen.tapItem(at: 0)

        // Verify detail screen appeared
        XCTAssertTrue(detailScreen.titleLabel.exists)
    }
}
```

## Test Utilities

### Test Data Builders

```swift
struct ItemBuilder {
    private var id = UUID().uuidString
    private var title = "Test Item"
    private var isCompleted = false
    private var createdAt = Date()

    func with(id: String) -> Self {
        var copy = self
        copy.id = id
        return copy
    }

    func with(title: String) -> Self {
        var copy = self
        copy.title = title
        return copy
    }

    func completed() -> Self {
        var copy = self
        copy.isCompleted = true
        return copy
    }

    func build() -> Item {
        Item(
            id: id,
            title: title,
            isCompleted: isCompleted,
            createdAt: createdAt
        )
    }
}

// Usage
let item = ItemBuilder()
    .with(title: "Custom Title")
    .completed()
    .build()
```

### Async Test Helpers

```swift
extension XCTestCase {

    func waitForAsync(
        timeout: TimeInterval = 5,
        condition: @escaping () async -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if await condition() {
                return
            }
            try await Task.sleep(for: .milliseconds(100))
        }

        XCTFail("Condition not met within \(timeout) seconds")
    }
}
```

## Best Practices

### Naming Conventions

```swift
// Swift Testing - use descriptive strings
@Test("user can successfully log in with valid credentials")

// XCTest - use method naming pattern
func test_login_withValidCredentials_succeeds()
func test_login_withInvalidPassword_fails()
func test_logout_clearsUserSession()
```

### Test Organization

```
Tests/
├── UnitTests/
│   ├── ViewModels/
│   ├── Services/
│   ├── Repositories/
│   └── Utilities/
├── IntegrationTests/
│   ├── API/
│   └── Database/
├── UITests/
│   ├── Screens/
│   ├── Flows/
│   └── Helpers/
└── Mocks/
    ├── MockAPIClient.swift
    ├── MockRepository.swift
    └── TestData.swift
```

### Code Coverage

```bash
# Generate coverage report
xcodebuild test \
  -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# View coverage
xcrun xccov view --report TestResults.xcresult
```
