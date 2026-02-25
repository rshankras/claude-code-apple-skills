# Consent Flow Code Templates

Production-ready Swift templates for privacy consent management. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## ConsentCategory.swift

```swift
import Foundation

/// Categories of data processing that require user consent.
///
/// Each category represents a distinct purpose for data collection.
/// Essential is always required and cannot be disabled by the user.
enum ConsentCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case essential
    case analytics
    case marketing
    case personalization
    case functional

    var id: String { rawValue }

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .essential: return "Essential"
        case .analytics: return "Analytics"
        case .marketing: return "Marketing"
        case .personalization: return "Personalization"
        case .functional: return "Functional"
        }
    }

    /// Explanation shown to users describing what this category covers.
    var explanation: String {
        switch self {
        case .essential:
            return "Required for the app to function. Includes authentication, security, and core features."
        case .analytics:
            return "Helps us understand how you use the app so we can improve it. Includes usage statistics and crash reports."
        case .marketing:
            return "Used for advertising and attribution. Allows us to measure ad effectiveness and show relevant ads."
        case .personalization:
            return "Enables personalized content and recommendations based on your usage patterns."
        case .functional:
            return "Remembers your preferences and settings to enhance your experience beyond essential functionality."
        }
    }

    /// Whether this category is required and cannot be disabled.
    var isRequired: Bool {
        self == .essential
    }

    /// Categories that require user consent (excludes essential).
    static var consentable: [ConsentCategory] {
        allCases.filter { !$0.isRequired }
    }
}
```

## ConsentDecision.swift

```swift
import Foundation

/// The user's consent decision for a specific category.
enum ConsentStatus: String, Codable, Sendable {
    case granted
    case denied
    case notDetermined
}

/// A recorded consent decision with metadata.
struct ConsentDecision: Codable, Sendable, Equatable {
    let category: ConsentCategory
    let status: ConsentStatus
    let timestamp: Date
    let regulation: ConsentRegulation?

    init(
        category: ConsentCategory,
        status: ConsentStatus,
        timestamp: Date = Date(),
        regulation: ConsentRegulation? = nil
    ) {
        self.category = category
        self.status = status
        self.timestamp = timestamp
        self.regulation = regulation
    }
}

/// Supported privacy regulations.
enum ConsentRegulation: String, Codable, Sendable, CaseIterable {
    case gdpr    // EU General Data Protection Regulation
    case ccpa    // California Consumer Privacy Act
    case dpdp    // India Digital Personal Data Protection

    var displayName: String {
        switch self {
        case .gdpr: return "GDPR"
        case .ccpa: return "CCPA"
        case .dpdp: return "DPDP"
        }
    }

    /// Whether this regulation requires explicit opt-in consent.
    var requiresOptIn: Bool {
        switch self {
        case .gdpr: return true   // Must opt-in
        case .ccpa: return false  // Opt-out model
        case .dpdp: return true   // Must opt-in
        }
    }

    /// Minimum age for self-consent.
    var minimumConsentAge: Int {
        switch self {
        case .gdpr: return 16    // Member states can lower to 13
        case .ccpa: return 16    // 13 for sale-of-data specific consent
        case .dpdp: return 18
        }
    }
}
```

## ConsentManager.swift

```swift
import Foundation
import AppTrackingTransparency

/// Manages user privacy consent state across the app.
///
/// Persists consent decisions in UserDefaults and integrates
/// with App Tracking Transparency for iOS.
///
/// Usage:
/// ```swift
/// @State private var consentManager = ConsentManager()
///
/// if consentManager.hasConsent(for: .analytics) {
///     trackEvent(.screenView)
/// }
/// ```
@Observable
final class ConsentManager {
    // MARK: - State

    private(set) var decisions: [ConsentCategory: ConsentDecision] = [:]
    private(set) var attStatus: ATTrackingManager.AuthorizationStatus = .notDetermined

    // MARK: - Dependencies

    private let defaults: UserDefaults
    private let auditLog: ConsentAuditLog
    private let regulation: ConsentRegulation?

    private static let storageKey = "com.app.consentDecisions"

    // MARK: - Computed Properties

    /// Whether the app needs to show the consent banner.
    ///
    /// Returns true if any non-essential category has not been decided.
    var needsConsent: Bool {
        ConsentCategory.consentable.contains { category in
            decisions[category]?.status == .notDetermined || decisions[category] == nil
        }
    }

