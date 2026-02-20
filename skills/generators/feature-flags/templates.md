# Feature Flag Code Templates

Production-ready Swift templates for feature flag infrastructure. All code targets iOS 17+ / macOS 14+ and uses `@Observable`, modern Swift concurrency, and protocol-based architecture.

## FeatureFlag.swift

The flag enum defines every feature flag in the app with typed default values.

```swift
import Foundation

/// Defines all feature flags available in the app.
///
/// Each case represents a single feature flag with a remote key and a local default value.
/// Add new flags here and provide defaults so the app functions correctly without a network connection.
enum FeatureFlag: String, CaseIterable, Sendable {
    case newOnboarding = "new_onboarding"
    case darkModeV2 = "dark_mode_v2"
    case premiumPaywall = "premium_paywall"
    case experimentalUI = "experimental_ui"

    // MARK: - Default Values

    /// The default boolean value used when no remote or override value is available.
    var defaultValue: Bool {
        switch self {
        case .newOnboarding: return false
        case .darkModeV2: return true
        case .premiumPaywall: return false
        case .experimentalUI: return false
        }
    }

    /// The default string value, if applicable. Returns nil for flags that are boolean-only.
    var defaultStringValue: String? {
        switch self {
        default: return nil
        }
    }

    /// The default integer value, if applicable. Returns nil for flags that are boolean-only.
    var defaultIntValue: Int? {
        switch self {
        default: return nil
        }
    }

    // MARK: - Display

    /// A human-readable label for display in debug menus.
    var displayName: String {
        switch self {
        case .newOnboarding: return "New Onboarding"
        case .darkModeV2: return "Dark Mode V2"
        case .premiumPaywall: return "Premium Paywall"
        case .experimentalUI: return "Experimental UI"
        }
    }

    /// A description for the debug menu explaining what the flag controls.
    var flagDescription: String {
        switch self {
        case .newOnboarding: return "Enables the redesigned onboarding flow"
        case .darkModeV2: return "Enables the updated dark mode color palette"
        case .premiumPaywall: return "Shows the premium paywall before gated features"
        case .experimentalUI: return "Enables experimental UI components"
        }
    }
}
```

## FeatureFlagService.swift

The protocol that all providers conform to. This enables swapping providers for testing, previews, or different environments.

```swift
import Foundation

/// Protocol defining the interface for feature flag providers.
///
/// Conform to this protocol to create new flag sources (local, remote, composite, mock).
/// All methods are synchronous reads; async `refresh()` is the only network operation.
protocol FeatureFlagService: Sendable {

    /// Returns whether the given flag is enabled.
    /// - Parameter flag: The feature flag to check.
    /// - Returns: `true` if the flag is enabled, `false` otherwise.
    func isEnabled(_ flag: FeatureFlag) -> Bool

    /// Returns the boolean value for a flag, or its default if not set.
    /// - Parameter flag: The feature flag to query.
    /// - Returns: The boolean value.
    func boolValue(_ flag: FeatureFlag) -> Bool

    /// Returns the string value for a flag, if one exists.
    /// - Parameter flag: The feature flag to query.
    /// - Returns: The string value, or nil if not set.
    func stringValue(_ flag: FeatureFlag) -> String?

    /// Returns the integer value for a flag, if one exists.
    /// - Parameter flag: The feature flag to query.
    /// - Returns: The integer value, or nil if not set.
    func intValue(_ flag: FeatureFlag) -> Int?

    /// Returns a decoded JSON value for a flag, if one exists.
    /// - Parameter flag: The feature flag to query.
    /// - Returns: The decoded value, or nil if not set or decoding fails.
    func jsonValue<T: Decodable>(_ flag: FeatureFlag) -> T?

    /// Refreshes flag values from the source (e.g., network fetch).
    /// For local-only providers, this is a no-op.
    func refresh() async throws
}

// MARK: - Default Implementations

extension FeatureFlagService {

    func boolValue(_ flag: FeatureFlag) -> Bool {
        isEnabled(flag)
    }

    func stringValue(_ flag: FeatureFlag) -> String? {
        flag.defaultStringValue
    }

    func intValue(_ flag: FeatureFlag) -> Int? {
        flag.defaultIntValue
    }

    func jsonValue<T: Decodable>(_ flag: FeatureFlag) -> T? {
        nil
    }

    func refresh() async throws {
        // No-op by default for local-only providers.
    }
}
```

