# Force Update Code Templates

Production-ready Swift templates for a force update / minimum version check system. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## AppVersion.swift

```swift
import Foundation

/// Semantic version representation (major.minor.patch) with comparison support.
///
/// Parses version strings like "2.1.3" and provides `Comparable` conformance
/// for safe numeric comparison — never compare version strings lexicographically.
///
/// Usage:
/// ```swift
/// let current = AppVersion.current  // From Bundle
/// let minimum = AppVersion(string: "2.0.0")
/// if current < minimum { /* force update */ }
/// ```
struct AppVersion: Sendable, Codable, Hashable {
    let major: Int
    let minor: Int
    let patch: Int

    init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parse from a version string like "2.1.3".
    /// Returns nil if the string cannot be parsed.
    init?(string: String) {
        let components = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ".")
            .compactMap { Int($0) }

        guard components.count >= 2 else { return nil }

        self.major = components[0]
        self.minor = components[1]
        self.patch = components.count >= 3 ? components[2] : 0
    }

    /// The current app version from the main bundle's CFBundleShortVersionString.
    static var current: AppVersion {
        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        return AppVersion(string: versionString) ?? AppVersion(major: 0, minor: 0, patch: 0)
    }

    /// Display string, e.g. "2.1.3".
    var displayString: String {
        "\(major).\(minor).\(patch)"
    }
}

extension AppVersion: Comparable {
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

extension AppVersion: CustomStringConvertible {
    var description: String { displayString }
}
```

## UpdateRequirement.swift

```swift
import Foundation

/// The result of a version check — determines what UI to show.
///
/// - `none`: App is up to date, no action needed.
/// - `softUpdate`: A recommended update is available. User can dismiss or skip.
/// - `hardUpdate`: A mandatory update is required. App usage is blocked.
enum UpdateRequirement: Sendable, Codable, Equatable {
    /// App is current or check was skipped.
    case none

    /// A recommended (non-blocking) update is available.
    case softUpdate(version: AppVersion, message: String)

    /// A mandatory (blocking) update is required.
    case hardUpdate(version: AppVersion, message: String)

    /// The App Store URL for this app.
    ///
    /// Set this from the remote config response.
    /// Falls back to the main App Store page if not configured.
    var storeURL: URL {
        // Replace with your actual App Store URL or make configurable.
        URL(string: "https://apps.apple.com/app/id000000000")!
    }
}

/// Remote configuration model for JSON-based version checking.
///
/// Expected JSON format:
/// ```json
/// {
///     "minimumVersion": "2.0.0",
///     "minimumVersionMessage": "Please update for critical security fixes.",
///     "recommendedVersion": "2.1.0",
///     "recommendedVersionMessage": "Update for new features and improvements.",
///     "storeURL": "https://apps.apple.com/app/id123456789"
/// }
/// ```
struct RemoteVersionConfig: Sendable, Codable {
    let minimumVersion: String
    let minimumVersionMessage: String
    let recommendedVersion: String?
    let recommendedVersionMessage: String?
    let storeURL: String?

    /// Evaluate the update requirement for a given app version.
    func requirement(for currentVersion: AppVersion) -> UpdateRequirement {
        // Check hard block first
        if let minimum = AppVersion(string: minimumVersion), currentVersion < minimum {
            return .hardUpdate(version: minimum, message: minimumVersionMessage)
        }

        // Check soft recommendation
        if let recommendedString = recommendedVersion,
           let recommended = AppVersion(string: recommendedString),
           let message = recommendedVersionMessage,
           currentVersion < recommended {
            return .softUpdate(version: recommended, message: message)
        }

        return .none
    }
}
```

## VersionChecker.swift

```swift
import Foundation

/// Protocol for checking the minimum required app version.
///
/// Conform to this protocol to implement custom version check sources
/// (remote JSON, App Store lookup, Firebase Remote Config, etc.).
protocol VersionChecking: Sendable {
    func checkForUpdate(currentVersion: AppVersion) async throws -> UpdateRequirement
}

// MARK: - Remote JSON Version Checker

/// Checks app version against a JSON endpoint you control.
///
/// This is the recommended approach — you have full control over the response
/// format, rate limits, and can update requirements without an app release.
///
/// Expected JSON format: see `RemoteVersionConfig`.
///
/// Usage:
/// ```swift
/// let checker = RemoteJSONVersionChecker(
///     url: URL(string: "https://api.example.com/app-config")!
/// )
/// let requirement = try await checker.checkForUpdate(currentVersion: .current)
/// ```
actor RemoteJSONVersionChecker: VersionChecking {
    private let url: URL
    private let session: URLSession

    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func checkForUpdate(currentVersion: AppVersion) async throws -> UpdateRequirement {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VersionCheckError.serverError
        }

        let decoder = JSONDecoder()
        let config = try decoder.decode(RemoteVersionConfig.self, from: data)
        return config.requirement(for: currentVersion)
    }
}

// MARK: - App Store Lookup Checker

