---
name: screenshot-automation
description: Generates an automated App Store screenshot pipeline with UI tests for screenshot capture, device framing, localized caption overlays, and multi-size batch export. Use when user wants automated screenshots, App Store screenshot generation, or a fastlane snapshot replacement.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Screenshot Automation Generator

Generate an automated App Store screenshot pipeline that captures screenshots via UI tests, adds localized marketing captions, applies device frames, and exports all required sizes for App Store Connect. Saves hours of manual screenshot creation every release.

## When This Skill Activates

Use this skill when the user:
- Asks about "screenshot automation" or "automate screenshots"
- Wants to generate "App Store screenshots" or "store screenshots"
- Mentions "automated screenshots" or "screenshot pipeline"
- Asks to "generate screenshots" or "batch screenshots"
- Wants "screenshot testing" or "UI test screenshots"
- Mentions "fastlane snapshot" or wants a replacement for it

## Pre-Generation Checks

### 1. Project Context Detection
- [ ] Check Swift version (requires Swift 5.9+)
- [ ] Check deployment target (iOS 16+ / macOS 13+)
- [ ] Identify existing UI test target (look for `*UITests` target)
- [ ] Check for existing UI test files
- [ ] Check for fastlane presence (`Fastfile`, `Snapfile`)

### 2. Conflict Detection
Search for existing screenshot infrastructure:
```
Glob: **/*Screenshot*.swift, **/*Snapshot*.swift, **/Snapfile, **/Fastfile
Grep: "XCTAttachment" or "screenshot" or "snapshot" in UI test files
```

If fastlane snapshot already configured:
- Ask if user wants to replace or augment it
- If keeping fastlane, generate only the post-processing pipeline

### 3. Localization Detection
Check for existing localization setup:
```
Glob: **/*.lproj/*.strings, **/*Localizable*, **/*.xcstrings
```
Determine which locales are already configured in the project.

## Configuration Questions

Ask user via AskUserQuestion:

1. **Screenshot capture method?**
   - XCUITest only (pure Apple, no dependencies)
   - fastlane snapshot (uses fastlane tooling)
   - Both (XCUITest capture + fastlane orchestration)

2. **Target devices?** (multi-select)
   - iPhone 6.7" (iPhone 15 Pro Max / 16 Pro Max) -- required for App Store
   - iPhone 6.5" (iPhone 11 Pro Max / XS Max) -- required for older slot
   - iPhone 5.5" (iPhone 8 Plus) -- optional legacy
   - iPad 12.9" (iPad Pro 6th gen) -- required if universal app
   - iPad 11" (iPad Air) -- optional

3. **Locales?**
   - en-US only
   - en-US + (list additional locales, e.g., de-DE, ja-JP, fr-FR, es-ES, zh-Hans)
   - Match existing project localizations

4. **Include device frames?**
   - Yes (wrap screenshots in device bezels for marketing)
   - No (raw screenshots only)

5. **Caption overlay style?**
   - Top (marketing text above the screenshot)
   - Bottom (marketing text below the screenshot)
   - None (no text overlay, raw screenshot or framed only)

## Generation Process

### Step 1: Read Templates
Read `templates.md` for production Swift code and scripts.

### Step 2: Create Configuration
Generate:
1. `ScreenshotPlan.swift` -- Defines screens to capture, devices, locales, and output paths

### Step 3: Create UI Test Files
Generate:
2. `ScreenshotUITests.swift` -- XCUITest class that navigates and captures each screen
3. `ScreenshotTestHelper.swift` -- Helper utilities for locale setup, data seeding, alert dismissal

### Step 4: Create Post-Processing Files
Generate:
4. `ScreenshotProcessor.swift` -- Loads captured images, routes through framing and captioning
5. `CaptionOverlay.swift` -- Renders localized marketing text onto screenshot images

### Step 5: Create Export Script
Generate:
6. `ScreenshotExportScript.swift` -- End-to-end pipeline script: build, test, process, organize

### Step 6: Determine File Locations
Check project structure:
- UI test files go into the existing `*UITests/` target directory
- Processing files go into a `ScreenshotAutomation/` group or `Scripts/` directory
- If `Sources/` exists -> `Sources/ScreenshotAutomation/`
- Otherwise -> `ScreenshotAutomation/`

## Output Format

After generation, provide:

### Files Created
```
ScreenshotAutomation/
├── ScreenshotPlan.swift          # Configuration: screens, devices, locales
├── ScreenshotUITests.swift       # XCUITest capture class
├── ScreenshotTestHelper.swift    # Helper: locale, seeding, alerts
├── ScreenshotProcessor.swift     # Post-processing orchestrator
├── CaptionOverlay.swift          # Localized text overlay renderer
└── ScreenshotExportScript.swift  # Full pipeline script
```

### Integration with CI

**Xcode Cloud:**
```yaml
# ci_scripts/ci_post_xcodebuild.sh
if [ "$CI_WORKFLOW" = "Screenshots" ]; then
    swift ScreenshotAutomation/ScreenshotExportScript.swift
fi
```

**GitHub Actions:**
```yaml
- name: Generate Screenshots
  run: |
    xcodebuild test \
      -scheme "YourAppUITests" \
      -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
      -testPlan ScreenshotPlan \
      -resultBundlePath screenshots.xcresult
    swift ScreenshotAutomation/ScreenshotExportScript.swift
```

