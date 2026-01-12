---
name: test-spec
description: Generates comprehensive test specification with unit tests, UI tests, accessibility testing, and beta testing plan. Creates TEST_SPEC.md from PRD and implementation specs. Use when creating QA strategy.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion]
---

# Test Specification Skill

Generate comprehensive test specification and QA plan for iOS/macOS app testing.

## Metadata
- **Name**: test-spec
- **Version**: 1.0.0
- **Role**: QA Engineer
- **Author**: ProductAgent Team

## Activation

This skill activates when the user says:
- "generate test spec"
- "create QA plan"
- "write testing guide"
- "generate test cases"
- "create test specification"

## Description

You are a QA Engineer AI agent specializing in iOS/macOS app testing. Your job is to transform product requirements and implementation details into a comprehensive test specification that ensures quality, identifies edge cases, and provides clear test cases for both automated and manual testing.

## Prerequisites

Before activating this skill, ensure:
1. PRD exists (from prd-generator skill) with features and acceptance criteria
2. IMPLEMENTATION_GUIDE exists (from implementation-guide skill) with code structure
3. UX_SPEC exists (from ux-spec skill) for UI testing scenarios

## Input Sources

Read and extract information from:

1. **docs/PRD.md**
   - All features with acceptance criteria
   - User stories (Given/When/Then format)
   - Success criteria
   - Non-functional requirements

2. **docs/IMPLEMENTATION_GUIDE.md**
   - All ViewModels to test
   - All data models to test
   - API endpoints to test
   - File structure for organizing tests

3. **docs/UX_SPEC.md**
   - All user flows
   - All interactions
   - All states (empty, loading, error)
   - Edge cases documented

4. **docs/ARCHITECTURE.md**
   - Testing strategy overview
   - Tech stack (for choosing testing tools)

## Output

Generate: **docs/TEST_SPEC.md**

Structure:

```markdown
# Test Specification: [App Name]

**Version**: 1.0.0
**Last Updated**: [Date]
**Status**: Draft / In Review / Approved
**QA Engineer**: QA Engineer AI
**Platform**: iOS [Version]+

---

## 1. Test Strategy

### 1.1 Test Pyramid

Our testing approach follows the test pyramid:

```
         /\\
        /  \\  UI Tests (10%)
       /    \\  Critical user journeys, happy paths
      /------\\
     /        \\  Integration Tests (20%)
    /          \\  API integration, data persistence, service layer
   /------------\\
  /              \\  Unit Tests (70%)
 /                \\  ViewModels, Models, Utilities, Business Logic
/------------------\\
```

**Rationale**:
- **Unit Tests (70%)**: Fast, reliable, easy to maintain. Focus on business logic.
- **Integration Tests (20%)**: Test component interactions (API + Database, ViewModel + Service).
- **UI Tests (10%)**: Slow and brittle, only for critical user flows.

### 1.2 Testing Levels

**Level 1: Unit Testing**
- **Scope**: Individual functions, methods, ViewModels, Models
- **Tools**: XCTest
- **Run Frequency**: On every commit (CI/CD)
- **Target Coverage**: 80%+ code coverage

**Level 2: Integration Testing**
- **Scope**: Multiple components working together
- **Tools**: XCTest with mock/stub services
- **Run Frequency**: On every PR merge
- **Target Coverage**: All critical data flows

**Level 3: UI Testing**
- **Scope**: End-to-end user journeys
- **Tools**: XCUITest
- **Run Frequency**: Before release
- **Target Coverage**: All P0 user flows

**Level 4: Manual Testing**
- **Scope**: Exploratory testing, edge cases, UX validation
- **Tools**: TestFlight beta
- **Run Frequency**: Before each release
- **Target Coverage**: Full app walkthrough

### 1.3 Test Environments

**Development**:
- Local Xcode testing
- In-memory database (SwiftData)
- Mock API responses
- Fast feedback loop

**Staging**:
- TestFlight internal testing
- Staging API environment
- Real backend integration
- Pre-production validation

**Production**:
- Phased rollout (10% → 50% → 100%)
- Real user monitoring
- Crash analytics
- Performance monitoring

### 1.4 Testing Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| XCTest | Unit & integration tests | Always |
| XCUITest | UI automation tests | Critical flows |
| TestFlight | Beta testing | Pre-release |
| Xcode Instruments | Performance profiling | Optimization phase |
| Accessibility Inspector | Accessibility audit | Every release |
| Network Link Conditioner | Network testing | Edge case testing |

---

## 2. Unit Test Cases

### 2.1 Data Model Tests

Test all `@Model` classes from ARCHITECTURE.md.

#### Test Suite: User Model

**File**: `[AppName]Tests/ModelTests/UserTests.swift`

| Test Case | Setup | Input | Expected Output | Priority |
|-----------|-------|-------|-----------------|----------|
| testUserInitialization | None | name: "John Doe", email: "john@test.com" | User object created with UUID, timestamps set | P0 |
| testUserInitializationWithEmptyName | None | name: "", email: "test@test.com" | User created but isValid returns false | P1 |
| testEmailValidation_Valid | User instance | email: "valid@example.com" | isValid returns true | P0 |
| testEmailValidation_Invalid | User instance | email: "invalid.com" | isValid returns false | P0 |
| testEmailValidation_Empty | User instance | email: "" | isValid returns false | P0 |
| testDisplayName_SingleName | User with name: "John" | Call displayName | Returns "John" | P1 |
| testDisplayName_FullName | User with name: "John Doe" | Call displayName | Returns "John" | P1 |
| testInitials_SingleName | User with name: "John" | Call initials | Returns "J" | P2 |
| testInitials_FullName | User with name: "John Doe" | Call initials | Returns "JD" | P2 |
| testUpdateProfile_Name | User instance | updateProfile(name: "Jane") | name updated, updatedAt changed | P1 |
| testUpdateProfile_Email | User instance | updateProfile(email: "new@test.com") | email updated, updatedAt changed | P1 |
| testCodable_Encoding | User instance | Encode to JSON | Valid JSON with snake_case keys | P1 |
| testCodable_Decoding | JSON data | Decode from JSON | User object created correctly | P1 |

**Implementation Example**:

```swift
import XCTest
@testable import [AppName]

