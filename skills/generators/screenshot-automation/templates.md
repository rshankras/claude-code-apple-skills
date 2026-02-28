# Screenshot Automation Code Templates

Production-ready Swift templates for automated App Store screenshot generation. All code targets iOS 16+ / macOS 13+ and uses XCUITest for capture with CoreGraphics for post-processing.

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

## ScreenshotPlan.swift

```swift
import Foundation

/// Configuration defining which screens to capture, on which devices, and in which locales.
///
/// Usage:
/// ```swift
/// let plan = ScreenshotPlan.default
/// for screen in plan.screens {
///     // Navigate to screen.name, then capture
/// }
/// ```
struct ScreenshotPlan: Codable, Sendable {

    /// A single screen to capture.
    struct Screen: Codable, Sendable {
        /// Display name used in output filename (e.g., "01_HomeScreen").
        let name: String

        /// Ordered steps to navigate to this screen from app launch.
        let setupSteps: [NavigationStep]

        /// Optional: override locale for this screen only.
        let localeOverride: String?

        /// Whether to capture in landscape orientation.
        let landscape: Bool

        init(
            name: String,
            setupSteps: [NavigationStep],
            localeOverride: String? = nil,
            landscape: Bool = false
        ) {
            self.name = name
            self.setupSteps = setupSteps
            self.localeOverride = localeOverride
            self.landscape = landscape
        }
    }

    /// A navigation action to reach a screen.
    enum NavigationStep: Codable, Sendable {
        case tapButton(identifier: String)
        case tapCell(identifier: String)
        case tapTabBarItem(identifier: String)
        case swipeLeft
        case swipeRight
        case typeText(identifier: String, text: String)
        case wait(seconds: TimeInterval)
        case dismissAlert
        case custom(description: String)
    }

    /// Target device specifications.
    enum Device: String, Codable, Sendable, CaseIterable {
        case iPhone6_7 = "iPhone_6.7"
        case iPhone6_5 = "iPhone_6.5"
        case iPhone5_5 = "iPhone_5.5"
        case iPad12_9 = "iPad_12.9"
        case iPad11 = "iPad_11"

        /// Simulator device name for xcodebuild destination.
        var simulatorName: String {
            switch self {
            case .iPhone6_7: return "iPhone 16 Pro Max"
            case .iPhone6_5: return "iPhone 11 Pro Max"
            case .iPhone5_5: return "iPhone 8 Plus"
            case .iPad12_9: return "iPad Pro (12.9-inch) (6th generation)"
            case .iPad11: return "iPad Air (5th generation)"
            }
        }

        /// Expected screenshot pixel dimensions (portrait).
        var screenshotSize: CGSize {
            switch self {
            case .iPhone6_7: return CGSize(width: 1290, height: 2796)
            case .iPhone6_5: return CGSize(width: 1242, height: 2688)
            case .iPhone5_5: return CGSize(width: 1242, height: 2208)
            case .iPad12_9: return CGSize(width: 2048, height: 2732)
            case .iPad11: return CGSize(width: 1668, height: 2388)
            }
        }
    }

    /// Screens to capture, in order.
    let screens: [Screen]

    /// Devices to generate screenshots for.
    let devices: [Device]

    /// Locales to generate screenshots for.
    let locales: [String]

    /// Output root directory.
    let outputDirectory: String

    /// Whether to include device frames in output.
    let includeDeviceFrames: Bool

    /// Caption overlay style.
    let captionStyle: CaptionStyle

    enum CaptionStyle: String, Codable, Sendable {
        case top
        case bottom
        case none
    }
}

// MARK: - Default Configuration

extension ScreenshotPlan {

    /// Default plan -- customize per project.
    static let `default` = ScreenshotPlan(
        screens: [
            Screen(
                name: "01_HomeScreen",
                setupSteps: [.wait(seconds: 1)]
            ),
            Screen(
                name: "02_DetailView",
                setupSteps: [
                    .tapCell(identifier: "item_cell_0"),
                    .wait(seconds: 0.5)
                ]
            ),
            Screen(
                name: "03_Search",
                setupSteps: [
                    .tapTabBarItem(identifier: "Search"),
                    .wait(seconds: 0.5)
                ]
            ),
            Screen(
                name: "04_Profile",
                setupSteps: [
                    .tapTabBarItem(identifier: "Profile"),
                    .wait(seconds: 0.5)
                ]
            ),
            Screen(
                name: "05_Settings",
                setupSteps: [
                    .tapTabBarItem(identifier: "Profile"),
                    .tapButton(identifier: "settings_button"),
                    .wait(seconds: 0.5)
                ]
            )
        ],
        devices: [.iPhone6_7, .iPhone6_5, .iPad12_9],
        locales: ["en-US"],
        outputDirectory: "screenshots",
        includeDeviceFrames: true,
        captionStyle: .top
    )
}
```

## ScreenshotUITests.swift

```swift
import XCTest

/// UI test class that captures screenshots for all screens defined in ScreenshotPlan.
///
/// Run with:
/// ```bash
/// xcodebuild test \
///   -scheme "YourAppUITests" \
///   -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
///   -only-testing "YourAppUITests/ScreenshotUITests"
/// ```
final class ScreenshotUITests: XCTestCase {

    private var app: XCUIApplication!
    private let helper = ScreenshotTestHelper()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()

        // Enable screenshot mode via launch argument
        app.launchArguments += ["-ScreenshotMode", "YES"]

