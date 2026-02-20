# Test Generator Code Templates

Production-ready Swift templates for unit tests, integration tests, and UI tests. Templates cover Swift Testing (iOS 16+) and XCTest frameworks.

## Swift Testing Suite Template

Full test suite using Swift Testing with `@Suite`, `@Test`, `#expect`, parameterized tests, and tags.

```swift
import Testing
@testable import YourApp

// MARK: - Custom Tags

extension Tag {
    @Tag static var viewModel: Self
    @Tag static var repository: Self
    @Tag static var networking: Self
    @Tag static var validation: Self
}

// MARK: - Item ViewModel Tests

@Suite("ItemViewModel", .tags(.viewModel))
struct ItemViewModelTests {

    // MARK: - Properties

    let mockRepository: MockItemRepository
    let sut: ItemViewModel

    // MARK: - Initialization (runs before each test)

    init() {
        mockRepository = MockItemRepository()
        sut = ItemViewModel(repository: mockRepository)
    }

    // MARK: - Loading

    @Test("loads items successfully")
    func loadsItemsSuccessfully() async throws {
        mockRepository.stubbedItems = [
            Item(id: "1", title: "First"),
            Item(id: "2", title: "Second"),
            Item(id: "3", title: "Third")
        ]

        await sut.loadItems()

        #expect(sut.items.count == 3)
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test("shows empty state when no items exist")
    func showsEmptyState() async {
        mockRepository.stubbedItems = []

        await sut.loadItems()

        #expect(sut.items.isEmpty)
        #expect(sut.showEmptyState == true)
    }

    @Test("sets loading state during fetch")
    func setsLoadingState() async {
        mockRepository.delay = .milliseconds(100)

        let loadTask = Task { await sut.loadItems() }

        // Allow the task to start
        try? await Task.sleep(for: .milliseconds(10))
        #expect(sut.isLoading == true)

        await loadTask.value
        #expect(sut.isLoading == false)
    }

    // MARK: - Error Handling

    @Test("handles repository failure")
    func handlesRepositoryFailure() async {
        mockRepository.shouldFail = true
        mockRepository.stubbedError = TestError.networkUnavailable

        await sut.loadItems()

        #expect(sut.state == .error)
        #expect(sut.errorMessage != nil)
        #expect(sut.items.isEmpty)
    }

    // MARK: - Parameterized Tests

    @Test("validates email format", arguments: [
        ("user@example.com", true),
        ("user@domain.co.uk", true),
        ("invalid-email", false),
        ("no@tld", false),
        ("@missing-local.com", false),
        ("user@.com", false)
    ])
    func validatesEmailFormat(email: String, isValid: Bool) {
        #expect(EmailValidator.isValid(email) == isValid)
    }

    @Test("filters items by category", arguments: [
        ItemCategory.active,
        ItemCategory.archived,
        ItemCategory.draft
    ])
    func filtersItemsByCategory(category: ItemCategory) async {
        mockRepository.stubbedItems = Item.sampleItems

        await sut.filterItems(by: category)

        let allMatchCategory = sut.items.allSatisfy { $0.category == category }
        #expect(allMatchCategory, "All displayed items should match the selected category")
    }

    // MARK: - Deletion

    @Test("deletes item and refreshes list")
    func deletesItem() async throws {
        let item = Item(id: "1", title: "To Delete")
        mockRepository.stubbedItems = [item]
        await sut.loadItems()

        await sut.deleteItem(item)

        #expect(mockRepository.deleteCallCount == 1)
        #expect(mockRepository.lastDeletedItemID == "1")
    }

    // MARK: - Confirmation (require for optionals)

    @Test("unwraps selected item safely")
    func unwrapsSelectedItem() async throws {
        mockRepository.stubbedItems = [Item(id: "1", title: "First")]
        await sut.loadItems()

        sut.selectItem(at: 0)

        let selected = try #require(sut.selectedItem, "Expected an item to be selected")
        #expect(selected.id == "1")
    }
}
```

## XCTest Class Template

Traditional XCTest class with `setUp`/`tearDown`, async tests, and expectations.

