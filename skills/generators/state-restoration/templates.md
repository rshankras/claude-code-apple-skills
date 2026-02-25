# State Restoration Code Templates

Production-ready Swift templates for state restoration infrastructure. All code targets iOS 17+ / macOS 14+ and uses @Observable, Codable, and modern Swift concurrency.

## AppState.swift

```swift
import Foundation

/// Codable model capturing all restorable app state.
///
/// Add fields for each piece of UI state you want to persist
/// across app launches and background termination.
///
/// Usage:
/// ```swift
/// var state = AppState()
/// state.selectedTab = 2
/// state.navigationPathData = try? JSONEncoder().encode(path.codable)
/// ```
struct AppState: Codable, Sendable {
    /// Currently selected tab index or tag.
    var selectedTab: Int = 0

    /// Encoded NavigationPath data for restoration.
    /// Use `NavigationPath.CodableRepresentation` to encode/decode.
    var navigationPathData: Data?

    /// Scroll positions keyed by scroll view identifier.
    /// Maps a scroll view ID string to the ID of the item at the top.
    var scrollPositions: [String: String] = [:]

    /// Form draft values keyed by form ID, then field key.
    /// Cleared when the form is successfully submitted.
    var formDrafts: [String: [String: String]] = [:]

    /// Timestamp of the last successful save.
    /// Used for time-limited restore behavior.
    var lastSavedDate: Date = .distantPast

    /// State schema version for migration support.
    /// Increment when making breaking changes to this struct.
    var stateVersion: Int = 1
}
```

## StateRestorationManager.swift

```swift
import Foundation
import SwiftUI

/// Storage backend for state persistence.
enum StateStorageMethod {
    /// Persist to a JSON file in Application Support.
    case file(directory: URL? = nil)

    /// Persist to UserDefaults with a given suite name.
    case userDefaults(suiteName: String? = nil)
}

/// Controls when saved state is restored.
enum RestoreBehavior {
    /// Always restore saved state on launch.
    case always

    /// Restore only if the state was saved within the given number of minutes.
    case timeLimited(minutes: Int)

    /// Show a prompt asking the user whether to restore.
    case askUser
}

/// Central manager for saving and restoring app state.
///
/// Observes state changes and auto-saves with debouncing.
/// Restores state on initialization based on the configured behavior.
///
/// Usage:
/// ```swift
/// @State private var stateManager = StateRestorationManager()
///
/// ContentView()
///     .environment(stateManager)
/// ```
@Observable
final class StateRestorationManager {
    // MARK: - Public State

    /// The currently selected tab.
    var selectedTab: Int = 0

    /// The navigation path for NavigationStack.
    var navigationPath = NavigationPath()

    /// Whether the user should be prompted to restore (for .askUser behavior).
    var showRestorePrompt = false

    // MARK: - Private

    private var appState = AppState()
    private let storage: StateStorageMethod
    private let restoreBehavior: RestoreBehavior
    private let fileURL: URL
    private var saveTask: Task<Void, Never>?
    private let debounceInterval: Duration

    // MARK: - Init

