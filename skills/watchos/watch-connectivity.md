# Watch Connectivity Patterns

Best practices for iPhone ↔ Apple Watch communication.

## Session Management

### Complete Session Manager

```swift
import WatchConnectivity
import Foundation

/// Manages Watch Connectivity between iPhone and Apple Watch.
@Observable
final class WatchConnectivityManager: NSObject, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = WatchConnectivityManager()

    // MARK: - State

    private(set) var activationState: WCSessionActivationState = .notActivated
    private(set) var isReachable = false
    private(set) var isCompanionAppInstalled = false

    #if os(iOS)
    private(set) var isPaired = false
    private(set) var isWatchAppInstalled = false
    #endif

    // MARK: - Callbacks

    var onContextReceived: (([String: Any]) -> Void)?
    var onMessageReceived: (([String: Any]) -> Void)?
    var onUserInfoReceived: (([String: Any]) -> Void)?

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else {
            print("⌚ WCSession not supported")
            return
        }

        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Sending Data

    /// Update application context (latest state, overwrites previous).
    func updateContext(_ context: [String: Any]) throws {
        guard activationState == .activated else {
            throw WatchConnectivityError.notActivated
        }
        try WCSession.default.updateApplicationContext(context)
    }

    /// Send message for immediate delivery (both apps must be active).
    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)? = nil,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        guard isReachable else {
            errorHandler?(WatchConnectivityError.notReachable)
            return
        }

        WCSession.default.sendMessage(
            message,
            replyHandler: replyHandler,
            errorHandler: errorHandler
        )
    }

    /// Transfer user info (queued, guaranteed delivery).
    @discardableResult
    func transferUserInfo(_ userInfo: [String: Any]) -> WCSessionUserInfoTransfer? {
        guard activationState == .activated else { return nil }
        return WCSession.default.transferUserInfo(userInfo)
    }

    /// Transfer file (background, for large data).
    @discardableResult
    func transferFile(_ file: URL, metadata: [String: Any]?) -> WCSessionFileTransfer? {
        guard activationState == .activated else { return nil }
        return WCSession.default.transferFile(file, metadata: metadata)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.activationState = activationState
            self.isReachable = session.isReachable

            #if os(iOS)
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            #endif

            if let error {
                print("⌚ Activation error: \(error)")
            } else {
                print("⌚ Activated: \(activationState.rawValue)")
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⌚ Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("⌚ Session deactivated, reactivating...")
        WCSession.default.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    #endif

    // MARK: - Receiving Data

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.onContextReceived?(applicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.onMessageReceived?(message)
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            self.onMessageReceived?(message)
            // Send reply
            replyHandler(["status": "received"])
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            self.onUserInfoReceived?(userInfo)
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        // Handle received file
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.fileURL.lastPathComponent)

        do {
            try FileManager.default.copyItem(at: file.fileURL, to: destinationURL)
            print("⌚ File received: \(destinationURL)")
        } catch {
            print("⌚ File copy error: \(error)")
        }
    }
}

// MARK: - Errors

enum WatchConnectivityError: LocalizedError {
    case notSupported
    case notActivated
    case notReachable
    case notPaired
    case watchAppNotInstalled

    var errorDescription: String? {
        switch self {
        case .notSupported: return "Watch Connectivity is not supported"
        case .notActivated: return "Session is not activated"
        case .notReachable: return "Companion app is not reachable"
        case .notPaired: return "No Watch is paired"
        case .watchAppNotInstalled: return "Watch app is not installed"
        }
    }
}
```

## Data Transfer Patterns

### Sync Settings

```swift
// iPhone side
struct SettingsSync {
    static func syncToWatch() throws {
        let settings: [String: Any] = [
            "theme": UserDefaults.standard.string(forKey: "theme") ?? "system",
            "notifications": UserDefaults.standard.bool(forKey: "notifications"),
            "syncDate": Date().timeIntervalSince1970
        ]
        try WatchConnectivityManager.shared.updateContext(settings)
    }
}

// Watch side
func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
    if let theme = context["theme"] as? String {
        UserDefaults.standard.set(theme, forKey: "theme")
    }
    if let notifications = context["notifications"] as? Bool {
        UserDefaults.standard.set(notifications, forKey: "notifications")
    }
}
```

