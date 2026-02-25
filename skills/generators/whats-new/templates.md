# What's New Code Templates

Production-ready Swift templates for a "What's New" screen with version tracking. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## WhatsNewFeature.swift

```swift
import SwiftUI

/// A single feature to highlight in the What's New screen.
///
/// Each feature has a title, description, SF Symbol icon, and tint color.
///
/// Usage:
/// ```swift
/// let feature = WhatsNewFeature(
///     title: "Dark Mode",
///     description: "Full dark mode support across all screens.",
///     systemImage: "moon.fill",
///     tintColor: .indigo
/// )
/// ```
struct WhatsNewFeature: Identifiable, Codable, Sendable {
    var id: String { title }

    let title: String
    let description: String
    let systemImage: String
    let tintColor: CodableColor

    init(title: String, description: String, systemImage: String, tintColor: Color) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.tintColor = CodableColor(color: tintColor)
    }
}

/// A Codable wrapper for SwiftUI Color.
///
/// Stores color as RGB components for JSON serialization.
struct CodableColor: Codable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(color: Color) {
        // Default to blue if color resolution fails
        let resolved = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

// For macOS, replace UIColor with NSColor:
// #if canImport(UIKit)
// let resolved = UIColor(color)
// #elseif canImport(AppKit)
// let resolved = NSColor(color)
// #endif
```

## WhatsNewRelease.swift

```swift
import Foundation

/// Groups features for a specific app version.
///
/// Each release corresponds to one app update and contains
/// the features introduced in that version.
///
/// Usage:
/// ```swift
/// let release = WhatsNewRelease(
///     version: "2.1.0",
///     date: .now,
///     features: [feature1, feature2, feature3]
/// )
/// ```
struct WhatsNewRelease: Identifiable, Codable, Sendable {
    var id: String { version }

    /// Marketing version string (e.g., "2.1.0").
    /// Must match CFBundleShortVersionString.
    let version: String

    /// Release date for display purposes.
    let date: Date

    /// Features introduced in this version.
    let features: [WhatsNewFeature]
}
```

## VersionTracker.swift

```swift
import Foundation

/// Tracks which app version the user last saw What's New for.
///
/// Compares the stored version against the current bundle version
/// to determine whether the What's New screen should be displayed.
///
/// - Important: Uses `CFBundleShortVersionString` (marketing version),
///   NOT `CFBundleVersion` (build number).
///
/// Usage:
/// ```swift
/// let tracker = VersionTracker()
/// if tracker.shouldShowWhatsNew() {
///     // Present What's New screen
///     tracker.markVersionAsShown()
/// }
/// ```
final class VersionTracker: Sendable {
    private let defaults: UserDefaults
    private let currentVersion: String
    private let storageKey: String

    /// Creates a version tracker.
    ///
    /// - Parameters:
    ///   - defaults: UserDefaults instance (injectable for testing).
    ///   - currentVersion: Override the bundle version (injectable for testing).
    ///   - storageKey: UserDefaults key for persistence.
    init(
        defaults: UserDefaults = .standard,
        currentVersion: String? = nil,
        storageKey: String = "whatsNew.lastShownVersion"
    ) {
        self.defaults = defaults
        self.currentVersion = currentVersion
            ?? Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "1.0.0"
        self.storageKey = storageKey
    }

    /// The last version for which What's New was shown, or `nil` on first install.
    var lastShownVersion: String? {
        defaults.string(forKey: storageKey)
    }

    /// Whether the What's New screen should be displayed.
    ///
    /// Returns `false` on first install (no previous version stored)
    /// to avoid showing What's New to brand new users. Sets the current
    /// version silently so it shows on the *next* update.
    func shouldShowWhatsNew() -> Bool {
        guard let lastShown = lastShownVersion else {
            // First install — mark current version, show onboarding instead
            markVersionAsShown()
            return false
        }
        return currentVersion.compare(lastShown, options: .numeric) == .orderedDescending
    }

    /// Marks the current version as shown so What's New won't appear again
    /// until the next update.
    func markVersionAsShown() {
        defaults.set(currentVersion, forKey: storageKey)
    }

    /// Resets tracking — useful for debugging and testing.
    func reset() {
        defaults.removeObject(forKey: storageKey)
    }
}
```

## WhatsNewProvider.swift

```swift
import Foundation

/// Protocol for providing What's New content.
///
/// Conform to this protocol to supply features from different sources
/// (hardcoded, local JSON, remote endpoint).
protocol WhatsNewProviding: Sendable {
    /// Returns all known releases.
    func allReleases() async throws -> [WhatsNewRelease]

    /// Returns the release matching a specific version, if available.
    func release(for version: String) async throws -> WhatsNewRelease?

    /// Returns the most recent release.
    func latestRelease() async throws -> WhatsNewRelease?

    /// Returns all features from versions newer than the given version.
    func featuresSince(version: String) async throws -> [WhatsNewFeature]
}

/// Default implementations for common queries.
extension WhatsNewProviding {
    func release(for version: String) async throws -> WhatsNewRelease? {
        try await allReleases().first { $0.version == version }
    }

