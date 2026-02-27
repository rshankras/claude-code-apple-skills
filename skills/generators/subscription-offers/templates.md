# Subscription Offers Templates

Production-ready Swift code for all subscription offer types.

## SubscriptionOfferManager.swift

```swift
import StoreKit

/// Central manager for all subscription offer types
@Observable
final class SubscriptionOfferManager {

    private var products: [String: Product] = [:]
    private var subscriptionStatuses: [Product.SubscriptionInfo.Status] = []

    // MARK: - Product Loading

    func loadProducts(ids: Set<String>) async throws {
        let loadedProducts = try await Product.products(for: ids)
        for product in loadedProducts {
            products[product.id] = product
        }
    }

    // MARK: - Best Available Offer

    /// Returns the best offer for the user's current state
    func bestAvailableOffer(for productID: String) async -> Product.SubscriptionOffer? {
        guard let product = products[productID],
              let subscription = product.subscription else {
            return nil
        }

        // Priority: Win-back > Promotional > Introductory

        // 1. Check win-back offers (iOS 18+)
        if #available(iOS 18.0, macOS 15.0, *) {
            let winBackOffers = await subscription.winBackOffers
            if let winBack = winBackOffers.first,
               await isEligibleForWinBack(productID: productID) {
                return winBack
            }
        }

        // 2. Check promotional offers
        if let promoOffer = subscription.promotionalOffers.first,
           await isEligibleForPromotionalOffer(productID: productID) {
            return promoOffer
        }

        // 3. Check introductory offer
        if let introOffer = subscription.introductoryOffer,
           await isEligibleForIntroOffer(productID: productID) {
            return introOffer
        }

        return nil
    }

    // MARK: - Purchase with Offer

    func purchase(
        productID: String,
        offer: Product.SubscriptionOffer? = nil
    ) async throws -> Transaction? {
        guard let product = products[productID] else {
            throw OfferError.productNotFound(productID)
        }

        var options: Set<Product.PurchaseOption> = []

        if let offer {
            switch offer.type {
            case .promotional:
                // Promotional offers require a signature
                guard let signedOffer = try await generateSignature(
                    for: offer,
                    productID: productID
                ) else {
                    throw OfferError.signatureGenerationFailed
                }
                options.insert(.promotionalOffer(
                    offerID: offer.id ?? "",
                    keyID: signedOffer.keyID,
                    nonce: signedOffer.nonce,
                    signature: signedOffer.signature,
                    timestamp: signedOffer.timestamp
                ))
            case .introductory:
                // Introductory offers are applied automatically
                break
            default:
                break
            }
        }

        let result = try await product.purchase(options: options)

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    // MARK: - Offer Code Redemption

    @MainActor
    func presentOfferCodeRedemption() async throws {
        try await AppStore.presentOfferCodeRedeemSheet()
    }

    // MARK: - Private Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw OfferError.verificationFailed(error)
        case .verified(let value):
            return value
        }
    }

    private func generateSignature(
        for offer: Product.SubscriptionOffer,
        productID: String
    ) async throws -> OfferSignature? {
        // TODO: Replace with your server-side signature generation
        // See OfferSignatureProvider.swift for implementation
        let provider = OfferSignatureProvider()
        return try await provider.generateSignature(
            productID: productID,
            offerID: offer.id ?? "",
            applicationUsername: "" // Your user identifier
        )
    }
}

// MARK: - Errors

enum OfferError: LocalizedError {
    case productNotFound(String)
    case signatureGenerationFailed
    case verificationFailed(Error)
    case notEligible

    var errorDescription: String? {
        switch self {
        case .productNotFound(let id): "Product not found: \(id)"
        case .signatureGenerationFailed: "Failed to generate offer signature"
        case .verificationFailed(let error): "Verification failed: \(error.localizedDescription)"
        case .notEligible: "Not eligible for this offer"
        }
    }
}
```

## OfferEligibility.swift

