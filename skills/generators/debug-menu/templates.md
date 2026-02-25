# Debug Menu Code Templates

Production-ready Swift templates for a developer debug menu. All code targets iOS 17+ / macOS 14+ with @Observable and modern Swift concurrency. **Every type and extension is wrapped in `#if DEBUG`** to ensure nothing ships to production.

## DebugMenuView.swift

```swift
#if DEBUG
import SwiftUI

/// Main debug menu presented as a NavigationStack with categorized sections.
///
/// Access via shake gesture or hidden tap using `.debugMenuTrigger()`.
struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var environmentSwitcher = DebugEnvironmentSwitcher.shared
    @State private var showResetConfirmation = false
    @State private var showExportSheet = false
    @State private var diagnosticReport = ""

    var body: some View {
        NavigationStack {
            List {
                appInfoSection
                featureFlagsSection
                environmentSection
                cacheSection
                networkLogSection
                diagnosticsSection
                actionsSection
            }
            .navigationTitle("Debug Menu")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: diagnosticReport) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(diagnosticReport.isEmpty)
                }
            }
            .task {
                diagnosticReport = DiagnosticInfo.collect().formattedReport
            }
        }
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        Section("App Info") {
            LabeledContent("Version", value: Bundle.main.appVersion)
            LabeledContent("Build", value: Bundle.main.buildNumber)
            LabeledContent("OS", value: ProcessInfo.processInfo.operatingSystemVersionString)
            LabeledContent("Device", value: DiagnosticInfo.deviceModel)
            LabeledContent("Bundle ID", value: Bundle.main.bundleIdentifier ?? "N/A")
        }
    }

    // MARK: - Feature Flags

    private var featureFlagsSection: some View {
        Section("Feature Flags") {
            ForEach(DebugMenuView.featureFlags) { flag in
                FeatureFlagToggleRow(flag: flag)
            }

            if DebugMenuView.featureFlags.isEmpty {
                Text("No feature flags configured.")
                    .foregroundStyle(.secondary)
                    .italic()
            }

            Button("Reset All Flags", role: .destructive) {
                DebugActions.resetFeatureFlags(DebugMenuView.featureFlags)
            }
        }
    }

    /// Register your feature flags here.
    ///
    /// ```swift
    /// static let featureFlags: [FeatureFlag] = [
    ///     FeatureFlag(key: "new_onboarding", title: "New Onboarding", defaultValue: false),
    /// ]
    /// ```
    static var featureFlags: [FeatureFlag] = []

    // MARK: - Environment

    private var environmentSection: some View {
        Section("Environment") {
            Picker("API Environment", selection: $environmentSwitcher.current) {
                ForEach(AppEnvironment.allCases, id: \.self) { env in
                    Text(env.displayName).tag(env)
                }
            }
            .pickerStyle(.segmented)

            LabeledContent("Base URL", value: environmentSwitcher.baseURL.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)

            if environmentSwitcher.needsRestart {
                Label("Restart recommended for full effect", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

    // MARK: - Cache

    private var cacheSection: some View {
        Section("Cache") {
            Button("Clear Image Cache") {
                DebugActions.clearImageCache()
            }

            Button("Clear HTTP Cache") {
                DebugActions.clearHTTPCache()
            }

            Button("Clear All Caches", role: .destructive) {
                DebugActions.clearAllCaches()
            }

            LabeledContent("URL Cache Size", value: DebugActions.urlCacheSizeDescription)
        }
    }

    // MARK: - Network Log

    private var networkLogSection: some View {
        Section("Network Log") {
            NavigationLink {
                DebugNetworkLogListView()
            } label: {
                HStack {
                    Text("Recent Requests")
                    Spacer()
                    Text("\(DebugNetworkLogger.shared.entryCount)")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Diagnostics

    private var diagnosticsSection: some View {
        Section("Diagnostics") {
            let info = DiagnosticInfo.collect()
            LabeledContent("Memory Usage", value: info.formattedMemoryUsage)
            LabeledContent("Disk Free", value: info.formattedDiskFree)
            LabeledContent("Locale", value: Locale.current.identifier)
            LabeledContent("Timezone", value: TimeZone.current.identifier)
            LabeledContent("Preferred Languages", value: Locale.preferredLanguages.prefix(3).joined(separator: ", "))
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section("Actions") {
            Button("Reset Onboarding") {
                DebugActions.resetOnboarding()
            }

            Button("Clear UserDefaults") {
                showResetConfirmation = true
            }
            .confirmationDialog("Clear all UserDefaults?", isPresented: $showResetConfirmation) {
                Button("Clear All", role: .destructive) {
                    DebugActions.clearUserDefaults()
                }
            } message: {
                Text("This will remove all stored preferences. The app may behave as if freshly installed.")
            }

            Button("Force Crash", role: .destructive) {
                DebugActions.simulateCrash()
            }
        }
    }
}

// MARK: - Feature Flag Model

/// A toggleable feature flag stored in UserDefaults.
struct FeatureFlag: Identifiable {
    let key: String
    let title: String
    let defaultValue: Bool

    var id: String { key }

    private var userDefaultsKey: String { "debug_flag_\(key)" }

    var isEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: userDefaultsKey) != nil {
                return UserDefaults.standard.bool(forKey: userDefaultsKey)
            }
            return defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
            NotificationCenter.default.post(name: .debugFeatureFlagChanged, object: key)
        }
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

extension Notification.Name {
    static let debugFeatureFlagChanged = Notification.Name("debugFeatureFlagChanged")
}

/// A row that toggles a single feature flag.
struct FeatureFlagToggleRow: View {
    let flag: FeatureFlag
    @State private var isOn: Bool

    init(flag: FeatureFlag) {
        self.flag = flag
        self._isOn = State(initialValue: flag.isEnabled)
    }

    var body: some View {
        Toggle(flag.title, isOn: $isOn)
            .onChange(of: isOn) { _, newValue in
                var mutableFlag = flag
                mutableFlag.isEnabled = newValue
            }
    }
}

// MARK: - Bundle Helpers

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
}

#Preview {
    DebugMenuView()
}
#endif
```

## DebugEnvironmentSwitcher.swift

```swift
#if DEBUG
import Foundation
import Observation

/// Available API environments.
enum AppEnvironment: String, CaseIterable, Sendable {
    case development
    case staging
    case production

    var displayName: String {
        switch self {
        case .development: "Development"
        case .staging: "Staging"
        case .production: "Production"
        }
    }

    var baseURL: URL {
        switch self {
        case .development:
            URL(string: "https://dev-api.example.com/v1")!
        case .staging:
            URL(string: "https://staging-api.example.com/v1")!
        case .production:
            URL(string: "https://api.example.com/v1")!
        }
    }
}

/// Manages switching between API environments at runtime.
///
/// Persists the selected environment to UserDefaults.
/// Services should read `DebugEnvironmentSwitcher.shared.baseURL`
/// for their API base URL.
///
/// Usage:
/// ```swift
/// let baseURL = DebugEnvironmentSwitcher.shared.baseURL
/// ```
@Observable
final class DebugEnvironmentSwitcher {
    static let shared = DebugEnvironmentSwitcher()

    private static let storageKey = "debug_selected_environment"

    var current: AppEnvironment {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: Self.storageKey)
            needsRestart = (current != initialEnvironment)
        }
    }

    var needsRestart = false

    var baseURL: URL { current.baseURL }

    private let initialEnvironment: AppEnvironment

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.storageKey),
           let env = AppEnvironment(rawValue: stored) {
            self.current = env
            self.initialEnvironment = env
        } else {
            self.current = .development
            self.initialEnvironment = .development
        }
    }
}
#endif
```

## DebugNetworkLogger.swift

```swift
#if DEBUG
import Foundation

/// A single logged network request/response pair.
struct NetworkLogEntry: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let url: String
    let method: String
    let statusCode: Int
    let duration: TimeInterval
    let requestHeaders: [String: String]
    let responseHeaders: [String: String]
    let requestBodySize: Int
    let responseBodySize: Int
    let responseBodyPreview: String

    var isSuccess: Bool { (200...299).contains(statusCode) }

    var formattedDuration: String {
        String(format: "%.0fms", duration * 1000)
    }

    var statusEmoji: String {
        switch statusCode {
        case 200...299: return "green"
        case 300...399: return "yellow"
        case 400...499: return "orange"
        default: return "red"
        }
    }
}

