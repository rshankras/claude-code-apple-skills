# Image Loading Code Templates

Production-ready Swift templates for image loading pipeline. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## Platform Compatibility

```swift
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif
```

## ImageCache.swift

```swift
import Foundation

/// Protocol for image cache storage.
///
/// Implementations handle memory and/or disk caching.
protocol ImageCaching: Sendable {
    func image(for url: URL) async -> PlatformImage?
    func store(_ image: PlatformImage, for url: URL) async
    func remove(for url: URL) async
    func removeAll() async
}
```

## MemoryImageCache.swift

```swift
import Foundation

/// NSCache-based memory image cache.
///
/// - Auto-evicts under memory pressure (NSCache behavior)
/// - Thread-safe without manual locking
/// - Configurable count and cost limits
final class MemoryImageCache: ImageCaching, @unchecked Sendable {
    private let cache = NSCache<NSString, PlatformImage>()

    init(countLimit: Int = 200, totalCostLimit: Int = 100 * 1024 * 1024) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func image(for url: URL) async -> PlatformImage? {
        cache.object(forKey: url.absoluteString as NSString)
    }

    func store(_ image: PlatformImage, for url: URL) async {
        let cost = estimatedCost(of: image)
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }

    func remove(for url: URL) async {
        cache.removeObject(forKey: url.absoluteString as NSString)
    }

    func removeAll() async {
        cache.removeAllObjects()
    }

    private func estimatedCost(of image: PlatformImage) -> Int {
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
        #endif
    }
}
```

## DiskImageCache.swift

```swift
import Foundation
import CryptoKit

/// Disk-backed image cache with LRU eviction and TTL expiration.
///
/// Stores images as JPEG files in the Caches directory.
/// Uses SHA-256 hashed filenames to avoid path conflicts.
actor DiskImageCache: ImageCaching {
    private let cacheDirectory: URL
    private let maxDiskSize: Int
    private let maxAge: TimeInterval

    init(
        directoryName: String = "ImageCache",
        maxDiskSize: Int = 250 * 1024 * 1024,
        maxAge: TimeInterval = 7 * 24 * 3600  // 7 days
    ) {
        self.cacheDirectory = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(directoryName, isDirectory: true)
        self.maxDiskSize = maxDiskSize
        self.maxAge = maxAge

        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    func image(for url: URL) async -> PlatformImage? {
        let fileURL = fileURL(for: url)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        // Check expiration
        if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modified = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modified) > maxAge {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        // Touch access date for LRU
        try? FileManager.default.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )

        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return PlatformImage(data: data)
    }

    func store(_ image: PlatformImage, for url: URL) async {
        let fileURL = fileURL(for: url)

        #if canImport(UIKit)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        #elseif canImport(AppKit)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else { return }
        #endif

        try? data.write(to: fileURL)
        await evictIfNeeded()
    }

    func remove(for url: URL) async {
        let fileURL = fileURL(for: url)
        try? FileManager.default.removeItem(at: fileURL)
    }

    func removeAll() async {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Private

    private func fileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = hash.compactMap { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent(filename)
    }

    private func evictIfNeeded() async {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        let totalSize = files.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }

        guard totalSize > maxDiskSize else { return }

        // LRU: sort by modification date (oldest first)
        let sorted = files.sorted { a, b in
            let dateA = (try? a.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let dateB = (try? b.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
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
```

## ImageDownloader.swift

