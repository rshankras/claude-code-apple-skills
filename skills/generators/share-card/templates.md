# Share Card Code Templates

Production-ready Swift templates for shareable card image generation. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## Platform Compatibility

```swift
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}
```

## ShareCardContent.swift

```swift
import Foundation

/// Protocol defining content that can be rendered as a share card.
///
/// Conform to this protocol to create custom card content types.
/// The renderer uses these properties to lay out the card.
protocol ShareCardContent: Sendable {
    /// Primary title displayed prominently on the card.
    var title: String { get }

    /// Optional subtitle or description below the title.
    var subtitle: String? { get }

    /// App or brand name shown in the card footer.
    var brandName: String { get }

    /// Optional SF Symbol name for a decorative icon.
    var iconName: String? { get }
}

// MARK: - Achievement Card Content

/// Content for achievement or milestone share cards.
///
/// Usage:
/// ```swift
/// let content = AchievementCardContent(
///     title: "First 5K Run",
///     subtitle: "Completed on March 15, 2025",
///     metric: "500 pts",
///     iconName: "figure.run",
///     brandName: "FitTracker"
/// )
/// ```
struct AchievementCardContent: ShareCardContent, Sendable {
    let title: String
    let subtitle: String?
    let metric: String
    let iconName: String?
    let brandName: String

    init(
        title: String,
        subtitle: String? = nil,
        metric: String,
        iconName: String? = nil,
        brandName: String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.metric = metric
        self.iconName = iconName
        self.brandName = brandName
    }
}

// MARK: - Statistics Card Content

/// A single statistic item displayed in a statistics card.
struct StatItem: Sendable, Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let trend: Trend?

    enum Trend: Sendable {
        case up, down, neutral
    }

    init(label: String, value: String, trend: Trend? = nil) {
        self.label = label
        self.value = value
        self.trend = trend
    }
}

/// Content for statistics or progress share cards.
///
/// Usage:
/// ```swift
/// let content = StatisticsCardContent(
///     title: "Weekly Progress",
///     stats: [
///         StatItem(label: "Steps", value: "52,340", trend: .up),
///         StatItem(label: "Calories", value: "3,200", trend: .neutral),
///     ],
///     dateRange: "Mar 10 - Mar 16",
///     brandName: "FitTracker"
/// )
/// ```
struct StatisticsCardContent: ShareCardContent, Sendable {
    let title: String
    let subtitle: String?
    let stats: [StatItem]
    let dateRange: String?
    let brandName: String

    var iconName: String? { nil }

    init(
        title: String,
        subtitle: String? = nil,
        stats: [StatItem],
        dateRange: String? = nil,
        brandName: String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.stats = stats
        self.dateRange = dateRange
        self.brandName = brandName
    }
}

// MARK: - Quote Card Content

/// Content for quote or text share cards.
///
/// Usage:
/// ```swift
/// let content = QuoteCardContent(
///     quote: "The only way to do great work is to love what you do.",
///     attribution: "Steve Jobs",
///     brandName: "DailyQuotes"
/// )
/// ```
struct QuoteCardContent: ShareCardContent, Sendable {
    let quote: String
    let attribution: String?
    let brandName: String

    var title: String { quote }
    var subtitle: String? { attribution }
    var iconName: String? { nil }

    init(
        quote: String,
        attribution: String? = nil,
        brandName: String
    ) {
        self.quote = quote
        self.attribution = attribution
        self.brandName = brandName
    }
}
```

## ShareCardStyle.swift

```swift
import SwiftUI

