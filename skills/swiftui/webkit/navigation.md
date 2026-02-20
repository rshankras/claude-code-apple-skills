# Navigation

Loading content, managing back/forward history, observing navigation events, and intercepting navigation with the `NavigationDeciding` protocol.

## Loading Content

WebPage supports three loading methods depending on the content source.

### Load a URL

```swift
let page = WebPage()

// Load from URL request
page.load(URLRequest(url: URL(string: "https://example.com")!))
```

### Load HTML String

```swift
let page = WebPage()

page.load(
    html: "<h1>Hello</h1><p>Rendered from a string.</p>",
    baseURL: URL(string: "https://example.com")  // Resolves relative URLs
)
```

### Load Raw Data

```swift
let page = WebPage()

let pdfData: Data = ...  // e.g., fetched from network or bundled file
page.load(
    data: pdfData,
    mimeType: "application/pdf",
    characterEncoding: "utf-8",
    baseURL: URL(string: "https://example.com")
)
```

### Reload and Stop

```swift
// Reload current page
page.reload()

// Reload bypassing cache (fetch fresh from origin)
page.reload(fromOrigin: true)

// Cancel an in-progress load
page.stopLoading()
```

## Back/Forward Navigation

WebPage maintains a back/forward list automatically as the user navigates.

### Reading the History

```swift
// Items the user can go back to
let backItems = page.backForwardList.backList

// Items the user can go forward to (after going back)
let forwardItems = page.backForwardList.forwardList

// Current item
let currentItem = page.backForwardList.currentItem
```

### Navigating the History

```swift
// Go back to a specific item
if let backItem = page.backForwardList.backList.last {
    page.load(backItem)
}
```

### Browser Toolbar Example

```swift
struct BrowserToolbar: View {
    let page: WebPage

    var body: some View {
        HStack(spacing: 16) {
            Button {
                if let backItem = page.backForwardList.backList.last {
                    page.load(backItem)
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(page.backForwardList.backList.isEmpty)

            Button {
                if let forwardItem = page.backForwardList.forwardList.first {
                    page.load(forwardItem)
                }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(page.backForwardList.forwardList.isEmpty)

            Button {
                page.reload()
            } label: {
                Image(systemName: "arrow.clockwise")
            }

            Spacer()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}
```

## Navigation Events

Observe `page.currentNavigationEvent` to track loading state and detect errors.

### Event States

| State | Meaning |
|-------|---------|
| `.started` | Navigation has begun; show loading indicator |
| `.finished` | Content loaded successfully; hide loading indicator |
| `.failed` | Navigation failed (network error, invalid URL, etc.) |

### Observing Events

```swift
struct WebBrowserView: View {
    @State private var page = WebPage()
    @State private var isLoading = false
    @State private var loadError: Error?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            }

            if let error = loadError {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "wifi.exclamationmark",
                    description: Text(error.localizedDescription)
                )
            }

            WebView(page)
        }
        .onChange(of: page.currentNavigationEvent) { _, event in
            switch event {
            case .started:
                isLoading = true
                loadError = nil
            case .finished:
                isLoading = false
            case .failed:
                isLoading = false
                // Handle the failure in your UI
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

### Waiting for Load Completion

When you need to perform an action (like JavaScript execution) after the page finishes loading, observe the navigation event:

```swift
struct ScriptAfterLoadView: View {
    @State private var page = WebPage()
    @State private var pageTitle = ""

    var body: some View {
        VStack {
            Text(pageTitle)
                .font(.headline)
            WebView(page)
        }
        .onChange(of: page.currentNavigationEvent) { _, event in
            if case .finished = event {
                Task {
                    if let title = try? await page.callJavaScript("document.title") as? String {
                        pageTitle = title
                    }
                }
            }
        }
        .onAppear {
            page.load(URLRequest(url: URL(string: "https://example.com")!))
        }
    }
}
```

## NavigationDeciding Protocol

Implement `NavigationDeciding` to intercept and control navigation decisions. This lets you allow, modify, or cancel navigations before they happen.

### Protocol Methods

The protocol defines two decision points:

1. **`decidePolicyFor(navigationAction:)`** -- Called before a request is sent. Return `NavigationPreferences` to allow, or `nil` to cancel.
2. **`decidePolicyFor(navigationResponse:)`** -- Called after a response is received but before content is displayed. Return `true` to allow, `false` to cancel.

### Basic Implementation

```swift
import WebKit

struct MyNavigationDelegate: NavigationDeciding {
    /// Decide whether to allow a navigation action (before request is sent)
    func decidePolicyFor(navigationAction: NavigationAction) -> NavigationPreferences? {
        // Allow all navigations with default preferences
        return NavigationPreferences()
    }

    /// Decide whether to display the response (after response is received)
    func decidePolicyFor(navigationResponse: NavigationResponse) -> Bool {
        // Allow all responses
        return true
    }
}
```

### Filtering by Domain

Block navigation to external domains, keeping the user within allowed sites:

```swift
struct DomainFilterDelegate: NavigationDeciding {
    let allowedDomains: Set<String>