```swift
import StoreKit

extension SubscriptionOfferManager {

    // MARK: - Introductory Offer Eligibility

    /// Checks if user is eligible for introductory offer
    /// Users are eligible if they have never subscribed to any product
    /// in the same subscription group
    func isEligibleForIntroOffer(productID: String) async -> Bool {
        guard let product = products[productID],
              let subscription = product.subscription else {
            return false
        }

        // Check if introductory offer exists
        guard subscription.introductoryOffer != nil else {
            return false
        }

        // Check eligibility via subscription status
        return await subscription.isEligibleForIntroOffer
    }

    // MARK: - Promotional Offer Eligibility

    /// Checks if user is eligible for promotional offers
    /// Customize this logic based on your business rules
    func isEligibleForPromotionalOffer(productID: String) async -> Bool {
        guard let product = products[productID],
              let subscription = product.subscription else {
            return false
        }

        // Check if promotional offers exist
        guard !subscription.promotionalOffers.isEmpty else {
            return false
        }

        // Get current subscription status
        guard let statuses = try? await subscription.status else {
            return false
        }

        // Business logic examples:
        // 1. Current subscriber approaching renewal (retain)
        // 2. Lapsed subscriber within 90 days (win-back via promo)
        // 3. Long-term free user (convert)

        for status in statuses {
            guard case .verified(let renewalInfo) = status.renewalInfo else {
                continue
            }

            // Eligible if auto-renew is disabled (at-risk subscriber)
            if renewalInfo.willAutoRenew == false {
                return true
            }

            // Eligible if in billing retry (payment issue)
            if status.state == .inBillingRetryPeriod {
                return true
            }
        }

        // Also eligible if previously subscribed but currently expired
        let hasExpiredSubscription = statuses.contains { status in
            status.state == .expired || status.state == .revoked
        }

        let hasActiveSubscription = statuses.contains { status in
            status.state == .subscribed || status.state == .inGracePeriod
        }

        return hasExpiredSubscription && !hasActiveSubscription
    }

    // MARK: - Win-Back Offer Eligibility (iOS 18+)

    /// Checks if user is eligible for win-back offers
    func isEligibleForWinBack(productID: String) async -> Bool {
        guard #available(iOS 18.0, macOS 15.0, *) else {
            return false
        }

        guard let product = products[productID],
              let subscription = product.subscription else {
            return false
        }

        // Win-back offers are available for churned subscribers
        let winBackOffers = await subscription.winBackOffers
        return !winBackOffers.isEmpty
    }

    // MARK: - Eligibility Summary

    /// Returns a summary of all available offers for a product
    func availableOffers(for productID: String) async -> OfferAvailability {
        let introEligible = await isEligibleForIntroOffer(productID: productID)
        let promoEligible = await isEligibleForPromotionalOffer(productID: productID)
        let winBackEligible = await isEligibleForWinBack(productID: productID)

        return OfferAvailability(
            introductoryOffer: introEligible,
            promotionalOffer: promoEligible,
            winBackOffer: winBackEligible,
            offerCodeRedemption: true // Always available
        )
    }
}

struct OfferAvailability {
    let introductoryOffer: Bool
    let promotionalOffer: Bool
    let winBackOffer: Bool
    let offerCodeRedemption: Bool

    var hasAnyOffer: Bool {
        introductoryOffer || promotionalOffer || winBackOffer
    }
}
```

## OfferConfiguration.swift

```swift
import StoreKit

/// Configuration for subscription offer presentation
struct OfferConfiguration {

    /// Your subscription group ID from App Store Connect
    static let subscriptionGroupID = "YOUR_GROUP_ID"

    /// Product IDs for your subscriptions
    enum ProductID {
        static let monthly = "com.yourapp.subscription.monthly"
        static let yearly = "com.yourapp.subscription.yearly"

        static let all: Set<String> = [monthly, yearly]
    }

    /// Promotional offer IDs (configured in App Store Connect)
    enum PromotionalOfferID {
        static let retentionDiscount = "retention_50_off"
        static let winBackDiscount = "winback_60_off"
        static let loyaltyReward = "loyalty_30_off"
    }

    /// Offer display configuration
    struct DisplayConfig {
        let title: String
        let subtitle: String
        let ctaText: String
        let badge: String?

        static func introductory(trialDays: Int) -> DisplayConfig {
            DisplayConfig(
                title: "Start Your Free Trial",
                subtitle: "Try Pro free for \(trialDays) days",
                ctaText: "Start Free Trial",
                badge: "FREE"
            )
        }

        static func promotional(percentOff: Int) -> DisplayConfig {
            DisplayConfig(
                title: "Special Offer",
                subtitle: "\(percentOff)% off your subscription",
                ctaText: "Claim Offer",
                badge: "\(percentOff)% OFF"
            )
        }

        static func winBack(percentOff: Int) -> DisplayConfig {
            DisplayConfig(
                title: "Welcome Back",
                subtitle: "We've missed you! \(percentOff)% off to come back",
                ctaText: "Resubscribe & Save",
                badge: "WELCOME BACK"
            )
        }
    }
}
```

