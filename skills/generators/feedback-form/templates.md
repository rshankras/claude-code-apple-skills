# Feedback Form Code Templates

Production-ready Swift templates for in-app feedback collection. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

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

## FeedbackCategory.swift

```swift
import Foundation

/// Categories for user feedback submissions.
///
/// Each category has an SF Symbol icon, display name, and description
/// to guide users in selecting the right type of feedback.
enum FeedbackCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case bug
    case featureRequest
    case general
    case praise
    case other

    var id: String { rawValue }

    /// SF Symbol name for the category.
    var icon: String {
        switch self {
        case .bug: return "ladybug"
        case .featureRequest: return "lightbulb"
        case .general: return "text.bubble"
        case .praise: return "heart"
        case .other: return "ellipsis.circle"
        }
    }

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .bug: return "Bug Report"
        case .featureRequest: return "Feature Request"
        case .general: return "General Feedback"
        case .praise: return "Praise"
        case .other: return "Other"
        }
    }

    /// Short description to help users pick the right category.
    var categoryDescription: String {
        switch self {
        case .bug: return "Something isn't working correctly"
        case .featureRequest: return "Suggest a new feature or improvement"
        case .general: return "Share your thoughts about the app"
        case .praise: return "Let us know what you love"
        case .other: return "Anything else on your mind"
        }
    }
}
```

## FeedbackEntry.swift

```swift
import Foundation

/// A single feedback submission from a user.
///
/// Contains the feedback content, sentiment rating, optional screenshots,
/// and device diagnostics for debugging context.
struct FeedbackEntry: Codable, Sendable {
    let id: UUID
    let category: FeedbackCategory
    let message: String
    /// User sentiment rating from 1 (very unhappy) to 5 (very happy).
    let rating: Int
    /// JPEG-compressed screenshot data.
    let screenshots: [Data]
    let deviceInfo: DeviceInfo
    let appVersion: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        category: FeedbackCategory,
        message: String,
        rating: Int,
        screenshots: [Data] = [],
        deviceInfo: DeviceInfo,
        appVersion: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.message = message
        self.rating = min(max(rating, 1), 5)
        self.screenshots = screenshots
        self.deviceInfo = deviceInfo
        self.appVersion = appVersion
        self.timestamp = timestamp
    }

    /// Whether this feedback suggests the user is happy enough to leave an App Store review.
    var suggestsAppStoreReview: Bool {
        rating >= 4
    }

    /// Whether this feedback suggests the user needs support follow-up.
    var suggestsSupportFollowUp: Bool {
        rating <= 2
    }
}

/// Device and environment information attached to feedback.
struct DeviceInfo: Codable, Sendable {
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let buildNumber: String
    let locale: String
    let timezone: String
    let diskSpaceAvailable: String
    let memoryUsage: String
    let batteryLevel: String

    /// Formats all device info as a readable string for email attachments.
    var formattedString: String {
        """
        Device: \(deviceModel)
        OS: \(osVersion)
        App Version: \(appVersion) (\(buildNumber))
        Locale: \(locale)
        Timezone: \(timezone)
        Disk Available: \(diskSpaceAvailable)
        Memory: \(memoryUsage)
        Battery: \(batteryLevel)
        """
    }
}
```

## FeedbackFormView.swift