        // Disable animations for consistent captures
        app.launchArguments += ["-UIViewAnimationDuration", "0"]
        app.launchArguments += ["-CALayerAnimationDuration", "0"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Screenshot Capture

    /// Captures all screens defined in ScreenshotPlan for the current locale.
    func testCaptureAllScreenshots() throws {
        let plan = ScreenshotPlan.default

        for locale in plan.locales {
            // Configure locale
            app.launchArguments += ["-AppleLanguages", "(\(locale))"]
            app.launchArguments += ["-AppleLocale", locale]
            app.launch()

            // Bypass onboarding if present
            helper.bypassOnboarding(app: app)

            // Seed sample data for attractive screenshots
            helper.seedSampleData(app: app)

            // Wait for initial load
            helper.waitForLoad(app: app)

            // Capture each screen
            for screen in plan.screens {
                try captureScreen(screen, locale: locale)

                // Return to root for next screen
                helper.returnToRoot(app: app)
            }
        }
    }

    /// Captures a single screen by executing its navigation steps.
    private func captureScreen(_ screen: ScreenshotPlan.Screen, locale: String) throws {
        // Set orientation
        if screen.landscape {
            XCUIDevice.shared.orientation = .landscapeLeft
        } else {
            XCUIDevice.shared.orientation = .portrait
        }

        // Execute navigation steps
        for step in screen.setupSteps {
            try executeStep(step)
        }

        // Allow UI to settle
        Thread.sleep(forTimeInterval: 0.3)

        // Capture and attach screenshot
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(locale)_\(screen.name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Executes a single navigation step.
    private func executeStep(_ step: ScreenshotPlan.NavigationStep) throws {
        switch step {
        case .tapButton(let identifier):
            let button = app.buttons[identifier]
            XCTAssertTrue(
                button.waitForExistence(timeout: 5),
                "Button '\(identifier)' not found"
            )
            button.tap()

        case .tapCell(let identifier):
            let cell = app.cells[identifier]
            XCTAssertTrue(
                cell.waitForExistence(timeout: 5),
                "Cell '\(identifier)' not found"
            )
            cell.tap()

        case .tapTabBarItem(let identifier):
            let tabBarItem = app.tabBars.buttons[identifier]
            XCTAssertTrue(
                tabBarItem.waitForExistence(timeout: 5),
                "Tab bar item '\(identifier)' not found"
            )
            tabBarItem.tap()

        case .swipeLeft:
            app.swipeLeft()

        case .swipeRight:
            app.swipeRight()

        case .typeText(let identifier, let text):
            let textField = app.textFields[identifier]
            XCTAssertTrue(
                textField.waitForExistence(timeout: 5),
                "Text field '\(identifier)' not found"
            )
            textField.tap()
            textField.typeText(text)

        case .wait(let seconds):
            Thread.sleep(forTimeInterval: seconds)

        case .dismissAlert:
            helper.dismissSystemAlerts(app: app)

        case .custom:
            // Override in subclass for custom navigation
            break
        }
    }

    // MARK: - Dark Mode Variant

    /// Captures all screens in dark mode.
    func testCaptureAllScreenshotsDarkMode() throws {
        let plan = ScreenshotPlan.default

        for locale in plan.locales {
            app.launchArguments += ["-AppleLanguages", "(\(locale))"]
            app.launchArguments += ["-AppleLocale", locale]
            app.launchArguments += ["-UIUserInterfaceStyle", "Dark"]
            app.launch()

            helper.bypassOnboarding(app: app)
            helper.seedSampleData(app: app)
            helper.waitForLoad(app: app)

            for screen in plan.screens {
                try captureScreen(
                    ScreenshotPlan.Screen(
                        name: "\(screen.name)_dark",
                        setupSteps: screen.setupSteps,
                        localeOverride: screen.localeOverride,
                        landscape: screen.landscape
                    ),
                    locale: locale
                )
                helper.returnToRoot(app: app)
            }
        }
    }
}
```

## ScreenshotTestHelper.swift

```swift
import XCTest

/// Helper utilities for screenshot UI tests.
///
/// Handles common tasks like bypassing onboarding, seeding sample data,
/// dismissing system alerts, and waiting for content to load.
struct ScreenshotTestHelper {

    // MARK: - Locale Setup

    /// Sets the app locale via launch arguments.
    ///
    /// Call before `app.launch()`.
    func setLocale(_ locale: String, on app: XCUIApplication) {
        app.launchArguments += ["-AppleLanguages", "(\(locale))"]
        app.launchArguments += ["-AppleLocale", locale]
    }

    // MARK: - Sample Data Seeding

    /// Seeds the app with attractive sample data for screenshots.
    ///
    /// The app should check for the `-ScreenshotMode` launch argument
    /// and load pre-configured sample data when present.
    ///
    /// In your app's launch code:
    /// ```swift
    /// if ProcessInfo.processInfo.arguments.contains("-ScreenshotMode") {
    ///     DataStore.shared.loadScreenshotSampleData()
    /// }
    /// ```
    func seedSampleData(app: XCUIApplication) {
        // Data seeding is handled via launch argument "-ScreenshotMode"
        // The app itself loads sample data when this flag is present
    }

    // MARK: - Onboarding Bypass

    /// Bypasses onboarding screens if they appear.
    ///
    /// The app should check for the `-SkipOnboarding` launch argument.
    /// As a fallback, this method taps through common onboarding patterns.
    func bypassOnboarding(app: XCUIApplication) {
        // Primary: launch argument handled by the app
        // Fallback: tap through onboarding buttons
        let skipButtons = ["Skip", "Continue", "Get Started", "Next"]

        for buttonLabel in skipButtons {
            let button = app.buttons[buttonLabel]
            if button.waitForExistence(timeout: 2) {
                button.tap()
            }
        }
    }

    // MARK: - System Alert Dismissal

    /// Dismisses system permission alerts (notifications, location, etc.).
    ///
    /// Call after app launch if the app requests permissions on first launch.
    func dismissSystemAlerts(app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButtons = ["Allow", "Allow While Using App", "OK", "Don't Allow"]

        for buttonLabel in allowButtons {
            let button = springboard.buttons[buttonLabel]
            if button.waitForExistence(timeout: 2) {
                button.tap()
            }
        }
    }

    // MARK: - Wait for Load

    /// Waits for the app's main content to finish loading.
    ///
    /// Uses a combination of activity indicator absence and element existence.
    func waitForLoad(app: XCUIApplication, timeout: TimeInterval = 10) {
        // Wait for any loading indicators to disappear
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            let disappeared = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(
                predicate: disappeared,
                object: loadingIndicator
            )
            _ = XCTWaiter.wait(for: [expectation], timeout: timeout)
        }

        // Additional settle time for animations
        Thread.sleep(forTimeInterval: 0.5)
    }

    // MARK: - Navigation Helpers

    /// Returns to the root view by tapping the back button repeatedly.
    func returnToRoot(app: XCUIApplication) {
        // Tap back buttons until we're at root
        for _ in 0..<5 {
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.exists && backButton.isHittable {
                backButton.tap()
                Thread.sleep(forTimeInterval: 0.2)
            } else {
                break
            }
        }
    }

    // MARK: - Status Bar Configuration

    /// Configures the simulator status bar for clean screenshots.
    ///
    /// Run this before launching tests:
    /// ```bash
    /// xcrun simctl status_bar "iPhone 16 Pro Max" override \
    ///   --time "9:41" \
    ///   --batteryState charged \
    ///   --batteryLevel 100 \
    ///   --wifiBars 3 \
    ///   --cellularBars 4 \
    ///   --operatorName ""
    /// ```
    static func configureStatusBar(simulatorName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "simctl", "status_bar", simulatorName, "override",
            "--time", "9:41",
            "--batteryState", "charged",
            "--batteryLevel", "100",
            "--wifiBars", "3",
            "--cellularBars", "4",
            "--operatorName", ""
        ]
        try? process.run()
        process.waitUntilExit()
    }

    // MARK: - Screenshot Naming

    /// Generates a standardized screenshot filename.
    ///
    /// Format: `{locale}_{screenshotName}` (e.g., "en-US_01_HomeScreen")
    /// Alphabetical ordering ensures correct order in App Store Connect.
    func screenshotName(locale: String, screenName: String) -> String {
        "\(locale)_\(screenName)"
    }
}

// MARK: - XCUIElement Unhittable Tap Extension

extension XCUIElement {
    /// Taps an element that XCUITest reports as not hittable.
    ///
    /// Some custom controls (e.g., custom tab bars, overlapping views, controls behind
    /// transparent overlays) don't properly report hittability. This method bypasses
    /// XCUITest's built-in hit testing by calculating the element's center coordinate
    /// and tapping it directly.
    ///
    /// Usage:
    /// ```swift
    /// let customControl = app.otherElements["pageStrip.page.1"]
    /// customControl.tapUnhittable()
    /// ```
    ///
    /// Ref: Common XCUITest workaround for custom controls.
    func tapUnhittable() {
        let center = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.tap()
    }

    /// Force-taps an element at a specific normalized offset.
    ///
    /// Useful when you need to tap a specific region of a non-hittable element,
    /// such as a custom slider track or a segmented control segment.
    ///
    /// - Parameter offset: Normalized offset (0.0-1.0) from the element's origin.
    func tapUnhittable(at offset: CGVector) {
        let point = coordinate(withNormalizedOffset: offset)
        point.tap()
    }
}
```

## ScreenshotProcessor.swift

```swift
import Foundation
import CoreGraphics
import ImageIO

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A captured screenshot with metadata for processing.
struct CapturedScreenshot: Sendable {
    /// Filename without extension (e.g., "01_HomeScreen").
    let name: String

    /// The raw screenshot image.
    let image: PlatformImage

    /// Locale this screenshot was captured in (e.g., "en-US").
    let locale: String

    /// Device this screenshot was captured on.
    let device: ScreenshotPlan.Device
}

/// Orchestrates screenshot post-processing: captioning, device framing, and export.
///
/// Flow: Load captured images -> Add captions -> Add device frames -> Export to organized directory
///
/// Usage:
/// ```swift
/// let processor = ScreenshotProcessor(
///     outputDirectory: URL(fileURLWithPath: "screenshots"),
///     plan: .default
/// )
/// try await processor.process(capturedScreenshots)
/// ```
final class ScreenshotProcessor: Sendable {
    private let outputDirectory: URL
    private let captionOverlay: CaptionOverlay?
    private let deviceFramer: DeviceFramer?
    private let plan: ScreenshotPlan

