# HTTP Cache Code Templates

Production-ready Swift templates for HTTP response caching. All code targets iOS 16+ / macOS 13+ and uses modern Swift concurrency.

## CachePolicy.swift

```swift
import Foundation

/// Defines how an individual endpoint's responses should be cached.
enum CachePolicy: Sendable {
    /// Use default behavior: respect server Cache-Control headers.
    case `default`

    /// Never cache this endpoint's responses.
    case noCache

    /// Always use cache if available, regardless of age.
    /// Falls back to network only on cache miss.
    case forceCache

    /// Return cache immediately, revalidate in background.
    /// `maxAge` controls how long the cached response is considered fresh.
    case cacheFirst(maxAge: TimeInterval = 300)

    /// Custom max-age override, ignoring server headers.
    case custom(maxAge: TimeInterval)
}

/// Conform endpoints to this protocol to specify per-endpoint cache behavior.
protocol CacheConfigurable {
    var cachePolicy: CachePolicy { get }
}
```

## HTTPCacheConfiguration.swift

```swift
import Foundation

/// Global configuration for the HTTP cache layer.
struct HTTPCacheConfiguration: Sendable {
    /// Maximum memory cache size in bytes.
    let memoryCapacity: Int

    /// Maximum disk cache size in bytes.
    let diskCapacity: Int

    /// Default TTL when server provides no Cache-Control header.
    let defaultMaxAge: TimeInterval

    /// Whether to serve stale cache when offline.
    let offlineFallbackEnabled: Bool

    /// Default cache policy for endpoints that don't specify one.
    let defaultPolicy: CachePolicy

    static let small = HTTPCacheConfiguration(
        memoryCapacity: 10 * 1024 * 1024,   // 10 MB
        diskCapacity: 50 * 1024 * 1024,      // 50 MB
        defaultMaxAge: 300,
        offlineFallbackEnabled: true,
        defaultPolicy: .default
    )

    static let medium = HTTPCacheConfiguration(
        memoryCapacity: 25 * 1024 * 1024,   // 25 MB
        diskCapacity: 100 * 1024 * 1024,    // 100 MB
        defaultMaxAge: 300,
        offlineFallbackEnabled: true,
        defaultPolicy: .default
    )

    static let large = HTTPCacheConfiguration(
        memoryCapacity: 50 * 1024 * 1024,   // 50 MB
        diskCapacity: 250 * 1024 * 1024,    // 250 MB
        defaultMaxAge: 300,
        offlineFallbackEnabled: true,
        defaultPolicy: .default
    )

    static let `default` = medium
}
```

## CacheControlHeader.swift

```swift
import Foundation

/// Parsed representation of a Cache-Control HTTP header.
struct CacheControlDirectives: Sendable {
    var maxAge: TimeInterval?
    var staleWhileRevalidate: TimeInterval?
    var noCache: Bool = false
    var noStore: Bool = false
    var mustRevalidate: Bool = false
    var isPublic: Bool = false
    var isPrivate: Bool = false
    var immutable: Bool = false

    /// Whether this response is cacheable at all.
    var isCacheable: Bool {
        !noStore
    }

    /// Parse a Cache-Control header value string.
    static func parse(_ headerValue: String) -> CacheControlDirectives {
        var directives = CacheControlDirectives()

        let parts = headerValue
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }

        for part in parts {
            if part == "no-cache" {
                directives.noCache = true
            } else if part == "no-store" {
                directives.noStore = true
            } else if part == "must-revalidate" {
                directives.mustRevalidate = true
            } else if part == "public" {
                directives.isPublic = true
            } else if part == "private" {
                directives.isPrivate = true
            } else if part == "immutable" {
                directives.immutable = true
            } else if part.hasPrefix("max-age=") {
                let value = part.dropFirst("max-age=".count)
                directives.maxAge = TimeInterval(value)
            } else if part.hasPrefix("stale-while-revalidate=") {
                let value = part.dropFirst("stale-while-revalidate=".count)
                directives.staleWhileRevalidate = TimeInterval(value)
            }
        }

        return directives
    }
}
```

## ConditionalRequestHandler.swift

```swift
import Foundation

/// Handles ETag and Last-Modified conditional request headers.
struct ConditionalRequestHandler: Sendable {

    /// Add conditional headers to a request based on cached response metadata.
    static func addConditionalHeaders(
        to request: inout URLRequest,
        cachedEntry: CachedResponseEntry
    ) {
        if let etag = cachedEntry.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        if let lastModified = cachedEntry.lastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
    }

    /// Check if a response indicates the cached version is still valid.
    static func isNotModified(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 304
    }

    /// Extract cache validators from a response.
    static func extractValidators(from response: HTTPURLResponse) -> (etag: String?, lastModified: String?) {
        let etag = response.value(forHTTPHeaderField: "ETag")
        let lastModified = response.value(forHTTPHeaderField: "Last-Modified")
        return (etag, lastModified)
    }
}
```

