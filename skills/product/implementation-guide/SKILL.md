---
name: implementation-guide
description: Generates detailed implementation guide with pseudo-code and step-by-step development instructions. Creates IMPLEMENTATION_GUIDE.md from PRD, Architecture, and UX specs. Use when creating development roadmap.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion]
---

# Implementation Guide Skill

Generate detailed implementation guide with pseudo-code and step-by-step instructions for iOS/macOS app development.

## Metadata
- **Name**: implementation-guide
- **Version**: 1.0.0
- **Role**: Senior iOS/macOS Developer
- **Author**: ProductAgent Team

## Activation

This skill activates when the user says:
- "generate implementation guide"
- "create development guide"
- "write implementation steps"
- "generate code guide"
- "create developer guide from specs"

## Description

You are a Senior iOS/macOS Developer AI agent with expertise in Swift, SwiftUI, SwiftData, and modern iOS development patterns. Your job is to transform product requirements, architecture, and UX specifications into a comprehensive, step-by-step implementation guide that enables any competent iOS developer to build the app confidently.

## Prerequisites

Before activating this skill, ensure:
1. PRD exists (from prd-generator skill) with all features defined
2. ARCHITECTURE.md exists (from architecture-spec skill) with tech stack and structure
3. UX_SPEC.md exists (from ux-spec skill) with wireframes and interactions
4. DESIGN_SYSTEM.md exists with colors, typography, components

## Input Sources

Read and extract information from:

1. **docs/PRD.md**
   - All features and user stories
   - Acceptance criteria
   - Success metrics
   - Timeline estimates

2. **docs/ARCHITECTURE.md**
   - Architecture pattern (MVVM, Clean, TCA)
   - Technology stack decisions
   - Data models and relationships
   - Module structure
   - Networking layer design

3. **docs/UX_SPEC.md**
   - All screens and wireframes
   - User flows
   - Interactions and gestures
   - States (empty, loading, error)

4. **docs/DESIGN_SYSTEM.md**
   - Colors, typography, spacing
   - Component styles
   - Animation timings
   - Design tokens

5. **User clarifications** (ask if needed):
   - Xcode version / minimum iOS version preferences
   - Any existing codebase to integrate with
   - CI/CD preferences (Xcode Cloud, GitHub Actions, Fastlane)

## Output

Generate: **docs/IMPLEMENTATION_GUIDE.md**

Structure (comprehensive, ~3000-5000 lines):

```markdown
# Implementation Guide: [App Name]

**Version**: 1.0.0
**Last Updated**: [Date]
**Platform**: iOS [Version]+
**Language**: Swift 5.9+
**Framework**: SwiftUI
**Xcode**: 15.0+

---

## 0. Quick Start

For the impatient developer:

```bash
# 1. Clone or create new Xcode project
# Template: iOS App (SwiftUI)
# Name: [AppName]
# Organization ID: com.yourcompany.appname
# Language: Swift
# Storage: SwiftData
# Include Tests: Yes

# 2. Set minimum deployment target
# Project Settings → General → Minimum Deployments: iOS 17.0

# 3. Add dependencies via SPM (if any)
# File → Add Package Dependencies → [URLs from ARCHITECTURE.md]

# 4. Create folder structure (see Section 2)

# 5. Follow implementation phases (Section 3)

# 6. Run tests frequently
xcodebuild test -scheme [AppName]

# 7. Launch and iterate
```

**Estimated Timeline**: [X] weeks for MVP (from PRD)
**Estimated LOC**: ~[Y] lines of Swift code
**Files to Create**: ~[Z] .swift files

---

## 1. Project Setup

### 1.1 Create Xcode Project

1. Open Xcode 15+
2. File → New → Project
3. Choose template: **iOS → App**
4. Configuration:
   - **Product Name**: [AppName]
   - **Team**: [Your team or Personal Team]
   - **Organization Identifier**: com.yourcompany.appname
   - **Bundle Identifier**: [Auto-generated]
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: SwiftData [or Core Data based on ARCHITECTURE]
   - **Include Tests**: ✅ Yes
   - **Create Git repository**: ✅ Optional but recommended

5. Click Create

### 1.2 Project Configuration

**File**: Select project in Navigator → General tab

**Deployment Info**:
- **Minimum Deployments**: iOS 17.0 [adjust based on ARCHITECTURE]
- **Supported Destinations**: iPhone (✅), iPad (based on requirements)
- **Device Orientation**:
  - Portrait (✅ Required)
  - Landscape Left (based on requirements)
  - Landscape Right (based on requirements)

**App Icons & Launch Screen**:
- **App Icon**: Add 1024x1024 icon to Assets.xcassets/AppIcon
- **Launch Screen**: Use default or customize LaunchScreen.storyboard

**Signing & Capabilities**:
- **Team**: Select your development team
- **Signing Certificate**: Automatically manage signing (recommended)
- **Capabilities**: Add as needed:
  - Push Notifications (if required)
  - iCloud (if using CloudKit sync)
  - Background Modes (if needed)

### 1.3 Add Dependencies (if any)

**From ARCHITECTURE.md**, add these packages:

**Example** (adjust based on actual ARCHITECTURE):
```
File → Add Package Dependencies

