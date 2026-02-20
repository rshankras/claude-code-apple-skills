# Widget Code Templates

Production-ready Swift templates for WidgetKit widgets. All code targets iOS 17+ and uses modern Swift concurrency with App Intents.

## Widget Definition (StaticConfiguration)

Use this for widgets that do not require user configuration.

```swift
import SwiftUI
import WidgetKit

/// A widget that displays {description}.
struct MyWidget: Widget {
    let kind = "MyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MyTimelineProvider()
        ) { entry in
            MyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("Shows important information at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled() // Optional: remove default content margins
    }
}
```

## Widget Definition (AppIntentConfiguration)

Use this for configurable and interactive widgets (iOS 17+). The user can long-press the widget and choose what it displays.

```swift
import SwiftUI
import WidgetKit

/// A configurable widget that displays {description}.
struct MyWidget: Widget {
    let kind = "MyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: MyWidgetConfigurationIntent.self,
            provider: MyAppIntentTimelineProvider()
        ) { entry in
            MyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("Shows information you choose.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
```

## Timeline Entry

The data model that the timeline provider produces and the views consume.

```swift
import WidgetKit
import Foundation

/// A single entry in the widget timeline.
struct MyWidgetEntry: TimelineEntry {
    /// The date at which the widget should be displayed.
    let date: Date

    /// The data to display. Use an enum or optional to handle loading/error states.
    let title: String
    let value: String
    let subtitle: String?
    let progress: Double?
    let iconName: String

    /// Whether this is placeholder data for the widget gallery.
    let isPlaceholder: Bool

    // MARK: - Convenience Initializers

    /// Placeholder entry shown in the widget gallery before data loads.
    static var placeholder: MyWidgetEntry {
        MyWidgetEntry(
            date: .now,
            title: "Widget Title",
            value: "42",
            subtitle: "Subtitle text",
            progress: 0.65,
            iconName: "star.fill",
            isPlaceholder: true
        )
    }

    /// Snapshot entry for the widget picker and gallery.
    static var snapshot: MyWidgetEntry {
        MyWidgetEntry(
            date: .now,
            title: "Today's Progress",
            value: "1,234",
            subtitle: "Steps today",
            progress: 0.65,
            iconName: "figure.walk",
            isPlaceholder: false
        )
    }
}
```

## Timeline Provider (Static)

For `StaticConfiguration` widgets with no user configuration.

```swift
import WidgetKit
import Foundation

/// Provides timeline entries for the widget.
///
/// The system calls these methods at different times:
/// - `placeholder`: Immediately, for the widget gallery redacted preview.
/// - `getSnapshot`: When showing the widget in the gallery or during transitions.
/// - `getTimeline`: When the widget needs fresh data. The system manages call frequency.
struct MyTimelineProvider: TimelineProvider {
    typealias Entry = MyWidgetEntry

    /// Provides a placeholder entry used in the widget gallery.
    /// This is displayed with a redacted modifier. Return instantly with representative data.
    func placeholder(in context: Context) -> MyWidgetEntry {
        .placeholder
    }

    /// Provides a snapshot for the widget gallery and transient situations.
    /// Should return quickly. Use sample data if real data is not immediately available.
    func getSnapshot(in context: Context, completion: @escaping (MyWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.snapshot)
            return
        }

        Task {
            let entry = await fetchCurrentEntry()
            completion(entry)
        }
    }

    /// Provides a timeline of entries for the widget to display over time.
    /// Include a reload policy so the system knows when to ask for new data.
    func getTimeline(in context: Context, completion: @escaping (Timeline<MyWidgetEntry>) -> Void) {
        Task {
            let currentEntry = await fetchCurrentEntry()

            // Option 1: Single entry, refresh after a fixed interval
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
            let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))

            // Option 2: Multiple entries for known future states
            // var entries: [MyWidgetEntry] = []
            // for hourOffset in 0..<5 {
            //     let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: .now)!
            //     let entry = MyWidgetEntry(date: entryDate, ...)
            //     entries.append(entry)
            // }
            // let timeline = Timeline(entries: entries, policy: .atEnd)

            completion(timeline)
        }
    }

    // MARK: - Data Fetching

    /// Fetch the current data for the widget.
    private func fetchCurrentEntry() async -> MyWidgetEntry {
        // Replace with real data fetching logic:
        // - Read from App Group shared UserDefaults
        // - Query a local database (SwiftData, Core Data)
        // - Make a network request (keep it fast)

        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.yourapp")
        let title = sharedDefaults?.string(forKey: "widgetTitle") ?? "No Data"
        let value = sharedDefaults?.string(forKey: "widgetValue") ?? "--"

        return MyWidgetEntry(
            date: .now,
            title: title,
            value: value,
            subtitle: nil,
            progress: nil,
            iconName: "star.fill",
            isPlaceholder: false
        )
    }
}
```

