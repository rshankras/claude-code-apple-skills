# Promoted IAP Templates

Production-ready Swift code for handling promoted In-App Purchases.

## PromotedPurchaseHandler.swift

```swift
import StoreKit
import SwiftUI

/// Handles purchases initiated from the App Store product page
@Observable
@MainActor
final class PromotedPurchaseHandler {

    static let shared = PromotedPurchaseHandler()

    private(set) var pendingPurchaseIntent: PurchaseIntent?
    private(set) var isProcessing = false

    /// The flow to show when a promoted purchase arrives
    enum PurchaseFlow: Identifiable {
        case directPurchase(Product)
        case showPaywall(Product)
        case showOnboarding(Product)

        var id: String {
            switch self {
            case .directPurchase(let p): "direct-\(p.id)"
            case .showPaywall(let p): "paywall-\(p.id)"
            case .showOnboarding(let p): "onboarding-\(p.id)"
            }
        }
    }

    private(set) var activePurchaseFlow: PurchaseFlow?

    // MARK: - Handle Purchase Intent

    /// Call this from your app's root view task to handle App Store purchases
    func handle(_ intent: PurchaseIntent) async {
        pendingPurchaseIntent = intent
        isProcessing = true

        let product = intent.product

        // Determine the right flow based on user state
        let flow = await determinePurchaseFlow(for: product)
        activePurchaseFlow = flow

        isProcessing = false
    }

    /// Complete the pending promoted purchase
    func completePurchase() async throws -> Transaction? {
        guard let intent = pendingPurchaseIntent else { return nil }

        let result = try await intent.product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw PromotedPurchaseError.verificationFailed
            }
            await transaction.finish()
            cleanup()
            return transaction

        case .userCancelled:
            cleanup()
            return nil

        case .pending:
            cleanup()
            return nil

        @unknown default:
            cleanup()
            return nil
        }
    }

    /// Cancel the pending promoted purchase
    func cancelPurchase() {
        cleanup()
    }

    // MARK: - Private

    private func determinePurchaseFlow(for product: Product) async -> PurchaseFlow {
        // Check if user has completed onboarding
        let hasCompletedOnboarding = UserDefaults.standard.bool(
            forKey: "hasCompletedOnboarding"
        )

        if !hasCompletedOnboarding {
            // New user from App Store — show onboarding first
            return .showOnboarding(product)
        }

        // Existing user — check if they should see the paywall
        // (e.g., to show other subscription options)
        if product.type == .autoRenewable {
            return .showPaywall(product)
        }

        // Direct purchase for non-subscription IAPs
        return .directPurchase(product)
    }

    private func cleanup() {
        pendingPurchaseIntent = nil
        activePurchaseFlow = nil
        isProcessing = false
    }
}

enum PromotedPurchaseError: LocalizedError {
    case verificationFailed
    case noPendingPurchase

    var errorDescription: String? {
        switch self {
        case .verificationFailed: "Purchase verification failed"
        case .noPendingPurchase: "No pending purchase to complete"
        }
    }
}
```

## PromotedProductConfiguration.swift

```swift
import StoreKit

/// Configuration for promoted In-App Purchases
struct PromotedProductConfiguration {

    /// Products to promote on the App Store product page
    /// Listed in display priority order (first = most prominent)
    static let promotedProducts: [PromotedProduct] = [
        PromotedProduct(
            id: "com.yourapp.pro",
            displayName: "Pro Upgrade",
            promotionalImageName: "promo_pro_upgrade",
            promotionPriority: .high
        ),
        // Add more promoted products as needed
    ]

    /// All promoted product IDs
    static var productIDs: Set<String> {
        Set(promotedProducts.map(\.id))
    }
}

struct PromotedProduct: Identifiable {
    let id: String
    let displayName: String
    let promotionalImageName: String
    let promotionPriority: PromotionPriority

    enum PromotionPriority {
        case high   // First in list, most visible
        case medium // Middle of list
        case low    // End of list
    }
}

// MARK: - Promotional Image Guidelines

/*
 App Store Connect Promotional Image Requirements:

 SIZE: 1024 x 1024 pixels
 FORMAT: PNG or JPEG
 TRANSPARENCY: Not allowed (no alpha channel)
 CORNERS: Square (App Store rounds them automatically)

 CONTENT BEST PRACTICES:
 - Show the key benefit or feature being purchased
 - Use your app's color scheme and visual identity
 - Keep text minimal (product name appears separately)
 - Make it visually distinct from your app icon
 - Test at small sizes (appears as thumbnail in search)

 EXAMPLES BY IAP TYPE:
 - Subscription: Show premium features collage
 - Feature Unlock: Show the specific feature in action
 - Content Pack: Show sample content thumbnails
 - Credits/Tokens: Show the currency with quantity
*/
```

