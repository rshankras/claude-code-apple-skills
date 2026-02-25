---
name: watermark-engine
description: Generates a watermark overlay system for images and video with configurable positioning, opacity, tiling, and paywall integration for automatic removal on subscription or purchase. Use when user wants to add branding, attribution, or free-tier watermarks to visual content.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Watermark Engine Generator

Generate a production watermarking system with text/image/logo overlays, configurable positioning and opacity, tiled patterns, live SwiftUI preview, and automatic watermark removal on subscription purchase.

## When This Skill Activates

Use this skill when the user:
- Asks to "add watermark" or "watermark images"
- Wants a "branded overlay" or "logo overlay on photos"
- Mentions "remove watermark on purchase" or "free tier watermark"
- Asks about "content watermarking" or "image branding"
- Wants "tiled watermark" or "diagonal watermark pattern"
- Mentions "attribution overlay" or "copyright overlay"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing watermark or overlay code:
```
Glob: **/*Watermark*.swift, **/*Overlay*.swift, **/*Branding*.swift
Grep: "watermark" or "overlay" or "CGContext" or "draw(in:"
```

If existing watermark code found:
- Ask if user wants to replace or extend it
- If extending, integrate with existing architecture

### 3. Dependency Detection
Check for existing image processing infrastructure:
```
Grep: "CoreImage" or "CoreGraphics" or "CGImage" or "UIGraphicsImageRenderer"
Grep: "StoreKit" or "SubscriptionStatus" or "Product.SubscriptionInfo"
```

If paywall/subscription code exists, integrate watermark removal with existing subscription logic rather than generating standalone subscription checks.

### 4. Platform Detection
Determine if generating for iOS (UIImage) or macOS (NSImage) or both (cross-platform typealias).

## Configuration Questions

Ask user via AskUserQuestion:

1. **Watermark content type?**
   - Text (e.g., username, app name, copyright)
   - Image/Logo (e.g., brand logo PNG with transparency)
   - Attributed text (styled text with font, color, shadow)

2. **Watermark positioning?**
   - Corner (top-left, top-right, bottom-left, bottom-right) — recommended for branding
   - Center — recommended for free-tier watermark
   - Tiled (repeated diagonal pattern) — strongest protection for freemium

3. **Watermark removal trigger?**
   - Subscription (auto-remove while subscription is active)
   - One-time purchase (remove permanently after purchase)
   - Never (always present, e.g., branding/attribution)

4. **Opacity level?**
   - Subtle (0.15–0.25) — light branding
   - Medium (0.3–0.5) — visible but non-intrusive — recommended
   - Strong (0.6–0.8) — clear protection for free-tier

5. **Platform?**
   - iOS only
   - macOS only
   - Cross-platform (iOS + macOS)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `WatermarkStyle.swift` — Configuration struct for content, position, opacity, scale, padding
2. `WatermarkPosition.swift` — Enum with computed CGRect placement relative to image bounds
3. `WatermarkRenderer.swift` — CoreGraphics-based renderer that composites watermark onto source image

### Step 3: Create UI Files
4. `WatermarkOverlayView.swift` — SwiftUI overlay view for live preview of watermark on content

### Step 4: Create Manager
5. `WatermarkManager.swift` — @Observable manager that applies/removes watermarks, integrates with subscription status

### Step 5: Create Modifier
6. `WatermarkImageModifier.swift` — SwiftUI ViewModifier for declarative watermark application

### Step 6: Determine File Location
Check project structure:
- If `Sources/` exists → `Sources/Watermark/`
- If `App/` exists → `App/Watermark/`
- Otherwise → `Watermark/`

## Output Format

After generation, provide:

### Files Created
```
Watermark/
├── WatermarkStyle.swift          # Configuration for content, position, opacity
├── WatermarkPosition.swift       # Position enum with CGRect computation
├── WatermarkRenderer.swift       # CoreGraphics compositor
├── WatermarkOverlayView.swift    # SwiftUI live preview overlay
├── WatermarkManager.swift        # Observable manager with paywall integration
└── WatermarkImageModifier.swift  # SwiftUI ViewModifier
```

### Integration Steps

**Apply a text watermark to an exported image:**
```swift
let style = WatermarkStyle(
    content: .text("@ MyApp"),
    position: .bottomRight,
    opacity: 0.4,
    scale: 0.08
)
let renderer = WatermarkRenderer()
let watermarked = try renderer.render(source: originalImage, style: style)
```

**Live preview overlay in SwiftUI:**
```swift
Image(uiImage: photo)
    .resizable()
    .aspectRatio(contentMode: .fit)
    .watermark(.text("Preview"), position: .center, opacity: 0.3)
```

**With subscription-based removal:**
```swift
struct PhotoEditorView: View {
    let photo: UIImage
    @State private var manager = WatermarkManager()

    var body: some View {
        Image(uiImage: photo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .watermark(manager.activeStyle)
    }
}

// WatermarkManager automatically checks subscription status
// and returns .none when user has active subscription
```

