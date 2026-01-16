import AppIntents

/// App Shortcuts provider for Siri and Shortcuts app.
///
/// Defines the shortcuts that appear in the Shortcuts app
/// and the phrases Siri recognizes.
struct AppShortcuts: AppShortcutsProvider {

    /// App shortcuts available to users.
    static var appShortcuts: [AppShortcut] {
        // Open item shortcut
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

        // Search shortcut
        AppShortcut(
            intent: SearchIntent(),
            phrases: [
                "Search for \(\.$query) in \(.applicationName)",
                "Find \(\.$query) in \(.applicationName)",
                "Look up \(\.$query)"
            ],
            shortTitle: "Search",
            systemImageName: "magnifyingglass"
        )

        // Create item shortcut
        AppShortcut(
            intent: CreateItemIntent(),
            phrases: [
                "Create a new \(\.$type) in \(.applicationName)",
                "Add \(\.$type) to \(.applicationName)",
                "New \(\.$type)"
            ],
            shortTitle: "Create",
            systemImageName: "plus.circle.fill"
        )

        // Open settings shortcut
        AppShortcut(
            intent: OpenSettingsIntent(),
            phrases: [
                "Open \(.applicationName) settings",
                "\(.applicationName) preferences"
            ],
            shortTitle: "Settings",
            systemImageName: "gear"
        )
    }
}

// MARK: - Open Item Intent

/// Intent to open a specific item.
struct OpenItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Item"
    static let description = IntentDescription("Opens a specific item in the app")

    static let openAppWhenRun: Bool = true

    @Parameter(title: "Item", requestValueDialog: "Which item would you like to open?")
    var target: ItemEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        let router = DeepLinkRouter.shared
        router.navigate(to: .item(itemId: target.id))
        return .result()
    }
}

// MARK: - Search Intent

/// Intent to search for items.
struct SearchIntent: AppIntent {
    static let title: LocalizedStringResource = "Search"
    static let description = IntentDescription("Search for items in the app")

    static let openAppWhenRun: Bool = true

    @Parameter(title: "Query")
    var query: String

    @MainActor
    func perform() async throws -> some IntentResult {
        let router = DeepLinkRouter.shared
        router.navigate(to: .search(query: query))
        return .result()
    }
}

// MARK: - Create Item Intent

/// Intent to create a new item.
struct CreateItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Item"
    static let description = IntentDescription("Create a new item in the app")

    static let openAppWhenRun: Bool = true

    @Parameter(title: "Type", default: .note)
    var type: ContentTypeEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        let router = DeepLinkRouter.shared
        router.navigate(to: .create(type: type.deepLinkType))
        return .result()
    }
}

// MARK: - Open Settings Intent

/// Intent to open app settings.
struct OpenSettingsIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Settings"
    static let description = IntentDescription("Opens the app settings")

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let router = DeepLinkRouter.shared
        router.navigate(to: .settings)
        return .result()
    }
}

// MARK: - Content Type Entity

/// App Intents entity for content types.
struct ContentTypeEntity: AppEnum {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Content Type")

    static let caseDisplayRepresentations: [ContentTypeEntity: DisplayRepresentation] = [
        .note: DisplayRepresentation(title: "Note", image: .init(systemName: "note.text")),
        .task: DisplayRepresentation(title: "Task", image: .init(systemName: "checkmark.circle")),
        .reminder: DisplayRepresentation(title: "Reminder", image: .init(systemName: "bell")),
        .folder: DisplayRepresentation(title: "Folder", image: .init(systemName: "folder"))
    ]

    case note
    case task
    case reminder
    case folder

    /// Convert to DeepLink content type.
    var deepLinkType: DeepLink.ContentType {
        switch self {
        case .note: return .note
        case .task: return .task
        case .reminder: return .reminder
        case .folder: return .folder
        }
    }
}

// MARK: - Item Entity

/// App Intents entity for items.
///
/// This enables Siri to understand and reference items in your app.
struct ItemEntity: AppEntity {

    // MARK: - AppEntity

    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Item",
        numericFormat: "\(placeholder: .int) items"
    )

    static var defaultQuery = ItemEntityQuery()

    // MARK: - Properties

    var id: String
    var name: String
    var category: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(category)",
            image: .init(systemName: "doc.fill")
        )
    }
}

// MARK: - Item Entity Query

/// Query handler for ItemEntity.
struct ItemEntityQuery: EntityQuery {

    /// Fetch items by their IDs.
    func entities(for identifiers: [String]) async throws -> [ItemEntity] {
        // TODO: Implement actual data fetching
        // return await DataStore.shared.items(ids: identifiers)

        // Placeholder implementation
        return identifiers.map { id in
            ItemEntity(id: id, name: "Item \(id)", category: "General")
        }
    }

    /// Suggest items to the user.
    func suggestedEntities() async throws -> [ItemEntity] {
        // TODO: Return recently accessed or popular items
        // return await DataStore.shared.recentItems(limit: 5)

        // Placeholder implementation
        return [
            ItemEntity(id: "1", name: "Recent Item 1", category: "General"),
            ItemEntity(id: "2", name: "Recent Item 2", category: "Work"),
            ItemEntity(id: "3", name: "Recent Item 3", category: "Personal")
        ]
    }
}

// MARK: - String Search (Optional)

extension ItemEntityQuery: EntityStringQuery {

    /// Search items by string.
    func entities(matching string: String) async throws -> [ItemEntity] {
        // TODO: Implement search
        // return await DataStore.shared.search(query: string)

        // Placeholder implementation
        return [
            ItemEntity(id: "search-1", name: "Result for '\(string)'", category: "Search")
        ]
    }
}