final class UserTests: XCTestCase {
    var sut: User!  // System Under Test

    override func setUp() {
        super.setUp()
        // Setup runs before each test
        sut = User(name: "Test User", email: "test@example.com")
    }

    override func tearDown() {
        // Cleanup runs after each test
        sut = nil
        super.tearDown()
    }

    // Test: User initialization creates valid object
    func testUserInitialization() {
        // Given: Setup in setUp()

        // When: User is initialized (done in setUp)

        // Then: Verify properties
        XCTAssertNotNil(sut.id, "ID should be generated")
        XCTAssertEqual(sut.name, "Test User")
        XCTAssertEqual(sut.email, "test@example.com")
        XCTAssertNotNil(sut.createdAt)
        XCTAssertNotNil(sut.updatedAt)
        XCTAssertTrue(sut.items.isEmpty, "New user should have no items")
    }

    // Test: Valid email passes validation
    func testEmailValidation_Valid() {
        // Given
        sut.email = "valid@example.com"

        // When
        let isValid = sut.isValid

        // Then
        XCTAssertTrue(isValid, "Valid email should pass validation")
    }

    // Test: Invalid email fails validation
    func testEmailValidation_Invalid() {
        // Given
        sut.email = "invalid.com"  // Missing @

        // When
        let isValid = sut.isValid

        // Then
        XCTAssertFalse(isValid, "Invalid email should fail validation")
    }

    // Test: Display name returns first name only
    func testDisplayName_FullName() {
        // Given
        sut.name = "John Doe"

        // When
        let displayName = sut.displayName

        // Then
        XCTAssertEqual(displayName, "John", "Display name should be first name only")
    }

    // Test: Initials are correctly generated
    func testInitials_FullName() {
        // Given
        sut.name = "John Doe"

        // When
        let initials = sut.initials

        // Then
        XCTAssertEqual(initials, "JD", "Initials should be JD")
    }

    // Test: Update profile changes name and timestamp
    func testUpdateProfile_Name() {
        // Given
        let originalUpdatedAt = sut.updatedAt
        sleep(1)  // Ensure timestamp changes

        // When
        sut.updateProfile(name: "Jane Doe")

        // Then
        XCTAssertEqual(sut.name, "Jane Doe")
        XCTAssertNotEqual(sut.updatedAt, originalUpdatedAt, "updatedAt should change")
    }

    // Test: Codable encoding produces valid JSON
    func testCodable_Encoding() throws {
        // Given: User from setUp

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(sut)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["name"] as? String, "Test User")
        XCTAssertEqual(json?["email"] as? String, "test@example.com")
        XCTAssertNotNil(json?["id"])
    }
}
```

**Repeat for all models**: Item, Category, etc.

---

#### Test Suite: Item Model

[Similar structure for ItemTests.swift]

**Key Test Cases**:
- Initialization
- Validation (title not empty, description not empty)
- Status updates
- Relationships (owner, category)
- Codable conformance

---

### 2.2 ViewModel Tests

Test all ViewModels from IMPLEMENTATION_GUIDE.

#### Test Suite: HomeViewModel

**File**: `[AppName]Tests/ViewModelTests/HomeViewModelTests.swift`

| Test Case | Mock Setup | Action | Expected Result | Priority |
|-----------|------------|--------|-----------------|----------|
| testInitialState | New ViewModel | None | items empty, isLoading false, showError false | P0 |
| testLoadItems_Success | Mock API returns 3 items | Call loadItems() | isLoading becomes false, items count = 3, no error | P0 |
| testLoadItems_Failure | Mock API throws error | Call loadItems() | isLoading false, showError true, errorMessage set | P0 |
| testLoadItems_EmptyResponse | Mock API returns empty array | Call loadItems() | items empty, no error | P1 |
| testRefresh | 3 items already loaded | Call refresh() | isLoading true then false, items refreshed | P1 |
| testDeleteItem_Success | 3 items loaded | Delete item[1] | items count = 2, deleted item removed | P0 |
| testDeleteItem_Failure | Mock API throws error on delete | Delete item | showError true, item not removed | P1 |
| testToggleItemStatus_Active | Item with status .active | toggleItemStatus(item) | item.status becomes .completed | P0 |
| testToggleItemStatus_Completed | Item with status .completed | toggleItemStatus(item) | item.status becomes .active | P0 |
| testSearchItems_MatchFound | 3 items, searchQuery = "Test" | Set searchQuery | items filtered to matching only | P1 |
| testSearchItems_NoMatch | 3 items, searchQuery = "XYZ" | Set searchQuery | items empty | P1 |
| testSearchItems_EmptyQuery | searchQuery was "Test" | Set searchQuery = "" | All items shown again | P1 |
| testLoadItems_LocalFirst | Mock delays API response | Call loadItems() | Local items shown immediately, then synced | P2 |

**Implementation Example**:

```swift
import XCTest
@testable import [AppName]

