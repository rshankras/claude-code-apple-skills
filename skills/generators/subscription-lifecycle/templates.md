# Subscription Lifecycle Code Templates

Production-ready Swift templates for StoreKit 2 subscription lifecycle management. All code targets iOS 15+ (iOS 17+ / macOS 14+ for @Observable) and uses modern Swift concurrency.

## SubscriptionState.swift

```swift
import Foundation
import StoreKit

/// Comprehensive subscription lifecycle state.
///
/// Covers all possible states a subscription can be in,
/// including grace period, billing retry, and revocation.
enum SubscriptionState: Sendable, Equatable {
    /// No subscription found — user has never subscribed.
    case notSubscribed

    /// Subscription is active and in good standing.
    /// - Parameter renewalDate: Next renewal or expiration date.
    case active(renewalDate: Date)

    /// Payment failed but user retains access during grace period.
    /// - Parameter daysRemaining: Approximate days left in grace period.
    case inGracePeriod(daysRemaining: Int)

    /// Grace period expired; Apple is retrying billing.
    /// User access is at your discretion (recommended: grant access).
    case inBillingRetry

    /// Subscription expired.
    /// - Parameter reason: Why the subscription expired.
    case expired(reason: ExpirationReason)

    /// Subscription was revoked (refund or family sharing removal).
    case revoked

    /// User upgraded to a higher tier in the same subscription group.
    /// - Parameter newProductID: The product ID of the new tier.
    case upgraded(newProductID: String)

    /// Status is being determined (initial load).
    case unknown

    /// Whether the user should have access to premium features.
    ///
    /// Grants access during grace period and billing retry
    /// to minimize involuntary churn.
    var hasAccess: Bool {
        switch self {
        case .active, .inGracePeriod, .inBillingRetry:
            return true
        case .notSubscribed, .expired, .revoked, .upgraded, .unknown:
            return false
        }
    }

    /// Whether the app should show a payment warning banner.
    var shouldShowPaymentWarning: Bool {
        switch self {
        case .inGracePeriod, .inBillingRetry:
            return true
        default:
            return false
        }
    }
}

/// Reasons a subscription expired.
enum ExpirationReason: Sendable, Equatable {
    /// User disabled auto-renew.
    case autoRenewDisabled
    /// Billing failed and retry period ended.
    case billingError
    /// User declined a price increase.
    case didNotConsentToPriceIncrease
    /// Product is no longer available.
    case productUnavailable
    /// Unknown or unhandled reason.
    case unknown
}
```

## SubscriptionMonitor.swift

```swift
import Foundation
import StoreKit
import Observation

/// Monitors subscription status in real time using StoreKit 2.
///
/// Listens for `Transaction.updates` and polls `Product.SubscriptionInfo`
/// to keep subscription state current throughout the app lifecycle.
///
/// Usage:
/// ```swift
/// @State private var monitor = SubscriptionMonitor()
///
/// ContentView()
///     .environment(monitor)
///     .task { await monitor.start(groupID: "your.group.id") }
/// ```
@Observable
final class SubscriptionMonitor {
    /// Current subscription state.
    private(set) var state: SubscriptionState = .unknown

    /// Current subscription product ID, if any.
    private(set) var currentProductID: String?

    /// Next renewal or expiration date, if active.
    private(set) var renewalDate: Date?

    /// Whether auto-renew is enabled for the current subscription.
    private(set) var isAutoRenewEnabled: Bool = false

    private var transactionListener: Task<Void, Never>?
    private var groupID: String = ""
    private var entitlements: SubscriptionEntitlement?

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Public API