    init(
        storage: StateStorageMethod = .file(),
        restoreBehavior: RestoreBehavior = .timeLimited(minutes: 30),
        debounceInterval: Duration = .milliseconds(500)
    ) {
        self.storage = storage
        self.restoreBehavior = restoreBehavior
        self.debounceInterval = debounceInterval

        switch storage {
        case .file(let directory):
            let dir = directory ?? FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("StateRestoration", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("appState.json")
        case .userDefaults:
            self.fileURL = URL(fileURLWithPath: "/dev/null") // Not used for UserDefaults
        }

        restoreState()
    }

    // MARK: - Save

    /// Save current state immediately.
    func saveState() {
        appState.selectedTab = selectedTab
        appState.lastSavedDate = Date()

        // Encode navigation path
        if let codable = navigationPath.codable {
            appState.navigationPathData = try? JSONEncoder().encode(codable)
        }

        persistState()
    }

    /// Schedule a debounced save. Call this on every state change.
    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: self?.debounceInterval ?? .milliseconds(500))
            guard !Task.isCancelled else { return }
            self?.saveState()
        }
    }

    /// Save state when the app enters the background.
    ///
    /// Call from `.onChange(of: scenePhase)`:
    /// ```swift
    /// .onChange(of: scenePhase) { _, newPhase in
    ///     if newPhase == .background {
    ///         stateManager.saveOnBackground()
    ///     }
    /// }
    /// ```
    func saveOnBackground() {
        saveTask?.cancel()
        saveState()
    }

    // MARK: - Restore

    /// Restore state from persistent storage.
    func restoreState() {
        guard let loaded = loadState() else { return }

        switch restoreBehavior {
        case .always:
            applyState(loaded)

        case .timeLimited(let minutes):
            let elapsed = Date().timeIntervalSince(loaded.lastSavedDate)
            let limit = TimeInterval(minutes * 60)
            if elapsed <= limit {
                applyState(loaded)
            }

        case .askUser:
            appState = loaded
            showRestorePrompt = true
        }
    }

    /// Apply the pending restored state (called after user confirms in .askUser mode).
    func confirmRestore() {
        applyState(appState)
        showRestorePrompt = false
    }

    /// Discard the pending restored state.
    func declineRestore() {
        appState = AppState()
        showRestorePrompt = false
        clearState()
    }

    // MARK: - Scroll Positions

    /// Save the scroll position for a given scroll view.
    func saveScrollPosition(id scrollViewID: String, topItemID: String) {
        appState.scrollPositions[scrollViewID] = topItemID
        scheduleSave()
    }

    /// Get the saved scroll position for a given scroll view.
    func scrollPosition(for scrollViewID: String) -> String? {
        appState.scrollPositions[scrollViewID]
    }

    // MARK: - Form Drafts

    /// Save a form field value as a draft.
    func saveFormDraft(formID: String, key: String, value: String) {
        if appState.formDrafts[formID] == nil {
            appState.formDrafts[formID] = [:]
        }
        appState.formDrafts[formID]?[key] = value
        scheduleSave()
    }

    /// Get a saved draft value for a form field.
    func formDraftValue(formID: String, key: String) -> String? {
        appState.formDrafts[formID]?[key]
    }

    /// Clear all draft data for a form (call on successful submission).
    func clearFormDraft(formID: String) {
        appState.formDrafts.removeValue(forKey: formID)
        scheduleSave()
    }

    // MARK: - Clear

    /// Clear all saved state.
    func clearState() {
        appState = AppState()
        selectedTab = 0
        navigationPath = NavigationPath()

        switch storage {
        case .file:
            try? FileManager.default.removeItem(at: fileURL)
        case .userDefaults(let suiteName):
            let defaults = suiteName.map { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            defaults?.removeObject(forKey: stateDefaultsKey)
        }
    }

    // MARK: - Private Helpers

    private let stateDefaultsKey = "com.app.stateRestoration.appState"

    private func applyState(_ state: AppState) {
        appState = state
        selectedTab = state.selectedTab

        // Restore navigation path
        if let data = state.navigationPathData,
           let codable = try? JSONDecoder().decode(
               NavigationPath.CodableRepresentation.self,
               from: data
           ) {
            navigationPath = NavigationPath(codable)
        }
    }

    private func persistState() {
        guard let data = try? JSONEncoder().encode(appState) else { return }

        switch storage {
        case .file:
            try? data.write(to: fileURL, options: .atomic)

        case .userDefaults(let suiteName):
            let defaults = suiteName.map { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            defaults?.set(data, forKey: stateDefaultsKey)
        }
    }

    private func loadState() -> AppState? {
        let data: Data?

        switch storage {
        case .file:
            data = try? Data(contentsOf: fileURL)

        case .userDefaults(let suiteName):
            let defaults = suiteName.map { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            data = defaults?.data(forKey: stateDefaultsKey)
        }

        guard let data else { return nil }
        return try? JSONDecoder().decode(AppState.self, from: data)
    }
}

// MARK: - Environment Integration

private struct StateRestorationManagerKey: EnvironmentKey {
    static let defaultValue: StateRestorationManager? = nil
}

extension EnvironmentValues {
    var stateRestorationManager: StateRestorationManager? {
        get { self[StateRestorationManagerKey.self] }
        set { self[StateRestorationManagerKey.self] = newValue }
    }
}
```

## NavigationStateModifier.swift

```swift
import SwiftUI

/// ViewModifier that persists and restores NavigationStack path.
///
/// Wraps a NavigationStack and automatically saves the path
/// whenever it changes. Restores on appear.
///
/// Usage:
/// ```swift
/// NavigationStack(path: $stateManager.navigationPath) {
///     RootView()
///         .navigationDestination(for: Route.self) { route in
///             RouteView(route: route)
///         }
/// }
/// .modifier(NavigationStateModifier(stateManager: stateManager))
/// ```
///
/// **Important:** All route types in the NavigationPath must conform
/// to both `Codable` and `Hashable`. If any type changes between
/// app versions, decoding fails and the path resets to empty.
struct NavigationStateModifier: ViewModifier {
    let stateManager: StateRestorationManager

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onChange(of: stateManager.navigationPath) {
                stateManager.scheduleSave()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    stateManager.saveOnBackground()
                }
            }
    }
}