[If networking library needed]
1. Alamofire: https://github.com/Alamofire/Alamofire
   Version: 5.9.0+

[If image loading needed]
2. Kingfisher: https://github.com/onevcat/Kingfisher
   Version: 7.10.0+

[Add only packages specified in ARCHITECTURE.md]
```

**Important**: Minimize third-party dependencies. Use native frameworks when possible.

### 1.4 Configure SwiftData

**File**: [AppName]App.swift

```swift
import SwiftUI
import SwiftData

@main
struct AppNameApp: App {
    // Define the data model container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // List all @Model classes here
            User.self,
            Item.self,
            // Add all data models from ARCHITECTURE.md
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false  // Persist to disk
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \\(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

---

## 2. File Structure

Create this folder hierarchy in your project:

```
[AppName]/
├── App/
│   ├── [AppName]App.swift           # Entry point
│   └── ContentView.swift            # Root view (delete if not using)
│
├── Features/                        # Feature modules
│   ├── Onboarding/
│   │   ├── Views/
│   │   │   ├── OnboardingView.swift
│   │   │   ├── OnboardingStep1View.swift
│   │   │   └── OnboardingStep2View.swift
│   │   └── ViewModels/
│   │       └── OnboardingViewModel.swift
│   │
│   ├── Home/
│   │   ├── Views/
│   │   │   ├── HomeView.swift
│   │   │   ├── HomeCardView.swift
│   │   │   └── HomeEmptyStateView.swift
│   │   ├── ViewModels/
│   │   │   └── HomeViewModel.swift
│   │   └── Models/
│   │       └── HomeFilter.swift         # View-specific models
│   │
│   ├── ItemDetail/
│   │   ├── Views/
│   │   │   ├── ItemDetailView.swift
│   │   │   └── ItemDetailHeaderView.swift
│   │   └── ViewModels/
│   │       └── ItemDetailViewModel.swift
│   │
│   ├── AddEditItem/
│   │   ├── Views/
│   │   │   └── AddEditItemView.swift
│   │   └── ViewModels/
│   │       └── AddEditItemViewModel.swift
│   │
│   └── Settings/
│       ├── Views/
│       │   ├── SettingsView.swift
│       │   └── AccountView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
│
├── Core/                            # Shared infrastructure
│   ├── Networking/
│   │   ├── APIClient.swift          # Base HTTP client
│   │   ├── Endpoint.swift           # API endpoint definitions
│   │   ├── NetworkError.swift       # Error types
│   │   └── APIService.swift         # High-level API service
│   │
│   ├── Storage/
│   │   ├── DataManager.swift        # SwiftData operations wrapper
│   │   └── CacheManager.swift       # Optional: in-memory cache
│   │
│   ├── Extensions/
│   │   ├── View+Extensions.swift    # SwiftUI view modifiers
│   │   ├── Color+Extensions.swift   # Design system colors
│   │   ├── Font+Extensions.swift    # Custom font extensions
│   │   └── Date+Extensions.swift    # Date formatting
│   │
│   ├── Utilities/
│   │   ├── Logger.swift             # Logging utility
│   │   ├── Validator.swift          # Input validation
│   │   └── Constants.swift          # App constants
│   │
│   └── DesignSystem/
│       └── DesignTokens.swift       # Centralized design tokens
│
├── Models/                          # Data models (SwiftData)
│   ├── User.swift
│   ├── Item.swift
│   ├── Category.swift
│   └── [Other models from ARCHITECTURE.md]
│
├── Services/                        # Business logic services
│   ├── AuthenticationService.swift  # If auth required
│   ├── SyncService.swift            # If sync required
│   └── NotificationService.swift    # If notifications required
│
├── Resources/                       # Assets and resources
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   ├── Colors/                  # Define colors here
│   │   │   ├── BrandPrimary.colorset
│   │   │   ├── BrandSecondary.colorset
│   │   │   └── [All colors from DESIGN_SYSTEM.md]
│   │   └── Images/
│   └── PrivacyInfo.xcprivacy        # Privacy manifest
│
└── Supporting Files/
    ├── Info.plist
    └── [AppName].entitlements       # If capabilities needed

[AppName]Tests/                      # Unit tests
├── ViewModelTests/
│   ├── HomeViewModelTests.swift
│   └── [Other ViewModel tests]
├── ModelTests/
│   ├── UserTests.swift
│   └── [Other Model tests]
└── ServiceTests/
    └── APIClientTests.swift

[AppName]UITests/                    # UI tests
└── [AppName]UITests.swift
```

**To Create Folders**:
1. Right-click project in Navigator
2. New Group (⌘⌥N)
3. Name it exactly as above
4. Create subgroups as needed
5. Add files to appropriate groups

---

## 3. Implementation Phases

Follow these phases sequentially. Each phase builds on the previous.

### **Phase 1: Core Infrastructure** (Week 1)

Goal: Set up foundational code that all features depend on.

---

#### Step 1.1: Create Data Models

For each entity in ARCHITECTURE.md Section 3.2, create a SwiftData model.

**File**: `Models/User.swift`

**Pseudo-code with inline documentation**:

```swift
import Foundation
import SwiftData

/// Represents a user of the application
/// SwiftData model - automatically persisted to local database
@Model
final class User {
    // MARK: - Properties

    /// Unique identifier for the user
    /// @Attribute(.unique) ensures no duplicate UUIDs in database
    @Attribute(.unique) var id: UUID

    /// User's full name
    var name: String

    /// User's email address (used for login and notifications)
    var email: String

    /// URL to user's profile image (optional)
    var profileImageURL: String?

    /// Timestamp when user account was created
    var createdAt: Date

    /// Timestamp of last profile update
    var updatedAt: Date

    // MARK: - Relationships

    /// All items created by this user
    /// @Relationship with deleteRule .cascade means: when User is deleted, all their Items are also deleted
    @Relationship(deleteRule: .cascade, inverse: \\Item.owner)
    var items: [Item]

    // MARK: - Initializer

    /// Creates a new User instance
    /// - Parameters:
    ///   - name: User's full name
    ///   - email: User's email address
    init(name: String, email: String) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.profileImageURL = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.items = []
    }

    // MARK: - Computed Properties

    /// Returns formatted display name (first name only if space exists)
    var displayName: String {
        let components = name.components(separatedBy: " ")
        return components.first ?? name
    }

    /// Returns user's initials for avatar fallback (e.g., "John Doe" → "JD")
    var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }

    // MARK: - Validation

    /// Validates if user data is complete and valid
    /// - Returns: true if valid, false otherwise
    var isValid: Bool {
        return !name.isEmpty && isValidEmail(email)
    }

    /// Validates email format using regex
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    // MARK: - Methods

    /// Updates the user's profile information
    /// - Parameters:
    ///   - name: New name (optional)
    ///   - email: New email (optional)
    ///   - profileImageURL: New profile image URL (optional)
    func updateProfile(name: String? = nil, email: String? = nil, profileImageURL: String? = nil) {
        if let name = name {
            self.name = name
        }
        if let email = email {
            self.email = email
        }
        if let profileImageURL = profileImageURL {
            self.profileImageURL = profileImageURL
        }
        self.updatedAt = Date()
    }
}

// MARK: - Codable Conformance (for API sync)

extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case profileImageURL = "profile_image_url"  // Match API naming
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

**Implementation Notes**:
- Use `@Model` macro for SwiftData (automatic persistence)
- Mark unique fields with `@Attribute(.unique)`
- Define relationships with `@Relationship(deleteRule:inverse:)`
- Add validation methods for data integrity
- Use `final` for classes that don't need subclassing (performance)
- Add `Codable` conformance if syncing with backend API

**Repeat for all models** listed in ARCHITECTURE.md:
- `Models/Item.swift`
- `Models/Category.swift`
- [Any other models]

---

**File**: `Models/Item.swift`

**Pseudo-code**:

```swift
import Foundation
import SwiftData

/// Represents an item in the application
@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String?
    var itemDescription: String
    var thumbnailURL: String?
    var status: ItemStatus
    var metadata: String?  // JSON string for flexible data
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(inverse: \\User.items)
    var owner: User?

    @Relationship(inverse: \\Category.items)
    var category: Category?

    init(title: String, description: String, owner: User, category: Category? = nil) {
        self.id = UUID()
        self.title = title
        self.subtitle = nil
        self.itemDescription = description
        self.thumbnailURL = nil
        self.status = .active
        self.metadata = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.owner = owner
        self.category = category
    }

    var isValid: Bool {
        return !title.isEmpty && !itemDescription.isEmpty
    }

    func updateStatus(_ newStatus: ItemStatus) {
        self.status = newStatus
        self.updatedAt = Date()
    }
}

/// Item status enum
enum ItemStatus: String, Codable {
    case active = "active"
    case pending = "pending"
    case completed = "completed"
    case archived = "archived"
}

// Make ItemStatus compatible with SwiftData
extension ItemStatus: RawRepresentable {}
```

---

#### Step 1.2: Setup Data Manager

**Purpose**: Centralized service for all SwiftData operations (CRUD + queries)

**File**: `Core/Storage/DataManager.swift`

**Pseudo-code**:

```swift
import Foundation
import SwiftData
import Observation

/// Centralized manager for all SwiftData operations
/// Use this instead of direct ModelContext access for consistency
@Observable
final class DataManager {
    // MARK: - Properties