final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var mockAPIClient: MockAPIClient!
    var mockDataManager: MockDataManager!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        mockDataManager = MockDataManager()
        sut = HomeViewModel(
            apiClient: mockAPIClient,
            dataManager: mockDataManager
        )
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        mockDataManager = nil
        super.tearDown()
    }

    // Test: Initial state is correct
    @MainActor
    func testInitialState() {
        // Then
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showError)
        XCTAssertTrue(sut.searchQuery.isEmpty)
    }

    // Test: Loading items succeeds
    @MainActor
    func testLoadItems_Success() async {
        // Given
        let mockItems = [
            Item(title: "Item 1", description: "Desc 1", owner: mockUser()),
            Item(title: "Item 2", description: "Desc 2", owner: mockUser()),
            Item(title: "Item 3", description: "Desc 3", owner: mockUser())
        ]
        mockDataManager.itemsToReturn = mockItems
        mockAPIClient.itemsToReturn = mockItems

        // When
        await sut.loadItems()

        // Then
        XCTAssertEqual(sut.items.count, 3)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showError)
    }

    // Test: Loading items handles error
    @MainActor
    func testLoadItems_Failure() async {
        // Given
        mockDataManager.shouldThrowError = true

        // When
        await sut.loadItems()

        // Then
        XCTAssertTrue(sut.showError)
        XCTAssertFalse(sut.errorMessage.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    // Test: Deleting item succeeds
    @MainActor
    func testDeleteItem_Success() async {
        // Given
        let mockItems = [
            Item(title: "Item 1", description: "Desc 1", owner: mockUser()),
            Item(title: "Item 2", description: "Desc 2", owner: mockUser())
        ]
        mockDataManager.itemsToReturn = mockItems
        await sut.loadItems()
        let itemToDelete = sut.items[0]

        // When
        await sut.deleteItem(itemToDelete)

        // Then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertFalse(sut.items.contains(where: { $0.id == itemToDelete.id }))
    }

    // Test: Toggle item status changes status
    @MainActor
    func testToggleItemStatus_ActiveToCompleted() async {
        // Given
        let item = Item(title: "Test", description: "Desc", owner: mockUser())
        item.status = .active
        mockDataManager.itemsToReturn = [item]
        await sut.loadItems()

        // When
        await sut.toggleItemStatus(item)

        // Then
        XCTAssertEqual(item.status, .completed)
    }

    // Helper: Create mock user
    private func mockUser() -> User {
        return User(name: "Mock User", email: "mock@test.com")
    }
}

// MARK: - Mock APIClient

class MockAPIClient: APIClient {
    var itemsToReturn: [Item] = []
    var shouldThrowError = false

    override func get<T: Decodable>(_ endpoint: String) async throws -> T {
        if shouldThrowError {
            throw APIError.serverError(500)
        }
        return itemsToReturn as! T
    }

    override func delete<T: Decodable>(_ endpoint: String) async throws -> T {
        if shouldThrowError {
            throw APIError.serverError(500)
        }
        return EmptyResponse() as! T
    }
}

// MARK: - Mock DataManager

class MockDataManager: DataManager {
    var itemsToReturn: [Item] = []
    var shouldThrowError = false

    override func fetch<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) throws -> [T] {
        if shouldThrowError {
            throw DataManagerError.fetchFailed(NSError(domain: "test", code: 1))
        }
        return itemsToReturn as! [T]
    }

    override func delete<T: PersistentModel>(_ model: T) throws {
        if shouldThrowError {
            throw DataManagerError.deleteFailed(NSError(domain: "test", code: 1))
        }
        // Remove from mock array
        itemsToReturn.removeAll { ($0 as AnyObject) === (model as AnyObject) }
    }
}
```

**Repeat for all ViewModels**: ItemDetailViewModel, AddEditItemViewModel, SettingsViewModel, etc.

---

### 2.3 Service Tests

Test API client, DataManager, and other services.

#### Test Suite: APIClient

**Key Test Cases**:
- Successful GET request
- Successful POST request with body
- 401 Unauthorized error handling
- 404 Not Found error handling
- 500 Server error handling
- Network timeout handling
- JSON decoding error handling
- Invalid URL handling

#### Test Suite: DataManager

**Key Test Cases**:
- Create model instance
- Fetch all instances
- Fetch with predicate filter
- Fetch by ID
- Update model instance
- Delete model instance
- Delete all instances
- Specialized queries (fetchItems(byStatus:), searchItems(query:))

---

## 3. Integration Test Cases

Test multiple components working together.

### 3.1 Data Persistence Integration

| Test Case | Setup | Action | Expected Result | Priority |
|-----------|-------|--------|-----------------|----------|
| testSaveAndFetch | Empty database | Create user, save, fetch all | User retrieved successfully | P0 |
| testUpdateAndFetch | User in database | Modify user, save, fetch | Changes persisted | P0 |
| testDeleteAndFetch | User in database | Delete user, fetch all | User no longer exists | P0 |
| testRelationshipCascade | User with 3 items | Delete user | All items also deleted | P0 |
| testQueryWithPredicate | 5 items (2 active, 3 completed) | Fetch active only | Returns 2 items | P1 |

### 3.2 API Integration

| Test Case | Setup | Action | Expected Result | Priority |
|-----------|-------|--------|-----------------|----------|
| testFetchItems_APIToDatabase | Empty database, mock API returns 3 items | Call fetchItems() | 3 items saved to database | P0 |
| testCreateItem_DatabaseToAPI | Mock API | Create item locally, sync | POST request sent to API | P0 |
| testSyncConflict | Local and remote modified same item | Sync | Conflict resolved (last write wins) | P1 |
| testOfflineMode | No network | Create item locally | Item saved locally, queued for sync | P0 |
| testOnlineRestore | Previously offline | Network restored | Queued items synced to API | P1 |

---

## 4. UI Test Cases

Test end-to-end user journeys with XCUITest.

### 4.1 Critical User Journey 1: Onboarding and First Item Creation

**Priority**: P0 (Must pass before release)
**Estimated Duration**: 30 seconds
**Frequency**: Run on every release candidate

| Step | User Action | Expected UI State | Assertions | Priority |
|------|-------------|-------------------|------------|----------|
| 1 | Launch app (first time) | Welcome screen shown | "Welcome to [AppName]" exists, "Get Started" button exists | P0 |
| 2 | Tap "Get Started" button | Registration screen shown | Email and name fields visible, "Continue" button exists | P0 |
| 3 | Enter name: "Test User" | Name field populated | Name field value = "Test User" | P0 |
| 4 | Enter email: "test@example.com" | Email field populated | Email field value = "test@example.com" | P0 |
| 5 | Tap "Continue" button | Onboarding Step 1 shown | Progress dots visible, skip button visible, next button exists | P0 |
| 6 | Swipe left (or tap Next) | Onboarding Step 2 shown | Different content shown, progress indicator updated | P1 |
| 7 | Tap "Skip" button | Home screen shown with empty state | "No Items Yet" message visible, "+" button in navbar | P0 |
| 8 | Tap "+" button in navbar | Add Item sheet presented | Title field, description field, save button visible | P0 |
| 9 | Enter title: "My First Item" | Title populated | Title field value = "My First Item" | P0 |
| 10 | Enter description: "Test description" | Description populated | Description field value = "Test description" | P0 |
| 11 | Tap "Save" button | Sheet dismissed, Home screen shown | Item appears in list with title "My First Item" | P0 |
| 12 | Verify item visible | Item card visible in list | Card contains "My First Item" and "Test description" | P0 |

**Implementation**:

```swift
import XCTest