## OfferBannerView.swift

```swift
import SwiftUI
import StoreKit

/// Contextual banner that shows the best available offer
struct OfferBannerView: View {
    let productID: String
    let offerManager: SubscriptionOfferManager

    @State private var availability: OfferAvailability?
    @State private var offer: Product.SubscriptionOffer?
    @State private var showPaywall = false

    var body: some View {
        Group {
            if let offer, let config = displayConfig(for: offer) {
                offerBanner(config: config)
            }
        }
        .task {
            availability = await offerManager.availableOffers(for: productID)
            offer = await offerManager.bestAvailableOffer(for: productID)
        }
    }

    @ViewBuilder
    private func offerBanner(config: OfferConfiguration.DisplayConfig) -> some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let badge = config.badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.accent.opacity(0.2))
                            .foregroundStyle(.accent)
                            .clipShape(Capsule())
                    }

                    Text(config.title)
                        .font(.headline)

                    Text(config.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(config.ctaText)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            // Present paywall with the pre-selected offer
            SubscriptionStoreView(groupID: OfferConfiguration.subscriptionGroupID)
                .preferredSubscriptionOffer { _, _, _ in
                    offer
                }
        }
    }

    private func displayConfig(
        for offer: Product.SubscriptionOffer
    ) -> OfferConfiguration.DisplayConfig? {
        switch offer.type {
        case .introductory:
            if offer.paymentMode == .freeTrial {
                let days = offer.period.value * (offer.period.unit == .day ? 1 : 7)
                return .introductory(trialDays: days)
            }
            return .promotional(percentOff: 50) // Adjust based on actual discount
        case .promotional:
            return .promotional(percentOff: 50)
        default:
            return .winBack(percentOff: 50)
        }
    }
}
```

## OfferCodeRedemptionView.swift

```swift
import SwiftUI
import StoreKit

/// View for offer code redemption with a manual entry option
struct OfferCodeRedemptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPresenting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "ticket.fill")
                .font(.system(size: 48))
                .foregroundStyle(.accent)

            Text("Redeem Offer Code")
                .font(.title2.weight(.bold))

            Text("Enter your offer code to unlock a special subscription deal.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await presentRedemptionSheet()
                }
            } label: {
                Text("Enter Offer Code")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(32)
    }

    private func presentRedemptionSheet() async {
        do {
            try await AppStore.presentOfferCodeRedeemSheet()
            dismiss()
        } catch {
            errorMessage = "Failed to redeem code. Please try again."
        }
    }
}
```

## OfferSignatureProvider.swift

```swift
import Foundation

/// Handles server-side signature generation for promotional offers
/// Replace the server URL with your actual backend endpoint
struct OfferSignatureProvider {

    struct OfferSignature {
        let keyID: String
        let nonce: UUID
        let signature: Data
        let timestamp: Int
    }

    private let serverURL: URL

    init(serverURL: URL = URL(string: "https://your-server.com/api/offer-signature")!) {
        self.serverURL = serverURL
    }

    /// Generate a signature for a promotional offer
    /// Your server must use the Subscription Key from App Store Connect
    func generateSignature(
        productID: String,
        offerID: String,
        applicationUsername: String
    ) async throws -> OfferSignature? {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "productID": productID,
            "offerID": offerID,
            "applicationUsername": applicationUsername
        ]

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        let decoded = try JSONDecoder().decode(SignatureResponse.self, from: data)

        return OfferSignature(
            keyID: decoded.keyID,
            nonce: UUID(uuidString: decoded.nonce) ?? UUID(),
            signature: Data(base64Encoded: decoded.signature) ?? Data(),
            timestamp: decoded.timestamp
        )
    }
}

private struct SignatureResponse: Decodable {
    let keyID: String
    let nonce: String
    let signature: String
    let timestamp: Int
}
```
