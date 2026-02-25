# Announcement Banner Code Templates

Production-ready Swift templates for an in-app announcement banner system. All code targets iOS 16+ / macOS 13+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## Announcement.swift

```swift
import Foundation

/// Represents an in-app announcement to display as a banner.
///
/// Announcements are prioritized, scheduled, and style-aware.
/// They can trigger deep links, open URLs, or simply be dismissed.
struct Announcement: Codable, Sendable, Identifiable {
    let id: String
    let title: String
    let message: String
    let style: Style
    let action: Action
    let priority: Int
    let startDate: Date?
    let endDate: Date?
    let isDismissible: Bool
    let targetAudience: Audience

    init(
        id: String,
        title: String,
        message: String,
        style: Style = .info,
        action: Action = .dismiss,
        priority: Int = 0,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isDismissible: Bool = true,
        targetAudience: Audience = .all
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.style = style
        self.action = action
        self.priority = priority
        self.startDate = startDate
        self.endDate = endDate
        self.isDismissible = isDismissible
        self.targetAudience = targetAudience
    }

    // MARK: - Style

    /// Visual style that determines banner colors and icon.
    enum Style: String, Codable, Sendable {
        case info
        case warning
        case success
        case promotion
    }

    // MARK: - Action

    /// Action triggered when the user taps the banner's action button.
    enum Action: Codable, Sendable {
        case deepLink(String)
        case url(URL)
        case dismiss

        // Custom Codable to handle associated values
        enum CodingKeys: String, CodingKey {
            case type, value
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "deepLink":
                let value = try container.decode(String.self, forKey: .value)
                self = .deepLink(value)
            case "url":
                let value = try container.decode(URL.self, forKey: .value)
                self = .url(value)
            default:
                self = .dismiss
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .deepLink(let destination):
                try container.encode("deepLink", forKey: .type)
                try container.encode(destination, forKey: .value)
            case .url(let url):
                try container.encode("url", forKey: .type)
                try container.encode(url, forKey: .value)
            case .dismiss:
                try container.encode("dismiss", forKey: .type)
            }
        }
    }

    // MARK: - Audience

    /// Target audience for the announcement.
    enum Audience: String, Codable, Sendable {
        case all
        case freeUsers
        case proUsers
        case newUsers
    }
}

/// Response wrapper for remote announcement JSON.
struct AnnouncementResponse: Codable, Sendable {
    let announcements: [Announcement]
}
```

## AnnouncementManager.swift

```swift
import Foundation
import SwiftUI

/// Manages announcement loading, filtering, prioritization, and dismissal tracking.
///
/// Exposes the single highest-priority active announcement to the UI.
/// Dismissed announcements are persisted across app launches.
///
/// Usage:
/// ```swift
/// let manager = AnnouncementManager(provider: RemoteAnnouncementProvider(url: configURL))
/// await manager.loadAnnouncements()
/// if let banner = manager.activeAnnouncement { ... }
/// ```
@Observable
final class AnnouncementManager {
    /// The highest-priority announcement that should be displayed.
    private(set) var activeAnnouncement: Announcement?

    /// All currently loaded announcements (unfiltered).
    private(set) var allAnnouncements: [Announcement] = []

    private let provider: any AnnouncementProviding
    private let dismissalStore: any DismissalStoring
    private let scheduler: AnnouncementScheduler
    private let audienceResolver: AudienceResolver

    init(
        provider: any AnnouncementProviding,
        dismissalStore: any DismissalStoring = UserDefaultsDismissalStore(),
        scheduler: AnnouncementScheduler = AnnouncementScheduler(),
        audienceResolver: AudienceResolver = AudienceResolver()
    ) {
        self.provider = provider
        self.dismissalStore = dismissalStore
        self.scheduler = scheduler
        self.audienceResolver = audienceResolver
    }

    /// Load announcements from the provider and update the active announcement.
    func loadAnnouncements() async {
        do {
            let announcements = try await provider.fetchAnnouncements()
            allAnnouncements = announcements
            updateActiveAnnouncement()
        } catch {
            // Silently fail — banner is non-critical UI
            // Optionally log: print("Failed to load announcements: \(error)")
        }
    }

