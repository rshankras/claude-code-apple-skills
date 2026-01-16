import SwiftUI

/// Central router for deep link navigation.
///
/// Setup in App:
/// ```swift
/// @main
/// struct MyApp: App {
///     @State private var router = DeepLinkRouter()
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(router)
///                 .onOpenURL { url in
///                     router.handle(url)
///                 }
///         }
///     }
/// }
/// ```
@MainActor
@Observable
final class DeepLinkRouter {

    // MARK: - Singleton (optional)

    /// Shared instance for use in App Intents.
    static let shared = DeepLinkRouter()

    // MARK: - Navigation State

    /// Navigation path for NavigationStack.
    var path = NavigationPath()

    /// Currently selected tab (if using TabView).
    var selectedTab: Tab = .home

    /// Sheet presentation state.
    var activeSheet: SheetDestination?

    // MARK: - Deferred Handling

    /// Pending deep link awaiting app readiness.
    private(set) var pendingDeepLink: DeepLink?

    /// Whether the app is ready to handle navigation.
    var isReady = false {
        didSet {
            if isReady, let pending = pendingDeepLink {
                pendingDeepLink = nil
                navigate(to: pending)
            }
        }
    }

    // MARK: - Types

    enum Tab: String, CaseIterable {
        case home
        case search
        case profile
        case settings
    }

    enum SheetDestination: Identifiable {
        case share(itemId: String)
        case create(type: DeepLink.ContentType)

        var id: String {
            switch self {
            case .share(let itemId): return "share-\(itemId)"
            case .create(let type): return "create-\(type.rawValue)"
            }
        }
    }

    // MARK: - URL Handling

    /// Handle an incoming URL.
    ///
    /// - Parameter url: The URL to handle (custom scheme or universal link).
    func handle(_ url: URL) {
        guard let deepLink = DeepLink(url: url) else {
            #if DEBUG
            print("⚠️ [DeepLink] Unrecognized URL: \(url)")
            #endif
            return
        }

        #if DEBUG
        print("🔗 [DeepLink] Handling: \(deepLink)")
        #endif

        if isReady {
            navigate(to: deepLink)
        } else {
            pendingDeepLink = deepLink
        }
    }

    // MARK: - Navigation

    /// Navigate to a deep link destination.
    ///
    /// - Parameter deepLink: The destination to navigate to.
    func navigate(to deepLink: DeepLink) {
        // Dismiss any presented sheet
        activeSheet = nil

        switch deepLink {
        case .home:
            selectedTab = .home
            path = NavigationPath()

        case .profile(let userId):
            selectedTab = .profile
            path = NavigationPath()
            path.append(ProfileDestination(userId: userId))

        case .item(let itemId):
            selectedTab = .home
            path = NavigationPath()
            path.append(ItemDestination(itemId: itemId))

        case .category(let categoryId):
            selectedTab = .home
            path = NavigationPath()
            path.append(CategoryDestination(categoryId: categoryId))

        case .search(let query):
            selectedTab = .search
            path = NavigationPath()
            if !query.isEmpty {
                path.append(SearchDestination(query: query))
            }

        case .settings:
            selectedTab = .settings
            path = NavigationPath()

        case .settingsSection(let section):
            selectedTab = .settings
            path = NavigationPath()
            path.append(SettingsSectionDestination(section: section))

        case .share(let itemId):
            activeSheet = .share(itemId: itemId)

        case .create(let type):
            activeSheet = .create(type: type)
        }
    }

    /// Pop to root of current navigation stack.
    func popToRoot() {
        path = NavigationPath()
    }

    /// Pop one level in navigation stack.
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}

// MARK: - Navigation Destinations

/// Profile screen destination.
struct ProfileDestination: Hashable {
    let userId: String
}

/// Item detail destination.
struct ItemDestination: Hashable {
    let itemId: String
}

/// Category listing destination.
struct CategoryDestination: Hashable {
    let categoryId: String
}

/// Search results destination.
struct SearchDestination: Hashable {
    let query: String
}

/// Settings section destination.
struct SettingsSectionDestination: Hashable {
    let section: DeepLink.SettingsSection
}

// MARK: - SwiftUI Environment

/// Environment key for DeepLinkRouter.
private struct DeepLinkRouterKey: EnvironmentKey {
    @MainActor static let defaultValue = DeepLinkRouter.shared
}

extension EnvironmentValues {
    var deepLinkRouter: DeepLinkRouter {
        get { self[DeepLinkRouterKey.self] }
        set { self[DeepLinkRouterKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Configure navigation destinations for deep linking.
    func withDeepLinkDestinations() -> some View {
        self
            .navigationDestination(for: ProfileDestination.self) { dest in
                // ProfileView(userId: dest.userId)
                Text("Profile: \(dest.userId)")
            }
            .navigationDestination(for: ItemDestination.self) { dest in
                // ItemDetailView(itemId: dest.itemId)
                Text("Item: \(dest.itemId)")
            }
            .navigationDestination(for: CategoryDestination.self) { dest in
                // CategoryView(categoryId: dest.categoryId)
                Text("Category: \(dest.categoryId)")
            }
            .navigationDestination(for: SearchDestination.self) { dest in
                // SearchResultsView(query: dest.query)
                Text("Search: \(dest.query)")
            }
            .navigationDestination(for: SettingsSectionDestination.self) { dest in
                // SettingsSectionView(section: dest.section)
                Text("Settings: \(dest.section.rawValue)")
            }
    }
}
