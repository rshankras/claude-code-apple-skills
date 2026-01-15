# API Design Checklist

Network and API patterns review for macOS and iOS applications.

## User-Agent Headers

### Why This Matters

User-Agent identifies your app to API servers. Spoofing (pretending to be a browser or another app) is:
- **Dishonest** - Misrepresents your app's identity
- **Risky** - Can get your app blocked when detected
- **Unprofessional** - Shows lack of engineering maturity

### ✅ Good Pattern
```swift
// Honest identification
let userAgent = "MyApp/1.2.0 (macOS 14.0; com.company.myapp)"

var request = URLRequest(url: url)
request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
```

### ❌ Anti-patterns
```swift
// Browser spoofing - NEVER do this
request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)...", forHTTPHeaderField: "User-Agent")

// Pretending to be official app
request.setValue("OfficialAPIClient/1.0", forHTTPHeaderField: "User-Agent")

// Empty or missing - also problematic
// (no User-Agent set at all)
```

### Checklist
- [ ] User-Agent honestly identifies your app
- [ ] Includes app name and version
- [ ] No browser or other app spoofing
- [ ] Consistent across all API calls

### Search Pattern
```
Grep: "User-Agent|userAgent|Mozilla|Chrome|Safari"
```

## Error Handling

### HTTP Status Codes

Handle all relevant status codes gracefully:

```swift
func handleResponse(_ response: HTTPURLResponse, data: Data) throws -> Data {
    switch response.statusCode {
    case 200...299:
        return data
    case 401:
        throw APIError.unauthorized("Session expired. Please re-authenticate.")
    case 403:
        throw APIError.forbidden("Access denied. Check your permissions.")
    case 404:
        throw APIError.notFound("Resource not found.")
    case 429:
        throw APIError.rateLimited("Too many requests. Please wait and try again.")
    case 500...599:
        throw APIError.serverError("Server error. Please try again later.")
    default:
        throw APIError.unknown("Unexpected error (HTTP \(response.statusCode)).")
    }
}
```

### User-Friendly Error Messages

#### ✅ Good Pattern
```swift
enum APIError: LocalizedError {
    case networkUnavailable
    case unauthorized(String)
    case rateLimited(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Unable to connect. Please check your internet connection."
        case .unauthorized(let message):
            return message
        case .rateLimited(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Try again when you have a stable connection."
        case .unauthorized:
            return "Sign out and sign back in to refresh your session."
        case .rateLimited:
            return "Wait a few minutes before making more requests."
        }
    }
}
```

#### ❌ Anti-patterns
```swift
// Technical jargon in user messages
throw NSError(domain: "HTTP", code: 401, userInfo: nil)

// Generic unhelpful messages
throw APIError.error("Something went wrong")

// Exposing internal details
throw APIError.error("JSON parsing failed at key 'data.user.id'")
```

### Checklist
- [ ] All HTTP status codes handled
- [ ] Error messages are user-friendly
- [ ] Error messages explain what to do
- [ ] No technical jargon in user-facing errors
- [ ] Errors logged for debugging (not shown to user)

## Token Expiration

### The Problem

API tokens expire. If not handled, users experience silent failures or confusing errors.

### ✅ Good Pattern
```swift
class APIClient {
    private var tokenExpiresAt: Date?

    func makeRequest() async throws -> Data {
        // Check expiration before request
        if let expiresAt = tokenExpiresAt, Date() >= expiresAt {
            throw APIError.tokenExpired("Your session has expired. Please restart the app to refresh.")
        }

        // Make request...
        let (data, response) = try await session.data(for: request)

        // Handle 401 from server (token revoked or expired early)
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            throw APIError.tokenExpired("Your session has expired. Please restart the app to refresh.")
        }

        return data
    }

    func refreshTokenIfNeeded() async throws {
        guard let expiresAt = tokenExpiresAt else { return }

        // Refresh proactively when close to expiration
        let refreshThreshold: TimeInterval = 300 // 5 minutes
        if Date().addingTimeInterval(refreshThreshold) >= expiresAt {
            try await refreshToken()
        }
    }
}
```

### Token Refresh Flow
```swift
// Option 1: Automatic refresh
func refreshToken() async throws {
    let newToken = try await authService.refreshToken()
    self.token = newToken.accessToken
    self.tokenExpiresAt = newToken.expiresAt
}

// Option 2: Notify user to re-authenticate
NotificationCenter.default.post(
    name: .tokenExpired,
    object: nil,
    userInfo: ["message": "Please sign in again to continue."]
)
```

### Checklist
- [ ] Token expiration time tracked
- [ ] Expiration checked before requests
- [ ] 401 responses handled as potential expiration
- [ ] User notified with clear action when token expires
- [ ] Proactive refresh implemented (if supported by API)

## Rate Limiting

### Handling 429 Responses

```swift
func makeRequestWithRetry(maxRetries: Int = 3) async throws -> Data {
    var lastError: Error?

    for attempt in 0..<maxRetries {
        do {
            return try await makeRequest()
        } catch APIError.rateLimited {
            lastError = APIError.rateLimited("Rate limited")

            // Exponential backoff
            let delay = pow(2.0, Double(attempt)) // 1s, 2s, 4s
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }

    throw lastError ?? APIError.unknown("Request failed after retries")
}
```

