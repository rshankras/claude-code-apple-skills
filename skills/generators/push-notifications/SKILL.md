# Push Notifications Generator

Generate push notification infrastructure with APNs registration, handling, and rich notifications.

## When to Use

- User wants to add push notifications to their app
- User mentions APNs (Apple Push Notification service)
- User asks about notification categories or actions
- User wants rich notifications with images or custom UI

## Pre-Generation Checks

Before generating, verify:

1. **Existing Notification Code**
   ```bash
   # Check for existing notification handling
   grep -r "UNUserNotificationCenter\|registerForRemoteNotifications" --include="*.swift" | head -5
   ```

2. **Entitlements**
   ```bash
   # Check for push notification entitlement
   find . -name "*.entitlements" -exec grep -l "aps-environment" {} \;
   ```

3. **App Delegate or SwiftUI App**
   ```bash
   # Determine app structure
   grep -r "@main\|UIApplicationDelegate" --include="*.swift" | head -5
   ```

## Configuration Questions

### 1. Notification Types
- **Basic** - Simple alerts with title/body
- **Rich** - Include images, custom UI (requires Notification Service Extension)
- **Both** - Full notification support

### 2. Notification Actions
- **None** - Just display notifications
- **Simple Actions** - Quick action buttons
- **Custom Categories** - Multiple action categories

### 3. Silent Notifications
- **Yes** - Background data updates
- **No** - User-visible only

## Generated Files

### Core Infrastructure
```
Sources/Notifications/
├── NotificationManager.swift      # Central notification management
├── NotificationDelegate.swift     # UNUserNotificationCenterDelegate
├── NotificationCategories.swift   # Action categories definition
└── NotificationPayload.swift      # Type-safe payload parsing
```

### Rich Notifications (Optional)
```
NotificationServiceExtension/
├── NotificationService.swift      # Modify notifications before display
└── Info.plist                     # Extension configuration
```

### Content Extension (Optional)
```
NotificationContentExtension/
├── NotificationViewController.swift  # Custom notification UI
├── MainInterface.storyboard
└── Info.plist
```

## Key Features

### Registration Flow

```swift
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        return try await center.requestAuthorization(options: options)
    }

    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
```

### Handling Notifications

```swift
// Foreground notification
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
) async -> UNNotificationPresentationOptions {
    return [.banner, .sound, .badge]
}

// Notification tap/action
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
) async {
    let userInfo = response.notification.request.content.userInfo
    await handleNotificationAction(response.actionIdentifier, userInfo: userInfo)
}
```

### Action Categories

```swift
enum NotificationCategory: String {
    case message = "MESSAGE_CATEGORY"
    case reminder = "REMINDER_CATEGORY"

    var actions: [UNNotificationAction] {
        switch self {
        case .message:
            return [
                UNNotificationAction(identifier: "REPLY", title: "Reply", options: []),
                UNNotificationAction(identifier: "MARK_READ", title: "Mark as Read", options: [])
            ]
        case .reminder:
            return [
                UNNotificationAction(identifier: "COMPLETE", title: "Complete", options: []),
                UNNotificationAction(identifier: "SNOOZE", title: "Snooze", options: [])
            ]
        }
    }
}
```

## Required Capabilities

### In Xcode
1. Select project target
2. Signing & Capabilities tab
3. Add "Push Notifications" capability
4. Add "Background Modes" > "Remote notifications" (for silent notifications)

### Entitlements
```xml
<key>aps-environment</key>
<string>development</string>  <!-- or "production" -->
```

## Integration Steps

### 1. SwiftUI App

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
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationCategories.registerAll()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")
        // Send token to your server
    }
}
```

### 2. Request Permission (at appropriate time)

```swift
Button("Enable Notifications") {
    Task {
        let granted = try await NotificationManager.shared.requestAuthorization()
        if granted {
            await MainActor.run {
                NotificationManager.shared.registerForRemoteNotifications()
            }
        }
    }
}
```

### 3. Server-Side Setup

Configure your server to send APNs requests:
- Use APNs HTTP/2 API
- Include team ID, key ID, and .p8 key
- Target: `api.push.apple.com` (production) or `api.sandbox.push.apple.com` (development)

## Testing

### Local Notifications (Simulator)
```swift
func scheduleTestNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Test"
    content.body = "This is a test notification"
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    UNUserNotificationCenter.current().add(request)
}
```

### Remote Notifications (Physical Device)
1. Build to physical device
2. Copy device token from console
3. Use APNs testing tool or `curl`:

```bash
curl -v \
  --header "authorization: bearer $JWT_TOKEN" \
  --header "apns-topic: com.yourcompany.yourapp" \
  --header "apns-push-type: alert" \
  --http2 \
  --data '{"aps":{"alert":{"title":"Test","body":"Hello"}}}' \
  https://api.sandbox.push.apple.com/3/device/$DEVICE_TOKEN
```

## References

- [User Notifications Framework](https://developer.apple.com/documentation/usernotifications)
- [Registering for APNs](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns)
- [Notification Service Extension](https://developer.apple.com/documentation/usernotifications/modifying-content-in-newly-delivered-notifications)