**Tiled diagonal pattern for free-tier:**
```swift
let style = WatermarkStyle(
    content: .text("SAMPLE"),
    position: .tiled(angle: -30, spacing: 120),
    opacity: 0.15,
    scale: 0.05
)
```

### Testing

```swift
@Test
func textWatermarkRendersAtCorrectPosition() async throws {
    let source = PlatformImage.testImage(size: CGSize(width: 1000, height: 1000))
    let style = WatermarkStyle(
        content: .text("Test"),
        position: .bottomRight,
        opacity: 0.5,
        scale: 0.1
    )
    let renderer = WatermarkRenderer()
    let result = try renderer.render(source: source, style: style)
    #expect(result.size.width == source.size.width)
    #expect(result.size.height == source.size.height)
}

@Test
func watermarkRemovedWhenSubscribed() async throws {
    let manager = WatermarkManager(
        subscriptionStatus: .subscribed
    )
    #expect(manager.activeStyle == nil)
}

@Test
func watermarkAppliedWhenNotSubscribed() async throws {
    let manager = WatermarkManager(
        subscriptionStatus: .notSubscribed,
        defaultStyle: .init(content: .text("Free"), position: .center, opacity: 0.4)
    )
    #expect(manager.activeStyle != nil)
    #expect(manager.activeStyle?.content == .text("Free"))
}

@Test
func tiledWatermarkCoversEntireImage() async throws {
    let source = PlatformImage.testImage(size: CGSize(width: 2000, height: 2000))
    let style = WatermarkStyle(
        content: .text("SAMPLE"),
        position: .tiled(angle: -30, spacing: 100),
        opacity: 0.2,
        scale: 0.05
    )
    let renderer = WatermarkRenderer()
    let result = try renderer.render(source: source, style: style)
    #expect(result.size.width == source.size.width)
}
```

## Common Patterns

### Pattern 1: Text Watermark (Branding)
```swift
// Simple text watermark in corner
let style = WatermarkStyle(
    content: .text("Shot with MyApp"),
    position: .bottomRight,
    opacity: 0.4,
    scale: 0.06,
    padding: 16
)
```

### Pattern 2: Logo Overlay
```swift
// Brand logo with transparency
let logo = UIImage(named: "AppLogo")!
let style = WatermarkStyle(
    content: .image(logo),
    position: .bottomLeft,
    opacity: 0.6,
    scale: 0.12,
    padding: 20
)
```

### Pattern 3: Tiled Diagonal Pattern (Freemium)
```swift
// Repeated diagonal text across entire image
let style = WatermarkStyle(
    content: .text("PREVIEW"),
    position: .tiled(angle: -45, spacing: 150),
    opacity: 0.12,
    scale: 0.04
)
```

### Pattern 4: Subscription-Gated Removal
```swift
// Watermark present for free users, removed for subscribers
@Observable
class PhotoExporter {
    @ObservationIgnored private let manager = WatermarkManager()
    @ObservationIgnored private let renderer = WatermarkRenderer()

    func export(photo: UIImage) async throws -> UIImage {
        if let style = manager.activeStyle {
            return try renderer.render(source: photo, style: style)
        }
        return photo  // No watermark for subscribers
    }
}
```

## Gotchas

### Retina Resolution Handling
CoreGraphics contexts must account for screen scale. A 1000x1000pt image on a @3x device has 3000x3000 pixels. Always use `UIGraphicsImageRenderer` (which handles scale automatically) or explicitly set `CGContext` scale:
```swift
// Wrong — blurry watermark on Retina
let size = image.size
UIGraphicsBeginImageContext(size)

// Right — crisp at all scales
let renderer = UIGraphicsImageRenderer(size: size)
// Or for CGContext:
UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
```

### Performance with Large Images
Rendering watermarks on 48MP photos (8064x6048) allocates significant memory. Downsample first if the output doesn't need full resolution:
```swift
// Downsample before watermarking for social sharing
let maxDimension: CGFloat = 2048
if max(image.size.width, image.size.height) > maxDimension {
    image = image.preparingThumbnail(of: targetSize) ?? image
}
```

### Video Watermarking Complexity
Video watermarking requires `AVVideoComposition` with a `CIFilter` chain or `AVMutableVideoComposition.applyingCIFiltersWithHandler`. This is significantly more complex than image watermarking. If the user needs video watermarks, generate the image pipeline first and add a note about extending to video with AVFoundation.

### CoreImage Filter Chain
When using CIFilter for watermarks (e.g., `CISourceOverCompositing`), always process in the same color space. Mismatched color spaces produce washed-out results:
```swift
let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceRGB()])
```

### Thread Safety
`WatermarkRenderer` performs CGContext operations that are not inherently thread-safe. Either use it from a single actor or create a new renderer per task. The generated code uses value types (struct) to avoid shared mutable state.

## References

- **templates.md** — All production Swift templates for the watermark engine
- Related: `generators/social-export` — Export watermarked images for social sharing
- Related: `generators/paywall-generator` — Paywall UI that triggers watermark removal
- Related: `generators/image-loading` — Image pipeline to load and cache watermarked assets