/// Singleton actor that collects recent network requests.
///
/// Uses a circular buffer to store the last 100 entries.
/// Hook into your networking layer to log requests:
///
/// ```swift
/// DebugNetworkLogger.shared.log(
///     request: request,
///     response: response,
///     data: data,
///     duration: elapsed
/// )
/// ```
actor DebugNetworkLogger {
    static let shared = DebugNetworkLogger()

    private var buffer: [NetworkLogEntry] = []
    private let maxEntries = 100

    var entries: [NetworkLogEntry] {
        buffer.reversed()  // Most recent first
    }

    var entryCount: Int { buffer.count }

    /// Log a completed network request.
    func log(
        request: URLRequest,
        response: URLResponse,
        data: Data,
        duration: TimeInterval
    ) {
        let httpResponse = response as? HTTPURLResponse

        // Redact sensitive headers
        var sanitizedRequestHeaders = request.allHTTPHeaderFields ?? [:]
        sanitizedRequestHeaders["Authorization"] = sanitizedRequestHeaders["Authorization"] != nil ? "[REDACTED]" : nil
        sanitizedRequestHeaders["Cookie"] = sanitizedRequestHeaders["Cookie"] != nil ? "[REDACTED]" : nil

        let responseHeaders = httpResponse?.allHeaderFields as? [String: String] ?? [:]

        // Truncate response body preview
        let maxPreviewLength = 500
        let bodyPreview: String
        if let bodyString = String(data: data.prefix(maxPreviewLength), encoding: .utf8) {
            bodyPreview = data.count > maxPreviewLength ? bodyString + "... (\(data.count) bytes total)" : bodyString
        } else {
            bodyPreview = "[\(data.count) bytes, non-UTF8]"
        }

        let entry = NetworkLogEntry(
            timestamp: Date(),
            url: request.url?.absoluteString ?? "Unknown",
            method: request.httpMethod ?? "GET",
            statusCode: httpResponse?.statusCode ?? 0,
            duration: duration,
            requestHeaders: sanitizedRequestHeaders,
            responseHeaders: responseHeaders,
            requestBodySize: request.httpBody?.count ?? 0,
            responseBodySize: data.count,
            responseBodyPreview: bodyPreview
        )

        buffer.append(entry)

        // Circular buffer: remove oldest when exceeding limit
        if buffer.count > maxEntries {
            buffer.removeFirst(buffer.count - maxEntries)
        }
    }

    /// Clear all logged entries.
    func clear() {
        buffer.removeAll()
    }
}