```swift
import Foundation

/// Protocol for image downloading.
protocol ImageDownloading: Actor {
    func download(url: URL) async throws -> Data
    func cancel(url: URL)
}

/// Actor-based image downloader with request deduplication.
///
/// If multiple views request the same URL simultaneously,
/// only one download occurs and all callers receive the result.
actor ImageDownloader: ImageDownloading {
    private var activeDownloads: [URL: Task<Data, Error>] = [:]
    private let session: URLSession

    init(session: URLSession? = nil) {
        let config = URLSessionConfiguration.default
        config.urlCache = nil  // We handle caching ourselves
        self.session = session ?? URLSession(configuration: config)
    }

    func download(url: URL) async throws -> Data {
        // Deduplicate: if already downloading, wait for existing task
        if let existing = activeDownloads[url] {
            return try await existing.value
        }

        let task = Task<Data, Error> {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ImageLoadingError.downloadFailed(url: url)
            }

            return data
        }

        activeDownloads[url] = task

        do {
            let data = try await task.value
            activeDownloads.removeValue(forKey: url)
            return data
        } catch {
            activeDownloads.removeValue(forKey: url)
            throw error
        }
    }

    func cancel(url: URL) {
        activeDownloads[url]?.cancel()
        activeDownloads.removeValue(forKey: url)
    }
}

/// Errors specific to image loading.
enum ImageLoadingError: Error, LocalizedError {
    case downloadFailed(url: URL)
    case decodingFailed(url: URL)
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .downloadFailed(let url):
            return "Failed to download image from \(url.absoluteString)"
        case .decodingFailed(let url):
            return "Failed to decode image from \(url.absoluteString)"
        case .processingFailed:
            return "Failed to process image"
        }
    }
}
```

## ImagePipeline.swift

```swift
import Foundation
import SwiftUI

/// Central image loading orchestrator.
///
/// Flow: Memory Cache → Disk Cache → Download → Process → Store
///
/// Usage:
/// ```swift
/// let pipeline = ImagePipeline.shared
/// let image = try await pipeline.image(for: url)
/// ```
@Observable
final class ImagePipeline: @unchecked Sendable {
    static let shared = ImagePipeline()

    private let memoryCache: MemoryImageCache
    private let diskCache: DiskImageCache
    private let downloader: any ImageDownloading
    private let processor: ImageProcessor?

    init(
        memoryCache: MemoryImageCache = MemoryImageCache(),
        diskCache: DiskImageCache = DiskImageCache(),
        downloader: any ImageDownloading = ImageDownloader(),
        processor: ImageProcessor? = nil
    ) {
        self.memoryCache = memoryCache
        self.diskCache = diskCache
        self.downloader = downloader
        self.processor = processor
    }

    /// Load an image from cache or network.
    func image(for url: URL, processing: ImageProcessingOptions? = nil) async throws -> PlatformImage {
        let cacheKey = processing.map { "\(url.absoluteString)_\($0.cacheKeySuffix)" } ?? url.absoluteString
        let cacheURL = URL(string: cacheKey) ?? url

        // 1. Check memory cache
        if let cached = await memoryCache.image(for: cacheURL) {
            return cached
        }

        // 2. Check disk cache
        if let cached = await diskCache.image(for: cacheURL) {
            await memoryCache.store(cached, for: cacheURL)
            return cached
        }

        // 3. Download
        let data = try await downloader.download(url: url)

        guard var image = PlatformImage(data: data) else {
            throw ImageLoadingError.decodingFailed(url: url)
        }

        // 4. Process (optional)
        if let processing, let processor {
            image = try processor.process(image, options: processing)
        }

        // 5. Store in both caches
        await memoryCache.store(image, for: cacheURL)
        await diskCache.store(image, for: cacheURL)

        return image
    }

    /// Cancel a pending download.
    func cancel(for url: URL) async {
        await downloader.cancel(url: url)
    }

    /// Clear all caches.
    func clearCache() async {
        await memoryCache.removeAll()
        await diskCache.removeAll()
    }
}

// For testing: allow injection via SwiftUI Environment
private struct ImagePipelineKey: EnvironmentKey {
    static let defaultValue: ImagePipeline = .shared
}

extension EnvironmentValues {
    var imagePipeline: ImagePipeline {
        get { self[ImagePipelineKey.self] }
        set { self[ImagePipelineKey.self] = newValue }
    }
}
```

## ImageProcessor.swift

```swift
import Foundation
import CoreGraphics
import ImageIO

/// Image processing options for the pipeline.
enum ImageProcessingOptions: Sendable {
    /// Resize to fit within target size, maintaining aspect ratio.
    case resize(targetSize: CGSize)

    /// Generate a thumbnail of the specified max pixel dimension.
    case thumbnail(maxPixelSize: Int)

