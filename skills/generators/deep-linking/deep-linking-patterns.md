# Deep Linking Patterns

Best practices for implementing deep links, Universal Links, and App Intents in iOS/macOS apps.

## URL Scheme Handling

### Route Definition

```swift
/// Defines all deep link routes in the app.
enum DeepLink: Equatable, Hashable, Sendable {
    // Navigation routes
    case home
    case profile(userId: String)
    case item(itemId: String)
    case category(categoryId: String)
    case search(query: String)
    case settings
    case settingsSection(SettingsSection)

    // Action routes
    case share(itemId: String)
    case create(type: ContentType)
    case compose(to: String?, subject: String?)

    // MARK: - Nested Types

    enum SettingsSection: String, Sendable {
        case account
        case notifications
        case appearance
        case privacy
    }

    enum ContentType: String, Sendable {
        case note
        case task
        case reminder
    }
}
```

### URL Parsing

```swift
extension DeepLink {

    /// Initialize from a URL (custom scheme or universal link).
    init?(url: URL) {
        // Handle both custom scheme (myapp://) and universal links (https://)
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        // Parse path components
        let pathComponents = components.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .split(separator: "/")
            .map(String.init)

        // Parse query parameters
        let queryItems = components.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        // Route matching
        switch pathComponents {
        case []:
            self = .home

        case ["users", let userId]:
            self = .profile(userId: userId)

        case ["items", let itemId]:
            self = .item(itemId: itemId)

        case ["categories", let categoryId]:
            self = .category(categoryId: categoryId)

        case ["search"]:
            let query = params["q"] ?? ""
            self = .search(query: query)

        case ["settings"]:
            self = .settings

        case ["settings", let section]:
            if let section = SettingsSection(rawValue: section) {
                self = .settingsSection(section)
            } else {
                self = .settings
            }

        case ["share", let itemId]:
            self = .share(itemId: itemId)

        case ["create", let type]:
            if let contentType = ContentType(rawValue: type) {
                self = .create(type: contentType)
            } else {
                return nil
            }

        case ["compose"]:
            self = .compose(to: params["to"], subject: params["subject"])

        default:
            return nil
        }
    }

    /// Convert back to URL for sharing or logging.
    func toURL(scheme: String = "myapp") -> URL? {
        var components = URLComponents()
        components.scheme = scheme

        switch self {
        case .home:
            components.path = "/"

        case .profile(let userId):
            components.path = "/users/\(userId)"

        case .item(let itemId):
            components.path = "/items/\(itemId)"

        case .category(let categoryId):
            components.path = "/categories/\(categoryId)"

        case .search(let query):
            components.path = "/search"
            components.queryItems = [URLQueryItem(name: "q", value: query)]

        case .settings:
            components.path = "/settings"

        case .settingsSection(let section):
            components.path = "/settings/\(section.rawValue)"

        case .share(let itemId):
            components.path = "/share/\(itemId)"

        case .create(let type):
            components.path = "/create/\(type.rawValue)"

        case .compose(let to, let subject):
            components.path = "/compose"
            var items: [URLQueryItem] = []
            if let to { items.append(URLQueryItem(name: "to", value: to)) }
            if let subject { items.append(URLQueryItem(name: "subject", value: subject)) }
            if !items.isEmpty { components.queryItems = items }
        }

        return components.url
    }
}
```

## Router Implementation

### Observable Router