/// Predefined visual styles for share cards.
///
/// Each style defines colors, fonts, spacing, and layout
/// parameters used by the card renderer.
enum ShareCardStyle: String, CaseIterable, Identifiable, Sendable {
    case minimal
    case branded
    case statistics

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .branded: return "Branded"
        case .statistics: return "Statistics"
        }
    }

    // MARK: - Colors

    var backgroundColor: Color {
        switch self {
        case .minimal: return .white
        case .branded: return Color(red: 0.1, green: 0.1, blue: 0.15)
        case .statistics: return Color(red: 0.05, green: 0.05, blue: 0.1)
        }
    }

    var primaryTextColor: Color {
        switch self {
        case .minimal: return .black
        case .branded: return .white
        case .statistics: return .white
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .minimal: return Color(white: 0.4)
        case .branded: return Color(white: 0.7)
        case .statistics: return Color(white: 0.6)
        }
    }

    var accentColor: Color {
        switch self {
        case .minimal: return .blue
        case .branded: return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .statistics: return Color(red: 0.3, green: 0.85, blue: 0.6)
        }
    }

    // MARK: - Typography

    var titleFont: Font {
        switch self {
        case .minimal: return .system(size: 28, weight: .semibold, design: .default)
        case .branded: return .system(size: 32, weight: .bold, design: .rounded)
        case .statistics: return .system(size: 24, weight: .bold, design: .monospaced)
        }
    }

    var subtitleFont: Font {
        switch self {
        case .minimal: return .system(size: 16, weight: .regular, design: .default)
        case .branded: return .system(size: 18, weight: .medium, design: .rounded)
        case .statistics: return .system(size: 14, weight: .regular, design: .monospaced)
        }
    }

    var metricFont: Font {
        switch self {
        case .minimal: return .system(size: 48, weight: .bold, design: .rounded)
        case .branded: return .system(size: 56, weight: .heavy, design: .rounded)
        case .statistics: return .system(size: 44, weight: .bold, design: .monospaced)
        }
    }

    var brandFont: Font {
        .system(size: 14, weight: .medium, design: .default)
    }

    // MARK: - Layout

    var cornerRadius: CGFloat {
        switch self {
        case .minimal: return 16
        case .branded: return 24
        case .statistics: return 20
        }
    }

    var contentPadding: EdgeInsets {
        switch self {
        case .minimal: return EdgeInsets(top: 40, leading: 32, bottom: 40, trailing: 32)
        case .branded: return EdgeInsets(top: 48, leading: 36, bottom: 48, trailing: 36)
        case .statistics: return EdgeInsets(top: 36, leading: 28, bottom: 36, trailing: 28)
        }
    }
}

// MARK: - Card Size Presets

/// Predefined card sizes optimized for different sharing platforms.
enum ShareCardSize: String, CaseIterable, Identifiable, Sendable {
    case square      // 1080x1080 — Instagram, general
    case story       // 1080x1920 — Instagram Stories, TikTok
    case wide        // 1200x630  — Twitter/X, Open Graph
    case compact     // 800x600   — Messages, lightweight

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .square:  return CGSize(width: 1080, height: 1080)
        case .story:   return CGSize(width: 1080, height: 1920)
        case .wide:    return CGSize(width: 1200, height: 630)
        case .compact: return CGSize(width: 800, height: 600)
        }
    }

    var displayName: String {
        switch self {
        case .square:  return "Square (1080x1080)"
        case .story:   return "Story (1080x1920)"
        case .wide:    return "Wide (1200x630)"
        case .compact: return "Compact (800x600)"
        }
    }

    /// Aspect ratio (width / height) for preview scaling.
    var aspectRatio: CGFloat {
        size.width / size.height
    }
}
```

## ShareCardRenderer.swift

```swift
import SwiftUI

/// Renders share card SwiftUI views into raster images using `ImageRenderer`.
///
/// Must be called from the main actor since `ImageRenderer` requires it.
///
/// Usage:
/// ```swift
/// let renderer = ShareCardRenderer()
/// let image = await renderer.render(
///     content: achievementContent,
///     style: .branded,
///     size: .square
/// )
/// ```
@MainActor
struct ShareCardRenderer {

    /// Render a share card to a platform image.
    ///
    /// - Parameters:
    ///   - content: The card content to render.
    ///   - style: The visual style to apply.
    ///   - size: The card size preset (default: square).
    ///   - qrCodeURL: Optional URL to encode as a QR code overlay.
    ///   - scale: The render scale factor (default: 2.0 for Retina).
    /// - Returns: A rendered platform image, or nil if rendering fails.
    func render(
        content: any ShareCardContent,
        style: ShareCardStyle,
        size: ShareCardSize = .square,
        qrCodeURL: URL? = nil,
        scale: CGFloat = 2.0
    ) -> PlatformImage? {
        let cardView = ShareCardView(
            content: content,
            style: style,
            cardSize: size,
            qrCodeURL: qrCodeURL
        )
        .frame(width: size.size.width, height: size.size.height)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = scale

        // Propose the exact card size so the layout doesn't compress
        renderer.proposedSize = ProposedViewSize(size.size)

        #if canImport(UIKit)
        return renderer.uiImage
        #elseif canImport(AppKit)
        return renderer.nsImage
        #endif
    }