    init(
        outputDirectory: URL,
        plan: ScreenshotPlan = .default,
        captionOverlay: CaptionOverlay? = nil,
        deviceFramer: DeviceFramer? = nil
    ) {
        self.outputDirectory = outputDirectory
        self.plan = plan

        if plan.captionStyle != .none {
            self.captionOverlay = captionOverlay ?? CaptionOverlay(style: plan.captionStyle)
        } else {
            self.captionOverlay = nil
        }

        if plan.includeDeviceFrames {
            self.deviceFramer = deviceFramer ?? DeviceFramer()
        } else {
            self.deviceFramer = nil
        }
    }

    /// Process all captured screenshots: caption, frame, and export.
    func process(_ screenshots: [CapturedScreenshot]) async throws {
        for screenshot in screenshots {
            var image = screenshot.image

            // Step 1: Add caption overlay (if configured)
            if let captionOverlay {
                let captionKey = "screenshot.\(screenshot.name)"
                let localizedCaption = localizedString(
                    key: captionKey,
                    locale: screenshot.locale
                )
                image = try captionOverlay.apply(
                    to: image,
                    text: localizedCaption,
                    canvasSize: screenshot.device.screenshotSize
                )
            }

            // Step 2: Add device frame (if configured)
            if let deviceFramer {
                image = try deviceFramer.frame(
                    image: image,
                    device: screenshot.device
                )
            }

            // Step 3: Export to organized directory
            try export(
                image: image,
                name: screenshot.name,
                locale: screenshot.locale,
                device: screenshot.device
            )
        }
    }

    // MARK: - Export

    /// Exports a processed image to the organized directory structure.
    ///
    /// Output structure: `{outputDirectory}/{locale}/{device}/{name}.png`
    private func export(
        image: PlatformImage,
        name: String,
        locale: String,
        device: ScreenshotPlan.Device
    ) throws {
        let directory = outputDirectory
            .appendingPathComponent(locale)
            .appendingPathComponent(device.rawValue)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let fileURL = directory.appendingPathComponent("\(name).png")
        let pngData = try pngRepresentation(of: image)
        try pngData.write(to: fileURL)
    }

    /// Converts a PlatformImage to PNG data.
    private func pngRepresentation(of image: PlatformImage) throws -> Data {
        #if canImport(UIKit)
        guard let data = image.pngData() else {
            throw ScreenshotError.exportFailed("Failed to create PNG data")
        }
        return data
        #elseif canImport(AppKit)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.exportFailed("Failed to create PNG data")
        }
        return data
        #endif
    }

    /// Loads a localized string for the given key and locale.
    private func localizedString(key: String, locale: String) -> String {
        guard let bundlePath = Bundle.main.path(
            forResource: locale,
            ofType: "lproj"
        ),
        let bundle = Bundle(path: bundlePath) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    // MARK: - Load from XCResult

    /// Loads captured screenshots from an xcresult bundle.
    ///
    /// Usage:
    /// ```swift
    /// let screenshots = try ScreenshotProcessor.loadFromXCResult(
    ///     at: URL(fileURLWithPath: "screenshots.xcresult"),
    ///     plan: .default
    /// )
    /// ```
    static func loadFromXCResult(
        at resultBundlePath: URL,
        plan: ScreenshotPlan
    ) throws -> [CapturedScreenshot] {
        // Extract attachments from xcresult using xcresulttool
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "xcresulttool", "get",
            "--path", resultBundlePath.path,
            "--format", "json"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        // Parse xcresult JSON to find screenshot attachments
        // Attachment names follow the convention: "{locale}_{screenshotName}"
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ScreenshotError.xcresultParseFailed
        }

        // Implementation varies based on xcresult format version
        // This provides the extraction framework -- adapt parsing to your Xcode version
        _ = json // Suppress unused warning; actual parsing depends on xcresult schema
        return []
    }
}

// MARK: - Device Framer

/// Applies device frame overlays to screenshots.
///
/// Device frame images should be placed in a `DeviceFrames/` directory
/// with naming convention: `frame_{device.rawValue}.png`
struct DeviceFramer: Sendable {
    private let framesDirectory: URL

    init(framesDirectory: URL = Bundle.main.resourceURL ?? URL(fileURLWithPath: "DeviceFrames")) {
        self.framesDirectory = framesDirectory
    }

    /// Composites the screenshot into a device frame.
    func frame(image: PlatformImage, device: ScreenshotPlan.Device) throws -> PlatformImage {
        let framePath = framesDirectory
            .appendingPathComponent("frame_\(device.rawValue).png")

        guard FileManager.default.fileExists(atPath: framePath.path),
              let frameImage = PlatformImage(contentsOfFile: framePath.path) else {
            // No frame available for this device; return original
            return image
        }

        return try compositeScreenshotInFrame(
            screenshot: image,
            frame: frameImage,
            device: device
        )
    }

    /// Composites a screenshot into the device frame using CoreGraphics.
    private func compositeScreenshotInFrame(
        screenshot: PlatformImage,
        frame: PlatformImage,
        device: ScreenshotPlan.Device
    ) throws -> PlatformImage {
        #if canImport(UIKit)
        let frameSize = frame.size
        let renderer = UIGraphicsImageRenderer(size: frameSize)
        return renderer.image { context in
            // Draw screenshot centered in frame (inset by bezel)
            let inset = bezelInset(for: device, frameSize: frameSize)
            screenshot.draw(in: inset)

            // Draw frame on top
            frame.draw(in: CGRect(origin: .zero, size: frameSize))
        }
        #elseif canImport(AppKit)
        let frameSize = frame.size
        let result = NSImage(size: frameSize)
        result.lockFocus()

        let inset = bezelInset(for: device, frameSize: frameSize)
        screenshot.draw(in: inset, from: .zero, operation: .copy, fraction: 1.0)
        frame.draw(in: NSRect(origin: .zero, size: frameSize), from: .zero, operation: .sourceOver, fraction: 1.0)

        result.unlockFocus()
        return result
        #endif
    }

    /// Returns the inset rect where the screenshot should be drawn within the frame.
    ///
    /// These values depend on your specific device frame assets.
    /// Adjust percentages to match your frame image dimensions.
    private func bezelInset(for device: ScreenshotPlan.Device, frameSize: CGSize) -> CGRect {
        // Default inset: 5% from each edge (adjust per your frame assets)
        let insetPercent: CGFloat = 0.05
        return CGRect(
            x: frameSize.width * insetPercent,
            y: frameSize.height * insetPercent,
            width: frameSize.width * (1 - 2 * insetPercent),
            height: frameSize.height * (1 - 2 * insetPercent)
        )
    }
}

// MARK: - Errors

/// Errors specific to screenshot automation.
enum ScreenshotError: Error, LocalizedError {
    case captionRenderFailed(String)
    case exportFailed(String)
    case xcresultParseFailed
    case deviceFrameNotFound(String)

    var errorDescription: String? {
        switch self {
        case .captionRenderFailed(let reason):
            return "Failed to render caption: \(reason)"
        case .exportFailed(let reason):
            return "Failed to export screenshot: \(reason)"
        case .xcresultParseFailed:
            return "Failed to parse xcresult bundle"
        case .deviceFrameNotFound(let device):
            return "Device frame not found for \(device)"
        }
    }
}
```

## CaptionOverlay.swift

```swift
import Foundation
import CoreGraphics
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Renders localized marketing text captions onto screenshot images.
///
/// Supports top and bottom placement, custom fonts, colors, and gradient backgrounds.
/// Uses CoreGraphics for image compositing to produce high-quality output.
///
/// Usage:
/// ```swift
/// let overlay = CaptionOverlay(style: .top)
/// let captioned = try overlay.apply(
///     to: screenshotImage,
///     text: "Track your goals effortlessly",
///     canvasSize: CGSize(width: 1290, height: 2796)
/// )
/// ```
struct CaptionOverlay: Sendable {

