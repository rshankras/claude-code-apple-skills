---
name: architecture-spec
description: Generates technical architecture specification from PRD. Covers architecture pattern, tech stack, data models, and app structure. Use when creating ARCHITECTURE.md or designing system architecture.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion]
---

# Architecture Spec Skill

Generate technical architecture specification for iOS/macOS app.

## Metadata
- **Name**: architecture-spec
- **Version**: 1.0.0
- **Role**: iOS/macOS Architect
- **Author**: ProductAgent Team

## Activation

This skill activates when the user says:
- "generate architecture"
- "create technical spec"
- "write architecture document"
- "generate architecture spec"
- "design technical architecture"
- "create ARCHITECTURE.md"

## Description

You are an iOS/macOS Architect AI agent specializing in Apple platform app architecture. Your job is to design a comprehensive technical architecture based on the Product Requirements Document (PRD) and make opinionated technology stack decisions following Apple best practices.

## Prerequisites

Before activating this skill, ensure:
1. PRD exists at `docs/PRD.md`
2. User has reviewed and approved the PRD
3. MVP scope is clear (from product-agent output or PRD)

## Input Sources

Read and extract information from:
1. **docs/PRD.md**
   - Core features and their complexity
   - Non-functional requirements
   - Data model hints
   - Platform requirements
   - Technical considerations

2. **Product development plan** (if available)
   - MVP scope with technical requirements
   - Third-party dependencies mentioned
   - Platform and timeline constraints

3. **User preferences** (ask if needed):
   - SwiftUI vs UIKit preference
   - Third-party library preferences
   - Architecture pattern preference (if strong opinion)
   - Backend API availability (determines data strategy)

## Output

Generate `docs/ARCHITECTURE.md` with the following structure:

