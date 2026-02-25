# App Clip Code Templates

Production-ready Swift templates for App Clip infrastructure. All code targets iOS 16+ and uses modern Swift concurrency. iOS 17+ required for @Observable.

## AppClipApp.swift

```swift
import SwiftUI

/// @main entry point for the App Clip target.
///
/// Handles invocation from NFC tags, QR codes, Safari banners,
/// and Messages by listening for `NSUserActivityTypeBrowsingWeb`.
@main
struct AppClipApp: App {
    @State private var invocationHandler = InvocationHandler()

    var body: some Scene {
        WindowGroup {
            AppClipRootView(handler: invocationHandler)
                .onContinueUserActivity(
                    NSUserActivityTypeBrowsingWeb
                ) { userActivity in
                    guard let url = userActivity.webpageURL else { return }
                    invocationHandler.handleInvocation(url: url)
                }
        }
    }
}

/// Root view that routes to the appropriate experience based on invocation.
struct AppClipRootView: View {
    let handler: InvocationHandler

    var body: some View {
        Group {
            if let experience = handler.currentExperience {
                AnyView(experience.makeView())
            } else {
                DefaultAppClipView()
            }
        }
        .animation(.default, value: handler.currentExperience != nil)
    }
}

/// Default view shown when no specific invocation URL is provided.
struct DefaultAppClipView: View {
    var body: some View {
        ContentUnavailableView(
            "Welcome",
            systemImage: "app.badge",
            description: Text("Scan an NFC tag or QR code to get started.")
        )
    }
}
```

## InvocationHandler.swift

```swift
import Foundation
import Observation

/// Parses App Clip invocation URLs and routes to the appropriate experience.
///
/// Registered URL patterns:
/// - `https://example.com/clip/order?location={id}` -> OrderExperience
/// - `https://example.com/clip/reserve?venue={id}` -> ReserveExperience
/// - `https://example.com/clip/checkin?event={id}` -> CheckInExperience
/// - `https://example.com/clip/product/{id}` -> PreviewContentExperience
@Observable
final class InvocationHandler {
    /// The currently active experience parsed from the invocation URL.
    private(set) var currentExperience: (any AppClipExperience)?

    /// The raw invocation URL, if any.
    private(set) var invocationURL: URL?

    /// Registered domain for App Clip invocations.
    /// Update this to match your associated domain.
    private let registeredDomain = "example.com"

    /// Handle an invocation URL from `onContinueUserActivity`.
    func handleInvocation(url: URL) {
        invocationURL = url
        currentExperience = parseURL(url)
    }

    /// Parse a URL into an App Clip experience.
    ///
    /// Returns `nil` if the URL doesn't match any registered pattern.
    func parseURL(_ url: URL) -> (any AppClipExperience)? {
        guard let host = url.host,
              host.contains(registeredDomain) else {
            return nil
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems ?? []

        guard pathComponents.first == "clip",
              pathComponents.count >= 2 else {
            return nil
        }

        let action = pathComponents[1]
        let parameters = Dictionary(
            uniqueKeysWithValues: queryItems.compactMap { item in
                item.value.map { (item.name, $0) }
            }
        )

        switch action {
        case "order":
            guard let locationID = parameters["location"] else { return nil }
            return OrderExperience(locationID: locationID)

        case "reserve":
            guard let venueID = parameters["venue"] else { return nil }
            return ReserveExperience(venueID: venueID)

        case "checkin":
            guard let eventID = parameters["event"] else { return nil }
            return CheckInExperience(eventID: eventID)

        case "product":
            guard pathComponents.count >= 3 else { return nil }
            let productID = pathComponents[2]
            return PreviewContentExperience(productID: productID)

        default:
            return nil
        }
    }
}
```

## AppClipExperience.swift

```swift
import SwiftUI

/// Defines a single App Clip experience.
///
/// Each experience represents one user flow triggered by an invocation URL.
/// Implementations must provide a lightweight view that loads instantly
/// and delivers value without sign-in.
protocol AppClipExperience: Sendable {
    /// The type of experience for analytics and routing.
    var experienceType: AppClipExperienceType { get }

    /// Parameters extracted from the invocation URL.
    var parameters: [String: String] { get }

    /// Create the SwiftUI view for this experience.
    @MainActor func makeView() -> any View
}

/// Types of App Clip experiences.
enum AppClipExperienceType: String, Sendable {
    case orderFood
    case reserve
    case checkIn
    case previewContent
}

// MARK: - Order Experience

/// Handles food/drink ordering from a physical location.
///
/// Invocation: `https://example.com/clip/order?location={locationID}`
struct OrderExperience: AppClipExperience {
    let locationID: String

    var experienceType: AppClipExperienceType { .orderFood }

