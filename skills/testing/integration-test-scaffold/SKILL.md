---
name: integration-test-scaffold
description: Generate cross-module test harness with mock servers, in-memory stores, and test configuration. Use when testing networking + persistence + business logic together.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Integration Test Scaffold

Generate test infrastructure for testing multiple modules working together — networking + persistence + business logic — without hitting real servers or databases.

## When This Skill Activates

Use this skill when the user:
- Wants to "test the full stack" or "integration test"
- Needs a mock server or mock API
- Wants to test networking + caching together
- Asks about "end-to-end tests without real servers"
- Needs to test data flow across layers (API → Repository → ViewModel)
- Mentions "test harness" or "test environment"

## Why Integration Tests

```
Unit tests:         Test ONE thing in isolation (fast, focused)
Integration tests:  Test MULTIPLE things together (realistic, catches wiring bugs)

Unit test passes:   PriceCalculator works alone ✅
Integration test:   PriceCalculator + API + Cache work together ✅
                    (Catches: wrong data format, missing mapping, race conditions)
```

## Process

### Phase 1: Map the Integration Boundaries

Identify what modules interact:

```
Grep: "import |@testable import" to find module dependencies
Read: source files to understand data flow
```

Common integration boundaries:
- **Network → Parser → Repository** (API data flow)
- **Repository → ViewModel → View** (UI data flow)
- **UserAction → Service → Storage → Notification** (write flow)

### Phase 2: Configuration Questions

Ask via AskUserQuestion:

1. **What layers to integrate?**
   - Network + Repository
   - Repository + ViewModel
   - Full stack (Network → ViewModel)
   - Custom combination

2. **Mock strategy?**
   - URLProtocol-based mock server (intercepts real URLSession)
   - Protocol-based mock (swap implementation)
   - In-memory database (SwiftData/CoreData)

### Phase 3: Generate Mock Server

#### URLProtocol Mock Server

```swift
// Tests/Infrastructure/MockURLProtocol.swift

final class MockURLProtocol: URLProtocol {
    /// Map of URL path → (status code, response data)
    static var mockResponses: [String: (Int, Data)] = [:]
    /// Captured requests for verification
    static var capturedRequests: [URLRequest] = []
    /// Simulated delay
    static var responseDelay: TimeInterval = 0

    static func reset() {
        mockResponses = [:]
        capturedRequests = []
        responseDelay = 0
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true  // Intercept all requests
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.capturedRequests.append(request)

        let path = request.url?.path ?? ""
        let (statusCode, data) = Self.mockResponses[path] ?? (404, Data())

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        if Self.responseDelay > 0 {
            Thread.sleep(forTimeInterval: Self.responseDelay)
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
```

#### Mock Server Helper

```swift
// Tests/Infrastructure/MockServer.swift

struct MockServer {
    /// Register a successful JSON response for a path
    static func respondWith<T: Encodable>(
        _ value: T,
        for path: String,
        statusCode: Int = 200
    ) {
        let data = try! JSONEncoder().encode(value)
        MockURLProtocol.mockResponses[path] = (statusCode, data)
    }

    /// Register a raw data response
    static func respondWith(
        data: Data,
        for path: String,
        statusCode: Int = 200
    ) {
        MockURLProtocol.mockResponses[path] = (statusCode, data)
    }

    /// Register an error response
    static func respondWithError(
        for path: String,
        statusCode: Int = 500
    ) {
        let error = ["error": "Server Error"]
        let data = try! JSONEncoder().encode(error)
        MockURLProtocol.mockResponses[path] = (statusCode, data)
    }

    /// Create a URLSession configured to use mock responses
    static func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
```

### Phase 4: Generate In-Memory Store

#### SwiftData In-Memory

```swift
// Tests/Infrastructure/InMemoryModelContainer.swift

import SwiftData

enum TestModelContainer {
    @MainActor
    static func create(for types: any PersistentModel.Type...) -> ModelContainer {
        let schema = Schema(types)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: config)
    }
}

// Usage in tests:
@Test("saves and fetches items")
@MainActor
func savesAndFetches() async throws {
    let container = TestModelContainer.create(for: Item.self)
    let context = container.mainContext

    let item = Item(title: "Test")
    context.insert(item)
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<Item>())
    #expect(fetched.count == 1)
}
```

#### UserDefaults In-Memory

```swift
// Tests/Infrastructure/MockUserDefaults.swift

final class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]

    override func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }

    override func bool(forKey defaultName: String) -> Bool {
        storage[defaultName] as? Bool ?? false
    }

    override func string(forKey defaultName: String) -> String? {
        storage[defaultName] as? String
    }

    func reset() {
        storage.removeAll()
    }
}
```

### Phase 5: Generate Test Environment

#### Dependency Container for Tests

```swift
// Tests/Infrastructure/TestEnvironment.swift

@testable import YourApp

struct TestEnvironment {
    let session: URLSession
    let container: ModelContainer
    let defaults: MockUserDefaults
    let apiClient: APIClient
    let repository: ItemRepository
    let viewModel: ItemListViewModel

    @MainActor
    static func create() -> TestEnvironment {
        let session = MockServer.session()
        let container = TestModelContainer.create(for: Item.self)
        let defaults = MockUserDefaults()

        let apiClient = APIClient(session: session)
        let repository = ItemRepository(
            apiClient: apiClient,
            modelContext: container.mainContext
        )
        let viewModel = ItemListViewModel(repository: repository)

        return TestEnvironment(
            session: session,
            container: container,
            defaults: defaults,
            apiClient: apiClient,
            repository: repository,
            viewModel: viewModel
        )
    }
}
```