```swift
import SwiftUI

/// Central deep link router for navigation.
@MainActor
@Observable
final class DeepLinkRouter {

    // MARK: - Properties

    /// Current navigation path for NavigationStack.
    var path = NavigationPath()

    /// Pending deep link (for deferred handling).
    private(set) var pendingDeepLink: DeepLink?

    /// Whether the app is ready to handle deep links.
    var isReady = false {
        didSet {
            if isReady, let pending = pendingDeepLink {
                pendingDeepLink = nil
                navigate(to: pending)
            }
        }
    }

    // MARK: - URL Handling

    /// Handle an incoming URL.
    func handle(_ url: URL) {
        guard let deepLink = DeepLink(url: url) else {
            print("⚠️ [DeepLink] Unrecognized URL: \(url)")
            return
        }

        print("🔗 [DeepLink] Handling: \(deepLink)")

        if isReady {
            navigate(to: deepLink)
        } else {
            // Defer until app is ready
            pendingDeepLink = deepLink
        }
    }

    // MARK: - Navigation

    /// Navigate to a deep link destination.
    func navigate(to deepLink: DeepLink) {
        // Reset navigation path
        path = NavigationPath()

        // Add appropriate destinations
        switch deepLink {
        case .home:
            break  // Already at root

        case .profile(let userId):
            path.append(ProfileDestination(userId: userId))

        case .item(let itemId):
            path.append(ItemDestination(itemId: itemId))

        case .category(let categoryId):
            path.append(CategoryDestination(categoryId: categoryId))

        case .search(let query):
            path.append(SearchDestination(query: query))

        case .settings:
            path.append(SettingsDestination())

        case .settingsSection(let section):
            path.append(SettingsDestination())
            path.append(SettingsSectionDestination(section: section))

        case .share(let itemId):
            // Handle share action
            NotificationCenter.default.post(
                name: .shareItem,
                object: nil,
                userInfo: ["itemId": itemId]
            )

        case .create(let type):
            NotificationCenter.default.post(
                name: .createContent,
                object: nil,
                userInfo: ["type": type]
            )

        case .compose(let to, let subject):
            NotificationCenter.default.post(
                name: .compose,
                object: nil,
                userInfo: ["to": to as Any, "subject": subject as Any]
            )
        }
    }
}

// MARK: - Navigation Destinations

struct ProfileDestination: Hashable {
    let userId: String
}

struct ItemDestination: Hashable {
    let itemId: String
}

struct CategoryDestination: Hashable {
    let categoryId: String
}

struct SearchDestination: Hashable {
    let query: String
}

struct SettingsDestination: Hashable {}

struct SettingsSectionDestination: Hashable {
    let section: DeepLink.SettingsSection
}

// MARK: - Notification Names

extension Notification.Name {
    static let shareItem = Notification.Name("shareItem")
    static let createContent = Notification.Name("createContent")
    static let compose = Notification.Name("compose")
}
```

### SwiftUI Integration

```swift
@main
struct MyApp: App {
    @State private var router = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .onOpenURL { url in
                    router.handle(url)
                }
                .onAppear {
                    router.isReady = true
                }
        }
    }
}

struct ContentView: View {
    @Environment(DeepLinkRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: ProfileDestination.self) { dest in
                    ProfileView(userId: dest.userId)
                }
                .navigationDestination(for: ItemDestination.self) { dest in
                    ItemDetailView(itemId: dest.itemId)
                }
                .navigationDestination(for: SearchDestination.self) { dest in
                    SearchView(initialQuery: dest.query)
                }
                .navigationDestination(for: SettingsDestination.self) { _ in
                    SettingsView()
                }
        }
    }
}
```

## Universal Links

### Apple App Site Association (AASA)

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": [
          "TEAMID.com.yourcompany.yourapp"
        ],
        "components": [
          {
            "/": "/items/*",
            "comment": "Item detail pages"
          },
          {
            "/": "/users/*",
            "comment": "User profile pages"
          },
          {
            "/": "/share/*",
            "comment": "Share links"
          },
          {
            "/": "/invite/*",
            "?": { "code": "*" },
            "comment": "Invite links with code"
          }
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": [
      "TEAMID.com.yourcompany.yourapp"
    ]
  }
}
```

### Server Requirements

1. Host AASA at `/.well-known/apple-app-site-association`
2. Serve with `Content-Type: application/json`
3. Use HTTPS with valid certificate
4. No redirects allowed
5. File size under 128 KB

### Validation

```swift
/// Validate universal link before handling.
struct UniversalLinkValidator {