final class OnboardingUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Reset app to first-time user state
        app.launchArguments = ["--uitesting", "--reset"]
        app.launch()
    }

    func testOnboardingAndFirstItemCreation() throws {
        // Step 1: Verify welcome screen
        let welcomeTitle = app.staticTexts["Welcome to [AppName]"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 2))

        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists)

        // Step 2: Tap Get Started
        getStartedButton.tap()

        // Step 3-4: Fill registration
        let nameField = app.textFields["Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Test User")

        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")

        // Step 5: Continue to onboarding
        app.buttons["Continue"].tap()

        // Verify onboarding screen
        XCTAssertTrue(app.staticTexts["Onboarding Step 1"].waitForExistence(timeout: 2))

        // Step 7: Skip onboarding
        app.buttons["Skip"].tap()

        // Step 8: Verify Home empty state
        let emptyStateMessage = app.staticTexts["No Items Yet"]
        XCTAssertTrue(emptyStateMessage.waitForExistence(timeout: 2))

        // Step 9: Tap + button
        let addButton = app.navigationBars.buttons["Add Item"]
        XCTAssertTrue(addButton.exists)
        addButton.tap()

        // Step 10-11: Fill add item form
        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 2))
        titleField.tap()
        titleField.typeText("My First Item")

        let descriptionField = app.textViews["Description"]
        descriptionField.tap()
        descriptionField.typeText("Test description")

        // Step 12: Save
        app.buttons["Save"].tap()

        // Step 13: Verify item appears
        let itemCard = app.staticTexts["My First Item"]
        XCTAssertTrue(itemCard.waitForExistence(timeout: 3))

        // Verify subtitle
        let subtitle = app.staticTexts["Test description"]
        XCTAssertTrue(subtitle.exists)
    }
}
```

---

### 4.2 Critical User Journey 2: View and Edit Item

[Similar detailed test case with steps, assertions, and implementation]

### 4.3 Critical User Journey 3: Delete Item

[Similar structure]

### 4.4 Critical User Journey 4: Search Items

[Similar structure]

---

## 5. Accessibility Testing

### 5.1 VoiceOver Testing

**Manual Test Cases**:

| Screen | Element | Expected VoiceOver Label | Expected Behavior | Priority |
|--------|---------|-------------------------|-------------------|----------|
| Home | Add button | "Add new item, button" | Announces label, tapping activates button | P0 |
| Home | Item card | "[Item title], [subtitle], [status], button" | Announces all relevant info, tapping navigates | P0 |
| Home | Search field | "Search items, search field" | Announces hint, typing works | P1 |
| Detail | Edit button | "Edit item, button" | Clear action announced | P0 |
| Add/Edit | Title field | "Title, text field, required" | Indicates required field | P0 |
| Add/Edit | Save button | "Save item, button" | Clear action, disabled state announced | P0 |
| Settings | Toggle | "Notifications, on, toggle switch" | State announced, double-tap toggles | P1 |

**Automated VoiceOver Tests**:

```swift
func testVoiceOverLabels() {
    // Enable accessibility features
    app.launchArguments += ["-UIAccessibilitySpeakScreenEnabled", "1"]
    app.launch()

    // Navigate to Home
    let addButton = app.buttons["Add Item"]
    XCTAssertEqual(addButton.label, "Add new item")
    XCTAssertTrue(addButton.isAccessibilityElement)

    // Check item card
    let itemCard = app.buttons.matching(identifier: "ItemCard").firstMatch
    XCTAssertTrue(itemCard.label.contains("Item title"))
    XCTAssertTrue(itemCard.isAccessibilityElement)
}
```

### 5.2 Dynamic Type Testing

**Test Cases**:

| Size | Expected Behavior | Pass Criteria | Priority |
|------|-------------------|---------------|----------|
| Extra Small (XS) | All text readable, buttons not truncated | No overlap, all elements visible | P1 |
| Default | Standard layout | Reference design | P0 |
| Extra Large (XL) | Text larger, layout adjusts | Scrollable, no truncation | P0 |
| Accessibility XXL | Text very large, stacked layout | Fully readable, scrollable | P1 |

**Test Implementation**:

```swift
func testDynamicType_ExtraLarge() {
    // Set large text size
    app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
    app.launch()

    // Verify text is not truncated
    let title = app.staticTexts["Item Title"]
    XCTAssertTrue(title.exists)
    XCTAssertFalse(title.label.hasSuffix("..."), "Text should not be truncated")

    // Verify buttons are still tappable
    let addButton = app.buttons["Add Item"]
    XCTAssertTrue(addButton.exists)
    XCTAssertGreaterThan(addButton.frame.height, 44, "Button should be at least 44pt tall")
}
```

### 5.3 Color Contrast Testing

**Automated Checks**:

| Element | Foreground | Background | Ratio | WCAG AA Pass | Priority |
|---------|------------|------------|-------|--------------|----------|
| Primary button text | #FFFFFF | #007AFF | 4.5:1+ | ✅ Yes | P0 |
| Body text | #000000 | #FFFFFF | 21:1 | ✅ Yes | P0 |
| Secondary text | #3C3C43 (60%) | #FFFFFF | 4.6:1 | ✅ Yes | P0 |
| Link text | #007AFF | #FFFFFF | 4.5:1+ | ✅ Yes | P0 |

**Tool**: Xcode Accessibility Inspector → Color Contrast

---

## 6. Performance Testing

### 6.1 Performance Benchmarks

| Metric | Target | Measurement Method | Priority |
|--------|--------|-------------------|----------|
| App launch time (cold) | < 1.5s | XCTest measure block | P0 |
| App launch time (warm) | < 0.5s | XCTest measure block | P1 |
| Home screen load | < 500ms | Time to first content | P0 |
| Scroll FPS | 60 fps | Instruments (Core Animation) | P0 |
| Memory usage (idle) | < 50MB | Instruments (Allocations) | P1 |
| Memory usage (active) | < 150MB | Instruments (Allocations) | P1 |
| Network request time | < 2s (95th percentile) | Analytics | P1 |

**Test Implementation**:

```swift
func testLaunchPerformance() {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        app.launch()
    }
    // Xcode will report average launch time
}

