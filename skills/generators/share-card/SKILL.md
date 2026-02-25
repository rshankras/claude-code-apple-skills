---
name: share-card
description: Generates shareable card images from app content (achievements, stats, quotes) for social media sharing. Use when user wants to create share images, social cards, shareable content cards, or export app content as images with ShareLink integration.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Share Card Generator

Generate a production share card system that renders app content (achievements, statistics, quotes, milestones) as shareable images with SwiftUI `ImageRenderer`, customizable styles, optional QR code overlays, and native `ShareLink` integration.

## When This Skill Activates

Use this skill when the user:
- Asks to "generate share cards" or "create shareable images"
- Wants to "share achievements as images" or "share stats to social media"
- Mentions "social media cards" or "shareable content cards"
- Asks about "exporting content as images" or "screenshot sharing"
- Wants "branded share images" or "share card templates"
- Asks to "add ShareLink with image" or "share rendered SwiftUI view"
- Wants "QR code on share image" or "deep link in share card"

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+ minimum for `ImageRenderer`)
- [ ] Check for @Observable support (iOS 17+ / macOS 14+)
- [ ] Identify source file locations

### 2. Conflict Detection
Search for existing share/export code:
```
Glob: **/*ShareCard*.swift, **/*ShareImage*.swift, **/*SocialCard*.swift
Grep: "ImageRenderer" or "ShareLink" or "UIGraphicsImageRenderer" or "share.*image"
```

If existing share infrastructure found:
- Ask if user wants to replace or extend it
- If extending, integrate with existing models and styles

### 3. Platform Detection
Determine if generating for iOS (`UIImage`) or macOS (`NSImage`) or both (cross-platform `PlatformImage` typealias).

## Configuration Questions

Ask user via AskUserQuestion:

1. **Card style?**
   - Minimal (clean, text-focused, light/dark adaptive)
   - Branded (app logo, brand colors, custom typography)
   - Statistics (data-heavy with charts/numbers emphasis)

2. **Share destinations?**
   - Social media (Instagram, Twitter/X — optimized aspect ratios)
   - Messages / General sharing (flexible sizing)
   - Both — recommended

3. **Card size preset?**
   - Square (1080x1080 — Instagram, general purpose)
   - Story (1080x1920 — Instagram Stories, TikTok)
   - Wide (1200x630 — Twitter/X, Open Graph)
   - Custom (user-specified dimensions)

4. **Include QR code?**
   - Yes (deep link or App Store URL embedded in card corner)
   - No (cleaner card, no link)

5. **Content types?** (multi-select)
   - Achievements / Milestones
   - Statistics / Progress
   - Quotes / Text content
   - Custom (user defines their own content model)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code.

### Step 2: Create Core Files
Generate these files:
1. `ShareCardContent.swift` — Protocol and concrete content types (achievement, statistics, quote)
2. `ShareCardStyle.swift` — Enum with predefined styles, colors, fonts, layout configuration
3. `ShareCardRenderer.swift` — `@MainActor` renderer using `ImageRenderer` to convert SwiftUI views to images
4. `ShareCardView.swift` — The SwiftUI view that composes the card layout (background, content, branding)

### Step 3: Create UI Files
5. `ShareCardSheet.swift` — Complete sharing sheet with style picker, live preview, and `ShareLink`

### Step 4: Create Optional Files
Based on configuration:
- `QRCodeOverlay.swift` — If QR code selected (CoreImage-based QR generator)
- `ShareCardPreview.swift` — SwiftUI Preview helpers for design iteration

### Step 5: Determine File Location
Check project structure:
- If `Sources/` exists -> `Sources/ShareCard/`
- If `App/` exists -> `App/ShareCard/`
- Otherwise -> `ShareCard/`

## Output Format

After generation, provide:

### Files Created
```
ShareCard/
├── ShareCardContent.swift    # Protocol + concrete content types
├── ShareCardStyle.swift      # Style enum with colors, fonts, layout
├── ShareCardRenderer.swift   # ImageRenderer-based rendering
├── ShareCardView.swift       # Card layout SwiftUI view
├── ShareCardSheet.swift      # Share sheet with preview + ShareLink
├── QRCodeOverlay.swift       # CoreImage QR code (optional)
└── ShareCardPreview.swift    # Preview helpers (optional)
```

### Integration Steps

**Share an achievement:**
```swift
struct AchievementDetailView: View {
    let achievement: Achievement
    @State private var showShareCard = false

    var body: some View {
        VStack {
            // ... achievement detail content ...

            Button("Share Achievement") {
                showShareCard = true
            }
        }
        .sheet(isPresented: $showShareCard) {
            ShareCardSheet(
                content: AchievementCardContent(
                    title: achievement.title,
                    subtitle: achievement.description,
                    metric: "\(achievement.points) pts",
                    iconName: achievement.iconName,
                    brandName: "MyApp"
                )
            )
        }
    }
}
```