    static let allowedHosts = [
        "yourapp.com",
        "www.yourapp.com",
        "links.yourapp.com"
    ]

    static func isValid(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }
        return allowedHosts.contains(host)
    }
}
```

## App Intents

### Entity Definition

```swift
import AppIntents
import CoreSpotlight

struct ItemEntity: AppEntity, IndexedEntity {

    // MARK: - AppEntity

    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Item",
        numericFormat: "\(placeholder: .int) items"
    )

    static var defaultQuery = ItemQuery()

    var id: String
    var name: String
    var description: String
    var category: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(category)",
            image: .init(systemName: "doc.fill")
        )
    }

    // MARK: - IndexedEntity

    var searchableAttributes: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.title = name
        attributes.contentDescription = description
        attributes.keywords = [category]
        return attributes
    }
}

struct ItemQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ItemEntity] {
        // Fetch items by IDs from your data source
        await DataStore.shared.items(ids: identifiers)
    }

    func suggestedEntities() async throws -> [ItemEntity] {
        // Return recently accessed items
        await DataStore.shared.recentItems(limit: 5)
    }
}
```

### Open Intent

```swift
import AppIntents

struct OpenItemIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Item"
    static let description = IntentDescription("Opens a specific item in the app")

    @Parameter(title: "Item", requestValueDialog: "Which item would you like to open?")
    var target: ItemEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        // Navigate to the item
        let router = DeepLinkRouter.shared
        router.navigate(to: .item(itemId: target.id))

        return .result()
    }
}

struct SearchItemsIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Items"
    static let description = IntentDescription("Search for items in the app")

    @Parameter(title: "Query")
    var query: String

    @MainActor
    func perform() async throws -> some ReturnsValue<[ItemEntity]> {
        let results = await DataStore.shared.search(query: query)
        return .result(value: results)
    }
}
```

### App Shortcuts Provider

```swift
import AppIntents

struct AppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenItemIntent(),
            phrases: [
                "Open \(\.$target) in \(.applicationName)",
                "Show \(\.$target) in \(.applicationName)",
                "Go to \(\.$target)"
            ],
            shortTitle: "Open Item",
            systemImageName: "doc.fill"
        )

        AppShortcut(
            intent: SearchItemsIntent(),
            phrases: [
                "Search for \(\.$query) in \(.applicationName)",
                "Find \(\.$query) in \(.applicationName)"
            ],
            shortTitle: "Search",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: CreateItemIntent(),
            phrases: [
                "Create a new item in \(.applicationName)",
                "Add item to \(.applicationName)"
            ],
            shortTitle: "Create Item",
            systemImageName: "plus"
        )
    }
}
```

### Spotlight Indexing

```swift
import CoreSpotlight

struct SpotlightIndexer {

    static func indexItems(_ items: [ItemEntity]) async throws {
        try await CSSearchableIndex.default().indexAppEntities(
            items,
            priority: .normal
        )
    }

    static func removeItem(_ item: ItemEntity) async throws {
        try await CSSearchableIndex.default().deleteAppEntities(
            identifiedBy: [item.id],
            ofType: ItemEntity.self
        )
    }

    static func reindexAll() async throws {
        // Delete all existing entries
        try await CSSearchableIndex.default().deleteAllSearchableItems()

        // Fetch and reindex
        let items = await DataStore.shared.allItems()
        try await indexItems(items)
    }
}
```

## NSUserActivity

### Handoff and State Restoration

```swift
extension DeepLink {

    /// Activity type for NSUserActivity.
    var activityType: String {
        "com.yourcompany.yourapp.\(activityIdentifier)"
    }