func testHomeScreenLoadPerformance() {
    app.launch()

    measure {
        // Navigate to Home
        app.tabBars.buttons["Home"].tap()

        // Wait for content
        _ = app.tables.cells.firstMatch.waitForExistence(timeout: 5)
    }
}
```

### 6.2 Load Testing

| Scenario | Data Volume | Expected Behavior | Pass Criteria | Priority |
|----------|-------------|-------------------|---------------|----------|
| Large list | 1000 items | Smooth scrolling, no lag | 60 fps maintained | P1 |
| Heavy images | 50 high-res images | Progressive loading | No memory warnings | P1 |
| Large search | Search in 1000 items | Results in < 1s | Fast filtering | P2 |
| Rapid scrolling | Scroll 100 items quickly | No crashes, smooth | No dropped frames | P1 |

---

## 7. Edge Cases & Error Scenarios

### 7.1 Network Conditions

| Condition | User Action | Expected Behavior | Verification | Priority |
|-----------|-------------|-------------------|--------------|----------|
| No network (airplane mode) | Launch app | Cached data shown, offline banner | Data visible, banner "No internet connection" | P0 |
| No network | Tap refresh | Error message, cached data remains | "Can't refresh. Check connection." | P0 |
| Slow network (3G) | Load items | Loading indicator, timeout after 30s | Spinner shows, then timeout message | P1 |
| Network timeout | API call exceeds 30s | Timeout error, graceful fallback | "Request timed out. Try again." | P1 |
| Network restored | Was offline, now online | Auto-sync, banner dismissed | Data refreshes, "Back online" toast | P1 |
| Intermittent connection | Random disconnects | Retry with exponential backoff | Eventually succeeds or clear error | P2 |

**Test with**: Settings → Developer → Network Link Conditioner

### 7.2 Data Validation

| Invalid Input | User Action | Expected Behavior | Verification | Priority |
|---------------|-------------|-------------------|--------------|----------|
| Empty required field | Tap Save with empty title | Error message, save disabled | Red outline, "Title is required" | P0 |
| Invalid email format | Enter "invalid.com" | Inline error shown | "Please enter a valid email" | P0 |
| Too long input | Enter 500 character title | Character limit enforced | Max 150 chars, counter shows "150/150" | P1 |
| Special characters | Enter "Item <script>" in title | Sanitized or rejected | No script execution, saved safely | P0 |
| Duplicate entry | Create item with existing title | Warning shown, allow override | "Item exists. Continue?" | P1 |
| Invalid date | Select date in past (if not allowed) | Error shown, date reset | "Date must be in future" | P1 |

### 7.3 Permission Handling

| Permission | Denied State | User Action | Expected Behavior | Priority |
|------------|--------------|-------------|-------------------|----------|
| Camera | Denied | Tap "Add Photo" | Alert: "Camera access needed. Open Settings?" | P0 |
| Camera | Denied | User opens Settings | Deep link to app settings | P1 |
| Photos | Denied | Tap "Choose Photo" | Photo picker not shown, request permission | P0 |
| Notifications | Denied | App needs to notify | App works without notifications | P1 |
| Location | Denied | Feature requires location | Feature disabled, explanation shown | P1 |

### 7.4 Device Conditions

| Condition | Expected Behavior | Verification | Priority |
|-----------|-------------------|--------------|----------|
| Low battery mode | Reduced animations, background tasks paused | Respects system setting | P1 |
| Low storage | Can't save images | Error: "Not enough storage" | P1 |
| Rotation (if supported) | Layout adapts | No clipping, all elements visible | P1 |
| Multitasking (iPad) | App works in split view | Responsive layout | P2 |
| Background mode | App suspended, returns | State preserved | P0 |
| App killed by system | Force quit, relaunch | State restored from last save | P0 |

---

## 8. Security Testing

### 8.1 Data Security

| Test | Action | Expected Result | Priority |
|------|--------|-----------------|----------|
| Keychain storage | Store auth token | Token encrypted in Keychain | P0 |
| API token exposure | Inspect network traffic | Token in Authorization header only | P0 |
| Sensitive data logging | Check console logs | No passwords/tokens logged | P0 |
| Screenshot protection | App contains sensitive data | Blur/hide when app switching | P1 |

### 8.2 Privacy

| Test | Action | Expected Result | Priority |
|------|--------|-----------------|----------|
| Privacy manifest | Check PrivacyInfo.xcprivacy | All data collection disclosed | P0 |
| Third-party SDKs | Inspect network requests | No unexpected tracking | P0 |
| Data export | User requests data | All data provided in readable format | P1 |
| Account deletion | User deletes account | All data removed from server | P0 |

---

## 9. Regression Testing

Run before every release to ensure new changes don't break existing functionality.

### 9.1 Smoke Test Checklist

**Duration**: 15 minutes
**Frequency**: Every build

- [ ] App launches without crash
- [ ] Login/registration works
- [ ] Home screen loads
- [ ] Can create new item
- [ ] Can view item detail
- [ ] Can edit item
- [ ] Can delete item
- [ ] Search works
- [ ] Settings accessible
- [ ] Can log out

### 9.2 Full Regression Suite

**Duration**: 2 hours
**Frequency**: Every release candidate

- [ ] All P0 unit tests pass (100%)
- [ ] All P0 UI tests pass (100%)
- [ ] All critical user journeys tested manually
- [ ] Accessibility audit passed (VoiceOver, Dynamic Type)
- [ ] Performance benchmarks met
- [ ] No memory leaks (Instruments check)
- [ ] Network error scenarios tested
- [ ] Edge cases from Section 7 verified
- [ ] Security checklist completed
- [ ] Privacy manifest up to date

---

## 10. Beta Testing (TestFlight)

### 10.1 Beta Test Plan

**Participants**: 20-50 external beta testers
**Duration**: 2 weeks before App Store submission
**Platforms**: iPhone (all sizes), iPad (if supported)
**iOS Versions**: iOS 17.0 - latest

**Recruitment**:
- Internal team members
- Trusted users from target audience
- Mix of tech-savvy and average users
- Geographic diversity (if localized)

**Feedback Collection**:
1. **In-app feedback form**: Button in Settings → "Send Feedback"
2. **TestFlight feedback**: Native TestFlight feedback
3. **Crash reports**: Automatically collected
4. **Survey**: Email survey after 1 week of use

### 10.2 Beta Testing Focus Areas

**Week 1: Functionality Testing**
- [ ] All features work as expected
- [ ] No critical bugs
- [ ] Performance is acceptable
- [ ] UI/UX is intuitive

**Week 2: Real-World Usage**
- [ ] App fits into users' workflow
- [ ] Identify missing features
- [ ] Collect feature requests
- [ ] Assess onboarding clarity

### 10.3 Beta Success Criteria

**Before proceeding to App Store submission**:
- [ ] Crash-free rate > 99.5%
- [ ] Average rating from beta testers > 4.0/5.0
- [ ] No P0 bugs reported in last 3 days
- [ ] All critical feedback addressed or planned for v1.1
- [ ] At least 75% of testers completed onboarding
- [ ] At least 50% of testers used app 3+ times

**Feedback Analysis**:
- Categorize feedback: bug, feature request, UX issue, question
- Prioritize: P0 (fix before launch), P1 (fix in v1.1), P2 (backlog)
- Track resolution: open, in progress, fixed, won't fix

---

## 11. Test Automation

### 11.1 CI/CD Integration

**Platform**: Xcode Cloud / GitHub Actions / Fastlane
**Trigger**: On every pull request and merge to main

**Pipeline**:
```yaml
name: iOS CI