    /// Render a share card and return PNG data suitable for sharing.
    ///
    /// PNG preserves text sharpness, which is ideal for cards with typography.
    func renderPNGData(
        content: any ShareCardContent,
        style: ShareCardStyle,
        size: ShareCardSize = .square,
        qrCodeURL: URL? = nil,
        scale: CGFloat = 2.0
    ) -> Data? {
        guard let image = render(
            content: content,
            style: style,
            size: size,
            qrCodeURL: qrCodeURL,
            scale: scale
        ) else { return nil }

        #if canImport(UIKit)
        return image.pngData()
        #elseif canImport(AppKit)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }

    /// Render a share card and return JPEG data with configurable quality.
    ///
    /// JPEG is smaller but may show compression artifacts on text.
    /// Use quality >= 0.9 for text-heavy cards.
    func renderJPEGData(
        content: any ShareCardContent,
        style: ShareCardStyle,
        size: ShareCardSize = .square,
        qrCodeURL: URL? = nil,
        scale: CGFloat = 2.0,
        quality: CGFloat = 0.92
    ) -> Data? {
        guard let image = render(
            content: content,
            style: style,
            size: size,
            qrCodeURL: qrCodeURL,
            scale: scale
        ) else { return nil }

        #if canImport(UIKit)
        return image.jpegData(compressionQuality: quality)
        #elseif canImport(AppKit)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
        #endif
    }
}
```

## ShareCardView.swift

```swift
import SwiftUI

/// The SwiftUI view that composes the card layout.
///
/// This view is rendered to an image by `ShareCardRenderer`.
/// It should NOT be used directly in the app UI — use `ShareCardSheet` instead.
struct ShareCardView: View {
    let content: any ShareCardContent
    let style: ShareCardStyle
    let cardSize: ShareCardSize
    let qrCodeURL: URL?

    init(
        content: any ShareCardContent,
        style: ShareCardStyle,
        cardSize: ShareCardSize = .square,
        qrCodeURL: URL? = nil
    ) {
        self.content = content
        self.style = style
        self.cardSize = cardSize
        self.qrCodeURL = qrCodeURL
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(style.backgroundColor)

            // Content
            VStack(spacing: 0) {
                Spacer(minLength: style.contentPadding.top)

                contentBody

                Spacer(minLength: 16)

                footerView
                    .padding(.bottom, style.contentPadding.bottom)
            }
            .padding(.horizontal, style.contentPadding.leading)

            // QR Code overlay (bottom-right corner)
            if let qrCodeURL {
                qrOverlay(url: qrCodeURL)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }

    // MARK: - Content Body

    @ViewBuilder
    private var contentBody: some View {
        if let achievement = content as? AchievementCardContent {
            AchievementCardBody(content: achievement, style: style)
        } else if let statistics = content as? StatisticsCardContent {
            StatisticsCardBody(content: statistics, style: style)
        } else if let quote = content as? QuoteCardContent {
            QuoteCardBody(content: quote, style: style)
        } else {
            GenericCardBody(content: content, style: style)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Text(content.brandName)
                .font(style.brandFont)
                .foregroundStyle(style.secondaryTextColor)

            Spacer()

            if qrCodeURL == nil {
                // Show a subtle divider dot when there's no QR code
                Circle()
                    .fill(style.accentColor.opacity(0.5))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - QR Code Overlay

    private func qrOverlay(url: URL) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                QRCodeOverlay(url: url, style: style)
                    .frame(width: cardSize.size.width * 0.12,
                           height: cardSize.size.width * 0.12)
                    .padding(style.contentPadding.trailing)
                    .padding(.bottom, style.contentPadding.bottom)
            }
        }
    }
}

// MARK: - Achievement Card Body

/// Renders achievement/milestone content within a share card.
private struct AchievementCardBody: View {
    let content: AchievementCardContent
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            if let iconName = content.iconName {
                Image(systemName: iconName)
                    .font(.system(size: 56))
                    .foregroundStyle(style.accentColor)
                    .padding(.bottom, 8)
            }