```markdown
# Technical Architecture: [App Name]

**Version**: 1.0.0
**Last Updated**: [Date]
**Status**: Draft / In Review / Approved
**Owner**: Technical Architect
**Platform**: iOS [version]+ / macOS [version]+

---

## 1. Architecture Overview

### 1.1 Architecture Pattern

**Selected Pattern**: MVVM (Model-View-ViewModel) with SwiftUI
*or* Clean Architecture *or* TCA (The Composable Architecture)

**Reasoning**:
[Explain why this pattern was chosen based on app complexity]

**Characteristics**:
- **Layers**: [Describe the architectural layers]
- **Data Flow**: [Unidirectional / Bidirectional]
- **State Management**: [@Observable, Combine, TCA Store, etc.]
- **Testability**: [How architecture supports testing]

### 1.2 High-Level Component Diagram

```
┌─────────────────────────────────────────────────┐
│                 Presentation Layer              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │  Views   │  │ViewModels│  │  Models  │     │
│  │ (SwiftUI)│←→│(@Observ.)│←→│  (Data)  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────┐
│                Business Logic Layer             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ Services │  │  Use     │  │Repository│     │
│  │          │  │  Cases   │  │ Pattern  │     │
│  └──────────┘  └──────────┘  └──────────┘     │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────┐
│                  Data Layer                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │SwiftData │  │ Network  │  │ Keychain │     │
│  │ / Core   │  │ Client   │  │ Storage  │     │
│  │   Data   │  │ (URLSess)│  │          │     │
│  └──────────┘  └──────────┘  └──────────┘     │
└─────────────────────────────────────────────────┘
```

### 1.3 Key Architectural Decisions

| Decision | Choice | Alternative Considered | Rationale |
|----------|--------|----------------------|-----------|
| UI Framework | SwiftUI | UIKit | Modern, declarative, iOS 17+ target allows it |
| Data Persistence | SwiftData | Core Data | Simpler API, better SwiftUI integration |
| Architecture Pattern | MVVM | VIPER, TCA | Balanced complexity vs maintainability |
| Networking | URLSession | Alamofire | No third-party dependency needed |
| State Management | @Observable | Combine, TCA | iOS 17+ Observation framework |
| Navigation | NavigationStack | Coordinator | SwiftUI native, simpler for MVP |

---

## 2. Technology Stack

### 2.1 Apple Frameworks

**UI & Presentation**:
- **SwiftUI** (primary) - Declarative UI framework
  - Minimum iOS 17.0 for @Observable, ContentUnavailableView, etc.
  - Navigation: NavigationStack, NavigationPath
  - Data binding: @State, @Binding, @Environment

**Data Persistence**:
- **SwiftData** (iOS 17+) - Data modeling and persistence
  - @Model macro for model classes
  - ModelContainer for database configuration
  - ModelContext for CRUD operations
  - @Query property wrapper for automatic observation

**Networking & Concurrency**:
- **URLSession** - HTTP networking
- **async/await** - Concurrency
- **Actors** - Thread-safe state management
- **Codable** - JSON serialization/deserialization

**Security**:
- **Keychain Services** - Secure credential storage
- **CryptoKit** - Encryption (if needed)
- **LocalAuthentication** - Biometric authentication (if needed)

**Other**:
- [List any other frameworks based on features]
  - MapKit (if maps needed)
  - Vision (if image recognition)
  - CoreML (if ML features)
  - StoreKit (if IAP)
  - CloudKit (if iCloud sync)

### 2.2 Third-Party Dependencies

**Via Swift Package Manager**:

1. **[Package Name]** (if needed)
   - **Repository**: https://github.com/[org]/[repo]
   - **Version**: ~> X.X.X
   - **Purpose**: [Why this is needed]
   - **Alternative Considered**: [Why not chosen]
   - **License**: [MIT, Apache, etc.]

*Note*: Keep dependencies minimal. Only add if:
- Provides significant value not available in Apple frameworks
- Well-maintained and trusted
- No suitable alternative

**Decision**: Start with zero third-party dependencies for MVP. Add only if needed.

### 2.3 Development Tools

- **Xcode**: [Latest stable version]
- **iOS Deployment Target**: iOS 17.0
- **Swift Version**: Swift 5.9+
- **Package Manager**: Swift Package Manager (SPM)
- **CI/CD**: Xcode Cloud / GitHub Actions (to be determined)

---

## 3. App Structure

### 3.1 Module Breakdown

```
[AppName]/
├── App/
│   ├── [AppName]App.swift          # App entry point (@main)
│   ├── ContentView.swift            # Root view
│   └── AppState.swift               # Global app state (if needed)
│
├── Features/                        # Feature-based modules
│   ├── Home/
│   │   ├── Views/
│   │   │   ├── HomeView.swift
│   │   │   ├── HomeCardView.swift
│   │   │   └── HomeEmptyStateView.swift
│   │   ├── ViewModels/
│   │   │   └── HomeViewModel.swift
│   │   └── Models/
│   │       └── HomeItem.swift (if feature-specific)
│   │
│   ├── [Feature2]/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   │
│   └── [Feature3]/
│       └── ...
│
├── Core/                            # Shared core functionality
│   ├── Networking/
│   │   ├── APIClient.swift          # HTTP client
│   │   ├── APIEndpoint.swift        # Endpoint definitions
│   │   ├── APIError.swift           # Error types
│   │   └── RequestModels/           # API request DTOs
│   │       └── ...
│   │
│   ├── Storage/
│   │   ├── DataManager.swift        # SwiftData container wrapper
│   │   └── KeychainManager.swift    # Keychain operations
│   │
│   ├── Extensions/
│   │   ├── View+Extensions.swift    # SwiftUI View extensions
│   │   ├── Color+Extensions.swift   # Color palette
│   │   ├── Font+Extensions.swift    # Typography
│   │   └── Date+Extensions.swift    # Date utilities
│   │
│   └── Utilities/
│       ├── Logger.swift              # Logging utility
│       ├── Validator.swift           # Input validation
│       └── Constants.swift           # App constants
│
├── Models/                          # Domain models (shared)
│   ├── User.swift                   # @Model classes
│   ├── [Entity2].swift
│   └── ResponseModels/              # API response DTOs
│       └── ...
│
├── Services/                        # Business logic services
│   ├── AuthenticationService.swift
│   ├── [Feature]Service.swift
│   └── SyncService.swift (if background sync)
│
├── Resources/
│   ├── Assets.xcassets              # Images, colors
│   ├── Localizable.xcstrings        # Translations
│   └── PrivacyInfo.xcprivacy        # Privacy manifest
│
└── Tests/
    ├── UnitTests/
    │   ├── ViewModelTests/
    │   ├── ServiceTests/
    │   └── ModelTests/
    └── UITests/
        └── ...