```swift
import SwiftUI
import PhotosUI
#if canImport(StoreKit)
import StoreKit
#endif

/// In-app feedback form with sentiment rating, category selection,
/// message input, and optional screenshot attachment.
///
/// Routes happy users (rating >= 4) to App Store review and
/// unhappy users (rating <= 2) to a support confirmation.
///
/// Usage:
/// ```swift
/// @State private var showFeedback = false
///
/// Button("Feedback") { showFeedback = true }
///     .sheet(isPresented: $showFeedback) {
///         FeedbackFormView()
///     }
/// ```
struct FeedbackFormView: View {
    var initialCategory: FeedbackCategory?
    var onSubmit: ((FeedbackEntry) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var rating: Int = 3
    @State private var selectedCategory: FeedbackCategory = .general
    @State private var message: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var screenshotData: [Data] = []
    @State private var isSubmitting = false
    @State private var showSubmitSuccess = false
    @State private var showSubmitError = false
    @State private var submitErrorMessage = ""
    @State private var showReviewPrompt = false

    private let submitter: any FeedbackSubmitting

    init(
        initialCategory: FeedbackCategory? = nil,
        submitter: any FeedbackSubmitting = WebhookFeedbackSubmitter.default,
        onSubmit: ((FeedbackEntry) -> Void)? = nil
    ) {
        self.initialCategory = initialCategory
        self.submitter = submitter
        self.onSubmit = onSubmit
    }

    var body: some View {
        NavigationStack {
            Form {
                sentimentSection
                categorySection
                messageSection
                screenshotSection
                deviceInfoSection
            }
            .formStyle(.grouped)
            .navigationTitle("Send Feedback")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task { await submitFeedback() }
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .alert("Feedback Sent", isPresented: $showSubmitSuccess) {
                Button("OK") {
                    dismiss()
                    if showReviewPrompt {
                        requestAppStoreReview()
                    }
                }
            } message: {
                if showReviewPrompt {
                    Text("Thank you for your positive feedback! Would you consider leaving a review on the App Store?")
                } else {
                    Text("Thank you for your feedback. We'll review it shortly.")
                }
            }
            .alert("Submission Failed", isPresented: $showSubmitError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(submitErrorMessage)
            }
            .onAppear {
                if let initialCategory {
                    selectedCategory = initialCategory
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var sentimentSection: some View {
        Section {
            VStack(spacing: 8) {
                Text("How are you feeling?")
                    .font(.headline)
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { value in
                        SentimentButton(
                            value: value,
                            isSelected: rating == value
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                rating = value
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $selectedCategory) {
                ForEach(FeedbackCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.icon)
                        .tag(category)
                }
            }
            #if os(iOS)
            .pickerStyle(.navigationLink)
            #endif
        }
    }

    @ViewBuilder
    private var messageSection: some View {
        Section("Message") {
            TextEditor(text: $message)
                .frame(minHeight: 120)
                .overlay(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("Describe your feedback...")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    @ViewBuilder
    private var screenshotSection: some View {
        Section("Screenshots (optional)") {
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 3,
                matching: .screenshots
            ) {
                Label("Attach Screenshots", systemImage: "camera.on.rectangle")
            }
            .onChange(of: selectedPhotos) { _, newItems in
                Task { await loadPhotos(from: newItems) }
            }

            if !screenshotData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(screenshotData.indices, id: \.self) { index in
                            if let image = PlatformImage(data: screenshotData[index]) {
                                #if canImport(UIKit)
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(alignment: .topTrailing) {
                                        removeButton(at: index)
                                    }
                                #elseif canImport(AppKit)
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(alignment: .topTrailing) {
                                        removeButton(at: index)
                                    }
                                #endif
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var deviceInfoSection: some View {
        Section("Device Info") {
            let info = DeviceDiagnostics.collect()
            DisclosureGroup("Included with feedback") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.formattedString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }

    @ViewBuilder
    private func removeButton(at index: Int) -> some View {
        Button {
            screenshotData.remove(at: index)
            if index < selectedPhotos.count {
                selectedPhotos.remove(at: index)
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.white, .red)
        }
        .buttonStyle(.plain)
        .offset(x: 4, y: -4)
    }

    // MARK: - Actions

    private func loadPhotos(from items: [PhotosPickerItem]) async {
        var loaded: [Data] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Compress to JPEG to reduce size
                if let image = PlatformImage(data: data) {
                    #if canImport(UIKit)
                    if let jpeg = image.jpegData(compressionQuality: 0.7) {
                        loaded.append(jpeg)
                    }
                    #elseif canImport(AppKit)
                    if let tiff = image.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiff),
                       let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) {
                        loaded.append(jpeg)
                    }
                    #endif
                }
            }
        }
        screenshotData = loaded
    }

    private func submitFeedback() async {
        isSubmitting = true
        defer { isSubmitting = false }

        let entry = FeedbackEntry(
            category: selectedCategory,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            rating: rating,
            screenshots: screenshotData,
            deviceInfo: DeviceDiagnostics.collect(),
            appVersion: Bundle.main.appVersion,
            timestamp: Date()
        )

        do {
            try await submitter.submit(entry)
            onSubmit?(entry)
            showReviewPrompt = entry.suggestsAppStoreReview
            showSubmitSuccess = true
        } catch {
            submitErrorMessage = error.localizedDescription
            showSubmitError = true
        }
    }

    private func requestAppStoreReview() {
        #if os(iOS)
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        #elseif os(macOS)
        SKStoreReviewController.requestReview()
        #endif
    }
}

// MARK: - Sentiment Button

/// An emoji-based sentiment button for the 1-5 rating scale.
private struct SentimentButton: View {
    let value: Int
    let isSelected: Bool
    let action: () -> Void

    private var emoji: String {
        switch value {
        case 1: return "\u{1F621}"  // Angry face
        case 2: return "\u{1F641}"  // Slightly frowning face
        case 3: return "\u{1F610}"  // Neutral face
        case 4: return "\u{1F642}"  // Slightly smiling face
        case 5: return "\u{1F60D}"  // Heart eyes
        default: return "\u{1F610}"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 32))
                .scaleEffect(isSelected ? 1.3 : 1.0)
                .opacity(isSelected ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rating \(value) of 5")
    }
}

// MARK: - Bundle Extension

extension Bundle {
    /// App version string from Info.plist.
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// Build number from Info.plist.
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
```

## ScreenshotCapture.swift

```swift
import Foundation
import SwiftUI

/// Captures the current screen or window as image data.
///
/// Provides platform-appropriate screenshot capture and optional
/// annotation overlay for user markup before attaching to feedback.
///
/// Usage:
/// ```swift
/// let screenshotData = try await ScreenshotCapture.captureCurrentWindow()
/// ```
enum ScreenshotCapture {

    /// Captures the current key window as JPEG data.
    @MainActor
    static func captureCurrentWindow(compressionQuality: CGFloat = 0.8) throws -> Data {
        #if canImport(UIKit)
        return try captureUIWindow(compressionQuality: compressionQuality)
        #elseif canImport(AppKit)
        return try captureNSWindow(compressionQuality: compressionQuality)
        #endif
    }

    #if canImport(UIKit)
    @MainActor
    private static func captureUIWindow(compressionQuality: CGFloat) throws -> Data {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            throw ScreenshotError.noWindow
        }

        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }

        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw ScreenshotError.compressionFailed
        }

        return data
    }
    #endif

    #if canImport(AppKit)
    @MainActor
    private static func captureNSWindow(compressionQuality: CGFloat) throws -> Data {
        guard let window = NSApp.keyWindow else {
            throw ScreenshotError.noWindow
        }

        guard let contentView = window.contentView else {
            throw ScreenshotError.noWindow
        }

        guard let bitmapRep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds) else {
            throw ScreenshotError.captureFailed
        }

        contentView.cacheDisplay(in: contentView.bounds, to: bitmapRep)

        guard let data = bitmapRep.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        ) else {
            throw ScreenshotError.compressionFailed
        }

        return data
    }
    #endif
}

/// Errors that can occur during screenshot capture.
enum ScreenshotError: Error, LocalizedError {
    case noWindow
    case captureFailed
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .noWindow:
            return "No active window available for capture"
        case .captureFailed:
            return "Failed to capture window contents"
        case .compressionFailed:
            return "Failed to compress screenshot to JPEG"
        }
    }
}

/// A SwiftUI view that overlays simple annotation tools on a screenshot.
///
/// Allows users to draw rectangles or freeform highlights
/// before attaching the annotated image to feedback.
struct ScreenshotAnnotationView: View {
    let imageData: Data
    var onSave: (Data) -> Void
    var onCancel: () -> Void

    @State private var annotations: [AnnotationRect] = []
    @State private var currentDragStart: CGPoint?
    @State private var currentDragEnd: CGPoint?

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            annotationCanvas
        }
    }

    @ViewBuilder
    private var headerBar: some View {
        HStack {
            Button("Cancel") { onCancel() }
            Spacer()
            Text("Mark up screenshot")
                .font(.headline)
            Spacer()
            Button("Done") { saveAnnotated() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding()
    }

    @ViewBuilder
    private var annotationCanvas: some View {
        if let image = PlatformImage(data: imageData) {
            ZStack {
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                #elseif canImport(AppKit)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                #endif

                // Existing annotations
                ForEach(annotations) { annotation in
                    Rectangle()
                        .strokeBorder(Color.red, lineWidth: 2)
                        .frame(width: annotation.size.width, height: annotation.size.height)
                        .position(annotation.center)
                }

                // Current drag annotation
                if let start = currentDragStart, let end = currentDragEnd {
                    let rect = dragRect(from: start, to: end)
                    Rectangle()
                        .strokeBorder(Color.red.opacity(0.8), lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        currentDragStart = currentDragStart ?? value.startLocation
                        currentDragEnd = value.location
                    }
                    .onEnded { value in
                        if let start = currentDragStart {
                            let rect = dragRect(from: start, to: value.location)
                            annotations.append(AnnotationRect(
                                center: CGPoint(x: rect.midX, y: rect.midY),
                                size: rect.size
                            ))
                        }
                        currentDragStart = nil
                        currentDragEnd = nil
                    }
            )
        }
    }

    private func dragRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private func saveAnnotated() {
        // For simplicity, save the original image data.
        // A production implementation would render annotations onto the image.
        onSave(imageData)
    }
}

/// A rectangle annotation on a screenshot.
private struct AnnotationRect: Identifiable {
    let id = UUID()
    let center: CGPoint
    let size: CGSize
}
```

## FeedbackSubmitter.swift

```swift
import Foundation
#if canImport(MessageUI)
import MessageUI
#endif

/// Protocol for feedback delivery implementations.
///
/// Conform to this protocol to deliver feedback via email, webhook,
/// or any custom backend.
protocol FeedbackSubmitting: Sendable {
    func submit(_ entry: FeedbackEntry) async throws
}

// MARK: - Webhook Submitter

/// Delivers feedback as a JSON POST request to a webhook URL.
///
/// Screenshots are base64-encoded in the JSON payload.
/// Suitable for services like Slack webhooks, custom APIs,
/// or serverless functions.
///
/// Usage:
/// ```swift
/// let submitter = WebhookFeedbackSubmitter(
///     url: URL(string: "https://api.example.com/feedback")!
/// )
/// try await submitter.submit(entry)
/// ```
struct WebhookFeedbackSubmitter: FeedbackSubmitting {
    let url: URL
    let session: URLSession
    let additionalHeaders: [String: String]

    /// Default submitter — configure this URL for your backend.
    static let `default` = WebhookFeedbackSubmitter(
        url: URL(string: "https://your-api.example.com/feedback")!
    )

    init(
        url: URL,
        session: URLSession = .shared,
        additionalHeaders: [String: String] = [:]
    ) {
        self.url = url
        self.session = session
        self.additionalHeaders = additionalHeaders
    }

    func submit(_ entry: FeedbackEntry) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode entry with base64 screenshots
        let payload = WebhookPayload(
            id: entry.id.uuidString,
            category: entry.category.rawValue,
            message: entry.message,
            rating: entry.rating,
            screenshots: entry.screenshots.map { $0.base64EncodedString() },
            deviceInfo: entry.deviceInfo,
            appVersion: entry.appVersion,
            timestamp: entry.timestamp
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(payload)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FeedbackSubmissionError.serverError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }
    }
}

/// JSON payload for webhook delivery.
private struct WebhookPayload: Codable {
    let id: String
    let category: String
    let message: String
    let rating: Int
    let screenshots: [String]  // Base64 encoded
    let deviceInfo: DeviceInfo
    let appVersion: String
    let timestamp: Date
}

// MARK: - Email Submitter (iOS only)

#if canImport(UIKit)
import UIKit

/// Delivers feedback via the system email composer (MFMailComposeViewController).
///
/// Falls back to `mailto:` URL if the device has no mail account configured.
/// Screenshots are added as JPEG attachments.
///
/// Usage:
/// ```swift
/// let submitter = EmailFeedbackSubmitter(
///     recipient: "support@yourapp.com",
///     subject: "Feedback"
/// )
/// try await submitter.submit(entry)
/// ```
@MainActor
final class EmailFeedbackSubmitter: NSObject, FeedbackSubmitting, MFMailComposeViewControllerDelegate {
    let recipient: String
    let subject: String
    private var continuation: CheckedContinuation<Void, Error>?

    nonisolated init(recipient: String, subject: String = "App Feedback") {
        self.recipient = recipient
        self.subject = subject
    }

    func submit(_ entry: FeedbackEntry) async throws {
        guard MFMailComposeViewController.canSendMail() else {
            // Fall back to mailto: URL
            try openMailtoFallback(entry: entry)
            return
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let composer = MFMailComposeViewController()
            composer.mailComposeDelegate = self
            composer.setToRecipients([recipient])
            composer.setSubject("\(subject) — \(entry.category.displayName)")

            let body = """
            Category: \(entry.category.displayName)
            Rating: \(entry.rating)/5

            \(entry.message)

            ---
            Device Info:
            \(entry.deviceInfo.formattedString)
            """
            composer.setMessageBody(body, isHTML: false)

            // Attach screenshots
            for (index, data) in entry.screenshots.enumerated() {
                composer.addAttachmentData(
                    data,
                    mimeType: "image/jpeg",
                    fileName: "screenshot_\(index + 1).jpg"
                )
            }

            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                continuation.resume(throwing: FeedbackSubmissionError.noViewController)
                return
            }

            rootVC.present(composer, animated: true)
        }
    }

    nonisolated func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        Task { @MainActor in
            controller.dismiss(animated: true)

            if let error {
                continuation?.resume(throwing: error)
            } else if result == .cancelled {
                continuation?.resume(throwing: FeedbackSubmissionError.cancelled)
            } else {
                continuation?.resume()
            }
            continuation = nil
        }
    }

    private func openMailtoFallback(entry: FeedbackEntry) throws {
        let subject = "\(subject) — \(entry.category.displayName)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = """
        Category: \(entry.category.displayName)
        Rating: \(entry.rating)/5

        \(entry.message)

        ---
        Device Info:
        \(entry.deviceInfo.formattedString)
        """
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlString = "mailto:\(recipient)?subject=\(subject)&body=\(body)"
        guard let url = URL(string: urlString) else {
            throw FeedbackSubmissionError.mailNotAvailable
        }

        UIApplication.shared.open(url)
    }
}
#endif

// MARK: - macOS Email Submitter

#if canImport(AppKit)
import AppKit

/// Delivers feedback via macOS sharing services or mailto: URL.
///
/// Uses NSSharingService for email composition when available.
@MainActor
final class EmailFeedbackSubmitter: FeedbackSubmitting {
    let recipient: String
    let subject: String

    nonisolated init(recipient: String, subject: String = "App Feedback") {
        self.recipient = recipient
        self.subject = subject
    }

    func submit(_ entry: FeedbackEntry) async throws {
        let subject = "\(subject) — \(entry.category.displayName)"
        let body = """
        Category: \(entry.category.displayName)
        Rating: \(entry.rating)/5

        \(entry.message)

        ---
        Device Info:
        \(entry.deviceInfo.formattedString)
        """

        guard let service = NSSharingService(named: .composeEmail) else {
            // Fall back to mailto:
            try openMailtoFallback(subject: subject, body: body)
            return
        }

        service.recipients = [recipient]
        service.subject = subject

        var items: [Any] = [body]

        // Add screenshot attachments as temp files
        for (index, data) in entry.screenshots.enumerated() {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("feedback_screenshot_\(index + 1).jpg")
            try data.write(to: tempURL)
            items.append(tempURL)
        }

        if service.canPerform(withItems: items) {
            service.perform(withItems: items)
        } else {
            try openMailtoFallback(subject: subject, body: body)
        }
    }

    private func openMailtoFallback(subject: String, body: String) throws {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(recipient)?subject=\(encodedSubject)&body=\(encodedBody)"

        guard let url = URL(string: urlString) else {
            throw FeedbackSubmissionError.mailNotAvailable
        }

        NSWorkspace.shared.open(url)
    }
}
#endif

// MARK: - Errors

/// Errors that can occur during feedback submission.
enum FeedbackSubmissionError: Error, LocalizedError {
    case serverError(statusCode: Int)
    case mailNotAvailable
    case noViewController
    case cancelled
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .serverError(let code):
            return "Server returned error status \(code)"
        case .mailNotAvailable:
            return "Email is not configured on this device"
        case .noViewController:
            return "Unable to present email composer"
        case .cancelled:
            return "Feedback submission was cancelled"
        case .encodingFailed:
            return "Failed to encode feedback data"
        }
    }
}
```

## DeviceDiagnostics.swift

```swift
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Collects device and app diagnostic information to attach to feedback.
///
/// Gathers non-sensitive system information that helps developers
/// reproduce and debug reported issues.
///
/// Usage:
/// ```swift
/// let info = DeviceDiagnostics.collect()
/// print(info.formattedString)
/// ```
enum DeviceDiagnostics {

    /// Collects current device and app diagnostics.
    static func collect() -> DeviceInfo {
        DeviceInfo(
            deviceModel: deviceModel,
            osVersion: osVersion,
            appVersion: appVersion,
            buildNumber: buildNumber,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier,
            diskSpaceAvailable: availableDiskSpace,
            memoryUsage: memoryInfo,
            batteryLevel: batteryInfo
        )
    }

    // MARK: - Device Model

    private static var deviceModel: String {
        #if canImport(UIKit)
        return UIDevice.current.model + " (" + machineIdentifier + ")"
        #elseif canImport(AppKit)
        return "Mac (" + machineIdentifier + ")"
        #endif
    }

    private static var machineIdentifier: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    // MARK: - OS Version

    private static var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        #if os(iOS)
        let platform = "iOS"
        #elseif os(macOS)
        let platform = "macOS"
        #elseif os(watchOS)
        let platform = "watchOS"
        #elseif os(tvOS)
        let platform = "tvOS"
        #elseif os(visionOS)
        let platform = "visionOS"
        #else
        let platform = "Unknown"
        #endif
        return "\(platform) \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    // MARK: - App Version

    private static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    // MARK: - Disk Space

    private static var availableDiskSpace: String {
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ),
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return "Unknown"
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: freeSpace)
    }

    // MARK: - Memory

    private static var memoryInfo: String {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .memory

        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedBytes = Int64(taskInfo.phys_footprint)
            let usedFormatted = formatter.string(fromByteCount: usedBytes)
            let totalFormatted = formatter.string(fromByteCount: Int64(physicalMemory))
            return "\(usedFormatted) used / \(totalFormatted) total"
        }

        return formatter.string(fromByteCount: Int64(physicalMemory)) + " total"
    }

    // MARK: - Battery

    private static var batteryInfo: String {
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState

        if level < 0 {
            return "Unknown"
        }

        let percentage = Int(level * 100)
        let stateString: String
        switch state {
        case .charging: stateString = "Charging"
        case .full: stateString = "Full"
        case .unplugged: stateString = "Unplugged"
        default: stateString = ""
        }

        return "\(percentage)% \(stateString)".trimmingCharacters(in: .whitespaces)
        #elseif os(macOS)
        // macOS battery info requires IOKit — return N/A for simplicity
        return "N/A (macOS)"
        #else
        return "N/A"
        #endif
    }
}
```