```swift
import XCTest
@testable import YourApp

final class ItemViewModelXCTests: XCTestCase {

    // MARK: - Properties

    private var sut: ItemViewModel!
    private var mockRepository: MockItemRepository!

    // MARK: - Lifecycle

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

    // MARK: - Loading Tests

    func testLoadsItemsSuccessfully() async throws {
        mockRepository.stubbedItems = [
            Item(id: "1", title: "First"),
            Item(id: "2", title: "Second")
        ]

        await sut.loadItems()

        XCTAssertEqual(sut.items.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testShowsEmptyState() async {
        mockRepository.stubbedItems = []

        await sut.loadItems()

        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertTrue(sut.showEmptyState)
    }

    // MARK: - Error Handling Tests

    func testHandlesRepositoryFailure() async {
        mockRepository.shouldFail = true

        await sut.loadItems()

        XCTAssertEqual(sut.state, .error)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.items.isEmpty)
    }

    // MARK: - Deletion Tests

    func testDeletesItemAndRefreshes() async throws {
        let item = Item(id: "1", title: "To Delete")
        mockRepository.stubbedItems = [item]
        await sut.loadItems()

        await sut.deleteItem(item)

        XCTAssertEqual(mockRepository.deleteCallCount, 1)
        XCTAssertEqual(mockRepository.lastDeletedItemID, "1")
    }

    // MARK: - Unwrapping Tests

    func testSelectedItemUnwrap() async throws {
        mockRepository.stubbedItems = [Item(id: "1", title: "First")]
        await sut.loadItems()

        sut.selectItem(at: 0)

        let selected = try XCTUnwrap(sut.selectedItem, "Expected an item to be selected")
        XCTAssertEqual(selected.id, "1")
    }

    // MARK: - Async Expectation Tests

    func testNotificationPostedOnSave() async {
        let expectation = expectation(forNotification: .itemSaved, object: nil)

        await sut.saveItem(Item(id: "1", title: "New"))

        await fulfillment(of: [expectation], timeout: 2.0)
    }
}
```

## Mock Object Template

Protocol-based mock with call counting, argument capture, stubbed returns, and failure injection.

```swift
import Foundation
@testable import YourApp

// MARK: - Protocol

/// Protocol defining repository operations.
/// Both the real implementation and mock conform to this.
protocol ItemRepositoryProtocol: Sendable {
    func fetchItems() async throws -> [Item]
    func fetchItem(id: String) async throws -> Item?
    func saveItem(_ item: Item) async throws
    func deleteItem(id: String) async throws
}

// MARK: - Mock Implementation

/// A mock repository for testing.
///
/// Features:
/// - Stubbed return values for all methods
/// - Call counting for verification
/// - Argument capture for assertion
/// - Configurable failure injection
/// - Optional artificial delay for testing loading states
final class MockItemRepository: ItemRepositoryProtocol, @unchecked Sendable {

    // MARK: - Stubbed Values

    /// Items returned by `fetchItems()`.
    var stubbedItems: [Item] = []

    /// Item returned by `fetchItem(id:)`. Defaults to looking up `stubbedItems` by ID.
    var stubbedItemByID: [String: Item] = [:]

    /// Error thrown when `shouldFail` is `true`.
    var stubbedError: Error = TestError.mockFailure

    // MARK: - Configuration

    /// When `true`, all methods throw `stubbedError`.
    var shouldFail = false

    /// Optional delay before returning results (for testing loading states).
    var delay: Duration?

    // MARK: - Call Tracking: fetchItems

    private(set) var fetchItemsCallCount = 0

    func fetchItems() async throws -> [Item] {
        fetchItemsCallCount += 1
        if let delay { try? await Task.sleep(for: delay) }
        if shouldFail { throw stubbedError }
        return stubbedItems
    }

    // MARK: - Call Tracking: fetchItem

    private(set) var fetchItemCallCount = 0
    private(set) var lastFetchedItemID: String?

    func fetchItem(id: String) async throws -> Item? {
        fetchItemCallCount += 1
        lastFetchedItemID = id
        if shouldFail { throw stubbedError }
        return stubbedItemByID[id] ?? stubbedItems.first { $0.id == id }
    }

    // MARK: - Call Tracking: saveItem

    private(set) var saveCallCount = 0
    private(set) var savedItems: [Item] = []

    func saveItem(_ item: Item) async throws {
        saveCallCount += 1
        savedItems.append(item)
        if shouldFail { throw stubbedError }
    }

    // MARK: - Call Tracking: deleteItem

    private(set) var deleteCallCount = 0
    private(set) var lastDeletedItemID: String?

    func deleteItem(id: String) async throws {
        deleteCallCount += 1
        lastDeletedItemID = id
        if shouldFail { throw stubbedError }
        stubbedItems.removeAll { $0.id == id }
    }

    // MARK: - Reset

    /// Reset all call counts and captured arguments. Useful between tests if sharing a mock.
    func reset() {
        fetchItemsCallCount = 0
        fetchItemCallCount = 0
        lastFetchedItemID = nil
        saveCallCount = 0
        savedItems = []
        deleteCallCount = 0
        lastDeletedItemID = nil
        shouldFail = false
    }
}

// MARK: - Test Errors

/// Common errors used in test mocks.
enum TestError: LocalizedError, Equatable {
    case mockFailure
    case networkUnavailable
    case unauthorized
    case notFound
    case timeout

    var errorDescription: String? {
        switch self {
        case .mockFailure: return "Mock failure for testing"
        case .networkUnavailable: return "Network is unavailable"
        case .unauthorized: return "Unauthorized access"
        case .notFound: return "Resource not found"
        case .timeout: return "Request timed out"
        }
    }
}
```