## Timeline Provider (AppIntentConfiguration)

For `AppIntentConfiguration` widgets where the user can choose what to display.

```swift
import WidgetKit
import AppIntents
import Foundation

/// Provides timeline entries for a configurable widget.
///
/// The `configuration` parameter on each method gives access to the user's
/// chosen intent values (e.g., which category to display).
struct MyAppIntentTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = MyWidgetEntry
    typealias Intent = MyWidgetConfigurationIntent

    func placeholder(in context: Context) -> MyWidgetEntry {
        .placeholder
    }

    func snapshot(for configuration: MyWidgetConfigurationIntent, in context: Context) async -> MyWidgetEntry {
        if context.isPreview {
            return .snapshot
        }
        return await fetchEntry(for: configuration)
    }

    func timeline(for configuration: MyWidgetConfigurationIntent, in context: Context) async -> Timeline<MyWidgetEntry> {
        let entry = await fetchEntry(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // MARK: - Data Fetching

    private func fetchEntry(for configuration: MyWidgetConfigurationIntent) async -> MyWidgetEntry {
        // Use configuration.category (or other intent parameters) to filter data
        let category = configuration.category

        // Fetch data based on the user's configuration choice
        return MyWidgetEntry(
            date: .now,
            title: category.displayName,
            value: "42",
            subtitle: "Updated just now",
            progress: 0.65,
            iconName: category.iconName,
            isPlaceholder: false
        )
    }
}
```

## Widget Views (All Families)

Each widget family gets its own view struct to keep the type checker fast and layouts clean.