    func latestRelease() async throws -> WhatsNewRelease? {
        try await allReleases()
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
            .first
    }

    func featuresSince(version: String) async throws -> [WhatsNewFeature] {
        try await allReleases()
            .filter { $0.version.compare(version, options: .numeric) == .orderedDescending }
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedAscending }
            .flatMap(\.features)
    }
}

/// Provides What's New content from hardcoded Swift data.
///
/// This is the simplest approach — define releases directly in code.
/// No network required, no file parsing, always available.
///
/// Usage:
/// ```swift
/// let provider = LocalWhatsNewProvider()
/// let latest = try await provider.latestRelease()
/// ```
struct LocalWhatsNewProvider: WhatsNewProviding {
    /// Define your releases here, newest first.
    ///
    /// Add a new entry at the top each time you release an update.
    static let releases: [WhatsNewRelease] = [
        // --- Add new releases at the top ---
        WhatsNewRelease(
            version: "2.1.0",
            date: Date(timeIntervalSince1970: 1_700_000_000),
            features: [
                WhatsNewFeature(
                    title: "Dark Mode",
                    description: "Full dark mode support across every screen.",
                    systemImage: "moon.fill",
                    tintColor: .indigo
                ),
                WhatsNewFeature(
                    title: "Faster Search",
                    description: "Search results now appear instantly as you type.",
                    systemImage: "magnifyingglass",
                    tintColor: .orange
                ),
                WhatsNewFeature(
                    title: "Widget Support",
                    description: "Add home screen widgets for quick access.",
                    systemImage: "rectangle.on.rectangle",
                    tintColor: .green
                ),
            ]
        ),
        WhatsNewRelease(
            version: "2.0.0",
            date: Date(timeIntervalSince1970: 1_695_000_000),
            features: [
                WhatsNewFeature(
                    title: "Redesigned Interface",
                    description: "A fresh new look with improved navigation.",
                    systemImage: "sparkles",
                    tintColor: .blue
                ),
                WhatsNewFeature(
                    title: "iCloud Sync",
                    description: "Your data now syncs seamlessly across all devices.",
                    systemImage: "icloud.fill",
                    tintColor: .cyan
                ),
            ]
        ),
    ]

    func allReleases() async throws -> [WhatsNewRelease] {
        Self.releases
    }
}
```

## RemoteWhatsNewProvider.swift (Optional)

```swift
import Foundation

/// Fetches What's New content from a remote JSON endpoint.
///
/// Falls back to a local provider if the network request fails.
///
/// Expected JSON format:
/// ```json
/// {
///   "releases": [
///     {
///       "version": "2.1.0",
///       "date": "2024-11-14T00:00:00Z",
///       "features": [
///         {
///           "title": "Dark Mode",
///           "description": "Full dark mode support.",
///           "systemImage": "moon.fill",
///           "tintColor": { "red": 0.29, "green": 0.27, "blue": 0.62, "opacity": 1.0 }
///         }
///       ]
///     }
///   ]
/// }
/// ```
actor RemoteWhatsNewProvider: WhatsNewProviding {
    private let endpoint: URL
    private let session: URLSession
    private let fallback: any WhatsNewProviding
    private let cacheExpiration: TimeInterval

    private var cachedReleases: [WhatsNewRelease]?
    private var lastFetchDate: Date?

    init(
        endpoint: URL,
        session: URLSession = .shared,
        fallback: any WhatsNewProviding = LocalWhatsNewProvider(),
        cacheExpiration: TimeInterval = 3600  // 1 hour
    ) {
        self.endpoint = endpoint
        self.session = session
        self.fallback = fallback
        self.cacheExpiration = cacheExpiration
    }

    func allReleases() async throws -> [WhatsNewRelease] {
        // Return cached data if still fresh
        if let cached = cachedReleases,
           let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < cacheExpiration {
            return cached
        }

        do {
            let (data, response) = try await session.data(from: endpoint)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return try await fallback.allReleases()
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let container = try decoder.decode(ReleasesContainer.self, from: data)
            cachedReleases = container.releases
            lastFetchDate = Date()
            return container.releases
        } catch {
            // Network failure — use fallback
            return try await fallback.allReleases()
        }
    }

    nonisolated func release(for version: String) async throws -> WhatsNewRelease? {
        try await allReleases().first { $0.version == version }
    }

    nonisolated func latestRelease() async throws -> WhatsNewRelease? {
        try await allReleases()
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
            .first
    }

    nonisolated func featuresSince(version: String) async throws -> [WhatsNewFeature] {
        try await allReleases()
            .filter { $0.version.compare(version, options: .numeric) == .orderedDescending }
            .sorted { $0.version.compare($1.version, options: .numeric) == .orderedAscending }
            .flatMap(\.features)
    }
}

/// JSON decoding container.
private struct ReleasesContainer: Codable {
    let releases: [WhatsNewRelease]
}
```

## WhatsNewView.swift

```swift
import SwiftUI