    /// Caption placement relative to the screenshot.
    let style: ScreenshotPlan.CaptionStyle

    /// Font for the caption text.
    let font: CTFont

    /// Caption text color.
    let textColor: CGColor

    /// Background color behind the caption area.
    let backgroundColor: CGColor

    /// Optional gradient colors for the caption background (overrides backgroundColor).
    let gradientColors: [CGColor]?

    /// Height of the caption area as a fraction of the total canvas height.
    let captionHeightFraction: CGFloat

    /// Horizontal padding as a fraction of canvas width.
    let horizontalPaddingFraction: CGFloat

    init(
        style: ScreenshotPlan.CaptionStyle,
        fontName: String = "SF Pro Display",
        fontSize: CGFloat = 72,
        fontWeight: CGFloat = 700, // Bold
        textColor: CGColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1),
        backgroundColor: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1),
        gradientColors: [CGColor]? = nil,
        captionHeightFraction: CGFloat = 0.2,
        horizontalPaddingFraction: CGFloat = 0.08
    ) {
        self.style = style

        // Create CTFont with the specified name and size, falling back to system font
        if let ctFont = CTFontCreateWithName(fontName as CFString, fontSize, nil) as CTFont? {
            self.font = ctFont
        } else {
            self.font = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
        }

        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.gradientColors = gradientColors
        self.captionHeightFraction = captionHeightFraction
        self.horizontalPaddingFraction = horizontalPaddingFraction
    }

    /// Applies the caption overlay to a screenshot image.
    ///
    /// - Parameters:
    ///   - image: The source screenshot image.
    ///   - text: The localized marketing caption text.
    ///   - canvasSize: The final output size (typically the device's screenshot size).
    /// - Returns: A new image with the caption rendered on it.
    func apply(
        to image: PlatformImage,
        text: String,
        canvasSize: CGSize
    ) throws -> PlatformImage {
        let captionHeight = canvasSize.height * captionHeightFraction
        let totalHeight = canvasSize.height + captionHeight
        let totalSize = CGSize(width: canvasSize.width, height: totalHeight)

        guard let context = CGContext(
            data: nil,
            width: Int(totalSize.width),
            height: Int(totalSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ScreenshotError.captionRenderFailed("Failed to create CGContext")
        }

        // Determine layout based on style
        let screenshotRect: CGRect
        let captionRect: CGRect

        switch style {
        case .top:
            captionRect = CGRect(
                x: 0,
                y: canvasSize.height, // CoreGraphics origin is bottom-left
                width: totalSize.width,
                height: captionHeight
            )
            screenshotRect = CGRect(
                x: 0,
                y: 0,
                width: canvasSize.width,
                height: canvasSize.height
            )
        case .bottom:
            captionRect = CGRect(
                x: 0,
                y: 0,
                width: totalSize.width,
                height: captionHeight
            )
            screenshotRect = CGRect(
                x: 0,
                y: captionHeight,
                width: canvasSize.width,
                height: canvasSize.height
            )
        case .none:
            // Should not reach here, but handle gracefully
            return image
        }

        // Draw caption background
        drawCaptionBackground(in: context, rect: captionRect)

        // Draw screenshot
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else {
            throw ScreenshotError.captionRenderFailed("Failed to get CGImage from UIImage")
        }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(
            forProposedRect: nil,
            context: nil,
            hints: nil
        ) else {
            throw ScreenshotError.captionRenderFailed("Failed to get CGImage from NSImage")
        }
        #endif

        context.draw(cgImage, in: screenshotRect)

        // Draw caption text
        drawCaptionText(text, in: context, rect: captionRect)

        // Create output image
        guard let outputCGImage = context.makeImage() else {
            throw ScreenshotError.captionRenderFailed("Failed to create output image")
        }

        #if canImport(UIKit)
        return UIImage(cgImage: outputCGImage)
        #elseif canImport(AppKit)
        return NSImage(
            cgImage: outputCGImage,
            size: NSSize(width: totalSize.width, height: totalSize.height)
        )
        #endif
    }

    // MARK: - Private Drawing

    /// Draws the caption background (solid color or gradient).
    private func drawCaptionBackground(in context: CGContext, rect: CGRect) {
        if let gradientColors, gradientColors.count >= 2 {
            // Draw gradient background
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: gradientColors as CFArray,
                locations: nil
            ) else {
                // Fallback to solid color
                context.setFillColor(backgroundColor)
                context.fill(rect)
                return
            }

            context.saveGState()
            context.clip(to: rect)
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.midX, y: rect.minY),
                end: CGPoint(x: rect.midX, y: rect.maxY),
                options: []
            )
            context.restoreGState()
        } else {
            context.setFillColor(backgroundColor)
            context.fill(rect)
        }
    }

    /// Draws centered caption text within the given rect.
    private func drawCaptionText(_ text: String, in context: CGContext, rect: CGRect) {
        let horizontalPadding = rect.width * horizontalPaddingFraction

        // Create attributed string
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)

        // Create framesetter for multi-line text layout
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)

        let textRect = CGRect(
            x: rect.origin.x + horizontalPadding,
            y: rect.origin.y,
            width: rect.width - 2 * horizontalPadding,
            height: rect.height
        )

        // Calculate text size for centering
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, 0),
            nil,
            textRect.size,
            nil
        )

        // Center text vertically within caption area
        let yOffset = (rect.height - suggestedSize.height) / 2
        let centeredRect = CGRect(
            x: textRect.origin.x,
            y: rect.origin.y + yOffset,
            width: textRect.width,
            height: suggestedSize.height
        )

        let path = CGPath(rect: centeredRect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)

        context.saveGState()
        CTFrameDraw(frame, context)
        context.restoreGState()
    }
}
```

## ScreenshotExportScript.swift

```swift
#!/usr/bin/env swift

import Foundation

// MARK: - Screenshot Export Pipeline Script
//
// Runs the full screenshot generation pipeline:
// 1. Configure simulators (status bar, appearance)
// 2. Build the app for testing
// 3. Run UI tests on each target device
// 4. Extract screenshots from xcresult bundles
// 5. Post-process (captions, device frames)
// 6. Organize output for App Store Connect upload
//
// Usage:
//   swift ScreenshotExportScript.swift
//   swift ScreenshotExportScript.swift --locales en-US,de-DE --devices iPhone_6.7,iPad_12.9
//   swift ScreenshotExportScript.swift --skip-frames --skip-captions

// MARK: - Configuration

struct ExportConfig {
    let projectPath: String
    let scheme: String
    let uiTestTarget: String
    let outputDirectory: String
    let locales: [String]
    let devices: [DeviceSpec]
    let skipFrames: Bool
    let skipCaptions: Bool

    struct DeviceSpec {
        let name: String         // Display name for directory
        let simulatorName: String // Xcode simulator identifier
    }

    static func parseArguments() -> ExportConfig {
        let args = CommandLine.arguments
        var locales = ["en-US"]
        var devices = defaultDevices
        var skipFrames = false
        var skipCaptions = false

        for (index, arg) in args.enumerated() {
            switch arg {
            case "--locales":
                if index + 1 < args.count {
                    locales = args[index + 1].components(separatedBy: ",")
                }
            case "--devices":
                if index + 1 < args.count {
                    let deviceNames = args[index + 1].components(separatedBy: ",")
                    devices = defaultDevices.filter { deviceNames.contains($0.name) }
                }
            case "--skip-frames":
                skipFrames = true
            case "--skip-captions":
                skipCaptions = true
            default:
                break
            }
        }

        return ExportConfig(
            projectPath: ".", // Current directory
            scheme: "YourAppUITests", // TODO: Replace with actual scheme
            uiTestTarget: "YourAppUITests/ScreenshotUITests",
            outputDirectory: "screenshots",
            locales: locales,
            devices: devices,
            skipFrames: skipFrames,
            skipCaptions: skipCaptions
        )
    }

