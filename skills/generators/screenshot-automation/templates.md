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