**fastlane (if selected):**
```ruby
lane :screenshots do
  capture_screenshots(scheme: "YourAppUITests")
  # Post-processing handled by ScreenshotProcessor
end
```

### Testing and Running

**Run screenshot tests from Xcode:**
```bash
xcodebuild test \
  -project YourApp.xcodeproj \
  -scheme "YourAppUITests" \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
  -only-testing "YourAppUITests/ScreenshotUITests"
```

**Run the full pipeline:**
```bash
swift ScreenshotAutomation/ScreenshotExportScript.swift
```

**Verify output directory:**
```
screenshots/
├── en-US/
│   ├── iPhone_6.7/
│   │   ├── 01_HomeScreen.png
│   │   ├── 02_DetailView.png
│   │   └── 03_Settings.png
│   └── iPad_12.9/
│       ├── 01_HomeScreen.png
│       └── ...
├── de-DE/
│   └── ...
└── ja-JP/
    └── ...
```

### Integration Steps

**Add to existing UI test target:**
```swift
// In your UITest scheme, add ScreenshotUITests.swift
// The test class auto-discovers screens from ScreenshotPlan
```

**Localized captions file (Localizable.strings):**
```
// en-US
"screenshot.home" = "Track your goals effortlessly";
"screenshot.detail" = "Deep insights at a glance";
"screenshot.settings" = "Customize everything";

// de-DE
"screenshot.home" = "Verfolgen Sie Ihre Ziele muhelos";
"screenshot.detail" = "Tiefe Einblicke auf einen Blick";
"screenshot.settings" = "Alles anpassen";
```

### Testing

```swift
@Test
func screenshotPlanLoadsAllScreens() throws {
    let plan = ScreenshotPlan.default
    #expect(!plan.screens.isEmpty)
    #expect(plan.screens.allSatisfy { !$0.name.isEmpty })
}

@Test
func captionOverlayRendersText() throws {
    let overlay = CaptionOverlay(
        text: "Track your goals",
        style: .top,
        font: .systemFont(ofSize: 48, weight: .bold),
        textColor: .white
    )
    let sourceImage = PlatformImage.testScreenshot(size: CGSize(width: 1290, height: 2796))
    let result = try overlay.apply(to: sourceImage)
    #expect(result.size.height > sourceImage.size.height)
}

@Test
func processorOrganizesOutputByLocaleAndDevice() async throws {
    let processor = ScreenshotProcessor(outputDirectory: tempDir)
    let screenshot = CapturedScreenshot(
        name: "01_HomeScreen",
        image: .testScreenshot(),
        locale: "en-US",
        device: .iPhone6_7
    )
    try await processor.process([screenshot])

    let outputPath = tempDir
        .appendingPathComponent("en-US")
        .appendingPathComponent("iPhone_6.7")
        .appendingPathComponent("01_HomeScreen.png")
    #expect(FileManager.default.fileExists(atPath: outputPath.path))
}
```

## Common Patterns

### Capture Key Screens
Identify 6-10 screens that showcase the app's value proposition. Order them for maximum impact -- the first screenshot is the most important in App Store search results.

### Add Captions
Marketing text should be short (3-6 words), benefit-focused, and localized. Use the app's brand fonts when possible.

### Frame and Export
Device frames add professionalism. Export at exact App Store Connect required resolutions to avoid rejection.

### Batch All Locales
Run the full pipeline once to generate screenshots for every locale simultaneously. Each locale uses its own localized strings and sample data.

## Gotchas

### Simulator vs Device Differences
- Simulators render slightly different font weights and colors than real devices
- Status bar content varies (carrier name, time) -- use `XCUIDevice.shared.appearance` to set a consistent state
- Always set a fixed time in the status bar: override with `simctl status_bar`

### Dark Mode Screenshots
- Capture both light and dark mode variants by toggling `UITraitCollection.current` or using launch arguments
- Name files distinctly: `01_HomeScreen_light.png`, `01_HomeScreen_dark.png`
- App Store Connect allows separate dark mode screenshot sets (iOS 18+)

### Dynamic Type Screenshots
- Consider capturing at default text size for consistency
- If accessibility is a selling point, include one screenshot at larger Dynamic Type

### Screenshot Naming Convention for App Store Connect
- Files must be PNG format
- Exact pixel dimensions must match device slot requirements:
  - iPhone 6.7": 1290 x 2796 (portrait) or 2796 x 1290 (landscape)
  - iPhone 6.5": 1242 x 2688 (portrait) or 2688 x 1242 (landscape)
  - iPhone 5.5": 1242 x 2208 (portrait) or 2208 x 1242 (landscape)
  - iPad 12.9": 2048 x 2732 (portrait) or 2732 x 2048 (landscape)
  - iPad 11": 1668 x 2388 (portrait) or 2388 x 1668 (landscape)
- Alphabetical file ordering determines screenshot order in App Store Connect

### Landscape Screenshots
- Some apps benefit from landscape screenshots (games, productivity)
- UI tests must explicitly rotate: `XCUIDevice.shared.orientation = .landscapeLeft`
- Remember to rotate back after capture

## References

- **templates.md** -- All production Swift/XCTest templates for screenshot automation
- Related: `generators/localization-setup` -- Setting up localization infrastructure
- Related: `app-store/screenshot-planner` -- Planning screenshot content and marketing messaging