## UI Test Screen Object Template

Screen Object pattern for XCUITest with page object encapsulation, assertions, and flow navigation.

```swift
import XCTest

// MARK: - Base Screen

/// Base class for all screen objects, providing common utilities.
class BaseScreen {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    /// Wait for an element to exist within a timeout.
    @discardableResult
    func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval = 5
    ) -> Bool {
        element.waitForExistence(timeout: timeout)
    }
}

// MARK: - Home Screen

final class HomeScreen: BaseScreen {

    // MARK: - Elements

    var navigationTitle: XCUIElement {
        app.navigationBars["Items"]
    }

    var itemList: XCUIElement {
        app.collectionViews["itemList"]
    }

    var addButton: XCUIElement {
        app.buttons["addItem"]
    }

    var emptyStateLabel: XCUIElement {
        app.staticTexts["No items yet"]
    }

    var searchField: XCUIElement {
        app.searchFields.firstMatch
    }

    func itemCell(at index: Int) -> XCUIElement {
        itemList.cells.element(boundBy: index)
    }

    func itemCell(titled title: String) -> XCUIElement {
        itemList.cells.staticTexts[title]
    }

    // MARK: - Actions

    @discardableResult
    func tapItem(at index: Int) -> DetailScreen {
        itemCell(at: index).tap()
        return DetailScreen(app: app)
    }

    @discardableResult
    func tapItem(titled title: String) -> DetailScreen {
        itemCell(titled: title).tap()
        return DetailScreen(app: app)
    }

    @discardableResult
    func tapAddButton() -> EditScreen {
        addButton.tap()
        return EditScreen(app: app)
    }

    func search(for query: String) {
        searchField.tap()
        searchField.typeText(query)
    }

    func deleteItem(at index: Int) {
        let cell = itemCell(at: index)
        cell.swipeLeft()
        app.buttons["Delete"].tap()
    }

    // MARK: - Assertions

    func assertItemCount(_ count: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(itemList.cells.count, count, "Expected \(count) items", file: file, line: line)
    }

    func assertEmptyStateVisible(file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(emptyStateLabel.exists, "Empty state should be visible", file: file, line: line)
    }

    func assertItemExists(titled title: String, file: StaticString = #file, line: UInt = #line) {
        let cell = itemCell(titled: title)
        XCTAssertTrue(cell.waitForExistence(timeout: 3), "Item '\(title)' should exist", file: file, line: line)
    }
}

// MARK: - Detail Screen

final class DetailScreen: BaseScreen {

    var titleLabel: XCUIElement {
        app.staticTexts["itemTitle"]
    }

    var editButton: XCUIElement {
        app.buttons["Edit"]
    }

    var deleteButton: XCUIElement {
        app.buttons["Delete"]
    }

    var backButton: XCUIElement {
        app.navigationBars.buttons.firstMatch
    }

    @discardableResult
    func tapEdit() -> EditScreen {
        editButton.tap()
        return EditScreen(app: app)
    }

    @discardableResult
    func tapBack() -> HomeScreen {
        backButton.tap()
        return HomeScreen(app: app)
    }

    func assertTitle(_ title: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(titleLabel.label, title, file: file, line: line)
    }
}

// MARK: - Edit Screen

final class EditScreen: BaseScreen {

    var titleField: XCUIElement {
        app.textFields["itemTitle"]
    }

    var saveButton: XCUIElement {
        app.buttons["Save"]
    }

    var cancelButton: XCUIElement {
        app.buttons["Cancel"]
    }

    func enterTitle(_ title: String) {
        titleField.tap()
        titleField.clearAndTypeText(title)
    }

    @discardableResult
    func tapSave() -> HomeScreen {
        saveButton.tap()
        return HomeScreen(app: app)
    }

    @discardableResult
    func tapCancel() -> HomeScreen {
        cancelButton.tap()
        return HomeScreen(app: app)
    }
}

// MARK: - UI Test Case

final class ItemFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["DISABLE_ANIMATIONS": "1"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testCreateNewItem() {
        let home = HomeScreen(app: app)

        let edit = home.tapAddButton()
        edit.enterTitle("New Item")
        let updatedHome = edit.tapSave()

        updatedHome.assertItemExists(titled: "New Item")
    }

    func testDeleteItem() {
        let home = HomeScreen(app: app)
        home.assertItemCount(3)

        home.deleteItem(at: 0)

        home.assertItemCount(2)
    }

    func testNavigateToDetailAndBack() {
        let home = HomeScreen(app: app)

        let detail = home.tapItem(at: 0)
        detail.assertTitle("First Item")

        let backHome = detail.tapBack()
        backHome.assertItemCount(3)
    }
}

// MARK: - XCUIElement Helpers

extension XCUIElement {
    /// Clear existing text and type new text.
    func clearAndTypeText(_ text: String) {
        guard let currentValue = value as? String, !currentValue.isEmpty else {
            typeText(text)
            return
        }
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteString)
        typeText(text)
    }
}
```

