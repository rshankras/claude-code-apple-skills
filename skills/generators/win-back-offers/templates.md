# Win-Back Offers Templates

Production-ready Swift code for win-back offer implementation.

## WinBackOfferManager.swift

```swift
import StoreKit

/// Manages win-back offer detection, eligibility, and presentation
@Observable
final class WinBackOfferManager {

    static let shared = WinBackOfferManager()

    private(set) var availableWinBackOffer: WinBackOffer?
    private(set) var isCheckingEligibility = false

    // MARK: - Check Availability

    /// Checks if a win-back offer is available for the given product
    func checkWinBackAvailability(productID: String) async -> WinBackOffer? {
        isCheckingEligibility = true
        defer { isCheckingEligibility = false }

        guard let product = try? await Product.products(for: [productID]).first,
              let subscription = product.subscription else {
            return nil
        }

        // iOS 18+ native win-back offers
        if #available(iOS 18.0, macOS 15.0, *) {
            let winBackOffers = await subscription.winBackOffers
            if let offer = winBackOffers.first {
                let winBack = WinBackOffer(
                    product: product,
                    offer: offer,
                    source: .native
                )
                availableWinBackOffer = winBack
                return winBack
            }
        }

        // Fallback: Check if eligible for promotional offer as win-back
        if await isChurnedSubscriber(subscription: subscription) {
            if let promoOffer = subscription.promotionalOffers.first(
                where: { $0.id?.contains("winback") == true }
            ) {
                let winBack = WinBackOffer(
                    product: product,
                    offer: promoOffer,
                    source: .promotional
                )
                availableWinBackOffer = winBack
                return winBack
            }
        }

        return nil
    }

    // MARK: - Purchase with Win-Back Offer

    func purchaseWithWinBack(_ winBack: WinBackOffer) async throws -> Transaction? {
        var options: Set<Product.PurchaseOption> = []

        if winBack.source == .promotional, let offerID = winBack.offer.id {
            // Promotional offers require server-side signature
            // See OfferSignatureProvider in subscription-offers skill
            options.insert(.promotionalOffer(
                offerID: offerID,
                keyID: "YOUR_KEY_ID",
                nonce: UUID(),
                signature: Data(), // From your server
                timestamp: Int(Date().timeIntervalSince1970)
            ))
        }

        let result = try await winBack.product.purchase(options: options)

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw WinBackError.verificationFailed
            }
            await transaction.finish()
            availableWinBackOffer = nil
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    // MARK: - Private

    private func isChurnedSubscriber(
        subscription: Product.SubscriptionInfo
    ) async -> Bool {
        guard let statuses = try? await subscription.status else {
            return false
        }

        let hasExpired = statuses.contains { $0.state == .expired }
        let hasActive = statuses.contains {
            $0.state == .subscribed || $0.state == .inGracePeriod
        }

        return hasExpired && !hasActive
    }
}

// MARK: - Models

struct WinBackOffer: Identifiable {
    let id = UUID()
    let product: Product
    let offer: Product.SubscriptionOffer
    let source: WinBackSource

    enum WinBackSource {
        case native       // iOS 18+ win-back offer
        case promotional  // Promotional offer used as win-back
    }

    var displayPrice: String {
        offer.displayPrice
    }

    var periodDescription: String {
        let unit = offer.period.unit
        let value = offer.period.value
        switch unit {
        case .day: return value == 1 ? "day" : "\(value) days"
        case .week: return value == 1 ? "week" : "\(value) weeks"
        case .month: return value == 1 ? "month" : "\(value) months"
        case .year: return value == 1 ? "year" : "\(value) years"
        @unknown default: return "\(value) periods"
        }
    }

    var isFree: Bool {
        offer.paymentMode == .freeTrial
    }
}

enum WinBackError: LocalizedError {
    case verificationFailed
    case noOfferAvailable
    case purchaseFailed(Error)

    var errorDescription: String? {
        switch self {
        case .verificationFailed: "Transaction verification failed"
        case .noOfferAvailable: "No win-back offer available"
        case .purchaseFailed(let error): "Purchase failed: \(error.localizedDescription)"
        }
    }
}
```

## WinBackMessageHandler.swift

```swift
import StoreKit

/// Handles App Store messages for win-back offers
/// Attach to your app's root view using .storeMessagesTask
@Observable
final class WinBackMessageHandler {

    static let shared = WinBackMessageHandler()

    private(set) var pendingMessage: Message?
    private(set) var showingOffer = false

    /// Handle an incoming App Store message
    /// Call this from .storeMessagesTask on your root view
    @MainActor
    func handle(_ message: Message) async {
        // Store the message for custom handling
        pendingMessage = message

        switch message.reason {
        case .winBackOffer:
            // Win-back offer from App Store
            showingOffer = true
            // Let the system present its default UI
            // Or suppress and show your custom UI:
            // message.display(in: .current)

        case .priceIncreaseConsent:
            // Price increase consent — always let system handle
            break

        case .billingIssue:
            // Billing issue — always let system handle
            break

        default:
            break
        }
    }

    /// Dismiss the current offer
    func dismissOffer() {
        showingOffer = false
        pendingMessage = nil
    }
}
```

## WinBackEligibility.swift