    /// Dismiss an announcement so it won't appear again.
    func dismiss(_ announcement: Announcement) {
        dismissalStore.markDismissed(id: announcement.id)
        updateActiveAnnouncement()
    }

    /// Force refresh announcements from the provider.
    func refresh() async {
        await loadAnnouncements()
    }

    /// Check if an announcement has been dismissed.
    func isDismissed(_ announcement: Announcement) -> Bool {
        dismissalStore.isDismissed(id: announcement.id)
    }

    // MARK: - Private

    private func updateActiveAnnouncement() {
        let now = Date()

        let eligible = allAnnouncements
            .filter { !dismissalStore.isDismissed(id: $0.id) }
            .filter { scheduler.isActive($0, at: now) }
            .filter { audienceResolver.matches($0.targetAudience) }
            .sorted { $0.priority > $1.priority }

        activeAnnouncement = eligible.first
    }
}

// MARK: - Dismissal Store Protocol

/// Protocol for persisting dismissed announcement IDs.
protocol DismissalStoring: Sendable {
    func isDismissed(id: String) -> Bool
    func markDismissed(id: String)
    func clearAll()
}

/// UserDefaults-backed dismissal store.
final class UserDefaultsDismissalStore: DismissalStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "dismissed_announcement_ids"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isDismissed(id: String) -> Bool {
        dismissedIDs.contains(id)
    }

    func markDismissed(id: String) {
        var ids = dismissedIDs
        ids.insert(id)
        defaults.set(Array(ids), forKey: key)
    }

    func clearAll() {
        defaults.removeObject(forKey: key)
    }

    private var dismissedIDs: Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }
}

/// In-memory dismissal store for testing and previews.
final class InMemoryDismissalStore: DismissalStoring, @unchecked Sendable {
    private var dismissedIDs: Set<String> = []

    func isDismissed(id: String) -> Bool {
        dismissedIDs.contains(id)
    }

    func markDismissed(id: String) {
        dismissedIDs.insert(id)
    }

    func clearAll() {
        dismissedIDs.removeAll()
    }
}

// MARK: - Audience Resolver

/// Resolves whether the current user matches a target audience.
///
/// Customize this class to check actual user state (subscription status, install date, etc.).
final class AudienceResolver: Sendable {
    func matches(_ audience: Announcement.Audience) -> Bool {
        switch audience {
        case .all:
            return true
        case .freeUsers:
            // TODO: Replace with actual subscription check
            return true
        case .proUsers:
            // TODO: Replace with actual subscription check
            return false
        case .newUsers:
            // TODO: Replace with actual install date check
            return false
        }
    }
}

// MARK: - Environment Key

private struct AnnouncementManagerKey: EnvironmentKey {
    static let defaultValue: AnnouncementManager = AnnouncementManager(
        provider: LocalAnnouncementProvider(announcements: [])
    )
}

extension EnvironmentValues {
    var announcementManager: AnnouncementManager {
        get { self[AnnouncementManagerKey.self] }
        set { self[AnnouncementManagerKey.self] = newValue }
    }
}
```

## AnnouncementProvider.swift

```swift
import Foundation

/// Protocol for fetching announcements from any source.
protocol AnnouncementProviding: Sendable {
    func fetchAnnouncements() async throws -> [Announcement]
}

// MARK: - Local Provider

/// Provides hardcoded announcements defined in code.
///
/// Useful for announcements that ship with app updates
/// or as fallbacks when remote config is unavailable.
///
/// Usage:
/// ```swift
/// let provider = LocalAnnouncementProvider(announcements: [
///     Announcement(id: "welcome", title: "Welcome!", message: "Thanks for downloading.", style: .info)
/// ])
/// ```
struct LocalAnnouncementProvider: AnnouncementProviding {
    let announcements: [Announcement]

    func fetchAnnouncements() async throws -> [Announcement] {
        announcements
    }
}

// MARK: - Remote Provider

