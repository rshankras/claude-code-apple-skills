# Account Deletion Code Templates

Production-ready Swift templates for Apple-compliant account deletion. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## AccountDeletionManager.swift

```swift
import Foundation
import SwiftUI

/// Orchestrates the complete account deletion lifecycle.
///
/// Manages state transitions from initiation through confirmation,
/// optional data export, grace period scheduling, and final execution.
///
/// Usage:
/// ```swift
/// @State private var deletionManager = AccountDeletionManager()
///
/// Button("Delete Account") {
///     Task { await deletionManager.initiateDeletion() }
/// }
/// ```
@Observable
final class AccountDeletionManager {
    private(set) var deletionState: DeletionState = .none
    private(set) var scheduledDeletionDate: Date?
    private(set) var isProcessing = false

    private let serverClient: AccountDeletionClient?
    private let keychainCleanup: KeychainCleanup
    private let gracePeriodKey = "AccountDeletion.scheduledDate"

    enum DeletionState: Sendable, Equatable {
        case none
        case confirming
        case exporting
        case scheduled(Date)
        case deleting
        case completed
        case failed(String)

        static func == (lhs: DeletionState, rhs: DeletionState) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none), (.confirming, .confirming),
                 (.exporting, .exporting), (.deleting, .deleting),
                 (.completed, .completed):
                return true
            case (.scheduled(let a), .scheduled(let b)):
                return a == b
            case (.failed(let a), .failed(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    init(
        serverClient: AccountDeletionClient? = nil,
        keychainCleanup: KeychainCleanup = KeychainCleanup()
    ) {
        self.serverClient = serverClient
        self.keychainCleanup = keychainCleanup

        // Restore any pending scheduled deletion
        if let scheduledDate = UserDefaults.standard.object(forKey: gracePeriodKey) as? Date {
            self.scheduledDeletionDate = scheduledDate
            self.deletionState = .scheduled(scheduledDate)
        }
    }

    /// Begin the deletion flow — transitions to confirming state.
    func initiateDeletion() async {
        deletionState = .confirming
    }

    /// Re-authenticate the user before proceeding with deletion.
    ///
    /// Uses LocalAuthentication for biometric or falls back to password.
    func confirmWithReauthentication() async throws {
        isProcessing = true
        defer { isProcessing = false }

        // Biometric authentication
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw AccountDeletionError.authenticationUnavailable
        }

        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Confirm your identity to delete your account"
        )

        guard success else {
            throw AccountDeletionError.authenticationFailed
        }
    }

    /// Export all user data before deletion.
    func exportUserData() async throws -> URL {
        deletionState = .exporting
        let exportService = DataExportService()
        return try await exportService.exportAllUserData()
    }

    /// Schedule deletion after a grace period instead of immediate execution.
    func scheduleDeletion(gracePeriodDays: Int) async throws {
        isProcessing = true
        defer { isProcessing = false }

        let deletionDate = Calendar.current.date(
            byAdding: .day,
            value: gracePeriodDays,
            to: Date()
        )!

        // Notify server of scheduled deletion
        if let serverClient {
            try await serverClient.scheduleDeletion(date: deletionDate)
        }

        // Persist locally
        UserDefaults.standard.set(deletionDate, forKey: gracePeriodKey)
        scheduledDeletionDate = deletionDate
        deletionState = .scheduled(deletionDate)
    }

    /// Cancel a previously scheduled deletion.
    func cancelScheduledDeletion() async throws {
        isProcessing = true
        defer { isProcessing = false }

        // Notify server of cancellation
        if let serverClient {
            try await serverClient.cancelScheduledDeletion()
        }

        // Clear local state
        UserDefaults.standard.removeObject(forKey: gracePeriodKey)
        scheduledDeletionDate = nil
        deletionState = .none
    }

    /// Execute the account deletion — cleans up all local and remote data.
    ///
    /// This is the final, irreversible step. Call only after confirmation.
    func executeDeletion() async throws {
        isProcessing = true
        deletionState = .deleting

        do {
            // 1. Server-side deletion (if configured)
            if let serverClient {
                try await serverClient.deleteAccount()
            }

            // 2. Revoke Sign in with Apple token (if applicable)
            await revokeSignInWithAppleTokenIfNeeded()

            // 3. Keychain cleanup
            try keychainCleanup.removeAllItems()

            // 4. UserDefaults cleanup
            cleanUserDefaults()

            // 5. File system cleanup
            cleanFileSystem()

            // 6. Clear scheduled deletion
            UserDefaults.standard.removeObject(forKey: gracePeriodKey)
            scheduledDeletionDate = nil

            deletionState = .completed
            isProcessing = false
        } catch {
            deletionState = .failed(error.localizedDescription)
            isProcessing = false
            throw error
        }
    }