    /// Summary of current consent state for display.
    var consentSummary: String {
        let granted = ConsentCategory.consentable.filter { hasConsent(for: $0) }
        return "\(granted.count) of \(ConsentCategory.consentable.count) optional categories enabled"
    }

    // MARK: - Initialization

    init(
        defaults: UserDefaults = .standard,
        auditLog: ConsentAuditLog = .shared,
        regulation: ConsentRegulation? = nil
    ) {
        self.defaults = defaults
        self.auditLog = auditLog
        self.regulation = regulation
        loadPersistedDecisions()
        ensureEssentialGranted()

        #if os(iOS)
        attStatus = ATTrackingManager.trackingAuthorizationStatus
        #endif
    }

    // MARK: - Consent Operations

    /// Check if the user has granted consent for a specific category.
    func hasConsent(for category: ConsentCategory) -> Bool {
        if category.isRequired { return true }
        return decisions[category]?.status == .granted
    }

    /// Update consent for a specific category.
    func updateConsent(for category: ConsentCategory, granted: Bool) {
        guard !category.isRequired else { return } // Essential cannot be changed

        let decision = ConsentDecision(
            category: category,
            status: granted ? .granted : .denied,
            regulation: regulation
        )

        decisions[category] = decision
        persistDecisions()

        auditLog.record(decision: decision)

        NotificationCenter.default.post(
            name: .consentDidChange,
            object: nil,
            userInfo: ["category": category, "granted": granted]
        )
    }

    /// Grant consent for all categories.
    func grantAll() {
        for category in ConsentCategory.consentable {
            updateConsent(for: category, granted: true)
        }
    }

    /// Deny consent for all non-essential categories.
    func denyAllNonEssential() {
        for category in ConsentCategory.consentable {
            updateConsent(for: category, granted: false)
        }
    }

    /// Reset all consent decisions, requiring re-consent.
    func resetAllConsent() {
        for category in ConsentCategory.consentable {
            let decision = ConsentDecision(
                category: category,
                status: .notDetermined,
                regulation: regulation
            )
            decisions[category] = decision
            auditLog.record(decision: decision)
        }
        persistDecisions()

        NotificationCenter.default.post(name: .consentDidChange, object: nil)
    }

    /// Execute a closure only if consent is granted for the given category.
    func executeIfConsented(
        category: ConsentCategory,
        action: () -> Void
    ) {
        guard hasConsent(for: category) else { return }
        action()
    }

    // MARK: - ATT Integration

    /// Request App Tracking Transparency permission.
    ///
    /// Should be called after showing your own consent explanation,
    /// not during app launch. Returns the authorization status.
    @MainActor
    func requestATTPermission() async -> ATTrackingManager.AuthorizationStatus {
        #if os(iOS)
        let status = await ATTrackingManager.requestTrackingAuthorization()
        attStatus = status

        // Sync ATT result with marketing consent
        switch status {
        case .authorized:
            updateConsent(for: .marketing, granted: true)
        case .denied, .restricted:
            updateConsent(for: .marketing, granted: false)
        case .notDetermined:
            break
        @unknown default:
            break
        }

        return status
        #else
        return .notDetermined
        #endif
    }

    /// Whether ATT has been requested and resolved.
    var isATTDetermined: Bool {
        #if os(iOS)
        return attStatus != .notDetermined
        #else
        return true
        #endif
    }

    // MARK: - Persistence

    private func loadPersistedDecisions() {
        guard let data = defaults.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode(
                  [String: ConsentDecision].self, from: data
              ) else {
            initializeDefaultDecisions()
            return
        }

        decisions = Dictionary(
            uniqueKeysWithValues: decoded.compactMap { key, value in
                guard let category = ConsentCategory(rawValue: key) else { return nil }
                return (category, value)
            }
        )
    }