```

**Organizational Principles**:
- **Feature-based organization**: Each major feature in its own folder
- **Vertical slicing**: Feature folder contains Views, ViewModels, and feature-specific Models
- **Core for shared**: Reusable components go in Core/
- **Models for domain**: Shared domain models (SwiftData @Model classes)
- **Services for business logic**: Business logic that spans features

### 3.2 Data Models

Based on PRD requirements, core entities are:

#### [Entity 1]: User

```swift
import Foundation
import SwiftData

@Model
final class User {
    // Identity
    @Attribute(.unique) var id: UUID
    var email: String
    var name: String
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade)
    var [relatedEntities]: [RelatedEntity]

    // Computed Properties
    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? email
            : name
    }

    // Validation
    var isValid: Bool {
        !email.isEmpty && email.contains("@") && !name.isEmpty
    }

    init(email: String, name: String) {
        self.id = UUID()
        self.email = email
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

#### [Entity 2]: [Name]

```swift
@Model
final class [Entity2] {
    @Attribute(.unique) var id: UUID
    var [property1]: String
    var [property2]: Date

    // Relationships
    @Relationship(inverse: \User.[relatedEntities])
    var owner: User?

    init(...) {
        // Initialization
    }
}
```

**Entity Relationships**:
- User has many [Entity2] (one-to-many)
- [Entity2] belongs to User (many-to-one)
- [Add other relationships as per PRD]

**SwiftData Considerations**:
- Use @Attribute(.unique) for identifiers
- Define deleteRule for relationships (cascade, nullify, deny, noAction)
- Keep models simple - complex logic goes in ViewModels/Services
- Use @Transient for computed properties that shouldn't persist
- Consider privacy: Mark sensitive fields appropriately

### 3.3 Navigation Architecture

**Pattern**: NavigationStack (SwiftUI native)

**Primary Navigation**:
- **TabView** for main app sections (if 3-5 top-level sections)
- **NavigationStack** for drill-down navigation within tabs

**Navigation State**:
```swift
// In each feature's root view
@State private var navigationPath = NavigationPath()

NavigationStack(path: $navigationPath) {
    ListView()
        .navigationDestination(for: Item.self) { item in
            DetailView(item: item)
        }
        .navigationDestination(for: EditMode.self) { _ in
            EditView()
        }
}
```

**Deep Linking**:
- Handle URL schemes: `[appname]://[route]/[id]`
- Use `.onOpenURL` modifier at app root
- Parse URL and manipulate NavigationPath

**Modal Presentation**:
- Use `.sheet` for full-screen modal forms
- Use `.alert` for simple confirmations
- Use `.confirmationDialog` for action sheets

---

## 4. Data Flow

### 4.1 State Management

**Pattern**: @Observable (iOS 17+ Observation framework)

**State Layers**:

1. **View State** (@State)
   - Local to view
   - Examples: isLoading, showError, selectedItem
   - Transient, not persisted

2. **ViewModel State** (@Observable)
   - Shared across view hierarchy
   - Examples: Business logic, API state, validation
   - Passed as @Environment or direct reference

3. **Persistent State** (SwiftData @Query)
   - Automatically observed by SwiftUI
   - Database-backed
   - Examples: User data, items list

**Example ViewModel**:
```swift
import Foundation
import Observation

@Observable
final class HomeViewModel {
    // Published state
    var items: [Item] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false

    // Dependencies (injected)
    private let apiClient: APIClient
    private let dataManager: DataManager

    init(apiClient: APIClient = .shared,
         dataManager: DataManager = .shared) {
        self.apiClient = apiClient
        self.dataManager = dataManager
    }

    // Actions
    @MainActor
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedItems = try await apiClient.fetchItems()
            items = fetchedItems
            // Persist to SwiftData
            try dataManager.saveItems(fetchedItems)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
```

**Data Flow Diagram**:
```
User Action (Tap Button)
    ↓
View calls ViewModel method
    ↓
ViewModel calls Service/APIClient
    ↓
Service makes API call
    ↓
Response updates ViewModel @Observable properties
    ↓
SwiftUI automatically updates View
    ↓
(Optional) Persist to SwiftData
```

### 4.2 Data Persistence

**Strategy**: Local-first with optional sync

**Local Storage**:
- **SwiftData** for structured data (models)
- **UserDefaults** for simple preferences
- **Keychain** for sensitive data (tokens, passwords)
- **FileManager** for large files (images, documents)

**SwiftData Setup**:
```swift
// In App struct
@main
struct [AppName]App: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([User.self, Item.self, ...])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(
                for: schema,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

**Data Migration**:
- SwiftData handles migrations automatically for simple changes
- For complex migrations, use VersionedSchema and MigrationPlan
- Test migrations thoroughly before releases

**Backup & Sync** (if needed):
- **iCloud CloudKit**: For user data sync across devices
- **File-based**: For documents (UIDocument + iCloud Drive)
- Implementation: Phase 2 (post-MVP unless critical)

### 4.3 Networking Layer

**Architecture**: Protocol-oriented with async/await

**APIClient Design**:
```swift
actor APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "https://api.example.com/v1")!
    private let session: URLSession
    private var authToken: String?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // Generic request method
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint.path))
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body for POST/PUT
        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        // Perform request
        let (data, response) = try await session.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        // Decode
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(T.self, from: data)
    }
}

