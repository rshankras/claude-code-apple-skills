# Social Export Code Templates

Production-ready Swift templates for social export pipeline. All code targets iOS 16+ / macOS 13+ and uses modern Swift concurrency with Sendable conformance.

## SocialPlatform.swift

```swift
import Foundation
import CoreGraphics

/// Supported social platforms with their export requirements.
///
/// Each platform defines its own aspect ratio, file size limits,
/// URL scheme, and content format requirements.
enum SocialPlatform: String, CaseIterable, Identifiable, Sendable {
    case instagramStories
    case instagramFeed
    case tiktok
    case twitterX
    case general

    var id: String { rawValue }

    /// Human-readable display name for the platform.
    var displayName: String {
        switch self {
        case .instagramStories: return "Instagram Stories"
        case .instagramFeed: return "Instagram Feed"
        case .tiktok: return "TikTok"
        case .twitterX: return "X (Twitter)"
        case .general: return "Share"
        }
    }

    /// SF Symbol name for the platform icon.
    var iconName: String {
        switch self {
        case .instagramStories: return "camera.circle"
        case .instagramFeed: return "photo.circle"
        case .tiktok: return "play.circle"
        case .twitterX: return "at.circle"
        case .general: return "square.and.arrow.up.circle"
        }
    }

    /// Target aspect ratio for exported content (width:height).
    var aspectRatio: CGSize {
        switch self {
        case .instagramStories: return CGSize(width: 9, height: 16)
        case .instagramFeed: return CGSize(width: 1, height: 1)
        case .tiktok: return CGSize(width: 9, height: 16)
        case .twitterX: return CGSize(width: 16, height: 9)
        case .general: return CGSize(width: 1, height: 1)
        }
    }

    /// Target export resolution in pixels.
    var targetResolution: CGSize {
        switch self {
        case .instagramStories: return CGSize(width: 1080, height: 1920)
        case .instagramFeed: return CGSize(width: 1080, height: 1080)
        case .tiktok: return CGSize(width: 1080, height: 1920)
        case .twitterX: return CGSize(width: 1200, height: 675)
        case .general: return CGSize(width: 1080, height: 1080)
        }
    }

    /// Maximum image file size in bytes.
    var maxImageFileSize: Int {
        switch self {
        case .instagramStories: return 12 * 1024 * 1024    // 12 MB
        case .instagramFeed: return 8 * 1024 * 1024        // 8 MB
        case .tiktok: return 10 * 1024 * 1024              // 10 MB
        case .twitterX: return 5 * 1024 * 1024             // 5 MB
        case .general: return 20 * 1024 * 1024             // 20 MB
        }
    }

    /// Maximum video file size in bytes.
    var maxVideoFileSize: Int {
        switch self {
        case .instagramStories: return 100 * 1024 * 1024   // 100 MB
        case .instagramFeed: return 100 * 1024 * 1024      // 100 MB
        case .tiktok: return 287 * 1024 * 1024             // 287 MB
        case .twitterX: return 512 * 1024 * 1024           // 512 MB
        case .general: return 500 * 1024 * 1024            // 500 MB
        }
    }

    /// URL scheme used to open the platform app.
    /// Returns nil for general share sheet.
    var urlScheme: String? {
        switch self {
        case .instagramStories: return "instagram-stories://share"
        case .instagramFeed: return "instagram://library"
        case .tiktok: return "tiktok://"
        case .twitterX: return "twitter://post"
        case .general: return nil
        }
    }

    /// URL scheme used for canOpenURL check.
    /// Must be registered in LSApplicationQueriesSchemes.
    var queryScheme: String? {
        switch self {
        case .instagramStories, .instagramFeed: return "instagram-stories"
        case .tiktok: return "tiktok"
        case .twitterX: return "twitter"
        case .general: return nil
        }
    }

    /// Whether the platform app is installed on this device.
    @MainActor
    var isAvailable: Bool {
        guard let scheme = queryScheme,
              let url = URL(string: "\(scheme)://") else {
            return true // General share sheet is always available
        }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Info.plist LSApplicationQueriesSchemes entries required for this platform.
    var requiredQuerySchemes: [String] {
        switch self {
        case .instagramStories, .instagramFeed:
            return ["instagram-stories", "instagram"]
        case .tiktok:
            return ["tiktok"]
        case .twitterX:
            return ["twitter", "x"]
        case .general:
            return []
        }
    }
}
```

