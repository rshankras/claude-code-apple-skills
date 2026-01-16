import Foundation

/// Defines all deep link routes in the app.
///
/// Usage:
/// ```swift
/// // Parse from URL
/// let deepLink = DeepLink(url: url)
///
/// // Create URL for sharing
/// let url = DeepLink.item(itemId: "123").toURL()
/// ```
enum DeepLink: Equatable, Hashable, Sendable {

    // MARK: - Navigation Routes

    /// Home screen
    case home

    /// User profile
    case profile(userId: String)

    /// Item detail
    case item(itemId: String)

    /// Category listing
    case category(categoryId: String)

    /// Search with optional query
    case search(query: String)

    /// Settings screen
    case settings

    /// Specific settings section
    case settingsSection(SettingsSection)

    // MARK: - Action Routes

    /// Share an item
    case share(itemId: String)

    /// Create new content
    case create(type: ContentType)

    // MARK: - Nested Types

    enum SettingsSection: String, Sendable, CaseIterable {
        case account
        case notifications
        case appearance
        case privacy
        case about
    }

    enum ContentType: String, Sendable, CaseIterable {
        case note
        case task
        case reminder
        case folder
    }
}

// MARK: - URL Parsing

extension DeepLink {

    /// Your app's custom URL scheme.
    static let scheme = "myapp"  // TODO: Replace with your scheme

    /// Allowed hosts for universal links.
    static let allowedHosts = [
        "yourapp.com",           // TODO: Replace with your domain
        "www.yourapp.com"
    ]

    /// Initialize from a URL (custom scheme or universal link).
    ///
    /// Supports:
    /// - Custom scheme: `myapp://items/123`
    /// - Universal link: `https://yourapp.com/items/123`
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        // Validate scheme for custom URLs or host for universal links
        if let scheme = components.scheme?.lowercased() {
            if scheme == Self.scheme {
                // Custom URL scheme - continue parsing
            } else if scheme == "https" || scheme == "http" {
                // Universal link - validate host
                guard let host = components.host?.lowercased(),
                      Self.allowedHosts.contains(host) else {
                    return nil
                }
            } else {
                return nil
            }
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
        self.init(pathComponents: pathComponents, params: params)
    }

    private init?(pathComponents: [String], params: [String: String]) {
        switch pathComponents {
        case []:
            self = .home

        case ["users", let userId]:
            self = .profile(userId: userId)

        case ["profiles", let userId]:  // Alternative path
            self = .profile(userId: userId)

        case ["items", let itemId]:
            self = .item(itemId: itemId)

        case ["categories", let categoryId]:
            self = .category(categoryId: categoryId)

        case ["search"]:
            let query = params["q"] ?? params["query"] ?? ""
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

        case ["create"]:
            if let typeString = params["type"],
               let contentType = ContentType(rawValue: typeString) {
                self = .create(type: contentType)
            } else {
                return nil
            }

        case ["create", let typeString]:
            if let contentType = ContentType(rawValue: typeString) {
                self = .create(type: contentType)
            } else {
                return nil
            }

        default:
            return nil
        }
    }
}

// MARK: - URL Generation

extension DeepLink {

    /// Convert to URL with custom scheme.
    func toURL() -> URL? {
        toURL(scheme: Self.scheme)
    }

    /// Convert to universal link URL.
    func toUniversalURL() -> URL? {
        guard let host = Self.allowedHosts.first else { return nil }
        return toURL(scheme: "https", host: host)
    }

    /// Convert to URL with specified scheme and optional host.
    func toURL(scheme: String, host: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host

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
            if !query.isEmpty {
                components.queryItems = [URLQueryItem(name: "q", value: query)]
            }

        case .settings:
            components.path = "/settings"

        case .settingsSection(let section):
            components.path = "/settings/\(section.rawValue)"

        case .share(let itemId):
            components.path = "/share/\(itemId)"

        case .create(let type):
            components.path = "/create/\(type.rawValue)"
        }

        return components.url
    }
}

// MARK: - Display

extension DeepLink: CustomStringConvertible {

    var description: String {
        switch self {
        case .home:
            return "Home"
        case .profile(let userId):
            return "Profile(\(userId))"
        case .item(let itemId):
            return "Item(\(itemId))"
        case .category(let categoryId):
            return "Category(\(categoryId))"
        case .search(let query):
            return "Search(\(query))"
        case .settings:
            return "Settings"
        case .settingsSection(let section):
            return "Settings/\(section.rawValue)"
        case .share(let itemId):
            return "Share(\(itemId))"
        case .create(let type):
            return "Create(\(type.rawValue))"
        }
    }
}