### Respect Retry-After Header
```swift
if response.statusCode == 429 {
    if let retryAfter = response.value(forHTTPHeaderField: "Retry-After"),
       let seconds = Int(retryAfter) {
        throw APIError.rateLimited("Please wait \(seconds) seconds before trying again.")
    }
}
```

### Checklist
- [ ] 429 status code handled
- [ ] Retry-After header respected
- [ ] Exponential backoff implemented
- [ ] User informed when rate limited
- [ ] Request queuing for high-volume operations

## Timeout Configuration

### Guidelines

- **Short timeouts** for user-initiated actions (10-30 seconds)
- **Longer timeouts** for background operations (60-120 seconds)
- **Very short timeouts** for connectivity checks (5 seconds)

```swift
// User-initiated request
var request = URLRequest(url: url)
request.timeoutInterval = 30

// Background sync
let config = URLSessionConfiguration.background(withIdentifier: "sync")
config.timeoutIntervalForRequest = 60
config.timeoutIntervalForResource = 300

// Connectivity check
var pingRequest = URLRequest(url: healthCheckURL)
pingRequest.timeoutInterval = 5
```

### Checklist
- [ ] Appropriate timeouts for each request type
- [ ] Timeout errors show user-friendly message
- [ ] Long operations use background session
- [ ] No infinite timeouts

## Offline Handling

### Network Reachability

```swift
import Network

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    @Published var isConnected = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
}
```

### Graceful Degradation

```swift
func fetchData() async throws -> [Item] {
    if !networkMonitor.isConnected {
        // Return cached data when offline
        if let cached = cache.loadItems() {
            return cached
        }
        throw APIError.networkUnavailable
    }

    // Fetch fresh data
    let items = try await api.fetchItems()
    cache.saveItems(items)
    return items
}
```

### Checklist
- [ ] Network connectivity monitored
- [ ] Offline state shown to user
- [ ] Cached data available offline (if applicable)
- [ ] Auto-retry when connection restored
- [ ] No silent failures when offline

## Request/Response Logging

### Debug Logging (Development Only)

```swift
#if DEBUG
func logRequest(_ request: URLRequest) {
    print("📤 \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
}

func logResponse(_ response: HTTPURLResponse, data: Data) {
    print("📥 \(response.statusCode) (\(data.count) bytes)")
}
#endif
```

### ❌ Anti-patterns
```swift
// NEVER log sensitive data
print("Token: \(apiToken)")  // Security risk!
print("Request body: \(String(data: body, encoding: .utf8))")  // May contain PII

// NEVER log in production
func makeRequest() {
    print("Making request...")  // Should be #if DEBUG
}
```

### Checklist
- [ ] Request/response logging only in DEBUG
- [ ] No sensitive data in logs (tokens, passwords, PII)
- [ ] No production logging of request bodies
- [ ] Structured logging for debugging

## Caching Strategy

### HTTP Caching

```swift
// Respect cache headers
let config = URLSessionConfiguration.default
config.requestCachePolicy = .useProtocolCachePolicy

// Custom cache for specific needs
let cache = URLCache(
    memoryCapacity: 10 * 1024 * 1024,  // 10 MB
    diskCapacity: 50 * 1024 * 1024,     // 50 MB
    diskPath: "api_cache"
)
config.urlCache = cache
```

### Application-Level Caching

```swift
actor APICache {
    private var cache: [String: (data: Data, timestamp: Date)] = [:]
    private let maxAge: TimeInterval = 300  // 5 minutes

    func get(_ key: String) -> Data? {
        guard let entry = cache[key] else { return nil }
        if Date().timeIntervalSince(entry.timestamp) > maxAge {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }

    func set(_ key: String, data: Data) {
        cache[key] = (data, Date())
    }
}
```

### Checklist
- [ ] Caching strategy defined
- [ ] Cache invalidation implemented
- [ ] Stale data handling defined
- [ ] Cache size limits set

## API Versioning

### Handling API Changes

```swift
struct APIClient {
    static let apiVersion = "v1"
    static let baseURL = "https://api.example.com/\(apiVersion)"

    // Check minimum supported version
    func checkAPICompatibility() async throws {
        let serverVersion = try await fetchServerVersion()
        if serverVersion < minimumSupportedVersion {
            throw APIError.updateRequired("Please update the app to continue using this feature.")
        }
    }
}
```

### Checklist
- [ ] API version included in requests
- [ ] Graceful handling of deprecated endpoints
- [ ] User prompted to update when API incompatible
- [ ] Fallback behavior for missing features

## Search Patterns

```
// Find potential API issues
Grep: "URLRequest|URLSession"
Grep: "User-Agent|userAgent"
Grep: "401|403|429|500"
Grep: "timeout|Timeout"
Grep: "print.*request|print.*response|NSLog.*API"
```

## References

- [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system)
- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)
- [Network Framework](https://developer.apple.com/documentation/network)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