    /// Start monitoring subscription status.
    ///
    /// Call this once at app launch. The monitor will continuously
    /// listen for transaction updates and refresh status.
    ///
    /// - Parameters:
    ///   - groupID: Your subscription group identifier from App Store Connect.
    ///   - entitlements: Optional entitlement mapping for multi-tier subscriptions.
    func start(groupID: String, entitlements: SubscriptionEntitlement? = nil) async {
        self.groupID = groupID
        self.entitlements = entitlements

        // Listen for real-time transaction updates
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshStatus()
                }
            }
        }

        // Initial status check
        await refreshStatus()
    }

    /// Force a status refresh.
    ///
    /// Call after a purchase, restore, or when returning to foreground.
    func refreshStatus() async {
        do {
            let statuses = try await Product.SubscriptionInfo.status(for: groupID)
            await MainActor.run {
                updateFromStatuses(statuses)
            }
        } catch {
            // If status fetch fails, fall back to entitlements check
            await checkEntitlements()
        }
    }

    /// Convenience: whether the user currently has access.
    var hasAccess: Bool {
        state.hasAccess
    }

    /// Days remaining in grace period, or nil if not in grace period.
    var gracePeriodDaysRemaining: Int? {
        if case .inGracePeriod(let days) = state {
            return days
        }
        return nil
    }

    /// Whether the user should see a payment warning.
    var shouldShowPaymentWarning: Bool {
        state.shouldShowPaymentWarning
    }

    /// Open the system subscription management page.
    func openSubscriptionManagement() async {
        guard let windowScene = await MainActor.run(body: {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first
        }) else { return }

        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            // Fallback: open Settings
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await MainActor.run {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    // MARK: - Internal (exposed for testing)

    /// Update state directly. Exposed for unit testing.
    func updateState(_ newState: SubscriptionState) {
        state = newState
    }

    // MARK: - Private

    private func updateFromStatuses(_ statuses: [Product.SubscriptionInfo.Status]) {
        // Find the most relevant status (highest priority)
        for status in statuses {
            guard case .verified(let renewalInfo) = status.renewalInfo,
                  case .verified(let transaction) = status.transaction else {
                continue
            }

            currentProductID = transaction.productID
            isAutoRenewEnabled = renewalInfo.willAutoRenew

            switch status.state {
            case .subscribed:
                renewalDate = transaction.expirationDate
                state = .active(renewalDate: transaction.expirationDate ?? Date.distantFuture)
                return

            case .inGracePeriod:
                let daysRemaining = daysUntil(transaction.expirationDate)
                state = .inGracePeriod(daysRemaining: max(daysRemaining, 0))
                return

            case .inBillingRetryPeriod:
                state = .inBillingRetry
                return

            case .expired:
                let reason = mapExpirationReason(renewalInfo)
                state = .expired(reason: reason)
                return

            case .revoked:
                state = .revoked
                return

            default:
                continue
            }
        }

        // No active status found
        state = .notSubscribed
        currentProductID = nil
        renewalDate = nil
    }

    private func checkEntitlements() async {
        var foundEntitlement = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable {
                    foundEntitlement = true
                    await MainActor.run {
                        currentProductID = transaction.productID
                        renewalDate = transaction.expirationDate
                        state = .active(renewalDate: transaction.expirationDate ?? Date.distantFuture)
                    }
                    break
                }
            }
        }

        if !foundEntitlement {
            await MainActor.run {
                state = .notSubscribed
            }
        }
    }

    private func mapExpirationReason(_ renewalInfo: Product.SubscriptionInfo.RenewalInfo) -> ExpirationReason {
        guard let reason = renewalInfo.expirationReason else {
            return .unknown
        }

        switch reason {
        case .autoRenewDisabled:
            return .autoRenewDisabled
        case .billingError:
            return .billingError
        case .didNotConsentToPriceIncrease:
            return .didNotConsentToPriceIncrease
        case .productUnavailable:
            return .productUnavailable
        default:
            return .unknown
        }
    }

    private func daysUntil(_ date: Date?) -> Int {
        guard let date else { return 0 }
        let interval = date.timeIntervalSince(Date())
        return max(Int(ceil(interval / 86400)), 0)
    }
}
```

## GracePeriodHandler.swift

```swift
import Foundation
import StoreKit
import SwiftUI

