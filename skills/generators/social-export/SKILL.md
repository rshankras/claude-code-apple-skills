---
name: social-export
description: Generates infrastructure for exporting app content to social platforms (Instagram Stories, TikTok, Twitter/X) with platform-specific formatting, aspect ratios, and metadata. Use when user wants social media export, share to stories, or platform-specific sharing pipelines.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Social Export Generator

Generate a production social export pipeline with platform-specific formatters, aspect ratio handling, branding overlays, and a complete SwiftUI export flow. Different from share-card (which creates the visual image) — this handles the full export pipeline to each social platform.

## When This Skill Activates

Use this skill when the user:
- Asks to "export to Instagram" or "share to Instagram Stories"
- Wants "social media export" or "social sharing pipeline"
- Mentions "share to TikTok" or "export for TikTok"
- Asks about "platform-specific sharing" or "export to Twitter/X"
- Wants to "format content for social platforms"
- Mentions "story export" or "share to stories"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing social export or sharing code:
```
Glob: **/*SocialExport*.swift, **/*ShareExport*.swift, **/*StoryExport*.swift
Grep: "UIActivityViewController" or "instagram-stories" or "SocialPlatform"
```

If existing share infrastructure found:
- Ask if user wants to extend or replace it
- If extending, integrate with existing sharing code

### 3. Framework Detection
Check for frameworks already in use:
```
Grep: "import Photos" or "import PhotosUI" or "import LinkPresentation"
Grep: "UIDocumentInteractionController" or "UIActivityViewController"
```

If Photos framework is used, export pipeline can integrate save-to-library as a fallback.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Target platforms?** (multi-select)
   - Instagram Stories (URL scheme + pasteboard)
   - TikTok (URL scheme + share API)
   - Twitter/X (URL scheme + activity controller)
   - General share sheet (UIActivityViewController fallback)

2. **Content type?**
   - Image only (photo, illustration, screenshot)
   - Video (short-form video export)
   - Text + Image (quote cards, text overlays on images)

3. **Include app branding overlay?**
   - Yes — add app logo/name watermark to exported content
   - No — export clean content

4. **Watermark style?** (if branding selected)
   - Corner logo (small, unobtrusive)
   - Bottom banner (app name + URL strip)
   - None

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `SocialPlatform.swift` — Enum for supported platforms with requirements (aspect ratio, max file size, URL scheme)
2. `ExportConfiguration.swift` — Configuration struct for export options (platform, quality, branding, watermark)
3. `SocialExporter.swift` — Protocol + platform-specific implementations for each social network

### Step 3: Create Content Formatting
4. `ContentFormatter.swift` — Formats content per platform (resize, crop to aspect ratio, add metadata)

### Step 4: Create UI Files
5. `ExportPreviewView.swift` — SwiftUI preview showing how content will look on each platform
6. `SocialExportSheet.swift` — Complete export flow with platform picker, preview, and share action

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/SocialExport/`
- If `App/` exists -> `App/SocialExport/`
- Otherwise -> `SocialExport/`

## Output Format

After generation, provide:

### Files Created
```
SocialExport/
├── SocialPlatform.swift       # Platform enum with requirements
├── ExportConfiguration.swift  # Export options configuration
├── SocialExporter.swift       # Protocol + platform exporters
├── ContentFormatter.swift     # Resize, crop, metadata
├── ExportPreviewView.swift    # Platform-specific preview
└── SocialExportSheet.swift    # Complete export flow UI
```

### Integration Steps

**Export an image to Instagram Stories:**
```swift
let config = ExportConfiguration(
    platform: .instagramStories,
    quality: .high,
    branding: .cornerLogo(UIImage(named: "AppLogo")!)
)

let exporter = SocialExporter()
try await exporter.export(image: myImage, configuration: config)
```

**Present the export sheet:**
```swift
struct ContentDetailView: View {
    let content: AppContent
    @State private var showExportSheet = false

    var body: some View {
        VStack {
            ContentView(content: content)
            Button("Share to Social") {
                showExportSheet = true
            }
        }
        .sheet(isPresented: $showExportSheet) {
            SocialExportSheet(image: content.renderedImage)
        }
    }
}
```

**Quick share with fallback:**
```swift
let exporter = SocialExporter()