    static let defaultDevices: [DeviceSpec] = [
        DeviceSpec(name: "iPhone_6.7", simulatorName: "iPhone 16 Pro Max"),
        DeviceSpec(name: "iPhone_6.5", simulatorName: "iPhone 11 Pro Max"),
        DeviceSpec(name: "iPad_12.9", simulatorName: "iPad Pro (12.9-inch) (6th generation)")
    ]
}

// MARK: - Shell Execution

@discardableResult
func shell(_ command: String, verbose: Bool = true) throws -> String {
    if verbose {
        print("  > \(command)")
    }

    let process = Process()
    let pipe = Pipe()

    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    process.arguments = ["-c", command]
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
        throw ExportError.shellCommandFailed(command: command, output: output)
    }

    return output
}

enum ExportError: Error, LocalizedError {
    case shellCommandFailed(command: String, output: String)
    case screenshotExtractionFailed(String)

    var errorDescription: String? {
        switch self {
        case .shellCommandFailed(let cmd, let output):
            return "Command failed: \(cmd)\nOutput: \(output)"
        case .screenshotExtractionFailed(let reason):
            return "Screenshot extraction failed: \(reason)"
        }
    }
}

// MARK: - Pipeline Steps

func configureSimulators(config: ExportConfig) throws {
    print("\n[1/5] Configuring simulators...")

    for device in config.devices {
        print("  Configuring \(device.simulatorName)...")

        // Boot simulator if needed
        try? shell(
            "xcrun simctl boot '\(device.simulatorName)'",
            verbose: false
        )

        // Override status bar for clean screenshots
        try shell("""
            xcrun simctl status_bar '\(device.simulatorName)' override \
              --time "9:41" \
              --batteryState charged \
              --batteryLevel 100 \
              --wifiBars 3 \
              --cellularBars 4 \
              --operatorName ""
            """)
    }
}

func buildForTesting(config: ExportConfig) throws {
    print("\n[2/5] Building for testing...")

    try shell("""
        xcodebuild build-for-testing \
          -scheme "\(config.scheme)" \
          -destination "platform=iOS Simulator,name=\(config.devices[0].simulatorName)" \
          -derivedDataPath DerivedData \
          | xcbeautify 2>/dev/null || true
        """)
}

func runTests(config: ExportConfig) throws {
    print("\n[3/5] Running screenshot tests...")

    for device in config.devices {
        print("  Capturing on \(device.simulatorName)...")

        let resultBundleName = "screenshots_\(device.name).xcresult"

        // Remove old result bundle if exists
        try? shell("rm -rf \(resultBundleName)", verbose: false)

        try shell("""
            xcodebuild test-without-building \
              -scheme "\(config.scheme)" \
              -destination "platform=iOS Simulator,name=\(device.simulatorName)" \
              -derivedDataPath DerivedData \
              -only-testing "\(config.uiTestTarget)" \
              -resultBundlePath \(resultBundleName) \
              | xcbeautify 2>/dev/null || true
            """)
    }
}

func extractScreenshots(config: ExportConfig) throws {
    print("\n[4/5] Extracting screenshots from test results...")

    let outputDir = config.outputDirectory
    try? shell("rm -rf \(outputDir)", verbose: false)

    for device in config.devices {
        let resultBundle = "screenshots_\(device.name).xcresult"

        // Extract test attachments from xcresult
        let attachmentsDir = "\(outputDir)/raw/\(device.name)"
        try shell("mkdir -p \(attachmentsDir)")

        // Use xcresulttool to list and extract attachments
        try shell("""
            xcrun xcresulttool get \
              --path \(resultBundle) \
              --format json \
              > /tmp/xcresult_\(device.name).json 2>/dev/null || true
            """)

        // Extract actual screenshot files using xcparse (if available) or manual extraction
        try? shell("""
            if command -v xcparse &> /dev/null; then
              xcparse attachments \(resultBundle) \(attachmentsDir)
            else
              echo "  Note: Install xcparse for easier extraction: brew install chargepoint/xcparse/xcparse"
              # Fallback: copy from result bundle internals
              find \(resultBundle) -name "*.png" -exec cp {} \(attachmentsDir)/ \\;
            fi
            """)

        // Organize by locale
        for locale in config.locales {
            let localeDir = "\(outputDir)/\(locale)/\(device.name)"
            try shell("mkdir -p \(localeDir)")

            // Move files matching this locale
            try? shell(
                "mv \(attachmentsDir)/\(locale)_*.png \(localeDir)/ 2>/dev/null || true",
                verbose: false
            )

            // Rename to remove locale prefix
            let files = try shell(
                "ls \(localeDir)/*.png 2>/dev/null || true",
                verbose: false
            )
            for file in files.components(separatedBy: "\n") where !file.isEmpty {
                let filename = URL(fileURLWithPath: file).lastPathComponent
                let cleaned = filename.replacingOccurrences(of: "\(locale)_", with: "")
                if cleaned != filename {
                    try? shell(
                        "mv '\(file)' '\(localeDir)/\(cleaned)'",
                        verbose: false
                    )
                }
            }
        }
    }
}

func postProcess(config: ExportConfig) throws {
    print("\n[5/5] Post-processing screenshots...")

    if config.skipCaptions && config.skipFrames {
        print("  Skipping post-processing (--skip-frames --skip-captions)")
        return
    }

    if !config.skipCaptions {
        print("  Adding caption overlays...")
        // Caption overlay is handled by ScreenshotProcessor when run as part of the app
        // For standalone script usage, invoke the compiled processor:
        print("  Note: Run the Swift post-processor for caption overlays:")
        print("    swift run ScreenshotProcessor --input \(config.outputDirectory) --captions")
    }

    if !config.skipFrames {
        print("  Adding device frames...")
        print("  Note: Run the Swift post-processor for device frames:")
        print("    swift run ScreenshotProcessor --input \(config.outputDirectory) --frames")
    }
}

func printSummary(config: ExportConfig) {
    print("\n" + String(repeating: "=", count: 60))
    print("Screenshot generation complete!")
    print(String(repeating: "=", count: 60))
    print("")
    print("Output directory: \(config.outputDirectory)/")
    print("Locales: \(config.locales.joined(separator: ", "))")
    print("Devices: \(config.devices.map(\.name).joined(separator: ", "))")
    print("")
    print("Directory structure:")

    for locale in config.locales {
        print("  \(config.outputDirectory)/\(locale)/")
        for device in config.devices {
            print("    \(device.name)/")
            print("      01_HomeScreen.png")
            print("      02_DetailView.png")
            print("      ...")
        }
    }

    print("")
    print("Next steps:")
    print("  1. Review screenshots in \(config.outputDirectory)/")
    print("  2. Upload to App Store Connect via Transporter or fastlane deliver")
    print("  3. Verify all required sizes are present")
}

// MARK: - Main

let config = ExportConfig.parseArguments()