### Real-Time Actions

```swift
// Watch: Request data from iPhone
func requestLatestData() {
    WatchConnectivityManager.shared.sendMessage(
        ["action": "refresh"],
        replyHandler: { response in
            if let items = response["items"] as? [[String: Any]] {
                self.updateItems(items)
            }
        },
        errorHandler: { error in
            print("Failed to get data: \(error)")
        }
    )
}

// iPhone: Respond to request
func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
    if message["action"] as? String == "refresh" {
        let items = DataStore.shared.items.map { $0.toDictionary() }
        replyHandler(["items": items])
    }
}
```

### Queued Updates

```swift
// iPhone: Queue update for Watch
func queueItemUpdate(_ item: Item) {
    let update: [String: Any] = [
        "type": "itemUpdate",
        "item": item.toDictionary(),
        "timestamp": Date().timeIntervalSince1970
    ]
    WatchConnectivityManager.shared.transferUserInfo(update)
}

// Watch: Process queued updates
func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
    guard let type = userInfo["type"] as? String else { return }

    switch type {
    case "itemUpdate":
        if let itemData = userInfo["item"] as? [String: Any],
           let item = Item(dictionary: itemData) {
            DataStore.shared.updateItem(item)
        }
    default:
        break
    }
}
```

## Offline Support

### Caching Received Data

```swift
@Observable
final class WatchDataCache {
    private let defaults = UserDefaults.standard
    private let cacheKey = "watchDataCache"

    var cachedItems: [Item] {
        get {
            guard let data = defaults.data(forKey: cacheKey),
                  let items = try? JSONDecoder().decode([Item].self, from: data) else {
                return []
            }
            return items
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: cacheKey)
        }
    }

    func updateFromContext(_ context: [String: Any]) {
        if let itemsData = context["items"] as? Data,
           let items = try? JSONDecoder().decode([Item].self, from: itemsData) {
            cachedItems = items
        }
    }
}
```

### Handling Disconnection

```swift
struct WatchSafeView: View {
    let connectivity = WatchConnectivityManager.shared

    var body: some View {
        Group {
            if connectivity.isReachable {
                LiveDataView()
            } else {
                CachedDataView()
                    .overlay(alignment: .top) {
                        Text("Offline")
                            .font(.caption)
                            .padding(4)
                            .background(.yellow)
                            .clipShape(Capsule())
                    }
            }
        }
    }
}
```

## Complication Updates

### Push Updates from iPhone

```swift
// iPhone side
import ClockKit

func updateWatchComplication() {
    #if os(iOS)
    guard WCSession.default.isComplicationEnabled else { return }

    // Send update via complicationUserInfo (limited to 50/day)
    let info: [String: Any] = [
        "complicationData": latestData,
        "updateTime": Date().timeIntervalSince1970
    ]
    WCSession.default.transferCurrentComplicationUserInfo(info)
    #endif
}

// Watch side
func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
    if userInfo["complicationData"] != nil {
        // Reload complications
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
}
```

## Testing

### Simulator Testing

1. Run iPhone app on iPhone Simulator
2. Run Watch app on paired Watch Simulator
3. Messages and context work between paired simulators

### Debug Logging

```swift
extension WatchConnectivityManager {
    func logState() {
        print("""
        ⌚ Watch Connectivity State:
           Activation: \(activationState.rawValue)
           Reachable: \(isReachable)
        """)

        #if os(iOS)
        print("""
           Paired: \(isPaired)
           Watch App Installed: \(isWatchAppInstalled)
           Complication Enabled: \(WCSession.default.isComplicationEnabled)
        """)
        #endif
    }
}
```

## Best Practices

1. **Don't rely on connectivity** - App should work offline
2. **Use appropriate transfer method** - Context for state, messages for real-time
3. **Handle activation states** - Check before sending
4. **Debounce updates** - Don't spam context updates
5. **Serialize properly** - Only plist-compatible types
6. **Test both directions** - iPhone → Watch and Watch → iPhone