/// Handles grace period detection and provides UI components
/// for communicating payment issues to the user.
///
/// Grace periods (6 or 16 days, configured in App Store Connect)
/// give users continued access while Apple resolves payment issues.
/// This handler detects the state and provides appropriate messaging.
///
/// Usage:
/// ```swift
/// GracePeriodBanner(
///     daysRemaining: monitor.gracePeriodDaysRemaining ?? 0,
///     onFixPayment: { await monitor.openSubscriptionManagement() }
/// )
/// ```
struct GracePeriodBanner: View {
    let daysRemaining: Int
    let onFixPayment: () async -> Void

    @State private var isProcessing = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Payment Issue")
                    .font(.subheadline.bold())

                Text(warningMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isProcessing = true
                Task {
                    await onFixPayment()
                    isProcessing = false
                }
            } label: {
                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Fix Now")
                        .font(.subheadline.bold())
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isProcessing)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }

    private var warningMessage: String {
        if daysRemaining <= 1 {
            return "Update your payment method today to keep your subscription."
        } else {
            return "Update your payment method within \(daysRemaining) days to keep your subscription."
        }
    }
}

/// Banner for billing retry period (after grace period expires).
struct BillingRetryBanner: View {
    let onFixPayment: () async -> Void

    @State private var isProcessing = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .foregroundStyle(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Billing Issue")
                    .font(.subheadline.bold())

                Text("There's a problem with your payment method. Update it to continue your subscription.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isProcessing = true
                Task {
                    await onFixPayment()
                    isProcessing = false
                }
            } label: {
                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Update")
                        .font(.subheadline.bold())
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isProcessing)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
}

/// Composite view that shows the appropriate banner based on state.
struct SubscriptionWarningOverlay: View {
    let state: SubscriptionState
    let onFixPayment: () async -> Void

    var body: some View {
        switch state {
        case .inGracePeriod(let daysRemaining):
            GracePeriodBanner(
                daysRemaining: daysRemaining,
                onFixPayment: onFixPayment
            )
            .transition(.move(edge: .top).combined(with: .opacity))

        case .inBillingRetry:
            BillingRetryBanner(onFixPayment: onFixPayment)
                .transition(.move(edge: .top).combined(with: .opacity))

        default:
            EmptyView()
        }
    }
}
```

## OfferManager.swift

```swift
import Foundation
import StoreKit
import Observation

/// Manages subscription offers: promotional offers, offer codes,
/// and win-back offers for lapsed subscribers.
///
/// Usage:
/// ```swift
/// @State private var offerManager = OfferManager()
///
/// // Check for win-back eligibility
/// if let offer = offerManager.availableWinBackOffer {
///     WinBackOfferCard(offer: offer) {
///         try await offerManager.redeemWinBackOffer(offer)
///     }
/// }
/// ```
@Observable
final class OfferManager {
    /// Available win-back offer for lapsed subscribers, if eligible.
    private(set) var availableWinBackOffer: WinBackOffer?

    /// Available promotional offers for the subscription group.
    private(set) var promotionalOffers: [PromotionalOffer] = []

    /// Whether an offer redemption is in progress.
    private(set) var isRedeeming = false

    /// Last error from an offer operation.
    private(set) var lastError: Error?

    private var groupID: String = ""
    private var productIDs: [String] = []

    // MARK: - Public API

    /// Load available offers for the subscription group.
    ///
    /// - Parameters:
    ///   - groupID: Your subscription group identifier.
    ///   - productIDs: Product IDs to check offers for.
    func loadOffers(groupID: String, productIDs: [String]) async {
        self.groupID = groupID
        self.productIDs = productIDs

        await loadWinBackOffers()
        await loadPromotionalOffers()
    }