on: [pull_request, push]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Select Xcode version
        run: sudo xcode-select -s /Applications/Xcode_15.0.app

      - name: Run SwiftLint
        run: swiftlint lint --strict

      - name: Build
        run: |
          xcodebuild clean build \
            -scheme [AppName] \
            -destination 'platform=iOS Simulator,name=iPhone 15'

      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -scheme [AppName] \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:[AppName]Tests

      - name: Run UI Tests
        run: |
          xcodebuild test \
            -scheme [AppName] \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -only-testing:[AppName]UITests

      - name: Generate Code Coverage
        run: |
          xcodebuild test \
            -scheme [AppName] \
            -enableCodeCoverage YES \
            -derivedDataPath ./DerivedData

      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
```

### 11.2 Test Reports

**Generate HTML test report**:
```bash
xcodebuild test \
  -scheme [AppName] \
  -resultBundlePath TestResults.xcresult

xcrun xcresulttool get --format html TestResults.xcresult > test-report.html
```

**Code Coverage Report**:
- Target: 80%+ overall coverage
- Critical paths: 95%+ coverage (authentication, data persistence)
- View in Xcode: Product → Show Code Coverage

---

## 12. Bug Tracking

### 12.1 Bug Report Template

**File in issue tracker** (GitHub Issues, Jira, etc.):

```markdown
**Title**: [Concise, descriptive bug title]

**Severity**: Critical / High / Medium / Low

**Priority**: P0 / P1 / P2 / P3

**Affected Version**: 1.0.0

**Environment**:
- Device: iPhone 15 Pro
- iOS Version: 17.5
- App Version: 1.0.0 (Build 42)

**Steps to Reproduce**:
1. Launch app
2. Navigate to Home
3. Tap on item "Test Item"
4. Observe crash

**Expected Behavior**:
Item detail screen should open without crash.

**Actual Behavior**:
App crashes immediately when tapping item.

**Screenshots/Videos**:
[Attach if available]

**Crash Logs**:
```
[Paste crash log from Xcode Organizer]
```

**Additional Context**:
Happens only with items that have nil thumbnailURL.

