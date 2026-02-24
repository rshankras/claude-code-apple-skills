# HTTP Cache Patterns and Best Practices

## Why Not Just URLCache?

`URLCache` works for basic scenarios but has limitations:

1. **No per-endpoint control** — Can't cache `/users` for 5 min and skip `/orders`
2. **Server must cooperate** — Requires proper Cache-Control headers from server
3. **No stale-while-revalidate** — Can't serve stale data while refreshing
4. **No offline fallback** — Doesn't serve expired cache when offline
5. **Opaque storage** — Hard to inspect, clear selectively, or migrate

This generator creates a transparent caching layer you control.

## Cache-Control Directives

### Standard Directives

| Directive | Meaning |
|-----------|---------|
| `max-age=N` | Response valid for N seconds |
| `no-cache` | Must revalidate before using cached copy |
| `no-store` | Never cache this response |
| `private` | Only cache in user's device, not shared proxies |
| `public` | May be cached by any cache |
| `must-revalidate` | Must check server when stale |
| `stale-while-revalidate=N` | May serve stale for N seconds while refreshing |
| `immutable` | Content will never change (versioned URLs) |

### Parsing Example

```
Cache-Control: public, max-age=300, stale-while-revalidate=60
```

Means: cache for 5 minutes, then serve stale for 1 more minute while refreshing in background.

### How Cache-Control Maps to Behavior

```
Request arrives
├── Has cached response?
│   ├── No → Fetch from network, cache if cacheable
│   └── Yes → Check freshness
│       ├── Fresh (within max-age) → Return cached
│       ├── Stale but within stale-while-revalidate
│       │   ├── Return cached immediately
│       │   └── Background: revalidate and update cache
│       └── Stale beyond tolerance
│           ├── Has ETag/Last-Modified? → Conditional request (If-None-Match / If-Modified-Since)
│           │   ├── 304 Not Modified → Return cached, refresh expiry
│           │   └── 200 → Return new, update cache
│           └── No validators → Fetch fresh
```

## ETag / Conditional Request Flow

### How It Works

1. Server sends `ETag: "abc123"` (or `Last-Modified: <date>`) with response
2. Client stores ETag alongside cached data
3. On next request, client sends `If-None-Match: "abc123"`
4. Server responds:
   - `304 Not Modified` — cached data is still valid, no body transferred
   - `200 OK` — new data, update cache

### Benefits

- **Bandwidth savings** — 304 responses have no body
- **Freshness guarantee** — Server confirms data hasn't changed
- **Works with no-cache** — Even `no-cache` responses use conditional requests

### Implementation Pattern

```swift
// Store ETag when caching
struct CachedResponse {
    let data: Data
    let etag: String?
    let lastModified: String?
    let cachedAt: Date
    let maxAge: TimeInterval?
}

// Send conditional headers on revalidation
func conditionalHeaders(for cached: CachedResponse) -> [String: String] {
    var headers: [String: String] = [:]
    if let etag = cached.etag {
        headers["If-None-Match"] = etag
    }
    if let lastModified = cached.lastModified {
        headers["If-Modified-Since"] = lastModified
    }
    return headers
}
```

## Stale-While-Revalidate Pattern

Best UX pattern for frequently accessed data:

1. Return stale cached data **immediately** (no loading spinner)
2. Fetch fresh data in background
3. Update cache and notify UI when fresh data arrives

```swift
// Conceptual flow
func requestWithSWR<T>(_ endpoint: Endpoint) async throws -> T {
    if let cached = cache.get(endpoint.cacheKey), cached.isStale, cached.withinSWRWindow {
        // Return stale immediately
        Task { await revalidateInBackground(endpoint) }
        return cached.value
    }
    // ... normal fetch
}
```

### When to Use Stale-While-Revalidate

| Use Case | SWR? | Why |
|----------|------|-----|
| User profile | ✅ | Data changes rarely, stale is fine |
| Feed/timeline | ✅ | Show last known, refresh in background |
| Shopping cart | ❌ | Must be accurate |
| Payment status | ❌ | Must be real-time |
| Config/settings | ✅ | Changes rarely, stale is fine briefly |

## Offline Fallback Strategy

### Network Reachability

Use `NWPathMonitor` (Network framework) — not `Reachability` third-party library:

```swift
import Network

actor NetworkReachability {
    private let monitor = NWPathMonitor()
    private(set) var isConnected = true

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { await self?.update(path.status == .satisfied) }
        }
        monitor.start(queue: DispatchQueue(label: "network.monitor"))
    }

    private func update(_ connected: Bool) {
        isConnected = connected
    }
}
```

### Offline Decision Tree

```
Network unavailable
├── Has cached response (even expired)?
│   ├── Yes → Return cached + flag as stale
│   └── No → Throw NetworkError.offline
```

### Stale Indicator for UI