// Endpoint definition
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let body: (any Encodable)?

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
}

// Error handling
enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, _):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to parse response"
        case .networkError:
            return "Network connection failed"
        }
    }
}
```

**Request/Response Models**:
- Separate DTOs (Data Transfer Objects) from domain models
- Keep in `Core/Networking/RequestModels/` and `ResponseModels/`
- Map from DTO to domain model in service layer

**Error Handling Strategy**:
- Use typed errors (APIError enum)
- Provide user-friendly messages
- Log technical details for debugging
- Implement retry with exponential backoff for transient failures
- Cache responses when appropriate

**Caching**:
- Use URLCache for HTTP caching (images, static content)
- Implement custom cache for API responses (if needed)
- Cache strategy: Cache-Control headers + custom logic

---

## 5. Security & Privacy

### 5.1 Data Security

**Sensitive Data Storage**:
```swift
// KeychainManager for secure storage
final class KeychainManager {
    static let shared = KeychainManager()

    func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func retrieve(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.retrieveFailed(status)
        }

        return data
    }
}
```

**Encryption**:
- API tokens: Stored in Keychain
- User passwords: Never stored locally (use tokens)
- Sensitive files: Encrypt with CryptoKit before saving
- Database: SwiftData encryption enabled (if available)

**Communication Security**:
- All API calls over HTTPS
- TLS 1.2+ required
- Certificate pinning: Consider for Phase 2 if high security needed
- No hardcoded secrets in code (use environment config)

### 5.2 Privacy

**Privacy Manifest** (PrivacyInfo.xcprivacy):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeEmailAddress</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- List any required reason APIs used -->
    </array>
</dict>
</plist>
```

**Data Collection Policy**:
- Collect minimum data necessary
- Document what data is collected and why
- Provide clear privacy policy
- Allow users to delete their data
- No tracking without explicit consent

**App Tracking Transparency**:
- Only if analytics/ads used
- Request permission with clear explanation
- App must work if denied

---

## 6. Performance Considerations

### 6.1 App Launch Optimization

**Cold Launch** (< 1.5s target):
- Defer non-critical initialization
- Use lazy loading for heavy components
- Optimize image assets (compress, use asset catalogs)
- Profile with Instruments (Time Profiler)

**Warm Launch** (< 0.5s target):
- Keep memory footprint low
- Proper state restoration

### 6.2 Memory Management

**Best Practices**:
- Use value types (structs) where possible
- Avoid retain cycles with `[weak self]` in closures
- Use `@MainActor` for UI updates
- Profile with Instruments (Leaks, Allocations)
- Implement proper deinitialization

**Image Handling**:
- Lazy loading with AsyncImage
- Downsample large images
- Cache thumbnail versions
- Use proper image formats (HEIC for photos)

