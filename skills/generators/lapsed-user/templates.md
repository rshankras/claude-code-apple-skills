# Lapsed User Code Templates

Production-ready Swift templates for lapsed user detection and re-engagement infrastructure. All code targets iOS 17+ / macOS 14+ with @Observable and modern Swift concurrency.

## InactivityTracker.swift

```swift
import Foundation

/// Tracks when the user was last active in the app.
///
/// Persists the last active date to UserDefaults and calculates
/// the number of days since the user last opened the app.
///
/// Usage:
/// ```swift
/// let tracker = InactivityTracker()
/// tracker.recordActivity() // Call on each app foreground
/// print(tracker.daysSinceLastActive) // e.g., 14
/// ```
@Observable
final class InactivityTracker: Sendable {
    private let store: UserDefaults
    private let currentDate: @Sendable () -> Date
    private let lastActiveDateKey = "com.app.lapsedUser.lastActiveDate"
    private let previousLastActiveDateKey = "com.app.lapsedUser.previousLastActiveDate"

    /// The date the user was last active before the current session.
    var lastActiveDate: Date? {
        store.object(forKey: previousLastActiveDateKey) as? Date
            ?? store.object(forKey: lastActiveDateKey) as? Date
    }

    /// Number of calendar days since the user was last active.
    var daysSinceLastActive: Int {
        guard let lastActive = lastActiveDate else { return 0 }
        return Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: lastActive),
            to: Calendar.current.startOfDay(for: currentDate())
        ).day ?? 0
    }

    init(
        store: UserDefaults = .standard,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.store = store
        self.currentDate = currentDate
    }

    /// Record that the user is currently active.
    ///
    /// Call this when the app transitions to the foreground via `scenePhase`.
    /// Preserves the previous last-active date so we can calculate the gap.
    func recordActivity() {
        // Save the old last-active date before overwriting
        if let existing = store.object(forKey: lastActiveDateKey) as? Date {
            store.set(existing, forKey: previousLastActiveDateKey)
        }
        store.set(currentDate(), forKey: lastActiveDateKey)
    }

    /// Clear all tracking data (e.g., on logout).
    func reset() {
        store.removeObject(forKey: lastActiveDateKey)
        store.removeObject(forKey: previousLastActiveDateKey)
    }

    // MARK: - Testing Support

    /// Override the last active date for testing purposes.
    func override(lastActiveDate date: Date) {
        store.set(date, forKey: previousLastActiveDateKey)
    }
}
```

## LapsedUserDetector.swift

```swift
import Foundation

/// Categories of user inactivity based on days since last active.
enum LapsedUserCategory: String, Sendable, Identifiable, CaseIterable {
    /// User has been active recently (within threshold). No action needed.
    case active

    /// User has been inactive for a short period (e.g., 7-13 days).
    /// Show a gentle "Welcome back" with highlights.
    case recentlyInactive

    /// User has been inactive for a moderate period (e.g., 14-29 days).
    /// Show what they missed and re-engagement prompts.
    case moderatelyLapsed

    /// User has been inactive for an extended period (e.g., 30+ days).
    /// Show win-back offers and a fresh-start option.
    case longTermLapsed

    var id: String { rawValue }

    /// Whether this category represents a lapsed user who should see a return experience.
    var isLapsed: Bool {
        switch self {
        case .active: return false
        case .recentlyInactive, .moderatelyLapsed, .longTermLapsed: return true
        }
    }
}

/// Evaluates a user's inactivity period against configurable thresholds.
///
/// Usage:
/// ```swift
/// let detector = LapsedUserDetector(tracker: tracker)
/// let category = detector.evaluate()
/// if category.isLapsed {
///     // Show return experience
/// }
/// ```
struct LapsedUserDetector: Sendable {
    private let tracker: InactivityTracker
    private let recentThreshold: Int
    private let moderateThreshold: Int
    private let longTermThreshold: Int

    /// - Parameters:
    ///   - tracker: The inactivity tracker providing days-since-last-active.
    ///   - recentThreshold: Days of inactivity to classify as recently inactive. Default: 7.
    ///   - moderateThreshold: Days of inactivity to classify as moderately lapsed. Default: 14.
    ///   - longTermThreshold: Days of inactivity to classify as long-term lapsed. Default: 30.
    init(
        tracker: InactivityTracker,
        recentThreshold: Int = 7,
        moderateThreshold: Int = 14,
        longTermThreshold: Int = 30
    ) {
        self.tracker = tracker
        self.recentThreshold = recentThreshold
        self.moderateThreshold = moderateThreshold
        self.longTermThreshold = longTermThreshold
    }