/// Checks app version against the App Store using the iTunes Search API.
///
/// No server infrastructure needed — queries Apple's public API.
///
/// **Limitations:**
/// - Undocumented rate limits (avoid calling too frequently)
/// - Only detects that a newer version exists, cannot distinguish hard vs soft
/// - Propagation delay: new versions may not appear immediately after release
/// - All updates are treated as soft updates; override `isCritical` for hard blocks
///
/// Usage:
/// ```swift
/// let checker = AppStoreLookupChecker(bundleId: "com.example.myapp")
/// let requirement = try await checker.checkForUpdate(currentVersion: .current)
/// ```
actor AppStoreLookupChecker: VersionChecking {
    private let bundleId: String
    private let countryCode: String
    private let session: URLSession

    init(
        bundleId: String? = nil,
        countryCode: String = "us",
        session: URLSession = .shared
    ) {
        self.bundleId = bundleId ?? Bundle.main.bundleIdentifier ?? ""
        self.countryCode = countryCode
        self.session = session
    }

    func checkForUpdate(currentVersion: AppVersion) async throws -> UpdateRequirement {
        guard !bundleId.isEmpty else {
            throw VersionCheckError.invalidBundleId
        }

        let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=\(countryCode)")!
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VersionCheckError.serverError
        }

        let result = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)

        guard let storeVersion = result.results.first?.version,
              let latestVersion = AppVersion(string: storeVersion) else {
            return .none
        }

        if currentVersion < latestVersion {
            return .softUpdate(
                version: latestVersion,
                message: "A new version (\(latestVersion.displayString)) is available on the App Store."
            )
        }

        return .none
    }
}

/// Response model for the iTunes Search API lookup endpoint.
private struct AppStoreLookupResponse: Codable {
    let resultCount: Int
    let results: [AppStoreLookupResult]
}

private struct AppStoreLookupResult: Codable {
    let version: String
    let trackViewUrl: String?
}

// MARK: - Errors

/// Errors that can occur during version checking.
enum VersionCheckError: Error, LocalizedError {
    case serverError
    case invalidBundleId
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .serverError:
            return "Failed to reach the version check server."
        case .invalidBundleId:
            return "Bundle identifier is missing or invalid."
        case .invalidResponse:
            return "Received an invalid response from the version check server."
        }
    }
}
```

## UpdateManager.swift

```swift
import Foundation
import SwiftUI

/// How often the app should check for updates.
enum UpdateCheckFrequency: Sendable {
    case everyLaunch
    case daily
    case weekly

    var interval: TimeInterval {
        switch self {
        case .everyLaunch: return 0
        case .daily: return 24 * 3600
        case .weekly: return 7 * 24 * 3600
        }
    }
}

/// Coordinates version checks, caches timing, and exposes the current update requirement.
///
/// Usage:
/// ```swift
/// let manager = UpdateManager(
///     checker: RemoteJSONVersionChecker(url: configURL),
///     frequency: .daily
/// )
/// await manager.checkIfNeeded()
///
/// switch manager.requirement {
/// case .none: // App is current
/// case .softUpdate: // Show banner
/// case .hardUpdate: // Block usage
/// }
/// ```
@Observable
final class UpdateManager: @unchecked Sendable {
    /// The current update requirement after the last check.
    private(set) var requirement: UpdateRequirement = .none

    /// Whether a check is currently in progress.
    private(set) var isChecking = false

    private let checker: any VersionChecking
    private let currentVersion: AppVersion
    private let frequency: UpdateCheckFrequency
    private let userDefaults: UserDefaults

    private static let lastCheckDateKey = "ForceUpdate_lastCheckDate"
    private static let skippedVersionKey = "ForceUpdate_skippedVersion"

    init(
        checker: any VersionChecking,
        currentVersion: AppVersion = .current,
        frequency: UpdateCheckFrequency = .daily,
        userDefaults: UserDefaults = .standard
    ) {
        self.checker = checker
        self.currentVersion = currentVersion
        self.frequency = frequency
        self.userDefaults = userDefaults
    }

    /// Check for updates only if enough time has passed since the last check.
    ///
    /// Respects the configured `frequency`. Use `checkNow()` to force a check.
    func checkIfNeeded() async {
        guard shouldCheck() else { return }
        await checkNow()
    }

    /// Force an immediate version check, ignoring the frequency throttle.
    func checkNow() async {
        #if DEBUG
        // Skip version check in debug builds to avoid blocking development.
        // Remove or adjust this guard if you want to test force update UI.
        return
        #endif

        isChecking = true
        defer { isChecking = false }

        do {
            let result = try await checker.checkForUpdate(currentVersion: currentVersion)
            recordCheckTime()

            // If the user skipped this specific soft update version, treat as none
            if case .softUpdate(let version, _) = result, isVersionSkipped(version) {
                requirement = .none
            } else {
                requirement = result
            }
        } catch {
            // On network failure, default to no requirement.
            // Never block the user due to a failed check.
            requirement = .none
        }
    }