            // Metric
            Text(content.metric)
                .font(style.metricFont)
                .foregroundStyle(style.accentColor)

            // Title
            Text(content.title)
                .font(style.titleFont)
                .foregroundStyle(style.primaryTextColor)
                .multilineTextAlignment(.center)

            // Subtitle
            if let subtitle = content.subtitle {
                Text(subtitle)
                    .font(style.subtitleFont)
                    .foregroundStyle(style.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Statistics Card Body

/// Renders statistics/progress content within a share card.
private struct StatisticsCardBody: View {
    let content: StatisticsCardContent
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text(content.title)
                .font(style.titleFont)
                .foregroundStyle(style.primaryTextColor)

            // Date range
            if let dateRange = content.dateRange {
                Text(dateRange)
                    .font(style.subtitleFont)
                    .foregroundStyle(style.secondaryTextColor)
            }

            // Stats grid
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: 16),
                count: min(content.stats.count, 3)
            )

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(content.stats) { stat in
                    StatItemView(stat: stat, style: style)
                }
            }
        }
    }
}

/// Renders a single statistic item with label, value, and optional trend.
private struct StatItemView: View {
    let stat: StatItem
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text(stat.value)
                    .font(style.metricFont)
                    .foregroundStyle(style.primaryTextColor)

                if let trend = stat.trend {
                    trendIndicator(trend)
                }
            }

            Text(stat.label)
                .font(style.subtitleFont)
                .foregroundStyle(style.secondaryTextColor)
        }
    }

    @ViewBuilder
    private func trendIndicator(_ trend: StatItem.Trend) -> some View {
        switch trend {
        case .up:
            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.green)
        case .down:
            Image(systemName: "arrow.down.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.red)
        case .neutral:
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(style.secondaryTextColor)
        }
    }
}

// MARK: - Quote Card Body

/// Renders quote/text content within a share card.
private struct QuoteCardBody: View {
    let content: QuoteCardContent
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: 24) {
            // Decorative quotation mark
            Text("\u{201C}")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(style.accentColor.opacity(0.3))
                .frame(height: 50)

            // Quote text
            Text(content.quote)
                .font(style.titleFont)
                .foregroundStyle(style.primaryTextColor)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            // Attribution
            if let attribution = content.attribution {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(style.accentColor)
                        .frame(width: 24, height: 2)

                    Text(attribution)
                        .font(style.subtitleFont)
                        .foregroundStyle(style.secondaryTextColor)
                }
            }
        }
    }
}

// MARK: - Generic Card Body

/// Fallback renderer for custom `ShareCardContent` conformances.
private struct GenericCardBody: View {
    let content: any ShareCardContent
    let style: ShareCardStyle

