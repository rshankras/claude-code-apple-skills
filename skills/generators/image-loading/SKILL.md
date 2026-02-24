---
name: image-loading
description: Generates an image loading pipeline with memory/disk caching, deduplication, and a CachedAsyncImage SwiftUI view. Use when user wants image caching, lazy image loading, or a replacement for AsyncImage.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Image Loading Generator

Generate a production image loading pipeline with NSCache memory cache, LRU disk cache, request deduplication, image processing, and a drop-in `CachedAsyncImage` SwiftUI view.

## When This Skill Activates

Use this skill when the user:
- Asks to "add image caching" or "cache images"
- Wants to "replace AsyncImage" or fix "AsyncImage has no cache"
- Mentions "image loading pipeline" or "lazy image loading"
- Asks about "image download" or "image prefetching"
- Wants "thumbnail generation" or "image resizing"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing image loading:
```
Glob: **/*ImageCache*.swift, **/*ImageLoader*.swift, **/*ImagePipeline*.swift
Grep: "AsyncImage" or "UIImage" or "NSImage" or "ImageCache"
```

If third-party library found (Kingfisher, SDWebImage, Nuke):
- Ask if user wants to replace or keep it
- If keeping, don't generate — advise on best practices instead

### 3. Platform Detection
Determine if generating for iOS (UIImage) or macOS (NSImage) or both (cross-platform typealias).

## Configuration Questions

Ask user via AskUserQuestion:

1. **Cache sizes?**
   - Small (50 MB memory / 100 MB disk)
   - Medium (100 MB memory / 250 MB disk) — recommended
   - Large (200 MB memory / 500 MB disk)

2. **Image processing?**
   - Resize to fit (downscale large images to save memory)
   - Thumbnail generation (create small thumbnails for lists)
   - None (cache original images only)

3. **Additional features?** (multi-select)
   - Prefetching for collections (preload images for visible rows + buffer)
   - Placeholder and error images
   - Progress indicator during download

4. **Platform?**
   - iOS only
   - macOS only
   - Cross-platform (iOS + macOS)

## Generation Process

### Step 1: Read Templates
Read `image-loading-patterns.md` for architecture guidance.
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `ImageCache.swift` — Protocol for cache interface
2. `MemoryImageCache.swift` — NSCache-based with configurable size
3. `DiskImageCache.swift` — FileManager LRU with expiration
4. `ImageDownloader.swift` — Actor-based with deduplication + cancellation
5. `ImagePipeline.swift` — Orchestrator (cache → download → process → store)

### Step 3: Create UI Files
6. `CachedAsyncImage.swift` — Drop-in SwiftUI view replacement

### Step 4: Create Optional Files
Based on configuration:
- `ImageProcessor.swift` — If resize or thumbnail selected
- `ImagePrefetcher.swift` — If prefetching selected

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists → `Sources/ImageLoading/`
- If `App/` exists → `App/ImageLoading/`
- Otherwise → `ImageLoading/`

## Output Format

After generation, provide:

### Files Created
```
ImageLoading/
├── ImageCache.swift          # Protocol for cache interface
├── MemoryImageCache.swift    # NSCache-based memory cache
├── DiskImageCache.swift      # LRU disk cache with expiration
├── ImageDownloader.swift     # Actor-based downloader
├── ImagePipeline.swift       # Orchestrator
├── ImageProcessor.swift      # Resize, thumbnails (optional)
├── CachedAsyncImage.swift    # SwiftUI view
└── ImagePrefetcher.swift     # Collection prefetching (optional)
```

### Integration Steps

**Drop-in replacement for AsyncImage:**
```swift
// Before (no caching)
AsyncImage(url: user.avatarURL) { image in
    image.resizable().aspectRatio(contentMode: .fill)
} placeholder: {
    ProgressView()
}

// After (with caching)
CachedAsyncImage(url: user.avatarURL) { image in
    image.resizable().aspectRatio(contentMode: .fill)
} placeholder: {
    ProgressView()
}
```

**In a List:**
```swift
List(users) { user in
    HStack {
        CachedAsyncImage(url: user.avatarURL) { image in
            image.resizable().frame(width: 44, height: 44).clipShape(Circle())
        } placeholder: {
            Circle().fill(Color.secondary.opacity(0.2)).frame(width: 44, height: 44)
        }
        Text(user.name)
    }
}
```

**With prefetching:**
```swift
struct UsersListView: View {
    let users: [User]
    @State private var prefetcher = ImagePrefetcher()

    var body: some View {
        List(users) { user in
            UserRow(user: user)
                .onAppear { prefetcher.startPrefetching(urls: nearbyURLs(for: user)) }
                .onDisappear { prefetcher.stopPrefetching(urls: [user.avatarURL]) }
        }
    }
}
```

**With image processing:**
```swift
CachedAsyncImage(
    url: photo.url,
    processing: .resize(targetSize: CGSize(width: 300, height: 300))
) { image in
    image.resizable()
} placeholder: {
    Color.secondary.opacity(0.2)
}
```

### Testing

```swift
@Test
func cachedImageReturnedWithoutDownload() async throws {
    let cache = InMemoryImageCache()
    let downloader = MockImageDownloader()
    let pipeline = ImagePipeline(cache: cache, downloader: downloader)

    let testImage = PlatformImage.testImage
    await cache.store(testImage, for: testURL)

    let result = try await pipeline.image(for: testURL)
    #expect(result != nil)
    #expect(downloader.downloadCount == 0) // Cache hit
}

@Test
func deduplicatesConcurrentRequests() async throws {
    let downloader = MockImageDownloader(delay: .milliseconds(100))
    let pipeline = ImagePipeline(downloader: downloader)

    async let image1 = pipeline.image(for: testURL)
    async let image2 = pipeline.image(for: testURL)

    let results = try await [image1, image2]
    #expect(results.count == 2)
    #expect(downloader.downloadCount == 1) // Only one download
}
```

## References

- **image-loading-patterns.md** — Why not AsyncImage, NSCache config, LRU disk cache, deduplication
- **templates.md** — All production Swift templates
- Related: `generators/http-cache` — General HTTP response caching
- Related: `generators/pagination` — Prefetch images in paginated lists