## LocalFeatureFlagProvider.swift

A provider backed by `UserDefaults` with compile-time defaults. In DEBUG builds, flags can be overridden via the debug menu.

```swift
import Foundation

/// A feature flag provider that uses local defaults and UserDefaults overrides.
///
/// In DEBUG builds, the debug menu writes overrides to UserDefaults with the `ff_` prefix.
/// In RELEASE builds, only the compile-time defaults from `FeatureFlag.defaultValue` are used.
final class LocalFeatureFlagProvider: FeatureFlagService, @unchecked Sendable {

    // MARK: - Properties

    private let defaults: UserDefaults
    private let keyPrefix = "ff_"

    // MARK: - Initialization

    /// Creates a local provider backed by the given UserDefaults suite.
    /// - Parameter defaults: The UserDefaults instance to use. Defaults to `.standard`.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - FeatureFlagService

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        #if DEBUG
        // Check for a debug override first.
        let key = keyPrefix + flag.rawValue
        if defaults.object(forKey: key) != nil {
            return defaults.bool(forKey: key)
        }
        #endif
        return flag.defaultValue
    }

    func boolValue(_ flag: FeatureFlag) -> Bool {
        isEnabled(flag)
    }

    func stringValue(_ flag: FeatureFlag) -> String? {
        #if DEBUG
        let key = keyPrefix + flag.rawValue + "_string"
        if let override = defaults.string(forKey: key) {
            return override
        }
        #endif
        return flag.defaultStringValue
    }

    func intValue(_ flag: FeatureFlag) -> Int? {
        #if DEBUG
        let key = keyPrefix + flag.rawValue + "_int"
        if defaults.object(forKey: key) != nil {
            return defaults.integer(forKey: key)
        }
        #endif
        return flag.defaultIntValue
    }

    func jsonValue<T: Decodable>(_ flag: FeatureFlag) -> T? {
        #if DEBUG
        let key = keyPrefix + flag.rawValue + "_json"
        if let data = defaults.data(forKey: key) {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        #endif
        return nil
    }

    // MARK: - Debug Override Management

    #if DEBUG
    /// Sets a boolean override for a flag. Used by the debug menu.
    func setOverride(_ flag: FeatureFlag, enabled: Bool) {
        defaults.set(enabled, forKey: keyPrefix + flag.rawValue)
    }

    /// Removes the override for a flag, reverting to the compile-time default.
    func removeOverride(_ flag: FeatureFlag) {
        defaults.removeObject(forKey: keyPrefix + flag.rawValue)
        defaults.removeObject(forKey: keyPrefix + flag.rawValue + "_string")
        defaults.removeObject(forKey: keyPrefix + flag.rawValue + "_int")
        defaults.removeObject(forKey: keyPrefix + flag.rawValue + "_json")
    }

    /// Removes all flag overrides.
    func removeAllOverrides() {
        for flag in FeatureFlag.allCases {
            removeOverride(flag)
        }
    }

    /// Returns whether a debug override exists for the given flag.
    func hasOverride(_ flag: FeatureFlag) -> Bool {
        defaults.object(forKey: keyPrefix + flag.rawValue) != nil
    }
    #endif
}
```

## RemoteFeatureFlagProvider.swift

A provider that fetches flag values from a JSON endpoint with disk caching.

```swift
import Foundation
import os.log

/// A feature flag provider that fetches flag values from a remote JSON endpoint.
///
/// The expected JSON format:
/// ```json
/// {
///   "new_onboarding": true,
///   "dark_mode_v2": false,
///   "welcome_message": "Hello!",
///   "max_retries": 5,
///   "paywall_config": { "title": "Go Premium", "trialDays": 7 }
/// }
/// ```
///
/// Values are cached to disk so the app has recent values available on cold launch
/// before the first network fetch completes.
final class RemoteFeatureFlagProvider: FeatureFlagService, @unchecked Sendable {

    // MARK: - Properties