    private var activityIdentifier: String {
        switch self {
        case .home: return "home"
        case .profile: return "viewProfile"
        case .item: return "viewItem"
        case .category: return "viewCategory"
        case .search: return "search"
        case .settings, .settingsSection: return "settings"
        case .share: return "share"
        case .create: return "create"
        case .compose: return "compose"
        }
    }

    /// Create NSUserActivity for this deep link.
    func userActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: activityType)
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true

        switch self {
        case .item(let itemId):
            activity.title = "View Item"
            activity.userInfo = ["itemId": itemId]
            activity.webpageURL = URL(string: "https://yourapp.com/items/\(itemId)")

        case .profile(let userId):
            activity.title = "View Profile"
            activity.userInfo = ["userId": userId]
            activity.webpageURL = URL(string: "https://yourapp.com/users/\(userId)")

        case .search(let query):
            activity.title = "Search: \(query)"
            activity.userInfo = ["query": query]

        default:
            break
        }

        return activity
    }

    /// Parse from NSUserActivity.
    init?(userActivity: NSUserActivity) {
        // Try webpage URL first (Universal Links)
        if let url = userActivity.webpageURL,
           let deepLink = DeepLink(url: url) {
            self = deepLink
            return
        }

        // Try userInfo
        let userInfo = userActivity.userInfo ?? [:]

        switch userActivity.activityType {
        case "com.yourcompany.yourapp.viewItem":
            guard let itemId = userInfo["itemId"] as? String else { return nil }
            self = .item(itemId: itemId)

        case "com.yourcompany.yourapp.viewProfile":
            guard let userId = userInfo["userId"] as? String else { return nil }
            self = .profile(userId: userId)

        case "com.yourcompany.yourapp.search":
            let query = userInfo["query"] as? String ?? ""
            self = .search(query: query)

        default:
            return nil
        }
    }
}
```

### SwiftUI UserActivity

```swift
struct ItemDetailView: View {
    let itemId: String
    @State private var item: Item?

    var body: some View {
        Group {
            if let item {
                ItemContent(item: item)
            } else {
                ProgressView()
            }
        }
        .userActivity(DeepLink.item(itemId: itemId).activityType) { activity in
            activity.title = item?.name ?? "Item"
            activity.userInfo = ["itemId": itemId]
            activity.webpageURL = URL(string: "https://yourapp.com/items/\(itemId)")
            activity.isEligibleForHandoff = true
        }
        .task {
            item = await DataStore.shared.item(id: itemId)
        }
    }
}
```

## Testing

### URL Scheme Testing

```swift
#if DEBUG
struct DeepLinkTester: View {
    @Environment(DeepLinkRouter.self) private var router
    @State private var testURL = "myapp://items/123"

    var body: some View {
        VStack {
            TextField("URL", text: $testURL)
                .textFieldStyle(.roundedBorder)

            Button("Test Deep Link") {
                if let url = URL(string: testURL) {
                    router.handle(url)
                }
            }
        }
        .padding()
    }
}
#endif
```

### Unit Tests

```swift
import XCTest
@testable import YourApp

final class DeepLinkTests: XCTestCase {

    func testItemParsing() {
        let url = URL(string: "myapp://items/123")!
        let deepLink = DeepLink(url: url)

        XCTAssertEqual(deepLink, .item(itemId: "123"))
    }

    func testSearchWithQuery() {
        let url = URL(string: "myapp://search?q=hello%20world")!
        let deepLink = DeepLink(url: url)

        XCTAssertEqual(deepLink, .search(query: "hello world"))
    }

    func testUniversalLink() {
        let url = URL(string: "https://yourapp.com/users/456")!
        let deepLink = DeepLink(url: url)

        XCTAssertEqual(deepLink, .profile(userId: "456"))
    }

    func testRoundTrip() {
        let original = DeepLink.item(itemId: "789")
        let url = original.toURL()!
        let parsed = DeepLink(url: url)

        XCTAssertEqual(parsed, original)
    }
}
```