    /// Redeem a win-back offer.
    ///
    /// - Parameter offer: The win-back offer to redeem.
    /// - Throws: StoreKit errors if purchase fails.
    func redeemWinBackOffer(_ offer: WinBackOffer) async throws {
        isRedeeming = true
        lastError = nil
        defer { isRedeeming = false }

        let products = try await Product.products(for: [offer.productID])
        guard let product = products.first else {
            throw OfferError.productNotFound(offer.productID)
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    /// Redeem a promotional offer.
    ///
    /// Promotional offers require server-side signing. Pass the signed
    /// offer from your server to complete the purchase.
    ///
    /// - Parameters:
    ///   - offer: The promotional offer to redeem.
    ///   - product: The product to purchase with this offer.
    ///   - signedOffer: Server-signed offer parameters.
    func redeemPromotionalOffer(
        _ offer: PromotionalOffer,
        for product: Product,
        signedOffer: Product.PurchaseOption
    ) async throws {
        isRedeeming = true
        lastError = nil
        defer { isRedeeming = false }

        let result = try await product.purchase(options: [signedOffer])

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    /// Present the system offer code redemption sheet.
    ///
    /// Users can enter offer codes generated in App Store Connect.
    @MainActor
    func presentOfferCodeRedemption() async throws {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            throw OfferError.noWindowScene
        }

        try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
    }

    /// Check if a user is eligible for an introductory offer.
    ///
    /// - Parameter product: The subscription product to check.
    /// - Returns: `true` if the user has never subscribed to the group.
    func isEligibleForIntroductoryOffer(_ product: Product) async -> Bool {
        await product.subscription?.isEligibleForIntroOffer ?? false
    }

    // MARK: - Private

    private func loadWinBackOffers() async {
        // Win-back offers are available in iOS 18+
        guard #available(iOS 18, *) else { return }

        do {
            let products = try await Product.products(for: productIDs)
            for product in products {
                guard let subscription = product.subscription else { continue }

                // Check subscription offers for win-back type
                for offer in subscription.promotionalOffers {
                    // Win-back offers are a subset of promotional offers
                    // Apple determines eligibility automatically
                    let winBack = WinBackOffer(
                        id: offer.id ?? "unknown",
                        productID: product.id,
                        displayPrice: offer.displayPrice,
                        period: offer.period,
                        periodCount: offer.periodCount,
                        paymentMode: offer.paymentMode
                    )
                    availableWinBackOffer = winBack
                    return  // Use first available
                }
            }
        } catch {
            lastError = error
        }
    }

    private func loadPromotionalOffers() async {
        do {
            let products = try await Product.products(for: productIDs)
            var offers: [PromotionalOffer] = []

            for product in products {
                guard let subscription = product.subscription else { continue }

                for offer in subscription.promotionalOffers {
                    offers.append(PromotionalOffer(
                        id: offer.id ?? "unknown",
                        productID: product.id,
                        displayPrice: offer.displayPrice,
                        period: offer.period,
                        periodCount: offer.periodCount,
                        paymentMode: offer.paymentMode
                    ))
                }
            }

            promotionalOffers = offers
        } catch {
            lastError = error
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw OfferError.verificationFailed(error)
        }
    }
}

// MARK: - Models

/// Represents a win-back offer for a lapsed subscriber.
struct WinBackOffer: Identifiable, Sendable {
    let id: String
    let productID: String
    let displayPrice: String
    let period: Product.SubscriptionPeriod
    let periodCount: Int
    let paymentMode: Product.SubscriptionOffer.PaymentMode

    var displayDescription: String {
        switch paymentMode {
        case .freeTrial:
            return "Free for \(periodCount) \(period.unit.localizedDescription)"
        case .payUpFront:
            return "\(displayPrice) for \(periodCount) \(period.unit.localizedDescription)"
        case .payAsYouGo:
            return "\(displayPrice)/\(period.unit.localizedDescription) for \(periodCount) periods"
        default:
            return displayPrice
        }
    }
}

/// Represents a promotional offer.
struct PromotionalOffer: Identifiable, Sendable {
    let id: String
    let productID: String
    let displayPrice: String
    let period: Product.SubscriptionPeriod
    let periodCount: Int
    let paymentMode: Product.SubscriptionOffer.PaymentMode
}

/// Errors specific to offer operations.
enum OfferError: Error, LocalizedError {
    case productNotFound(String)
    case verificationFailed(Error)
    case noWindowScene

    var errorDescription: String? {
        switch self {
        case .productNotFound(let id):
            return "Product not found: \(id)"
        case .verificationFailed(let error):
            return "Verification failed: \(error.localizedDescription)"
        case .noWindowScene:
            return "No active window scene available"
        }
    }
}

// MARK: - Period Unit Extension

extension Product.SubscriptionPeriod.Unit {
    var localizedDescription: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return "period"
        }
    }
}
```

## SubscriptionDashboardView.swift

```swift
import SwiftUI
import StoreKit

/// Dashboard view showing current subscription status, plan details,
/// renewal information, and management options.
///
/// Usage:
/// ```swift
/// NavigationLink("Subscription") {
///     SubscriptionDashboardView()
/// }
/// ```
struct SubscriptionDashboardView: View {
    @Environment(SubscriptionMonitor.self) private var monitor

