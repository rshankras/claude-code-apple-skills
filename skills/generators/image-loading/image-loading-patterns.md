# Image Loading Patterns and Best Practices

## Why Not Just AsyncImage?

`AsyncImage` is convenient but has critical limitations:

| Feature | AsyncImage | Custom Pipeline |
|---------|-----------|-----------------|
| Memory cache | ❌ None | ✅ NSCache |
| Disk cache | ❌ None | ✅ LRU FileManager |
| Request deduplication | ❌ Each view downloads independently | ✅ Single download shared |
| Prefetching | ❌ Not possible | ✅ Preload before visible |
| Image processing | ❌ Returns original size | ✅ Resize, thumbnail |
| Cancel on disappear | ⚠️ Inconsistent | ✅ Explicit cancellation |
| Memory pressure handling | ❌ No eviction | ✅ NSCache auto-evicts |
| Offline support | ❌ None | ✅ Serve from disk cache |
| Cache key customization | ❌ None | ✅ Custom keys |

**Rule of thumb:** Use `AsyncImage` for prototypes and low-traffic views. Use a custom pipeline for anything with lists, grids, or many images.

## Architecture Overview

```
CachedAsyncImage (SwiftUI View)
    └── ImagePipeline (Orchestrator)
            ├── MemoryImageCache (NSCache)
            │       └── Hit? → Return immediately
            ├── DiskImageCache (FileManager)
            │       └── Hit? → Decode, store in memory, return
            ├── ImageDownloader (Actor)
            │       ├── Deduplicate concurrent requests
            │       ├── Download via URLSession
            │       └── Return Data
            └── ImageProcessor (Optional)
                    ├── Resize to fit
                    ├── Generate thumbnail
                    └── Return processed image
```

## NSCache Configuration

### Why NSCache Over Dictionary

- **Automatic eviction** on memory pressure
- **Thread-safe** without manual locking
- **Cost-based** — assign cost = byte size of image
- **Count limit** — cap maximum entries

### Configuration

```swift
let cache = NSCache<NSString, PlatformImage>()
cache.countLimit = 200                     // Max 200 images
cache.totalCostLimit = 100 * 1024 * 1024   // 100 MB max

// Store with cost = image byte size
let cost = image.pngData()?.count ?? 0
cache.setObject(image, forKey: key as NSString, cost: cost)
```

### Memory Pressure

NSCache automatically evicts objects when the system is under memory pressure. You don't need to handle `UIApplication.didReceiveMemoryWarningNotification` — NSCache does it for you.

However, for disk cache, listen for memory warnings to clear the memory layer:

```swift
NotificationCenter.default.addObserver(
    forName: UIApplication.didReceiveMemoryWarningNotification,
    object: nil, queue: .main
) { _ in
    memoryCache.removeAllObjects()
}
```

## LRU Disk Cache

### File Structure

```
CachesDirectory/
└── ImageCache/
    ├── a1b2c3d4.jpg     # Hashed filename
    ├── e5f6g7h8.jpg
    └── ...
```

### Key Design Decisions

1. **Use Caches directory** — system can clear it, not backed up to iCloud
2. **Hash URL for filename** — SHA-256 avoids path conflicts, special characters
3. **Track access dates** — for LRU eviction, use file system's content access date
4. **Background eviction** — don't evict synchronously during load

### Expiration

Two eviction strategies:

1. **Size-based (LRU):** When total cache exceeds limit, remove least-recently-accessed files
2. **Time-based (TTL):** Remove files older than N days (e.g., 7 days)

```swift
func evictExpired(maxAge: TimeInterval = 7 * 24 * 3600) {
    let cutoff = Date().addingTimeInterval(-maxAge)
    for file in allCachedFiles() {
        if file.modificationDate < cutoff {
            try? FileManager.default.removeItem(at: file.url)
        }
    }
}
```

## Request Deduplication

### The Problem

A list with 10 visible cells showing the same user avatar = 10 simultaneous downloads for the same URL.

### The Solution: Actor-Based Coalescing

```swift
actor ImageDownloader {
    private var activeDownloads: [URL: Task<Data, Error>] = [:]

    func download(url: URL) async throws -> Data {
        // If already downloading this URL, wait for existing task
        if let existing = activeDownloads[url] {
            return try await existing.value
        }

        let task = Task {
            let (data, _) = try await URLSession.shared.data(from: url)
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
}
```

### Why an Actor?

- **Thread-safe** — no data races on `activeDownloads`
- **Serialized access** — checks for existing download before starting new one
- **Automatic cleanup** — remove completed tasks

