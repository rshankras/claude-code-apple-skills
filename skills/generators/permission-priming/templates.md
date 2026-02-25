# Permission Priming Code Templates

Production-ready Swift templates for pre-permission priming screens. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## PermissionType.swift

```swift
import Foundation

/// All permission types the app may request, with associated metadata.
///
/// Each case carries display information for the priming screen
/// and the corresponding Info.plist usage description key.
enum PermissionType: CaseIterable, Identifiable, Sendable {
    case notifications
    case camera
    case photoLibrary
    case location(LocationAccuracy)
    case microphone
    case contacts
    case health
    case tracking

    enum LocationAccuracy: Sendable {
        case whenInUse
        case always
    }

    var id: String { infoPlistKey ?? title }

    // MARK: - Display Metadata

    /// Title shown on the priming screen.
    var title: String {
        switch self {
        case .notifications:   return "Enable Notifications"
        case .camera:          return "Allow Camera Access"
        case .photoLibrary:    return "Access Your Photos"
        case .location(.whenInUse): return "Share Your Location"
        case .location(.always):    return "Enable Background Location"
        case .microphone:      return "Allow Microphone Access"
        case .contacts:        return "Access Your Contacts"
        case .health:          return "Connect Health Data"
        case .tracking:        return "Allow Tracking"
        }
    }

    /// SF Symbol name for the priming illustration.
    var systemImage: String {
        switch self {
        case .notifications:   return "bell.badge.fill"
        case .camera:          return "camera.fill"
        case .photoLibrary:    return "photo.on.rectangle.angled"
        case .location:        return "location.fill"
        case .microphone:      return "mic.fill"
        case .contacts:        return "person.crop.circle.fill"
        case .health:          return "heart.fill"
        case .tracking:        return "hand.raised.fill"
        }
    }

    /// Benefit description explaining WHY the app needs this permission.
    /// Customize these strings per app for maximum grant rates.
    var benefitDescription: String {
        switch self {
        case .notifications:
            return "Get notified about important updates, reminders, and activity so you never miss what matters."
        case .camera:
            return "Take photos and scan documents directly within the app for a seamless experience."
        case .photoLibrary:
            return "Choose photos from your library to share, edit, or use as profile pictures."
        case .location(.whenInUse):
            return "Find nearby places, get directions, and see relevant content based on where you are."
        case .location(.always):
            return "Receive location-based alerts and updates even when the app is in the background."
        case .microphone:
            return "Record audio for voice messages, video calls, and voice commands."
        case .contacts:
            return "Find friends who are already using the app and easily share content with them."
        case .health:
            return "Sync your health and fitness data to provide personalized insights and track your progress."
        case .tracking:
            return "Allow us to deliver personalized ads and measure campaign effectiveness."
        }
    }

    /// The corresponding Info.plist usage description key.
    /// Returns nil for types that don't require an Info.plist entry (e.g., notifications).
    var infoPlistKey: String? {
        switch self {
        case .notifications:        return nil  // No Info.plist key required
        case .camera:               return "NSCameraUsageDescription"
        case .photoLibrary:         return "NSPhotoLibraryUsageDescription"
        case .location(.whenInUse): return "NSLocationWhenInUseUsageDescription"
        case .location(.always):    return "NSLocationAlwaysAndWhenInUseUsageDescription"
        case .microphone:           return "NSMicrophoneUsageDescription"
        case .contacts:             return "NSContactsUsageDescription"
        case .health:               return "NSHealthShareUsageDescription"
        case .tracking:             return "NSUserTrackingUsageDescription"
        }
    }

    // MARK: - CaseIterable Conformance

    /// All cases for iteration. Defaults to `.whenInUse` for location.
    static var allCases: [PermissionType] {
        [.notifications, .camera, .photoLibrary, .location(.whenInUse),
         .location(.always), .microphone, .contacts, .health, .tracking]
    }
}
```

## PermissionStatus.swift

```swift
import Foundation

/// Unified permission status that wraps platform-specific authorization statuses.
///
/// Normalizes the different status enums from AVFoundation, CoreLocation,
/// UserNotifications, Photos, etc. into a single type.
enum PermissionStatus: Sendable, Equatable {
    /// User has not yet been asked. Priming screen should be shown.
    case notDetermined

    /// User granted access.
    case authorized

    /// User explicitly denied access. Must direct to Settings.
    case denied

    /// Access restricted by parental controls or device management.
    case restricted

    /// Notifications only: provisional (quiet) delivery authorized.
    case provisional

    /// Whether the permission has been granted (fully or provisionally).
    var isGranted: Bool {
        self == .authorized || self == .provisional
    }

    /// Whether the priming screen should be shown.
    var shouldShowPriming: Bool {
        self == .notDetermined
    }

    /// Whether the user must be directed to Settings to change the permission.
    var requiresSettings: Bool {
        self == .denied || self == .restricted
    }
}
```