    @State private var products: [Product] = []
    @State private var isLoadingProducts = true
    @State private var showUpgradeSheet = false

    var body: some View {
        List {
            currentPlanSection
            statusSection
            managementSection
        }
        .navigationTitle("Subscription")
        .task {
            await loadProducts()
        }
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradePlanSheet(products: products)
        }
    }

    // MARK: - Current Plan

    @ViewBuilder
    private var currentPlanSection: some View {
        Section {
            if let productID = monitor.currentProductID,
               let product = products.first(where: { $0.id == productID }) {
                CurrentPlanRow(product: product, monitor: monitor)
            } else if monitor.state == .notSubscribed {
                NotSubscribedRow()
            } else if case .unknown = monitor.state {
                LoadingRow()
            }
        } header: {
            Text("Current Plan")
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {
        Section {
            StatusRow(state: monitor.state)

            if let renewalDate = monitor.renewalDate {
                LabeledContent("Renewal Date") {
                    Text(renewalDate, style: .date)
                }
            }

            LabeledContent("Auto-Renew") {
                Text(monitor.isAutoRenewEnabled ? "On" : "Off")
                    .foregroundStyle(monitor.isAutoRenewEnabled ? .primary : .red)
            }
        } header: {
            Text("Status")
        }
    }

    // MARK: - Management

    @ViewBuilder
    private var managementSection: some View {
        Section {
            if monitor.hasAccess && products.count > 1 {
                Button("Change Plan") {
                    showUpgradeSheet = true
                }
            }

            Button("Manage Subscription") {
                Task { await monitor.openSubscriptionManagement() }
            }

            Button("Restore Purchases") {
                Task {
                    try? await AppStore.sync()
                    await monitor.refreshStatus()
                }
            }
        } header: {
            Text("Manage")
        }
    }

    // MARK: - Data Loading

    private func loadProducts() async {
        // Replace with your actual product IDs
        let productIDs = SubscriptionEntitlement.default.allProductIDs
        do {
            products = try await Product.products(for: productIDs)
            isLoadingProducts = false
        } catch {
            isLoadingProducts = false
        }
    }
}

// MARK: - Row Views

private struct CurrentPlanRow: View {
    let product: Product
    let monitor: SubscriptionMonitor

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.displayPrice + periodSuffix)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if monitor.hasAccess {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }

    private var periodSuffix: String {
        guard let period = product.subscription?.subscriptionPeriod else { return "" }
        switch period.unit {
        case .month: return "/month"
        case .year: return "/year"
        case .week: return "/week"
        case .day: return "/day"
        @unknown default: return ""
        }
    }
}

private struct NotSubscribedRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("No Active Subscription")
                    .font(.headline)
                Text("Subscribe to unlock premium features")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "xmark.circle")
                .foregroundStyle(.secondary)
                .font(.title2)
        }
        .padding(.vertical, 4)
    }
}

private struct LoadingRow: View {
    var body: some View {
        HStack {
            Text("Loading subscription status...")
                .foregroundStyle(.secondary)
            Spacer()
            ProgressView()
        }
    }
}

private struct StatusRow: View {
    let state: SubscriptionState

    var body: some View {
        LabeledContent("Status") {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusLabel)
            }
        }
    }

    private var statusLabel: String {
        switch state {
        case .active:
            return "Active"
        case .inGracePeriod(let days):
            return "Grace Period (\(days) days left)"
        case .inBillingRetry:
            return "Billing Issue"
        case .expired:
            return "Expired"
        case .revoked:
            return "Revoked"
        case .upgraded:
            return "Upgraded"
        case .notSubscribed:
            return "Not Subscribed"
        case .unknown:
            return "Checking..."
        }
    }

    private var statusColor: Color {
        switch state {
        case .active:
            return .green
        case .inGracePeriod, .inBillingRetry:
            return .yellow
        case .expired, .revoked:
            return .red
        case .upgraded:
            return .blue
        case .notSubscribed, .unknown:
            return .secondary
        }
    }
}

