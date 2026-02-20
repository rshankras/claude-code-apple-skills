# JavaScript and Advanced Features

JavaScript execution, content worlds for isolation, snapshot capture, PDF export, web archives, and custom URL scheme handling.

## JavaScript Execution

Use `page.callJavaScript` to run scripts in loaded web content. The page must have finished loading before scripts can execute reliably.

### Basic Execution

```swift
// Execute a script and get the result
let title = try await page.callJavaScript("document.title") as? String

// Execute a script with no return value
try await page.callJavaScript("document.body.style.backgroundColor = 'lightblue'")
```

### Passing Arguments

Use the `arguments:` parameter to pass named values safely into the script. This avoids string interpolation and protects against injection:

```swift
// ❌ String interpolation -- vulnerable to injection
let script = "document.getElementById('\(elementId)').textContent = '\(newText)'"
try await page.callJavaScript(script)

// ✅ Named arguments -- safe, readable, debuggable
try await page.callJavaScript(
    "document.getElementById(elementId).textContent = newText",
    arguments: [
        "elementId": elementId,
        "newText": newText
    ]
)
```

Arguments are passed as a dictionary of `[String: Any]` where keys become variable names in the script scope.

### Executing in a Specific Frame

Target a specific frame (e.g., an iframe) rather than the main frame:

```swift
try await page.callJavaScript(
    "document.title",
    in: frameInfo  // A WKFrameInfo representing the target frame
)
```

### Content Worlds for Isolation

Use `WKContentWorld` to isolate your JavaScript from the page's scripts. This prevents naming collisions and provides security boundaries:

```swift
// Execute in the default page world (shares scope with page scripts)
try await page.callJavaScript("window.myVar", contentWorld: .page)

// Execute in the default client world (isolated from page scripts)
try await page.callJavaScript("window.myVar", contentWorld: .defaultClient)

// Execute in a custom named world (fully isolated namespace)
let appWorld = WKContentWorld.world(name: "myApp")
try await page.callJavaScript(
    "var myState = { count: 0 }; myState.count",
    contentWorld: appWorld
)
```

| Content World | Isolation | Use Case |
|---------------|-----------|----------|
| `.page` | None -- shares scope with page scripts | Reading page variables, interacting with page libraries |
| `.defaultClient` | Isolated from page scripts | General app-to-web communication |
| `.world(name:)` | Fully isolated namespace | Multiple independent script contexts |

### Complete JavaScript Example

```swift
import SwiftUI
import WebKit

struct JavaScriptDemoView: View {
    @State private var page = WebPage()
    @State private var extractedData = ""

    var body: some View {
        VStack {
            Text(extractedData)
                .font(.caption)
                .padding()

            WebView(page)
        }
        .onChange(of: page.currentNavigationEvent) { _, event in
            if case .finished = event {
                Task {
                    await extractPageData()
                }
            }
        }
        .onAppear {
            page.load(URLRequest(url: URL(string: "https://example.com")!))
        }
    }

    func extractPageData() async {
        do {
            // Get page title
            let title = try await page.callJavaScript("document.title") as? String ?? "Unknown"

            // Count links using named arguments for the tag name
            let linkCount = try await page.callJavaScript(
                "document.getElementsByTagName(tag).length",
                arguments: ["tag": "a"]
            ) as? Int ?? 0

            // Modify page appearance in an isolated world
            let appWorld = WKContentWorld.world(name: "myApp")
            try await page.callJavaScript(
                """
                document.querySelectorAll('a').forEach(function(link) {
                    link.style.color = color;
                });
                """,
                arguments: ["color": "blue"],
                contentWorld: appWorld
            )

            extractedData = "Title: \(title) | Links: \(linkCount)"
        } catch {
            extractedData = "JavaScript error: \(error.localizedDescription)"
        }
    }
}
```

## Snapshots

Capture the current web view content as an image.

```swift
import WebKit

// Basic snapshot
let image = try await page.snapshot(WKSnapshotConfiguration())

// Configured snapshot (specific rect, after screen updates)
var snapshotConfig = WKSnapshotConfiguration()
snapshotConfig.rect = CGRect(x: 0, y: 0, width: 400, height: 300)
snapshotConfig.afterScreenUpdates = true

let croppedImage = try await page.snapshot(snapshotConfig)
```

### Snapshot in SwiftUI

```swift
struct SnapshotView: View {
    @State private var page = WebPage()
    @State private var capturedImage: Image?

    var body: some View {
        VStack {
            if let capturedImage {
                capturedImage
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }

            WebView(page)

            Button("Capture Snapshot") {
                Task {
                    let snapshot = try await page.snapshot(WKSnapshotConfiguration())
                    capturedImage = snapshot
                }
            }
            .buttonStyle(.bordered)
        }
        .onAppear {
            page.load(URLRequest(url: URL(string: "https://example.com")!))
        }
    }
}
```

## PDF Export

Generate a PDF from the current web content.

```swift
import WebKit

// Basic PDF
let pdfData = try await page.pdf(configuration: WKPDFConfiguration())

// Configured PDF (specific print rect)
var pdfConfig = WKPDFConfiguration()
pdfConfig.rect = CGRect(x: 0, y: 0, width: 612, height: 792)  // US Letter size in points

let letterPDF = try await page.pdf(configuration: pdfConfig)
```

### Save PDF to File

```swift
struct PDFExportView: View {
    @State private var page = WebPage()
    @State private var showShareSheet = false
    @State private var pdfURL: URL?

    var body: some View {
        VStack {
            WebView(page)

            Button("Export PDF") {
                Task {
                    let pdfData = try await page.pdf(configuration: WKPDFConfiguration())

                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("export.pdf")
                    try pdfData.write(to: tempURL)

                    pdfURL = tempURL
                    showShareSheet = true
                }
            }
            .buttonStyle(.bordered)
        }
        .onAppear {
            page.load(URLRequest(url: URL(string: "https://example.com")!))
        }
    }
}
```

