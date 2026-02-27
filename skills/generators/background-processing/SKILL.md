---
name: background-processing
description: Generates background processing infrastructure with BGTaskScheduler, background refresh, background downloads, and silent push handling. Use when user needs background tasks, periodic refresh, background URLSession downloads, or silent push notification processing.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Background Processing Generator

Generate production background processing infrastructure -- BGTaskScheduler for periodic refresh and long-running tasks, background URLSession for downloads/uploads that survive app termination, and silent push handling for server-triggered updates.

## When This Skill Activates

Use this skill when the user:
- Asks to "add background processing" or "background tasks"
- Mentions "BGTaskScheduler" or "BGAppRefreshTask" or "BGProcessingTask"
- Wants "background refresh" or "periodic background updates"
- Asks about "background downloads" or "background uploads"
- Mentions "silent push" or "content-available push notifications"
- Wants data to sync or update while the app is in the background
- Asks about "background fetch" or "background execution"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (BGTaskScheduler requires iOS 13+)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Existing Background Task Detection
Search for existing background task code:
```
Glob: **/*BackgroundTask*.swift, **/*BGTask*.swift, **/*BackgroundDownload*.swift
Grep: "BGTaskScheduler" or "BGAppRefreshTask" or "BGProcessingTask" or "backgroundSession"
```

If existing background code found:
- Ask if user wants to replace or augment it
- If augmenting, identify what is missing and generate only those pieces

### 3. Info.plist Check
Search for existing background modes configuration:
```
Grep: "BGTaskSchedulerPermittedIdentifiers" or "UIBackgroundModes"
```

Check for push notification entitlements if silent push is needed:
```
Glob: **/*.entitlements
Grep: "aps-environment"
```

## Configuration Questions

Ask user via AskUserQuestion:

1. **What background processing do you need?**
   - App refresh (lightweight periodic updates -- weather, feeds, content)
   - Data processing (long-running -- database cleanup, ML model updates, large syncs)
   - Background downloads (files, media, assets that survive app termination)
   - Silent push notifications (server-triggered content updates)
   - Multiple (select which combination)

2. **How often should background tasks run?**
   - Hourly (system decides exact timing, best-effort)
   - Every few hours (recommended for most apps)
   - Daily (content that changes infrequently)
   - On content change via push (server triggers update with silent push)

3. **Does the task need network access?**
   - Yes -- needs background fetch or download capability
   - No -- local processing only (database maintenance, cleanup)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `BackgroundTaskManager.swift` -- Central manager for registering and scheduling all background tasks
2. `BackgroundTaskConfiguration.swift` -- Info.plist keys, entitlements, and task identifier constants

### Step 3: Create Feature-Specific Files
Based on configuration:
3. `BackgroundDownloadManager.swift` -- If background downloads selected
4. `SilentPushHandler.swift` -- If silent push selected

### Step 4: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/BackgroundProcessing/`
- If `App/` exists -> `App/BackgroundProcessing/`
- Otherwise -> `BackgroundProcessing/`

## Output Format

After generation, provide:

### Files Created
```
BackgroundProcessing/
├── BackgroundTaskManager.swift        # BGTaskScheduler registration & scheduling
├── BackgroundTaskConfiguration.swift  # Task identifiers and Info.plist config
├── BackgroundDownloadManager.swift    # Background URLSession downloads (optional)
└── SilentPushHandler.swift            # Silent push handling (optional)
```

### Integration with App Lifecycle

**Register tasks at app launch (must happen before app finishes launching):**
```swift
@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        BackgroundTaskManager.shared.registerTasks()
        return true
    }
}
```

**Schedule refresh when app enters background:**
```swift
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            FeedView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                BackgroundTaskManager.shared.scheduleAppRefresh()
            }
        }
    }
}
```

**Start a background download:**
```swift
func downloadAsset(from url: URL) {
    BackgroundDownloadManager.shared.startDownload(from: url)
}
```

**Handle silent push in AppDelegate:**
```swift
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any]
) async -> UIBackgroundFetchResult {
    await SilentPushHandler.shared.handle(userInfo: userInfo)
}
```

### Testing

**Simulate background task in Xcode debugger (LLDB):**
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.app.refresh"]
```

**Simulate expiration:**
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.app.refresh"]
```

**Test background download:**
```swift
#if DEBUG
func simulateBackgroundDownload() {
    let testURL = URL(string: "https://example.com/test-asset.zip")!
    BackgroundDownloadManager.shared.startDownload(from: testURL)
}
#endif
```

### Required Info.plist Configuration

Add to Info.plist:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.app.refresh</string>
    <string>com.app.processing</string>
</array>
```

### Required Background Modes

In Xcode: Target > Signing & Capabilities > Background Modes:
- **Background fetch** -- for BGAppRefreshTask
- **Background processing** -- for BGProcessingTask
- **Remote notifications** -- for silent push
- **Background download** -- for background URLSession (automatic when using background configuration)

## Common Patterns

### Schedule Refresh on Entering Background
Always schedule the next refresh when the app goes to background. The system decides when to actually run it.
```swift
BackgroundTaskManager.shared.scheduleAppRefresh()
```

### Long-Running Processing with Expiration Handling
BGProcessingTask can run for minutes, but always handle the `expirationHandler` to save progress.
```swift
task.expirationHandler = {
    // Save partial progress so next run can resume
    processingJob.saveCheckpoint()
}
```

### Energy-Efficient Background Work
```swift
// Only process on Wi-Fi + power
let request = BGProcessingTaskRequest(identifier: taskID)
request.requiresNetworkConnectivity = true
request.requiresExternalPower = true
```

## Gotchas

### Registration Must Happen Before didFinishLaunching Returns
`BGTaskScheduler.shared.register(forTaskWithIdentifier:)` must be called during `didFinishLaunchingWithOptions`. If called later, the registration silently fails. Always register in AppDelegate, never in a View.

### System Controls Scheduling
The system decides when to run background tasks based on battery, network, user patterns, and frequency. You cannot guarantee exact timing. `earliestBeginDate` is a hint, not a guarantee.

### Background URLSession Delegate Callbacks
Background URLSession delivers delegate callbacks even if the app was terminated and relaunched. The session must be recreated with the same identifier, and `application(_:handleEventsForBackgroundURLSession:completionHandler:)` must be implemented.

### Silent Push Limitations
Silent push notifications are rate-limited by APNs. If you send too many, the system throttles them. Use them for important content changes, not periodic polling.

### 30-Second Window for App Refresh
`BGAppRefreshTask` gives you approximately 30 seconds of execution time. For longer work, use `BGProcessingTask` instead (which can run for several minutes when conditions are met).

### Simulator Limitations
Background tasks do not run naturally on the Simulator. Use the LLDB `_simulateLaunchForTaskWithIdentifier:` command to trigger them manually during development.

## References

- **templates.md** -- All production Swift templates for background processing
- [Background Tasks Framework](https://developer.apple.com/documentation/backgroundtasks)
- [Downloading Files in the Background](https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background)
- [Pushing Background Updates to Your App](https://developer.apple.com/documentation/usernotifications/pushing-background-updates-to-your-app)
- Related: `generators/push-notifications` -- Full push notification infrastructure
- Related: `generators/offline-queue` -- Queue operations for when back online