    private let endpoint: URL
    private let urlSession: URLSession
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "FeatureFlags")
    private let cacheURL: URL
    private let cacheDuration: TimeInterval

    /// Lock-protected storage for the fetched flag values.
    private let lock = NSLock()
    private var flags: [String: Any] = [:]

    // MARK: - Initialization

    /// Creates a remote provider.
    /// - Parameters:
    ///   - endpoint: The URL of the JSON endpoint returning flag values.
    ///   - urlSession: The URLSession to use for fetching. Defaults to `.shared`.
    ///   - cacheDuration: How long cached values are considered fresh, in seconds. Defaults to 300 (5 minutes).
    init(
        endpoint: URL,
        urlSession: URLSession = .shared,
        cacheDuration: TimeInterval = 300
    ) {
        self.endpoint = endpoint
        self.urlSession = urlSession
        self.cacheDuration = cacheDuration

        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheURL = cacheDir.appendingPathComponent("feature_flags_cache.json")

        // Load cached values on init so flags are available before first refresh.
        loadCache()
    }

    // MARK: - FeatureFlagService

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return (flags[flag.rawValue] as? Bool) ?? flag.defaultValue
    }

    func boolValue(_ flag: FeatureFlag) -> Bool {
        isEnabled(flag)
    }

    func stringValue(_ flag: FeatureFlag) -> String? {
        lock.lock()
        defer { lock.unlock() }

        if let value = flags[flag.rawValue] as? String {
            return value
        }
        // Check for a suffixed key (e.g., "flag_name_string").
        if let value = flags[flag.rawValue + "_string"] as? String {
            return value
        }
        return flag.defaultStringValue
    }

    func intValue(_ flag: FeatureFlag) -> Int? {
        lock.lock()
        defer { lock.unlock() }

        if let value = flags[flag.rawValue] as? Int {
            return value
        }
        if let value = flags[flag.rawValue + "_int"] as? Int {
            return value
        }
        return flag.defaultIntValue
    }

    func jsonValue<T: Decodable>(_ flag: FeatureFlag) -> T? {
        lock.lock()
        let rawValue = flags[flag.rawValue]
        lock.unlock()

        guard let rawValue else { return nil }

        // If the value is already a dictionary or array, re-serialize and decode.
        guard JSONSerialization.isValidJSONObject(rawValue) else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: rawValue) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func refresh() async throws {
        let (data, response) = try await urlSession.data(from: endpoint)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            logger.error("Feature flag fetch failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw FeatureFlagError.fetchFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Feature flag response is not a valid JSON object.")
            throw FeatureFlagError.invalidResponse
        }

        lock.lock()
        flags = json
        lock.unlock()

        // Persist to disk cache.
        saveCache(data: data)

        logger.info("Feature flags refreshed: \(json.count) flags loaded.")
    }

    // MARK: - Disk Cache

    private func loadCache() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return }

        // Check cache freshness.
        if let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
           let modDate = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modDate) > cacheDuration {
            // Cache is stale but still usable as fallback. Load it anyway.
            logger.info("Feature flag cache is stale but loading as fallback.")
        }

        guard let data = try? Data(contentsOf: cacheURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        lock.lock()
        flags = json
        lock.unlock()

        logger.info("Feature flags loaded from cache: \(json.count) flags.")
    }

    private func saveCache(data: Data) {
        do {
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            logger.warning("Failed to save feature flag cache: \(error.localizedDescription)")
        }
    }
}

// MARK: - Errors

/// Errors that can occur during feature flag operations.
enum FeatureFlagError: LocalizedError {
    case fetchFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch feature flags from the remote endpoint."
        case .invalidResponse:
            return "The feature flag response was not a valid JSON object."
        }
    }
}
```

## CompositeFeatureFlagProvider.swift

Combines a local provider (for defaults and debug overrides) with a remote provider (for server-driven values). Remote values take precedence when available.

```swift
import Foundation

/// A composite provider that layers remote values on top of local defaults.
///
/// Resolution order:
/// 1. DEBUG override (if set via debug menu, handled inside LocalFeatureFlagProvider)
/// 2. Remote value (if fetched successfully)
/// 3. Local default (compile-time fallback)
///
/// This ensures the app always has a working value, even without network access.
final class CompositeFeatureFlagProvider: FeatureFlagService, @unchecked Sendable {

    // MARK: - Properties

    private let local: LocalFeatureFlagProvider
    private let remote: RemoteFeatureFlagProvider

    // MARK: - Initialization