```swift
import SwiftUI
import WidgetKit

// MARK: - Entry View Router

/// Routes to the correct view based on the widget family.
struct MyWidgetEntryView: View {
    let entry: MyWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - System Small

/// Compact view for the small home screen widget.
/// Design: Single focused piece of information with an icon.
struct SmallWidgetView: View {
    let entry: MyWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: entry.iconName)
                .font(.title2)
                .foregroundStyle(.blue)

            Spacer()

            Text(entry.value)
                .font(.title.bold())
                .minimumScaleFactor(0.6)

            Text(entry.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - System Medium

/// Horizontal layout for the medium home screen widget.
/// Design: Icon and value on the left, details on the right.
struct MediumWidgetView: View {
    let entry: MyWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: icon and primary value
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: entry.iconName)
                    .font(.title2)
                    .foregroundStyle(.blue)

                Spacer()

                Text(entry.value)
                    .font(.title.bold())

                Text(entry.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Right: additional details
            VStack(alignment: .leading, spacing: 8) {
                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                }

                if let progress = entry.progress {
                    ProgressView(value: progress)
                        .tint(.blue)

                    Text("\(Int(progress * 100))% complete")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - System Large

/// Full-size view for the large home screen widget.
/// Design: Header with value, then a content area with detailed information.
struct LargeWidgetView: View {
    let entry: MyWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: entry.iconName)
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading) {
                    Text(entry.title)
                        .font(.headline)
                    if let subtitle = entry.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(entry.value)
                    .font(.title.bold())
            }

            Divider()

            // Content area
            if let progress = entry.progress {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Progress")
                        .font(.subheadline.weight(.medium))

                    ProgressView(value: progress)
                        .tint(.blue)

                    Text("\(Int(progress * 100))% of daily goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Footer
            HStack {
                Text("Updated \(entry.date, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Accessory Circular (Lock Screen)

/// Circular lock screen widget.
/// Design: Gauge or single icon with a small label.
struct AccessoryCircularView: View {
    let entry: MyWidgetEntry

    var body: some View {
        if let progress = entry.progress {
            Gauge(value: progress) {
                Image(systemName: entry.iconName)
            } currentValueLabel: {
                Text(entry.value)
                    .font(.system(.caption2, design: .rounded).bold())
            }
            .gaugeStyle(.accessoryCircularCapacity)
        } else {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 2) {
                    Image(systemName: entry.iconName)
                        .font(.title3)
                    Text(entry.value)
                        .font(.system(.caption2, design: .rounded).bold())
                }
            }
        }
    }
}

// MARK: - Accessory Rectangular (Lock Screen)

/// Rectangular lock screen widget.
/// Design: Small label with a value, optionally a gauge bar.
struct AccessoryRectangularView: View {
    let entry: MyWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.iconName)
                Text(entry.title)
                    .font(.headline)
                    .lineLimit(1)
            }
            .widgetAccentable()

            Text(entry.value)
                .font(.system(.title3, design: .rounded).bold())

            if let progress = entry.progress {
                ProgressView(value: progress)
            }
        }
    }
}

// MARK: - Accessory Inline (Lock Screen)

/// Inline lock screen widget (single line of text above the clock).
/// Design: Icon and short text, very constrained space.
struct AccessoryInlineView: View {
    let entry: MyWidgetEntry

    var body: some View {
        Label {
            Text("\(entry.title): \(entry.value)")
        } icon: {
            Image(systemName: entry.iconName)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    MyWidget()
} timeline: {
    MyWidgetEntry.snapshot
}

#Preview("Medium", as: .systemMedium) {
    MyWidget()
} timeline: {
    MyWidgetEntry.snapshot
}

#Preview("Large", as: .systemLarge) {
    MyWidget()
} timeline: {
    MyWidgetEntry.snapshot
}

#Preview("Circular", as: .accessoryCircular) {
    MyWidget()
} timeline: {
    MyWidgetEntry.snapshot
}

#Preview("Rectangular", as: .accessoryRectangular) {
    MyWidget()
} timeline: {
    MyWidgetEntry.snapshot
}

#Preview("Inline", as: .accessoryInline) {
    MyWidget()
} timeline: {
    MyWidgetEntry.snapshot
}
```

## Interactive Widget with AppIntent (iOS 17+)

Buttons and toggles that execute actions directly on the widget without opening the app.

### Interactive Button

```swift
import SwiftUI
import AppIntents
import WidgetKit

// MARK: - App Intent for Button Action

/// An intent that performs an action when the user taps a button on the widget.
struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"
    static var description: IntentDescription = "Marks a task as complete or incomplete."

    /// The ID of the task to toggle. Passed from the widget button.
    @Parameter(title: "Task ID")
    var taskID: String

    init() {}

    init(taskID: String) {
        self.taskID = taskID
    }

    func perform() async throws -> some IntentResult {
        // 1. Read current state from shared storage
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.yourapp")
        var completedTasks = sharedDefaults?.stringArray(forKey: "completedTasks") ?? []

        // 2. Toggle the task
        if completedTasks.contains(taskID) {
            completedTasks.removeAll { $0 == taskID }
        } else {
            completedTasks.append(taskID)
        }

        // 3. Write updated state back
        sharedDefaults?.set(completedTasks, forKey: "completedTasks")

        // 4. Reload the widget timeline to reflect the change
        WidgetCenter.shared.reloadTimelines(ofKind: "MyTaskWidget")

        return .result()
    }
}

// MARK: - Interactive Widget View

/// A widget view with tappable buttons that execute App Intents.
struct InteractiveTaskWidgetView: View {
    let entry: TaskWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tasks")
                .font(.headline)

            ForEach(entry.tasks) { task in
                Button(intent: ToggleTaskIntent(taskID: task.id)) {
                    HStack(spacing: 8) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isCompleted ? .green : .secondary)

                        Text(task.title)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}
```