## ExportConfiguration.swift

```swift
import UIKit

/// Branding overlay style for exported content.
enum BrandingStyle: Sendable {
    /// Small logo in the specified corner.
    case cornerLogo(UIImage, corner: Corner = .bottomRight)

    /// Banner strip at the bottom with app name and optional URL.
    case bottomBanner(appName: String, urlString: String? = nil, backgroundColor: UIColor = .black)

    /// No branding applied.
    case none

    enum Corner: Sendable {
        case topLeft, topRight, bottomLeft, bottomRight
    }
}

/// Export quality preset affecting JPEG compression and resolution scaling.
enum ExportQuality: String, CaseIterable, Sendable {
    case low       // 0.5x resolution, 60% JPEG quality
    case medium    // 0.75x resolution, 75% JPEG quality
    case high      // 1x resolution, 85% JPEG quality
    case maximum   // 1x resolution, 95% JPEG quality

    /// JPEG compression quality (0.0 to 1.0).
    var compressionQuality: CGFloat {
        switch self {
        case .low: return 0.6
        case .medium: return 0.75
        case .high: return 0.85
        case .maximum: return 0.95
        }
    }

    /// Resolution scale factor applied to the platform's target resolution.
    var resolutionScale: CGFloat {
        switch self {
        case .low: return 0.5
        case .medium: return 0.75
        case .high: return 1.0
        case .maximum: return 1.0
        }
    }
}

/// Configuration for a social export operation.
///
/// Combines platform target, quality settings, and branding options
/// into a single configuration passed to the exporter.
///
/// Usage:
/// ```swift
/// let config = ExportConfiguration(
///     platform: .instagramStories,
///     quality: .high,
///     branding: .cornerLogo(myLogo)
/// )
/// ```
struct ExportConfiguration: Sendable {
    /// Target social platform.
    let platform: SocialPlatform

    /// Export quality preset.
    let quality: ExportQuality

    /// Branding overlay applied to exported content.
    let branding: BrandingStyle

    /// Optional caption or text to include (used by Twitter/X and share sheet).
    let caption: String?

    /// Optional hashtags to append to the caption.
    let hashtags: [String]

    /// Optional URL to attach (used by Twitter/X and share sheet).
    let attachmentURL: URL?

    init(
        platform: SocialPlatform,
        quality: ExportQuality = .high,
        branding: BrandingStyle = .none,
        caption: String? = nil,
        hashtags: [String] = [],
        attachmentURL: URL? = nil
    ) {
        self.platform = platform
        self.quality = quality
        self.branding = branding
        self.caption = caption
        self.hashtags = hashtags
        self.attachmentURL = attachmentURL
    }

    /// Effective resolution after applying quality scaling.
    var effectiveResolution: CGSize {
        let target = platform.targetResolution
        let scale = quality.resolutionScale
        return CGSize(
            width: target.width * scale,
            height: target.height * scale
        )
    }

    /// Full caption with hashtags appended.
    var fullCaption: String? {
        guard let caption else {
            return hashtags.isEmpty ? nil : hashtags.map { "#\($0)" }.joined(separator: " ")
        }
        if hashtags.isEmpty {
            return caption
        }
        let tags = hashtags.map { "#\($0)" }.joined(separator: " ")
        return "\(caption)\n\n\(tags)"
    }
}
```

## SocialExporter.swift

```swift
import UIKit

/// Result of a social export operation.
enum ExportResult: Sendable {
    /// Successfully exported to the target platform app.
    case success(platform: SocialPlatform)