extension View {
    /// Attach navigation state persistence to a NavigationStack.
    func persistNavigationState(using stateManager: StateRestorationManager) -> some View {
        modifier(NavigationStateModifier(stateManager: stateManager))
    }
}
```

## ScrollRestorationModifier.swift

```swift
import SwiftUI

/// ViewModifier that saves and restores scroll position by item ID.
///
/// Uses @SceneStorage for lightweight per-scene persistence and
/// ScrollViewReader to programmatically scroll on restore.
///
/// Usage:
/// ```swift
/// ScrollView {
///     LazyVStack {
///         ForEach(items) { item in
///             ItemRow(item: item)
///         }
///     }
/// }
/// .modifier(ScrollRestorationModifier(scrollViewID: "item-list"))
/// ```
///
/// For this modifier to work, each item in the scroll view must have
/// an `.id()` that matches the string stored in scroll state.
struct ScrollRestorationModifier: ViewModifier {
    /// Unique identifier for this scroll view (used as the storage key).
    let scrollViewID: String

    @SceneStorage private var savedScrollPosition: String?
    @State private var hasRestored = false

    init(scrollViewID: String) {
        self.scrollViewID = scrollViewID
        _savedScrollPosition = SceneStorage(wrappedValue: nil, "scroll_\(scrollViewID)")
    }

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .onAppear {
                    guard !hasRestored, let savedID = savedScrollPosition else { return }
                    hasRestored = true
                    // Slight delay to let the ScrollView populate
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.none) {
                            proxy.scrollTo(savedID, anchor: .top)
                        }
                    }
                }
        }
    }

    /// Call this to update the saved scroll position when visible items change.
    ///
    /// Typically called from a GeometryReader or onAppear of list items:
    /// ```swift
    /// .onAppear { scrollModifier.updatePosition(topItemID: item.id.uuidString) }
    /// ```
    func updatePosition(topItemID: String) {
        savedScrollPosition = topItemID
    }
}

/// Convenience: scroll position tracker for items in a LazyVStack.
///
/// Attach to each item row to track which item is at the top.
///
/// Usage:
/// ```swift
/// LazyVStack {
///     ForEach(items) { item in
///         ItemRow(item: item)
///             .modifier(ScrollPositionTracker(
///                 itemID: item.id.uuidString,
///                 scrollViewID: "item-list",
///                 stateManager: stateManager
///             ))
///     }
/// }
/// ```
struct ScrollPositionTracker: ViewModifier {
    let itemID: String
    let scrollViewID: String
    let stateManager: StateRestorationManager

    func body(content: Content) -> some View {
        content
            .onAppear {
                stateManager.saveScrollPosition(id: scrollViewID, topItemID: itemID)
            }
    }
}

extension View {
    /// Track this item's visibility for scroll position restoration.
    func trackScrollPosition(
        itemID: String,
        scrollViewID: String,
        stateManager: StateRestorationManager
    ) -> some View {
        modifier(ScrollPositionTracker(
            itemID: itemID,
            scrollViewID: scrollViewID,
            stateManager: stateManager
        ))
    }
}
```

## TabRestorationModifier.swift

```swift
import SwiftUI

/// ViewModifier that persists the selected tab to @AppStorage.
///
/// Automatically saves the tab selection whenever it changes
/// and restores it on app launch.
///
/// Usage:
/// ```swift
/// TabView(selection: $stateManager.selectedTab) {
///     HomeView().tag(0)
///     SearchView().tag(1)
///     ProfileView().tag(2)
/// }
/// .modifier(TabRestorationModifier(stateManager: stateManager))
/// ```
///
/// For String-based tab tags, use `TabRestorationStringModifier` instead.
struct TabRestorationModifier: ViewModifier {
    let stateManager: StateRestorationManager

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onChange(of: stateManager.selectedTab) {
                stateManager.scheduleSave()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    stateManager.saveOnBackground()
                }
            }
    }
}