// MARK: - Upgrade Plan Sheet

private struct UpgradePlanSheet: View {
    let products: [Product]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(sortedProducts, id: \.id) { product in
                Button {
                    Task {
                        let result = try? await product.purchase()
                        if case .success = result {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.displayName)
                                .font(.headline)
                            Text(product.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(product.displayPrice)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Change Plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var sortedProducts: [Product] {
        products.sorted { ($0.price) < ($1.price) }
    }
}
```

## SubscriptionEntitlement.swift

```swift
import Foundation

/// Maps subscription product IDs to feature access levels.
///
/// Use this to determine what features a user has access to
/// based on their current subscription product.
///
/// Usage:
/// ```swift
/// let entitlements = SubscriptionEntitlement.default
/// let level = entitlements.accessLevel(for: "com.app.pro.monthly")
/// if level >= .pro {
///     // Grant pro features
/// }
/// ```
struct SubscriptionEntitlement: Sendable {

    /// Access tier levels, ordered from lowest to highest.
    enum AccessLevel: Int, Comparable, Sendable {
        case free = 0
        case basic = 1
        case pro = 2
        case business = 3

        static func < (lhs: AccessLevel, rhs: AccessLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Mapping of product ID to access level.
    private let productLevels: [String: AccessLevel]

    /// All registered product IDs.
    var allProductIDs: [String] {
        Array(productLevels.keys)
    }

    init(productLevels: [String: AccessLevel]) {
        self.productLevels = productLevels
    }

    /// Get the access level for a product ID.
    ///
    /// - Parameter productID: The StoreKit product identifier.
    /// - Returns: The access level, or `.free` if unknown.
    func accessLevel(for productID: String) -> AccessLevel {
        productLevels[productID] ?? .free
    }

    /// Check if a product ID grants at least the required level.
    ///
    /// - Parameters:
    ///   - productID: The StoreKit product identifier.
    ///   - requiredLevel: Minimum access level needed.
    /// - Returns: `true` if the product grants sufficient access.
    func hasAccess(for productID: String, requiredLevel: AccessLevel) -> Bool {
        accessLevel(for: productID) >= requiredLevel
    }

    /// Determine upgrade/downgrade/crossgrade relationship.
    ///
    /// - Parameters:
    ///   - fromProductID: Current product ID.
    ///   - toProductID: Target product ID.
    /// - Returns: The tier change type.
    func tierChange(from fromProductID: String, to toProductID: String) -> TierChangeType {
        let fromLevel = accessLevel(for: fromProductID)
        let toLevel = accessLevel(for: toProductID)

        if toLevel > fromLevel {
            return .upgrade
        } else if toLevel < fromLevel {
            return .downgrade
        } else {
            return .crossgrade
        }
    }

    /// Types of tier changes.
    enum TierChangeType: Sendable {
        /// Moving to a higher tier (takes effect immediately).
        case upgrade
        /// Moving to a lower tier (takes effect at next renewal).
        case downgrade
        /// Moving to an equivalent tier (e.g., monthly to yearly at same level).
        case crossgrade
    }

    // MARK: - Default Configuration

    /// Default entitlement configuration.
    ///
    /// **Customize these product IDs** to match your App Store Connect configuration.
    static let `default` = SubscriptionEntitlement(productLevels: [
        // Basic tier
        "com.yourapp.basic.monthly": .basic,
        "com.yourapp.basic.yearly": .basic,

        // Pro tier
        "com.yourapp.pro.monthly": .pro,
        "com.yourapp.pro.yearly": .pro,

        // Business tier
        "com.yourapp.business.monthly": .business,
        "com.yourapp.business.yearly": .business,
    ])
}
```