    /// Shared singleton instance (use dependency injection in production)
    static let shared = DataManager()

    /// SwiftData container holding the schema and configurations
    let container: ModelContainer

    /// Main context for UI-related operations (runs on main thread)
    var mainContext: ModelContext

    // MARK: - Initialization

    /// Private init for singleton
    private init() {
        // Define schema with all model types
        let schema = Schema([
            User.self,
            Item.self,
            Category.self,
            // Add all @Model classes here
        ])

        // Configure persistence
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,  // false = persist to disk
            allowsSave: true
        )

        do {
            // Create container
            self.container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Get main context
            self.mainContext = container.mainContext

            // Configure context
            mainContext.autosaveEnabled = true  // Auto-save on changes

            print("✅ DataManager initialized successfully")
        } catch {
            fatalError("Failed to create ModelContainer: \\(error)")
        }
    }

    // MARK: - Generic CRUD Operations

    /// Creates and inserts a new model instance
    /// - Parameter model: The model instance to insert
    /// - Throws: Error if save fails
    func create<T: PersistentModel>(_ model: T) throws {
        mainContext.insert(model)
        try save()
    }

    /// Fetches all instances of a model type
    /// - Parameters:
    ///   - type: The model type to fetch
    ///   - predicate: Optional filter (nil = fetch all)
    ///   - sortBy: Optional sort descriptors
    /// - Returns: Array of model instances
    /// - Throws: Error if fetch fails
    func fetch<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) throws -> [T] {
        var fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        return try mainContext.fetch(fetchDescriptor)
    }

    /// Fetches a single instance by ID
    /// - Parameters:
    ///   - type: The model type
    ///   - id: The persistent model ID
    /// - Returns: Model instance or nil if not found
    func fetchByID<T: PersistentModel>(_ type: T.Type, id: PersistentIdentifier) -> T? {
        return mainContext.model(for: id) as? T
    }

    /// Updates a model (no-op, changes are tracked automatically)
    /// Just call save() after modifying properties
    func update() throws {
        try save()
    }

    /// Deletes a model instance
    /// - Parameter model: The model instance to delete
    /// - Throws: Error if delete/save fails
    func delete<T: PersistentModel>(_ model: T) throws {
        mainContext.delete(model)
        try save()
    }

    /// Deletes all instances of a model type
    /// - Parameter type: The model type to delete all of
    /// - Throws: Error if delete fails
    func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        let all = try fetch(type)
        for item in all {
            mainContext.delete(item)
        }
        try save()
    }

    /// Saves pending changes to persistent store
    /// - Throws: Error if save fails
    private func save() throws {
        if mainContext.hasChanges {
            try mainContext.save()
        }
    }

    // MARK: - Background Context

    /// Creates a background context for heavy operations (imports, sync)
    /// - Returns: A new ModelContext for background thread
    func backgroundContext() -> ModelContext {
        return ModelContext(container)
    }

    // MARK: - Specialized Queries (Domain-Specific)

    /// Fetches items filtered by status
    /// - Parameter status: The item status to filter by
    /// - Returns: Array of items with matching status
    /// - Throws: Error if fetch fails
    func fetchItems(byStatus status: ItemStatus) throws -> [Item] {
        let predicate = #Predicate<Item> { item in
            item.status == status
        }
        let sortBy = [SortDescriptor(\\Item.createdAt, order: .reverse)]
        return try fetch(Item.self, predicate: predicate, sortBy: sortBy)
    }

    /// Fetches recent items (last N days)
    /// - Parameter days: Number of days to look back
    /// - Returns: Array of recent items
    /// - Throws: Error if fetch fails
    func fetchRecentItems(days: Int = 7) throws -> [Item] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = #Predicate<Item> { item in
            item.createdAt >= startDate
        }
        let sortBy = [SortDescriptor(\\Item.createdAt, order: .reverse)]
        return try fetch(Item.self, predicate: predicate, sortBy: sortBy)
    }

    /// Searches items by title or description
    /// - Parameter query: Search query string
    /// - Returns: Array of matching items
    /// - Throws: Error if fetch fails
    func searchItems(query: String) throws -> [Item] {
        let lowercaseQuery = query.lowercased()
        let predicate = #Predicate<Item> { item in
            item.title.lowercased().contains(lowercaseQuery) ||
            item.itemDescription.lowercased().contains(lowercaseQuery)
        }
        return try fetch(Item.self, predicate: predicate)
    }

    // Add more domain-specific queries as needed from PRD features
}