    private func persistDecisions() {
        let encoded = Dictionary(
            uniqueKeysWithValues: decisions.map { ($0.key.rawValue, $0.value) }
        )
        if let data = try? JSONEncoder().encode(encoded) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    private func initializeDefaultDecisions() {
        for category in ConsentCategory.allCases {
            decisions[category] = ConsentDecision(
                category: category,
                status: category.isRequired ? .granted : .notDetermined
            )
        }
    }

    private func ensureEssentialGranted() {
        decisions[.essential] = ConsentDecision(
            category: .essential,
            status: .granted
        )
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted when any consent decision changes.
    ///
    /// UserInfo contains "category" (ConsentCategory) and "granted" (Bool).
    static let consentDidChange = Notification.Name("consentDidChange")
}
```

## ConsentBannerView.swift

```swift
import SwiftUI

/// A bottom banner view requesting user consent for data processing.
///
/// Displays a brief explanation with three action buttons:
/// - Accept All: grants all consent categories
/// - Manage Preferences: opens detailed preferences view
/// - Reject Non-Essential: denies all optional categories
///
/// Usage:
/// ```swift
/// .overlay(alignment: .bottom) {
///     if consentManager.needsConsent {
///         ConsentBannerView()
///             .transition(.move(edge: .bottom).combined(with: .opacity))
///     }
/// }
/// ```
struct ConsentBannerView: View {
    @Environment(ConsentManager.self) private var consentManager
    @State private var showPreferences = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "hand.raised.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text("Your Privacy Matters")
                    .font(.headline)
                Spacer()
            }

            // Explanation
            Text("We use cookies and similar technologies to improve your experience. You can choose which categories of data processing to allow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Action Buttons
            VStack(spacing: 10) {
                Button {
                    consentManager.grantAll()
                } label: {
                    Text("Accept All")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                HStack(spacing: 10) {
                    Button {
                        showPreferences = true
                    } label: {
                        Text("Manage Preferences")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                    Button {
                        consentManager.denyAllNonEssential()
                    } label: {
                        Text("Reject Non-Essential")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            }

            // Privacy Policy Link
            Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                #if os(iOS)
                .fill(.ultraThinMaterial)
                #else
                .fill(Color(nsColor: .controlBackgroundColor))
                #endif
                .shadow(color: .black.opacity(0.15), radius: 10, y: -5)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .sheet(isPresented: $showPreferences) {
            ConsentPreferencesView()
        }
    }
}
```

## ConsentPreferencesView.swift

```swift
import SwiftUI

/// Detailed consent preferences view with per-category toggles.
///
/// Shows each consent category with its description and a toggle.
/// Essential category is always on with a disabled toggle.
/// Provides Save and Cancel actions.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showPreferences) {
///     ConsentPreferencesView()
///         .environment(consentManager)
/// }
/// ```
struct ConsentPreferencesView: View {
    @Environment(ConsentManager.self) private var consentManager
    @Environment(\.dismiss) private var dismiss

    @State private var pendingDecisions: [ConsentCategory: Bool] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    explanationHeader
                }

                Section("Consent Categories") {
                    ForEach(ConsentCategory.allCases) { category in
                        ConsentCategoryRow(
                            category: category,
                            isEnabled: binding(for: category)
                        )
                    }
                }

                Section {
                    quickActions
                }

                Section {
                    privacyLinks
                }
            }
            .navigationTitle("Privacy Preferences")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreferences()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentDecisions()
            }
        }
    }

    // MARK: - Subviews

    private var explanationHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose which types of data processing you consent to. Essential data processing cannot be disabled as it is required for the app to function.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var quickActions: some View {
        VStack(spacing: 8) {
            Button("Enable All") {
                for category in ConsentCategory.consentable {
                    pendingDecisions[category] = true
                }
            }

            Button("Disable All Non-Essential") {
                for category in ConsentCategory.consentable {
                    pendingDecisions[category] = false
                }
            }
            .foregroundStyle(.secondary)
        }
    }

    private var privacyLinks: some View {
        VStack(alignment: .leading, spacing: 8) {
            Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
            Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
        }
        .font(.footnote)
    }

    // MARK: - Logic

    private func binding(for category: ConsentCategory) -> Binding<Bool> {
        Binding(
            get: { pendingDecisions[category] ?? category.isRequired },
            set: { newValue in
                guard !category.isRequired else { return }
                pendingDecisions[category] = newValue
            }
        )
    }

    private func loadCurrentDecisions() {
        for category in ConsentCategory.allCases {
            pendingDecisions[category] = consentManager.hasConsent(for: category)
        }
    }

    private func savePreferences() {
        for (category, granted) in pendingDecisions {
            guard !category.isRequired else { continue }
            consentManager.updateConsent(for: category, granted: granted)
        }
    }
}

// MARK: - Category Row

/// A single row in the consent preferences list.
struct ConsentCategoryRow: View {
    let category: ConsentCategory
    @Binding var isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(category.displayName)
                            .font(.body.weight(.medium))
                        if category.isRequired {
                            Text("Required")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .disabled(category.isRequired)
            }