    /// Creates a composite provider.
    /// - Parameters:
    ///   - local: The local provider for defaults and debug overrides.
    ///   - remote: The remote provider for server-driven values.
    init(local: LocalFeatureFlagProvider, remote: RemoteFeatureFlagProvider) {
        self.local = local
        self.remote = remote
    }

    // MARK: - FeatureFlagService

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        #if DEBUG
        // Debug overrides always win.
        if local.hasOverride(flag) {
            return local.isEnabled(flag)
        }
        #endif

        // Remote value takes precedence over local default.
        // The remote provider falls back to flag.defaultValue internally
        // if no remote value exists, which matches the local default.
        return remote.isEnabled(flag)
    }

    func boolValue(_ flag: FeatureFlag) -> Bool {
        isEnabled(flag)
    }

    func stringValue(_ flag: FeatureFlag) -> String? {
        #if DEBUG
        if local.hasOverride(flag), let value = local.stringValue(flag) {
            return value
        }
        #endif
        return remote.stringValue(flag) ?? local.stringValue(flag)
    }

    func intValue(_ flag: FeatureFlag) -> Int? {
        #if DEBUG
        if local.hasOverride(flag), let value = local.intValue(flag) {
            return value
        }
        #endif
        return remote.intValue(flag) ?? local.intValue(flag)
    }

    func jsonValue<T: Decodable>(_ flag: FeatureFlag) -> T? {
        #if DEBUG
        if local.hasOverride(flag) {
            if let value: T = local.jsonValue(flag) {
                return value
            }
        }
        #endif
        return remote.jsonValue(flag) ?? local.jsonValue(flag)
    }

    func refresh() async throws {
        try await remote.refresh()
    }
}
```

## FeatureFlagManager.swift

The `@Observable` manager that SwiftUI views interact with. It wraps a provider and exposes flag state reactively.

```swift
import Foundation
import os.log

/// The main entry point for feature flag access in the app.
///
/// This class is `@Observable` so SwiftUI views automatically re-render when
/// flag values change (e.g., after a remote refresh or debug override).
///
/// Usage:
/// ```swift
/// @Environment(FeatureFlagManager.self) private var flags
///
/// if flags.isEnabled(.newOnboarding) {
///     NewOnboardingView()
/// }
/// ```
@MainActor
@Observable
final class FeatureFlagManager {

    // MARK: - Properties