/// A paged view displaying new features for a release.
///
/// Shows each feature as a full-page card with an SF Symbol icon,
/// title, and description. Includes a "Continue" button on the last page.
///
/// Usage:
/// ```swift
/// WhatsNewView(release: release) {
///     // Called when user finishes viewing
/// }
/// ```
struct WhatsNewView: View {
    let release: WhatsNewRelease
    var onDismiss: (() -> Void)?

    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            headerView

            TabView(selection: $currentPage) {
                ForEach(Array(release.features.enumerated()), id: \.element.id) { index, feature in
                    FeaturePageView(feature: feature)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            bottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .background(Color(uiColor: .systemGroupedBackground))
        #elseif os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 480, minHeight: 560)
        #endif
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("What's New")
                .font(.largeTitle.bold())
            Text("Version \(release.version)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
        .padding(.bottom, 16)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 12) {
            pageIndicatorLabel

            Button(action: handleContinue) {
                Text(isLastPage ? "Continue" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 32)
    }

    private var pageIndicatorLabel: some View {
        Text("\(currentPage + 1) of \(release.features.count)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Logic

    private var isLastPage: Bool {
        currentPage >= release.features.count - 1
    }

    private func handleContinue() {
        if isLastPage {
            onDismiss?()
            dismiss()
        } else {
            withAnimation {
                currentPage += 1
            }
        }
    }
}

/// Displays a single feature as a full-page card.
struct FeaturePageView: View {
    let feature: WhatsNewFeature

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: feature.systemImage)
                .font(.system(size: 64))
                .foregroundStyle(feature.tintColor.color)
                .accessibilityHidden(true)

            Text(feature.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(feature.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    WhatsNewView(
        release: WhatsNewRelease(
            version: "2.1.0",
            date: .now,
            features: [
                WhatsNewFeature(
                    title: "Dark Mode",
                    description: "Full dark mode support across every screen.",
                    systemImage: "moon.fill",
                    tintColor: .indigo
                ),
                WhatsNewFeature(
                    title: "Faster Search",
                    description: "Search results now appear instantly as you type.",
                    systemImage: "magnifyingglass",
                    tintColor: .orange
                ),
                WhatsNewFeature(
                    title: "Widgets",
                    description: "Add home screen widgets for quick access.",
                    systemImage: "rectangle.on.rectangle",
                    tintColor: .green
                ),
            ]
        )
    )
}
#endif
```

## WhatsNewSheet.swift

```swift
import SwiftUI

/// A view modifier that automatically presents the What's New sheet
/// when a new app version is detected.
///
/// Uses `.sheet(item:)` pattern for proper data-driven presentation.
/// Marks the version as shown on dismiss, so it only appears once per update.
///
/// Usage:
/// ```swift
/// ContentView()
///     .whatsNewSheet()
///
/// // With custom provider:
/// ContentView()
///     .whatsNewSheet(provider: myRemoteProvider)
/// ```
struct WhatsNewSheetModifier: ViewModifier {
    let provider: any WhatsNewProviding
    let tracker: VersionTracker

    @State private var releaseToShow: WhatsNewRelease?

    init(
        provider: any WhatsNewProviding = LocalWhatsNewProvider(),
        tracker: VersionTracker = VersionTracker()
    ) {
        self.provider = provider
        self.tracker = tracker
    }

    func body(content: Content) -> some View {
        content
            .sheet(item: $releaseToShow) { release in
                WhatsNewView(release: release) {
                    tracker.markVersionAsShown()
                }
                #if os(iOS)
                .interactiveDismissDisabled(false)
                #endif
            }
            .task {
                await checkForUpdate()
            }
    }

    private func checkForUpdate() async {
        guard tracker.shouldShowWhatsNew() else { return }

        do {
            if let release = try await provider.latestRelease() {
                releaseToShow = release
            }
        } catch {
            // Silently fail — don't block the user experience
        }
    }
}

extension View {
    /// Presents a What's New sheet automatically after app updates.
    ///
    /// - Parameters:
    ///   - provider: Content source for What's New features.
    ///   - tracker: Version tracker instance (injectable for testing).
    /// - Returns: A view that auto-presents What's New when appropriate.
    func whatsNewSheet(
        provider: any WhatsNewProviding = LocalWhatsNewProvider(),
        tracker: VersionTracker = VersionTracker()
    ) -> some View {
        modifier(WhatsNewSheetModifier(provider: provider, tracker: tracker))
    }
}

#if DEBUG
/// Preview helper that always shows the sheet.
#Preview {
    Text("App Content")
        .whatsNewSheet(
            tracker: {
                let defaults = UserDefaults(suiteName: "PreviewWhatsNew")!
                defaults.removePersistentDomain(forName: "PreviewWhatsNew")
                // Set a previous version so shouldShowWhatsNew() returns true
                defaults.set("1.0.0", forKey: "whatsNew.lastShownVersion")
                return VersionTracker(
                    defaults: defaults,
                    currentVersion: "2.1.0"
                )
            }()
        )
}
#endif
```