## Test Helpers Template

Factory methods, test fixtures, and convenience extensions for building test data.

```swift
import Foundation
@testable import YourApp

// MARK: - Test Fixtures

/// Factory methods for creating test data.
/// Use these instead of constructing models directly in each test.
enum TestFixtures {

    // MARK: - Items

    /// A single default item for simple tests.
    static let defaultItem = Item(
        id: "test-1",
        title: "Test Item",
        description: "A test item for unit tests",
        category: .active,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000)
    )

    /// A collection of sample items covering various states.
    static let sampleItems: [Item] = [
        Item(id: "1", title: "Active Item", category: .active, createdAt: .now),
        Item(id: "2", title: "Archived Item", category: .archived, createdAt: .now),
        Item(id: "3", title: "Draft Item", category: .draft, createdAt: .now)
    ]

    /// An empty array for testing empty states.
    static let noItems: [Item] = []

    // MARK: - Users

    static let defaultUser = User(
        id: "user-1",
        name: "Test User",
        email: "test@example.com"
    )

    // MARK: - Builders

    /// Create an item with customized properties.
    static func item(
        id: String = UUID().uuidString,
        title: String = "Test Item",
        description: String = "Description",
        category: ItemCategory = .active,
        createdAt: Date = .now
    ) -> Item {
        Item(
            id: id,
            title: title,
            description: description,
            category: category,
            createdAt: createdAt
        )
    }

    /// Create a batch of items for list tests.
    static func items(count: Int, category: ItemCategory = .active) -> [Item] {
        (0..<count).map { index in
            item(
                id: "item-\(index)",
                title: "Item \(index)",
                category: category
            )
        }
    }
}

// MARK: - Model Extensions for Testing

extension Item {
    /// A collection of sample items covering all categories.
    static let sampleItems = TestFixtures.sampleItems
}

// MARK: - Async Test Helpers

/// Utilities for testing asynchronous code.
enum AsyncTestHelpers {

    /// Run an async block with a timeout. Throws if the block does not complete in time.
    static func withTimeout<T>(
        seconds: TimeInterval = 5,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw TestError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Date Helpers

extension Date {
    /// Create a date relative to now for test assertions.
    static func hoursFromNow(_ hours: Double) -> Date {
        Date().addingTimeInterval(hours * 3600)
    }

    /// Create a date in the past for test data.
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }
}

// MARK: - JSON Test Helpers

/// Helpers for testing Codable conformance.
enum CodableTestHelpers {

    /// Encode and decode a value, verifying round-trip fidelity.
    static func verifyRoundTrip<T: Codable & Equatable>(
        _ value: T,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(value)
        let decoded = try decoder.decode(T.self, from: data)
        return decoded
    }

    /// Decode a value from a JSON string.
    static func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}
```