    private let provider: any FeatureFlagService
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "FeatureFlagManager")

    /// Incremented after each refresh to trigger SwiftUI observation updates.
    private(set) var refreshCount: Int = 0

    /// The timestamp of the last successful refresh.
    private(set) var lastRefreshDate: Date?

    /// Whether a refresh is currently in progress.
    private(set) var isRefreshing: Bool = false

    // MARK: - Initialization

    /// Creates a feature flag manager with the given provider.
    /// - Parameter provider: The underlying flag provider (local, remote, or composite).
    init(provider: any FeatureFlagService) {
        self.provider = provider
    }

    // MARK: - Flag Access

    /// Returns whether the given flag is enabled.
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        // Access refreshCount to establish an observation dependency,
        // ensuring views re-evaluate after refresh.
        _ = refreshCount
        return provider.isEnabled(flag)
    }

    /// Returns the boolean value for a flag.
    func boolValue(_ flag: FeatureFlag) -> Bool {
        _ = refreshCount
        return provider.boolValue(flag)
    }

    /// Returns the string value for a flag, if one exists.
    func stringValue(_ flag: FeatureFlag) -> String? {
        _ = refreshCount
        return provider.stringValue(flag)
    }

    /// Returns the integer value for a flag, if one exists.
    func intValue(_ flag: FeatureFlag) -> Int? {
        _ = refreshCount
        return provider.intValue(flag)
    }

    /// Returns a decoded JSON value for a flag, if one exists.
    func jsonValue<T: Decodable>(_ flag: FeatureFlag) -> T? {
        _ = refreshCount
        return provider.jsonValue(flag)
    }

    // MARK: - Refresh

    /// Refreshes flag values from the remote source.
    ///
    /// After a successful refresh, all observing SwiftUI views will re-evaluate.
    func refresh() async throws {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await provider.refresh()
            refreshCount += 1
            lastRefreshDate = Date()
            logger.info("Feature flags refreshed successfully.")
        } catch {
            logger.error("Feature flag refresh failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Debug Access

    #if DEBUG
    /// Provides access to the underlying provider for the debug menu.
    /// Returns the local provider if available (directly or inside a composite).
    var debugLocalProvider: LocalFeatureFlagProvider? {
        if let local = provider as? LocalFeatureFlagProvider {
            return local
        }
        if let composite = provider as? CompositeFeatureFlagProvider {
            // Access the local provider via a mirror since it is private.
            let mirror = Mirror(reflecting: composite)
            return mirror.children.first(where: { $0.label == "local" })?.value as? LocalFeatureFlagProvider
        }
        return nil
    }

    /// Forces a re-evaluation of all observing views.
    /// Called by the debug menu after toggling an override.
    func notifyFlagChanged() {
        refreshCount += 1
    }
    #endif
}
```

## FeatureFlagEnvironmentKey.swift

SwiftUI Environment integration so views can access the flag manager via `@Environment`.

```swift
import SwiftUI

// MARK: - Environment Access

/// Provides the FeatureFlagManager through SwiftUI's environment system.
///
/// Injection (at the app root):
/// ```swift
/// ContentView()
///     .environment(featureFlagManager)
/// ```
///
/// Usage (in any descendant view):
/// ```swift
/// @Environment(FeatureFlagManager.self) private var flags
///
/// if flags.isEnabled(.newOnboarding) { ... }
/// ```
///
/// Because `FeatureFlagManager` is `@Observable`, SwiftUI automatically
/// discovers it from the environment when using `@Environment(FeatureFlagManager.self)`.
/// No custom `EnvironmentKey` is needed with the iOS 17+ observation system.
///
/// For convenience, a `View` extension is provided below.

extension View {

    /// Injects the feature flag manager into the environment.
    ///
    /// Equivalent to `.environment(manager)` but provides a discoverable API.
    func featureFlags(_ manager: FeatureFlagManager) -> some View {
        self.environment(manager)
    }
}

// MARK: - Preview Support

/// A convenience initializer for SwiftUI previews that creates a manager with local defaults.
extension FeatureFlagManager {

    /// Creates a manager backed by a local-only provider for use in previews.
    @MainActor
    static var preview: FeatureFlagManager {
        FeatureFlagManager(provider: LocalFeatureFlagProvider())
    }
}
```

## FeatureFlagDebugView.swift

A debug-only view that lists all flags with toggles for overriding values at runtime.

```swift
#if DEBUG
import SwiftUI

/// A debug menu for viewing and overriding feature flag values at runtime.
///
/// This view is only available in DEBUG builds. It allows developers and QA
/// to toggle flags without recompiling or changing the server configuration.
///
/// Usage:
/// ```swift
/// #if DEBUG
/// NavigationLink("Feature Flags") {
///     FeatureFlagDebugView()
/// }
/// #endif
/// ```
struct FeatureFlagDebugView: View {

    @Environment(FeatureFlagManager.self) private var manager

    var body: some View {
        List {
            headerSection
            flagsSection
            actionsSection
        }
        .navigationTitle("Feature Flags")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            if let lastRefresh = manager.lastRefreshDate {
                LabeledContent("Last Refresh") {
                    Text(lastRefresh, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }

            if manager.isRefreshing {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Refreshing...")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Status")
        }
    }

    private var flagsSection: some View {
        Section {
            ForEach(FeatureFlag.allCases, id: \.self) { flag in
                FlagRow(flag: flag, manager: manager)
            }
        } header: {
            Text("Flags")
        } footer: {
            Text("Overrides are stored in UserDefaults and persist across launches. They only apply in DEBUG builds.")
        }
    }

    private var actionsSection: some View {
        Section {
            Button("Refresh Remote Flags") {
                Task {
                    try? await manager.refresh()
                }
            }

            Button("Reset All Overrides", role: .destructive) {
                manager.debugLocalProvider?.removeAllOverrides()
                manager.notifyFlagChanged()
            }
        } header: {
            Text("Actions")
        }
    }
}

// MARK: - Flag Row

/// A single row in the debug flag list showing the flag name, description, and a toggle.
private struct FlagRow: View {

    let flag: FeatureFlag
    let manager: FeatureFlagManager

    var body: some View {
        let localProvider = manager.debugLocalProvider
        let hasOverride = localProvider?.hasOverride(flag) ?? false
        let currentValue = manager.isEnabled(flag)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle(flag.displayName, isOn: Binding(
                    get: { currentValue },
                    set: { newValue in
                        localProvider?.setOverride(flag, enabled: newValue)
                        manager.notifyFlagChanged()
                    }
                ))
                .font(.body.weight(hasOverride ? .semibold : .regular))
            }

            Text(flag.flagDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("Key: \(flag.rawValue)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if hasOverride {
                    Text("OVERRIDDEN")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                }

                Text("Default: \(flag.defaultValue ? "ON" : "OFF")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing) {
            if hasOverride {
                Button("Reset") {
                    localProvider?.removeOverride(flag)
                    manager.notifyFlagChanged()
                }
                .tint(.blue)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FeatureFlagDebugView()
            .environment(FeatureFlagManager.preview)
    }
}
#endif
```

## Patterns: Good and Bad

### Flag Definitions

```swift
// ✅ Good: Descriptive names with clear defaults
enum FeatureFlag: String, CaseIterable, Sendable {
    case newCheckoutFlow = "new_checkout_flow"
    case premiumTrial = "premium_trial"

    var defaultValue: Bool {
        switch self {
        case .newCheckoutFlow: return false  // Off until rollout
        case .premiumTrial: return true       // On by default
        }
    }
}

// ❌ Bad: Vague names, no structure
let flag1 = UserDefaults.standard.bool(forKey: "flag1")
let enableThing = true
```

### Checking Flags

```swift
// ✅ Good: Check via the manager (reactive, testable)
@Environment(FeatureFlagManager.self) private var flags

if flags.isEnabled(.newOnboarding) {
    NewOnboardingView()
}

// ❌ Bad: Read UserDefaults directly (not reactive, not testable)
if UserDefaults.standard.bool(forKey: "new_onboarding") {
    NewOnboardingView()
}
```

### Provider Architecture

```swift
// ✅ Good: Protocol-based, swappable providers
let provider = CompositeFeatureFlagProvider(
    local: LocalFeatureFlagProvider(),
    remote: RemoteFeatureFlagProvider(endpoint: flagsURL)
)
let manager = FeatureFlagManager(provider: provider)

// ❌ Bad: Hardcoded single implementation with no abstraction
class FeatureFlags {
    static let shared = FeatureFlags()
    func isEnabled(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
```

### Refresh Strategy

```swift
// ✅ Good: Refresh on launch, handle errors gracefully
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Task {
        do {
            try await featureFlagManager.refresh()
        } catch {
            // Local defaults are already available; log and continue.
            logger.warning("Flag refresh failed: \(error.localizedDescription)")
        }
    }
    return true
}

// ❌ Bad: Block app launch on network call
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let semaphore = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: flagsURL) { data, _, _ in
        // Parse flags...
        semaphore.signal()
    }.resume()
    semaphore.wait()  // Blocks main thread!
    return true
}
```

### Flag Cleanup

```swift
// ✅ Good: Remove flag after full rollout
// 1. Delete the enum case
// 2. Remove all conditional branches
// 3. Delete remote configuration
// 4. Remove debug overrides from UserDefaults

// ❌ Bad: Leave stale flags indefinitely
enum FeatureFlag: String, CaseIterable {
    case migrationV1 = "migration_v1"       // Rolled out 6 months ago
    case onboardingV2 = "onboarding_v2"     // Rolled out 1 year ago
    case betaFeature2023 = "beta_2023"      // What does this even do?
}
```

### Thread Safety

```swift
// ✅ Good: @MainActor manager, Sendable providers, NSLock for mutable state
@MainActor
@Observable
final class FeatureFlagManager {
    private let provider: any FeatureFlagService  // Sendable
}

// ❌ Bad: Unprotected mutable state accessed from multiple threads
class FeatureFlagService {
    var flags: [String: Any] = [:]  // Data race!

    func refresh() {
        DispatchQueue.global().async {
            self.flags = self.fetchFlags()  // Written on background thread
        }
    }

    func isEnabled(_ key: String) -> Bool {
        flags[key] as? Bool ?? false  // Read on main thread
    }
}
```