### Interactive Toggle

```swift
import SwiftUI
import AppIntents
import WidgetKit

/// An intent that toggles a boolean setting.
struct ToggleFeatureIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Feature"
    static var description: IntentDescription = "Turns a feature on or off."

    @Parameter(title: "Enabled")
    var isEnabled: Bool

    init() {}

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func perform() async throws -> some IntentResult {
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.yourapp")
        sharedDefaults?.set(isEnabled, forKey: "featureEnabled")

        WidgetCenter.shared.reloadTimelines(ofKind: "MyToggleWidget")

        return .result()
    }
}

/// A widget with a toggle control.
struct ToggleWidgetView: View {
    let entry: ToggleWidgetEntry

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: entry.isEnabled ? "bolt.fill" : "bolt.slash")
                .font(.largeTitle)
                .foregroundStyle(entry.isEnabled ? .yellow : .secondary)

            Toggle(isOn: entry.isEnabled, intent: ToggleFeatureIntent(isEnabled: !entry.isEnabled)) {
                Text(entry.isEnabled ? "Enabled" : "Disabled")
                    .font(.caption)
            }
            .toggleStyle(.switch)
            .tint(.blue)
        }
        .padding()
    }
}
```

## Widget Configuration Intent (iOS 17+)

Allows the user to choose what the widget displays via the long-press edit interface.

```swift
import AppIntents
import Foundation

/// Configuration intent that lets users choose what the widget displays.
///
/// When the user long-presses the widget and taps "Edit Widget", the system
/// presents UI generated from these parameters.
struct MyWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Widget"
    static var description: IntentDescription = "Choose what information the widget shows."

    /// The category to display in the widget.
    @Parameter(title: "Category", default: .general)
    var category: WidgetCategory

    /// Whether to show detailed information.
    @Parameter(title: "Show Details", default: true)
    var showDetails: Bool
}

// MARK: - Category Enum

/// The categories available for widget configuration.
enum WidgetCategory: String, AppEnum {
    case general
    case fitness
    case productivity
    case finance

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Category"
    }

    static var caseDisplayRepresentations: [WidgetCategory: DisplayRepresentation] {
        [
            .general: "General",
            .fitness: DisplayRepresentation(title: "Fitness", image: .init(systemName: "figure.walk")),
            .productivity: DisplayRepresentation(title: "Productivity", image: .init(systemName: "checkmark.circle")),
            .finance: DisplayRepresentation(title: "Finance", image: .init(systemName: "dollarsign.circle"))
        ]
    }

    /// The SF Symbol icon for this category.
    var iconName: String {
        switch self {
        case .general: return "star.fill"
        case .fitness: return "figure.walk"
        case .productivity: return "checkmark.circle.fill"
        case .finance: return "dollarsign.circle.fill"
        }
    }

    /// Display name for UI.
    var displayName: String {
        switch self {
        case .general: return "General"
        case .fitness: return "Fitness"
        case .productivity: return "Productivity"
        case .finance: return "Finance"
        }
    }
}
```

### Dynamic Options (Query-Based)

For configuration parameters that load options dynamically (e.g., from a database):

```swift
import AppIntents
import Foundation

/// A selectable item for widget configuration, loaded from the app's data store.
struct SelectableItem: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Item"
    static var defaultQuery = SelectableItemQuery()

    var id: String
    var name: String
    var iconName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            image: .init(systemName: iconName)
        )
    }
}

/// Query that provides selectable items for the widget configuration UI.
struct SelectableItemQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SelectableItem] {
        // Load items matching the given IDs from your data store
        let allItems = loadItems()
        return allItems.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [SelectableItem] {
        // Return all available items for the picker
        loadItems()
    }

    func defaultResult() async -> SelectableItem? {
        loadItems().first
    }

    private func loadItems() -> [SelectableItem] {
        // Load from App Group shared storage, database, etc.
        let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.yourapp")
        // Decode and return items...
        return [
            SelectableItem(id: "1", name: "Item One", iconName: "1.circle"),
            SelectableItem(id: "2", name: "Item Two", iconName: "2.circle"),
        ]
    }
}
```