// Tries platform-specific export first, falls back to share sheet
try await exporter.export(
    image: shareImage,
    configuration: .init(platform: .instagramStories),
    fallbackToShareSheet: true,
    presentingViewController: viewController
)
```

### Testing

```swift
@Test
func instagramStoriesExportFormatsCorrectly() async throws {
    let formatter = ContentFormatter()
    let testImage = UIImage.testSolidColor(.red, size: CGSize(width: 1000, height: 1000))
    let formatted = try formatter.format(testImage, for: .instagramStories)

    // Instagram Stories expects 9:16 aspect ratio (1080x1920)
    #expect(formatted.size.width == 1080)
    #expect(formatted.size.height == 1920)
}

@Test
func fallsBackToShareSheetWhenAppNotInstalled() async throws {
    let exporter = MockSocialExporter(installedApps: [])
    let config = ExportConfiguration(platform: .instagramStories)

    let result = try await exporter.export(
        image: UIImage.testSolidColor(.blue, size: CGSize(width: 500, height: 500)),
        configuration: config,
        fallbackToShareSheet: true
    )

    #expect(result == .fallbackUsed)
}

@Test
func brandingOverlayApplied() async throws {
    let formatter = ContentFormatter()
    let logo = UIImage.testSolidColor(.white, size: CGSize(width: 50, height: 50))
    let config = ExportConfiguration(
        platform: .general,
        branding: .cornerLogo(logo)
    )

    let image = UIImage.testSolidColor(.red, size: CGSize(width: 1080, height: 1080))
    let result = try formatter.format(image, for: config.platform, branding: config.branding)

    // Image should still be the correct size after overlay
    #expect(result.size.width == 1080)
    #expect(result.size.height == 1080)
}
```

## Common Patterns

### Instagram Stories Export
Instagram Stories uses URL scheme + pasteboard for background images:
```swift
// Key details:
// - URL scheme: instagram-stories://share?source_application=YOUR_APP_ID
// - Pasteboard: set image data with key "com.instagram.sharedSticker.backgroundImage"
// - Aspect ratio: 9:16 (1080x1920)
// - Max file size: ~12 MB for images
// - Supports background image, sticker image, and background color
```

### General Share Sheet Fallback
Always provide `UIActivityViewController` as a fallback when the target app is not installed:
```swift
// Check canOpenURL before attempting URL scheme
// If unavailable, present UIActivityViewController with formatted content
// Include UTType metadata for proper previews in share sheet
```

### Video Export Pipeline
For video content, use `AVAssetExportSession` to transcode to platform-required formats:
```swift
// Instagram/TikTok: H.264, 9:16, max 60s (Stories) or 3min (Reels)
// Twitter/X: H.264, max 2:20, max 512 MB
// General: H.264, original aspect ratio
```

## Gotchas

### Instagram URL Scheme Requirements
- Must register `instagram-stories` in LSApplicationQueriesSchemes (Info.plist)
- Facebook App ID is required as the `source_application` parameter
- Pasteboard items must be set BEFORE opening the URL scheme
- Data must be set as `Data` on the pasteboard, not `UIImage`

### Aspect Ratios Per Platform
| Platform | Stories | Feed Post | Reels/Short |
|----------|---------|-----------|-------------|
| Instagram | 9:16 (1080x1920) | 1:1 (1080x1080) or 4:5 (1080x1350) | 9:16 (1080x1920) |
| TikTok | 9:16 (1080x1920) | 9:16 (1080x1920) | 9:16 (1080x1920) |
| Twitter/X | 16:9 (1200x675) | 16:9 or 1:1 | N/A |

### File Size Limits
| Platform | Image Max | Video Max |
|----------|-----------|-----------|
| Instagram Stories | ~12 MB | ~100 MB (H.264) |
| TikTok | ~10 MB | ~287 MB |
| Twitter/X | 5 MB (JPEG/PNG) | 512 MB (H.264) |

### App Detection
- `UIApplication.shared.canOpenURL()` requires LSApplicationQueriesSchemes in Info.plist
- iOS limits you to 50 URL schemes in LSApplicationQueriesSchemes
- Always test on physical device — simulator does not have social apps installed

### Thread Safety
- `UIPasteboard.general` must be accessed on the main thread
- `UIApplication.shared.open()` must be called on the main thread
- Image formatting/resizing should happen on a background thread to avoid UI lag

## References

- **templates.md** — All production Swift templates for social export
- Related: `generators/share-card` — Generate the visual share image/card
- Related: `generators/watermark-engine` — Advanced watermark and branding overlays