/// Fetches announcements from a remote JSON endpoint with caching.
///
/// Expected JSON format:
/// ```json
/// {
///   "announcements": [
///     {
///       "id": "maintenance-2024",
///       "title": "Scheduled Maintenance",
///       "message": "We'll be down Saturday 2-4 AM EST.",
///       "style": "warning",
///       "action": { "type": "url", "value": "https://status.example.com" },
///       "priority": 100,
///       "startDate": "2024-06-14T06:00:00Z",
///       "endDate": "2024-06-15T08:00:00Z",
///       "isDismissible": false,
///       "targetAudience": "all"
///     }
///   ]
/// }
/// ```
actor RemoteAnnouncementProvider: AnnouncementProviding {
    private let url: URL
    private let session: URLSession
    private let cacheDuration: TimeInterval
    private var cachedAnnouncements: [Announcement]?
    private var lastFetchDate: Date?

    init(
        url: URL,
        session: URLSession = .shared,
        cacheDuration: TimeInterval = 3600  // 1 hour default
    ) {
        self.url = url
        self.session = session
        self.cacheDuration = cacheDuration
    }

    func fetchAnnouncements() async throws -> [Announcement] {
        // Return cached data if still valid
        if let cached = cachedAnnouncements,
           let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            return cached
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AnnouncementError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let announcementResponse = try decoder.decode(AnnouncementResponse.self, from: data)

        cachedAnnouncements = announcementResponse.announcements
        lastFetchDate = Date()

        return announcementResponse.announcements
    }

    /// Force clear the cache so the next fetch hits the network.
    func invalidateCache() {
        cachedAnnouncements = nil
        lastFetchDate = nil
    }
}

// MARK: - Combined Provider

/// Combines multiple providers, merging announcements from all sources.
///
/// Useful for combining remote announcements with local fallbacks.
///
/// Usage:
/// ```swift
/// let provider = CombinedAnnouncementProvider(providers: [
///     RemoteAnnouncementProvider(url: configURL),
///     LocalAnnouncementProvider(announcements: localAnnouncements)
/// ])
/// ```
struct CombinedAnnouncementProvider: AnnouncementProviding {
    let providers: [any AnnouncementProviding]

    func fetchAnnouncements() async throws -> [Announcement] {
        var allAnnouncements: [Announcement] = []

        for provider in providers {
            do {
                let announcements = try await provider.fetchAnnouncements()
                allAnnouncements.append(contentsOf: announcements)
            } catch {
                // Continue with other providers if one fails
                continue
            }
        }

        // Deduplicate by ID, keeping the first occurrence (remote takes priority)
        var seen = Set<String>()
        return allAnnouncements.filter { announcement in
            guard !seen.contains(announcement.id) else { return false }
            seen.insert(announcement.id)
            return true
        }
    }
}

// MARK: - Mock Provider (Testing)

/// Mock provider for testing and SwiftUI previews.
struct MockAnnouncementProvider: AnnouncementProviding {
    let announcements: [Announcement]
    var shouldFail: Bool = false

    func fetchAnnouncements() async throws -> [Announcement] {
        if shouldFail {
            throw AnnouncementError.fetchFailed
        }
        return announcements
    }
}

// MARK: - Errors

enum AnnouncementError: Error, LocalizedError {
    case fetchFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch announcements from server."
        case .decodingFailed:
            return "Failed to decode announcement data."
        }
    }
}
```

## AnnouncementBannerView.swift

```swift
import SwiftUI

