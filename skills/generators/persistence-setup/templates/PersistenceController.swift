import Foundation
import SwiftData

/// Central persistence controller managing the SwiftData container.
///
/// Usage:
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .modelContainer(PersistenceController.shared.container)
///         }
///     }
/// }
/// ```
@MainActor
final class PersistenceController: Sendable {

    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Container

    /// The main model container.
    let container: ModelContainer

    // MARK: - Initialization

    private init() {
        // Define schema with all model types
        let schema = Schema([
            Item.self,
            // Add more models here as your app grows
        ])

        // Configure storage
        // For iCloud sync, use CloudKitConfiguration instead
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Preview Container

    /// In-memory container for SwiftUI previews.
    static var preview: ModelContainer {
        let schema = Schema([Item.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: configuration
            )

            // Add sample data for previews
            let context = container.mainContext
            let sampleItems = [
                Item(title: "First Item"),
                Item(title: "Second Item"),
                Item(title: "Third Item"),
            ]
            for item in sampleItems {
                context.insert(item)
            }
            try context.save()

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}

// MARK: - Convenience Extensions

extension PersistenceController {

    /// Main context for UI operations.
    var mainContext: ModelContext {
        container.mainContext
    }

    /// Create a new background context for heavy operations.
    func newBackgroundContext() -> ModelContext {
        ModelContext(container)
    }
}