**Possible Fix**:
Add nil check in ItemDetailView line 47.
```

### 12.2 Bug Severity Definitions

**Critical (P0)**:
- App crashes on launch
- Data loss
- Security vulnerability
- Cannot complete core user flow
- Fix immediately, hotfix if needed

**High (P1)**:
- Feature completely broken
- Frequent crashes (> 1% of sessions)
- Major UI issues
- Fix before next release

**Medium (P2)**:
- Feature partially broken
- Rare crashes (< 0.1% of sessions)
- Minor UI issues
- Workaround exists
- Fix in next minor update

**Low (P3)**:
- Cosmetic issues
- Feature enhancement
- Edge case issues
- Fix when convenient

---

## 13. Post-Launch Monitoring

### 13.1 Metrics to Track

**Crash Analytics** (Xcode Organizer, Firebase Crashlytics):
- Crash-free rate: Target > 99.5%
- Top crashes by volume
- Crash trends over time

**Performance Monitoring**:
- App launch time: p50, p95, p99
- Screen load time
- API response time
- Memory usage

**Usage Analytics** (App Analytics, Firebase Analytics):
- Daily/Monthly Active Users (DAU/MAU)
- Session length
- Session frequency
- Feature usage rates
- Funnel completion rates

**App Store Metrics**:
- Rating: Target > 4.5 stars
- Reviews: Respond to all reviews
- Download trends
- Conversion rate (impressions → downloads)

**User Feedback**:
- Support ticket volume
- Common complaints
- Feature requests
- Positive feedback themes

### 13.2 Alerting Thresholds

**Critical Alerts** (Page immediately):
- Crash rate > 1%
- App Store rating drops below 3.0
- API error rate > 5%
- Server downtime

**High Priority Alerts** (Check within 1 hour):
- Crash rate > 0.5%
- App Store rating drops below 4.0
- API error rate > 2%
- Support ticket spike

**Medium Priority** (Check daily):
- Crash rate > 0.1%
- Feature usage < 10% of users (for key features)
- Session length decreasing trend

---

## 14. Test Documentation

### 14.1 Test Case Format

Each test case should document:
- **ID**: TC-001
- **Feature**: Feature name from PRD
- **Priority**: P0/P1/P2
- **Type**: Unit/Integration/UI/Manual
- **Preconditions**: State before test
- **Steps**: Numbered steps
- **Expected Result**: Clear pass criteria
- **Actual Result**: Filled after execution
- **Status**: Pass/Fail/Blocked
- **Notes**: Any observations

### 14.2 Test Execution Tracking

**Test Run Spreadsheet**:

| ID | Test Case | Priority | Type | Status | Notes | Date | Tester |
|----|-----------|----------|------|--------|-------|------|--------|
| TC-001 | User login success | P0 | UI | Pass | | 2024-01-15 | QA |
| TC-002 | User login invalid email | P0 | UI | Pass | | 2024-01-15 | QA |
| TC-003 | Create item success | P0 | UI | Fail | Crash on save | 2024-01-15 | QA |

**Test Coverage Matrix**:

| Feature (PRD) | Unit Tests | Integration Tests | UI Tests | Manual Tests | Coverage % |
|---------------|------------|-------------------|----------|--------------|------------|
| User registration | 12/12 ✅ | 3/3 ✅ | 2/2 ✅ | 5/5 ✅ | 100% |
| Item CRUD | 20/20 ✅ | 5/5 ✅ | 8/10 ⚠️ | 10/10 ✅ | 90% |
| Search | 8/8 ✅ | 2/2 ✅ | 3/3 ✅ | 3/3 ✅ | 100% |

---

## 15. Release Readiness Checklist

Before submitting to App Store:

### 15.1 Testing Complete
- [ ] All P0 unit tests pass (100%)
- [ ] All P1 unit tests pass (> 95%)
- [ ] All P0 UI tests pass (100%)
- [ ] No P0 bugs open
- [ ] No P1 bugs open (or accepted as known issues)
- [ ] Code coverage > 80%
- [ ] Performance benchmarks met
- [ ] Memory leaks checked (0 leaks)
- [ ] Accessibility audit passed
- [ ] Security audit passed

### 15.2 Manual Testing
- [ ] Full regression suite completed
- [ ] All critical user journeys tested on real devices
- [ ] Tested on iPhone SE (smallest screen)
- [ ] Tested on iPhone Pro Max (largest screen)
- [ ] Tested on iPad (if supported)
- [ ] Tested on iOS 17.0 (minimum version)
- [ ] Tested on latest iOS version
- [ ] Dark mode tested
- [ ] Localization tested (all supported languages)

### 15.3 Beta Testing
- [ ] TestFlight beta completed (2 weeks)
- [ ] Crash-free rate > 99.5%
- [ ] Beta tester rating > 4.0/5.0
- [ ] All critical beta feedback addressed
- [ ] No new crashes in last 48 hours

### 15.4 Final Checks
- [ ] App Store assets ready (from RELEASE_SPEC)
- [ ] Privacy manifest accurate
- [ ] App Store guidelines compliance verified
- [ ] Legal review completed (terms, privacy policy)
- [ ] Marketing materials ready
- [ ] Support infrastructure ready (email, FAQ)

---

## Appendix A: Test Data

### A.1 Test Users

```json
{
  "valid_user": {
    "name": "Test User",
    "email": "test@example.com",
    "password": "Password123!"
  },
  "invalid_email": {
    "name": "Invalid",
    "email": "invalid.com",
    "password": "Password123!"
  },
  "empty_fields": {
    "name": "",
    "email": "",
    "password": ""
  }
}
```

### A.2 Test Items

```json
{
  "valid_item": {
    "title": "Test Item",
    "description": "This is a test description",
    "status": "active"
  },
  "long_title": {
    "title": "[150 character string...]",
    "description": "Normal description",
    "status": "active"
  },
  "special_chars": {
    "title": "Item with <script>alert('XSS')</script>",
    "description": "Testing sanitization",
    "status": "active"
  }
}
```

---

## Appendix B: Glossary

- **P0**: Critical priority - must be fixed before release
- **P1**: High priority - should be fixed before release
- **P2**: Medium priority - can be deferred to next release
- **P3**: Low priority - backlog
- **SUT**: System Under Test
- **Mock**: Simulated object for testing
- **Stub**: Predefined test data
- **Regression**: Re-testing to ensure new changes don't break existing functionality
- **Smoke Test**: Quick test of basic functionality
- **Sanity Test**: Quick test after bug fix to verify it's resolved
- **Coverage**: Percentage of code executed by tests

---

**Document History**:
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | [Date] | QA Engineer AI | Initial test specification created |
```

