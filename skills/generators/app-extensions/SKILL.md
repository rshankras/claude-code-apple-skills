---
name: app-extensions
description: Generates app extension infrastructure for Share Extensions, Action Extensions, Keyboard Extensions, and Safari Web Extensions with data sharing via App Groups. Use when user wants to add a share extension, action extension, keyboard extension, Safari web extension, or any app extension type.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# App Extensions Generator

Generate production app extension infrastructure -- Share Extensions for receiving content from other apps, Action Extensions for manipulating content in-place, Keyboard Extensions for custom input, and Safari Web Extensions for browser integration. Includes App Group data sharing between the host app and extensions.

## When This Skill Activates

Use this skill when the user:
- Asks to "add a share extension" or "share sheet extension"
- Wants to "receive content from other apps" or "accept shared content"
- Mentions "action extension" or "content manipulation extension"
- Wants to "add a custom keyboard" or "keyboard extension"
- Asks about "Safari extension" or "Safari web extension"
- Mentions "app extension" or "extension target" generically
- Wants to "share data between app and extension" or "App Groups"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Identify project structure (find .xcodeproj or Package.swift)
- [ ] Identify source file locations

### 2. Existing Extension Detection
Search for existing extension targets:
```
Glob: **/*Extension*/*.swift, **/*Extension*/Info.plist
Grep: "NSExtensionPointIdentifier" or "NSExtensionPrincipalClass"
```

If existing extensions found:
- Ask if user wants to add another or modify existing
- Identify existing App Groups configuration

### 3. App Groups Detection
Check for existing App Groups setup:
```
Glob: **/*.entitlements
Grep: "com.apple.security.application-groups"
```

If App Groups exist, reuse the existing group identifier.

## Configuration Questions

Ask user via AskUserQuestion:

1. **What type of extension?**
   - Share Extension (accept content from other apps, display share UI)
   - Action Extension (manipulate content in-place -- transform text, edit images)
   - Keyboard Extension (custom input keyboard with KeyboardViewController)
   - Safari Web Extension (inject JavaScript/CSS into web pages)

2. **What content types does it handle?**
   - Text (plain text, rich text)
   - URLs (web links, deep links)
   - Images (photos, screenshots)
   - Files (documents, PDFs, archives)
   - All (any content type)

3. **Does the extension need to share data with the main app?**
   - Yes -- needs App Groups (shared UserDefaults, shared file container, shared Keychain)
   - No -- extension is self-contained

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Extension Files
Based on extension type selected:

**Share Extension:**
1. `ShareViewController.swift` -- Main share extension view controller with content handling
2. `Info.plist` -- Extension configuration with activation rules

**Action Extension:**
3. `ActionViewController.swift` -- Action extension with content manipulation
4. `Info.plist` -- Extension configuration

**Keyboard Extension:**
5. `KeyboardViewController.swift` -- Custom keyboard with UIInputViewController
6. `Info.plist` -- Keyboard extension configuration

**Safari Web Extension:**
7. `SafariWebExtensionHandler.swift` -- Native message handler
8. `manifest.json` -- Web extension manifest
9. `content.js` -- Content script template

### Step 3: Create Shared Infrastructure
If data sharing selected:
10. `SharedDataManager.swift` -- App Group data sharing helper

### Step 4: Determine File Location
Extensions are separate targets:
- Share Extension -> `ShareExtension/`
- Action Extension -> `ActionExtension/`
- Keyboard Extension -> `KeyboardExtension/`
- Safari Web Extension -> `SafariWebExtension/`
- Shared code -> `Shared/` or within main app target

## Output Format

After generation, provide:

### Files Created

**Share Extension:**
```
ShareExtension/
├── ShareViewController.swift  # Main share extension view controller
└── Info.plist                 # Extension activation rules & config
```

**Action Extension:**
```
ActionExtension/
├── ActionViewController.swift # Content manipulation controller
└── Info.plist                 # Extension activation rules & config
```

**Keyboard Extension:**
```
KeyboardExtension/
├── KeyboardViewController.swift # UIInputViewController subclass
└── Info.plist                   # Keyboard extension config
```

**Safari Web Extension:**
```
SafariWebExtension/
├── SafariWebExtensionHandler.swift # Native message handler
└── Resources/
    ├── manifest.json               # Web extension manifest
    ├── content.js                  # Content script
    └── popup.html                  # Popup UI (optional)
```

