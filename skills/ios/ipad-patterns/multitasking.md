# Multitasking, Multi-Window, and Adaptive Layout

Covers Stage Manager, multiple windows via UIScene, Split View and Slide Over adaptation, size classes, NavigationSplitView column configuration, and external display support.

## UIScene Lifecycle

iPadOS 13+ uses the UIScene architecture. Each window is backed by a `UISceneSession` with a `UIScene` (specifically `UIWindowScene`).

### Scene Configuration (UIKit)

In `Info.plist`, declare scene configurations:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

Set `UIApplicationSupportsMultipleScenes` to `true` to enable multi-window.

### Scene Delegate

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()

        // Restore state from user activity
        if let activity = connectionOptions.userActivities.first
            ?? session.stateRestorationActivity {
            restoreState(from: activity)
        }
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        // Return activity representing current state for restoration
        let activity = NSUserActivity(activityType: "com.app.document")
        activity.userInfo = ["documentID": currentDocumentID]
        return activity
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Scene released by system -- clean up resources
        // Do NOT delete user data here; the scene may reconnect
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Scene moved to foreground and is interactive
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Scene is about to move out of foreground
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save state; scene may be disconnected next
    }
}
```

### Scene Lifecycle States

```
Not Running --> Foreground Inactive --> Foreground Active
                       |                       |
                       v                       v
                  Background <-----------------+
                       |
                       v
                  Suspended (may be disconnected)
```

Key point: each scene transitions independently. One scene can be active while another is in the background.

## Requesting New Windows (UIKit)

```swift
// Open a new window for a document
func openNewWindow(for document: Document) {
    let activity = NSUserActivity(activityType: "com.app.document")
    activity.userInfo = ["documentID": document.id.uuidString]

    UIApplication.shared.requestSceneSessionActivation(
        nil,                    // nil = create new session
        userActivity: activity, // Pass data to the new scene
        options: nil,
        errorHandler: { error in
            print("Failed to open window: \(error)")
        }
    )
}

// Close/destroy a scene session
func closeWindow(session: UISceneSession) {
    UIApplication.shared.requestSceneSessionDestruction(
        session,
        options: nil,
        errorHandler: nil
    )
}
```

### Handling the Activity in Scene Delegate

```swift
func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
) {
    if let activity = connectionOptions.userActivities.first {
        if let documentID = activity.userInfo?["documentID"] as? String {
            showDocument(withID: documentID)
        }
    }
}
```

## Multi-Window in SwiftUI

### Basic Multi-Window Support

```swift
@main
struct MyApp: App {
    var body: some Scene {
        // Primary window group -- supports multiple instances
        WindowGroup {
            ContentView()
        }

        // Additional window type for a specific purpose
        WindowGroup("Document", id: "document", for: UUID.self) { $documentID in
            if let documentID {
                DocumentView(documentID: documentID)
            }
        }
    }
}
```

### Opening Windows Programmatically

```swift
struct ContentView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Document") {
            openWindow(id: "document", value: document.id)
        }
    }
}
```

### Handling External Events

```swift
WindowGroup {
    ContentView()
}
.handlesExternalEvents(matching: ["main"])

WindowGroup("Document", id: "document", for: URL.self) { $url in
    if let url {
        DocumentView(url: url)
    }
}
.handlesExternalEvents(matching: ["document"])
```

## Stage Manager

Stage Manager (iPadOS 16+, M1 iPads) allows freely resizable windows. Apps must handle:

1. **Arbitrary window sizes** -- do not assume fixed dimensions
2. **Multiple windows visible simultaneously** -- each is its own scene
3. **Window chrome** -- system provides title bar, resize handles

### Handling Resizable Windows

```swift
// ❌ Wrong -- assuming full screen width
struct ContentView: View {
    var body: some View {
        HStack {
            sidebar
                .frame(width: 300)   // Fixed sidebar breaks at small widths
            detail
        }
    }
}