            Text(category.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}
```

## ConsentAuditLog.swift

```swift
import Foundation

/// Records all consent decisions for compliance auditing.
///
/// Persists entries as JSON in the app's documents directory.
/// Supports export for data subject access requests (DSAR).
///
/// Usage:
/// ```swift
/// let log = ConsentAuditLog.shared
/// log.record(decision: decision)
/// let jsonData = try log.exportJSON()
/// ```
final class ConsentAuditLog: Sendable {
    static let shared = ConsentAuditLog()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.app.consentAuditLog", qos: .utility)

    // MARK: - Audit Entry

    struct Entry: Codable, Sendable, Identifiable {
        let id: UUID
        let category: ConsentCategory
        let status: ConsentStatus
        let regulation: ConsentRegulation?
        let timestamp: Date
        let appVersion: String
        let osVersion: String

        init(
            category: ConsentCategory,
            status: ConsentStatus,
            regulation: ConsentRegulation?,
            timestamp: Date = Date()
        ) {
            self.id = UUID()
            self.category = category
            self.status = status
            self.regulation = regulation
            self.timestamp = timestamp
            self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            self.osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        }
    }

    // MARK: - Initialization

    init(directory: URL? = nil) {
        let dir = directory ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = dir.appendingPathComponent("consent_audit_log.json")
    }

    // MARK: - Recording

    /// Record a consent decision in the audit log.
    func record(decision: ConsentDecision) {
        let entry = Entry(
            category: decision.category,
            status: decision.status,
            regulation: decision.regulation
        )
        record(entry: entry)
    }

    /// Record a consent decision by components.
    func record(
        category: ConsentCategory,
        granted: Bool,
        regulation: ConsentRegulation? = nil
    ) {
        let entry = Entry(
            category: category,
            status: granted ? .granted : .denied,
            regulation: regulation
        )
        record(entry: entry)
    }

    private func record(entry: Entry) {
        queue.async { [fileURL] in
            var entries = Self.loadEntries(from: fileURL)
            entries.append(entry)
            Self.saveEntries(entries, to: fileURL)
        }
    }

    // MARK: - Querying

    /// All recorded audit entries, sorted by timestamp (newest first).
    func allEntries() -> [Entry] {
        Self.loadEntries(from: fileURL).sorted { $0.timestamp > $1.timestamp }
    }

    /// Entries filtered by category.
    func entries(for category: ConsentCategory) -> [Entry] {
        allEntries().filter { $0.category == category }
    }

    /// The most recent decision for each category.
    func currentDecisions() -> [ConsentCategory: Entry] {
        var result: [ConsentCategory: Entry] = [:]
        for entry in allEntries() {
            if result[entry.category] == nil {
                result[entry.category] = entry
            }
        }
        return result
    }

    // MARK: - Export

    /// Export the full audit log as JSON data.
    ///
    /// Use for data subject access requests (DSAR) or compliance reporting.
    func exportJSON() throws -> Data {
        let entries = allEntries()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(entries)
    }

    /// Export as a human-readable string for display.
    func exportReadable() -> String {
        let entries = allEntries()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        return entries.map { entry in
            let action = entry.status == .granted ? "Granted" : "Denied"
            let date = formatter.string(from: entry.timestamp)
            let reg = entry.regulation?.displayName ?? "—"
            return "[\(date)] \(action) \(entry.category.displayName) (Regulation: \(reg), App: \(entry.appVersion))"
        }.joined(separator: "\n")
    }

    // MARK: - Maintenance

    /// Remove entries older than the specified retention period.
    ///
    /// Default retention: 3 years (GDPR recommendation).
    func pruneOldEntries(olderThan retention: TimeInterval = 3 * 365 * 24 * 3600) {
        queue.async { [fileURL] in
            let cutoff = Date().addingTimeInterval(-retention)
            var entries = Self.loadEntries(from: fileURL)
            entries.removeAll { $0.timestamp < cutoff }
            Self.saveEntries(entries, to: fileURL)
        }
    }

    /// Delete the entire audit log.
    func deleteAll() {
        queue.async { [fileURL] in
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    // MARK: - File Operations

    private static func loadEntries(from fileURL: URL) -> [Entry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Entry].self, from: data)) ?? []
    }

    private static func saveEntries(_ entries: [Entry], to fileURL: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
```
