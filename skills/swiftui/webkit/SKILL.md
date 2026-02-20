---
name: webkit-integration
description: WebKit integration in SwiftUI using WebView and WebPage for embedding web content, navigation, JavaScript interop, and customization. Use when embedding web content in SwiftUI apps.
allowed-tools: [Read, Glob, Grep]
---

# WebKit Integration for SwiftUI

Embed and control web content in SwiftUI apps using the native `WebView` struct and `WebPage` observable class. Covers loading, navigation, JavaScript execution, and view customization.

## When This Skill Activates

- User wants to display web content inside a SwiftUI app
- User needs to load URLs, HTML strings, or data blobs in a web view
- User asks about JavaScript interop from SwiftUI
- User needs navigation control (back, forward, reload) for embedded web content
- User wants to customize web view behavior (gestures, text selection, link previews)
- User needs to capture snapshots or export PDFs from web content
- User asks about intercepting navigation requests or custom URL schemes
- User wants to configure private browsing or custom user agents

## Decision Tree

```
What do you need?
|
+-- Display a URL or HTML content
|   +-- Simple, no interaction needed
|   |   +-- WebView(url:) --> see webview-basics.md
|   +-- Need loading state, reload, custom config
|       +-- WebPage + WebView(page) --> see webview-basics.md
|
+-- Navigate programmatically (back, forward, intercept)
|   +-- Back/forward list, navigation events
|   |   +-- see navigation.md
|   +-- Intercept or cancel navigation requests
|       +-- NavigationDeciding protocol --> see navigation.md
|
+-- Execute JavaScript or communicate with web content
|   +-- callJavaScript, arguments, content worlds
|       +-- see javascript-advanced.md
|
+-- Capture snapshots, export PDF, web archive
|   +-- page.snapshot(), page.pdf(), page.webArchiveData()
|       +-- see javascript-advanced.md
|
+-- Handle custom URL schemes
    +-- URLSchemeHandler protocol --> see javascript-advanced.md
```

## API Availability

| API | Minimum OS | Import |
|-----|-----------|--------|
| `WebView` | iOS 26 / macOS 26 | `SwiftUI` + `WebKit` |
| `WebPage` | iOS 26 / macOS 26 | `WebKit` |
| `WebPage.Configuration` | iOS 26 / macOS 26 | `WebKit` |
| `NavigationDeciding` | iOS 26 / macOS 26 | `WebKit` |
| `WKContentWorld` | iOS 14 / macOS 11 | `WebKit` |
| `WKSnapshotConfiguration` | iOS 11 / macOS 10.13 | `WebKit` |
| `WKPDFConfiguration` | iOS 14 / macOS 11 | `WebKit` |

## Quick Start

### Simplest Usage

```swift
import SwiftUI
import WebKit

struct BrowserView: View {
    var body: some View {
        WebView(url: URL(string: "https://developer.apple.com")!)
    }
}
```

### With WebPage for Full Control

```swift
import SwiftUI
import WebKit

struct ControlledBrowserView: View {
    @State private var page = WebPage()

    var body: some View {
        WebView(page)
            .onAppear {
                page.load(URLRequest(url: URL(string: "https://developer.apple.com")!))
            }
    }
}
```

## Top Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Using `WebView(url:)` when you need navigation control | No access to back/forward, reload, or events | Use `WebPage` + `WebView(page)` |
| Forgetting `import WebKit` alongside `import SwiftUI` | `WebView` is in SwiftUI but `WebPage` requires WebKit | Always import both |
| Not observing `currentNavigationEvent` | Missing loading states, errors go unnoticed | Use `onChange(of: page.currentNavigationEvent)` |
| Calling `callJavaScript` before page finishes loading | Script fails because DOM is not ready | Wait for `.finished` navigation event |
| Using persistent data store for private browsing | User data is saved to disk | Use `.nonPersistent()` on `WebsiteDataStore` |
| Not handling `nil` return from `decidePolicyFor(navigationAction:)` | Navigation proceeds when it should be cancelled | Return `nil` to cancel, return `NavigationPreferences` to allow |
| Passing JavaScript without argument binding | Vulnerable to injection, hard to debug | Use `arguments:` parameter for named values |

## Review Checklist

- [ ] Using `WebPage` when any control beyond simple display is needed
- [ ] Both `SwiftUI` and `WebKit` are imported
- [ ] Navigation events observed for loading indicators and error handling
- [ ] JavaScript execution waits for page to finish loading
- [ ] Private browsing uses `.nonPersistent()` data store
- [ ] Navigation interception returns correct values (preferences to allow, nil to cancel)
- [ ] JavaScript arguments passed via `arguments:` parameter, not string interpolation
- [ ] Custom URL scheme handler registered on configuration before page loads
- [ ] Find-in-page enabled with `findNavigator(isPresented:)` if needed
- [ ] Appropriate gesture and interaction modifiers applied (back/forward, magnification, text selection)
- [ ] Content background customized if needed for visual integration

## Reference Files

| File | Contents |
|------|----------|
| `webview-basics.md` | WebView creation, WebPage setup, configuration, find-in-page, customization modifiers |
| `navigation.md` | Loading content, back/forward list, navigation events, NavigationDeciding protocol |
| `javascript-advanced.md` | JavaScript execution, content worlds, snapshots, PDF export, custom URL schemes |

## Cross-References

- For **macOS window management** around web views, see `macos/architecture-patterns/`
- For **navigation architecture** that hosts a web view, see `ios/navigation-patterns/`
- For **Liquid Glass** design around web content, see `design/liquid-glass/`

## References

- [WebView (SwiftUI)](https://developer.apple.com/documentation/swiftui/webview)
- [WebPage](https://developer.apple.com/documentation/webkit/webpage)
- [WKContentWorld](https://developer.apple.com/documentation/webkit/wkcontentworld)
- [WKSnapshotConfiguration](https://developer.apple.com/documentation/webkit/wksnapshotconfiguration)