### 6.3 Background Task Handling

**Background Refresh**:
```swift
// If needed for data sync
func scheduleBackgroundRefresh() {
    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.app.refresh",
        using: nil
    ) { task in
        self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
    }
}
```

**Background URLSession**:
- For large downloads/uploads
- Continues even if app terminated
- Implement URLSessionDelegate

### 6.4 Launch Time Optimization

**Strategies**:
- Minimize work in app launch path
- Defer heavy operations to background
- Use lazy initialization
- Optimize image assets
- Remove unused frameworks

---

## 7. Testing Strategy

### 7.1 Unit Testing

**Coverage Target**: 70%+ for business logic

**What to Test**:
- ViewModels: All business logic methods
- Services: API calls, data transformations
- Models: Validation logic, computed properties
- Utilities: Pure functions

**Testing Framework**: XCTest

**Example**:
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

    func testLoadItems_Success() async throws {
        // Given
        let expectedItems = [Item(id: UUID(), name: "Test")]
        mockAPIClient.itemsToReturn = expectedItems

        // When
        await sut.loadItems()

        // Then
        XCTAssertEqual(sut.items, expectedItems)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showError)
    }

    func testLoadItems_Failure() async throws {
        // Given
        mockAPIClient.shouldThrowError = true

        // When
        await sut.loadItems()

        // Then
        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.items.isEmpty)
    }
}
```

### 7.2 UI Testing

**Coverage Target**: Critical user journeys only (~10% of tests)

**What to Test**:
- Onboarding flow
- Core feature happy paths
- Error state handling
- Navigation flows

**Framework**: XCTest with XCUITest

**Best Practices**:
- Use accessibility identifiers
- Test user-facing behavior, not implementation
- Keep tests independent
- Use test plans for different configurations

### 7.3 Integration Testing

**What to Test**:
- API integration (with mock backend or staging)
- SwiftData CRUD operations
- Background tasks
- Deep linking

### 7.4 Mocking Strategy

**Mock Types**:
- Protocol-based mocks for dependencies
- In-memory storage for tests
- Mock API client with canned responses

**Dependency Injection**:
- Use initializer injection for testability
- Provide default values for production
- Override with mocks in tests

---

## 8. Deployment & DevOps

### 8.1 Build Configurations

**Debug**:
- Optimization: None (-Onone)
- Assertions: Enabled
- Logging: Verbose
- API endpoint: Development/Staging
- Crashlytics: Disabled

**Release**:
- Optimization: Speed (-O)
- Assertions: Disabled
- Logging: Errors only
- API endpoint: Production
- Crashlytics: Enabled
- Strip debug symbols: Yes

### 8.2 Environment Management

**Configuration**:
```swift
enum Environment {
    case development
    case staging
    case production

    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    var apiBaseURL: URL {
        switch self {
        case .development:
            return URL(string: "https://dev.api.example.com")!
        case .staging:
            return URL(string: "https://staging.api.example.com")!
        case .production:
            return URL(string: "https://api.example.com")!
        }
    }
}
```

### 8.3 CI/CD

**Recommended**: Xcode Cloud or GitHub Actions

**Pipeline Stages**:
1. **On Pull Request**:
   - Run SwiftLint
   - Build project
   - Run unit tests
   - Generate code coverage report

2. **On Merge to Main**:
   - Full test suite (unit + UI)
   - Build release configuration
   - Archive build

3. **On Tag** (e.g., v1.0.0):
   - Build release
   - Upload to TestFlight
   - Create GitHub release

**Example GitHub Actions** (placeholder):
```yaml
name: CI
on: [pull_request, push]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and Test
        run: |
          xcodebuild clean build test \
            -scheme [AppName] \
            -destination 'platform=iOS Simulator,name=iPhone 15'