    /// Target app not installed; fell back to share sheet.
    case fallbackUsed

    /// User cancelled the export.
    case cancelled

    /// Export failed with an error.
    case failed(SocialExportError)
}

/// Errors specific to social export operations.
enum SocialExportError: Error, LocalizedError {
    case platformNotAvailable(SocialPlatform)
    case imageTooLarge(currentSize: Int, maxSize: Int)
    case formattingFailed
    case exportFailed(underlying: Error)
    case missingFacebookAppID
    case pasteboardWriteFailed

    var errorDescription: String? {
        switch self {
        case .platformNotAvailable(let platform):
            return "\(platform.displayName) is not installed on this device"
        case .imageTooLarge(let current, let max):
            let currentMB = current / (1024 * 1024)
            let maxMB = max / (1024 * 1024)
            return "Image is \(currentMB) MB, exceeds \(maxMB) MB limit"
        case .formattingFailed:
            return "Failed to format content for export"
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        case .missingFacebookAppID:
            return "Facebook App ID is required for Instagram Stories export"
        case .pasteboardWriteFailed:
            return "Failed to write content to pasteboard"
        }
    }
}

/// Protocol for platform-specific social export implementations.
///
/// Conforming types handle the details of exporting to a specific
/// social platform, including URL scheme invocation, pasteboard
/// setup, and fallback behavior.
protocol SocialExporting: Sendable {
    /// Export an image to the target platform.
    @MainActor
    func export(
        image: UIImage,
        configuration: ExportConfiguration,
        presentingViewController: UIViewController?
    ) async throws -> ExportResult
}

/// Central social exporter that delegates to platform-specific implementations.
///
/// Usage:
/// ```swift
/// let exporter = SocialExporter(facebookAppID: "YOUR_FB_APP_ID")
/// let result = try await exporter.export(
///     image: shareImage,
///     configuration: .init(platform: .instagramStories)
/// )
/// ```
final class SocialExporter: Sendable {
    private let facebookAppID: String?
    private let formatter: ContentFormatter

    init(facebookAppID: String? = nil, formatter: ContentFormatter = ContentFormatter()) {
        self.facebookAppID = facebookAppID
        self.formatter = formatter
    }

    /// Export an image to the configured platform.
    ///
    /// Formats the image for the target platform, applies branding,
    /// and attempts to open the platform app. Falls back to the
    /// system share sheet if `fallbackToShareSheet` is true.
    @MainActor
    func export(
        image: UIImage,
        configuration: ExportConfiguration,
        fallbackToShareSheet: Bool = true,
        presentingViewController: UIViewController? = nil
    ) async throws -> ExportResult {
        // Format the image for the target platform
        let formattedImage = try formatter.format(
            image,
            for: configuration.platform,
            branding: configuration.branding,
            quality: configuration.quality
        )

        // Validate file size
        guard let imageData = formattedImage.jpegData(
            compressionQuality: configuration.quality.compressionQuality
        ) else {
            throw SocialExportError.formattingFailed
        }

        let maxSize = configuration.platform.maxImageFileSize
        if imageData.count > maxSize {
            // Try reducing quality to fit
            let reducedData = try compressToFit(
                image: formattedImage,
                maxSize: maxSize
            )
            return try await exportData(
                reducedData,
                originalImage: formattedImage,
                configuration: configuration,
                fallbackToShareSheet: fallbackToShareSheet,
                presentingViewController: presentingViewController
            )
        }

        return try await exportData(
            imageData,
            originalImage: formattedImage,
            configuration: configuration,
            fallbackToShareSheet: fallbackToShareSheet,
            presentingViewController: presentingViewController
        )
    }

    // MARK: - Private