// MARK: - Network Log List View

import SwiftUI

/// Displays all logged network requests in a navigable list.
struct DebugNetworkLogListView: View {
    @State private var entries: [NetworkLogEntry] = []
    @State private var searchText = ""

    var filteredEntries: [NetworkLogEntry] {
        if searchText.isEmpty { return entries }
        return entries.filter { $0.url.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(filteredEntries) { entry in
            NavigationLink {
                NetworkLogDetailView(entry: entry)
            } label: {
                HStack {
                    Circle()
                        .fill(statusColor(for: entry.statusCode))
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(entry.method)
                                .font(.caption.monospaced().bold())
                            Text("\(entry.statusCode)")
                                .font(.caption.monospaced())
                                .foregroundStyle(statusColor(for: entry.statusCode))
                        }
                        Text(entry.url)
                            .font(.caption2)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(entry.formattedDuration)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Filter by URL")
        .navigationTitle("Network Log")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") {
                    Task {
                        await DebugNetworkLogger.shared.clear()
                        entries = []
                    }
                }
            }
        }
        .task {
            entries = await DebugNetworkLogger.shared.entries
        }
        .refreshable {
            entries = await DebugNetworkLogger.shared.entries
        }
    }

    private func statusColor(for code: Int) -> Color {
        switch code {
        case 200...299: .green
        case 300...399: .yellow
        case 400...499: .orange
        default: .red
        }
    }
}