    /// Mark the current soft update version as skipped.
    ///
    /// The user won't see the soft prompt again until a newer version is available.
    func skipCurrentUpdate() {
        if case .softUpdate(let version, _) = requirement {
            userDefaults.set(version.displayString, forKey: Self.skippedVersionKey)
            requirement = .none
        }
    }

    /// Open the App Store page for this app.
    func openAppStore() {
        let url = requirement.storeURL
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    // MARK: - Private

    private func shouldCheck() -> Bool {
        guard frequency != .everyLaunch else { return true }

        guard let lastCheck = userDefaults.object(forKey: Self.lastCheckDateKey) as? Date else {
            return true
        }

        return Date().timeIntervalSince(lastCheck) >= frequency.interval
    }

    private func recordCheckTime() {
        userDefaults.set(Date(), forKey: Self.lastCheckDateKey)
    }

    private func isVersionSkipped(_ version: AppVersion) -> Bool {
        guard let skippedString = userDefaults.string(forKey: Self.skippedVersionKey),
              let skipped = AppVersion(string: skippedString) else {
            return false
        }
        return skipped == version
    }
}
```

## ForceUpdateView.swift

```swift
import SwiftUI

/// Full-screen blocking view shown when a hard (mandatory) update is required.
///
/// Displays an icon, title, message, and an "Update Now" button that opens
/// the App Store. There is no dismiss option — the user must update.
///
/// Usage:
/// ```swift
/// ForceUpdateView(
///     message: "This version is no longer supported.",
///     storeURL: URL(string: "https://apps.apple.com/app/id123456789")!
/// )
/// ```
struct ForceUpdateView: View {
    let message: String
    let storeURL: URL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            Text("Update Required")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: openStore) {
                Text("Update Now")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 48)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .interactiveDismissDisabled()
    }

    private func openStore() {
        #if canImport(UIKit)
        UIApplication.shared.open(storeURL)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(storeURL)
        #endif
    }
}
```

## SoftUpdateBannerView.swift

```swift
import SwiftUI

/// Non-blocking banner shown when a soft (recommended) update is available.
///
/// Displays a message with "Update" and "Later" buttons.
/// Supports skipping a specific version so the user isn't prompted again
/// until a newer version is released.
///
/// Usage:
/// ```swift
/// SoftUpdateBannerView(
///     message: "A new version is available with performance improvements.",
///     onUpdate: { updateManager.openAppStore() },
///     onSkip: { updateManager.skipCurrentUpdate() }
/// )
/// ```
struct SoftUpdateBannerView: View {
    let message: String
    let onUpdate: () -> Void
    let onSkip: () -> Void

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.down.app")
                        .font(.title3)
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Update Available")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        withAnimation {
                            isVisible = false
                        }
                        onSkip()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss")
                }

                HStack(spacing: 12) {
                    Button("Later") {
                        withAnimation {
                            isVisible = false
                        }
                        onSkip()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("Update") {
                        onUpdate()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            }
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
```

## UpdateCheckModifier.swift

```swift
import SwiftUI

/// ViewModifier that automatically checks for updates on appear
/// and presents the appropriate UI (hard block or soft banner).
///
/// Usage:
/// ```swift
/// ContentView()
///     .checkForUpdates()
///
/// // With custom configuration:
/// ContentView()
///     .checkForUpdates(
///         checker: RemoteJSONVersionChecker(url: configURL),
///         frequency: .daily
///     )
/// ```
struct UpdateCheckModifier: ViewModifier {
    @State private var updateManager: UpdateManager

    init(checker: any VersionChecking, frequency: UpdateCheckFrequency) {
        _updateManager = State(
            wrappedValue: UpdateManager(checker: checker, frequency: frequency)
        )
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .environment(updateManager)

            // Soft update banner at the top
            if case .softUpdate(_, let message) = updateManager.requirement {
                VStack {
                    SoftUpdateBannerView(
                        message: message,
                        onUpdate: { updateManager.openAppStore() },
                        onSkip: { updateManager.skipCurrentUpdate() }
                    )
                    Spacer()
                }
                .animation(.easeInOut, value: updateManager.requirement)
            }
        }
        // Hard update as a full-screen cover
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    if case .hardUpdate = updateManager.requirement { return true }
                    return false
                },
                set: { _ in }
            )
        ) {
            if case .hardUpdate(_, let message) = updateManager.requirement {
                ForceUpdateView(
                    message: message,
                    storeURL: updateManager.requirement.storeURL
                )
            }
        }
        .task {
            await updateManager.checkIfNeeded()
        }
    }
}

extension View {
    /// Check for app updates on appear and present the appropriate UI.
    ///
    /// - Parameters:
    ///   - checker: The version checking implementation to use.
    ///   - frequency: How often to check (default: `.daily`).
    /// - Returns: A modified view that checks for updates automatically.
    func checkForUpdates(
        checker: any VersionChecking = RemoteJSONVersionChecker(
            url: URL(string: "https://api.example.com/app-config")!
        ),
        frequency: UpdateCheckFrequency = .daily
    ) -> some View {
        modifier(UpdateCheckModifier(checker: checker, frequency: frequency))
    }
}
```