do {
    try configureSimulators(config: config)
    try buildForTesting(config: config)
    try runTests(config: config)
    try extractScreenshots(config: config)
    try postProcess(config: config)
    printSummary(config: config)
} catch {
    print("\nError: \(error.localizedDescription)")
    exit(1)
}
```

## ScreenshotModeController.swift

A controller the user adds to their **app target** (not the test target) that detects `--screenshot-mode` and configures the app for clean screenshot capture. This is the app-side counterpart to the UI test infrastructure.

```swift
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Controls app behavior during automated screenshot capture.
///
/// Add this to your App's init or main entry point:
/// ```swift
/// @main
/// struct MyApp: App {
///     init() {
///         ScreenshotModeController.shared.configureIfNeeded()
///     }
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .onAppear {
///                     ScreenshotModeController.shared.configureWindow()
///                 }
///         }
///     }
/// }
/// ```
@MainActor
final class ScreenshotModeController {
    static let shared = ScreenshotModeController()

    /// Whether the app was launched in screenshot mode.
    let isScreenshotMode: Bool

    /// Whether onboarding should be skipped.
    let shouldSkipOnboarding: Bool

    private init() {
        let args = ProcessInfo.processInfo.arguments
        self.isScreenshotMode = args.contains("--screenshot-mode") ||
                                args.contains("-ScreenshotMode")
        self.shouldSkipOnboarding = isScreenshotMode ||
                                    args.contains("--skip-onboarding") ||
                                    args.contains("-SkipOnboarding")
    }

    /// Call early in app lifecycle (e.g., App.init or applicationDidFinishLaunching).
    /// Suppresses onboarding, disables analytics, loads sample data.
    func configureIfNeeded() {
        guard isScreenshotMode else { return }

        // Suppress first-launch behaviors
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(true, forKey: "hasSeenWhatsNew")

        // Disable analytics and crash reporting during screenshots
        UserDefaults.standard.set(false, forKey: "analyticsEnabled")

        // Disable in-app purchase prompts
        UserDefaults.standard.set(true, forKey: "hideIAPPrompts")

        // Load sample data for attractive screenshots
        loadSampleData()

        #if canImport(AppKit)
        configureDesktopForScreenshots()
        #endif
    }

    /// Configure the main window for screenshot capture.
    /// Call in onAppear of your root view.
    func configureWindow() {
        guard isScreenshotMode else { return }

        #if canImport(AppKit)
        // Size the window to match App Store screenshot dimensions
        // Mac App Store requires 2880×1800 for Retina displays
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let window = NSApp.windows.first(where: { $0.isVisible }) else { return }

            // Account for title bar height and asymmetric window borders
            // macOS windows have different border thickness top vs bottom.
            // The bottom ~3pt gets cropped, so add padding there.
            let titleBarHeight: CGFloat = 28
            let bottomBorderPadding: CGFloat = 4

            let contentWidth: CGFloat = 1440  // Half of 2880 for Retina
            let contentHeight: CGFloat = 900 - titleBarHeight + bottomBorderPadding

            window.setContentSize(NSSize(width: contentWidth, height: contentHeight))
            window.center()

            // Bring window to front
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        #endif
    }

    // MARK: - Sample Data

    /// Override this method to load your app's sample data.
    /// Called automatically when screenshot mode is detected.
    ///
    /// Example implementation:
    /// ```swift
    /// override func loadSampleData() {
    ///     let store = DataStore.shared
    ///     store.clearAll()
    ///     store.insert(SampleData.projects)
    ///     store.insert(SampleData.tasks)
    /// }
    /// ```
    func loadSampleData() {
        // Override in your app to load attractive sample data.
        // This is where you populate your data store with content
        // that makes the app look great in screenshots.
    }

    #if canImport(AppKit)
    // MARK: - macOS Desktop Configuration

    /// Configures the macOS desktop for clean screenshots.
    /// Hides the dock and sets a clean appearance.
    private func configureDesktopForScreenshots() {
        // Hide the dock during screenshots
        // The dock auto-hides when the app is in the foreground with this setting
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "com.apple.dock", "autohide", "-bool", "true"]
        try? process.run()
        process.waitUntilExit()

        // Restart dock to apply
        let killDock = Process()
        killDock.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killDock.arguments = ["Dock"]
        try? killDock.run()
        killDock.waitUntilExit()
    }
    #endif
}

// MARK: - SwiftUI Integration

/// Environment key for screenshot mode detection in views.
///
/// Usage in views:
/// ```swift
/// @Environment(\.isScreenshotMode) private var isScreenshotMode
///
/// var body: some View {
///     if !isScreenshotMode {
///         UpgradePromptBanner()
///     }
///     // ... main content
/// }
/// ```
private struct ScreenshotModeKey: EnvironmentKey {
    static let defaultValue = ScreenshotModeController.shared.isScreenshotMode
}

extension EnvironmentValues {
    var isScreenshotMode: Bool {
        get { self[ScreenshotModeKey.self] }
        set { self[ScreenshotModeKey.self] = newValue }
    }
}
```

## sips-screenshot-process.sh

A lightweight post-processing script using macOS's built-in `sips` command. Zero external dependencies — no Swift compilation, no fastlane, no ImageMagick. Best for macOS app screenshots where you just need to resize and crop to App Store dimensions.

```bash
#!/bin/bash
# sips-screenshot-process.sh
# Post-process screenshots using macOS built-in sips command.
# No external dependencies required.
#
# Usage:
#   ./sips-screenshot-process.sh raw_screenshots/ processed/
#   ./sips-screenshot-process.sh raw_screenshots/ processed/ --mac-only
#   ./sips-screenshot-process.sh raw_screenshots/ processed/ --target 2880x1800

set -euo pipefail

INPUT_DIR="${1:?Usage: $0 <input_dir> <output_dir> [--mac-only] [--target WxH]}"
OUTPUT_DIR="${2:?Usage: $0 <input_dir> <output_dir> [--mac-only] [--target WxH]}"
MAC_ONLY=false
TARGET_WIDTH=""
TARGET_HEIGHT=""

# Parse optional arguments
shift 2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mac-only) MAC_ONLY=true; shift ;;
        --target)
            TARGET_WIDTH="${2%x*}"
            TARGET_HEIGHT="${2#*x}"
            shift 2
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Default App Store dimensions
declare -A SIZES
if [[ "$MAC_ONLY" == true ]]; then
    SIZES=(
        ["mac_retina"]="2880x1800"
    )
else
    SIZES=(
        ["iPhone_6.9"]="1320x2868"
        ["iPhone_6.7"]="1290x2796"
        ["iPhone_6.5"]="1284x2778"
        ["iPhone_5.5"]="1242x2208"
        ["iPad_12.9"]="2048x2732"
        ["mac_retina"]="2880x1800"
    )
fi

mkdir -p "$OUTPUT_DIR"

process_image() {
    local src="$1"
    local dst="$2"
    local target_w="$3"
    local target_h="$4"
    local filename
    filename=$(basename "$src")

    # Get current dimensions
    local cur_w cur_h
    cur_w=$(sips -g pixelWidth "$src" | tail -1 | awk '{print $2}')
    cur_h=$(sips -g pixelHeight "$src" | tail -1 | awk '{print $2}')

    cp "$src" "$dst/$filename"
    local work="$dst/$filename"

    # Step 1: Resize to target width (maintaining aspect ratio)
    if [[ "$cur_w" -ne "$target_w" ]]; then
        sips --resampleWidth "$target_w" "$work" --out "$work" > /dev/null 2>&1
    fi

    # Step 2: Crop to exact target height if needed
    local new_h
    new_h=$(sips -g pixelHeight "$work" | tail -1 | awk '{print $2}')
    if [[ "$new_h" -gt "$target_h" ]]; then
        # Crop from bottom (removes extra pixels at the bottom edge)
        # This accounts for macOS asymmetric window borders
        sips --cropToHeightWidth "$target_h" "$target_w" "$work" --out "$work" > /dev/null 2>&1
    fi

    echo "  ✓ $filename → ${target_w}×${target_h}"
}