```

### 8.4 Feature Flags

**Implementation**: (If needed for gradual rollouts)
- Use remote config (Firebase Remote Config, Launch Darkly, or custom)
- Local override for testing
- A/B testing capability

---

## 9. Technical Risks & Mitigations

### Risk 1: SwiftData Maturity (iOS 17+ framework)

**Risk**: SwiftData is relatively new, may have bugs or limitations
**Impact**: Data loss, migration issues, performance problems
**Probability**: Medium
**Mitigation**:
- Thorough testing of CRUD operations
- Implement backup mechanism
- Have Core Data migration path ready as fallback
- Monitor SwiftData-related crashes closely
**Fallback**: Migrate to Core Data if critical issues found

### Risk 2: iOS 17+ Minimum Version

**Risk**: Limits addressable market (older iOS versions excluded)
**Impact**: Reduced potential user base
**Probability**: Certain
**Mitigation**:
- Validate market data (% of users on iOS 17+)
- Accept trade-off for modern APIs
- Plan for iOS 16 support in future if needed
**Decision**: Accept for MVP, modern APIs worth the trade-off

### Risk 3: Network Dependency

**Risk**: App requires network for most features
**Impact**: Poor user experience in offline scenarios
**Probability**: High
**Mitigation**:
- Implement robust offline support with local caching
- Sync when network available
- Clear messaging when offline
- Core features work offline where possible
**Fallback**: None - core to architecture

### Risk 4: Third-Party API Reliability

**Risk**: Backend API downtime or rate limiting
**Impact**: App functionality degraded
**Probability**: Low-Medium
**Mitigation**:
- Implement proper error handling
- Retry logic with exponential backoff
- Cache responses locally
- Graceful degradation
- Monitor API health

---

## 10. Future Considerations

### Phase 2 Enhancements

**After MVP Launch**:
1. **iPad Support**: Adapt layouts for larger screens
2. **macOS Catalyst**: Cross-platform desktop version
3. **Widgets**: Home screen and Lock screen widgets
4. **Watch App**: Companion watchOS app
5. **App Clips**: Lightweight app clip for quick access
6. **CloudKit Sync**: Cross-device synchronization
7. **Offline-First**: Enhance offline capabilities
8. **Performance**: Optimize based on real-world metrics
9. **Accessibility**: Enhanced VoiceOver support, keyboard shortcuts
10. **Localization**: Additional languages

### Technology Updates

**Monitor**:
- SwiftUI updates in future iOS versions
- SwiftData improvements and bug fixes
- New Apple frameworks (announced at WWDC)
- Swift language evolution proposals

---

## 11. Documentation & Knowledge Sharing

**Code Documentation**:
- Use Swift DocC comments for public APIs
- Document complex algorithms
- Keep README updated
- Maintain CHANGELOG

**Architecture Decision Records (ADRs)**:
- Document major architectural decisions
- Include context, options considered, decision, consequences
- Store in docs/architecture/decisions/

**Onboarding**:
- Architecture overview for new developers
- Setup guide (README.md)
- Coding standards document
- PR review checklist

---

## 12. Success Metrics

**Technical KPIs**:
- Crash-free rate: > 99.5%
- App launch time (cold): < 1.5s
- App launch time (warm): < 0.5s
- Network request latency (95th percentile): < 2s
- Test coverage: > 70% for business logic
- Build time: < 10 minutes (for CI)

**Monitoring**:
- Crashlytics / Firebase Crashlytics
- Performance monitoring (Xcode Organizer, MetricKit)
- Network monitoring (URLSession metrics)
- Custom analytics (if needed)

---

## Appendix A: Coding Standards

### Swift Style Guide
- Follow [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for consistency
- Naming conventions:
  - Types: PascalCase
  - Variables/functions: camelCase
  - Constants: camelCase (not SCREAMING_SNAKE_CASE)

### SwiftUI Best Practices
- Keep views small and focused
- Extract subviews for reusability
- Use @ViewBuilder for custom DSLs
- Prefer property wrappers (@State, @Binding) over manual management

### Concurrency
- Always use async/await over completion handlers
- Mark UI updates with @MainActor
- Use actors for thread-safe shared state
- Avoid @unchecked Sendable unless necessary

---

## Appendix B: Reference Links

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

**Document History**:
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | [Date] | [Name] | Initial architecture design |

```

## Execution Instructions

When activated, follow these steps:

1. **Read PRD**
   ```
   Read docs/PRD.md
   Extract:
   - Core features and complexity level
   - Non-functional requirements
   - Platform requirements (iOS version)
   - Data model hints from user stories
   - Technical requirements section
   ```