    func decidePolicyFor(navigationAction: NavigationAction) -> NavigationPreferences? {
        guard let host = navigationAction.request.url?.host else {
            return nil  // Cancel if no host
        }

        if allowedDomains.contains(host) {
            return NavigationPreferences()  // Allow
        }

        return nil  // Cancel -- domain not allowed
    }

    func decidePolicyFor(navigationResponse: NavigationResponse) -> Bool {
        return true
    }
}
```

### Opening External Links in System Browser

Intercept links that should open outside the app:

```swift
import SwiftUI
import WebKit

struct ExternalLinkDelegate: NavigationDeciding {
    let internalHost: String
    @Environment(\.openURL) private var openURL

    func decidePolicyFor(navigationAction: NavigationAction) -> NavigationPreferences? {
        guard let url = navigationAction.request.url,
              let host = url.host else {
            return NavigationPreferences()
        }

        if host == internalHost {
            return NavigationPreferences()  // Allow internal navigation
        }

        // Open external links in the system browser
        openURL(url)
        return nil  // Cancel in-app navigation
    }

    func decidePolicyFor(navigationResponse: NavigationResponse) -> Bool {
        return true
    }
}
```

### Controlling JavaScript per Navigation

```swift
struct JavaScriptControlDelegate: NavigationDeciding {
    let trustedDomains: Set<String>

    func decidePolicyFor(navigationAction: NavigationAction) -> NavigationPreferences? {
        var preferences = NavigationPreferences()

        if let host = navigationAction.request.url?.host,
           trustedDomains.contains(host) {
            preferences.allowsContentJavaScript = true
        } else {
            preferences.allowsContentJavaScript = false
        }

        return preferences
    }

    func decidePolicyFor(navigationResponse: NavigationResponse) -> Bool {
        return true
    }
}
```

## Complete Browser Example

A full browser view with address bar, back/forward, reload, and loading state:

```swift
import SwiftUI
import WebKit

struct MiniBrowser: View {
    @State private var page = WebPage()
    @State private var urlText = "https://developer.apple.com"
    @State private var isLoading = false
    @State private var isFindPresented = false

    var body: some View {
        VStack(spacing: 0) {
            // Address bar
            HStack {
                Button {
                    if let item = page.backForwardList.backList.last {
                        page.load(item)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(page.backForwardList.backList.isEmpty)

                Button {
                    if let item = page.backForwardList.forwardList.first {
                        page.load(item)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(page.backForwardList.forwardList.isEmpty)

                TextField("URL", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        loadURL()
                    }

                if isLoading {
                    Button {
                        page.stopLoading()
                    } label: {
                        Image(systemName: "xmark")
                    }
                } else {
                    Button {
                        page.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .padding()
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Web content
            WebView(page)
                .webViewBackForwardNavigationGestures(.enabled)
                .webViewTextSelection(.enabled)
                .findNavigator(isPresented: $isFindPresented)
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
            loadURL()
        }
    }

    private func loadURL() {
        guard let url = URL(string: urlText) else { return }
        page.load(URLRequest(url: url))
    }
}
```

## Mistakes to Avoid

### Not Observing Navigation Events

```swift
// ❌ No feedback to user about loading state or errors
struct SilentWebView: View {
    @State private var page = WebPage()

    var body: some View {
        WebView(page)
            .onAppear {
                page.load(URLRequest(url: URL(string: "https://example.com")!))
            }
    }
}

// ✅ Observe events for loading state and error handling
struct ObservantWebView: View {
    @State private var page = WebPage()
    @State private var isLoading = false

    var body: some View {
        ZStack {
            WebView(page)
            if isLoading { ProgressView() }
        }
        .onChange(of: page.currentNavigationEvent) { _, event in
            isLoading = (event == .started)
        }
        .onAppear {
            page.load(URLRequest(url: URL(string: "https://example.com")!))
        }
    }
}
```

### Returning Wrong Values from NavigationDeciding

```swift
// ❌ Returning NavigationPreferences() when you want to cancel
func decidePolicyFor(navigationAction: NavigationAction) -> NavigationPreferences? {
    if shouldBlock(navigationAction) {
        return NavigationPreferences()  // Wrong -- this ALLOWS the navigation
    }
    return nil
}

// ✅ Return nil to cancel, NavigationPreferences to allow
func decidePolicyFor(navigationAction: NavigationAction) -> NavigationPreferences? {
    if shouldBlock(navigationAction) {
        return nil  // Correct -- cancels the navigation
    }
    return NavigationPreferences()  // Allow
}
```

## Checklist

- [ ] Loading state tracked via `currentNavigationEvent`
- [ ] Error state handled for `.failed` navigation events
- [ ] Back/forward buttons disabled when history list is empty
- [ ] `NavigationDeciding` used if navigation filtering is needed
- [ ] `decidePolicyFor(navigationAction:)` returns `nil` to cancel, `NavigationPreferences` to allow
- [ ] `decidePolicyFor(navigationResponse:)` returns `false` to cancel, `true` to allow
- [ ] `reload(fromOrigin: true)` used when cache bypass is needed
- [ ] External links handled appropriately (in-app vs system browser)