// ✅ Right -- use NavigationSplitView which handles resizing
struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
    }
}
```

### Restricting Window Size (UIKit)

```swift
func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
) {
    guard let windowScene = scene as? UIWindowScene else { return }

    // Set minimum and maximum window size
    let restrictions = UISceneSizeRestrictions(minimumSize: CGSize(width: 400, height: 300))
    restrictions.maximumSize = CGSize(width: 1200, height: 900)

    if #available(iOS 16.0, *) {
        windowScene.sizeRestrictions?.minimumSize = CGSize(width: 400, height: 300)
        windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1200, height: 900)
    }
}
```

### Restricting Window Size (SwiftUI)

```swift
WindowGroup {
    ContentView()
}
.defaultSize(width: 800, height: 600)
```

## Split View and Slide Over

When the user places the app in Split View (50/50 or 70/30) or Slide Over (narrow overlay), the app receives a compact or regular horizontal size class.

### Size Class Detection (SwiftUI)

```swift
struct AdaptiveView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            // Single-column layout (Slide Over, Split View narrow, iPhone)
            NavigationStack {
                ItemListView()
            }
        } else {
            // Multi-column layout (full screen, Split View wide)
            NavigationSplitView {
                ItemListView()
            } detail: {
                DetailView()
            }
        }
    }
}
```

### Size Class Detection (UIKit)

```swift
class AdaptiveViewController: UIViewController {
    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateLayout()
        }
    }

    // iOS 17+: Modern trait change registration
    func setupTraitObservation() {
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            self.updateLayout()
        }
    }

    private func updateLayout() {
        if traitCollection.horizontalSizeClass == .compact {
            showSingleColumnLayout()
        } else {
            showMultiColumnLayout()
        }
    }
}
```

### NavigationSplitView Column Configuration

```swift
struct ContentView: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } content: {
            ContentListView()
                .navigationSplitViewColumnWidth(min: 250, ideal: 350, max: 500)
        } detail: {
            DetailView()
                .navigationSplitViewColumnWidth(min: 300)
        }
        .navigationSplitViewStyle(.balanced) // or .prominentDetail
    }
}
```

### Adapting Toolbar for Size Class

```swift
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        content
            .toolbar {
                if sizeClass == .regular {
                    ToolbarItem(placement: .primaryAction) {
                        Button("New", systemImage: "plus") { }
                    }
                    ToolbarItem(placement: .secondaryAction) {
                        Button("Filter", systemImage: "line.3.horizontal.decrease.circle") { }
                    }
                } else {
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Button("New", systemImage: "plus") { }
                            Spacer()
                            Button("Filter", systemImage: "line.3.horizontal.decrease.circle") { }
                        }
                    }
                }
            }
    }
}
```

## External Display Support

### Modern Approach (SwiftUI, iPadOS 16+)

Use a dedicated `WindowGroup` for external displays:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        // This WindowGroup can be placed on an external display
        WindowGroup("Presentation", id: "presentation") {
            PresentationView()
        }
    }
}
```

### Legacy Approach (UIKit)

```swift
class ExternalDisplayManager {
    private var externalWindow: UIWindow?

    func startObservingScreens() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidConnect),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidDisconnect),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )
    }

    @objc private func screenDidConnect(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }

        let window = UIWindow(frame: screen.bounds)
        window.screen = screen
        window.rootViewController = ExternalDisplayViewController()
        window.makeKeyAndVisible()
        externalWindow = window
    }

    @objc private func screenDidDisconnect(_ notification: Notification) {
        externalWindow?.isHidden = true
        externalWindow = nil
    }
}
```

Note: `UIScreen.didConnectNotification` and `UIScreen.didDisconnectNotification` are the legacy pattern. For SwiftUI apps, prefer multiple `WindowGroup` scenes.

## Common Mistakes

### Not Setting UIApplicationSupportsMultipleScenes

```swift
// ❌ Wrong -- Info.plist has UIApplicationSupportsMultipleScenes = false
// App only ever has one window, Expose shows no multi-window option

// ✅ Right -- set to true in Info.plist
// <key>UIApplicationSupportsMultipleScenes</key>
// <true/>
```

### Storing State in AppDelegate Instead of Per-Scene

```swift
// ❌ Wrong -- global state shared across all windows
class AppDelegate: UIResponder, UIApplicationDelegate {
    var currentDocument: Document?  // Which window does this belong to?
}

// ✅ Right -- state lives in scene delegate or per-scene model
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var documentState: DocumentState?  // Each scene has its own state
}
```

### Ignoring Scene Disconnection

```swift
// ❌ Wrong -- never cleaning up when scene disconnects
// Resources leak as system disconnects background scenes

// ✅ Right -- release heavy resources in sceneDidDisconnect
func sceneDidDisconnect(_ scene: UIScene) {
    // Release image caches, media players, etc.
    // Keep user data — scene may reconnect
    releaseHeavyResources()
}
```

### Fixed Layouts That Break in Split View

```swift
// ❌ Wrong -- assumes full screen width
.frame(width: UIScreen.main.bounds.width)

// ✅ Right -- use GeometryReader or flexible layouts
GeometryReader { geometry in
    content
        .frame(width: geometry.size.width)
}

// ✅ Even better -- use flexible SwiftUI layout without explicit widths
HStack {
    sidebar
        .frame(minWidth: 200, maxWidth: 300)
    detail
        .frame(maxWidth: .infinity)
}
```

## Checklist

- [ ] `UIApplicationSupportsMultipleScenes` is `true` in Info.plist
- [ ] State is per-scene, not global in AppDelegate
- [ ] `stateRestorationActivity(for:)` returns meaningful NSUserActivity
- [ ] Scene handles `userActivities` in `willConnectTo` for restoring state
- [ ] `sceneDidDisconnect` releases heavy resources without deleting user data
- [ ] Layout adapts to `horizontalSizeClass` (compact vs regular)
- [ ] No use of `UIScreen.main.bounds` for sizing (use GeometryReader or flexible layout)
- [ ] NavigationSplitView uses `min/ideal/max` column widths
- [ ] Toolbar items adapt placement for compact vs regular size class
- [ ] External display content is handled via WindowGroup or screen notifications