    @MainActor
    private func exportData(
        _ data: Data,
        originalImage: UIImage,
        configuration: ExportConfiguration,
        fallbackToShareSheet: Bool,
        presentingViewController: UIViewController?
    ) async throws -> ExportResult {
        let platform = configuration.platform

        // Check if platform app is available
        guard platform.isAvailable else {
            if fallbackToShareSheet {
                return try await exportViaShareSheet(
                    image: originalImage,
                    configuration: configuration,
                    presentingViewController: presentingViewController
                )
            }
            throw SocialExportError.platformNotAvailable(platform)
        }

        switch platform {
        case .instagramStories:
            return try await exportToInstagramStories(
                data: data,
                configuration: configuration
            )
        case .instagramFeed:
            return try await exportToInstagramFeed(
                image: originalImage,
                configuration: configuration,
                presentingViewController: presentingViewController
            )
        case .tiktok:
            return try await exportToTikTok(
                image: originalImage,
                configuration: configuration,
                presentingViewController: presentingViewController
            )
        case .twitterX:
            return try await exportToTwitterX(
                image: originalImage,
                configuration: configuration,
                presentingViewController: presentingViewController
            )
        case .general:
            return try await exportViaShareSheet(
                image: originalImage,
                configuration: configuration,
                presentingViewController: presentingViewController
            )
        }
    }

    // MARK: - Instagram Stories

    @MainActor
    private func exportToInstagramStories(
        data: Data,
        configuration: ExportConfiguration
    ) async throws -> ExportResult {
        guard let appID = facebookAppID else {
            throw SocialExportError.missingFacebookAppID
        }

        guard let url = URL(
            string: "instagram-stories://share?source_application=\(appID)"
        ) else {
            throw SocialExportError.formattingFailed
        }

        // Set pasteboard items BEFORE opening URL scheme
        var pasteboardItems: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": data
        ]

        // Optional: set background gradient colors
        // pasteboardItems["com.instagram.sharedSticker.backgroundTopColor"] = "#FF0000"
        // pasteboardItems["com.instagram.sharedSticker.backgroundBottomColor"] = "#0000FF"

        if let caption = configuration.fullCaption {
            pasteboardItems["com.instagram.sharedSticker.contentURL"] = caption
        }

        UIPasteboard.general.setItems(
            [pasteboardItems],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )

        let opened = await UIApplication.shared.open(url)
        return opened ? .success(platform: .instagramStories) : .fallbackUsed
    }

    // MARK: - Instagram Feed

    @MainActor
    private func exportToInstagramFeed(
        image: UIImage,
        configuration: ExportConfiguration,
        presentingViewController: UIViewController?
    ) async throws -> ExportResult {
        // Instagram Feed sharing requires saving to Photos and opening
        // the Instagram app. Use UIDocumentInteractionController for
        // the most reliable behavior.
        return try await exportViaShareSheet(
            image: image,
            configuration: configuration,
            presentingViewController: presentingViewController
        )
    }

    // MARK: - TikTok

    @MainActor
    private func exportToTikTok(
        image: UIImage,
        configuration: ExportConfiguration,
        presentingViewController: UIViewController?
    ) async throws -> ExportResult {
        // TikTok SDK or share sheet integration
        // For basic sharing, use the activity view controller
        // For deeper integration, use TikTok's OpenSDK
        return try await exportViaShareSheet(
            image: image,
            configuration: configuration,
            presentingViewController: presentingViewController
        )
    }

    // MARK: - Twitter/X

    @MainActor
    private func exportToTwitterX(
        image: UIImage,
        configuration: ExportConfiguration,
        presentingViewController: UIViewController?
    ) async throws -> ExportResult {
        // Build tweet URL with text
        if let caption = configuration.fullCaption,
           let encodedCaption = caption.addingPercentEncoding(
               withAllowedCharacters: .urlQueryAllowed
           ),
           let tweetURL = URL(
               string: "twitter://post?message=\(encodedCaption)"
           ) {
            let opened = await UIApplication.shared.open(tweetURL)
            if opened {
                return .success(platform: .twitterX)
            }
        }

        // Fall back to share sheet if URL scheme fails
        return try await exportViaShareSheet(
            image: image,
            configuration: configuration,
            presentingViewController: presentingViewController
        )
    }

    // MARK: - General Share Sheet

    @MainActor
    private func exportViaShareSheet(
        image: UIImage,
        configuration: ExportConfiguration,
        presentingViewController: UIViewController?
    ) async throws -> ExportResult {
        guard let viewController = presentingViewController
            ?? UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController else {
            throw SocialExportError.exportFailed(
                underlying: NSError(
                    domain: "SocialExporter",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No presenting view controller"]
                )
            )
        }

        var activityItems: [Any] = [image]

        if let caption = configuration.fullCaption {
            activityItems.append(caption)
        }

        if let url = configuration.attachmentURL {
            activityItems.append(url)
        }

        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Exclude irrelevant activities
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]

        // iPad requires popover presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        return await withCheckedContinuation { continuation in
            activityVC.completionWithItemsHandler = { activityType, completed, _, error in
                if let error {
                    continuation.resume(returning: .failed(.exportFailed(underlying: error)))
                } else if completed {
                    continuation.resume(returning: .success(platform: .general))
                } else {
                    continuation.resume(returning: .cancelled)
                }
            }

            viewController.present(activityVC, animated: true)
        }
    }

    // MARK: - Compression

    private func compressToFit(image: UIImage, maxSize: Int) throws -> Data {
        var quality: CGFloat = 0.9
        let minimumQuality: CGFloat = 0.1

        while quality >= minimumQuality {
            guard let data = image.jpegData(compressionQuality: quality) else {
                throw SocialExportError.formattingFailed
            }

            if data.count <= maxSize {
                return data
            }

            quality -= 0.1
        }

        // Last resort: try with minimum quality
        guard let data = image.jpegData(compressionQuality: minimumQuality) else {
            throw SocialExportError.formattingFailed
        }

        if data.count <= maxSize {
            return data
        }

        throw SocialExportError.imageTooLarge(
            currentSize: data.count,
            maxSize: maxSize
        )
    }
}
```

## ContentFormatter.swift

```swift
import UIKit
import CoreGraphics

/// Formats content for each social platform by resizing, cropping
/// to the target aspect ratio, and applying branding overlays.
///
/// Usage:
/// ```swift
/// let formatter = ContentFormatter()
/// let formatted = try formatter.format(
///     originalImage,
///     for: .instagramStories,
///     branding: .cornerLogo(logo)
/// )
/// ```
struct ContentFormatter: Sendable {

    /// Format an image for the specified platform.
    ///
    /// - Parameters:
    ///   - image: Source image to format.
    ///   - platform: Target social platform.
    ///   - branding: Optional branding overlay style.
    ///   - quality: Export quality affecting resolution scaling.
    /// - Returns: Formatted image ready for export.
    func format(
        _ image: UIImage,
        for platform: SocialPlatform,
        branding: BrandingStyle = .none,
        quality: ExportQuality = .high
    ) throws -> UIImage {
        let targetSize = CGSize(
            width: platform.targetResolution.width * quality.resolutionScale,
            height: platform.targetResolution.height * quality.resolutionScale
        )

        // Step 1: Crop to target aspect ratio
        let cropped = try cropToAspectRatio(
            image: image,
            targetAspect: platform.aspectRatio
        )

        // Step 2: Resize to target resolution
        let resized = resize(image: cropped, to: targetSize)

        // Step 3: Apply branding overlay
        let branded = try applyBranding(image: resized, branding: branding)

        return branded
    }

    // MARK: - Crop to Aspect Ratio