    /// Check for pending scheduled deletions on app launch.
    ///
    /// Call this from your App's `.task` modifier.
    func checkPendingDeletion() async {
        guard let scheduledDate = scheduledDeletionDate else { return }

        if Date() >= scheduledDate {
            // Grace period expired — execute deletion
            try? await executeDeletion()
        }
    }

    // MARK: - Private Cleanup Methods

    private func revokeSignInWithAppleTokenIfNeeded() async {
        // Check if user signed in with Apple
        guard let refreshToken = retrieveAppleRefreshToken() else { return }
        let revocation = SignInWithAppleRevocation()
        try? await revocation.revokeToken(
            refreshToken: refreshToken,
            clientID: Bundle.main.bundleIdentifier ?? "",
            clientSecret: "" // Generate via server
        )
    }

    private func retrieveAppleRefreshToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "apple_refresh_token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func cleanUserDefaults() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()

        // Also clean any app group defaults
        // UserDefaults(suiteName: "group.com.yourapp")?.removePersistentDomain(forName: "group.com.yourapp")
    }

    private func cleanFileSystem() {
        let fileManager = FileManager.default

        // Documents directory
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                .forEach { try? fileManager.removeItem(at: $0) }
        }

        // Caches directory
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            try? fileManager.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil)
                .forEach { try? fileManager.removeItem(at: $0) }
        }

        // Application Support directory
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? fileManager.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: nil)
                .forEach { try? fileManager.removeItem(at: $0) }
        }
    }
}

// MARK: - Supporting Types

/// Protocol for server-side account deletion requests.
protocol AccountDeletionClient: Sendable {
    func deleteAccount() async throws
    func scheduleDeletion(date: Date) async throws
    func cancelScheduledDeletion() async throws
}

/// Errors specific to account deletion.
enum AccountDeletionError: Error, LocalizedError {
    case authenticationUnavailable
    case authenticationFailed
    case serverDeletionFailed(String)
    case keychainCleanupFailed
    case alreadyScheduled

    var errorDescription: String? {
        switch self {
        case .authenticationUnavailable:
            return "Authentication is not available on this device."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .serverDeletionFailed(let reason):
            return "Server deletion failed: \(reason)"
        case .keychainCleanupFailed:
            return "Failed to clean up stored credentials."
        case .alreadyScheduled:
            return "Account deletion is already scheduled."
        }
    }
}

// Required import for LocalAuthentication
import LocalAuthentication
import Security
```

## DeletionConfirmationView.swift

```swift
import SwiftUI