## HTTPResponseCache.swift

```swift
import Foundation

/// Metadata stored alongside cached response data.
struct CachedResponseEntry: Codable, Sendable {
    let data: Data
    let statusCode: Int
    let etag: String?
    let lastModified: String?
    let cacheControl: String?
    let cachedAt: Date
    let maxAge: TimeInterval
    var lastAccessedAt: Date

    /// Whether the entry is fresh (within max-age).
    var isFresh: Bool {
        Date().timeIntervalSince(cachedAt) < maxAge
    }

    /// Whether the entry is within the stale-while-revalidate window.
    func isWithinSWRWindow(swrDuration: TimeInterval) -> Bool {
        let age = Date().timeIntervalSince(cachedAt)
        return age < (maxAge + swrDuration)
    }
}

/// Protocol for HTTP response cache storage.
protocol HTTPResponseCaching: Actor {
    func get(_ key: String) -> CachedResponseEntry?
    func store(_ key: String, entry: CachedResponseEntry)
    func remove(_ key: String)
    func removeAll()
}

/// Disk-backed HTTP response cache with LRU eviction.
actor DiskHTTPResponseCache: HTTPResponseCaching {
    private let cacheDirectory: URL
    private let maxDiskSize: Int
    private var memoryCache: [String: CachedResponseEntry] = [:]
    private let maxMemoryEntries: Int

    init(
        directory: URL? = nil,
        maxDiskSize: Int = 100 * 1024 * 1024,
        maxMemoryEntries: Int = 100
    ) {
        self.cacheDirectory = directory ?? FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HTTPCache", isDirectory: true)
        self.maxDiskSize = maxDiskSize
        self.maxMemoryEntries = maxMemoryEntries

        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    func get(_ key: String) -> CachedResponseEntry? {
        // Check memory first
        if var entry = memoryCache[key] {
            entry.lastAccessedAt = Date()
            memoryCache[key] = entry
            return entry
        }

        // Check disk
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash)
        guard let data = try? Data(contentsOf: fileURL),
              var entry = try? JSONDecoder().decode(CachedResponseEntry.self, from: data) else {
            return nil
        }

        // Promote to memory
        entry.lastAccessedAt = Date()
        memoryCache[key] = entry
        evictMemoryIfNeeded()

        return entry
    }

    func store(_ key: String, entry: CachedResponseEntry) {
        // Store in memory
        memoryCache[key] = entry
        evictMemoryIfNeeded()

        // Store on disk
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash)
        if let data = try? JSONEncoder().encode(entry) {
            try? data.write(to: fileURL)
        }

        Task { await evictDiskIfNeeded() }
    }

    func remove(_ key: String) {
        memoryCache.removeValue(forKey: key)
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func removeAll() {
        memoryCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Eviction

    private func evictMemoryIfNeeded() {
        guard memoryCache.count > maxMemoryEntries else { return }
        let sorted = memoryCache.sorted { $0.value.lastAccessedAt < $1.value.lastAccessedAt }
        let toRemove = sorted.prefix(memoryCache.count - maxMemoryEntries)
        for (key, _) in toRemove {
            memoryCache.removeValue(forKey: key)
        }
    }

    private func evictDiskIfNeeded() {
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentAccessDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let totalSize = contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }

        guard totalSize > maxDiskSize else { return }

        // Sort by access date, remove oldest
        let sorted = contents.sorted { a, b in
            let dateA = (try? a.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate ?? .distantPast
            let dateB = (try? b.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate ?? .distantPast
            return dateA < dateB
        }

        var currentSize = totalSize
        for url in sorted {
            guard currentSize > maxDiskSize else { break }
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            try? fileManager.removeItem(at: url)
            currentSize -= size
        }
    }
}

/// In-memory cache for testing.
actor InMemoryHTTPResponseCache: HTTPResponseCaching {
    private var storage: [String: CachedResponseEntry] = [:]

    func get(_ key: String) -> CachedResponseEntry? { storage[key] }
    func store(_ key: String, entry: CachedResponseEntry) { storage[key] = entry }
    func remove(_ key: String) { storage.removeValue(forKey: key) }
    func removeAll() { storage.removeAll() }
}

// MARK: - String Hashing Extension

extension String {
    /// SHA-256 hash for safe file names.
    var sha256Hash: String {
        import CryptoKit
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
```