    var body: some View {
        VStack(spacing: 20) {
            if let iconName = content.iconName {
                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(style.accentColor)
            }

            Text(content.title)
                .font(style.titleFont)
                .foregroundStyle(style.primaryTextColor)
                .multilineTextAlignment(.center)

            if let subtitle = content.subtitle {
                Text(subtitle)
                    .font(style.subtitleFont)
                    .foregroundStyle(style.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
```

## ShareCardSheet.swift

```swift
import SwiftUI

/// A complete sharing sheet with live card preview, style picker, and ShareLink.
///
/// Presents a preview of the share card with options to change style and size,
/// then share via the system share sheet.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showShareCard) {
///     ShareCardSheet(
///         content: AchievementCardContent(
///             title: "First Run",
///             metric: "500 pts",
///             brandName: "FitApp"
///         )
///     )
/// }
/// ```
struct ShareCardSheet: View {
    let content: any ShareCardContent
    let qrCodeURL: URL?

    @State private var selectedStyle: ShareCardStyle = .branded
    @State private var selectedSize: ShareCardSize = .square
    @State private var renderedImage: PlatformImage?
    @State private var isRendering = false
    @Environment(\.dismiss) private var dismiss

    init(content: any ShareCardContent, qrCodeURL: URL? = nil) {
        self.content = content
        self.qrCodeURL = qrCodeURL
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    cardPreview
                    stylePickerSection
                    sizePickerSection
                    shareSection
                }
                .padding()
            }
            .navigationTitle("Share Card")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task(id: StyleSizeKey(style: selectedStyle, size: selectedSize)) {
                await renderCard()
            }
        }
    }

    // MARK: - Card Preview

    private var cardPreview: some View {
        Group {
            if let renderedImage {
                Image(platformImage: renderedImage)
                    .resizable()
                    .aspectRatio(selectedSize.aspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .aspectRatio(selectedSize.aspectRatio, contentMode: .fit)
                    .overlay(ProgressView())
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Style Picker

    private var stylePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style")
                .font(.headline)

            Picker("Style", selection: $selectedStyle) {
                ForEach(ShareCardStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Size Picker

    private var sizePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Size")
                .font(.headline)

            Picker("Size", selection: $selectedSize) {
                ForEach(ShareCardSize.allCases) { size in
                    Text(size.displayName).tag(size)
                }
            }
            #if os(iOS)
            .pickerStyle(.menu)
            #else
            .pickerStyle(.automatic)
            #endif
        }
    }

    // MARK: - Share Section

    private var shareSection: some View {
        VStack(spacing: 12) {
            if let renderedImage {
                ShareLink(
                    item: Image(platformImage: renderedImage),
                    preview: SharePreview(
                        content.title,
                        image: Image(platformImage: renderedImage)
                    )
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button(action: {}) {
                    Label("Rendering...", systemImage: "hourglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(true)
            }

            // Save to Photos button (iOS only)
            #if canImport(UIKit)
            if let renderedImage {
                Button {
                    UIImageWriteToSavedPhotosAlbum(renderedImage, nil, nil, nil)
                } label: {
                    Label("Save to Photos", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            #endif
        }
    }

    // MARK: - Rendering

    @MainActor
    private func renderCard() async {
        isRendering = true
        let renderer = ShareCardRenderer()
        renderedImage = renderer.render(
            content: content,
            style: selectedStyle,
            size: selectedSize,
            qrCodeURL: qrCodeURL
        )
        isRendering = false
    }
}

/// Key for tracking style + size changes to trigger re-render.
private struct StyleSizeKey: Equatable {
    let style: ShareCardStyle
    let size: ShareCardSize
}
```

## QRCodeOverlay.swift

```swift
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Generates and displays a QR code overlay for embedding deep links in share cards.
///
/// Uses CoreImage's built-in QR code generator for reliable encoding.
///
/// Usage:
/// ```swift
/// QRCodeOverlay(
///     url: URL(string: "https://myapp.com/share/123")!,
///     style: .branded
/// )
/// .frame(width: 120, height: 120)
/// ```
struct QRCodeOverlay: View {
    let url: URL
    let style: ShareCardStyle

    var body: some View {
        ZStack {
            // Background for contrast
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .padding(-4)

            if let qrImage = QRCodeGenerator.generate(
                from: url.absoluteString,
                size: CGSize(width: 200, height: 200)
            ) {
                Image(platformImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

// MARK: - QR Code Generator

/// CoreImage-based QR code generator.
///
/// Generates high-resolution QR code images suitable for embedding in share cards.
/// The output is a crisp, black-on-transparent QR code.
enum QRCodeGenerator {

    private static let context = CIContext()

    /// Generate a QR code image from a string.
    ///
    /// - Parameters:
    ///   - string: The string to encode (typically a URL).
    ///   - size: The desired output size in points.
    /// - Returns: A platform image containing the QR code, or nil if generation fails.
    static func generate(from string: String, size: CGSize) -> PlatformImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"  // Medium error correction

        guard let ciImage = filter.outputImage else { return nil }

        // Scale the QR code to the requested size
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let scaledImage = ciImage.transformed(
            by: CGAffineTransform(scaleX: scaleX, y: scaleY)
        )

        guard let cgImage = context.createCGImage(
            scaledImage,
            from: scaledImage.extent
        ) else { return nil }

        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: size.width, height: size.height)
        )
        #endif
    }
}
```