### Phase 6: Generate Integration Tests

#### Full Stack Test: API → Repository → ViewModel

```swift
import Testing
import SwiftData
@testable import YourApp

@Suite("Integration: Item Data Flow")
struct ItemDataFlowIntegrationTests {

    @Test("fetches items from API and displays in ViewModel")
    @MainActor
    func fetchAndDisplay() async throws {
        // Arrange
        MockURLProtocol.reset()
        let env = TestEnvironment.create()
        let items = [
            APIItem(id: "1", title: "First", description: "Desc 1"),
            APIItem(id: "2", title: "Second", description: "Desc 2")
        ]
        MockServer.respondWith(items, for: "/api/items")

        // Act
        await env.viewModel.loadItems()

        // Assert — verify end-to-end
        #expect(env.viewModel.items.count == 2)
        #expect(env.viewModel.items.first?.title == "First")
        #expect(env.viewModel.state == .loaded)
    }

    @Test("caches items and serves from cache when offline")
    @MainActor
    func cacheAndOffline() async throws {
        MockURLProtocol.reset()
        let env = TestEnvironment.create()

        // First load — from API
        MockServer.respondWith([APIItem(id: "1", title: "Cached")], for: "/api/items")
        await env.viewModel.loadItems()
        #expect(env.viewModel.items.count == 1)

        // Second load — API fails, should use cache
        MockServer.respondWithError(for: "/api/items")
        await env.viewModel.loadItems()
        #expect(env.viewModel.items.count == 1)
        #expect(env.viewModel.items.first?.title == "Cached")
    }

    @Test("saves item through full stack")
    @MainActor
    func saveFullStack() async throws {
        MockURLProtocol.reset()
        let env = TestEnvironment.create()
        MockServer.respondWith(APIItem(id: "new", title: "New Item"), for: "/api/items")

        // Act
        try await env.viewModel.addItem(title: "New Item")

        // Assert — saved to local store
        let descriptor = FetchDescriptor<Item>()
        let stored = try env.container.mainContext.fetch(descriptor)
        #expect(stored.count == 1)

        // Assert — API was called
        let postRequests = MockURLProtocol.capturedRequests.filter { $0.httpMethod == "POST" }
        #expect(postRequests.count == 1)
    }

    @Test("handles API error gracefully")
    @MainActor
    func apiErrorGraceful() async throws {
        MockURLProtocol.reset()
        let env = TestEnvironment.create()
        MockServer.respondWithError(for: "/api/items", statusCode: 500)

        await env.viewModel.loadItems()

        #expect(env.viewModel.state == .error)
        #expect(env.viewModel.items.isEmpty)
    }
}
```

#### Request Verification Tests

```swift
@Suite("Integration: API Request Formation")
struct APIRequestFormationTests {

    @Test("sends correct headers")
    @MainActor
    func correctHeaders() async throws {
        MockURLProtocol.reset()
        let env = TestEnvironment.create()
        MockServer.respondWith([APIItem](), for: "/api/items")

        await env.viewModel.loadItems()

        let request = MockURLProtocol.capturedRequests.first
        #expect(request?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request?.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("includes auth token in request")
    @MainActor
    func authToken() async throws {
        MockURLProtocol.reset()
        let env = TestEnvironment.create()
        env.defaults.set("test-token", forKey: "auth_token")
        MockServer.respondWith([APIItem](), for: "/api/items")

        await env.viewModel.loadItems()

        let request = MockURLProtocol.capturedRequests.first
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
    }
}
```

## File Structure

```
Tests/
├── Infrastructure/           # Shared test infrastructure
│   ├── MockURLProtocol.swift
│   ├── MockServer.swift
│   ├── TestModelContainer.swift
│   ├── MockUserDefaults.swift
│   └── TestEnvironment.swift
├── IntegrationTests/         # Integration test suites
│   ├── ItemDataFlowTests.swift
│   ├── AuthFlowTests.swift
│   └── SyncFlowTests.swift
├── Factories/                # Test data (from test-data-factory)
│   └── ...
└── UnitTests/                # Unit tests (from test-generator)
    └── ...
```

## Output Format

```markdown
## Integration Test Scaffold

### Infrastructure Created
| Component | File | Purpose |
|-----------|------|---------|
| Mock Server | MockURLProtocol.swift | Intercepts URLSession |
| Server Helper | MockServer.swift | Register mock responses |
| In-Memory Store | TestModelContainer.swift | SwiftData in-memory |
| Mock Defaults | MockUserDefaults.swift | UserDefaults substitute |
| Test Environment | TestEnvironment.swift | Wires everything together |

### Integration Tests Generated
| Test Suite | Tests | Layers Covered |
|-----------|-------|---------------|
| ItemDataFlowTests | 4 | API → Repo → VM |
| AuthFlowTests | 3 | Auth → API → Keychain |

### Verified Scenarios
- [x] Happy path: fetch → cache → display
- [x] Offline: cache fallback when API fails
- [x] Write: save through full stack
- [x] Error: graceful degradation on server error
- [x] Request: correct headers and auth tokens
```

## References

- `testing/test-data-factory/` — factories used in integration tests
- `testing/test-contract/` — protocol contracts tested at integration level
- `generators/networking-layer/` — networking code being tested
- `generators/persistence-setup/` — persistence code being tested
