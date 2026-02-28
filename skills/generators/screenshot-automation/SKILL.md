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

### Step 2: Create App-Side Screenshot Mode
Generate:
1. `ScreenshotModeController.swift` -- **Add to the app target (not tests)**. Detects `--screenshot-mode` launch argument and configures the app: suppresses onboarding, disables analytics/IAP, loads sample data, sizes windows (macOS). Also provides `@Environment(\.isScreenshotMode)` for views to hide promotional UI during capture.

Tell the user to:
- Call `ScreenshotModeController.shared.configureIfNeeded()` in their App's `init()`
- Call `ScreenshotModeController.shared.configureWindow()` in their root view's `onAppear`
- Override `loadSampleData()` to populate their data store with attractive content

### Step 3: Create Configuration
Generate:
2. `ScreenshotPlan.swift` -- Defines screens to capture, devices, locales, and output paths

### Step 4: Create UI Test Files
Generate:
3. `ScreenshotUITests.swift` -- XCUITest class that navigates and captures each screen
4. `ScreenshotTestHelper.swift` -- Helper utilities for locale setup, data seeding, alert dismissal, plus `tapUnhittable()` extension for custom controls

### Step 5: Create Post-Processing Files
Generate:
5. `ScreenshotProcessor.swift` -- Loads captured images, routes through framing and captioning
6. `CaptionOverlay.swift` -- Renders localized marketing text onto screenshot images

For macOS-only or lightweight needs, offer `sips-screenshot-process.sh` as an alternative to the Swift processor. Uses macOS's built-in `sips` command — zero dependencies.

### Step 6: Create Export Script
Generate:
7. `ScreenshotExportScript.swift` -- End-to-end pipeline script: build, test, process, organize

For macOS apps, also generate:
8. `macos-screenshot-env.sh` -- Desktop preparation script (hides dock, desktop icons, simplifies clock) with `trap`-based cleanup

### Step 7: Create Sample Content Generator
If the user needs realistic sample data for screenshots:
9. `SampleContentGenerator.swift` -- Provides text content, chart data, placeholder images, and PDF generation (macOS). Category-specific sample titles for productivity, fitness, finance, and notes apps.

### Step 8: Create Xcode Test Plan
Generate:
10. `ScreenshotTests.xctestplan` -- Dedicated test plan that isolates screenshot tests from development tests. Prevents screenshot tests from running during `Cmd+U`.

Tell the user to:
- Save to project root
- Add to their scheme via Product → Scheme → Edit Scheme → Test → add plan
- Run with: `xcodebuild test -testPlan "ScreenshotTests" ...`

### Step 9: Determine File Locations
Check project structure:
- `ScreenshotModeController.swift` goes into the **app target** source directory
- `SampleContentGenerator.swift` goes into the **app target** source directory
- UI test files go into the existing `*UITests/` target directory
- Processing files go into a `ScreenshotAutomation/` group or `Scripts/` directory
- Shell scripts go into `Scripts/` directory
- Test plan goes into the project root
- If `Sources/` exists -> `Sources/ScreenshotAutomation/`
- Otherwise -> `ScreenshotAutomation/`

## Output Format

After generation, provide:

### Files Created
```
App Target (source directory):
├── ScreenshotModeController.swift  # App-side screenshot mode detection & config
└── SampleContentGenerator.swift    # Realistic sample data for screenshots

UITests Target:
├── ScreenshotUITests.swift         # XCUITest capture class
└── ScreenshotTestHelper.swift      # Helper: locale, seeding, alerts, tapUnhittable()

ScreenshotAutomation/:
├── ScreenshotPlan.swift            # Configuration: screens, devices, locales
├── ScreenshotProcessor.swift       # Post-processing orchestrator
├── CaptionOverlay.swift            # Localized text overlay renderer
└── ScreenshotExportScript.swift    # Full pipeline script

Scripts/ (shell scripts):
├── sips-screenshot-process.sh      # Lightweight sips-based image processing
└── macos-screenshot-env.sh         # macOS desktop prep with trap cleanup

Project Root:
└── ScreenshotTests.xctestplan      # Dedicated test plan for screenshots
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
  - Mac Retina: 2880 x 1800 (landscape)
- Alphabetical file ordering determines screenshot order in App Store Connect

### Landscape Screenshots
- Some apps benefit from landscape screenshots (games, productivity)
- UI tests must explicitly rotate: `XCUIDevice.shared.orientation = .landscapeLeft`
- Remember to rotate back after capture

### macOS: Asymmetric Window Borders
- macOS windows have different border thickness at the top (title bar) vs bottom
- The bottom ~3px typically gets cropped during resize-to-fit
- `ScreenshotModeController` accounts for this by adding `bottomBorderPadding` when sizing windows
- If cropping manually with `sips`, crop from the bottom edge, not centered

### macOS: Desktop Environment
- Unlike iOS simulators, macOS screenshots capture the real desktop behind your app
- Use `macos-screenshot-env.sh` to hide dock, desktop icons, and simplify the clock
- The script uses `trap` handlers to restore settings even on Ctrl+C or failure
- Run the desktop prep script before launching tests, not from within the test

### macOS: Window Sizing for App Store
- Mac App Store requires 2880×1800 (Retina) or minimum 1280×800
- `ScreenshotModeController.configureWindow()` sizes the window to fill the required dimensions
- For non-full-screen apps, account for the title bar (28pt) and menu bar in your layout

### Custom Controls and tapUnhittable()
- Custom tab bars, overlapping views, and controls behind transparent overlays often don't report as hittable in XCUITest
- Use the `tapUnhittable()` extension from `ScreenshotTestHelper.swift` to tap by coordinate
- Assign unique accessibility identifiers to all custom controls used in screenshot navigation (e.g., `"pageStrip.page.1"`)

### Isolating Screenshot Tests
- Screenshot tests are slow and should NOT run during normal `Cmd+U` test cycles
- Generate `ScreenshotTests.xctestplan` and add it as a separate test plan in your scheme
- Run screenshots explicitly: `xcodebuild test -testPlan "ScreenshotTests" ...`
- This also prevents accidental test failures from blocking development

## References

- **templates.md** -- All production Swift/XCTest templates for screenshot automation:
  - `ScreenshotModeController.swift` -- App-side screenshot mode detection
  - `ScreenshotPlan.swift` -- Screen/device/locale configuration
  - `ScreenshotUITests.swift` -- XCUITest capture class
  - `ScreenshotTestHelper.swift` -- Helpers + `tapUnhittable()` extension
  - `ScreenshotProcessor.swift` -- Post-processing orchestrator
  - `CaptionOverlay.swift` -- Localized text overlay renderer
  - `ScreenshotExportScript.swift` -- Full pipeline script
  - `sips-screenshot-process.sh` -- Lightweight macOS image processing
  - `macos-screenshot-env.sh` -- Desktop preparation with trap cleanup
  - `SampleContentGenerator.swift` -- Realistic sample data patterns
  - `ScreenshotTests.xctestplan` -- Dedicated Xcode test plan
- Related: `generators/localization-setup` -- Setting up localization infrastructure
- Related: `app-store/screenshot-planner` -- Planning screenshot content and marketing messaging