## PermissionManager.swift

```swift
import Foundation
import AVFoundation
import UserNotifications
import CoreLocation
import Photos
import Contacts

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

#if canImport(HealthKit)
import HealthKit
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Manages checking and requesting all app permissions through a unified interface.
///
/// Usage:
/// ```swift
/// @State private var permissionManager = PermissionManager()
///
/// let status = await permissionManager.status(for: .camera)
/// if status == .notDetermined {
///     let granted = await permissionManager.request(.camera)
/// }
/// ```
@Observable
final class PermissionManager {
    private let locationDelegate = LocationPermissionDelegate()

    // MARK: - Check Status

    /// Returns the current authorization status for a permission type.
    @MainActor
    func status(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .notifications:
            return await notificationStatus()
        case .camera:
            return cameraStatus()
        case .photoLibrary:
            return photoLibraryStatus()
        case .location(let accuracy):
            return locationStatus(accuracy: accuracy)
        case .microphone:
            return microphoneStatus()
        case .contacts:
            return contactsStatus()
        case .health:
            return .notDetermined  // HealthKit status is per-type; check specific data types
        case .tracking:
            return trackingStatus()
        }
    }

    // MARK: - Request Permission

    /// Requests a permission and returns whether it was granted.
    @MainActor
    @discardableResult
    func request(_ type: PermissionType) async -> Bool {
        switch type {
        case .notifications:
            return await requestNotifications()
        case .camera:
            return await requestCamera()
        case .photoLibrary:
            return await requestPhotoLibrary()
        case .location(let accuracy):
            return await requestLocation(accuracy: accuracy)
        case .microphone:
            return await requestMicrophone()
        case .contacts:
            return await requestContacts()
        case .health:
            return await requestHealth()
        case .tracking:
            return await requestTracking()
        }
    }

    // MARK: - Open Settings

    /// Opens the app's Settings page so the user can change a denied permission.
    func openSettings() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") else { return }
        NSWorkspace.shared.open(url)
        #endif
    }

    /// Returns the Settings URL for testing or custom UI.
    var settingsURL: URL? {
        #if canImport(UIKit)
        return URL(string: UIApplication.openSettingsURLString)
        #else
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")
        #endif
    }

    // MARK: - Notifications

    private func notificationStatus() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .provisional:   return .provisional
        case .ephemeral:     return .authorized
        @unknown default:    return .notDetermined
        }
    }

    private func requestNotifications() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Camera

    private func cameraStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: return .notDetermined
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .restricted:    return .restricted
        @unknown default:    return .notDetermined
        }
    }

    private func requestCamera() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    // MARK: - Photo Library

    private func photoLibraryStatus() -> PermissionStatus {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .notDetermined: return .notDetermined
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .restricted:    return .restricted
        case .limited:       return .authorized  // Treat limited as authorized
        @unknown default:    return .notDetermined
        }
    }

    private func requestPhotoLibrary() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

    // MARK: - Location

    private func locationStatus(accuracy: PermissionType.LocationAccuracy) -> PermissionStatus {
        switch locationDelegate.manager.authorizationStatus {
        case .notDetermined:         return .notDetermined
        case .authorizedWhenInUse:
            return accuracy == .always ? .notDetermined : .authorized
        case .authorizedAlways:      return .authorized
        case .denied:                return .denied
        case .restricted:            return .restricted
        @unknown default:            return .notDetermined
        }
    }

    private func requestLocation(accuracy: PermissionType.LocationAccuracy) async -> Bool {
        await withCheckedContinuation { continuation in
            locationDelegate.onAuthorizationChange = { status in
                switch status {
                case .authorizedWhenInUse:
                    continuation.resume(returning: accuracy == .whenInUse)
                case .authorizedAlways:
                    continuation.resume(returning: true)
                case .denied, .restricted:
                    continuation.resume(returning: false)
                default:
                    break  // Wait for a definitive status
                }
            }

            switch accuracy {
            case .whenInUse:
                locationDelegate.manager.requestWhenInUseAuthorization()
            case .always:
                locationDelegate.manager.requestAlwaysAuthorization()
            }
        }
    }

    // MARK: - Microphone

    private func microphoneStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined: return .notDetermined
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .restricted:    return .restricted
        @unknown default:    return .notDetermined
        }
    }

    private func requestMicrophone() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    // MARK: - Contacts

    private func contactsStatus() -> PermissionStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined: return .notDetermined
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .restricted:    return .restricted
        @unknown default:    return .notDetermined
        }
    }

    private func requestContacts() async -> Bool {
        do {
            return try await CNContactStore().requestAccess(for: .contacts)
        } catch {
            return false
        }
    }

    // MARK: - Health

    private func requestHealth() async -> Bool {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let store = HKHealthStore()
        // Customize these types per your app's needs
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    // MARK: - App Tracking Transparency

    private func trackingStatus() -> PermissionStatus {
        #if canImport(AppTrackingTransparency)
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorized:    return .authorized
        case .denied:        return .denied
        case .restricted:    return .restricted
        @unknown default:    return .notDetermined
        }
        #else
        return .notDetermined
        #endif
    }

    private func requestTracking() async -> Bool {
        #if canImport(AppTrackingTransparency)
        let status = await ATTrackingManager.requestTrackingAuthorization()
        return status == .authorized
        #else
        return false
        #endif
    }
}