```swift
import StoreKit

/// Determines win-back eligibility based on subscription history
struct WinBackEligibility {

    struct ChurnInfo {
        let lastSubscriptionEndDate: Date?
        let daysSinceChurn: Int
        let previousSubscriptionDuration: Int // in days
        let totalPreviousSpend: Decimal?
        let churnReason: ChurnReason?
    }

    enum ChurnReason {
        case voluntaryCancellation
        case billingIssue
        case priceIncrease
        case unknown
    }

    /// Analyze churn details for a subscription group
    static func analyzeChurn(groupID: String) async -> ChurnInfo? {
        var lastEndDate: Date?
        var churnReason: ChurnReason?

        // Check transaction history
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.subscriptionGroupID == groupID else {
                continue
            }

            if let expirationDate = transaction.expirationDate {
                if lastEndDate == nil || expirationDate > lastEndDate! {
                    lastEndDate = expirationDate

                    // Determine churn reason from revocation
                    if transaction.revocationDate != nil {
                        churnReason = .voluntaryCancellation
                    }
                }
            }
        }

        guard let endDate = lastEndDate else {
            return nil // Never subscribed
        }

        let daysSinceChurn = Calendar.current.dateComponents(
            [.day], from: endDate, to: Date()
        ).day ?? 0

        guard daysSinceChurn > 0 else {
            return nil // Still active
        }

        return ChurnInfo(
            lastSubscriptionEndDate: endDate,
            daysSinceChurn: daysSinceChurn,
            previousSubscriptionDuration: 0, // Calculate from transaction history
            totalPreviousSpend: nil, // Calculate from transaction history
            churnReason: churnReason ?? .unknown
        )
    }

    /// Recommend win-back offer aggressiveness based on churn info
    static func recommendedOfferTier(for churn: ChurnInfo) -> OfferTier {
        switch churn.daysSinceChurn {
        case 0...14:
            return .gentle // 25-30% off, they just left
        case 15...60:
            return .moderate // 40-50% off, need convincing
        case 61...180:
            return .aggressive // 60%+ off or free month
        default:
            return .lastChance // Free trial restart or deep discount
        }
    }

    enum OfferTier: String {
        case gentle = "25-30% discount"
        case moderate = "40-50% discount"
        case aggressive = "60%+ discount or free month"
        case lastChance = "Extended free trial"
    }
}
```

## WinBackOfferView.swift

```swift
import SwiftUI
import StoreKit

/// Custom win-back offer presentation
struct WinBackOfferView: View {
    let offer: WinBackOffer
    let onAccept: () async -> Void
    let onDecline: () -> Void

    @State private var isPurchasing = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.accent)
                    .symbolEffect(.pulse, options: .repeating)

                Text("Welcome Back!")
                    .font(.title.weight(.bold))

                Text("We've been making \(offer.product.displayName) even better while you were away.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // What's New section
            VStack(alignment: .leading, spacing: 12) {
                Text("What's New")
                    .font(.headline)

                // TODO: Customize with your actual new features
                FeatureRow(icon: "sparkles", text: "Improved performance")
                FeatureRow(icon: "paintbrush", text: "Fresh new design")
                FeatureRow(icon: "star", text: "New premium features")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
            }

            // Offer details
            VStack(spacing: 8) {
                if offer.isFree {
                    Text("Try Again Free")
                        .font(.title3.weight(.semibold))

                    Text("Get \(offer.periodDescription) free, then \(offer.product.displayPrice)/\(offer.product.subscription?.subscriptionPeriod.unit.localizedDescription ?? "month")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Special Return Offer")
                        .font(.title3.weight(.semibold))

                    Text("Just \(offer.displayPrice) for your first \(offer.periodDescription)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // CTA buttons
            VStack(spacing: 12) {
                Button {
                    isPurchasing = true
                    Task {
                        await onAccept()
                        isPurchasing = false
                    }
                } label: {
                    if isPurchasing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(offer.isFree ? "Start Free Trial" : "Claim Offer")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isPurchasing)

                Button("Not Now", action: onDecline)
                    .foregroundStyle(.secondary)
            }

            // Legal
            Text("Cancel anytime. Subscription auto-renews.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.accent)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Subscription Period Helper

private extension Product.SubscriptionPeriod.Unit {
    var localizedDescription: String {
        switch self {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        @unknown default: "period"
        }
    }
}
```

## WinBackAnalytics.swift

```swift
import Foundation

/// Tracks win-back offer funnel metrics
protocol WinBackAnalyticsProvider {
    func trackEvent(_ event: WinBackAnalyticsEvent)
}

enum WinBackAnalyticsEvent {
    case eligibilityChecked(productID: String, eligible: Bool)
    case offerShown(productID: String, offerType: String, source: String)
    case offerAccepted(productID: String, offerType: String)
    case offerDeclined(productID: String, offerType: String)
    case purchaseCompleted(productID: String, revenue: Decimal)
    case purchaseFailed(productID: String, error: String)

    var name: String {
        switch self {
        case .eligibilityChecked: "winback_eligibility_checked"
        case .offerShown: "winback_offer_shown"
        case .offerAccepted: "winback_offer_accepted"
        case .offerDeclined: "winback_offer_declined"
        case .purchaseCompleted: "winback_purchase_completed"
        case .purchaseFailed: "winback_purchase_failed"
        }
    }

    var parameters: [String: String] {
        switch self {
        case .eligibilityChecked(let productID, let eligible):
            ["product_id": productID, "eligible": "\(eligible)"]
        case .offerShown(let productID, let offerType, let source):
            ["product_id": productID, "offer_type": offerType, "source": source]
        case .offerAccepted(let productID, let offerType):
            ["product_id": productID, "offer_type": offerType]
        case .offerDeclined(let productID, let offerType):
            ["product_id": productID, "offer_type": offerType]
        case .purchaseCompleted(let productID, let revenue):
            ["product_id": productID, "revenue": "\(revenue)"]
        case .purchaseFailed(let productID, let error):
            ["product_id": productID, "error": error]
        }
    }
}

/// Default print-based analytics (replace with your analytics SDK)
struct PrintWinBackAnalytics: WinBackAnalyticsProvider {
    func trackEvent(_ event: WinBackAnalyticsEvent) {
        print("[WinBack Analytics] \(event.name): \(event.parameters)")
    }
}
```
