import Foundation
import SwiftUI
import CloudKit

/// Monitors iCloud sync status for UI feedback.
///
/// Usage:
/// ```swift
/// struct ContentView: View {
///     @Environment(SyncStatus.self) var syncStatus
///
///     var body: some View {
///         VStack {
///             if syncStatus.isSyncing {
///                 ProgressView("Syncing...")
///             }
///
///             if let error = syncStatus.error {
///                 Text("Sync error: \(error.localizedDescription)")
///             }
///         }
///     }
/// }
/// ```
@MainActor
@Observable
final class SyncStatus {

    // MARK: - Singleton

    static let shared = SyncStatus()

    // MARK: - State

    /// Whether a sync operation is in progress.
    private(set) var isSyncing = false

    /// The last time sync completed successfully.
    private(set) var lastSyncDate: Date?

    /// Current iCloud account status.
    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine

    /// Any error from the last sync attempt.
    private(set) var error: SyncError?

    /// Whether iCloud is available for this user.
    var isCloudAvailable: Bool {
        accountStatus == .available
    }

    /// Human-readable status description.
    var statusDescription: String {
        if let error {
            return error.localizedDescription
        }

        switch accountStatus {
        case .available:
            if isSyncing {
                return "Syncing..."
            } else if let lastSync = lastSyncDate {
                return "Last synced: \(lastSync.formatted(.relative(presentation: .named)))"
            } else {
                return "iCloud connected"
            }
        case .noAccount:
            return "Sign in to iCloud to sync"
        case .restricted:
            return "iCloud access restricted"
        case .couldNotDetermine:
            return "Checking iCloud status..."
        case .temporarilyUnavailable:
            return "iCloud temporarily unavailable"
        @unknown default:
            return "Unknown status"
        }
    }

    // MARK: - Initialization

    private init() {
        startMonitoring()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        // Check initial status
        Task {
            await checkAccountStatus()
        }

        // Monitor account changes
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAccountStatus()
            }
        }
    }

    /// Check the current iCloud account status.
    func checkAccountStatus() async {
        do {
            accountStatus = try await CKContainer.default().accountStatus()
            error = nil
        } catch {
            self.error = .accountCheckFailed(error)
        }
    }

    // MARK: - Sync Operations

    /// Mark sync as started.
    func syncStarted() {
        isSyncing = true
        error = nil
    }

    /// Mark sync as completed successfully.
    func syncCompleted() {
        isSyncing = false
        lastSyncDate = .now
        error = nil
    }

    /// Mark sync as failed.
    func syncFailed(_ error: Error) {
        isSyncing = false
        self.error = .syncFailed(error)
    }
}

// MARK: - Sync Error

/// Errors related to iCloud sync.
enum SyncError: Error, LocalizedError {
    case accountCheckFailed(Error)
    case syncFailed(Error)
    case networkUnavailable
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .accountCheckFailed(let error):
            return "Could not check iCloud status: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network unavailable. Changes will sync when connected."
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        }
    }
}

// MARK: - Environment Key

private struct SyncStatusKey: EnvironmentKey {
    @MainActor
    static let defaultValue = SyncStatus.shared
}

extension EnvironmentValues {
    var syncStatus: SyncStatus {
        get { self[SyncStatusKey.self] }
        set { self[SyncStatusKey.self] = newValue }
    }
}

// MARK: - SwiftUI View Extension

extension View {

    /// Add a sync status indicator to the view.
    func syncStatusIndicator() -> some View {
        modifier(SyncStatusIndicatorModifier())
    }
}

private struct SyncStatusIndicatorModifier: ViewModifier {
    @Environment(SyncStatus.self) private var syncStatus

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if syncStatus.isSyncing {
                    ProgressView()
                        .padding(8)
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Sync Status Demo")
            .font(.headline)

        Text(SyncStatus.shared.statusDescription)
            .foregroundStyle(.secondary)

        if SyncStatus.shared.isSyncing {
            ProgressView("Syncing...")
        }

        Button("Check Status") {
            Task {
                await SyncStatus.shared.checkAccountStatus()
            }
        }
    }
    .padding()
}