## WidgetBundle Registration

Register multiple widgets in a single widget extension.

```swift
import SwiftUI
import WidgetKit

/// The widget bundle that registers all widgets in this extension.
///
/// Only one `@main` entry point is allowed per widget extension.
/// Add all widgets and Live Activities here.
@main
struct MyAppWidgets: WidgetBundle {
    var body: some Widget {
        // Home screen widgets
        MyWidget()
        MySecondWidget()

        // Live Activities (if applicable)
        // MyLiveActivity()
    }
}
```

If the widget extension contains only a single widget, the `@main` attribute can go directly on the `Widget` struct instead of using a `WidgetBundle`:

```swift
@main
struct MyWidget: Widget {
    let kind = "MyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MyTimelineProvider()) { entry in
            MyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("Shows important information.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

## App Group Shared Data Access Pattern

Read and write data shared between the main app and the widget extension using App Groups.

### Writing from the Main App

```swift
import Foundation
import WidgetKit

/// Provides write access to shared data for the widget.
///
/// Use this from the main app to update data that the widget reads.
final class WidgetDataWriter {
    private let suiteName: String
    private let sharedDefaults: UserDefaults?

    init(suiteName: String = "group.com.yourcompany.yourapp") {
        self.suiteName = suiteName
        self.sharedDefaults = UserDefaults(suiteName: suiteName)
    }

    /// Write widget data and trigger a timeline reload.
    /// - Parameters:
    ///   - data: The data to encode and store.
    ///   - key: The UserDefaults key.
    ///   - widgetKind: The widget kind string to reload. Pass nil to reload all.
    func write<T: Encodable>(_ data: T, forKey key: String, widgetKind: String? = nil) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        sharedDefaults?.set(encoded, forKey: key)

        if let widgetKind {
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        } else {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
```

### Reading from the Widget Extension

```swift
import Foundation

/// Provides read access to shared data in the widget extension.
///
/// Use this from the timeline provider to read data written by the main app.
struct WidgetDataReader {
    private let sharedDefaults: UserDefaults?

    init(suiteName: String = "group.com.yourcompany.yourapp") {
        self.sharedDefaults = UserDefaults(suiteName: suiteName)
    }

    /// Read and decode widget data.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - key: The UserDefaults key.
    /// - Returns: The decoded data, or nil if not found or decoding fails.
    func read<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = sharedDefaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
```

### Using Shared File Container

For larger data (images, databases), use the shared container directory:

```swift
import Foundation

/// Access the shared App Group container for file-based data.
struct SharedContainer {
    static let appGroupID = "group.com.yourcompany.yourapp"

    /// The shared container directory URL.
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    /// Write an image to the shared container for the widget to display.
    static func writeImage(_ imageData: Data, named filename: String) {
        guard let containerURL else { return }
        let fileURL = containerURL.appendingPathComponent(filename)
        try? imageData.write(to: fileURL)
    }

    /// Read an image from the shared container.
    static func readImageData(named filename: String) -> Data? {
        guard let containerURL else { return nil }
        let fileURL = containerURL.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }
}
```

## containerBackground Usage (iOS 17+)

All widget views must apply a `containerBackground` so the system can remove or replace the background in StandBy mode, Lock Screen, and other contexts.

```swift
// MARK: - Standard Background

/// Apply to the outermost view in your widget entry view.
MyWidgetEntryView(entry: entry)
    .containerBackground(.fill.tertiary, for: .widget)

// MARK: - Gradient Background

MyWidgetEntryView(entry: entry)
    .containerBackground(for: .widget) {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

// MARK: - Color Background

MyWidgetEntryView(entry: entry)
    .containerBackground(.blue.gradient, for: .widget)

// MARK: - Custom View Background

MyWidgetEntryView(entry: entry)
    .containerBackground(for: .widget) {
        Color.clear // Transparent, system manages background
    }
```

Note: For lock screen accessory widgets, the system ignores `containerBackground` and renders in its own style. You do not need to conditionally apply it.

## Widget URL / Deep Linking

Open the main app to a specific view when the user taps the widget.

```swift
// MARK: - On the Widget View

/// Apply a URL to the entire widget (systemSmall only supports one tap target).
struct SmallWidgetView: View {
    let entry: MyWidgetEntry

    var body: some View {
        VStack {
            Text(entry.title)
            Text(entry.value)
        }
        .widgetURL(URL(string: "myapp://widget/\(entry.itemID)"))
    }
}

/// For medium and large widgets, use Link for multiple tap targets.
struct MediumWidgetView: View {
    let entry: MyWidgetEntry

    var body: some View {
        HStack {
            Link(destination: URL(string: "myapp://item/1")!) {
                Text("Item 1")
            }
            Link(destination: URL(string: "myapp://item/2")!) {
                Text("Item 2")
            }
        }
    }
}

// MARK: - Handling in the Main App

/// In your App struct, handle the widget URL.
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Parse the URL and navigate to the relevant view
                    // e.g., url.pathComponents to extract the item ID
                    handleWidgetURL(url)
                }
        }
    }