// MARK: - Location Delegate

/// Internal delegate for handling CLLocationManager authorization callbacks.
private final class LocationPermissionDelegate: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChange?(manager.authorizationStatus)
    }
}
```

## PermissionPrimingView.swift

```swift
import SwiftUI

/// Pre-permission priming screen shown before the iOS system permission dialog.
///
/// Explains WHY the app needs the permission with an illustration,
/// benefit description, and clear call-to-action. Dramatically increases
/// grant rates compared to showing the system prompt cold.
///
/// Usage:
/// ```swift
/// PermissionPrimingView(permissionType: .notifications) {
///     // User granted permission
/// } onDenied: {
///     // User tapped "Not Now" or system denied
/// }
/// ```
struct PermissionPrimingView: View {
    let permissionType: PermissionType
    let onGranted: () -> Void
    let onDenied: () -> Void

    /// Optional overrides for custom copy.
    var customTitle: String?
    var customDescription: String?
    var customImage: String?

    @Environment(\.dismiss) private var dismiss
    @State private var permissionManager = PermissionManager()
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            illustrationSection

            titleSection
                .padding(.top, 24)

            descriptionSection
                .padding(.top, 12)

            Spacer()

            buttonSection
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if canImport(UIKit)
        .background(Color(uiColor: .systemBackground))
        #endif
    }

    // MARK: - Sections

    private var illustrationSection: some View {
        Image(systemName: customImage ?? permissionType.systemImage)
            .font(.system(size: 64))
            .foregroundStyle(.tint)
            .frame(width: 120, height: 120)
            .background(
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 120, height: 120)
            )
    }

    private var titleSection: some View {
        Text(customTitle ?? permissionType.title)
            .font(.title2)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
    }

    private var descriptionSection: some View {
        Text(customDescription ?? permissionType.benefitDescription)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var buttonSection: some View {
        VStack(spacing: 12) {
            // Primary CTA
            Button {
                Task {
                    isRequesting = true
                    let granted = await permissionManager.request(permissionType)
                    isRequesting = false
                    if granted {
                        onGranted()
                    } else {
                        onDenied()
                    }
                    dismiss()
                }
            } label: {
                if isRequesting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 22)
                } else {
                    Text("Enable")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRequesting)

            // Secondary "Not Now"
            Button {
                onDenied()
                dismiss()
            } label: {
                Text("Not Now")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .controlSize(.large)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Convenience Initializer with Custom Copy

extension PermissionPrimingView {
    /// Creates a priming view with custom title and description.
    ///
    /// Use this to provide context-specific copy, e.g., "Find Nearby Restaurants"
    /// instead of the generic "Share Your Location".
    init(
        permissionType: PermissionType,
        customTitle: String,
        customDescription: String,
        customImage: String? = nil,
        onGranted: @escaping () -> Void,
        onDenied: @escaping () -> Void
    ) {
        self.permissionType = permissionType
        self.customTitle = customTitle
        self.customDescription = customDescription
        self.customImage = customImage
        self.onGranted = onGranted
        self.onDenied = onDenied
    }
}

// MARK: - Denied State View

/// Shown when a permission was previously denied.
///
/// Explains that the user must go to Settings to re-enable,
/// and provides a direct button to open the Settings page.
struct PermissionDeniedView: View {
    let permissionType: PermissionType
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "gear.badge.xmark")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("\(permissionType.title)")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 24)

            Text("You previously denied this permission. To enable it, open Settings and allow access.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Spacer()

            Button {
                onOpenSettings()
            } label: {
                Text("Open Settings")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 32)
    }
}
```

## PermissionStatusTracker.swift

```swift
import Foundation
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// Monitors permission status changes and updates the UI reactively.
///
/// When a user changes a permission in Settings and returns to the app,
/// this tracker detects the change and updates the published status.
///
/// Usage:
/// ```swift
/// @State private var tracker = PermissionStatusTracker()
///
/// var body: some View {
///     Text("Camera: \(tracker.statuses[.camera]?.description ?? "unknown")")
///         .task { await tracker.startTracking([.camera, .notifications]) }
/// }
/// ```
@Observable
final class PermissionStatusTracker {
    /// Current status for each tracked permission.
    var statuses: [PermissionType: PermissionStatus] = [:]

    private let permissionManager = PermissionManager()
    private var isTracking = false

    #if canImport(UIKit)
    private var cancellables = Set<AnyCancellable>()
    #endif

    /// Start monitoring permission statuses for the given types.
    ///
    /// Checks status immediately, then re-checks whenever the app
    /// returns to the foreground (user may have changed permissions in Settings).
    @MainActor
    func startTracking(_ types: [PermissionType]) async {
        guard !isTracking else { return }
        isTracking = true

        // Initial check
        await refreshStatuses(for: types)

        // Re-check when app returns from background (user may have visited Settings)
        #if canImport(UIKit)
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    await self.refreshStatuses(for: types)
                }
            }
            .store(in: &cancellables)
        #endif
    }

    /// Stop monitoring and clear stored statuses.
    func stopTracking() {
        isTracking = false
        statuses.removeAll()
        #if canImport(UIKit)
        cancellables.removeAll()
        #endif
    }

    /// Manually refresh statuses for the tracked permissions.
    @MainActor
    func refreshStatuses(for types: [PermissionType]) async {
        for type in types {
            statuses[type] = await permissionManager.status(for: type)
        }
    }
}
```

## PermissionGatedModifier.swift

```swift
import SwiftUI