/// Standalone tab persistence using @AppStorage (no StateRestorationManager needed).
///
/// Use this for simple cases where you only need tab persistence.
///
/// Usage:
/// ```swift
/// struct ContentView: View {
///     @AppStorage("selectedTab") private var selectedTab = 0
///
///     var body: some View {
///         TabView(selection: $selectedTab) {
///             HomeView().tag(0)
///             SearchView().tag(1)
///             ProfileView().tag(2)
///         }
///     }
/// }
/// ```
///
/// For String tags:
/// ```swift
/// @AppStorage("selectedTab") private var selectedTab = "home"
///
/// TabView(selection: $selectedTab) {
///     HomeView().tag("home")
///     SearchView().tag("search")
///     ProfileView().tag("profile")
/// }
/// ```

extension View {
    /// Attach tab selection persistence.
    func persistTabSelection(using stateManager: StateRestorationManager) -> some View {
        modifier(TabRestorationModifier(stateManager: stateManager))
    }
}
```

## FormDraftManager.swift

```swift
import Foundation

/// Auto-saves form field values as the user types, with debounced persistence.
///
/// Clears draft data when the form is successfully submitted.
/// Each form is identified by a unique `formID`.
///
/// Usage:
/// ```swift
/// struct ComposeView: View {
///     @State private var draftManager = FormDraftManager(formID: "compose")
///     @State private var title = ""
///     @State private var bodyText = ""
///
///     var body: some View {
///         Form {
///             TextField("Title", text: $title)
///             TextEditor(text: $bodyText)
///             Button("Submit") { submit() }
///         }
///         .onAppear {
///             title = draftManager.value(for: "title") ?? ""
///             bodyText = draftManager.value(for: "body") ?? ""
///         }
///         .onChange(of: title) { draftManager.save(key: "title", value: title) }
///         .onChange(of: bodyText) { draftManager.save(key: "body", value: bodyText) }
///     }
///
///     private func submit() {
///         // ... submit form ...
///         draftManager.clearDraft()
///     }
/// }
/// ```
@Observable
final class FormDraftManager {
    /// Unique identifier for the form.
    let formID: String

    // MARK: - Private

    private var drafts: [String: String] = [:]
    private let storage: StateStorageMethod
    private let fileURL: URL
    private var saveTask: Task<Void, Never>?
    private let debounceInterval: Duration
    private let defaultsKey: String

    // MARK: - Init

    init(
        formID: String,
        storage: StateStorageMethod = .file(),
        debounceInterval: Duration = .seconds(1)
    ) {
        self.formID = formID
        self.storage = storage
        self.debounceInterval = debounceInterval
        self.defaultsKey = "com.app.formDraft.\(formID)"

        switch storage {
        case .file(let directory):
            let dir = directory ?? FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("FormDrafts", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("\(formID).json")
        case .userDefaults:
            self.fileURL = URL(fileURLWithPath: "/dev/null")
        }

        loadDrafts()
    }

    // MARK: - Public API

    /// Save a field value. Debounced — won't write to disk on every keystroke.
    func save(key: String, value: String) {
        drafts[key] = value
        scheduleSave()
    }

    /// Get the saved draft value for a field.
    func value(for key: String) -> String? {
        drafts[key]
    }

    /// Restore saved draft values into bindings.
    ///
    /// Usage:
    /// ```swift
    /// .onAppear {
    ///     title = draftManager.value(for: "title") ?? ""
    ///     body = draftManager.value(for: "body") ?? ""
    /// }
    /// ```
    func allDraftValues() -> [String: String] {
        drafts
    }

    /// Check if there is a saved draft for this form.
    var hasDraft: Bool {
        !drafts.isEmpty
    }

    /// Clear all draft data for this form.
    ///
    /// Call this after the form is successfully submitted.
    func clearDraft() {
        saveTask?.cancel()
        drafts.removeAll()

        switch storage {
        case .file:
            try? FileManager.default.removeItem(at: fileURL)
        case .userDefaults(let suiteName):
            let defaults = suiteName.map { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            defaults?.removeObject(forKey: defaultsKey)
        }
    }

    // MARK: - Private

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: self?.debounceInterval ?? .seconds(1))
            guard !Task.isCancelled else { return }
            self?.persistDrafts()
        }
    }

    private func persistDrafts() {
        guard let data = try? JSONEncoder().encode(drafts) else { return }

        switch storage {
        case .file:
            try? data.write(to: fileURL, options: .atomic)
        case .userDefaults(let suiteName):
            let defaults = suiteName.map { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            defaults?.set(data, forKey: defaultsKey)
        }
    }

    private func loadDrafts() {
        let data: Data?

        switch storage {
        case .file:
            data = try? Data(contentsOf: fileURL)
        case .userDefaults(let suiteName):
            let defaults = suiteName.map { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            data = defaults?.data(forKey: defaultsKey)
        }

        guard let data else { return }
        drafts = (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }
}
```