## PromotedPurchaseFlowView.swift

```swift
import SwiftUI
import StoreKit

/// Root view modifier that handles promoted purchase flows
struct PromotedPurchaseFlowModifier: ViewModifier {
    @State private var handler = PromotedPurchaseHandler.shared

    func body(content: Content) -> some View {
        content
            .task {
                for await intent in PurchaseIntent.intents {
                    await handler.handle(intent)
                }
            }
            .sheet(item: $handler.activePurchaseFlow) { flow in
                PromotedPurchaseFlowView(flow: flow, handler: handler)
            }
    }
}

extension View {
    /// Add promoted purchase handling to this view
    func handlePromotedPurchases() -> some View {
        modifier(PromotedPurchaseFlowModifier())
    }
}

/// View that presents the appropriate flow for a promoted purchase
struct PromotedPurchaseFlowView: View {
    let flow: PromotedPurchaseHandler.PurchaseFlow
    let handler: PromotedPurchaseHandler

    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    var body: some View {
        NavigationStack {
            Group {
                switch flow {
                case .directPurchase(let product):
                    directPurchaseView(product: product)
                case .showPaywall(let product):
                    paywallView(product: product)
                case .showOnboarding(let product):
                    onboardingView(product: product)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        handler.cancelPurchase()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Direct Purchase

    @ViewBuilder
    private func directPurchaseView(product: Product) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text(product.displayName)
                .font(.title.weight(.bold))

            Text(product.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(product.displayPrice)
                .font(.title2.weight(.semibold))

            purchaseButton(product: product)

            if let error = purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(32)
    }

    // MARK: - Paywall

    @ViewBuilder
    private func paywallView(product: Product) -> some View {
        // Use SubscriptionStoreView for subscription products
        if product.type == .autoRenewable,
           let groupID = product.subscription?.subscriptionGroupID {
            SubscriptionStoreView(groupID: groupID)
        } else {
            directPurchaseView(product: product)
        }
    }

    // MARK: - Onboarding

    @ViewBuilder
    private func onboardingView(product: Product) -> some View {
        VStack(spacing: 24) {
            Text("Welcome!")
                .font(.largeTitle.weight(.bold))

            Text("Thanks for checking out \(product.displayName). Here's what you'll get:")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Feature list - customize for your app
            VStack(alignment: .leading, spacing: 16) {
                FeatureBullet(icon: "checkmark.circle.fill", text: "Feature 1")
                FeatureBullet(icon: "checkmark.circle.fill", text: "Feature 2")
                FeatureBullet(icon: "checkmark.circle.fill", text: "Feature 3")
            }
            .padding()

            Spacer()

            purchaseButton(product: product)

            Button("Try Free First") {
                handler.cancelPurchase()
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding(32)
    }

    // MARK: - Shared Purchase Button

    @ViewBuilder
    private func purchaseButton(product: Product) -> some View {
        Button {
            isPurchasing = true
            Task {
                do {
                    _ = try await handler.completePurchase()
                    dismiss()
                } catch {
                    purchaseError = error.localizedDescription
                }
                isPurchasing = false
            }
        } label: {
            if isPurchasing {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Buy for \(product.displayPrice)")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isPurchasing)
    }
}

private struct FeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.green)
            Text(text)
        }
    }
}
```