## Web Archives

Save the complete web page (HTML, CSS, images) as a web archive for offline viewing.

```swift
// Capture web archive data
let archiveData = try await page.webArchiveData()

// Save to file
let archiveURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("page.webarchive")
try archiveData.write(to: archiveURL)

// Load a web archive later
let savedData = try Data(contentsOf: archiveURL)
page.load(
    data: savedData,
    mimeType: "application/x-webarchive",
    characterEncoding: "utf-8",
    baseURL: nil
)
```

## Custom URL Scheme Handling

Intercept requests to custom URL schemes (e.g., `myapp://`) to serve local content or handle app-specific protocols.

### Define a URL Scheme Handler

```swift
import WebKit

class AppSchemeHandler: URLSchemeHandler {
    func webView(
        _ webView: WKWebView,
        start urlSchemeTask: any WKURLSchemeTask
    ) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        // Serve local content based on the URL path
        let path = url.path
        let responseHTML = """
            <html>
            <body>
                <h1>Local Content</h1>
                <p>Served for path: \(path)</p>
            </body>
            </html>
            """

        let data = Data(responseHTML.utf8)
        let response = URLResponse(
            url: url,
            mimeType: "text/html",
            expectedContentLength: data.count,
            textEncodingName: "utf-8"
        )

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(
        _ webView: WKWebView,
        stop urlSchemeTask: any WKURLSchemeTask
    ) {
        // Handle cancellation if needed
    }
}
```

### Register the Handler

Register the scheme handler on the configuration before creating the WebPage:

```swift
var configuration = WebPage.Configuration()
configuration.setURLSchemeHandler(
    AppSchemeHandler(),
    forURLScheme: "myapp"
)

let page = WebPage(configuration: configuration)

// Now URLs like "myapp://content/page1" will be handled by AppSchemeHandler
page.load(URLRequest(url: URL(string: "myapp://content/page1")!))
```

### Serving Bundle Resources

A common pattern is serving local files from the app bundle via a custom scheme:

```swift
class BundleSchemeHandler: URLSchemeHandler {
    func webView(
        _ webView: WKWebView,
        start urlSchemeTask: any WKURLSchemeTask
    ) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        // Map URL path to bundle resource
        let resourceName = url.lastPathComponent
        let resourceExtension = url.pathExtension

        guard let fileURL = Bundle.main.url(
            forResource: resourceName.replacingOccurrences(
                of: ".\(resourceExtension)", with: ""
            ),
            withExtension: resourceExtension
        ),
        let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let mimeType: String
        switch resourceExtension {
        case "html": mimeType = "text/html"
        case "css": mimeType = "text/css"
        case "js": mimeType = "application/javascript"
        case "png": mimeType = "image/png"
        case "jpg", "jpeg": mimeType = "image/jpeg"
        case "svg": mimeType = "image/svg+xml"
        default: mimeType = "application/octet-stream"
        }

        let response = URLResponse(
            url: url,
            mimeType: mimeType,
            expectedContentLength: data.count,
            textEncodingName: "utf-8"
        )

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(
        _ webView: WKWebView,
        stop urlSchemeTask: any WKURLSchemeTask
    ) {
        // No-op for synchronous responses
    }
}
```

## Mistakes to Avoid

### String Interpolation in JavaScript

```swift
// ❌ Injection risk and hard to debug
let userInput = "'; document.cookie; '"
try await page.callJavaScript("alert('\(userInput)')")

// ✅ Named arguments are escaped and type-safe
try await page.callJavaScript(
    "alert(message)",
    arguments: ["message": userInput]
)
```

### Running JavaScript Before Page Loads

```swift
// ❌ Page not ready -- script will fail or return unexpected results
page.load(URLRequest(url: someURL))
let title = try await page.callJavaScript("document.title")

// ✅ Wait for .finished navigation event before executing scripts
// (See navigation.md for the onChange pattern)
```

### Registering URL Scheme Handler After Creating WebPage

```swift
// ❌ Handler must be set on configuration BEFORE creating the page
let page = WebPage()
// Too late to register a scheme handler

// ✅ Register on configuration first, then create page
var configuration = WebPage.Configuration()
configuration.setURLSchemeHandler(handler, forURLScheme: "myapp")
let page = WebPage(configuration: configuration)
```

### Using .page Content World for Sensitive Scripts

```swift
// ❌ Page scripts can see and interfere with your variables
try await page.callJavaScript(
    "var apiKey = key",
    arguments: ["key": secretKey],
    contentWorld: .page  // Exposed to page scripts
)

// ✅ Use an isolated world for sensitive operations
let secureWorld = WKContentWorld.world(name: "secure")
try await page.callJavaScript(
    "var apiKey = key",
    arguments: ["key": secretKey],
    contentWorld: secureWorld  // Isolated from page scripts
)
```

## Checklist

- [ ] JavaScript arguments passed via `arguments:` parameter, not string interpolation
- [ ] Scripts execute only after page navigation reaches `.finished`
- [ ] Sensitive scripts use isolated `WKContentWorld`, not `.page`
- [ ] Snapshot configuration specifies rect if only partial capture is needed
- [ ] PDF configuration sets appropriate page size for the target use case
- [ ] Custom URL scheme handler registered on configuration before `WebPage` is created
- [ ] URL scheme handler calls `didFailWithError` for invalid requests
- [ ] URL scheme handler calls `didReceive` (response), `didReceive` (data), `didFinish` in order
- [ ] Error handling wraps all `callJavaScript` calls in do/catch or try?