**Shared (if data sharing enabled):**
```
Shared/
└── SharedDataManager.swift    # App Group data sharing
```

### Integration Steps

**1. Add Extension Target in Xcode:**
- File > New > Target
- Select the extension type (Share, Action, Keyboard, Safari Web)
- Configure bundle identifier: `com.yourapp.ShareExtension`
- Xcode creates the target with boilerplate -- replace with generated code

**2. Configure App Groups (if data sharing):**
- Select main app target > Signing & Capabilities > Add "App Groups"
- Add group: `group.com.yourapp.shared`
- Select extension target > Signing & Capabilities > Add "App Groups"
- Add the same group identifier

**3. Share code between targets:**
- Add shared files to both the app and extension targets
- Or create a shared framework target

### Extension Content Handling

**Accept shared URLs:**
```swift
if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, error in
        guard let url = item as? URL else { return }
        // Process URL
    }
}
```

**Accept shared images:**
```swift
if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
    provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, error in
        if let imageURL = item as? URL {
            let imageData = try? Data(contentsOf: imageURL)
            // Process image data
        }
    }
}
```

**Share data to main app via App Groups:**
```swift
let shared = SharedDataManager.shared
shared.saveSharedContent(url.absoluteString, forKey: "lastSharedURL")
```

### Testing

**Share Extension:**
1. Build and run the extension scheme
2. Select a host app (Safari, Photos, etc.)
3. Share content and verify your extension appears
4. Test with different content types

**Action Extension:**
1. Build and run the extension scheme
2. Open content in a supported app
3. Tap the share/action button and select your action

**Keyboard Extension:**
1. Build and run the keyboard extension scheme
2. Go to Settings > General > Keyboard > Keyboards > Add New Keyboard
3. Select your keyboard
4. Open any text field and switch to your keyboard

**Safari Web Extension:**
1. Build and run the app (which contains the extension)
2. Go to Safari > Settings > Extensions
3. Enable your extension
4. Navigate to a web page and verify behavior

## Extension Lifecycle and Limits

### Memory Limits
- Share Extension: ~120 MB
- Action Extension: ~120 MB
- Keyboard Extension: ~48 MB (very constrained)
- Safari Web Extension: ~6 MB for content scripts

### Execution Limits
- Extensions must complete work quickly (no long background execution)
- Must call `completeRequest()` or `cancelRequest()` when done
- No access to HealthKit, CallKit, or some restricted frameworks
- Network requests are allowed but should be brief

### Extension Termination
The system can terminate extensions at any time for resource reclamation. Save state frequently and handle interruption gracefully.

## Gotchas

### completeRequest Must Be Called
The extension host waits for `extensionContext?.completeRequest(returningItems:)`. If you never call it, the share sheet hangs and the user is stuck. Always call it in both success and error paths.

### Keyboard Extensions Need Open Access for Network
By default keyboard extensions have no network access. The user must explicitly grant "Allow Full Access" in Settings. Without it, URLSession calls fail silently. Design your keyboard to work without network and enhance when access is granted.

### App Groups Require Matching Identifiers
The App Group identifier must be identical in both the main app and extension entitlements. A typo means `UserDefaults(suiteName:)` returns a different (empty) container.

### Safari Web Extension Content Scripts Run in Isolated World
Content scripts cannot directly access the page's JavaScript variables. Use `window.postMessage` or the browser messaging API to communicate between content scripts and the page.

### Extension Bundle Identifier Convention
Extension bundle identifiers must be prefixed with the main app bundle identifier:
- Main app: `com.yourcompany.myapp`
- Share Extension: `com.yourcompany.myapp.ShareExtension`

## References

- **templates.md** -- All production Swift templates for each extension type
- [App Extension Programming Guide](https://developer.apple.com/app-extensions/)
- [Creating a Share Extension](https://developer.apple.com/documentation/foundation/app_extension_support)
- [Custom Keyboard Guide](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard)
- [Safari Web Extensions](https://developer.apple.com/documentation/safariservices/safari_web_extensions)
- Related: `generators/deep-linking` -- Handle URLs received via extensions
- Related: `generators/push-notifications` -- Notification extensions (Service/Content)