/// Multi-step account deletion confirmation flow.
///
/// Steps: Explain Consequences -> Optional Data Export -> Re-authenticate -> Confirm
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showDeletion) {
///     DeletionConfirmationView()
/// }
/// ```
struct DeletionConfirmationView: View {
    @Environment(AccountDeletionManager.self) private var deletionManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: DeletionStep = .consequences
    @State private var confirmationText = ""
    @State private var includeDataExport = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?
    @State private var showError = false

    enum DeletionStep: Int, CaseIterable {
        case consequences
        case dataExport
        case reauthenticate
        case finalConfirm
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                ProgressIndicatorView(
                    currentStep: currentStep.rawValue,
                    totalSteps: DeletionStep.allCases.count
                )
                .padding(.top)

                // Step content
                switch currentStep {
                case .consequences:
                    ConsequencesStepView(
                        includeDataExport: $includeDataExport,
                        onContinue: { advanceStep() }
                    )
                case .dataExport:
                    DataExportStepView(
                        exportURL: $exportURL,
                        onExport: { await exportData() },
                        onSkip: { advanceStep() }
                    )
                case .reauthenticate:
                    ReauthenticateStepView(
                        onAuthenticate: { await reauthenticate() }
                    )
                case .finalConfirm:
                    FinalConfirmStepView(
                        confirmationText: $confirmationText,
                        isProcessing: deletionManager.isProcessing,
                        onDelete: { await performDeletion() }
                    )
                }
            }
            .navigationTitle("Delete Account")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(deletionManager.isProcessing)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unexpected error occurred.")
            }
        }
    }

    // MARK: - Step Navigation

    private func advanceStep() {
        withAnimation {
            switch currentStep {
            case .consequences:
                currentStep = includeDataExport ? .dataExport : .reauthenticate
            case .dataExport:
                currentStep = .reauthenticate
            case .reauthenticate:
                currentStep = .finalConfirm
            case .finalConfirm:
                break
            }
        }
    }

    // MARK: - Actions

    private func exportData() async {
        do {
            exportURL = try await deletionManager.exportUserData()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func reauthenticate() async {
        do {
            try await deletionManager.confirmWithReauthentication()
            advanceStep()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func performDeletion() async {
        do {
            try await deletionManager.executeDeletion()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Step Views

private struct ConsequencesStepView: View {
    @Binding var includeDataExport: Bool
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)

                Text("What happens when you delete your account")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    ConsequenceRow(
                        icon: "person.slash",
                        text: "Your account and profile will be permanently removed"
                    )
                    ConsequenceRow(
                        icon: "doc.text.fill",
                        text: "All your data, content, and history will be deleted"
                    )
                    ConsequenceRow(
                        icon: "key.fill",
                        text: "All saved credentials and tokens will be erased"
                    )
                    ConsequenceRow(
                        icon: "arrow.counterclockwise",
                        text: "This action cannot be undone"
                    )
                }

                Divider()

                // Subscription warning
                VStack(alignment: .leading, spacing: 8) {
                    Label("Active Subscriptions", systemImage: "creditcard.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)

                    Text("Deleting your account does not cancel active subscriptions. Please cancel any subscriptions in Settings > Subscriptions before proceeding.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Toggle("Export my data before deletion", isOn: $includeDataExport)
                    .padding(.top, 8)

                Button(action: onContinue) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
            }
            .padding()
        }
    }
}

private struct ConsequenceRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.red)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

private struct DataExportStepView: View {
    @Binding var exportURL: URL?
    let onExport: () async -> Void
    let onSkip: () -> Void

    @State private var isExporting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "square.and.arrow.down.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Export Your Data")
                .font(.title2.weight(.semibold))

            Text("Download a copy of all your data before deleting your account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Share Export File", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)

                Button("Continue to Deletion") {
                    onSkip()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                Button {
                    isExporting = true
                    Task {
                        await onExport()
                        isExporting = false
                    }
                } label: {
                    if isExporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Export My Data", systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isExporting)
                .padding(.horizontal)

                Button("Skip Export") {
                    onSkip()
                }
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct ReauthenticateStepView: View {
    let onAuthenticate: () async -> Void

    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "faceid")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Verify Your Identity")
                .font(.title2.weight(.semibold))

            Text("For your security, please verify your identity before deleting your account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                isAuthenticating = true
                Task {
                    await onAuthenticate()
                    isAuthenticating = false
                }
            } label: {
                if isAuthenticating {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Verify Identity", systemImage: "lock.shield.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isAuthenticating)
            .padding(.horizontal)

            Spacer()
        }
    }
}

private struct FinalConfirmStepView: View {
    @Binding var confirmationText: String
    let isProcessing: Bool
    let onDelete: () async -> Void

    private let requiredText = "DELETE"

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Final Confirmation")
                .font(.title2.weight(.semibold))

            Text("Type **DELETE** to confirm account deletion.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Type DELETE", text: $confirmationText)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.characters)
                #endif
                .padding(.horizontal, 40)

            Button {
                Task { await onDelete() }
            } label: {
                if isProcessing {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Delete My Account Permanently")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            .disabled(confirmationText != requiredText || isProcessing)
            .padding(.horizontal)

            Spacer()
        }
    }
}

// MARK: - Progress Indicator

private struct ProgressIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.red : Color.secondary.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
    }
}
```

## DataExportService.swift

```swift
import Foundation
import SwiftUI

/// Collects all user data and packages it into a JSON archive for download.
///
/// Gathers data from SwiftData/CoreData, UserDefaults, and the file system,
/// then produces a JSON file that can be shared via ShareLink.
///
/// Usage:
/// ```swift
/// let exportService = DataExportService()
/// let archiveURL = try await exportService.exportAllUserData()
/// // Present ShareLink with archiveURL
/// ```
@Observable
final class DataExportService {
    private(set) var isExporting = false
    private(set) var exportProgress: Double = 0

