# Watermark Engine Code Templates

Production-ready Swift templates for a watermarking system. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

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

## WatermarkStyle.swift

```swift
import Foundation
import SwiftUI

/// Configuration for a watermark overlay.
///
/// Defines what content to render, where to place it, and how it should appear.
///
/// Usage:
/// ```swift
/// let style = WatermarkStyle(
///     content: .text("© MyApp"),
///     position: .bottomRight,
///     opacity: 0.4,
///     scale: 0.08
/// )
/// ```
struct WatermarkStyle: Equatable, Sendable {

    /// The visual content of the watermark.
    enum Content: Equatable, Sendable {
        /// Plain text rendered with system font.
        case text(String)

        /// An image or logo with transparency.
        case image(PlatformImage)

        /// Styled text with custom font, color, and optional shadow.
        case attributed(AttributedString)

        static func == (lhs: Content, rhs: Content) -> Bool {
            switch (lhs, rhs) {
            case (.text(let a), .text(let b)):
                return a == b
            case (.image(let a), .image(let b)):
                return a === b
            case (.attributed(let a), .attributed(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    /// What to render as the watermark.
    let content: Content

    /// Where to place the watermark relative to the image bounds.
    let position: WatermarkPosition

    /// Opacity of the watermark overlay (0.0–1.0).
    let opacity: CGFloat

    /// Scale of the watermark relative to the source image's shortest dimension.
    ///
    /// For example, `0.1` means the watermark will be 10% of the image's shortest side.
    let scale: CGFloat

    /// Padding from the edge of the image in points.
    let padding: CGFloat

    /// Font used for text watermarks.
    let font: PlatformFont

    /// Color used for text watermarks.
    let textColor: PlatformColor

    init(
        content: Content,
        position: WatermarkPosition = .bottomRight,
        opacity: CGFloat = 0.4,
        scale: CGFloat = 0.08,
        padding: CGFloat = 16,
        font: PlatformFont = .systemFont(ofSize: 24, weight: .semibold),
        textColor: PlatformColor = .white
    ) {
        self.content = content
        self.position = position
        self.opacity = opacity.clamped(to: 0...1)
        self.scale = scale.clamped(to: 0.01...1)
        self.padding = padding
        self.font = font
        self.textColor = textColor
    }
}

// MARK: - Platform Font/Color Typealias

#if canImport(UIKit)
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#endif

// MARK: - Clamping Helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
```

## WatermarkPosition.swift

```swift
import Foundation
import CoreGraphics

/// Describes where a watermark is placed relative to the source image bounds.
///
/// For fixed positions (corners, center), computes a single CGRect.
/// For tiled positions, computes an array of CGRects covering the entire image.
enum WatermarkPosition: Equatable, Sendable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
    case tiled(angle: CGFloat = -30, spacing: CGFloat = 120)

    /// Compute the frame for a single watermark placement.
    ///
    /// - Parameters:
    ///   - watermarkSize: The size of the watermark content.
    ///   - imageSize: The size of the source image.
    ///   - padding: Edge padding in points.
    /// - Returns: The CGRect where the watermark should be drawn.
    func frame(
        watermarkSize: CGSize,
        imageSize: CGSize,
        padding: CGFloat
    ) -> CGRect {
        let x: CGFloat
        let y: CGFloat

        switch self {
        case .topLeft:
            x = padding
            y = padding

        case .topRight:
            x = imageSize.width - watermarkSize.width - padding
            y = padding

        case .bottomLeft:
            x = padding
            y = imageSize.height - watermarkSize.height - padding

        case .bottomRight:
            x = imageSize.width - watermarkSize.width - padding
            y = imageSize.height - watermarkSize.height - padding

        case .center:
            x = (imageSize.width - watermarkSize.width) / 2
            y = (imageSize.height - watermarkSize.height) / 2

        case .tiled:
            // For tiled, return the first tile at origin.
            // Use tiledFrames() for the full set.
            x = padding
            y = padding
        }

        return CGRect(x: x, y: y, width: watermarkSize.width, height: watermarkSize.height)
    }

    /// Compute all tile frames for a tiled watermark.
    ///
    /// Returns an array of (frame, angle) pairs covering the entire image
    /// with the specified spacing and rotation.
    ///
    /// - Parameters:
    ///   - watermarkSize: The size of each watermark tile.
    ///   - imageSize: The size of the source image.
    /// - Returns: Array of (CGRect, CGFloat) pairs for each tile position and rotation angle.
    func tiledFrames(
        watermarkSize: CGSize,
        imageSize: CGSize
    ) -> [(frame: CGRect, angle: CGFloat)] {
        guard case .tiled(let angle, let spacing) = self else { return [] }

        var frames: [(CGRect, CGFloat)] = []
        let angleRadians = angle * .pi / 180

        // Expand the tiling area to cover the image even after rotation.
        // Use the diagonal as the safe coverage radius.
        let diagonal = hypot(imageSize.width, imageSize.height)
        let startX = -diagonal / 2
        let startY = -diagonal / 2
        let endX = imageSize.width + diagonal / 2
        let endY = imageSize.height + diagonal / 2

        let stepX = watermarkSize.width + spacing
        let stepY = watermarkSize.height + spacing

        var currentY = startY
        while currentY < endY {
            var currentX = startX
            while currentX < endX {
                let frame = CGRect(
                    x: currentX,
                    y: currentY,
                    width: watermarkSize.width,
                    height: watermarkSize.height
                )
                frames.append((frame, angleRadians))
                currentX += stepX
            }
            currentY += stepY
        }

        return frames
    }

    /// Whether this position produces a tiled (repeating) pattern.
    var isTiled: Bool {
        if case .tiled = self { return true }
        return false
    }
}
```

## WatermarkRenderer.swift

```swift
import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// CoreGraphics-based renderer that composites a watermark onto a source image.
///
/// Handles Retina (@2x/@3x) resolution, rotation for tiled patterns,
/// and alpha blending. Uses `UIGraphicsImageRenderer` on iOS for
/// automatic scale handling.
///
/// Usage:
/// ```swift
/// let renderer = WatermarkRenderer()
/// let style = WatermarkStyle(content: .text("© MyApp"), position: .bottomRight)
/// let result = try renderer.render(source: photo, style: style)
/// ```
struct WatermarkRenderer: Sendable {

    /// Render a watermark onto a source image.
    ///
    /// - Parameters:
    ///   - source: The original image to watermark.
    ///   - style: Configuration describing the watermark appearance and placement.
    /// - Returns: A new image with the watermark composited on top.
    /// - Throws: `WatermarkError.renderingFailed` if the graphics context cannot be created.
    func render(source: PlatformImage, style: WatermarkStyle) throws -> PlatformImage {
        let imageSize = source.size
        let watermarkSize = computeWatermarkSize(style: style, imageSize: imageSize)

        #if canImport(UIKit)
        return try renderUIKit(source: source, style: style, watermarkSize: watermarkSize)
        #elseif canImport(AppKit)
        return try renderAppKit(source: source, style: style, watermarkSize: watermarkSize)
        #endif
    }

    // MARK: - Size Computation

    /// Compute the watermark size based on the style scale and source image dimensions.
    private func computeWatermarkSize(style: WatermarkStyle, imageSize: CGSize) -> CGSize {
        let referenceDimension = min(imageSize.width, imageSize.height)
        let targetHeight = referenceDimension * style.scale

        switch style.content {
        case .text(let text):
            let attributes: [NSAttributedString.Key: Any] = [
                .font: style.font
            ]
            let textSize = (text as NSString).size(withAttributes: attributes)
            let scaleFactor = targetHeight / textSize.height
            return CGSize(
                width: textSize.width * scaleFactor,
                height: targetHeight
            )

        case .image(let image):
            let aspectRatio = image.size.width / image.size.height
            return CGSize(
                width: targetHeight * aspectRatio,
                height: targetHeight
            )

        case .attributed(let attrString):
            let nsAttrString = NSAttributedString(attrString)
            let textSize = nsAttrString.size()
            let scaleFactor = targetHeight / textSize.height
            return CGSize(
                width: textSize.width * scaleFactor,
                height: targetHeight
            )
        }
    }

    // MARK: - iOS Rendering (UIKit)

    #if canImport(UIKit)
    private func renderUIKit(
        source: PlatformImage,
        style: WatermarkStyle,
        watermarkSize: CGSize
    ) throws -> PlatformImage {
        let renderer = UIGraphicsImageRenderer(size: source.size)

        return renderer.image { context in
            // Draw source image
            source.draw(at: .zero)

            let cgContext = context.cgContext
            cgContext.setAlpha(style.opacity)

            if style.position.isTiled {
                drawTiledWatermark(
                    in: cgContext,
                    style: style,
                    watermarkSize: watermarkSize,
                    imageSize: source.size
                )
            } else {
                let frame = style.position.frame(
                    watermarkSize: watermarkSize,
                    imageSize: source.size,
                    padding: style.padding
                )
                drawWatermarkContent(
                    style: style,
                    in: frame,
                    scaledFontSize: watermarkSize.height * 0.7
                )
            }
        }
    }
    #endif

    // MARK: - macOS Rendering (AppKit)

    #if canImport(AppKit)
    private func renderAppKit(
        source: PlatformImage,
        style: WatermarkStyle,
        watermarkSize: CGSize
    ) throws -> PlatformImage {
        let newImage = NSImage(size: source.size)
        newImage.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            newImage.unlockFocus()
            throw WatermarkError.renderingFailed
        }

        // Draw source image
        source.draw(
            in: NSRect(origin: .zero, size: source.size),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )

        context.setAlpha(style.opacity)

        if style.position.isTiled {
            drawTiledWatermark(
                in: context,
                style: style,
                watermarkSize: watermarkSize,
                imageSize: source.size
            )
        } else {
            let frame = style.position.frame(
                watermarkSize: watermarkSize,
                imageSize: source.size,
                padding: style.padding
            )
            drawWatermarkContent(
                style: style,
                in: frame,
                scaledFontSize: watermarkSize.height * 0.7
            )
        }

        newImage.unlockFocus()
        return newImage
    }
    #endif

    // MARK: - Tiled Rendering

    private func drawTiledWatermark(
        in context: CGContext,
        style: WatermarkStyle,
        watermarkSize: CGSize,
        imageSize: CGSize
    ) {
        let tiles = style.position.tiledFrames(
            watermarkSize: watermarkSize,
            imageSize: imageSize
        )

        for (frame, angle) in tiles {
            context.saveGState()

            // Rotate around the center of each tile
            let centerX = frame.midX
            let centerY = frame.midY
            context.translateBy(x: centerX, y: centerY)
            context.rotate(by: angle)
            context.translateBy(x: -centerX, y: -centerY)

            drawWatermarkContent(
                style: style,
                in: frame,
                scaledFontSize: watermarkSize.height * 0.7
            )

            context.restoreGState()
        }
    }

    // MARK: - Content Drawing

    private func drawWatermarkContent(
        style: WatermarkStyle,
        in frame: CGRect,
        scaledFontSize: CGFloat
    ) {
        switch style.content {
        case .text(let text):
            let scaledFont: PlatformFont
            #if canImport(UIKit)
            scaledFont = UIFont.systemFont(ofSize: scaledFontSize, weight: .semibold)
            #elseif canImport(AppKit)
            scaledFont = NSFont.systemFont(ofSize: scaledFontSize, weight: .semibold)
            #endif

            let shadow = NSShadow()
            shadow.shadowColor = PlatformColor.black.withAlphaComponent(0.5)
            shadow.shadowBlurRadius = 2
            shadow.shadowOffset = CGSize(width: 1, height: 1)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: scaledFont,
                .foregroundColor: style.textColor,
                .shadow: shadow
            ]

            (text as NSString).draw(in: frame, withAttributes: attributes)

        case .image(let image):
            #if canImport(UIKit)
            image.draw(in: frame)
            #elseif canImport(AppKit)
            image.draw(
                in: NSRect(origin: frame.origin, size: frame.size),
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0
            )
            #endif

        case .attributed(let attrString):
            let nsAttrString = NSAttributedString(attrString)
            nsAttrString.draw(in: frame)
        }
    }
}

// MARK: - Errors

/// Errors that can occur during watermark rendering.
enum WatermarkError: Error, LocalizedError {
    case renderingFailed
    case invalidSource
    case unsupportedContentType