2. **Assess Complexity**
   - Simple (1-3 core features, basic CRUD): MVVM with SwiftUI
   - Medium (4-8 features, some complexity): MVVM or Clean Architecture
   - Complex (9+ features, high complexity): Clean Architecture or TCA

3. **Make Technology Decisions**
   Based on PRD requirements and iOS version target:
   - iOS 17+ → SwiftUI + SwiftData + @Observable (recommended)
   - iOS 16+ → SwiftUI + Core Data + Combine
   - UIKit → Only if strong reason (legacy, specific UI needs)

4. **Ask User Preferences** (if needed)
   ```
   Quick questions about the architecture:

   1. Do you have a preference for UI framework?
      - SwiftUI (modern, recommended for iOS 17+)
      - UIKit (if you need more control or have existing UIKit code)

   2. Do you have a backend API already?
      - Yes → Focus on networking layer
      - No → Focus on local-first architecture

   3. Any required third-party libraries?
      - List them, or say "minimize dependencies"
   ```

5. **Create Output Directory**
   ```bash
   mkdir -p docs
   ```

6. **Generate ARCHITECTURE.md**
   - Use template above
   - Fill in all sections with specific, opinionated choices
   - Make architectural decisions and explain reasoning
   - Design data models based on PRD features
   - Define complete module structure

7. **Write to File**
   ```
   Write to: docs/ARCHITECTURE.md
   ```

8. **Present Summary**
   ```
   ✅ Technical Architecture generated!

   🏗️ **Architecture Summary**:
   - Document: docs/ARCHITECTURE.md
   - Pattern: [MVVM / Clean / TCA]
   - UI Framework: [SwiftUI / UIKit]
   - Data Persistence: [SwiftData / Core Data]
   - Minimum iOS: [17.0 / 16.0 / 15.0]
   - Third-party deps: [X] (or "None - Apple frameworks only")
   - Data models: [X] entities defined

   **Key Decisions**:
   1. [Decision 1]: [Choice] - [Reason]
   2. [Decision 2]: [Choice] - [Reason]
   3. [Decision 3]: [Choice] - [Reason]

   **Next Steps**:
   1. Review the architecture in docs/ARCHITECTURE.md
   2. Confirm technology stack choices
   3. Once approved, we can proceed to UX spec

   Any questions or changes to the architecture?
   ```

9. **Iterate if Needed**
   - If user wants different tech stack, regenerate relevant sections
   - If user disagrees with pattern choice, explain and offer alternative
   - Update document with changes

## Quality Guidelines

1. **Be Opinionated**: Make clear technology choices
   - BAD: "You could use SwiftUI or UIKit"
   - GOOD: "Using SwiftUI because iOS 17+ target allows modern APIs and declarative UI is more maintainable"

2. **Explain Reasoning**: Every major decision should have rationale
   - Why this architecture pattern?
   - Why these frameworks?
   - Why these trade-offs?

3. **Be Specific**: Provide actual code examples
   - Show data model structure
   - Show networking client design
   - Show ViewModel pattern

4. **Consider Trade-offs**: Document risks and mitigations
   - What could go wrong?
   - How do we handle it?
   - What's the backup plan?

5. **Stay Current**: Use modern Swift and iOS features
   - iOS 17+: SwiftData, @Observable, ContentUnavailableView
   - async/await over completion handlers
   - Actors for thread safety

6. **Follow Apple HIG**: Architecture should enable HIG compliance
   - Native patterns (NavigationStack, TabView)
   - Platform conventions
   - Accessibility built-in

## Integration with Workflow

This skill is typically:
- **Second step** in implementation specification generation (after prd-generator)
- Activated after PRD is approved
- Followed by ux-spec, implementation-guide, test-spec, release-spec

The architecture document guides all downstream technical decisions.

## Notes

- Be pragmatic: Choose technologies that fit the problem
- Start simple: MVVM + SwiftUI + SwiftData is a great default
- Document decisions: Future developers will thank you
- Consider team skills: If team is UIKit-expert, maybe stick with UIKit
- Balance modern vs stable: Bleeding edge isn't always best
- MVP mindset: Perfect is enemy of shipped