// MARK: - Error Handling

enum DataManagerError: LocalizedError {
    case fetchFailed(Error)
    case saveFailed(Error)
    case deleteFailed(Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch data: \\(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \\(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \\(error.localizedDescription)"
        case .notFound:
            return "Item not found"
        }
    }
}
```

**Testing DataManager**:

Create `Tests/ServiceTests/DataManagerTests.swift`:

```swift
import XCTest
@testable import [AppName]

final class DataManagerTests: XCTestCase {
    var dataManager: DataManager!

    override func setUp() {
        super.setUp()
        // Use in-memory store for tests
        dataManager = DataManager.shared
    }

    override func tearDown() {
        // Clean up test data
        try? dataManager.deleteAll(Item.self)
        try? dataManager.deleteAll(User.self)
        dataManager = nil
        super.tearDown()
    }

    func testCreateUser() throws {
        // Given
        let user = User(name: "Test User", email: "test@example.com")

        // When
        try dataManager.create(user)

        // Then
        let fetched = try dataManager.fetch(User.self)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Test User")
    }

    func testFetchItemsByStatus() throws {
        // Given
        let user = User(name: "Test", email: "test@test.com")
        try dataManager.create(user)

        let item1 = Item(title: "Active", description: "Test", owner: user)
        item1.status = .active
        try dataManager.create(item1)

        let item2 = Item(title: "Complete", description: "Test", owner: user)
        item2.status = .completed
        try dataManager.create(item2)

        // When
        let activeItems = try dataManager.fetchItems(byStatus: .active)

        // Then
        XCTAssertEqual(activeItems.count, 1)
        XCTAssertEqual(activeItems.first?.title, "Active")
    }

