# Deep Linking Generator

Generate deep linking infrastructure with URL schemes, Universal Links, and App Intents for Siri/Shortcuts.

## When to Use

- User wants to handle custom URL schemes (myapp://)
- User mentions Universal Links or Associated Domains
- User wants Siri Shortcuts or App Intents
- User needs to navigate to specific content from external sources

## Pre-Generation Checks

Before generating, verify:

1. **Existing Deep Link Handling**
   ```bash
   # Check for existing URL handling
   grep -r "onOpenURL\|open.*url\|handleOpen" --include="*.swift" | head -5
   ```

2. **URL Scheme in Info.plist**
   ```bash
   # Check for CFBundleURLTypes
   find . -name "Info.plist" -exec grep -l "CFBundleURLSchemes" {} \;
   ```

3. **Associated Domains Entitlement**
   ```bash
   find . -name "*.entitlements" -exec grep -l "associated-domains" {} \;
   ```

## Configuration Questions

### 1. URL Scheme
- What custom URL scheme? (e.g., `myapp`)
- This enables `myapp://path/to/content` links

### 2. Universal Links
- **Yes** - Handle HTTPS links (requires AASA file on server)
- **No** - Custom URL scheme only

### 3. App Intents / Siri Shortcuts
- **Yes** - Enable voice commands and Shortcuts app
- **No** - URL-based deep linking only

### 4. Link Types
- Profile: `/users/{id}`
- Content: `/items/{id}`
- Actions: `/actions/share`, `/actions/create`
- Custom routes based on app needs

## Generated Files

### Core Infrastructure
```
Sources/DeepLinking/
├── DeepLinkRouter.swift       # Central router
├── DeepLink.swift             # Route definitions
└── UniversalLinkHandler.swift # Universal link processing
```

### App Intents (Optional)
```
Sources/AppIntents/
├── OpenContentIntent.swift    # Open specific content
├── AppShortcuts.swift         # Shortcuts provider
└── ContentEntity.swift        # Entities for Spotlight/Siri
```

### Server Files (Universal Links)
```
.well-known/
└── apple-app-site-association  # AASA file template
```

## Key Features

### Route Definitions

```swift
enum DeepLink: Equatable {
    case home
    case profile(userId: String)
    case item(itemId: String)
    case settings
    case action(ActionType)

    enum ActionType {
        case share(itemId: String)
        case create
    }
}
```

### URL Parsing

```swift
extension DeepLink {
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        let pathComponents = components.path.split(separator: "/").map(String.init)

        switch pathComponents {
        case ["users", let userId]:
            self = .profile(userId: userId)
        case ["items", let itemId]:
            self = .item(itemId: itemId)
        case ["settings"]:
            self = .settings
        default:
            self = .home
        }
    }
}
```

### SwiftUI Integration

```swift
@main
struct MyApp: App {
    @State private var router = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .onOpenURL { url in
                    router.handle(url)
                }
        }
    }
}
```

## App Intents Integration

### OpenIntent for Navigation

```swift
struct OpenItemIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Item"

    @Parameter(title: "Item")
    var target: ItemEntity

    func perform() async throws -> some IntentResult {
        await router.navigate(to: .item(itemId: target.id))
        return .result()
    }
}
```

### App Shortcuts

```swift
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenItemIntent(),
            phrases: [
                "Open \(\.$target) in \(.applicationName)",
                "Show \(\.$target)"
            ],
            shortTitle: "Open Item",
            systemImageName: "doc"
        )
    }
}
```

## Required Capabilities

### URL Scheme (Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.myapp</string>
    </dict>
</array>
```

### Universal Links (Entitlements)
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:yourapp.com</string>
    <string>applinks:www.yourapp.com</string>
</array>
```

### Server Configuration (AASA)

Host at `https://yourapp.com/.well-known/apple-app-site-association`:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAMID.com.yourcompany.yourapp",
        "paths": [
          "/items/*",
          "/users/*",
          "/share/*"
        ]
      }
    ]
  }
}
```

## Integration Steps

### 1. Basic URL Handling

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
}
```

### 2. Universal Links (UIKit)

```swift
// In SceneDelegate
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
        return
    }
    handleUniversalLink(url)
}
```

### 3. App Intents Setup

1. Create entities for Spotlight indexing
2. Implement OpenIntent for each content type
3. Define AppShortcuts for Siri phrases
4. Index entities with CSSearchableIndex

## Testing

### URL Schemes
```bash
# Simulator
xcrun simctl openurl booted "myapp://items/123"

# Device
# Open Safari and navigate to myapp://items/123
```

### Universal Links
```bash
# Test AASA file
curl -I "https://yourapp.com/.well-known/apple-app-site-association"
# Should return Content-Type: application/json

# Validate with Apple
# Use Apple's tool or Branch.io validator
```

### App Intents
1. Build and run on device
2. Open Shortcuts app
3. Your app's shortcuts should appear
4. Test with Siri: "Hey Siri, [your phrase]"

## References

- [Supporting Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [App Intents Framework](https://developer.apple.com/documentation/appintents)
- [Defining Custom URL Schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [Making App Entities Available in Spotlight](https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight)