## Image Processing

### When to Process

| Scenario | Process? | Why |
|----------|----------|-----|
| 4000x3000 photo in a 44x44 avatar | ✅ Resize | Saves ~95% memory |
| Icon from CDN already sized | ❌ | Already optimized |
| Photo gallery (full screen) | ⚠️ Maybe | Resize to screen size, not original |
| Thumbnail in list | ✅ Thumbnail | Small size for fast scrolling |

### Memory Impact

A 4000x3000 photo at 4 bytes/pixel = **48 MB** in memory. Resized to 88x88 (2x for Retina) = **31 KB**. That's a 1500x reduction.

### Resize with UIGraphicsImageRenderer

```swift
func resize(_ image: UIImage, to targetSize: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
}
```

### Thumbnail with ImageIO (Most Efficient)

```swift
import ImageIO

func thumbnail(from data: Data, maxPixelSize: Int) -> CGImage? {
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true
    ]

    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
}
```

ImageIO is more efficient than UIGraphicsImageRenderer because:
- Doesn't decode full image into memory first
- Operates on compressed data directly
- Uses hardware acceleration

## Prefetching for Collections

### How It Works

Preload images for rows that are about to become visible:

```swift
// User sees rows 5-15
// Prefetch rows 15-25 (next screen)
// Cancel rows 0-4 (scrolled off)
```

### UICollectionView Integration

```swift
// UIKit has built-in prefetching
extension ViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView,
                        prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.map { items[$0.row].imageURL }
        prefetcher.startPrefetching(urls: urls)
    }

    func collectionView(_ collectionView: UICollectionView,
                        cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.map { items[$0.row].imageURL }
        prefetcher.stopPrefetching(urls: urls)
    }
}
```

### SwiftUI Prefetching

SwiftUI doesn't have built-in prefetching. Use `onAppear`/`onDisappear`:

```swift
ForEach(items) { item in
    ItemRow(item: item)
        .onAppear { prefetcher.startPrefetching(urls: nearbyURLs(for: item)) }
        .onDisappear { prefetcher.stopPrefetching(urls: [item.imageURL]) }
}
```

## Cross-Platform Support

### Platform Image Typealias

```swift
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif
```

### Platform-Specific Extensions

```swift
extension PlatformImage {
    var cgImageValue: CGImage? {
        #if canImport(UIKit)
        return cgImage
        #elseif canImport(AppKit)
        return cgImage(forProposedRect: nil, context: nil, hints: nil)
        #endif
    }

    static func from(data: Data) -> PlatformImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #endif
    }
}
```

## Anti-Patterns to Avoid

### Don't Decode on Main Thread
```swift
// ❌ Blocks UI while decoding large image
let image = UIImage(data: downloadedData)!
imageView.image = image

// ✅ Decode in background, display on main
Task.detached {
    let image = UIImage(data: downloadedData)
    // Force decode
    _ = image?.cgImage?.dataProvider?.data
    await MainActor.run { imageView.image = image }
}
```

### Don't Cache Full-Size Images When Displaying Thumbnails
```swift
// ❌ 48 MB per image in cache
cache.setObject(fullSizeImage, forKey: url)

// ✅ Cache at display size
let resized = resize(fullSizeImage, to: displaySize)
cache.setObject(resized, forKey: "\(url)_\(displaySize)")
```

### Don't Ignore Memory Warnings
```swift
// ❌ Memory cache grows unbounded
var cache: [URL: UIImage] = [:]  // Dictionary doesn't auto-evict

// ✅ NSCache auto-evicts under memory pressure
let cache = NSCache<NSString, UIImage>()
cache.totalCostLimit = 100 * 1024 * 1024
```

### Don't Re-Download On Every Appear
```swift
// ❌ Downloads every time cell appears
.onAppear { Task { image = await download(url) } }

// ✅ Check cache first
.task { image = await pipeline.image(for: url) }  // Cache-first
```

## Testing Image Loading

### Mock Downloader
```swift
actor MockImageDownloader: ImageDownloading {
    var downloadCount = 0
    var responses: [URL: Data] = [:]
    var delay: Duration?

    func download(url: URL) async throws -> Data {
        if let delay { try await Task.sleep(for: delay) }
        downloadCount += 1
        guard let data = responses[url] else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
```

### Test Image Helper
```swift
extension PlatformImage {
    static var testImage: PlatformImage {
        let size = CGSize(width: 100, height: 100)
        #if canImport(UIKit)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        #elseif canImport(AppKit)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
        #endif
    }
}
```