## Patterns: Good and Bad

### Test Isolation

```swift
// ✅ Good: Each test creates its own dependencies (Swift Testing)
@Suite("Tests")
struct MyTests {
    let sut: ItemViewModel
    let mock: MockItemRepository

    init() {
        mock = MockItemRepository()
        sut = ItemViewModel(repository: mock)
    }
}

// ❌ Bad: Shared mutable state without reset
@Suite("Tests")
struct MyTests {
    static let mock = MockItemRepository()  // Shared across all tests!
    static let sut = ItemViewModel(repository: mock)
}
```

### Assertions

```swift
// ✅ Good: Specific assertions with context
#expect(items.count == 3, "Expected 3 items after loading")
#expect(viewModel.state == .loaded)
let first = try #require(items.first)
#expect(first.title == "Expected Title")

// ❌ Bad: Vague assertions
#expect(!items.isEmpty)           // How many should there be?
#expect(viewModel.state != .idle) // What state SHOULD it be?
```

### Error Testing

```swift
// ✅ Good: Test specific error type (Swift Testing)
@Test("throws notFound for missing item")
func throwsNotFound() async {
    let repo = MockItemRepository()
    repo.shouldFail = true
    repo.stubbedError = TestError.notFound

    await #expect(throws: TestError.notFound) {
        try await repo.fetchItem(id: "missing")
    }
}

// ❌ Bad: Only test that "some" error is thrown
@Test("throws error")
func throwsError() async {
    await #expect(throws: (any Error).self) {
        try await repo.fetchItem(id: "missing")
    }
}
```

### Async Tests

```swift
// ✅ Good: Use async/await directly (Swift Testing)
@Test("fetches items asynchronously")
func fetchesItems() async throws {
    let items = try await service.fetchItems()
    #expect(items.count > 0)
}

// ❌ Bad: Using XCTest expectations for simple async (when you could use async/await)
func testFetchesItems() {
    let exp = expectation(description: "fetch")
    Task {
        let items = try await service.fetchItems()
        XCTAssertGreaterThan(items.count, 0)
        exp.fulfill()
    }
    wait(for: [exp], timeout: 5)
}
```

### Optional Handling in Tests

```swift
// ✅ Good: Use #require to unwrap (Swift Testing)
@Test("selected item has correct title")
func selectedItemTitle() async throws {
    await sut.loadItems()
    sut.selectItem(at: 0)

    let selected = try #require(sut.selectedItem)
    #expect(selected.title == "First")
}

// ✅ Good: Use XCTUnwrap (XCTest)
func testSelectedItemTitle() async throws {
    await sut.loadItems()
    sut.selectItem(at: 0)

    let selected = try XCTUnwrap(sut.selectedItem)
    XCTAssertEqual(selected.title, "First")
}

// ❌ Bad: Force unwrap in tests
func testSelectedItemTitle() async {
    await sut.loadItems()
    sut.selectItem(at: 0)

    XCTAssertEqual(sut.selectedItem!.title, "First")  // Crash if nil
}
```