    /// Export all user data to a JSON file in the temporary directory.
    ///
    /// - Returns: URL to the exported JSON file.
    func exportAllUserData() async throws -> URL {
        isExporting = true
        exportProgress = 0
        defer { isExporting = false }

        var exportData: [String: Any] = [:]

        // 1. Export UserDefaults
        exportProgress = 0.2
        exportData["userDefaults"] = exportUserDefaults()

        // 2. Export documents directory file list
        exportProgress = 0.4
        exportData["documents"] = exportDocumentsManifest()

        // 3. Export app-specific data
        // TODO: Add your SwiftData/CoreData model exports here
        // Example:
        // exportData["posts"] = try await exportPosts()
        // exportData["comments"] = try await exportComments()
        exportProgress = 0.7

        // 4. Export metadata
        exportData["exportMetadata"] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "bundleIdentifier": Bundle.main.bundleIdentifier ?? "unknown"
        ]

        exportProgress = 0.9

        // 5. Serialize and write to temp file
        let jsonData = try JSONSerialization.data(
            withJSONObject: exportData,
            options: [.prettyPrinted, .sortedKeys]
        )

        let fileName = "account-data-export-\(formattedDate()).json"
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        try jsonData.write(to: exportURL)

        exportProgress = 1.0
        return exportURL
    }

    // MARK: - Private

    private func exportUserDefaults() -> [String: Any] {
        guard let bundleID = Bundle.main.bundleIdentifier else { return [:] }
        return UserDefaults.standard.persistentDomain(forName: bundleID) ?? [:]
    }

    private func exportDocumentsManifest() -> [[String: String]] {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else { return [] }

        let files = (try? fileManager.contentsOfDirectory(
            at: documentsURL,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: .skipsHiddenFiles
        )) ?? []

        return files.map { url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            let created = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate

            return [
                "name": url.lastPathComponent,
                "size": "\(size) bytes",
                "created": created.map { ISO8601DateFormatter().string(from: $0) } ?? "unknown"
            ]
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
```

## DeletionGracePeriodView.swift

```swift
import SwiftUI

/// Displays the grace period countdown and option to cancel scheduled deletion.
///
/// Show this view when the user has a pending account deletion.
///
/// Usage:
/// ```swift
/// if case .scheduled(let date) = deletionManager.deletionState {
///     DeletionGracePeriodView(scheduledDate: date)
/// }
/// ```
struct DeletionGracePeriodView: View {
    @Environment(AccountDeletionManager.self) private var deletionManager

    let scheduledDate: Date

    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 24) {
            // Warning icon
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.multicolor)

            // Countdown
            Text("Account Deletion Scheduled")
                .font(.title2.weight(.semibold))

            Text("Your account will be permanently deleted on:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(scheduledDate, style: .date)
                .font(.title3.weight(.medium))
                .foregroundStyle(.red)

            // Time remaining
            TimeRemainingView(targetDate: scheduledDate)

            Divider()
                .padding(.horizontal)

            // What happens
            VStack(alignment: .leading, spacing: 12) {
                Text("When the period expires:")
                    .font(.subheadline.weight(.semibold))

                Label("All account data will be permanently deleted", systemImage: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("All stored credentials will be removed", systemImage: "key.slash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("This action cannot be reversed", systemImage: "arrow.counterclockwise")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            Spacer()

            // Cancel button
            Button {
                Task {
                    do {
                        try await deletionManager.cancelScheduledDeletion()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            } label: {
                Text("Cancel Account Deletion")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(deletionManager.isProcessing)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Failed to cancel deletion.")
        }
    }
}

/// Displays a live countdown to the target date.
private struct TimeRemainingView: View {
    let targetDate: Date

    @State private var timeRemaining: String = ""

    var body: some View {
        Text(timeRemaining)
            .font(.headline)
            .foregroundStyle(.orange)
            .monospacedDigit()
            .onAppear { updateTimeRemaining() }
            .task {
                // Update every minute
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60))
                    updateTimeRemaining()
                }
            }
    }

    private func updateTimeRemaining() {
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: Date(),
            to: targetDate
        )

        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if days > 0 {
            timeRemaining = "\(days) day\(days == 1 ? "" : "s"), \(hours) hour\(hours == 1 ? "" : "s") remaining"
        } else if hours > 0 {
            timeRemaining = "\(hours) hour\(hours == 1 ? "" : "s"), \(minutes) minute\(minutes == 1 ? "" : "s") remaining"
        } else {
            timeRemaining = "\(max(0, minutes)) minute\(minutes == 1 ? "" : "s") remaining"
        }
    }
}
```

## KeychainCleanup.swift

```swift
import Foundation
import Security

/// Utility to remove all app Keychain items during account deletion.
///
/// Handles SecItemDelete for all item classes:
/// - Generic passwords (kSecClassGenericPassword)
/// - Internet passwords (kSecClassInternetPassword)
/// - Certificates (kSecClassCertificate)
/// - Keys (kSecClassKey)
/// - Identities (kSecClassIdentity)
///
/// Usage:
/// ```swift
/// let cleanup = KeychainCleanup()
/// try cleanup.removeAllItems()
/// ```
struct KeychainCleanup: Sendable {

    /// All Keychain item classes that need to be cleaned.
    private static let itemClasses: [CFString] = [
        kSecClassGenericPassword,
        kSecClassInternetPassword,
        kSecClassCertificate,
        kSecClassKey,
        kSecClassIdentity
    ]

    /// Remove all Keychain items stored by this app.
    ///
    /// Iterates through all item classes and deletes matching entries.
    /// - Throws: `AccountDeletionError.keychainCleanupFailed` if any deletion fails
    ///   with an error other than `errSecItemNotFound`.
    func removeAllItems() throws {
        var errors: [OSStatus] = []

        for itemClass in Self.itemClasses {
            let query: [String: Any] = [
                kSecClass as String: itemClass
            ]

            let status = SecItemDelete(query as CFDictionary)

            // errSecItemNotFound is fine — means nothing to delete
            if status != errSecSuccess && status != errSecItemNotFound {
                errors.append(status)
            }
        }

        if !errors.isEmpty {
            throw AccountDeletionError.keychainCleanupFailed
        }
    }

    /// Remove a specific Keychain item by account name.
    ///
    /// - Parameters:
    ///   - account: The account identifier (kSecAttrAccount value).
    ///   - itemClass: The Keychain item class. Defaults to generic password.
    func removeItem(account: String, itemClass: CFString = kSecClassGenericPassword) throws {
        let query: [String: Any] = [
            kSecClass as String: itemClass,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            throw AccountDeletionError.keychainCleanupFailed
        }
    }
}
```

## SignInWithAppleRevocation.swift

```swift
import Foundation
import AuthenticationServices

/// Revokes a Sign in with Apple refresh token via Apple's REST API.
///
/// Required for compliance when deleting accounts that used Sign in with Apple.
/// Apple mandates that apps revoke tokens when a user deletes their account.
///
/// Reference: https://developer.apple.com/documentation/sign_in_with_apple/revoke_tokens
///
/// Usage:
/// ```swift
/// let revocation = SignInWithAppleRevocation()
/// try await revocation.revokeToken(
///     refreshToken: storedRefreshToken,
///     clientID: Bundle.main.bundleIdentifier!,
///     clientSecret: generatedClientSecret
/// )
/// ```
struct SignInWithAppleRevocation: Sendable {

    private let revokeURL = URL(string: "https://appleid.apple.com/auth/revoke")!

    /// Revoke a Sign in with Apple token.
    ///
    /// - Parameters:
    ///   - refreshToken: The refresh token obtained during Sign in with Apple.
    ///   - clientID: Your app's bundle identifier (client_id).
    ///   - clientSecret: A JWT client secret generated server-side.
    ///
    /// - Note: The client secret must be a JWT signed with your Sign in with Apple
    ///   private key. Generate this on your server, not in the client app.
    func revokeToken(
        refreshToken: String,
        clientID: String,
        clientSecret: String
    ) async throws {
        var request = URLRequest(url: revokeURL)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        let parameters = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "token": refreshToken,
            "token_type_hint": "refresh_token"
        ]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SignInWithAppleRevocationError.invalidResponse
        }

        // 200 = success, 400 = invalid token (already revoked, which is fine)
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 400 else {
            throw SignInWithAppleRevocationError.revocationFailed(
                statusCode: httpResponse.statusCode
            )
        }
    }

    /// Check if the current user's Apple ID credential is still valid.
    ///
    /// Call this to determine if Sign in with Apple revocation is needed.
    func checkCredentialState(userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }
}

/// Errors specific to Sign in with Apple token revocation.
enum SignInWithAppleRevocationError: Error, LocalizedError {
    case invalidResponse
    case revocationFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Apple's revocation endpoint."
        case .revocationFailed(let statusCode):
            return "Token revocation failed with status code \(statusCode)."
        }
    }
}
```
