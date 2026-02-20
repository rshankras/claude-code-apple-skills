# WebView Basics

Creating web views, configuring WebPage, enabling find-in-page, and applying customization modifiers.

## WebView Creation

### URL-Based (Simplest)

For display-only scenarios where no programmatic control is needed:

```swift
import SwiftUI
import WebKit

struct SimpleWebView: View {
    var body: some View {
        WebView(url: URL(string: "https://example.com")!)
    }
}
```

### WebPage-Based (Full Control)

For any scenario requiring loading control, navigation, JavaScript, or event observation:

```swift
import SwiftUI
import WebKit

struct ControlledWebView: View {
    @State private var page = WebPage()

    var body: some View {
        WebView(page)
            .onAppear {
                page.load(URLRequest(url: URL(string: "https://example.com")!))
            }
    }
}
```

### When to Use Which

| Scenario | Approach |
|----------|----------|
| Static content display (about page, terms) | `WebView(url:)` |
| Need reload, back/forward | `WebPage` + `WebView(page)` |
| Need loading indicators | `WebPage` + `WebView(page)` |
| Need JavaScript execution | `WebPage` + `WebView(page)` |
| Need navigation interception | `WebPage` + `WebView(page)` |

## WebPage Configuration

Configure a `WebPage` with a `WebPage.Configuration` for advanced scenarios.

### Basic Configuration

```swift
var configuration = WebPage.Configuration()

// Allow JavaScript in loaded content
configuration.defaultNavigationPreferences.allowsContentJavaScript = true

// Load subresources (images, CSS, scripts)
configuration.loadsSubresources = true

let page = WebPage(configuration: configuration)
```

### Private Browsing

Use a non-persistent data store so no cookies, cache, or history are saved to disk:

```swift
var configuration = WebPage.Configuration()
configuration.websiteDataStore = .nonPersistent()

let page = WebPage(configuration: configuration)
```

### Custom User Agent

Override the user agent string sent with requests:

```swift
let page = WebPage()
page.customUserAgent = "MyApp/1.0 (iOS)"
```

### Full Configuration Example

```swift
struct ConfiguredBrowserView: View {
    @State private var page: WebPage

    init() {
        var configuration = WebPage.Configuration()
        configuration.defaultNavigationPreferences.allowsContentJavaScript = true
        configuration.loadsSubresources = true
        configuration.websiteDataStore = .nonPersistent()

        _page = State(initialValue: WebPage(configuration: configuration))
    }

    var body: some View {
        WebView(page)
            .onAppear {
                page.customUserAgent = "MyApp/1.0"
                page.load(URLRequest(url: URL(string: "https://example.com")!))
            }
    }
}
```

## Find in Page

Enable the built-in text search UI using `findNavigator`:

```swift
struct SearchableWebView: View {
    @State private var page = WebPage()
    @State private var isFindPresented = false

    var body: some View {
        WebView(page)
            .findNavigator(isPresented: $isFindPresented)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Find", systemImage: "magnifyingglass") {
                        isFindPresented.toggle()
                    }
                }
            }
            .onAppear {
                page.load(URLRequest(url: URL(string: "https://example.com")!))
            }
    }
}
```

## Customization Modifiers

Apply these modifiers to `WebView` to control interaction and appearance.

### Gestures

```swift
WebView(page)
    // Enable swipe left/right for back/forward navigation
    .webViewBackForwardNavigationGestures(.enabled)

    // Enable pinch-to-zoom
    .webViewMagnificationGestures(.enabled)
```

### Text and Links

```swift
WebView(page)
    // Enable text selection in web content
    .webViewTextSelection(.enabled)

    // Enable link preview on long press / force touch
    .webViewLinkPreviews(.enabled)
```

### Content Background

Override the web view background color to match your app's design:

```swift
WebView(page)
    .webViewContentBackground(.color(.systemBackground))
```

### Fullscreen Video

Allow elements (like video) to enter fullscreen mode:

```swift
WebView(page)
    .webViewElementFullscreenBehavior(.enabled)
```

### Context Menu

Customize the right-click / long-press context menu:

```swift
WebView(page)
    .webViewContextMenu { defaultActions in
        // Return modified actions or completely custom menu
        defaultActions
    }
```

### Combined Example

```swift
struct FullFeaturedWebView: View {
    @State private var page = WebPage()
    @State private var isFindPresented = false

    var body: some View {
        WebView(page)
            .webViewBackForwardNavigationGestures(.enabled)
            .webViewMagnificationGestures(.enabled)
            .webViewTextSelection(.enabled)
            .webViewLinkPreviews(.enabled)
            .webViewContentBackground(.color(.systemBackground))
            .webViewElementFullscreenBehavior(.enabled)
            .findNavigator(isPresented: $isFindPresented)
            .onAppear {
                page.load(URLRequest(url: URL(string: "https://example.com")!))
            }
    }
}
```

## Common Patterns

### WebView with Loading Indicator

```swift
struct WebViewWithLoading: View {
    @State private var page = WebPage()
    @State private var isLoading = true

    var body: some View {
        ZStack {
            WebView(page)

            if isLoading {
                ProgressView()
            }
        }
        .onChange(of: page.currentNavigationEvent) { _, event in
            switch event {
            case .started:
                isLoading = true
            case .finished, .failed:
                isLoading = false
            default:
                break
            }
        }
        .onAppear {
            page.load(URLRequest(url: URL(string: "https://example.com")!))
        }
    }
}
```

### Inline HTML Content

```swift
struct HTMLContentView: View {
    @State private var page = WebPage()

    let htmlContent = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { font-family: -apple-system; padding: 16px; }
                h1 { color: #333; }
            </style>
        </head>
        <body>
            <h1>Hello from SwiftUI</h1>
            <p>This is inline HTML content.</p>
        </body>
        </html>
        """

    var body: some View {
        WebView(page)
            .onAppear {
                page.load(
                    html: htmlContent,
                    baseURL: nil
                )
            }
    }
}
```

## Mistakes to Avoid

### Using WebView(url:) When Control Is Needed

```swift
// ❌ No way to reload, go back, or detect loading state
struct LimitedView: View {
    var body: some View {
        WebView(url: URL(string: "https://example.com")!)
    }
}

// ✅ Full control through WebPage
struct ControlledView: View {
    @State private var page = WebPage()

    var body: some View {
        WebView(page)
            .onAppear {
                page.load(URLRequest(url: URL(string: "https://example.com")!))
            }
    }
}
```

### Forgetting to Import WebKit

```swift
// ❌ WebView is in SwiftUI, but WebPage and configuration types require WebKit
import SwiftUI
// Missing: import WebKit

// ✅ Always import both
import SwiftUI
import WebKit
```

### Not Waiting for Load Before Interacting

```swift
// ❌ JavaScript may fail if page hasn't loaded
page.load(URLRequest(url: someURL))
try await page.callJavaScript("document.title")  // Page not ready

// ✅ Wait for navigation event to reach .finished
page.load(URLRequest(url: someURL))
// Observe currentNavigationEvent and call JavaScript after .finished
```

## Checklist

- [ ] Chosen correct WebView initializer (`url:` vs `page`)
- [ ] Imported both `SwiftUI` and `WebKit`
- [ ] Configured `WebPage.Configuration` before first load if needed
- [ ] Set `customUserAgent` if the server requires it
- [ ] Used `.nonPersistent()` data store for private browsing
- [ ] Applied appropriate customization modifiers
- [ ] Added `findNavigator` if text search is needed
- [ ] Loading indicator tied to `currentNavigationEvent`