    /// Evaluate the user's inactivity and return their lapse category.
    func evaluate() -> LapsedUserCategory {
        let days = tracker.daysSinceLastActive

        if days >= longTermThreshold {
            return .longTermLapsed
        } else if days >= moderateThreshold {
            return .moderatelyLapsed
        } else if days >= recentThreshold {
            return .recentlyInactive
        } else {
            return .active
        }
    }
}
```

## ReturnExperienceView.swift

```swift
import SwiftUI

/// Data model for a personalized return experience.
struct ReturnExperience: Identifiable, Sendable {
    let id = UUID()
    let headline: String
    let subtitle: String
    let highlights: [ReturnHighlight]
    let ctaTitle: String
    let category: LapsedUserCategory
}

/// A single highlight item showing what the user missed.
struct ReturnHighlight: Identifiable, Sendable {
    let id = UUID()
    let icon: String       // SF Symbol name
    let title: String
    let description: String
}

/// Personalized return screen shown to lapsed users.
///
/// Displays a "Welcome back!" message, highlights what changed
/// since their last visit, and provides a CTA to re-engage.
///
/// Usage:
/// ```swift
/// .sheet(item: $returnExperience) { experience in
///     ReturnExperienceView(experience: experience)
/// }
/// ```
struct ReturnExperienceView: View {
    let experience: ReturnExperience
    var onDismiss: (() -> Void)?
    var onDontShowAgain: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    highlightsSection
                    ctaSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss?()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text(experience.headline)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(experience.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var highlightsSection: some View {
        if !experience.highlights.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("While you were away...")
                    .font(.headline)

                ForEach(experience.highlights) { highlight in
                    HighlightRow(highlight: highlight)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                onDismiss?()
                dismiss()
            } label: {
                Text(experience.ctaTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if onDontShowAgain != nil {
                Button("Don't show this again") {
                    onDontShowAgain?()
                    dismiss()
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }
}

/// A single row displaying a return highlight.
private struct HighlightRow: View {
    let highlight: ReturnHighlight

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: highlight.icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(highlight.title)
                    .font(.subheadline.bold())

                Text(highlight.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

## WinBackOfferView.swift

```swift
import SwiftUI

/// Discount type for win-back offers.
enum WinBackDiscount: Sendable {
    case percentage(Int)              // e.g., 30% off
    case fixedAmount(Decimal)         // e.g., $3 off
    case freeTrialDays(Int)           // e.g., 7-day free trial

    var displayText: String {
        switch self {
        case .percentage(let pct):
            return "\(pct)% off"
        case .fixedAmount(let amount):
            return "$\(amount) off"
        case .freeTrialDays(let days):
            return "\(days)-day free trial"
        }
    }
}

/// Duration for time-limited offers.
enum OfferDuration: Sendable {
    case days(Int)
    case hours(Int)

    var displayText: String {
        switch self {
        case .days(let d): return d == 1 ? "1 day" : "\(d) days"
        case .hours(let h): return h == 1 ? "1 hour" : "\(h) hours"
        }
    }
}

/// Data model for a win-back offer shown to lapsed subscribers.
struct WinBackOffer: Identifiable, Sendable {
    let id = UUID()
    let headline: String
    let bodyText: String
    let discount: WinBackDiscount
    let originalPrice: String
    let offerPrice: String
    let expiresIn: OfferDuration
    let productID: String
    let features: [String]

    init(
        headline: String = "We missed you!",
        bodyText: String = "Come back and enjoy a special offer just for you.",
        discount: WinBackDiscount,
        originalPrice: String,
        offerPrice: String,
        expiresIn: OfferDuration = .days(7),
        productID: String,
        features: [String] = []
    ) {
        self.headline = headline
        self.bodyText = bodyText
        self.discount = discount
        self.originalPrice = originalPrice
        self.offerPrice = offerPrice
        self.expiresIn = expiresIn
        self.productID = productID
        self.features = features
    }
}

/// Special offer screen for win-back of lapsed subscribers.
///
/// Presents a discount or trial offer with a countdown timer,
/// subscription comparison, and purchase CTA.
///
/// Usage:
/// ```swift
/// .sheet(item: $winBackOffer) { offer in
///     WinBackOfferView(offer: offer, onRedeem: handleRedeem)
/// }
/// ```
struct WinBackOfferView: View {
    let offer: WinBackOffer
    var onRedeem: ((WinBackOffer) -> Void)?
    var onDecline: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var isRedeeming = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    badgeSection
                    headlineSection
                    pricingSection
                    featuresSection
                    actionSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDecline?()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var badgeSection: some View {
        Text(offer.discount.displayText)
            .font(.caption.bold())
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.tint.opacity(0.15))
            .foregroundStyle(.tint)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var headlineSection: some View {
        VStack(spacing: 12) {
            Text(offer.headline)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text(offer.bodyText)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var pricingSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(offer.originalPrice)
                    .font(.title2)
                    .strikethrough()
                    .foregroundStyle(.secondary)

                Text(offer.offerPrice)
                    .font(.title.bold())
                    .foregroundStyle(.tint)
            }

            Text("Offer expires in \(offer.expiresIn.displayText)")
                .font(.footnote)
                .foregroundStyle(.orange)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var featuresSection: some View {
        if !offer.features.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("What you get")
                    .font(.headline)

                ForEach(offer.features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                isRedeeming = true
                onRedeem?(offer)
            } label: {
                Group {
                    if isRedeeming {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Claim Offer")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isRedeeming)

            Button("No thanks") {
                onDecline?()
                dismiss()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
```

## LapsedUserManager.swift

```swift
import Foundation
import SwiftUI

/// Analytics events emitted by the lapsed user system.
enum LapsedUserAnalyticsEvent: String, Sendable {
    case lapseDetected = "lapsed_user.detected"
    case returnScreenShown = "lapsed_user.return_screen_shown"
    case returnScreenDismissed = "lapsed_user.return_screen_dismissed"
    case returnScreenCtaTapped = "lapsed_user.return_screen_cta_tapped"
    case winBackOfferShown = "lapsed_user.winback_offer_shown"
    case winBackOfferRedeemed = "lapsed_user.winback_offer_redeemed"
    case winBackOfferDeclined = "lapsed_user.winback_offer_declined"
    case dontShowAgainTapped = "lapsed_user.dont_show_again_tapped"
}

/// Protocol for analytics tracking integration.
protocol LapsedUserAnalytics: Sendable {
    func track(_ event: LapsedUserAnalyticsEvent, properties: [String: String])
}

/// Default no-op analytics implementation.
struct NoOpLapsedUserAnalytics: LapsedUserAnalytics {
    func track(_ event: LapsedUserAnalyticsEvent, properties: [String: String]) {}
}

/// Orchestrates lapsed user detection, return experience selection, and analytics.
///
/// Combines the `InactivityTracker`, `LapsedUserDetector`, and UI presentation
/// into a single manager that determines which return screen (if any) to show
/// based on lapse duration and user tier.
///
/// Usage:
/// ```swift
/// @State private var manager = LapsedUserManager()
///
/// .task { await manager.checkOnReturn() }
/// .sheet(item: $manager.returnExperience) { experience in
///     ReturnExperienceView(experience: experience)
/// }
/// .sheet(item: $manager.winBackOffer) { offer in
///     WinBackOfferView(offer: offer)
/// }
/// ```
@Observable
final class LapsedUserManager {
    // MARK: - Published State

    /// The return experience to present, if any. Bind to `.sheet(item:)`.
    var returnExperience: ReturnExperience?

    /// The win-back offer to present, if any. Bind to `.sheet(item:)`.
    var winBackOffer: WinBackOffer?

    // MARK: - Dependencies

    private let tracker: InactivityTracker
    private let detector: LapsedUserDetector
    private let analytics: any LapsedUserAnalytics
    private let isSubscriber: Bool
    private let store: UserDefaults
    private let dontShowAgainKey = "com.app.lapsedUser.dontShowAgain"
    private let dismissCountKey = "com.app.lapsedUser.dismissCount"
    private let highlightsProvider: (@Sendable (Date?) -> [ReturnHighlight])?

    init(
        tracker: InactivityTracker = InactivityTracker(),
        detector: LapsedUserDetector? = nil,
        analytics: any LapsedUserAnalytics = NoOpLapsedUserAnalytics(),
        isSubscriber: Bool = false,
        store: UserDefaults = .standard,
        highlightsProvider: (@Sendable (Date?) -> [ReturnHighlight])? = nil
    ) {
        self.tracker = tracker
        self.detector = detector ?? LapsedUserDetector(tracker: tracker)
        self.analytics = analytics
        self.isSubscriber = isSubscriber
        self.store = store
        self.highlightsProvider = highlightsProvider
    }

    // MARK: - Public API

    /// Check the user's inactivity status and prepare the appropriate return experience.
    ///
    /// Call this when the app comes to the foreground. It evaluates the lapse category
    /// and sets `returnExperience` and/or `winBackOffer` if appropriate.
    func checkOnReturn() async {
        let category = detector.evaluate()

        guard category.isLapsed else {
            tracker.recordActivity()
            return
        }

        // Respect "don't show again" preference with exponential backoff
        if shouldSuppressPresentation() {
            tracker.recordActivity()
            return
        }

        analytics.track(.lapseDetected, properties: [
            "category": category.rawValue,
            "days_inactive": "\(tracker.daysSinceLastActive)"
        ])

        // Build return experience
        returnExperience = buildReturnExperience(for: category)

        // Build win-back offer for lapsed subscribers
        if isSubscriber && category == .longTermLapsed {
            winBackOffer = buildWinBackOffer()
        }

        // Record activity after evaluation so next launch sees fresh data
        tracker.recordActivity()
    }

    /// Call when the user taps "Don't show again" on the return screen.
    func userTappedDontShowAgain() {
        store.set(true, forKey: dontShowAgainKey)
        analytics.track(.dontShowAgainTapped, properties: [:])
    }

    /// Call when the return screen is dismissed without action.
    func returnScreenDismissed() {
        let count = store.integer(forKey: dismissCountKey) + 1
        store.set(count, forKey: dismissCountKey)
        analytics.track(.returnScreenDismissed, properties: [
            "dismiss_count": "\(count)"
        ])
    }

    /// Reset all lapsed user state (e.g., on logout).
    func reset() {
        tracker.reset()
        store.removeObject(forKey: dontShowAgainKey)
        store.removeObject(forKey: dismissCountKey)
        returnExperience = nil
        winBackOffer = nil
    }

    // MARK: - Private

    private func shouldSuppressPresentation() -> Bool {
        if store.bool(forKey: dontShowAgainKey) {
            return true
        }

        // Exponential backoff: after N dismissals, require N^2 extra days
        let dismissCount = store.integer(forKey: dismissCountKey)
        if dismissCount > 0 {
            let extraDaysRequired = dismissCount * dismissCount
            let effectiveThreshold = 7 + extraDaysRequired // Base threshold + backoff
            return tracker.daysSinceLastActive < effectiveThreshold
        }

        return false
    }

    private func buildReturnExperience(for category: LapsedUserCategory) -> ReturnExperience {
        let highlights = highlightsProvider?(tracker.lastActiveDate) ?? defaultHighlights(for: category)

        switch category {
        case .recentlyInactive:
            return ReturnExperience(
                headline: "Welcome back!",
                subtitle: "Here's what's been happening while you were away.",
                highlights: highlights,
                ctaTitle: "Jump back in",
                category: category
            )
        case .moderatelyLapsed:
            return ReturnExperience(
                headline: "We missed you!",
                subtitle: "A lot has changed — take a quick look at what's new.",
                highlights: highlights,
                ctaTitle: "See what's new",
                category: category
            )
        case .longTermLapsed:
            return ReturnExperience(
                headline: "It's been a while!",
                subtitle: "We've made some big improvements. Let us show you around.",
                highlights: highlights,
                ctaTitle: "Get restarted",
                category: category
            )
        case .active:
            // Should not reach here, but handle gracefully
            return ReturnExperience(
                headline: "Welcome!",
                subtitle: "",
                highlights: [],
                ctaTitle: "Continue",
                category: category
            )
        }
    }

    private func defaultHighlights(for category: LapsedUserCategory) -> [ReturnHighlight] {
        // Override with highlightsProvider for dynamic content.
        // These are static fallbacks.
        switch category {
        case .recentlyInactive:
            return [
                ReturnHighlight(
                    icon: "sparkles",
                    title: "New features",
                    description: "We've added improvements since your last visit."
                )
            ]
        case .moderatelyLapsed:
            return [
                ReturnHighlight(
                    icon: "sparkles",
                    title: "New features",
                    description: "Several new features have been added."
                ),
                ReturnHighlight(
                    icon: "bolt.fill",
                    title: "Performance improvements",
                    description: "The app is faster and more reliable than ever."
                )
            ]
        case .longTermLapsed:
            return [
                ReturnHighlight(
                    icon: "sparkles",
                    title: "Major updates",
                    description: "We've been busy building great new features."
                ),
                ReturnHighlight(
                    icon: "bolt.fill",
                    title: "Rebuilt from the ground up",
                    description: "Faster, smoother, and more powerful."
                ),
                ReturnHighlight(
                    icon: "heart.fill",
                    title: "Designed for you",
                    description: "New personalization options to make it yours."
                )
            ]
        case .active:
            return []
        }
    }

    private func buildWinBackOffer() -> WinBackOffer {
        // Customize these values based on your subscription tiers.
        WinBackOffer(
            headline: "Welcome back — here's a gift!",
            bodyText: "We'd love to have you back. Enjoy a special returning member discount.",
            discount: .percentage(30),
            originalPrice: "$9.99/mo",
            offerPrice: "$6.99/mo",
            expiresIn: .days(7),
            productID: "com.app.premium.monthly.winback",
            features: [
                "Full access to all premium features",
                "Priority support",
                "No ads"
            ]
        )
    }
}
```

## LapsedUserModifier.swift

```swift
import SwiftUI

/// A ViewModifier that automatically detects lapsed users on app return
/// and presents the appropriate re-engagement experience.
///
/// Attach to your root view for automatic detection:
/// ```swift
/// ContentView()
///     .lapsedUserDetection()
/// ```
///
/// Or with custom configuration:
/// ```swift
/// ContentView()
///     .lapsedUserDetection(
///         tracker: myTracker,
///         isSubscriber: subscriptionManager.isActive,
///         onAnalyticsEvent: { event, props in
///             analytics.track(event.rawValue, properties: props)
///         }
///     )
/// ```
struct LapsedUserModifier: ViewModifier {
    @State private var manager: LapsedUserManager
    @Environment(\.scenePhase) private var scenePhase

    private let onAnalyticsEvent: ((LapsedUserAnalyticsEvent, [String: String]) -> Void)?

    init(
        tracker: InactivityTracker = InactivityTracker(),
        detector: LapsedUserDetector? = nil,
        isSubscriber: Bool = false,
        highlightsProvider: (@Sendable (Date?) -> [ReturnHighlight])? = nil,
        onAnalyticsEvent: ((LapsedUserAnalyticsEvent, [String: String]) -> Void)? = nil
    ) {
        let analytics: any LapsedUserAnalytics
        if let onAnalyticsEvent {
            analytics = ClosureLapsedUserAnalytics(handler: onAnalyticsEvent)
        } else {
            analytics = NoOpLapsedUserAnalytics()
        }

        self._manager = State(initialValue: LapsedUserManager(
            tracker: tracker,
            detector: detector,
            analytics: analytics,
            isSubscriber: isSubscriber,
            highlightsProvider: highlightsProvider
        ))
        self.onAnalyticsEvent = onAnalyticsEvent
    }

    func body(content: Content) -> some View {
        content
            .task {
                await manager.checkOnReturn()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await manager.checkOnReturn()
                    }
                }
            }
            .sheet(item: $manager.returnExperience) { experience in
                ReturnExperienceView(
                    experience: experience,
                    onDismiss: {
                        manager.returnScreenDismissed()
                    },
                    onDontShowAgain: {
                        manager.userTappedDontShowAgain()
                    }
                )
            }
            .sheet(item: $manager.winBackOffer) { offer in
                WinBackOfferView(
                    offer: offer,
                    onRedeem: { redeemedOffer in
                        onAnalyticsEvent?(.winBackOfferRedeemed, [
                            "product_id": redeemedOffer.productID,
                            "discount": redeemedOffer.discount.displayText
                        ])
                    },
                    onDecline: {
                        onAnalyticsEvent?(.winBackOfferDeclined, [:])
                    }
                )
            }
    }
}

/// Convenience View extension for the lapsed user modifier.
extension View {
    /// Adds automatic lapsed user detection and re-engagement presentation.
    ///
    /// - Parameters:
    ///   - tracker: Custom inactivity tracker. Defaults to a new instance.
    ///   - isSubscriber: Whether the current user is/was a subscriber (enables win-back offers).
    ///   - highlightsProvider: Closure returning highlights based on last active date.
    ///   - onAnalyticsEvent: Closure called when analytics events fire.
    func lapsedUserDetection(
        tracker: InactivityTracker = InactivityTracker(),
        isSubscriber: Bool = false,
        highlightsProvider: (@Sendable (Date?) -> [ReturnHighlight])? = nil,
        onAnalyticsEvent: ((LapsedUserAnalyticsEvent, [String: String]) -> Void)? = nil
    ) -> some View {
        modifier(LapsedUserModifier(
            tracker: tracker,
            isSubscriber: isSubscriber,
            highlightsProvider: highlightsProvider,
            onAnalyticsEvent: onAnalyticsEvent
        ))
    }
}

/// Analytics adapter that wraps a closure.
private struct ClosureLapsedUserAnalytics: LapsedUserAnalytics {
    let handler: @Sendable (LapsedUserAnalyticsEvent, [String: String]) -> Void

    func track(_ event: LapsedUserAnalyticsEvent, properties: [String: String]) {
        handler(event, properties)
    }
}
```