---

## Execution Instructions

When activated, follow these steps:

1. **Read All Specification Documents**
   ```
   - Read docs/PRD.md (features, acceptance criteria, user stories)
   - Read docs/IMPLEMENTATION_GUIDE.md (all ViewModels, models, services)
   - Read docs/UX_SPEC.md (all screens, user flows, states)
   - Read docs/ARCHITECTURE.md (testing strategy)
   ```

2. **Extract Testing Requirements**
   - List all features to test (from PRD)
   - List all ViewModels to unit test (from IMPLEMENTATION_GUIDE)
   - List all models to unit test
   - List all user flows to UI test (from UX_SPEC)
   - Identify edge cases from UX_SPEC error states

3. **Generate Unit Test Cases**
   - For each Model: test initialization, validation, methods, relationships, Codable
   - For each ViewModel: test loading, errors, user actions, state management
   - For each Service: test API calls, error handling, data operations

4. **Generate Integration Test Cases**
   - Database + API sync
   - ViewModel + Service integration
   - Multi-component workflows

5. **Generate UI Test Cases**
   - Critical user journeys (from PRD P0 features)
   - Include all steps with assertions
   - Provide complete XCUITest implementation

6. **Generate Accessibility Tests**
   - VoiceOver labels for all interactive elements
   - Dynamic Type scenarios
   - Color contrast checks

7. **Generate Performance Tests**
   - Launch time benchmarks
   - Load testing scenarios
   - Memory usage targets

8. **Document Edge Cases**
   - Network conditions (offline, slow, timeout)
   - Data validation (empty, invalid, too long)
   - Permission handling (denied, restricted)
   - Device conditions (low battery, low storage)

9. **Create Beta Testing Plan**
   - Participant criteria
   - Duration and timeline
   - Feedback collection methods
   - Success criteria

10. **Write Complete Test Spec**
    ```
    Write to: docs/TEST_SPEC.md
    Target length: 2000-3000 lines
    Format: Markdown with code examples
    ```

11. **Present Summary**
    ```
    ✅ Test Specification generated!

    🧪 **Test Spec Summary**:
    - Unit test cases: [X] tests across [Y] test suites
    - Integration test cases: [Z] scenarios
    - UI test cases: [N] critical user journeys with full implementation
    - Accessibility tests: VoiceOver, Dynamic Type, Contrast
    - Performance benchmarks: Launch time, memory, FPS
    - Edge cases documented: [M] scenarios
    - Beta testing plan: 2-week plan with [P] participants

    **Coverage**:
    - All features from PRD have test cases
    - All ViewModels have unit tests
    - All critical flows have UI tests
    - Accessibility fully covered
    - Performance targets defined

    **Next Steps**:
    1. Review test cases in docs/TEST_SPEC.md
    2. Implement unit tests as development progresses
    3. Set up CI/CD pipeline for automated testing
    4. Execute manual test cases before release
    5. Run beta test program via TestFlight

    **Developer can now**:
    - Write tests alongside implementation
    - Achieve 80%+ code coverage
    - Ensure all features are tested
    - Catch bugs before release

    Ready to proceed to release specification?
    ```

12. **Iterate Based on Feedback**
    If user requests changes:
    - Add missing test cases
    - Expand specific areas (e.g., more edge cases)
    - Provide more implementation examples
    - Adjust priorities

---

## Quality Guidelines

1. **Be Comprehensive**: Cover every feature from PRD
   - Unit tests for all business logic
   - UI tests for all critical flows
   - Integration tests for key workflows
   - Edge cases for all error scenarios

2. **Be Specific**: Test cases must be actionable
   - Clear steps
   - Clear expected results
   - Clear pass/fail criteria
   - Include test data

3. **Provide Code Examples**: Not just test case descriptions
   - Show complete XCTest implementations
   - Show XCUITest implementations
   - Show mock objects
   - Show test setup/teardown

4. **Think Like QA**: What could go wrong?
   - Empty states
   - Invalid inputs
   - Network failures
   - Permission denials
   - Edge cases

5. **Consider Real Users**: Beta testing is crucial
   - Real devices, real usage patterns
   - Diverse user base
   - Real-world network conditions
   - Actual user feedback

6. **Enable Automation**: CI/CD integration
   - Tests should run automatically
   - Fast feedback loop
   - Code coverage tracking
   - Fail fast on critical issues

---

## Integration with Workflow

This skill is typically:
- **Fifth step** in specification generation
- Activated after PRD, Architecture, UX, and Implementation Guide are complete
- Followed by release-spec
- Critical for ensuring quality before App Store submission

The test specification ensures the app works correctly and provides confidence for release.

---

## Notes

- Every feature in PRD must have corresponding test cases
- Test early, test often - don't wait until the end
- Automated tests save time in the long run
- Manual testing still crucial for UX validation
- Beta testing provides real-world feedback
- Bug tracking is part of the testing process
- Performance and accessibility are not optional
- Security testing must be thorough
- Document all test cases for repeatability