/// A style-aware banner view for displaying announcements.
///
/// Renders with appropriate colors and icon based on the announcement style:
/// - Info: blue with info.circle icon
/// - Warning: orange with exclamationmark.triangle icon
/// - Success: green with checkmark.circle icon
/// - Promotion: purple with star.fill icon
///
/// Usage:
/// ```swift
/// AnnouncementBannerView(
///     announcement: announcement,
///     onAction: { handleAction($0) },
///     onDismiss: { manager.dismiss(announcement) }
/// )
/// ```
struct AnnouncementBannerView: View {
    let announcement: Announcement
    let onAction: (Announcement.Action) -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Style icon
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(styleColor)
                .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(announcement.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(announcement.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                // Action button (if not dismiss-only)
                if case .dismiss = announcement.action {
                    // No action button for dismiss-only
                } else {
                    Button {
                        onAction(announcement.action)
                    } label: {
                        Text(actionButtonTitle)
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(styleColor)
                    .controlSize(.small)
                    .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)

            // Dismiss button
            if announcement.isDismissible {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss announcement")
            }
        }
        .padding(16)
        .background(bannerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    // MARK: - Style Properties

    private var iconName: String {
        switch announcement.style {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .promotion: return "star.fill"
        }
    }

    private var styleColor: Color {
        switch announcement.style {
        case .info: return .blue
        case .warning: return .orange
        case .success: return .green
        case .promotion: return .purple
        }
    }

    private var actionButtonTitle: String {
        switch announcement.action {
        case .deepLink: return "View"
        case .url: return "Learn More"
        case .dismiss: return ""
        }
    }

    private var bannerBackground: some ShapeStyle {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }
}

// MARK: - Previews

#Preview("Info Banner") {
    AnnouncementBannerView(
        announcement: Announcement(
            id: "preview-info",
            title: "App Update Available",
            message: "Version 2.5 includes performance improvements and bug fixes.",
            style: .info,
            action: .url(URL(string: "https://example.com")!),
            priority: 5
        ),
        onAction: { _ in },
        onDismiss: { }
    )
    .padding()
}

#Preview("Warning Banner") {
    AnnouncementBannerView(
        announcement: Announcement(
            id: "preview-warning",
            title: "Scheduled Maintenance",
            message: "Service will be unavailable Saturday 2-4 AM EST.",
            style: .warning,
            action: .dismiss,
            priority: 10,
            isDismissible: false
        ),
        onAction: { _ in },
        onDismiss: { }
    )
    .padding()
}

#Preview("Promotion Banner") {
    AnnouncementBannerView(
        announcement: Announcement(
            id: "preview-promo",
            title: "Summer Sale - 40% Off!",
            message: "Upgrade to Pro at our lowest price ever. Limited time offer.",
            style: .promotion,
            action: .deepLink("app://subscription/upgrade"),
            priority: 8
        ),
        onAction: { _ in },
        onDismiss: { }
    )
    .padding()
}
```

## AnnouncementBannerModifier.swift

```swift
import SwiftUI

/// Banner position relative to the screen.
enum AnnouncementBannerPosition {
    case top
    case bottom
    case floating
}

/// ViewModifier that overlays an announcement banner on the view.
///
/// Automatically loads announcements on appear, handles animations,
/// and routes actions through the provided handler.
///
/// Usage:
/// ```swift
/// ContentView()
///     .announcementBanner(position: .top) { action in
///         switch action {
///         case .deepLink(let path): router.navigate(to: path)
///         case .url(let url): openURL(url)
///         case .dismiss: break
///         }
///     }
/// ```
struct AnnouncementBannerModifier: ViewModifier {
    let position: AnnouncementBannerPosition
    let actionHandler: ((Announcement.Action) -> Void)?