**Share statistics:**
```swift
ShareCardSheet(
    content: StatisticsCardContent(
        title: "Weekly Progress",
        stats: [
            StatItem(label: "Steps", value: "52,340"),
            StatItem(label: "Calories", value: "3,200"),
            StatItem(label: "Distance", value: "28.5 km"),
        ],
        brandName: "FitTracker"
    )
)
```

**Share a quote:**
```swift
ShareCardSheet(
    content: QuoteCardContent(
        quote: "The only way to do great work is to love what you do.",
        attribution: "Steve Jobs",
        brandName: "DailyQuotes"
    )
)
```

**Inline ShareLink (without sheet):**
```swift
struct QuickShareButton: View {
    let content: any ShareCardContent
    @State private var renderedImage: PlatformImage?

    var body: some View {
        Group {
            if let image = renderedImage {
                ShareLink(
                    item: Image(platformImage: image),
                    preview: SharePreview(content.title, image: Image(platformImage: image))
                )
            } else {
                ProgressView()
            }
        }
        .task {
            let renderer = ShareCardRenderer()
            renderedImage = await renderer.render(content: content, style: .branded)
        }
    }
}
```

### Testing

```swift
@Test
func rendersAchievementCard() async throws {
    let content = AchievementCardContent(
        title: "First Run",
        subtitle: "Completed your first 5K run",
        metric: "500 pts",
        iconName: "figure.run",
        brandName: "FitApp"
    )

    let renderer = ShareCardRenderer()
    let image = await renderer.render(content: content, style: .branded)
    #expect(image != nil)
    #expect(image!.size.width > 0)
    #expect(image!.size.height > 0)
}

@Test
func allStylesRenderSuccessfully() async throws {
    let content = QuoteCardContent(
        quote: "Test quote",
        attribution: "Author",
        brandName: "App"
    )

    let renderer = ShareCardRenderer()
    for style in ShareCardStyle.allCases {
        let image = await renderer.render(content: content, style: style)
        #expect(image != nil, "Style \(style) failed to render")
    }
}

@Test
func qrCodeGeneratesValidImage() throws {
    let image = QRCodeGenerator.generate(
        from: "https://example.com/share/123",
        size: CGSize(width: 100, height: 100)
    )
    #expect(image != nil)
}
```

## Common Patterns

### Achievement Card
Best for: gamification, milestones, unlockables.
- Large icon or badge at top
- Achievement title prominently displayed
- Metric or point value highlighted
- App branding at bottom

### Statistics Card
Best for: fitness, finance, productivity apps.
- Grid or list of stat items with labels and values
- Optional trend indicators (up/down arrows)
- Date range context
- App branding at bottom

### Quote Card
Best for: reading, journaling, social apps.
- Large quotation marks or decorative element
- Quote text centered with elegant typography
- Attribution below quote
- Minimal branding

## Gotchas

### Image Quality for Different Platforms
- Instagram: JPEG works, but use high quality (0.9+) to avoid artifacts on text
- Twitter/X: PNG preserves text sharpness but larger file size
- Use `@2x` scale factor in `ImageRenderer` for Retina-quality output
- Always render at the display scale: `renderer.scale = UIScreen.main.scale` (iOS) or `NSScreen.main?.backingScaleFactor` (macOS)

### Memory for Large Renders
- A 1080x1920 card at `@3x` scale = 3240x5760 pixels = ~75 MB in memory
- Render at `@2x` maximum for share cards — social platforms compress anyway
- Release the rendered image after sharing completes
- Use `autoreleasepool` if generating multiple cards in sequence

### ImageRenderer Limitations
- `ImageRenderer` is `@MainActor` — must be called from the main thread
- Minimum iOS 16 / macOS 13
- Does not render `Map`, `Camera`, or `WebView` content
- Animations are not captured — renders a single frame
- `ScrollView` content beyond visible bounds is not rendered

### Cross-Platform Rendering
- On macOS, `ImageRenderer` produces `NSImage` via `nsImage` property
- On iOS, use `uiImage` property
- Use the `PlatformImage` typealias pattern for shared code
- `UIGraphicsImageRenderer` is UIKit-only — prefer `ImageRenderer` for SwiftUI cross-platform code

### ShareLink Gotchas
- `ShareLink` requires the shared item to conform to `Transferable`
- `Image` conforms to `Transferable` on iOS 16+ / macOS 13+
- For custom share items, implement `Transferable` with `DataRepresentation`
- `ShareLink` renders as a button — style it to match your UI

## References

- **templates.md** — All production Swift templates
- Related: `generators/image-loading` — Cache rendered share card images
- Related: `ios/deep-linking` — Generate deep links for QR codes