    /// Crops the image to match the target aspect ratio using center crop.
    private func cropToAspectRatio(
        image: UIImage,
        targetAspect: CGSize
    ) throws -> UIImage {
        let imageSize = image.size
        let targetRatio = targetAspect.width / targetAspect.height
        let imageRatio = imageSize.width / imageSize.height

        var cropRect: CGRect

        if imageRatio > targetRatio {
            // Image is wider than target — crop sides
            let newWidth = imageSize.height * targetRatio
            let xOffset = (imageSize.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: imageSize.height)
        } else {
            // Image is taller than target — crop top and bottom
            let newHeight = imageSize.width / targetRatio
            let yOffset = (imageSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: imageSize.width, height: newHeight)
        }

        // Scale crop rect for retina
        let scale = image.scale
        let scaledRect = CGRect(
            x: cropRect.origin.x * scale,
            y: cropRect.origin.y * scale,
            width: cropRect.size.width * scale,
            height: cropRect.size.height * scale
        )

        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else {
            throw SocialExportError.formattingFailed
        }

        return UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
    }

    // MARK: - Resize

    /// Resizes the image to the exact target size.
    private func resize(image: UIImage, to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    // MARK: - Branding Overlay

    /// Applies branding overlay (logo or banner) to the image.
    private func applyBranding(
        image: UIImage,
        branding: BrandingStyle
    ) throws -> UIImage {
        switch branding {
        case .none:
            return image

        case .cornerLogo(let logo, let corner):
            return try applyCornerLogo(
                image: image,
                logo: logo,
                corner: corner
            )

        case .bottomBanner(let appName, let urlString, let backgroundColor):
            return try applyBottomBanner(
                image: image,
                appName: appName,
                urlString: urlString,
                backgroundColor: backgroundColor
            )
        }
    }

    /// Draws a small logo in the specified corner with padding and optional background.
    private func applyCornerLogo(
        image: UIImage,
        logo: UIImage,
        corner: BrandingStyle.Corner
    ) throws -> UIImage {
        let imageSize = image.size
        let padding: CGFloat = imageSize.width * 0.03  // 3% padding
        let logoMaxSize = imageSize.width * 0.12        // 12% of image width

        // Scale logo maintaining aspect ratio
        let logoAspect = logo.size.width / logo.size.height
        let logoSize: CGSize
        if logoAspect >= 1 {
            logoSize = CGSize(width: logoMaxSize, height: logoMaxSize / logoAspect)
        } else {
            logoSize = CGSize(width: logoMaxSize * logoAspect, height: logoMaxSize)
        }

        // Calculate position
        let logoOrigin: CGPoint
        switch corner {
        case .topLeft:
            logoOrigin = CGPoint(x: padding, y: padding)
        case .topRight:
            logoOrigin = CGPoint(x: imageSize.width - logoSize.width - padding, y: padding)
        case .bottomLeft:
            logoOrigin = CGPoint(x: padding, y: imageSize.height - logoSize.height - padding)
        case .bottomRight:
            logoOrigin = CGPoint(
                x: imageSize.width - logoSize.width - padding,
                y: imageSize.height - logoSize.height - padding
            )
        }

        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)

            // Draw semi-transparent background behind logo
            let bgRect = CGRect(
                x: logoOrigin.x - padding / 2,
                y: logoOrigin.y - padding / 2,
                width: logoSize.width + padding,
                height: logoSize.height + padding
            )
            UIColor.black.withAlphaComponent(0.3).setFill()
            UIBezierPath(roundedRect: bgRect, cornerRadius: padding / 2).fill()

            // Draw logo
            let logoRect = CGRect(origin: logoOrigin, size: logoSize)
            logo.draw(in: logoRect)
        }
    }

    /// Draws a banner at the bottom of the image with app name and optional URL.
    private func applyBottomBanner(
        image: UIImage,
        appName: String,
        urlString: String?,
        backgroundColor: UIColor
    ) throws -> UIImage {
        let imageSize = image.size
        let bannerHeight = imageSize.height * 0.06  // 6% of image height
        let fontSize = bannerHeight * 0.5
        let padding = bannerHeight * 0.2

        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)

            // Draw banner background
            let bannerRect = CGRect(
                x: 0,
                y: imageSize.height - bannerHeight,
                width: imageSize.width,
                height: bannerHeight
            )
            backgroundColor.withAlphaComponent(0.7).setFill()
            context.fill(bannerRect)

            // Draw app name
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let nameString = appName as NSString
            let nameSize = nameString.size(withAttributes: nameAttributes)
            let namePoint = CGPoint(
                x: padding,
                y: imageSize.height - bannerHeight + (bannerHeight - nameSize.height) / 2
            )
            nameString.draw(at: namePoint, withAttributes: nameAttributes)

            // Draw URL if provided
            if let urlString {
                let urlAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize * 0.8, weight: .regular),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.8)
                ]
                let urlNSString = urlString as NSString
                let urlSize = urlNSString.size(withAttributes: urlAttributes)
                let urlPoint = CGPoint(
                    x: imageSize.width - urlSize.width - padding,
                    y: imageSize.height - bannerHeight + (bannerHeight - urlSize.height) / 2
                )
                urlNSString.draw(at: urlPoint, withAttributes: urlAttributes)
            }
        }
    }
}
```

## ExportPreviewView.swift

```swift
import SwiftUI