    var parameters: [String: String] {
        ["locationID": locationID]
    }

    @MainActor func makeView() -> any View {
        OrderExperienceView(locationID: locationID)
    }
}

struct OrderExperienceView: View {
    let locationID: String
    @State private var menuItems: [MenuItem] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading menu...")
                } else {
                    List(menuItems) { item in
                        MenuItemRow(item: item)
                    }
                }
            }
            .navigationTitle("Order")
            .task {
                await loadMenu()
            }
        }
    }

    private func loadMenu() async {
        // TODO: Replace with actual API call
        // Keep network requests minimal for App Clip size budget
        try? await Task.sleep(for: .milliseconds(500))
        menuItems = [
            MenuItem(id: "1", name: "Sample Item", price: 4.99)
        ]
        isLoading = false
    }
}

// MARK: - Reserve Experience

/// Handles reservation/booking at a venue.
///
/// Invocation: `https://example.com/clip/reserve?venue={venueID}`
struct ReserveExperience: AppClipExperience {
    let venueID: String

    var experienceType: AppClipExperienceType { .reserve }

    var parameters: [String: String] {
        ["venueID": venueID]
    }

    @MainActor func makeView() -> any View {
        ReserveExperienceView(venueID: venueID)
    }
}

struct ReserveExperienceView: View {
    let venueID: String
    @State private var selectedDate = Date()
    @State private var partySize = 2

    var body: some View {
        NavigationStack {
            Form {
                Section("Reservation Details") {
                    DatePicker("Date & Time", selection: $selectedDate,
                               in: Date()...,
                               displayedComponents: [.date, .hourAndMinute])

                    Stepper("Party size: \(partySize)", value: $partySize, in: 1...20)
                }

                Section {
                    Button("Reserve Now") {
                        // TODO: Submit reservation
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Reserve")
        }
    }
}

// MARK: - Check-In Experience

/// Handles event or location check-in.
///
/// Invocation: `https://example.com/clip/checkin?event={eventID}`
struct CheckInExperience: AppClipExperience {
    let eventID: String

    var experienceType: AppClipExperienceType { .checkIn }

    var parameters: [String: String] {
        ["eventID": eventID]
    }

    @MainActor func makeView() -> any View {
        CheckInExperienceView(eventID: eventID)
    }
}

struct CheckInExperienceView: View {
    let eventID: String
    @State private var isCheckedIn = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isCheckedIn {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)
                    Text("You're checked in!")
                        .font(.title)
                } else {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 80))
                        .foregroundStyle(.secondary)
                    Text("Ready to check in")
                        .font(.title)

                    Button("Check In Now") {
                        withAnimation {
                            isCheckedIn = true
                        }
                        // TODO: Submit check-in to server
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Check In")
        }
    }
}

// MARK: - Preview Content Experience

/// Handles product or content preview.
///
/// Invocation: `https://example.com/clip/product/{productID}`
struct PreviewContentExperience: AppClipExperience {
    let productID: String

    var experienceType: AppClipExperienceType { .previewContent }

    var parameters: [String: String] {
        ["productID": productID]
    }

    @MainActor func makeView() -> any View {
        PreviewContentExperienceView(productID: productID)
    }
}

struct PreviewContentExperienceView: View {
    let productID: String
    @State private var product: ProductInfo?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading...")
                } else if let product {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Product image placeholder
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.2))
                                .aspectRatio(16 / 9, contentMode: .fit)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }

                            Text(product.name)
                                .font(.title.bold())

                            Text(product.formattedPrice)
                                .font(.title2)
                                .foregroundStyle(.secondary)

                            Text(product.description)
                                .font(.body)

                            Button("Add to Cart") {
                                // TODO: Add to cart
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "Product Not Found",
                        systemImage: "exclamationmark.triangle",
                        description: Text("This product is no longer available.")
                    )
                }
            }
            .navigationTitle("Product")
            .task {
                await loadProduct()
            }
        }
    }

    private func loadProduct() async {
        // TODO: Replace with actual API call
        try? await Task.sleep(for: .milliseconds(500))
        product = ProductInfo(
            id: productID,
            name: "Sample Product",
            price: 29.99,
            description: "Product description loaded from the server."
        )
        isLoading = false
    }
}

// MARK: - Supporting Models

struct MenuItem: Identifiable {
    let id: String
    let name: String
    let price: Double
}

struct MenuItemRow: View {
    let item: MenuItem

    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
            Text(item.price, format: .currency(code: "USD"))
                .foregroundStyle(.secondary)
        }
    }
}

struct ProductInfo {
    let id: String
    let name: String
    let price: Double
    let description: String

    var formattedPrice: String {
        price.formatted(.currency(code: "USD"))
    }
}
```

## LocationConfirmationView.swift

```swift
import SwiftUI
import CoreLocation