    var errorDescription: String? {
        switch self {
        case .renderingFailed:
            return "Failed to create graphics context for watermark rendering"
        case .invalidSource:
            return "Source image is invalid or corrupted"
        case .unsupportedContentType:
            return "Watermark content type is not supported"
        }
    }
}
```

## WatermarkOverlayView.swift

```swift
import SwiftUI

/// SwiftUI overlay view for live preview of a watermark on content.
///
/// Displays a semi-transparent watermark on top of any view,
/// useful for showing users what their exported image will look like.
///
/// Usage:
/// ```swift
/// Image(uiImage: photo)
///     .resizable()
///     .aspectRatio(contentMode: .fit)
///     .overlay {
///         WatermarkOverlayView(style: watermarkStyle)
///     }
/// ```
struct WatermarkOverlayView: View {
    let style: WatermarkStyle?

    var body: some View {
        if let style {
            GeometryReader { geometry in
                WatermarkOverlayCanvas(style: style, size: geometry.size)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Canvas Rendering

/// Internal view that renders the watermark using Canvas for efficient drawing.
private struct WatermarkOverlayCanvas: View {
    let style: WatermarkStyle
    let size: CGSize

    var body: some View {
        switch style.content {
        case .text(let text):
            TextWatermarkOverlay(text: text, style: style, size: size)
        case .image(let image):
            ImageWatermarkOverlay(image: image, style: style, size: size)
        case .attributed(let attrString):
            AttributedTextWatermarkOverlay(text: attrString, style: style, size: size)
        }
    }
}

// MARK: - Text Watermark Overlay

private struct TextWatermarkOverlay: View {
    let text: String
    let style: WatermarkStyle
    let size: CGSize

    var body: some View {
        if style.position.isTiled {
            TiledTextOverlay(text: text, style: style, size: size)
        } else {
            SingleTextOverlay(text: text, style: style, size: size)
        }
    }
}

private struct SingleTextOverlay: View {
    let text: String
    let style: WatermarkStyle
    let size: CGSize

    var body: some View {
        let fontSize = min(size.width, size.height) * style.scale * 0.7

        Text(text)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(Color(style.textColor))
            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
            .opacity(style.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(style.padding)
    }

    private var alignment: Alignment {
        switch style.position {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        case .center: return .center
        case .tiled: return .center
        }
    }
}

private struct TiledTextOverlay: View {
    let text: String
    let style: WatermarkStyle
    let size: CGSize

    var body: some View {
        let fontSize = min(size.width, size.height) * style.scale * 0.7
        let angle: CGFloat = {
            if case .tiled(let a, _) = style.position { return a }
            return -30
        }()

        Canvas { context, canvasSize in
            let resolvedText = context.resolve(
                Text(text)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(Color(style.textColor))
            )
            let textSize = resolvedText.measure(in: canvasSize)
            let spacing: CGFloat = {
                if case .tiled(_, let s) = style.position { return s }
                return 120
            }()
            let stepX = textSize.width + spacing
            let stepY = textSize.height + spacing
            let diagonal = hypot(canvasSize.width, canvasSize.height)

            var y = -diagonal / 2
            while y < canvasSize.height + diagonal / 2 {
                var x = -diagonal / 2
                while x < canvasSize.width + diagonal / 2 {
                    context.drawLayer { layerContext in
                        let center = CGPoint(x: x + textSize.width / 2, y: y + textSize.height / 2)
                        layerContext.translateBy(x: center.x, y: center.y)
                        layerContext.rotate(by: .degrees(angle))
                        layerContext.translateBy(x: -center.x, y: -center.y)
                        layerContext.draw(
                            resolvedText,
                            at: CGPoint(x: x, y: y),
                            anchor: .topLeading
                        )
                    }
                    x += stepX
                }
                y += stepY
            }
        }
        .opacity(style.opacity)
        .allowsHitTesting(false)
    }
}

// MARK: - Image Watermark Overlay

private struct ImageWatermarkOverlay: View {
    let image: PlatformImage
    let style: WatermarkStyle
    let size: CGSize

    var body: some View {
        let referenceDimension = min(size.width, size.height)
        let targetHeight = referenceDimension * style.scale
        let aspectRatio = image.size.width / image.size.height
        let targetWidth = targetHeight * aspectRatio

        swiftUIImage
            .resizable()
            .frame(width: targetWidth, height: targetHeight)
            .opacity(style.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(style.padding)
    }

    private var swiftUIImage: Image {
        #if canImport(UIKit)
        Image(uiImage: image)
        #elseif canImport(AppKit)
        Image(nsImage: image)
        #endif
    }

    private var alignment: Alignment {
        switch style.position {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        case .center: return .center
        case .tiled: return .center
        }
    }
}

// MARK: - Attributed Text Watermark Overlay

private struct AttributedTextWatermarkOverlay: View {
    let text: AttributedString
    let style: WatermarkStyle
    let size: CGSize

    var body: some View {
        Text(text)
            .opacity(style.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(style.padding)
    }

    private var alignment: Alignment {
        switch style.position {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        case .center: return .center
        case .tiled: return .center
        }
    }
}
```

## WatermarkManager.swift

```swift
import Foundation
import SwiftUI

/// Subscription status for watermark gating.
///
/// Implement this protocol to bridge your existing subscription
/// infrastructure with the watermark system.
protocol WatermarkSubscriptionProvider: Sendable {
    /// Whether the user currently has an active subscription or purchase
    /// that removes watermarks.
    var isWatermarkRemoved: Bool { get async }
}

/// Observable manager that controls watermark application based on subscription status.
///
/// Automatically applies watermarks for free-tier users and removes them
/// when a subscription or purchase is detected.
///
/// Usage:
/// ```swift
/// @State private var manager = WatermarkManager(
///     defaultStyle: .init(content: .text("Free"), position: .center, opacity: 0.3),
///     subscriptionProvider: MyStoreKitProvider()
/// )
///
/// Image(uiImage: photo)
///     .overlay { WatermarkOverlayView(style: manager.activeStyle) }
///     .task { await manager.refreshStatus() }
/// ```
@Observable
final class WatermarkManager {

    /// The currently active watermark style, or nil if watermarks are removed.
    private(set) var activeStyle: WatermarkStyle?

    /// Whether the watermark is currently being shown.
    var isWatermarkActive: Bool { activeStyle != nil }

    /// The default style to apply when watermarks are enabled.
    let defaultStyle: WatermarkStyle

    /// The removal trigger mode.
    let removalMode: RemovalMode

    private let subscriptionProvider: (any WatermarkSubscriptionProvider)?

    /// How the watermark is removed.
    enum RemovalMode: Sendable {
        /// Watermark removed while subscription is active. Re-appears if subscription lapses.
        case subscription

        /// Watermark removed permanently after a one-time purchase.
        case oneTimePurchase

        /// Watermark is always present (branding/attribution).
        case never
    }

    /// Convenience initializer for testing or static configuration.
    init(
        subscriptionStatus: SubscriptionTestStatus = .notSubscribed,
        defaultStyle: WatermarkStyle = WatermarkStyle(
            content: .text("Sample"),
            position: .center,
            opacity: 0.3
        )
    ) {
        self.defaultStyle = defaultStyle
        self.removalMode = .subscription
        self.subscriptionProvider = nil

        switch subscriptionStatus {
        case .subscribed:
            self.activeStyle = nil
        case .notSubscribed:
            self.activeStyle = defaultStyle
        }
    }

    /// Production initializer with subscription provider.
    init(
        defaultStyle: WatermarkStyle,
        removalMode: RemovalMode = .subscription,
        subscriptionProvider: any WatermarkSubscriptionProvider
    ) {
        self.defaultStyle = defaultStyle
        self.removalMode = removalMode
        self.subscriptionProvider = subscriptionProvider

        // Start with watermark active; refreshStatus() will remove if entitled.
        self.activeStyle = (removalMode == .never) ? defaultStyle : defaultStyle
    }

    /// Refresh the watermark status by checking subscription state.
    ///
    /// Call this on view appearance and when subscription status changes.
    func refreshStatus() async {
        guard removalMode != .never else {
            activeStyle = defaultStyle
            return
        }

        guard let provider = subscriptionProvider else { return }

        let isRemoved = await provider.isWatermarkRemoved
        activeStyle = isRemoved ? nil : defaultStyle
    }

    /// Manually remove the watermark (e.g., after a verified purchase).
    func removeWatermark() {
        activeStyle = nil
    }

    /// Manually restore the watermark (e.g., after subscription expiry).
    func restoreWatermark() {
        activeStyle = defaultStyle
    }

    /// Override the watermark style temporarily (e.g., for preview purposes).
    func setTemporaryStyle(_ style: WatermarkStyle?) {
        activeStyle = style
    }
}

/// Test-only subscription status for convenience initializer.
enum SubscriptionTestStatus {
    case subscribed
    case notSubscribed
}

// MARK: - Example StoreKit Provider

/// Example integration with StoreKit 2 subscription status.
///
/// Replace the product ID and adapt to your subscription model.
///
/// ```swift
/// struct StoreKitWatermarkProvider: WatermarkSubscriptionProvider {
///     let productID: String
///
///     var isWatermarkRemoved: Bool {
///         get async {
///             guard let result = await Transaction.currentEntitlement(for: productID) else {
///                 return false
///             }
///             switch result {
///             case .verified(let transaction):
///                 return transaction.revocationDate == nil
///             case .unverified:
///                 return false
///             }
///         }
///     }
/// }
/// ```
```

## WatermarkImageModifier.swift

```swift
import SwiftUI

/// SwiftUI ViewModifier for declarative watermark application.
///
/// Adds a watermark overlay to any view. When `style` is nil, no watermark is shown.
///
/// Usage:
/// ```swift
/// Image(uiImage: photo)
///     .resizable()
///     .aspectRatio(contentMode: .fit)
///     .watermark(.text("© MyApp"), position: .bottomRight, opacity: 0.4)
/// ```
struct WatermarkImageModifier: ViewModifier {
    let style: WatermarkStyle?

    func body(content: Content) -> some View {
        content
            .overlay {
                WatermarkOverlayView(style: style)
            }
    }
}

// MARK: - View Extension

extension View {
    /// Apply a watermark overlay to this view.
    ///
    /// - Parameter style: The watermark style to apply, or nil for no watermark.
    /// - Returns: The view with a watermark overlay.
    func watermark(_ style: WatermarkStyle?) -> some View {
        modifier(WatermarkImageModifier(style: style))
    }

    /// Apply a text watermark overlay to this view.
    ///
    /// - Parameters:
    ///   - text: The watermark text content.
    ///   - position: Where to place the watermark.
    ///   - opacity: Opacity of the watermark (0.0–1.0).
    ///   - scale: Scale relative to the shortest image dimension.
    /// - Returns: The view with a text watermark overlay.
    func watermark(
        _ text: String,
        position: WatermarkPosition = .bottomRight,
        opacity: CGFloat = 0.4,
        scale: CGFloat = 0.08
    ) -> some View {
        modifier(
            WatermarkImageModifier(
                style: WatermarkStyle(
                    content: .text(text),
                    position: position,
                    opacity: opacity,
                    scale: scale
                )
            )
        )
    }

    /// Apply an image watermark overlay to this view.
    ///
    /// - Parameters:
    ///   - image: The watermark image (logo) to overlay.
    ///   - position: Where to place the watermark.
    ///   - opacity: Opacity of the watermark (0.0–1.0).
    ///   - scale: Scale relative to the shortest image dimension.
    /// - Returns: The view with an image watermark overlay.
    func watermark(
        image: PlatformImage,
        position: WatermarkPosition = .bottomRight,
        opacity: CGFloat = 0.5,
        scale: CGFloat = 0.12
    ) -> some View {
        modifier(
            WatermarkImageModifier(
                style: WatermarkStyle(
                    content: .image(image),
                    position: position,
                    opacity: opacity,
                    scale: scale
                )
            )
        )
    }

    /// Conditionally apply a watermark based on a WatermarkManager.
    ///
    /// The watermark is shown only when the manager's active style is non-nil.
    ///
    /// - Parameter manager: The watermark manager controlling visibility.
    /// - Returns: The view with a managed watermark overlay.
    func watermark(managedBy manager: WatermarkManager) -> some View {
        modifier(WatermarkImageModifier(style: manager.activeStyle))
    }
}
```