/// Shows a preview of how content will appear on each social platform.
///
/// Displays the image cropped and scaled to each platform's aspect ratio
/// so the user can see the result before exporting.
///
/// Usage:
/// ```swift
/// ExportPreviewView(
///     image: myImage,
///     platform: .instagramStories,
///     branding: .cornerLogo(logo)
/// )
/// ```
struct ExportPreviewView: View {
    let image: UIImage
    let platform: SocialPlatform
    let branding: BrandingStyle
    let quality: ExportQuality

    @State private var previewImage: UIImage?
    @State private var isProcessing = false
    @State private var error: String?

    init(
        image: UIImage,
        platform: SocialPlatform,
        branding: BrandingStyle = .none,
        quality: ExportQuality = .high
    ) {
        self.image = image
        self.platform = platform
        self.branding = branding
        self.quality = quality
    }

    var body: some View {
        VStack(spacing: 12) {
            // Platform header
            HStack {
                Image(systemName: platform.iconName)
                    .font(.title3)
                Text(platform.displayName)
                    .font(.headline)
                Spacer()
                Text(resolutionLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Preview image
            previewContent
                .frame(maxWidth: previewWidth, maxHeight: previewHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            // Aspect ratio info
            Text(aspectRatioLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .task(id: platform) {
            await generatePreview()
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        if isProcessing {
            ProgressView("Formatting...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.1))
        } else if let previewImage {
            Image(uiImage: previewImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if let error {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.secondary.opacity(0.1))
        } else {
            Color.secondary.opacity(0.1)
        }
    }

    // MARK: - Layout Calculations

    /// Maximum preview width within the available space.
    private var previewWidth: CGFloat {
        300
    }

    /// Preview height based on platform aspect ratio.
    private var previewHeight: CGFloat {
        let ratio = platform.aspectRatio
        return previewWidth * (ratio.height / ratio.width)
    }

    private var resolutionLabel: String {
        let res = platform.targetResolution
        return "\(Int(res.width))x\(Int(res.height))"
    }

    private var aspectRatioLabel: String {
        let ratio = platform.aspectRatio
        return "Aspect ratio: \(Int(ratio.width)):\(Int(ratio.height))"
    }

    // MARK: - Preview Generation

    private func generatePreview() async {
        isProcessing = true
        error = nil

        do {
            let formatter = ContentFormatter()
            let formatted = try formatter.format(
                image,
                for: platform,
                branding: branding,
                quality: quality
            )
            previewImage = formatted
        } catch {
            self.error = error.localizedDescription
        }

        isProcessing = false
    }
}
```

## SocialExportSheet.swift

```swift
import SwiftUI

/// Complete export flow with platform picker, preview, and share action.
///
/// Presents a bottom sheet showing available social platforms,
/// a preview of how the content will appear, and an export button.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showExportSheet) {
///     SocialExportSheet(
///         image: contentImage,
///         facebookAppID: "YOUR_FB_APP_ID",
///         branding: .cornerLogo(appLogo)
///     )
/// }
/// ```
struct SocialExportSheet: View {
    let image: UIImage
    let facebookAppID: String?
    let defaultBranding: BrandingStyle

    @State private var selectedPlatform: SocialPlatform = .general
    @State private var quality: ExportQuality = .high
    @State private var caption: String = ""
    @State private var isExporting = false
    @State private var exportResult: ExportResult?
    @State private var showResultAlert = false

    @Environment(\.dismiss) private var dismiss

    init(
        image: UIImage,
        facebookAppID: String? = nil,
        branding: BrandingStyle = .none
    ) {
        self.image = image
        self.facebookAppID = facebookAppID
        self.defaultBranding = branding
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Platform Picker
                    platformPicker

                    // Preview
                    ExportPreviewView(
                        image: image,
                        platform: selectedPlatform,
                        branding: defaultBranding,
                        quality: quality
                    )
                    .padding(.horizontal)

                    // Caption input (for platforms that support it)
                    if selectedPlatform == .twitterX || selectedPlatform == .general {
                        captionSection
                    }

                    // Quality picker
                    qualityPicker

                    // Export button
                    exportButton
                }
                .padding(.vertical)
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Export Result", isPresented: $showResultAlert) {
                Button("OK") {
                    if case .success = exportResult {
                        dismiss()
                    }
                }
            } message: {
                Text(resultMessage)
            }
        }
    }

    // MARK: - Platform Picker

    private var platformPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Platform")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SocialPlatform.allCases) { platform in
                        PlatformButton(
                            platform: platform,
                            isSelected: selectedPlatform == platform
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPlatform = platform
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Caption

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Add a caption...", text: $caption, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }

    // MARK: - Quality Picker

    private var qualityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quality")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Picker("Quality", selection: $quality) {
                ForEach(ExportQuality.allCases, id: \.self) { q in
                    Text(q.rawValue.capitalized).tag(q)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }

    // MARK: - Export Button

    private var exportButton: some View {
        Button {
            Task { await performExport() }
        } label: {
            HStack {
                if isExporting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: selectedPlatform.iconName)
                }
                Text(isExporting ? "Exporting..." : "Export to \(selectedPlatform.displayName)")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isExporting)
        .padding(.horizontal)
    }

    // MARK: - Export Logic

    @MainActor
    private func performExport() async {
        isExporting = true

        let configuration = ExportConfiguration(
            platform: selectedPlatform,
            quality: quality,
            branding: defaultBranding,
            caption: caption.isEmpty ? nil : caption
        )

        let exporter = SocialExporter(facebookAppID: facebookAppID)

        do {
            exportResult = try await exporter.export(
                image: image,
                configuration: configuration,
                fallbackToShareSheet: true
            )
        } catch {
            exportResult = .failed(
                .exportFailed(underlying: error)
            )
        }

        isExporting = false
        showResultAlert = true
    }

    private var resultMessage: String {
        switch exportResult {
        case .success(let platform):
            return "Successfully shared to \(platform.displayName)!"
        case .fallbackUsed:
            return "The app is not installed. Content was shared via the system share sheet."
        case .cancelled:
            return "Export was cancelled."
        case .failed(let error):
            return error.localizedDescription
        case nil:
            return ""
        }
    }
}

// MARK: - Platform Button

/// Individual platform selector button with icon and label.
private struct PlatformButton: View {
    let platform: SocialPlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: platform.iconName)
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                    )
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(platform.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Export to \(platform.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Test Helpers

extension UIImage {
    /// Creates a solid-color test image for use in previews and tests.
    static func testSolidColor(
        _ color: UIColor,
        size: CGSize = CGSize(width: 100, height: 100)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Preview

#Preview {
    SocialExportSheet(
        image: .testSolidColor(.systemBlue, size: CGSize(width: 800, height: 600))
    )
}
```