/// Detail view for a single network log entry.
struct NetworkLogDetailView: View {
    let entry: NetworkLogEntry

    var body: some View {
        List {
            Section("Request") {
                LabeledContent("Method", value: entry.method)
                LabeledContent("URL", value: entry.url)
                    .textSelection(.enabled)
                LabeledContent("Body Size", value: "\(entry.requestBodySize) bytes")
            }

            Section("Response") {
                LabeledContent("Status", value: "\(entry.statusCode)")
                LabeledContent("Duration", value: entry.formattedDuration)
                LabeledContent("Body Size", value: "\(entry.responseBodySize) bytes")
            }

            if !entry.requestHeaders.isEmpty {
                Section("Request Headers") {
                    ForEach(entry.requestHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        LabeledContent(key, value: value)
                            .font(.caption)
                    }
                }
            }

            if !entry.responseHeaders.isEmpty {
                Section("Response Headers") {
                    ForEach(entry.responseHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        LabeledContent(key, value: value)
                            .font(.caption)
                    }
                }
            }

            Section("Response Body Preview") {
                Text(entry.responseBodyPreview)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("\(entry.method) \(entry.statusCode)")
    }
}
#endif
```

## DiagnosticInfo.swift

```swift
#if DEBUG
import Foundation

/// Collects device and app diagnostic information.
///
/// Usage:
/// ```swift
/// let info = DiagnosticInfo.collect()
/// print(info.formattedReport)
/// ```
struct DiagnosticInfo {
    let appVersion: String
    let buildNumber: String
    let bundleIdentifier: String
    let osVersion: String
    let deviceModel: String
    let memoryUsageMB: Double
    let totalMemoryMB: Double
    let diskFreeMB: Double
    let diskTotalMB: Double
    let locale: String
    let timezone: String
    let preferredLanguages: [String]
    let isLowPowerMode: Bool
    let thermalState: String
    let timestamp: Date

    /// Collect current diagnostic information.
    static func collect() -> DiagnosticInfo {
        let processInfo = ProcessInfo.processInfo
        let fileManager = FileManager.default

        // Memory usage
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        let memoryUsageMB = result == KERN_SUCCESS
            ? Double(taskInfo.resident_size) / (1024 * 1024)
            : 0

        // Disk space
        let homeURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
        let diskValues = try? homeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
        let diskFreeMB = Double(diskValues?.volumeAvailableCapacityForImportantUsage ?? 0) / (1024 * 1024)
        let diskTotalMB = Double(diskValues?.volumeTotalCapacity ?? 0) / (1024 * 1024)

        // Thermal state
        let thermalState: String = switch processInfo.thermalState {
        case .nominal: "Nominal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        @unknown default: "Unknown"
        }

        return DiagnosticInfo(
            appVersion: Bundle.main.appVersion,
            buildNumber: Bundle.main.buildNumber,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "N/A",
            osVersion: processInfo.operatingSystemVersionString,
            deviceModel: Self.deviceModel,
            memoryUsageMB: memoryUsageMB,
            totalMemoryMB: Double(processInfo.physicalMemory) / (1024 * 1024),
            diskFreeMB: diskFreeMB,
            diskTotalMB: diskTotalMB,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier,
            preferredLanguages: Array(Locale.preferredLanguages.prefix(5)),
            isLowPowerMode: processInfo.isLowPowerModeEnabled,
            thermalState: thermalState,
            timestamp: Date()
        )
    }

    /// Human-readable device model string.
    static var deviceModel: String {
        #if canImport(UIKit)
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
        #elseif canImport(AppKit)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
        #endif
    }

    // MARK: - Formatted Output

    var formattedMemoryUsage: String {
        String(format: "%.0f MB / %.0f MB", memoryUsageMB, totalMemoryMB)
    }

    var formattedDiskFree: String {
        if diskFreeMB > 1024 {
            return String(format: "%.1f GB free", diskFreeMB / 1024)
        }
        return String(format: "%.0f MB free", diskFreeMB)
    }

    /// Full diagnostic report formatted for sharing.
    var formattedReport: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .long

        return """
        === Diagnostic Report ===
        Generated: \(dateFormatter.string(from: timestamp))

        -- App --
        Version: \(appVersion) (\(buildNumber))
        Bundle ID: \(bundleIdentifier)

        -- Device --
        Model: \(deviceModel)
        OS: \(osVersion)
        Thermal State: \(thermalState)
        Low Power Mode: \(isLowPowerMode ? "Yes" : "No")

        -- Memory --
        App Usage: \(String(format: "%.0f MB", memoryUsageMB))
        Total: \(String(format: "%.0f MB", totalMemoryMB))

        -- Disk --
        Free: \(formattedDiskFree)
        Total: \(String(format: "%.1f GB", diskTotalMB / 1024))

        -- Locale --
        Current: \(locale)
        Timezone: \(timezone)
        Languages: \(preferredLanguages.joined(separator: ", "))

        -- Debug State --
        Environment: \(DebugEnvironmentSwitcher.shared.current.displayName)
        Base URL: \(DebugEnvironmentSwitcher.shared.baseURL.absoluteString)
        ===========================
        """
    }
}
#endif
```

## DebugMenuTrigger.swift

```swift
#if DEBUG
import SwiftUI

// MARK: - Trigger Method

/// How the debug menu is activated.
enum DebugTriggerMethod {
    /// Shake the device to open.
    case shakeGesture
    /// Tap a hidden area 5 times to open.
    case hiddenTap
    /// Both shake and hidden tap.
    case both
}

// MARK: - Shake Detection (iOS)

#if canImport(UIKit)
import UIKit

/// Custom UIWindow subclass that detects shake gestures.
///
/// Set your app's window to this class to enable shake-to-debug.
/// The window posts a notification when a shake is detected.
class ShakeDetectingWindow: UIWindow {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .debugShakeDetected, object: nil)
        }
    }
}