```swift
struct CacheResult<T> {
    let value: T
    let source: CacheSource

    enum CacheSource {
        case network         // Fresh from server
        case cache           // Within max-age
        case staleCache      // Expired but served offline/SWR
    }

    var isStale: Bool { source == .staleCache }
}
```

## Cache Key Design

### Good Cache Keys

Include everything that makes the response unique:

```swift
func cacheKey(for request: URLRequest) -> String {
    var components = [request.httpMethod ?? "GET", request.url?.absoluteString ?? ""]

    // Include relevant headers that affect response
    if let accept = request.value(forHTTPHeaderField: "Accept") {
        components.append("accept:\(accept)")
    }

    return components.joined(separator: "|")
}
```

### Don't Include

- Auth tokens (same endpoint, different users = same cache)
- Timestamps or request IDs
- Transient headers (User-Agent, etc.)

**Exception:** If different users get different responses from the same endpoint, include a user identifier in the cache key.

## Disk Cache with LRU Eviction

### File-Based Storage

```
CachesDirectory/
└── HTTPCache/
    ├── manifest.json       # Index of cached entries
    └── responses/
        ├── abc123.data     # Response body
        └── abc123.meta     # Headers, ETag, expiry
```

### LRU Eviction

When disk cache exceeds size limit:
1. Sort entries by last access time
2. Remove oldest entries until under limit
3. Remove both `.data` and `.meta` files

### Size Calculation

```swift
func currentDiskUsage() -> Int {
    let fileManager = FileManager.default
    guard let contents = try? fileManager.contentsOfDirectory(
        at: cacheDirectory,
        includingPropertiesForKeys: [.fileSizeKey]
    ) else { return 0 }

    return contents.reduce(0) { total, url in
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        return total + size
    }
}
```

## Decorator Pattern for Integration

### Why a Decorator?

The `CachingAPIClient` wraps any `APIClient` conformance without modifying it:

```swift
// Before: direct client
let client: APIClient = URLSessionAPIClient(config: .production)

// After: cached client (same interface)
let client: APIClient = CachingAPIClient(
    wrapping: URLSessionAPIClient(config: .production),
    cache: DiskHTTPResponseCache()
)
```

- Existing code doesn't change
- Cache can be added/removed without touching call sites
- Easy to test: wrap a MockAPIClient with caching

### Endpoint Cache Configuration

Endpoints opt into caching via protocol conformance:

```swift
protocol CacheConfigurable {
    var cachePolicy: CachePolicy { get }
}

// Endpoints that don't conform use the default policy
extension APIEndpoint {
    var cachePolicy: CachePolicy {
        (self as? CacheConfigurable)?.cachePolicy ?? .default
    }
}
```

## Anti-Patterns to Avoid

### Don't Cache Mutations
```swift
// ❌ Never cache POST/PUT/DELETE responses
// ✅ Only cache GET (and optionally HEAD) requests
```

### Don't Cache Auth-Dependent Without User Key
```swift
// ❌ Cache /api/me across users
// ✅ Include user ID in cache key for personalized endpoints
```

### Don't Ignore Cache-Control: no-store
```swift
// ❌ Cache everything regardless of server headers
// ✅ Respect no-store — the server says this data must not be persisted
```

### Don't Use In-Memory Only
```swift
// ❌ NSCache alone — cleared on memory pressure, lost on app restart
// ✅ Disk cache with memory layer for fast access
```

## Testing Caches

### Test Cache Hit/Miss
```swift
@Test func cacheHitAvoidNetworkCall() async throws {
    let mock = MockAPIClient()
    let cache = InMemoryHTTPResponseCache()
    let client = CachingAPIClient(wrapping: mock, cache: cache)

    mock.mockResponse(for: UsersEndpoint.self, response: [.mock])

    _ = try await client.request(UsersEndpoint())
    _ = try await client.request(UsersEndpoint())

    #expect(mock.requestCount(for: UsersEndpoint.self) == 1)
}
```

### Test Cache Expiry
```swift
@Test func expiredCacheRefetches() async throws {
    let cache = InMemoryHTTPResponseCache()
    // Pre-populate with expired entry
    cache.store(key: "GET|/users", data: oldData, maxAge: -1)

    let mock = MockAPIClient()
    let client = CachingAPIClient(wrapping: mock, cache: cache)

    _ = try await client.request(UsersEndpoint())
    #expect(mock.requestCount(for: UsersEndpoint.self) == 1) // Had to fetch
}
```

### Test Offline Fallback
```swift
@Test func offlineServesStaleCache() async throws {
    let cache = InMemoryHTTPResponseCache()
    cache.store(key: "GET|/users", data: staleData, maxAge: -1)

    let mock = MockAPIClient()
    mock.mockError(for: UsersEndpoint.self, error: NetworkError.networkUnavailable)

    let client = CachingAPIClient(wrapping: mock, cache: cache, offlineEnabled: true)

    let result = try await client.request(UsersEndpoint())
    #expect(result == staleData.decoded()) // Served stale
}
```