    /// Cache key suffix to differentiate processed variants.
    var cacheKeySuffix: String {
        switch self {
        case .resize(let size):
            return "resize_\(Int(size.width))x\(Int(size.height))"
        case .thumbnail(let size):
            return "thumb_\(size)"
        }
    }
}

/// Handles image processing (resize, thumbnail generation).
struct ImageProcessor: Sendable {

    func process(_ image: PlatformImage, options: ImageProcessingOptions) throws -> PlatformImage {
        switch options {
        case .resize(let targetSize):
            return try resize(image, to: targetSize)
        case .thumbnail(let maxPixelSize):
            return try generateThumbnail(from: image, maxPixelSize: maxPixelSize)
        }
    }

    // MARK: - Resize

    private func resize(_ image: PlatformImage, to targetSize: CGSize) throws -> PlatformImage {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        #elseif canImport(AppKit)
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
        #endif
    }

    // MARK: - Thumbnail (ImageIO — most efficient)

    private func generateThumbnail(from image: PlatformImage, maxPixelSize: Int) throws -> PlatformImage {
        #if canImport(UIKit)
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw ImageLoadingError.processingFailed
        }
        #elseif canImport(AppKit)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
            throw ImageLoadingError.processingFailed
        }
        #endif

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ImageLoadingError.processingFailed
        }

        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #endif
    }
}
```

## CachedAsyncImage.swift

```swift
import SwiftUI

/// A drop-in replacement for AsyncImage with caching support.
///
/// Uses `ImagePipeline` for memory/disk caching, request deduplication,
/// and optional image processing.
///
/// Usage:
/// ```swift
/// CachedAsyncImage(url: user.avatarURL) { image in
///     image.resizable().aspectRatio(contentMode: .fill)
/// } placeholder: {
///     ProgressView()
/// }
/// ```
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let processing: ImageProcessingOptions?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @Environment(\.imagePipeline) private var pipeline
    @State private var loadedImage: PlatformImage?
    @State private var isLoading = false
    @State private var loadError: Error?

    init(
        url: URL?,
        processing: ImageProcessingOptions? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.processing = processing
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let loadedImage {
                #if canImport(UIKit)
                content(Image(uiImage: loadedImage))
                #elseif canImport(AppKit)
                content(Image(nsImage: loadedImage))
                #endif
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url else { return }

        loadedImage = nil
        loadError = nil
        isLoading = true

        do {
            let image = try await pipeline.image(for: url, processing: processing)
            guard !Task.isCancelled else { return }
            loadedImage = image
        } catch {
            guard !Task.isCancelled else { return }
            loadError = error
        }

        isLoading = false
    }
}

// Convenience initializer without placeholder
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        processing: ImageProcessingOptions? = nil,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(url: url, processing: processing, content: content) {
            ProgressView()
        }
    }
}
```

## ImagePrefetcher.swift

```swift
import Foundation

/// Prefetches images for upcoming list items.
///
/// Start prefetching when items are about to appear,
/// and cancel when they scroll off screen.
///
/// Usage:
/// ```swift
/// @State private var prefetcher = ImagePrefetcher()
///
/// ForEach(items) { item in
///     ItemRow(item: item)
///         .onAppear { prefetcher.startPrefetching(urls: [item.imageURL]) }
///         .onDisappear { prefetcher.stopPrefetching(urls: [item.imageURL]) }
/// }
/// ```
@Observable
final class ImagePrefetcher {
    private var activeTasks: [URL: Task<Void, Never>] = [:]
    private let pipeline: ImagePipeline

    init(pipeline: ImagePipeline = .shared) {
        self.pipeline = pipeline
    }

    /// Start prefetching images for the given URLs.
    func startPrefetching(urls: [URL]) {
        for url in urls {
            guard activeTasks[url] == nil else { continue }

            activeTasks[url] = Task {
                _ = try? await pipeline.image(for: url)
            }
        }
    }

    /// Cancel prefetching for the given URLs.
    func stopPrefetching(urls: [URL]) {
        for url in urls {
            activeTasks[url]?.cancel()
            activeTasks.removeValue(forKey: url)
        }
    }

    /// Cancel all active prefetch tasks.
    func stopAll() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
}
```