# Process with explicit target
if [[ -n "$TARGET_WIDTH" && -n "$TARGET_HEIGHT" ]]; then
    echo "Processing screenshots to ${TARGET_WIDTH}×${TARGET_HEIGHT}..."
    for img in "$INPUT_DIR"/*.png; do
        [[ -f "$img" ]] || continue
        process_image "$img" "$OUTPUT_DIR" "$TARGET_WIDTH" "$TARGET_HEIGHT"
    done
    echo "Done. Output in $OUTPUT_DIR/"
    exit 0
fi

# Process for each App Store size
for size_name in "${!SIZES[@]}"; do
    dims="${SIZES[$size_name]}"
    w="${dims%x*}"
    h="${dims#*x}"

    size_dir="$OUTPUT_DIR/$size_name"
    mkdir -p "$size_dir"

    echo "Processing for $size_name (${w}×${h})..."
    for img in "$INPUT_DIR"/*.png; do
        [[ -f "$img" ]] || continue
        process_image "$img" "$size_dir" "$w" "$h"
    done
done

echo ""
echo "All screenshots processed."
echo "Output: $OUTPUT_DIR/"
ls -la "$OUTPUT_DIR"/
```

## macos-screenshot-env.sh

Prepares the macOS desktop environment for clean screenshot capture. Sets clock time, hides desktop icons, configures wallpaper, and hides the dock. Uses `trap` to restore everything on exit — even if the script fails or is interrupted.

```bash
#!/bin/bash
# macos-screenshot-env.sh
# Prepare macOS desktop for screenshot capture with automatic cleanup.
#
# Usage:
#   ./macos-screenshot-env.sh             # Setup only (restores on exit)
#   ./macos-screenshot-env.sh --run-tests # Setup, run tests, then restore
#   ./macos-screenshot-env.sh --restore   # Force restore saved state
#
# This script saves original settings, applies screenshot-friendly configuration,
# and restores everything on exit via trap — even on Ctrl+C or failure.

set -euo pipefail

STATE_FILE="/tmp/.screenshot_env_state"

# ── Save current state ──────────────────────────────────────────────

save_state() {
    echo "Saving current desktop state..."

    local dock_autohide
    dock_autohide=$(defaults read com.apple.dock autohide 2>/dev/null || echo "0")

    local dock_size
    dock_size=$(defaults read com.apple.dock tilesize 2>/dev/null || echo "48")

    local desktop_icons
    desktop_icons=$(defaults read com.apple.finder CreateDesktop 2>/dev/null || echo "1")

    local menubar_clock
    menubar_clock=$(defaults read com.apple.menuextra.clock DateFormat 2>/dev/null || echo "")

    cat > "$STATE_FILE" <<STATEEOF
DOCK_AUTOHIDE=$dock_autohide
DOCK_SIZE=$dock_size
DESKTOP_ICONS=$desktop_icons
MENUBAR_CLOCK=$menubar_clock
STATEEOF

    echo "  State saved to $STATE_FILE"
}

# ── Restore original state ──────────────────────────────────────────

restore_state() {
    echo ""
    echo "Restoring original desktop state..."

    if [[ ! -f "$STATE_FILE" ]]; then
        echo "  No saved state found at $STATE_FILE"
        return
    fi

    source "$STATE_FILE"

    # Restore dock
    defaults write com.apple.dock autohide -bool "$DOCK_AUTOHIDE"
    defaults write com.apple.dock tilesize -int "$DOCK_SIZE"

    # Restore desktop icons
    defaults write com.apple.finder CreateDesktop -bool "$DESKTOP_ICONS"

    # Restore clock format
    if [[ -n "$MENUBAR_CLOCK" ]]; then
        defaults write com.apple.menuextra.clock DateFormat "$MENUBAR_CLOCK"
    fi

    # Restart affected services
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true

    rm -f "$STATE_FILE"
    echo "  Desktop restored to original state."
}

# ── Apply screenshot environment ────────────────────────────────────

apply_screenshot_env() {
    echo "Configuring desktop for screenshots..."

    # Hide the dock
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 1000
    defaults write com.apple.dock no-bouncing -bool true

    # Hide desktop icons (Finder's "CreateDesktop" setting)
    defaults write com.apple.finder CreateDesktop -bool false

    # Set clock to canonical time (9:41 — Apple's standard)
    # Note: This changes the display format, not the actual time.
    # For the menu bar clock, we hide seconds and use a clean format.
    defaults write com.apple.menuextra.clock DateFormat -string "h:mm"

    # Restart affected services to apply changes
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true

    # Wait for services to restart
    sleep 2

    echo "  ✓ Dock hidden"
    echo "  ✓ Desktop icons hidden"
    echo "  ✓ Menu bar clock simplified"
    echo ""
    echo "Desktop is ready for screenshots."
}

# ── Trap: Always restore on exit ────────────────────────────────────

trap restore_state EXIT INT TERM

# ── Main ────────────────────────────────────────────────────────────

case "${1:-}" in
    --restore)
        restore_state
        trap - EXIT INT TERM  # Don't double-restore
        exit 0
        ;;
    --run-tests)
        save_state
        apply_screenshot_env

        echo ""
        echo "Running screenshot tests..."
        shift

        # Run the test command passed as remaining arguments,
        # or use default xcodebuild command
        if [[ $# -gt 0 ]]; then
            "$@"
        else
            echo "No test command provided. Desktop is configured."
            echo "Run your tests manually, then press Enter to restore."
            read -r
        fi
        # restore_state runs automatically via trap
        ;;
    *)
        save_state
        apply_screenshot_env

        echo ""
        echo "Desktop configured. Press Enter when done to restore, or Ctrl+C."
        read -r
        # restore_state runs automatically via trap
        ;;
esac
```

## SampleContentGenerator.swift

Patterns for generating realistic sample content programmatically. Instead of relying on pre-seeded databases, generate attractive data at runtime during screenshot mode. Covers text, images, PDFs, and structured data.

```swift
import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Generates realistic sample content for screenshot capture.
///
/// Use in your ScreenshotModeController.loadSampleData() override
/// to populate the app with attractive content.
///
/// ```swift
/// override func loadSampleData() {
///     let generator = SampleContentGenerator()
///     let projects = generator.generateProjects(count: 5)
///     DataStore.shared.insert(projects)
/// }
/// ```
enum SampleContentGenerator {

    // MARK: - Text Content

    /// Realistic sample titles by app category.
    /// Use these instead of "Lorem Ipsum" for screenshots that look real.
    static let sampleTitles: [String: [String]] = [
        "productivity": [
            "Q4 Marketing Strategy",
            "Website Redesign Sprint",
            "Product Launch Checklist",
            "Team Onboarding Guide",
            "Budget Review 2025"
        ],
        "fitness": [
            "Morning Run - Central Park",
            "Upper Body Workout",
            "5K Training Plan",
            "Yoga Flow Session",
            "Weekend Hike"
        ],
        "finance": [
            "Monthly Budget",
            "Vacation Fund",
            "Emergency Savings",
            "Investment Portfolio",
            "Subscription Audit"
        ],
        "notes": [
            "Meeting Notes - Design Review",
            "Book Recommendations",
            "Recipe: Homemade Pasta",
            "Travel Packing List",
            "Gift Ideas for Mom"
        ]
    ]

    /// Returns sample titles for a given category, cycling if count exceeds available titles.
    static func titles(for category: String, count: Int) -> [String] {
        let pool = sampleTitles[category] ?? sampleTitles["productivity"]!
        return (0..<count).map { pool[$0 % pool.count] }
    }

    /// Generates a realistic paragraph of text.
    static func paragraph(sentences: Int = 3) -> String {
        let pool = [
            "Track your progress with detailed analytics and visual charts.",
            "Stay organized with smart folders that adapt to your workflow.",
            "Collaborate seamlessly with your team in real-time.",
            "Set reminders so you never miss an important deadline.",
            "Export your data in multiple formats for easy sharing.",
            "Customize the interface to match your personal style.",
            "Access your content from any device with cloud sync.",
            "Use keyboard shortcuts to work faster than ever.",
            "Get insights with weekly summary reports.",
            "Protect your data with end-to-end encryption."
        ]
        let selected = (0..<sentences).map { pool[$0 % pool.count] }
        return selected.joined(separator: " ")
    }

    // MARK: - Sample Dates

    /// Generates an array of recent dates, useful for chart data or activity feeds.
    static func recentDates(count: Int, daySpacing: Int = 1) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<count).compactMap { index in
            calendar.date(byAdding: .day, value: -(index * daySpacing), to: now)
        }.reversed()
    }

    // MARK: - Sample Numbers

    /// Generates realistic-looking chart data with a general upward trend.
    static func trendingData(count: Int, baseValue: Double = 100, variance: Double = 20) -> [Double] {
        var values: [Double] = []
        var current = baseValue
        for i in 0..<count {
            let trend = Double(i) * (variance / Double(count)) // Gradual increase
            let noise = Double.random(in: -variance/3...variance/3)
            current = baseValue + trend + noise
            values.append(max(0, current))
        }
        return values
    }

    /// Generates percentage values that sum to 100 (useful for pie charts).
    static func percentages(count: Int) -> [Double] {
        let raw = (0..<count).map { _ in Double.random(in: 10...50) }
        let total = raw.reduce(0, +)
        return raw.map { ($0 / total) * 100 }
    }

    // MARK: - Placeholder Images

    /// Generates a solid color placeholder image.
    static func placeholderImage(
        size: CGSize,
        color: CGColor = CGColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1)
    ) -> PlatformImage? {
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.setFillColor(color)
        context.fill(CGRect(origin: .zero, size: size))

        guard let cgImage = context.makeImage() else { return nil }

        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        return NSImage(cgImage: cgImage, size: size)
        #endif
    }

    /// Generates a gradient placeholder image (more visually appealing for screenshots).
    static func gradientImage(
        size: CGSize,
        colors: [CGColor] = [
            CGColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1),
            CGColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1)
        ]
    ) -> PlatformImage? {
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: nil
        ) else { return nil }

        context.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: size.width, y: size.height),
            options: []
        )

        guard let cgImage = context.makeImage() else { return nil }

        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        return NSImage(cgImage: cgImage, size: size)
        #endif
    }

    // MARK: - PDF Generation (macOS)

    #if canImport(AppKit)
    /// Generates a sample PDF document with multiple pages of varied content.
    ///
    /// Useful for document-based apps that need realistic content in screenshots.
    /// Creates pages with headings, body text, and simple shapes.
    static func generateSamplePDF(
        pages: Int = 3,
        pageSize: CGSize = CGSize(width: 612, height: 792), // US Letter
        outputURL: URL
    ) throws {
        var mediaBox = CGRect(origin: .zero, size: pageSize)

        guard let context = CGContext(outputURL as CFURL, mediaBox: &mediaBox, nil) else {
            return
        }

        let headingFont = CTFontCreateWithName("Helvetica-Bold" as CFString, 24, nil)
        let bodyFont = CTFontCreateWithName("Helvetica" as CFString, 12, nil)

        let pageTitles = [
            "Executive Summary",
            "Market Analysis",
            "Financial Projections",
            "Implementation Timeline",
            "Risk Assessment"
        ]

        let bodyText = """
        This section contains detailed analysis and supporting data for the \
        overall strategy. Key metrics indicate positive trends across all \
        measured dimensions, with particular strength in user engagement \
        and retention rates.
        """

        for pageIndex in 0..<pages {
            context.beginPage(mediaBox: &mediaBox)

            // Draw heading
            let title = pageTitles[pageIndex % pageTitles.count]
            let headingAttrs: [NSAttributedString.Key: Any] = [
                .font: headingFont,
                .foregroundColor: NSColor.black
            ]
            let headingString = NSAttributedString(string: title, attributes: headingAttrs)
            let headingLine = CTLineCreateWithAttributedString(headingString)

            context.textPosition = CGPoint(x: 72, y: pageSize.height - 72)
            CTLineDraw(headingLine, context)

            // Draw body text
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: NSColor.darkGray
            ]
            let bodyString = NSAttributedString(string: bodyText, attributes: bodyAttrs)
            let framesetter = CTFramesetterCreateWithAttributedString(bodyString)
            let textRect = CGRect(x: 72, y: 72, width: pageSize.width - 144, height: pageSize.height - 180)
            let path = CGPath(rect: textRect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
            CTFrameDraw(frame, context)

            // Draw a decorative chart placeholder on some pages
            if pageIndex % 2 == 1 {
                let chartRect = CGRect(
                    x: 72,
                    y: pageSize.height - 400,
                    width: pageSize.width - 144,
                    height: 200
                )
                context.setStrokeColor(CGColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1))
                context.setLineWidth(1)
                context.stroke(chartRect)

                // Draw simple bar chart
                let barCount = 6
                let barWidth = (chartRect.width - 20) / CGFloat(barCount)
                let colors: [CGColor] = [
                    CGColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 0.8),
                    CGColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 0.8)
                ]

                for i in 0..<barCount {
                    let barHeight = CGFloat.random(in: 40...180)
                    let barRect = CGRect(
                        x: chartRect.origin.x + 10 + CGFloat(i) * barWidth + 5,
                        y: chartRect.origin.y + 10,
                        width: barWidth - 10,
                        height: barHeight
                    )
                    context.setFillColor(colors[i % colors.count])
                    context.fill(barRect)
                }
            }

            context.endPage()
        }

        context.closePDF()
    }
    #endif
}

// MARK: - Sample User Profiles

extension SampleContentGenerator {
    /// Pre-built user profiles for social or collaborative app screenshots.
    struct SampleUser {
        let name: String
        let initials: String
        let role: String
        let avatarColor: CGColor
    }

    static let sampleUsers: [SampleUser] = [
        SampleUser(
            name: "Sarah Chen",
            initials: "SC",
            role: "Designer",
            avatarColor: CGColor(red: 0.9, green: 0.4, blue: 0.4, alpha: 1)
        ),
        SampleUser(
            name: "Alex Rivera",
            initials: "AR",
            role: "Developer",
            avatarColor: CGColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)
        ),
        SampleUser(
            name: "Jordan Park",
            initials: "JP",
            role: "Manager",
            avatarColor: CGColor(red: 0.4, green: 0.8, blue: 0.5, alpha: 1)
        ),
        SampleUser(
            name: "Maya Johnson",
            initials: "MJ",
            role: "Analyst",
            avatarColor: CGColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1)
        )
    ]
}
```

## Xcode Test Plan for Screenshots

Create a dedicated test plan to isolate screenshot tests from development tests. This prevents screenshot tests from running during normal `Cmd+U` test cycles.

**File: `ScreenshotTests.xctestplan`**

```json
{
  "configurations" : [
    {
      "id" : "screenshot-config",
      "name" : "Screenshot Configuration",
      "options" : {
        "language" : "en",
        "region" : "US",
        "uiTestingScreenshotsLifetime" : "keepAlways",
        "testRepetitionMode" : "none"
      }
    }
  ],
  "defaultOptions" : {
    "codeCoverage" : false,
    "testTimeoutsEnabled" : true,
    "defaultTestExecutionTimeAllowance" : 300,
    "maximumTestExecutionTimeAllowance" : 600,
    "targetForVariableExpansion" : {
      "containerPath" : "container:YourApp.xcodeproj",
      "identifier" : "YourAppUITests",
      "name" : "YourAppUITests"
    }
  },
  "testTargets" : [
    {
      "target" : {
        "containerPath" : "container:YourApp.xcodeproj",
        "identifier" : "YourAppUITests",
        "name" : "YourAppUITests"
      },
      "selectedTests" : [
        "ScreenshotUITests"
      ]
    }
  ],
  "version" : 1
}
```

**How to add this test plan to Xcode:**

1. Save the above JSON as `ScreenshotTests.xctestplan` in your project root
2. In Xcode, go to **Product → Scheme → Edit Scheme**
3. Under **Test**, click the `+` at the bottom of the test plans list
4. Select "Add existing test plan" and choose `ScreenshotTests.xctestplan`
5. Your normal test plan runs with `Cmd+U`; run the screenshot plan via:
   ```bash
   xcodebuild test \
     -scheme "YourApp" \
     -testPlan "ScreenshotTests" \
     -destination "platform=iOS Simulator,name=iPhone 16 Pro Max"
   ```

**Adding locale variants as test configurations:**

```json
{
  "configurations" : [
    {
      "id" : "en-US",
      "name" : "English (US)",
      "options" : { "language" : "en", "region" : "US" }
    },
    {
      "id" : "de-DE",
      "name" : "German",
      "options" : { "language" : "de", "region" : "DE" }
    },
    {
      "id" : "ja-JP",
      "name" : "Japanese",
      "options" : { "language" : "ja", "region" : "JP" }
    }
  ]
}
```
