---
name: http-cache
description: Generates an HTTP caching layer with Cache-Control parsing, ETag/conditional requests, and offline fallback. Use when user wants to add response caching, offline support, or reduce API calls.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# HTTP Cache Generator

Generate a production HTTP caching layer that integrates with your existing networking code. Supports Cache-Control directives, ETag/Last-Modified conditional requests, stale-while-revalidate, and offline fallback.

## When This Skill Activates

Use this skill when the user:
- Asks to "add HTTP caching" or "cache API responses"
- Wants "offline support" or "offline fallback"
- Mentions "reduce API calls" or "cache network responses"
- Asks about "ETag" or "conditional requests" or "304 Not Modified"
- Wants "stale-while-revalidate" behavior

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Search for existing caching implementations
- [ ] Identify source file locations

### 2. Networking Layer Detection
Search for existing networking code:
```
Glob: **/*API*.swift, **/*Client*.swift, **/*Network*.swift
Grep: "APIClient" or "URLSession" or "HTTPURLResponse"
```

If `networking-layer` generator was used, detect the `APIClient` protocol and generate a decorator that wraps it.

### 3. Conflict Detection
Search for existing caching:
```
Glob: **/*Cache*.swift
Grep: "URLCache" or "ResponseCache" or "CachePolicy"
```

If found, ask user whether to replace or extend.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Cache storage sizes?**
   - Small (10 MB memory / 50 MB disk)
   - Medium (25 MB memory / 100 MB disk) — recommended
   - Large (50 MB memory / 250 MB disk)

2. **Caching strategy?**
   - Respect server Cache-Control headers (standard)
   - Cache-first with background revalidation (stale-while-revalidate)
   - Manual per-endpoint policies

3. **Offline support?**
   - Yes — serve stale cache when network unavailable
   - No — only cache while online

4. **Integration style?**
   - Decorator wrapping existing APIClient (recommended if networking-layer exists)
   - Standalone cache you call directly

## Generation Process

### Step 1: Read Templates
Read `http-cache-patterns.md` for architecture guidance.
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `HTTPCacheConfiguration.swift` — Memory/disk sizes, default policy
2. `CachePolicy.swift` — Per-endpoint enum (default, noCache, forceCache, cacheFirst)
3. `CacheControlHeader.swift` — Cache-Control header parser
4. `ConditionalRequestHandler.swift` — ETag/Last-Modified/304 handling
5. `HTTPResponseCache.swift` — Protocol + disk-backed response store

### Step 3: Create Integration Files
Based on configuration:
- `CachingAPIClient.swift` — Decorator wrapping existing APIClient (if decorator style)
- `NetworkReachability.swift` — NWPathMonitor wrapper (if offline support selected)

### Step 4: Determine File Location
Check project structure:
- If `Sources/Networking/` exists → `Sources/Networking/Cache/`
- If `App/Networking/` exists → `App/Networking/Cache/`
- If `Networking/` exists → `Networking/Cache/`
- Otherwise → `Cache/`

## Output Format

After generation, provide:

### Files Created
```
Networking/Cache/
├── HTTPCacheConfiguration.swift    # Memory/disk sizes, default policy
├── CachePolicy.swift               # Per-endpoint caching enum
├── CacheControlHeader.swift        # Cache-Control header parser
├── ConditionalRequestHandler.swift # ETag/Last-Modified/304
├── HTTPResponseCache.swift         # Protocol + disk implementation
├── CachingAPIClient.swift          # Decorator for existing APIClient
└── NetworkReachability.swift       # NWPathMonitor (optional)
```

### Integration Steps

**Wrap your existing client:**
```swift
let baseClient = URLSessionAPIClient(configuration: .production)
let cachingClient = CachingAPIClient(
    wrapping: baseClient,
    cache: DiskHTTPResponseCache(),
    configuration: .default
)

// Use cachingClient everywhere you used baseClient
let users = try await cachingClient.request(UsersEndpoint())
```

**Per-endpoint cache policy:**
```swift
struct UsersEndpoint: APIEndpoint, CacheConfigurable {
    var cachePolicy: CachePolicy { .cacheFirst(maxAge: 300) }
}

struct OrdersEndpoint: APIEndpoint, CacheConfigurable {
    var cachePolicy: CachePolicy { .noCache }
}
```

**With SwiftUI:**
```swift
struct UsersView: View {
    @Environment(\.apiClient) private var apiClient

    var body: some View {
        List(users) { user in
            Text(user.name)
        }
        .task {
            // Automatically uses cache if available
            users = try await apiClient.request(UsersEndpoint())
        }
    }
}
```

### Testing

```swift
@Test
func cachedResponseReturnedOnSecondRequest() async throws {
    let mockClient = MockAPIClient()
    let cache = InMemoryHTTPResponseCache()
    let cachingClient = CachingAPIClient(wrapping: mockClient, cache: cache)

    mockClient.mockResponse(for: UsersEndpoint.self, response: [.mock])

    // First request hits network
    let first = try await cachingClient.request(UsersEndpoint())
    #expect(mockClient.requestCount == 1)

    // Second request comes from cache
    let second = try await cachingClient.request(UsersEndpoint())
    #expect(mockClient.requestCount == 1) // No additional network call
    #expect(first == second)
}
```

## References

- **http-cache-patterns.md** — Cache-Control directives, ETag flow, stale-while-revalidate
- **templates.md** — All production Swift templates
- Related: `generators/networking-layer` — Base networking layer this decorates