    private func handleWidgetURL(_ url: URL) {
        // Route based on URL path
        guard url.scheme == "myapp" else { return }
        // Navigate to the appropriate view
    }
}
```

## Patterns: Good and Bad

### containerBackground

```swift
// ✅ Good: Always provide containerBackground for iOS 17+
MyWidgetEntryView(entry: entry)
    .containerBackground(.fill.tertiary, for: .widget)

// ❌ Bad: No containerBackground -- widget shows default placeholder background
MyWidgetEntryView(entry: entry)
```

### Timeline Entries

```swift
// ✅ Good: Return meaningful placeholder data instantly
func placeholder(in context: Context) -> MyEntry {
    MyEntry(date: .now, title: "Steps", value: "1,234", iconName: "figure.walk", isPlaceholder: true)
}

// ❌ Bad: Fetching data in placeholder (this must return synchronously)
func placeholder(in context: Context) -> MyEntry {
    // WRONG: Cannot do async work here
    let data = fetchDataSynchronously() // Blocks the main thread
    return MyEntry(date: .now, data: data)
}
```

### View Complexity

```swift
// ✅ Good: Separate view struct for each family
struct MyWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: MyEntry

    var body: some View {
        switch family {
        case .systemSmall: SmallView(entry: entry)
        case .systemMedium: MediumView(entry: entry)
        default: SmallView(entry: entry)
        }
    }
}

// ❌ Bad: All families in one massive body with inline conditionals
var body: some View {
    if family == .systemSmall {
        // 50 lines of layout...
    } else if family == .systemMedium {
        // 80 lines of layout...
    } else {
        // 100 lines of layout...
    }
}
```

### Data Access

```swift
// ✅ Good: Use App Groups for shared data
let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.yourapp")
let value = sharedDefaults?.string(forKey: "widgetData")

// ❌ Bad: Use standard UserDefaults (widget cannot access main app's container)
let value = UserDefaults.standard.string(forKey: "widgetData")
```

### Interactive Widgets

```swift
// ✅ Good: Use Button with AppIntent for interactivity (iOS 17+)
Button(intent: ToggleIntent(itemID: item.id)) {
    Label("Complete", systemImage: "checkmark.circle")
}

// ❌ Bad: Try to use onTapGesture (not supported in widgets)
Text("Tap me")
    .onTapGesture { /* This does nothing in a widget */ }
```

### Memory Usage

```swift
// ✅ Good: Load small, optimized thumbnails
if let imageData = SharedContainer.readImageData(named: "widget-thumb-small.jpg") {
    Image(uiImage: UIImage(data: imageData)!)
        .resizable()
}

// ❌ Bad: Load full-resolution images (risks exceeding 40MB limit)
if let imageData = SharedContainer.readImageData(named: "original-photo-12MB.heic") {
    Image(uiImage: UIImage(data: imageData)!)
}
```