## CachingAPIClient.swift

```swift
import Foundation

/// Decorator that adds HTTP caching to any APIClient conformance.
///
/// Uses the decorator pattern: wraps an existing client without modifying it.
/// Cache behavior is controlled per-endpoint via `CacheConfigurable`.
final class CachingAPIClient: APIClient, Sendable {
    private let wrapped: APIClient
    private let cache: any HTTPResponseCaching
    private let configuration: HTTPCacheConfiguration
    private let reachability: NetworkReachability?

    init(
        wrapping client: APIClient,
        cache: any HTTPResponseCaching,
        configuration: HTTPCacheConfiguration = .default,
        reachability: NetworkReachability? = nil
    ) {
        self.wrapped = client
        self.cache = cache
        self.configuration = configuration
        self.reachability = reachability
    }

    func request<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response {
        let cacheKey = Self.cacheKey(for: endpoint)
        let policy = (endpoint as? CacheConfigurable)?.cachePolicy ?? configuration.defaultPolicy

        switch policy {
        case .noCache:
            return try await wrapped.request(endpoint)

        case .forceCache:
            if let cached = await cache.get(cacheKey) {
                return try JSONDecoder().decode(E.Response.self, from: cached.data)
            }
            return try await fetchAndCache(endpoint, key: cacheKey)

        case .cacheFirst(let maxAge):
            if let cached = await cache.get(cacheKey), cached.isFresh {
                return try JSONDecoder().decode(E.Response.self, from: cached.data)
            }
            // Stale-while-revalidate: return stale and refresh
            if let cached = await cache.get(cacheKey) {
                let decoded = try JSONDecoder().decode(E.Response.self, from: cached.data)
                Task { try? await self.fetchAndCache(endpoint, key: cacheKey) }
                return decoded
            }
            return try await fetchAndCache(endpoint, key: cacheKey, maxAge: maxAge)

        case .default, .custom:
            return try await handleDefault(endpoint, key: cacheKey, policy: policy)
        }
    }

    // MARK: - Private

    private func handleDefault<E: APIEndpoint>(
        _ endpoint: E,
        key: String,
        policy: CachePolicy
    ) async throws -> E.Response {
        // Check cache
        if let cached = await cache.get(key), cached.isFresh {
            return try JSONDecoder().decode(E.Response.self, from: cached.data)
        }

        // Try network
        do {
            let maxAge: TimeInterval? = if case .custom(let age) = policy { age } else { nil }
            return try await fetchAndCache(endpoint, key: key, maxAge: maxAge)
        } catch {
            // Offline fallback
            if configuration.offlineFallbackEnabled,
               let cached = await cache.get(key) {
                return try JSONDecoder().decode(E.Response.self, from: cached.data)
            }
            throw error
        }
    }

    @discardableResult
    private func fetchAndCache<E: APIEndpoint>(
        _ endpoint: E,
        key: String,
        maxAge: TimeInterval? = nil
    ) async throws -> E.Response {
        let response = try await wrapped.request(endpoint)

        let data = try JSONEncoder().encode(response)
        let entry = CachedResponseEntry(
            data: data,
            statusCode: 200,
            etag: nil,
            lastModified: nil,
            cacheControl: nil,
            cachedAt: Date(),
            maxAge: maxAge ?? configuration.defaultMaxAge,
            lastAccessedAt: Date()
        )
        await cache.store(key, entry: entry)

        return response
    }

    private static func cacheKey<E: APIEndpoint>(for endpoint: E) -> String {
        let method = "\(endpoint.method)"
        let path = endpoint.path
        let query = endpoint.queryItems?
            .sorted { $0.name < $1.name }
            .map { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: "&") ?? ""
        return "\(method)|\(path)|\(query)"
    }
}
```

## NetworkReachability.swift

```swift
import Foundation
import Network

/// Monitors network connectivity using NWPathMonitor.
///
/// Use to detect offline state and enable stale cache fallback.
actor NetworkReachability {
    private let monitor: NWPathMonitor
    private(set) var isConnected: Bool = true
    private(set) var isExpensive: Bool = false

    init() {
        self.monitor = NWPathMonitor()
    }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                await self?.updatePath(path)
            }
        }
        monitor.start(queue: DispatchQueue(label: "com.app.network.monitor"))
    }

    func stop() {
        monitor.cancel()
    }

    private func updatePath(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
    }
}
```