    // Add more tests for each DataManager method
}
```

---

#### Step 1.3: Implement Design System

**Purpose**: Centralize all design tokens (colors, typography, spacing) in one file

**File**: `Core/DesignSystem/DesignTokens.swift`

**Complete implementation** (copy from DESIGN_SYSTEM.md Section 12):

```swift
import SwiftUI

/// Centralized design system tokens
/// All design decisions are defined here - reference throughout the app
enum DesignSystem {

    // MARK: - Colors

    enum Colors {
        // Brand colors (defined in Assets.xcassets/Colors/)
        static let brandPrimary = Color("BrandPrimary")
        static let brandSecondary = Color("BrandSecondary")
        static let brandAccent = Color("BrandAccent")

        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue

        // Text colors (use system colors for automatic dark mode)
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary

        // Background colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)

        // UI element colors
        static let separator = Color(.separator)
        static let border = Color(.separator)
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16     // Default
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let xs: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12   // Default
        static let large: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999   // Fully rounded
    }

    // MARK: - Shadows

    enum Shadow {
        static let card = (color: Color.black.opacity(0.1), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
        static let modal = (color: Color.black.opacity(0.15), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(4))
        static let elevated = (color: Color.black.opacity(0.2), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(8))
    }

    // MARK: - Animation

    enum Animation {
        static let fast: Double = 0.2
        static let standard: Double = 0.3
        static let slow: Double = 0.5
        static let verySlow: Double = 1.0
    }

    // MARK: - Layout