    @Environment(\.announcementManager) private var manager
    @Environment(\.openURL) private var openURL
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: overlayAlignment) {
                if let announcement = manager.activeAnnouncement, isVisible {
                    bannerView(for: announcement)
                        .transition(bannerTransition)
                        .zIndex(1000)
                }
            }
            .task {
                await manager.loadAnnouncements()
                withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                    isVisible = manager.activeAnnouncement != nil
                }
            }
            .onChange(of: manager.activeAnnouncement?.id) { _, newValue in
                withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                    isVisible = newValue != nil
                }
            }
    }

    // MARK: - Banner View

    @ViewBuilder
    private func bannerView(for announcement: Announcement) -> some View {
        AnnouncementBannerView(
            announcement: announcement,
            onAction: { action in
                handleAction(action)
                if announcement.isDismissible {
                    dismissWithAnimation(announcement)
                }
            },
            onDismiss: {
                dismissWithAnimation(announcement)
            }
        )
        .padding(.top, position == .top ? 8 : 0)
        .padding(.bottom, position == .bottom ? 8 : 0)
        .accessibilityAddTraits(.isStaticText)
        .onAppear {
            #if canImport(UIKit)
            UIAccessibility.post(
                notification: .announcement,
                argument: "\(announcement.title). \(announcement.message)"
            )
            #elseif canImport(AppKit)
            NSAccessibility.post(
                element: NSApp as Any,
                notification: .announcementRequested
            )
            #endif
        }
    }

    // MARK: - Action Handling

    private func handleAction(_ action: Announcement.Action) {
        if let handler = actionHandler {
            handler(action)
            return
        }

        // Default action handling
        switch action {
        case .deepLink(let destination):
            if let url = URL(string: destination) {
                openURL(url)
            }
        case .url(let url):
            openURL(url)
        case .dismiss:
            break
        }
    }

    // MARK: - Animation Helpers

    private func dismissWithAnimation(_ announcement: Announcement) {
        withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
            isVisible = false
        }
        // Delay the actual dismissal to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            manager.dismiss(announcement)
        }
    }

    private var overlayAlignment: Alignment {
        switch position {
        case .top: return .top
        case .bottom: return .bottom
        case .floating: return .center
        }
    }

    private var bannerTransition: AnyTransition {
        switch position {
        case .top:
            return .asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            )
        case .bottom:
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        case .floating:
            return .asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            )
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds an announcement banner overlay to the view.
    ///
    /// ```swift
    /// NavigationStack { ... }
    ///     .announcementBanner()
    /// ```
    func announcementBanner(
        position: AnnouncementBannerPosition = .top,
        actionHandler: ((Announcement.Action) -> Void)? = nil
    ) -> some View {
        modifier(AnnouncementBannerModifier(
            position: position,
            actionHandler: actionHandler
        ))
    }
}
```

## AnnouncementScheduler.swift

```swift
import Foundation

/// Filters announcements based on date ranges and timezone-aware scheduling.
///
/// Handles start/end date filtering with proper UTC handling.
/// Announcements without dates are considered always active.
///
/// Usage:
/// ```swift
/// let scheduler = AnnouncementScheduler()
/// let isActive = scheduler.isActive(announcement, at: Date())
/// ```
struct AnnouncementScheduler: Sendable {

    /// Check if an announcement is currently active based on its date range.
    ///
    /// - Parameters:
    ///   - announcement: The announcement to check.
    ///   - date: The reference date (defaults to now).
    /// - Returns: `true` if the announcement is within its active window.
    func isActive(_ announcement: Announcement, at date: Date = Date()) -> Bool {
        // If no dates set, always active
        if announcement.startDate == nil && announcement.endDate == nil {
            return true
        }

        // Check start date
        if let startDate = announcement.startDate, date < startDate {
            return false
        }

        // Check end date
        if let endDate = announcement.endDate, date > endDate {
            return false
        }

        return true
    }

    /// Filter a list of announcements to only those currently active.
    func activeAnnouncements(
        from announcements: [Announcement],
        at date: Date = Date()
    ) -> [Announcement] {
        announcements.filter { isActive($0, at: date) }
    }

    /// Get the next announcement that will become active.
    ///
    /// Useful for scheduling a refresh when the next announcement starts.
    func nextActivation(
        from announcements: [Announcement],
        after date: Date = Date()
    ) -> (announcement: Announcement, activationDate: Date)? {
        announcements
            .filter { announcement in
                guard let startDate = announcement.startDate else { return false }
                return startDate > date
            }
            .sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
            .first
            .flatMap { announcement in
                guard let startDate = announcement.startDate else { return nil }
                return (announcement, startDate)
            }
    }

    /// Get the next expiration date among active announcements.
    ///
    /// Useful for scheduling a refresh when an announcement expires.
    func nextExpiration(
        from announcements: [Announcement],
        after date: Date = Date()
    ) -> Date? {
        announcements
            .filter { isActive($0, at: date) }
            .compactMap { $0.endDate }
            .filter { $0 > date }
            .sorted()
            .first
    }
}
```