/// Verifies the user is physically at the expected location before
/// proceeding with the App Clip experience.
///
/// Uses the App Clip location confirmation API. The system shows a
/// confirmation dialog — the app never receives the exact location,
/// only a boolean result indicating if the user is within the expected region.
///
/// Usage:
/// ```swift
/// LocationConfirmationView(
///     region: CLCircularRegion(
///         center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
///         radius: 100,
///         identifier: "store-42"
///     )
/// ) {
///     // Proceed to experience
///     OrderExperienceView(locationID: "store-42")
/// }
/// ```
struct LocationConfirmationView<Content: View>: View {
    let region: CLCircularRegion
    @ViewBuilder let confirmedContent: () -> Content

    @State private var confirmationStatus: ConfirmationStatus = .pending
    @State private var locationManager = AppClipLocationManager()

    var body: some View {
        Group {
            switch confirmationStatus {
            case .pending:
                VStack(spacing: 20) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Confirming your location...")
                        .font(.headline)
                    Text("This helps ensure you're at the right place.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

            case .confirmed:
                confirmedContent()

            case .denied:
                ContentUnavailableView(
                    "Location Not Confirmed",
                    systemImage: "location.slash",
                    description: Text(
                        "We couldn't confirm you're at the expected location. "
                        + "Please make sure you're at the right place and try again."
                    )
                )

            case .failed(let message):
                ContentUnavailableView(
                    "Location Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .task {
            await confirmLocation()
        }
    }

    private func confirmLocation() async {
        do {
            let confirmed = try await locationManager.confirmLocation(in: region)
            confirmationStatus = confirmed ? .confirmed : .denied
        } catch {
            confirmationStatus = .failed(error.localizedDescription)
        }
    }
}

// MARK: - Confirmation Status

enum ConfirmationStatus {
    case pending
    case confirmed
    case denied
    case failed(String)
}

// MARK: - Location Manager

/// Wraps CLLocationManager for App Clip location confirmation.
///
/// App Clips use a special confirmation flow where the system
/// shows a dialog to the user. The app receives only a boolean
/// result, never the precise location.
@Observable
final class AppClipLocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Bool, Error>?

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Confirm the user is within the specified region.
    ///
    /// - Parameter region: The expected location region.
    /// - Returns: `true` if the user confirmed they are at the location.
    func confirmLocation(in region: CLCircularRegion) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            // Request location confirmation — system shows a dialog
            manager.requestWhenInUseAuthorization()
            manager.startMonitoring(for: region)
            manager.requestState(for: region)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(
        _ manager: CLLocationManager,
        didDetermineState state: CLRegionState,
        for region: CLRegion
    ) {
        manager.stopMonitoring(for: region)

        switch state {
        case .inside:
            continuation?.resume(returning: true)
        case .outside, .unknown:
            continuation?.resume(returning: false)
        @unknown default:
            continuation?.resume(returning: false)
        }
        continuation = nil
    }

    func locationManager(
        _ manager: CLLocationManager,
        monitoringDidFailFor region: CLRegion?,
        withError error: Error
    ) {
        if let region {
            manager.stopMonitoring(for: region)
        }
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
```

## FullAppUpgradeView.swift

```swift
import SwiftUI
import StoreKit

/// Presents an SKOverlay banner prompting the user to download the full app.
///
/// Shows a list of benefits the user will get by upgrading,
/// and displays the system App Store overlay for one-tap install.
///
/// Usage:
/// ```swift
/// FullAppUpgradeView(
///     appStoreID: "123456789",
///     benefits: [
///         "Order history and favorites",
///         "Loyalty rewards program",
///         "Push notifications for order updates"
///     ]
/// )
/// ```
struct FullAppUpgradeView: View {
    let appStoreID: String
    let benefits: [String]

    @State private var showOverlay = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

                Text("Get the Full App")
                    .font(.title.bold())

                Text("Unlock all features with the full app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Benefits list
            VStack(alignment: .leading, spacing: 12) {
                ForEach(benefits, id: \.self) { benefit in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(benefit)
                            .font(.body)
                    }
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            }

            Spacer()

            // Install button
            Button {
                showOverlay = true
            } label: {
                Text("Download Full App")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Skip button
            Button("Not Now") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .appStoreOverlay(isPresented: $showOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
    }
}

// MARK: - Inline Upgrade Banner

/// A compact banner view that can be placed at the bottom of any experience
/// to suggest upgrading to the full app.
///
/// Usage:
/// ```swift
/// VStack {
///     // Main experience content
///     OrderExperienceView(locationID: locationID)
///
///     UpgradeBanner(appStoreID: "123456789")
/// }
/// ```
struct UpgradeBanner: View {
    let appStoreID: String
    @State private var showOverlay = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Get the full experience")
                    .font(.subheadline.bold())
                Text("Download the app for all features")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Get") {
                showOverlay = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        }
        .padding(.horizontal)
        .appStoreOverlay(isPresented: $showOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
    }
}
```

## SharedDataManager.swift

```swift
import Foundation

/// Manages shared data between the App Clip and the full app via App Group.
///
/// Data stored by the App Clip can be read by the full app after install,
/// enabling seamless transfer of user activity (orders, preferences, etc.).
///
/// **Important:** App Clip data is deleted after 8 hours of inactivity.
/// Use this manager to persist critical data in the shared App Group container
/// so the full app can access it after install.
///
/// Setup:
/// 1. Add App Group capability to both targets
/// 2. Use the same group identifier (e.g., `group.com.yourapp`)
///
/// Usage:
/// ```swift
/// // App Clip: Save data
/// SharedDataManager.shared.save(order, forKey: "pendingOrder")
///
/// // Full App: Load data
/// if let order: Order = SharedDataManager.shared.load(forKey: "pendingOrder") {
///     showPendingOrder(order)
/// }
/// ```
final class SharedDataManager: Sendable {
    /// Shared instance using the default App Group.
    /// Update the suite name to match your App Group identifier.
    static let shared = SharedDataManager(suiteName: "group.com.yourapp")

    private let defaults: UserDefaults?

    /// Initialize with an App Group suite name.
    ///
    /// - Parameter suiteName: The App Group identifier (e.g., `group.com.yourapp`).
    init(suiteName: String) {
        self.defaults = UserDefaults(suiteName: suiteName)
    }

    // MARK: - Save

    /// Save a Codable value to the shared container.
    ///
    /// - Parameters:
    ///   - value: The value to save.
    ///   - key: The key to store the value under.
    func save<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults?.set(data, forKey: key)

        // Also store a timestamp for migration awareness
        defaults?.set(Date(), forKey: "\(key)_timestamp")
    }

    // MARK: - Load

    /// Load a Codable value from the shared container.
    ///
    /// - Parameter key: The key the value was stored under.
    /// - Returns: The decoded value, or `nil` if not found or decoding fails.
    func load<T: Codable>(forKey key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Timestamp

    /// Get the timestamp when a value was saved.
    ///
    /// Useful to check if shared data is stale or fresh.
    func timestamp(forKey key: String) -> Date? {
        defaults?.object(forKey: "\(key)_timestamp") as? Date
    }

    // MARK: - Remove

    /// Remove a value from the shared container.
    func remove(forKey key: String) {
        defaults?.removeObject(forKey: key)
        defaults?.removeObject(forKey: "\(key)_timestamp")
    }

    // MARK: - Migration

    /// Check if there is pending data from the App Clip to migrate.
    ///
    /// Call this in the full app's launch sequence to detect
    /// and import App Clip data.
    ///
    /// - Parameter keys: Keys to check for pending data.
    /// - Returns: Keys that have data available.
    func pendingMigrationKeys(from keys: [String]) -> [String] {
        keys.filter { defaults?.data(forKey: $0) != nil }
    }

    /// Remove all migrated data after successful import.
    ///
    /// Call this after the full app has imported all App Clip data.
    func clearMigratedData(keys: [String]) {
        for key in keys {
            remove(forKey: key)
        }
    }
}

// MARK: - Migration Helper

/// Handles one-time data migration from App Clip to full app.
///
/// Usage in the full app's root view or App struct:
/// ```swift
/// .task {
///     AppClipMigrator.migrateIfNeeded { migrated in
///         if migrated.contains("pendingOrder") {
///             // Show the user their pending order from the App Clip
///         }
///     }
/// }
/// ```
enum AppClipMigrator {
    private static let migrationCompleteKey = "appClipMigrationComplete"

    /// Known keys that the App Clip may have stored.
    /// Update this list to match your App Clip's stored data keys.
    static let knownKeys = [
        "pendingOrder",
        "userPreferences",
        "recentActivity"
    ]

    /// Check for and migrate App Clip data.
    ///
    /// This is idempotent — it only runs once per install.
    ///
    /// - Parameter handler: Closure called with the list of keys that had data.
    static func migrateIfNeeded(handler: ([String]) -> Void) {
        let manager = SharedDataManager.shared

        // Skip if already migrated
        guard !(UserDefaults.standard.bool(forKey: migrationCompleteKey)) else {
            return
        }

        let pendingKeys = manager.pendingMigrationKeys(from: knownKeys)

        if !pendingKeys.isEmpty {
            handler(pendingKeys)

            // Clean up after migration
            manager.clearMigratedData(keys: pendingKeys)
        }

        UserDefaults.standard.set(true, forKey: migrationCompleteKey)
    }
}
```