    enum Layout {
        static let cardHeight: CGFloat = 80
        static let buttonHeight: CGFloat = 50
        static let textFieldHeight: CGFloat = 50
        static let minTapTarget: CGFloat = 44
        static let maxContentWidth: CGFloat = 600  // For iPad
    }
}

// MARK: - Convenience Extensions

extension Color {
    /// Initialize from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

**Add Color Assets**:

1. Open `Assets.xcassets`
2. Right-click → New Color Set
3. Name: "BrandPrimary"
4. In Attributes Inspector: Appearances → Any, Dark
5. Set Light Mode color: #007AFF (or from DESIGN_SYSTEM.md)
6. Set Dark Mode color: #0A84FF
7. Repeat for "BrandSecondary", "BrandAccent", etc.

---

#### Step 1.4: Create View Extensions

**Purpose**: Reusable SwiftUI modifiers for consistent styling

**File**: `Core/Extensions/View+Extensions.swift`

**Implementation**:

```swift
import SwiftUI

extension View {
    // MARK: - Card Style

    /// Applies standard card styling
    /// - Returns: View with card background, padding, corner radius, and shadow
    func cardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.l)
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.Radius.medium)
            .shadow(
                color: DesignSystem.Shadow.card.color,
                radius: DesignSystem.Shadow.card.radius,
                x: DesignSystem.Shadow.card.x,
                y: DesignSystem.Shadow.card.y
            )
    }

    // MARK: - Button Styles

    /// Applies primary button styling
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(DesignSystem.Colors.brandPrimary)
            .cornerRadius(DesignSystem.Radius.medium)
    }

    /// Applies secondary button styling (outlined)
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.headline)
            .foregroundColor(DesignSystem.Colors.brandPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(Color.clear)
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(DesignSystem.Colors.brandPrimary, lineWidth: 2)
            )
    }

    /// Applies text button styling (no background)
    func textButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.brandPrimary)
    }

    // MARK: - Loading Overlay

    /// Shows loading overlay when condition is true
    /// - Parameter isLoading: Binding to loading state
    func loadingOverlay(isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .controlSize(.large)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Conditional Modifiers

    /// Applies modifier only when condition is true
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    // MARK: - Keyboard Dismissal

    /// Adds tap gesture to dismiss keyboard
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}

// MARK: - Button Style Structs

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .primaryButtonStyle()
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: DesignSystem.Animation.fast), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .secondaryButtonStyle()
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: DesignSystem.Animation.fast), value: configuration.isPressed)
    }
}

// Usage:
// Button("Continue") { }
//     .buttonStyle(PrimaryButtonStyle())
```

---

#### Step 1.5: Create Networking Layer

**Purpose**: Centralized HTTP client for API calls

**File**: `Core/Networking/APIClient.swift`

**Implementation**:

```swift
import Foundation

/// Actor-based API client for thread-safe network operations
actor APIClient {
    // MARK: - Properties

    /// Shared singleton instance
    static let shared = APIClient()

    /// Base URL for API
    private let baseURL: URL

    /// URLSession for network requests
    private let session: URLSession

    // MARK: - Initialization

    init(baseURL: String = "https://api.example.com") {
        self.baseURL = URL(string: baseURL)!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Generic Request Method

    /// Performs an API request and decodes the response
    /// - Parameters:
    ///   - endpoint: The API endpoint to call
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - body: Optional request body (will be JSON encoded)
    ///   - headers: Additional headers
    /// - Returns: Decoded response of type T
    /// - Throws: APIError if request fails
    func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        // Build URL
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add authentication header (if user is logged in)
        // Uncomment if auth required:
        // if let token = try? await getAuthToken() {
        //     request.setValue("Bearer \\(token)", forHTTPHeaderField: "Authorization")
        // }

        // Encode body
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        // Perform request
        let (data, response) = try await session.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ Decoding error: \\(error)")
                print("Response data: \\(String(data: data, encoding: .utf8) ?? "")")
                throw APIError.decodingError(error)
            }

        case 401:
            throw APIError.unauthorized

        case 403:
            throw APIError.forbidden

        case 404:
            throw APIError.notFound

        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)

        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
    }

    // MARK: - Convenience Methods

    /// Performs a GET request
    func get<T: Decodable>(_ endpoint: String) async throws -> T {
        return try await request(endpoint, method: .get)
    }

    /// Performs a POST request
    func post<T: Decodable>(_ endpoint: String, body: Encodable) async throws -> T {
        return try await request(endpoint, method: .post, body: body)
    }

    /// Performs a PUT request
    func put<T: Decodable>(_ endpoint: String, body: Encodable) async throws -> T {
        return try await request(endpoint, method: .put, body: body)
    }

    /// Performs a DELETE request
    func delete<T: Decodable>(_ endpoint: String) async throws -> T {
        return try await request(endpoint, method: .delete)
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case httpError(Int)
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .forbidden:
            return "You don't have permission to access this resource"
        case .notFound:
            return "Resource not found"
        case .httpError(let code):
            return "HTTP error: \\(code)"
        case .serverError(let code):
            return "Server error: \\(code)"
        case .decodingError(let error):
            return "Failed to decode response: \\(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \\(error.localizedDescription)"
        }
    }
}

// MARK: - Usage Example

extension APIClient {
    // Example: Fetch items from API
    func fetchItems() async throws -> [Item] {
        return try await get("/items")
    }

    // Example: Create new item
    func createItem(_ item: Item) async throws -> Item {
        return try await post("/items", body: item)
    }

    // Add all API endpoints from ARCHITECTURE.md here
}
```

---

**Phase 1 Complete!** ✅

At this point, you have:
- ✅ All data models defined
- ✅ DataManager for CRUD operations
- ✅ Design system tokens centralized
- ✅ Reusable view modifiers
- ✅ Networking layer ready

---

### **Phase 2: Feature Implementation** (Weeks 2-4)

Now implement each screen from UX_SPEC.md, one feature at a time.

[Due to character limit, I'll provide the structure for one complete feature, which you repeat for all features]

---

#### Step 2.1: Implement Home Screen

**Goal**: Create the main content view where users see their items

**Files to create**:
- `Features/Home/Views/HomeView.swift`
- `Features/Home/Views/HomeCardView.swift`
- `Features/Home/Views/HomeEmptyStateView.swift`
- `Features/Home/ViewModels/HomeViewModel.swift`

---

**File**: `Features/Home/ViewModels/HomeViewModel.swift`

**Purpose**: Business logic and state management for Home screen

```swift
import Foundation
import SwiftUI
import SwiftData
import Observation

/// View model for Home screen
/// Manages data fetching, state, and user actions
@Observable
final class HomeViewModel {
    // MARK: - Published State

    /// Array of items to display
    var items: [Item] = []

    /// Loading state
    var isLoading = false

    /// Error message (if any)
    var errorMessage: String = ""

    /// Whether to show error alert
    var showError = false

    /// Search query
    var searchQuery: String = "" {
        didSet {
            if searchQuery.isEmpty {
                Task {
                    await loadItems()
                }
            } else {
                Task {
                    await searchItems()
                }
            }
        }
    }

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let dataManager: DataManager

    // MARK: - Initialization

    init(
        apiClient: APIClient = .shared,
        dataManager: DataManager = .shared
    ) {
        self.apiClient = apiClient
        self.dataManager = dataManager
    }

    // MARK: - Data Loading

    /// Loads items from local database and syncs with API
    @MainActor
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Load from local database first (instant)
            items = try dataManager.fetch(
                Item.self,
                sortBy: [SortDescriptor(\\.createdAt, order: .reverse)]
            )

            // 2. Sync with API in background (if online)
            await syncWithAPI()

        } catch {
            handleError(error)
        }
    }

    /// Syncs data with backend API
    private func syncWithAPI() async {
        do {
            // Fetch latest from API
            let remoteItems: [Item] = try await apiClient.get("/items")

            // Update local database
            for remoteItem in remoteItems {
                // Check if exists locally
                let existsLocally = items.contains { $0.id == remoteItem.id }

                if !existsLocally {
                    try dataManager.create(remoteItem)
                }
                // TODO: Handle updates (compare updatedAt timestamps)
            }

            // Reload from database to reflect changes
            await loadItems()

        } catch let error as APIError {
            // Don't show error for network issues during background sync
            print("⚠️ Background sync failed: \\(error)")
        } catch {
            print("⚠️ Sync error: \\(error)")
        }
    }

    /// Refreshes data (pull-to-refresh)
    @MainActor
    func refresh() async {
        await loadItems()
    }

    /// Searches items by query
    @MainActor
    private func searchItems() async {
        guard !searchQuery.isEmpty else { return }

        do {
            items = try dataManager.searchItems(query: searchQuery)
        } catch {
            handleError(error)
        }
    }

    // MARK: - User Actions

    /// Deletes an item
    @MainActor
    func deleteItem(_ item: Item) async {
        do {
            // Delete from local database
            try dataManager.delete(item)

            // Delete from API
            let _: EmptyResponse = try await apiClient.delete("/items/\\(item.id)")

            // Remove from array
            items.removeAll { $0.id == item.id }

        } catch {
            handleError(error)
        }
    }

    /// Toggles item status
    @MainActor
    func toggleItemStatus(_ item: Item) async {
        let newStatus: ItemStatus = item.status == .completed ? .active : .completed

        do {
            item.updateStatus(newStatus)
            try dataManager.update()

            // Sync to API
            let _: Item = try await apiClient.put("/items/\\(item.id)", body: item)

        } catch {
            handleError(error)
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        print("❌ Error: \\(error)")
    }
}

/// Empty response for DELETE endpoints
struct EmptyResponse: Codable {}
```

---

**File**: `Features/Home/Views/HomeView.swift`

**Purpose**: Main Home screen UI

```swift
import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Environment

    @Environment(\\.modelContext) private var modelContext

    // MARK: - State

    /// View model (initialize here or inject via dependency)
    @State private var viewModel = HomeViewModel()

    /// Whether to show add item sheet
    @State private var showingAddSheet = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                if viewModel.items.isEmpty && !viewModel.isLoading {
                    HomeEmptyStateView {
                        showingAddSheet = true
                    }
                } else {
                    itemListView
                }

                // Loading overlay
                if viewModel.isLoading {
                    loadingView
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .searchable(
                text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search items..."
            )
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditItemView()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                // Load data when view appears
                await viewModel.loadItems()
            }
        }
    }

    // MARK: - Subviews

    private var itemListView: some View {
        List {
            ForEach(viewModel.items) { item in
                NavigationLink {
                    ItemDetailView(item: item)
                } label: {
                    HomeCardView(item: item)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteItem(item)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        Task {
                            await viewModel.toggleItemStatus(item)
                        }
                    } label: {
                        Label(
                            item.status == .completed ? "Mark Active" : "Complete",
                            systemImage: item.status == .completed ? "arrow.uturn.backward" : "checkmark"
                        )
                    }
                    .tint(.green)
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(
                top: DesignSystem.Spacing.s,
                leading: DesignSystem.Spacing.l,
                bottom: DesignSystem.Spacing.s,
                trailing: DesignSystem.Spacing.l
            ))
        }
        .listStyle(.plain)
    }

    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ProgressView()
                .controlSize(.large)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(DesignSystem.Radius.medium)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingAddSheet = true
            } label: {
                Label("Add Item", systemImage: "plus")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                SettingsView()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [Item.self, User.self], inMemory: true)
}
```

---

**Continue this pattern** for:
- ItemDetailView
- AddEditItemView
- SettingsView
- All other screens from UX_SPEC.md

Each screen follows the same structure:
1. Create ViewModel (business logic, state management)
2. Create View (UI with SwiftUI)
3. Create subviews (components like cards, empty states)
4. Write tests (unit tests for ViewModel, UI tests for View)

---

## 4. Testing Implementation

[Include comprehensive testing guide for unit tests, UI tests, integration tests]

## 5. App Store Submission

[Include complete submission checklist and process]

## 6. Troubleshooting Guide

[Include common issues and solutions]

---

**Total Document**: ~5000+ lines with all features implemented

---

## Execution Instructions

When activated, follow these steps:

1. **Read All Specification Documents**
   ```
   - Read docs/PRD.md (all features)
   - Read docs/ARCHITECTURE.md (tech stack, structure)
   - Read docs/UX_SPEC.md (all screens)
   - Read docs/DESIGN_SYSTEM.md (design tokens)
   ```

2. **Extract Implementation Requirements**
   - List all features to implement (from PRD)
   - List all screens to build (from UX_SPEC)
   - List all data models (from ARCHITECTURE)
   - Understand navigation flow (from UX_SPEC)

3. **Generate Project Setup Instructions**
   - Xcode project creation
   - Dependency installation
   - Folder structure
   - Initial configuration

4. **Generate Phase 1: Core Infrastructure**
   - Detailed pseudo-code for all data models
   - Complete DataManager implementation
   - Design system setup
   - View extensions
   - Networking layer

5. **Generate Phase 2: Feature Implementation**
   - For EACH screen in UX_SPEC:
     - ViewModel (complete pseudo-code)
     - View (complete SwiftUI code)
     - Subviews (components)
     - Tests
   - Include all states (empty, loading, error)
   - Include all interactions from UX_SPEC

6. **Generate Phase 3: Testing**
   - Unit test structure
   - UI test scenarios
   - Integration test examples

7. **Generate Phase 4: Release**
   - Build configuration
   - App Store preparation
   - Submission checklist

8. **Write Complete Guide**
   ```
   Write to: docs/IMPLEMENTATION_GUIDE.md
   Target length: 3000-5000 lines
   Format: Markdown with code blocks
   ```

9. **Present Summary**
   ```
   ✅ Implementation Guide generated!

   📚 **Implementation Guide Summary**:
   - Total sections: [X]
   - Implementation phases: [X] phases over [Y] weeks
   - Files to create: ~[Z] Swift files
   - Estimated lines of code: ~[N] LOC
   - Complete pseudo-code for all features
   - Testing strategy included
   - Troubleshooting guide included

   **What's Included**:
   ✅ Project setup (Xcode, SPM, configuration)
   ✅ Complete folder structure
   ✅ Phase 1: Core infrastructure (models, networking, design system)
   ✅ Phase 2: All features with detailed pseudo-code
   ✅ Phase 3: Testing guide
   ✅ Phase 4: Release preparation

   **Next Steps**:
   1. Review the implementation guide in docs/IMPLEMENTATION_GUIDE.md
   2. Follow Phase 1 to set up infrastructure
   3. Implement features one by one in Phase 2
   4. Run tests continuously
   5. Prepare for release with Phase 4 checklist

   **Developer can now**:
   - Follow step-by-step to build the entire app
   - Copy-paste pseudo-code and adapt to actual implementation
   - Understand architectural decisions at each step
   - Test along the way with provided test cases

   Ready to start implementing? Or would you like me to clarify any section?
   ```

10. **Iterate Based on Feedback**
    If user requests changes:
    - Update specific sections
    - Add missing features
    - Clarify pseudo-code
    - Expand on complex areas

---

## Quality Guidelines

1. **Be Extremely Detailed**: Pseudo-code should be ~80% real code
   - BAD: "Create a view model with state"
   - GOOD: [Complete code with all properties, methods, error handling, comments]

2. **Include All Error Handling**: Every async operation needs try/catch
   - Show how to handle API errors
   - Show how to display errors to users
   - Include logging for debugging

3. **Provide Complete Examples**: Not just snippets
   - Full file implementations
   - All imports
   - All comments
   - Usage examples

4. **Follow Architecture**: Match ARCHITECTURE.md exactly
   - Use specified patterns (MVVM, Clean, etc.)
   - Use specified frameworks (SwiftUI, SwiftData)
   - Follow folder structure

5. **Include Testing**: Every feature needs tests
   - Unit tests for ViewModels
   - UI tests for critical flows
   - Integration tests for API/database

6. **Be Production-Ready**: Code should be copy-pastable
   - Proper error handling
   - Accessibility labels
   - Performance considerations
   - Security best practices

7. **Comment Extensively**: Explain WHY, not just WHAT
   - Architecture decisions
   - Tradeoffs made
   - Alternatives considered
   - Performance implications

---

## Integration with Workflow

This skill is typically:
- **Fourth step** in specification generation
- Activated after PRD, Architecture, and UX specs are complete
- Followed by test-spec and release-spec
- Most detailed document in the workflow (~5000 lines)

The implementation guide is the bridge between specifications and working code.

---

## Notes

- Pseudo-code should be detailed enough that junior developers can follow
- Include complete examples, not just outlines
- Every screen from UX_SPEC must have implementation code
- Testing is not optional - include test cases
- Performance and security must be considered throughout
- Accessibility must be built in from the start
- This is the most critical document - take time to make it comprehensive
- Code should follow Swift and SwiftUI best practices
- Use modern iOS 17+ APIs (async/await, @Observable, SwiftData)