/// A ViewModifier that gates content behind a permission check.
///
/// If the permission is authorized, the content is shown normally.
/// If not determined, the priming screen is shown automatically.
/// If denied, the denied view with a Settings link is shown.
///
/// Usage:
/// ```swift
/// CameraView()
///     .permissionGated(.camera)
///
/// // With custom priming copy:
/// MapView()
///     .permissionGated(
///         .location(.whenInUse),
///         title: "Find Nearby Coffee",
///         description: "We need your location to show cafes within walking distance."
///     )
/// ```
struct PermissionGatedModifier: ViewModifier {
    let permissionType: PermissionType
    var customTitle: String?
    var customDescription: String?

    @State private var permissionManager = PermissionManager()
    @State private var currentStatus: PermissionStatus = .notDetermined
    @State private var hasChecked = false

    func body(content: Content) -> some View {
        Group {
            if !hasChecked {
                ProgressView("Checking permissions...")
            } else {
                switch currentStatus {
                case .authorized, .provisional:
                    content
                case .notDetermined:
                    primingView
                case .denied, .restricted:
                    deniedView
                }
            }
        }
        .task {
            currentStatus = await permissionManager.status(for: permissionType)
            hasChecked = true
        }
        #if canImport(UIKit)
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            Task {
                currentStatus = await permissionManager.status(for: permissionType)
            }
        }
        #endif
    }

    @ViewBuilder
    private var primingView: some View {
        if let customTitle, let customDescription {
            PermissionPrimingView(
                permissionType: permissionType,
                customTitle: customTitle,
                customDescription: customDescription,
                onGranted: { refreshStatus() },
                onDenied: { refreshStatus() }
            )
        } else {
            PermissionPrimingView(
                permissionType: permissionType,
                onGranted: { refreshStatus() },
                onDenied: { refreshStatus() }
            )
        }
    }

    private var deniedView: some View {
        PermissionDeniedView(permissionType: permissionType) {
            permissionManager.openSettings()
        }
    }

    private func refreshStatus() {
        Task {
            currentStatus = await permissionManager.status(for: permissionType)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Gates this view behind a permission check, showing a priming screen if needed.
    ///
    /// - Parameters:
    ///   - type: The permission type to check.
    ///   - title: Optional custom title for the priming screen.
    ///   - description: Optional custom description for the priming screen.
    func permissionGated(
        _ type: PermissionType,
        title: String? = nil,
        description: String? = nil
    ) -> some View {
        modifier(PermissionGatedModifier(
            permissionType: type,
            customTitle: title,
            customDescription: description
        ))
    }
}
```