extension Notification.Name {
    static let debugShakeDetected = Notification.Name("debugShakeDetected")
}
#endif

// MARK: - View Modifier

/// ViewModifier that presents the debug menu via shake gesture and/or hidden tap.
///
/// Usage:
/// ```swift
/// ContentView()
///     .debugMenuTrigger()                    // Both shake + tap
///     .debugMenuTrigger(method: .shakeGesture) // Shake only
///     .debugMenuTrigger(method: .hiddenTap)    // Hidden tap only
/// ```
struct DebugMenuTriggerModifier: ViewModifier {
    let method: DebugTriggerMethod
    @State private var showDebugMenu = false
    @State private var tapCount = 0
    private let requiredTaps = 5
    private let tapResetDelay: TimeInterval = 2.0

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if method == .hiddenTap || method == .both {
                    hiddenTapArea
                }
            }
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView()
            }
            #if canImport(UIKit)
            .onReceive(NotificationCenter.default.publisher(for: .debugShakeDetected)) { _ in
                if method == .shakeGesture || method == .both {
                    showDebugMenu = true
                }
            }
            #endif
    }

    /// Invisible tap target in the top-right corner.
    private var hiddenTapArea: some View {
        Color.clear
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .onTapGesture {
                tapCount += 1
                if tapCount >= requiredTaps {
                    tapCount = 0
                    showDebugMenu = true
                }

                // Reset tap count after delay
                Task {
                    try? await Task.sleep(for: .seconds(tapResetDelay))
                    tapCount = 0
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - View Extension

extension View {
    /// Adds a debug menu trigger to this view.
    ///
    /// - Parameter method: How the debug menu is activated. Default is `.both`.
    /// - Returns: A view with the debug menu trigger attached.
    ///
    /// ```swift
    /// ContentView()
    ///     .debugMenuTrigger()
    /// ```
    func debugMenuTrigger(method: DebugTriggerMethod = .both) -> some View {
        modifier(DebugMenuTriggerModifier(method: method))
    }
}
#endif
```

## DebugActions.swift

```swift
#if DEBUG
import Foundation

/// Collection of debug utility actions.
///
/// Each action is a static function that can be called from the debug menu
/// or programmatically during development.
enum DebugActions {

    // MARK: - Onboarding

    /// Reset onboarding state so the user sees onboarding again on next launch.
    static func resetOnboarding() {
        let onboardingKeys = [
            "hasCompletedOnboarding",
            "onboardingCompleted",
            "isOnboarded",
            "didFinishOnboarding",
            "hasSeenWelcome",
        ]

        for key in onboardingKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        print("[DebugActions] Onboarding state reset")
    }

    // MARK: - UserDefaults

    /// Clear all UserDefaults for the app's bundle.
    static func clearUserDefaults() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleId)
        UserDefaults.standard.synchronize()
        print("[DebugActions] UserDefaults cleared for \(bundleId)")
    }

    // MARK: - Keychain

    /// Remove all keychain items for the app.
    static func clearKeychain() {
        let secClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]

        for secClass in secClasses {
            let query: [String: Any] = [kSecClass as String: secClass]
            SecItemDelete(query as CFDictionary)
        }

        print("[DebugActions] Keychain cleared")
    }

    // MARK: - Cache

    /// Clear the shared URL cache.
    static func clearHTTPCache() {
        URLCache.shared.removeAllCachedResponses()
        print("[DebugActions] HTTP cache cleared")
    }

    /// Clear the image cache (if using ImagePipeline from image-loading generator).
    ///
    /// Override this to integrate with your image caching layer:
    /// ```swift
    /// DebugActions.clearImageCache = {
    ///     await ImagePipeline.shared.clearCache()
    /// }
    /// ```
    static func clearImageCache() {
        // Clear the shared URLCache images
        URLCache.shared.removeAllCachedResponses()

        // Clear any on-disk image cache directory
        let cacheDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.removeItem(at: cacheDir)

        print("[DebugActions] Image cache cleared")
    }

    /// Clear all caches: URL, image, and temporary files.
    static func clearAllCaches() {
        clearHTTPCache()
        clearImageCache()

        // Clear tmp directory
        let tmpDir = FileManager.default.temporaryDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }

        print("[DebugActions] All caches cleared")
    }

    /// Human-readable URL cache size.
    static var urlCacheSizeDescription: String {
        let cache = URLCache.shared
        let usedMB = Double(cache.currentDiskUsage) / (1024 * 1024)
        let totalMB = Double(cache.diskCapacity) / (1024 * 1024)
        return String(format: "%.1f MB / %.0f MB", usedMB, totalMB)
    }

    // MARK: - Feature Flags

    /// Reset all feature flags to their default values.
    static func resetFeatureFlags(_ flags: [FeatureFlag]) {
        for flag in flags {
            flag.reset()
        }
        print("[DebugActions] All feature flags reset to defaults")
    }

    // MARK: - Crash

    /// Trigger a fatal error for testing crash reporting (e.g., Crashlytics).
    ///
    /// - Warning: This will terminate the app immediately.
    static func simulateCrash() {
        fatalError("[DebugActions] Intentional crash triggered from debug menu")
    }
}
#endif
```
