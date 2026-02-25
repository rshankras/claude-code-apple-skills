# Referral System Code Templates

Production-ready Swift templates for a referral/invite system. All code targets iOS 17+ / macOS 14+ and uses @Observable, SwiftData, and modern Swift concurrency.

## ReferralCode.swift

```swift
import Foundation
import SwiftData

/// A unique referral code owned by a user.
///
/// Codes are alphanumeric, have an expiration date, and track
/// how many times they have been successfully redeemed.
@Model
final class ReferralCode: Sendable {
    /// The unique alphanumeric code string (e.g., "A7K2M9").
    @Attribute(.unique) var value: String

    /// The user ID of the person who owns this code.
    var ownerID: String

    /// When the code was created.
    var createdAt: Date

    /// When the code expires. Nil means no expiration.
    var expiresAt: Date?

    /// Number of successful redemptions.
    var redemptionCount: Int

    /// Maximum allowed redemptions. Nil means unlimited.
    var maxRedemptions: Int?

    /// Whether this code is currently active and shareable.
    var isActive: Bool

    init(
        value: String = ReferralCode.generateUniqueCode(),
        ownerID: String,
        createdAt: Date = .now,
        expiresAt: Date? = Calendar.current.date(byAdding: .day, value: 30, to: .now),
        redemptionCount: Int = 0,
        maxRedemptions: Int? = nil,
        isActive: Bool = true
    ) {
        self.value = value
        self.ownerID = ownerID
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.redemptionCount = redemptionCount
        self.maxRedemptions = maxRedemptions
        self.isActive = isActive
    }

    /// Whether this code can still be redeemed.
    var isValid: Bool {
        guard isActive else { return false }

        if let expiresAt, Date.now > expiresAt {
            return false
        }

        if let maxRedemptions, redemptionCount >= maxRedemptions {
            return false
        }

        return true
    }

    /// Generate a random 6-character alphanumeric code.
    static func generateUniqueCode(length: Int = 6) -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Excludes ambiguous: 0/O, 1/I/L
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    /// Generate a code with a custom prefix (e.g., "MYAPP-A7K2M9").
    static func generatePrefixedCode(prefix: String, length: Int = 6) -> String {
        "\(prefix)-\(generateUniqueCode(length: length))"
    }

    /// Generate a username-based code (e.g., "john-A7K2").
    static func generateUsernameCode(username: String, length: Int = 4) -> String {
        let sanitized = username.lowercased().filter { $0.isLetter || $0.isNumber }
        let truncated = String(sanitized.prefix(10))
        return "\(truncated)-\(generateUniqueCode(length: length))"
    }
}
```

## ReferralReward.swift

```swift
import Foundation
import SwiftData

/// The type of reward granted for a referral.
enum RewardType: String, Codable, Sendable {
    /// Both referrer and invitee receive a reward.
    case bothGet

    /// Only the referrer receives a reward.
    case referrerOnly

    /// Both parties earn points toward a larger reward.
    case pointsBased
}

/// The specific benefit granted as a reward.
enum RewardBenefit: Codable, Sendable, Equatable {
    /// Unlock a premium feature for a duration.
    case premiumAccess(days: Int)

    /// Grant in-app currency or points.
    case points(amount: Int)

    /// Extend an existing subscription.
    case subscriptionExtension(days: Int)

    /// Unlock a specific feature by identifier.
    case featureUnlock(featureID: String)

    /// A display-friendly description of the reward.
    var displayDescription: String {
        switch self {
        case .premiumAccess(let days):
            return "\(days) days of premium access"
        case .points(let amount):
            return "\(amount) bonus points"
        case .subscriptionExtension(let days):
            return "\(days) extra days on your subscription"
        case .featureUnlock(let featureID):
            return "Unlocked: \(featureID)"
        }
    }
}

/// Configuration for how rewards are granted.
struct RewardConfiguration: Codable, Sendable {
    /// What type of referral reward to use.
    let type: RewardType

    /// The reward the referrer receives.
    let referrerBenefit: RewardBenefit

    /// The reward the invitee receives (nil if referrer-only).
    let inviteeBenefit: RewardBenefit?

    /// Minimum action the invitee must complete before rewards are granted.
    let requiredAction: RequiredAction

    /// Default both-get configuration with premium access.
    static let defaultBothGet = RewardConfiguration(
        type: .bothGet,
        referrerBenefit: .premiumAccess(days: 7),
        inviteeBenefit: .premiumAccess(days: 7),
        requiredAction: .accountCreation
    )

    /// Default points-based configuration.
    static let defaultPointsBased = RewardConfiguration(
        type: .pointsBased,
        referrerBenefit: .points(amount: 100),
        inviteeBenefit: .points(amount: 50),
        requiredAction: .accountCreation
    )
}

/// The action an invitee must complete to trigger reward fulfillment.
enum RequiredAction: String, Codable, Sendable {
    /// Reward granted when invitee creates an account.
    case accountCreation

    /// Reward granted when invitee completes onboarding.
    case onboardingComplete

    /// Reward granted when invitee makes a first purchase.
    case firstPurchase

    /// Reward granted when invitee reaches a usage milestone.
    case usageMilestone
}

/// A reward that has been earned through a referral.
@Model
final class ReferralReward: Sendable {
    /// Unique identifier for this reward instance.
    var id: UUID

    /// The user who earned this reward.
    var userID: String

    /// The referral code that triggered this reward.
    var referralCodeValue: String

    /// Whether this user was the referrer or the invitee.
    var role: ReferralRole

    /// The benefit granted.
    var benefit: RewardBenefit

    /// When the reward was created.
    var createdAt: Date

    /// When the reward was fulfilled (applied to the user's account).
    var fulfilledAt: Date?

    /// Whether the reward has been applied.
    var isFulfilled: Bool {
        fulfilledAt != nil
    }

    init(
        id: UUID = UUID(),
        userID: String,
        referralCodeValue: String,
        role: ReferralRole,
        benefit: RewardBenefit,
        createdAt: Date = .now,
        fulfilledAt: Date? = nil
    ) {
        self.id = id
        self.userID = userID
        self.referralCodeValue = referralCodeValue
        self.role = role
        self.benefit = benefit
        self.createdAt = createdAt
        self.fulfilledAt = fulfilledAt
    }
}

/// Whether the user was the referrer or the invitee in a referral.
enum ReferralRole: String, Codable, Sendable {
    case referrer
    case invitee
}
```

## ReferralManager.swift

```swift
import Foundation
import SwiftData
import OSLog

/// Result of attempting to redeem a referral code.
enum RedemptionResult: Equatable, Sendable {
    case success
    case alreadyRedeemed
    case expired
    case invalid
    case maxRedemptionsReached
    case fraudDetected(FraudReason)
}

/// Reason a redemption was flagged as fraudulent.
enum FraudReason: String, Equatable, Sendable {
    case selfReferral
    case duplicateDevice
    case rateLimitExceeded
}

/// Manages the referral code lifecycle: generation, validation, redemption, and reward tracking.
///
/// Usage:
/// ```swift
/// @State private var referralManager = ReferralManager()
///
/// // Generate a code
/// let code = await referralManager.generateCode(for: userID)
///
/// // Redeem a code
/// let result = await referralManager.redeemCode("A7K2M9", redeemedBy: userID)
/// ```
@Observable
final class ReferralManager {
    private let modelContainer: ModelContainer
    private let rewardConfig: RewardConfiguration
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Referral", category: "ReferralManager")

    /// Maximum redemptions per referrer per month.
    private let monthlyReferralCap: Int

    /// Set of user IDs that have already redeemed a code (in-memory cache).
    private var redeemedUserIDs: Set<String> = []

    init(
        modelContainer: ModelContainer? = nil,
        rewardConfig: RewardConfiguration = .defaultBothGet,
        monthlyReferralCap: Int = 50
    ) {
        if let modelContainer {
            self.modelContainer = modelContainer
        } else {
            let schema = Schema([ReferralCode.self, ReferralReward.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            self.modelContainer = try! ModelContainer(for: schema, configurations: [config])
        }
        self.rewardConfig = rewardConfig
        self.monthlyReferralCap = monthlyReferralCap
    }

    // MARK: - Code Generation

    /// Generate a new referral code for the given user.
    @MainActor
    func generateCode(for ownerID: String) -> ReferralCode {
        let context = modelContainer.mainContext
        let code = ReferralCode(ownerID: ownerID)
        context.insert(code)
        try? context.save()
        logger.info("Generated referral code \(code.value) for user \(ownerID)")
        return code
    }

    /// Get the active referral code for a user, or generate one if none exists.
    @MainActor
    func activeCode(for ownerID: String) -> ReferralCode {
        let context = modelContainer.mainContext
        let predicate = #Predicate<ReferralCode> { code in
            code.ownerID == ownerID && code.isActive
        }
        let descriptor = FetchDescriptor<ReferralCode>(predicate: predicate)

        if let existing = try? context.fetch(descriptor).first, existing.isValid {
            return existing
        }

        return generateCode(for: ownerID)
    }

    // MARK: - Code Redemption

    /// Attempt to redeem a referral code.
    ///
    /// Validates the code, checks for fraud, creates rewards, and increments the usage count.
    @MainActor
    func redeemCode(_ codeValue: String, redeemedBy inviteeID: String) -> RedemptionResult {
        let context = modelContainer.mainContext

        // 1. Find the code
        let predicate = #Predicate<ReferralCode> { code in
            code.value == codeValue
        }
        let descriptor = FetchDescriptor<ReferralCode>(predicate: predicate)

        guard let code = try? context.fetch(descriptor).first else {
            logger.warning("Invalid referral code attempted: \(codeValue)")
            return .invalid
        }

        // 2. Check expiration
        if let expiresAt = code.expiresAt, Date.now > expiresAt {
            return .expired
        }

        // 3. Check active and valid
        guard code.isValid else {
            if let max = code.maxRedemptions, code.redemptionCount >= max {
                return .maxRedemptionsReached
            }
            return .invalid
        }

        // 4. Fraud checks
        if code.ownerID == inviteeID {
            logger.warning("Self-referral attempt by user \(inviteeID)")
            return .fraudDetected(.selfReferral)
        }

        if redeemedUserIDs.contains(inviteeID) {
            return .alreadyRedeemed
        }

        if isRateLimited(ownerID: code.ownerID) {
            logger.warning("Rate limit exceeded for referrer \(code.ownerID)")
            return .fraudDetected(.rateLimitExceeded)
        }

        // 5. Create rewards
        let referrerReward = ReferralReward(
            userID: code.ownerID,
            referralCodeValue: code.value,
            role: .referrer,
            benefit: rewardConfig.referrerBenefit
        )
        context.insert(referrerReward)

        if let inviteeBenefit = rewardConfig.inviteeBenefit {
            let inviteeReward = ReferralReward(
                userID: inviteeID,
                referralCodeValue: code.value,
                role: .invitee,
                benefit: inviteeBenefit
            )
            context.insert(inviteeReward)
        }

        // 6. Update code usage
        code.redemptionCount += 1
        redeemedUserIDs.insert(inviteeID)

        try? context.save()
        logger.info("Code \(codeValue) redeemed by \(inviteeID), referrer: \(code.ownerID)")
        return .success
    }

    // MARK: - Rewards

    /// Get all rewards for a user.
    @MainActor
    func rewards(for userID: String) -> [ReferralReward] {
        let context = modelContainer.mainContext
        let predicate = #Predicate<ReferralReward> { reward in
            reward.userID == userID
        }
        let descriptor = FetchDescriptor<ReferralReward>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])

        return (try? context.fetch(descriptor)) ?? []
    }

    /// Get unfulfilled rewards for a user.
    @MainActor
    func pendingRewards(for userID: String) -> [ReferralReward] {
        rewards(for: userID).filter { !$0.isFulfilled }
    }

    /// Mark a reward as fulfilled.
    @MainActor
    func markFulfilled(_ reward: ReferralReward) {
        reward.fulfilledAt = .now
        try? modelContainer.mainContext.save()
        logger.info("Reward \(reward.id) fulfilled for user \(reward.userID)")
    }

    // MARK: - Stats

    /// Total number of successful referrals for a user.
    @MainActor
    func totalReferrals(for ownerID: String) -> Int {
        let context = modelContainer.mainContext
        let predicate = #Predicate<ReferralReward> { reward in
            reward.userID == ownerID && reward.role == .referrer
        }
        let descriptor = FetchDescriptor<ReferralReward>(predicate: predicate)
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Private

    @MainActor
    private func isRateLimited(ownerID: String) -> Bool {
        let context = modelContainer.mainContext
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        let predicate = #Predicate<ReferralReward> { reward in
            reward.userID == ownerID &&
            reward.role == .referrer &&
            reward.createdAt > thirtyDaysAgo
        }
        let descriptor = FetchDescriptor<ReferralReward>(predicate: predicate)
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count >= monthlyReferralCap
    }
}

// MARK: - SwiftUI Environment

import SwiftUI

private struct ReferralManagerKey: EnvironmentKey {
    static let defaultValue: ReferralManager = ReferralManager()
}

extension EnvironmentValues {
    var referralManager: ReferralManager {
        get { self[ReferralManagerKey.self] }
        set { self[ReferralManagerKey.self] = newValue }
    }
}
```

## InviteView.swift

```swift
import SwiftUI

/// A view that displays the user's referral code and provides sharing options.
///
/// Shows the code prominently, with buttons to copy, share via ShareLink,
/// and a brief explanation of the referral reward.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showInvite) {
///     InviteView(ownerID: currentUserID)
/// }
/// ```
struct InviteView: View {
    let ownerID: String

    @Environment(\.referralManager) private var referralManager
    @Environment(\.dismiss) private var dismiss
    @State private var referralCode: ReferralCode?
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                headerSection
                codeDisplaySection
                shareSection
                rewardExplanation
                Spacer()
            }
            .padding(24)
            .navigationTitle("Invite Friends")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                referralCode = referralManager.activeCode(for: ownerID)
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Share Your Code")
                .font(.title2.bold())

            Text("Invite friends and you'll both earn rewards!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var codeDisplaySection: some View {
        VStack(spacing: 12) {
            if let code = referralCode {
                Text(code.value)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .textSelection(.enabled)
            } else {
                ProgressView()
                    .frame(height: 70)
            }
        }
    }

    private var shareSection: some View {
        HStack(spacing: 16) {
            // Copy button
            Button {
                guard let code = referralCode else { return }
                #if canImport(UIKit)
                UIPasteboard.general.string = code.value
                #elseif canImport(AppKit)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code.value, forType: .string)
                #endif
                withAnimation { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { copied = false }
                }
            } label: {
                Label(
                    copied ? "Copied!" : "Copy Code",
                    systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(copied ? .green : nil)

            // Share button
            if let code = referralCode {
                let shareMessage = "Join me on the app! Use my referral code \(code.value) to get started with a bonus."
                ShareLink(item: shareMessage) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private var rewardExplanation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How it works")
                .font(.headline)

            RewardStepRow(
                number: 1,
                icon: "link",
                text: "Share your unique code with friends"
            )
            RewardStepRow(
                number: 2,
                icon: "person.crop.circle.badge.plus",
                text: "They sign up using your code"
            )
            RewardStepRow(
                number: 3,
                icon: "gift.fill",
                text: "You both earn rewards!"
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.05))
        )
    }
}

/// A single step row in the referral explanation.
private struct RewardStepRow: View {
    let number: Int
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.tint)
            }
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}
```

## ReferralDashboardView.swift

```swift
import SwiftUI

/// A dashboard showing referral statistics and reward history.
///
/// Displays total referrals, rewards earned, pending rewards,
/// and a list of recent referral activity.
///
/// Usage:
/// ```swift
/// NavigationLink("My Referrals") {
///     ReferralDashboardView(ownerID: currentUserID)
/// }
/// ```
struct ReferralDashboardView: View {
    let ownerID: String

    @Environment(\.referralManager) private var referralManager
    @State private var referralCode: ReferralCode?
    @State private var allRewards: [ReferralReward] = []

    private var totalReferrals: Int {
        allRewards.filter { $0.role == .referrer }.count
    }

    private var fulfilledRewards: [ReferralReward] {
        allRewards.filter { $0.isFulfilled }
    }

    private var pendingRewards: [ReferralReward] {
        allRewards.filter { !$0.isFulfilled }
    }

    var body: some View {
        List {
            statsSection
            codeSection
            pendingSection
            historySection
        }
        .navigationTitle("My Referrals")
        .task {
            referralCode = referralManager.activeCode(for: ownerID)
            allRewards = referralManager.rewards(for: ownerID)
        }
        .refreshable {
            allRewards = referralManager.rewards(for: ownerID)
        }
    }

    // MARK: - Sections

    private var statsSection: some View {
        Section {
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Referrals",
                    value: "\(totalReferrals)",
                    icon: "person.2.fill",
                    color: .blue
                )
                StatCard(
                    title: "Rewards Earned",
                    value: "\(fulfilledRewards.count)",
                    icon: "gift.fill",
                    color: .green
                )
                StatCard(
                    title: "Pending",
                    value: "\(pendingRewards.count)",
                    icon: "clock.fill",
                    color: .orange
                )
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }

    private var codeSection: some View {
        Section("Your Code") {
            if let code = referralCode {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(code.value)
                            .font(.title3.bold().monospaced())
                        Text("Used \(code.redemptionCount) times")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if code.isValid {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Label("Expired", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var pendingSection: some View {
        if !pendingRewards.isEmpty {
            Section("Pending Rewards") {
                ForEach(pendingRewards, id: \.id) { reward in
                    RewardRow(reward: reward)
                }
            }
        }
    }

    private var historySection: some View {
        Section("Reward History") {
            if fulfilledRewards.isEmpty {
                ContentUnavailableView(
                    "No Rewards Yet",
                    systemImage: "gift",
                    description: Text("Share your code to start earning rewards.")
                )
            } else {
                ForEach(fulfilledRewards, id: \.id) { reward in
                    RewardRow(reward: reward)
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// A compact stat card for the dashboard header.
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

/// A row displaying a single reward with its status.
private struct RewardRow: View {
    let reward: ReferralReward

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.benefit.displayDescription)
                    .font(.subheadline)
                HStack(spacing: 4) {
                    Text(reward.role == .referrer ? "You referred" : "You were invited")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("via \(reward.referralCodeValue)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if reward.isFulfilled {
                    Label("Claimed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Label("Pending", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Text(reward.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
```

## ReferralDeepLinkHandler.swift

```swift
import Foundation
import OSLog

/// Handles incoming referral deep links and constructs shareable URLs.
///
/// Supports universal links in the format:
/// `https://yourapp.com/referral?code=A7K2M9`
///
/// Usage:
/// ```swift
/// let handler = ReferralDeepLinkHandler(host: "yourapp.com")
///
/// // Build a share URL
/// let url = handler.buildShareURL(for: referralCode)
///
/// // Extract code from incoming URL
/// if let code = handler.extractCode(from: incomingURL) {
///     await referralManager.redeemCode(code, redeemedBy: userID)
/// }
/// ```
struct ReferralDeepLinkHandler: Sendable {
    /// The host for universal links (e.g., "yourapp.com").
    let host: String

    /// The path component for referral links.
    let path: String

    /// The query parameter name for the referral code.
    let codeParameter: String

    /// Custom URL scheme for fallback (e.g., "myapp").
    let customScheme: String?

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Referral", category: "DeepLink")

    init(
        host: String = "yourapp.com",
        path: String = "/referral",
        codeParameter: String = "code",
        customScheme: String? = nil
    ) {
        self.host = host
        self.path = path
        self.codeParameter = codeParameter
        self.customScheme = customScheme
    }

    // MARK: - Build Share URLs

    /// Build a universal link URL containing the referral code.
    func buildShareURL(for code: ReferralCode) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = [URLQueryItem(name: codeParameter, value: code.value)]
        return components.url!
    }

    /// Build a custom-scheme URL as a fallback deep link.
    func buildCustomSchemeURL(for code: ReferralCode) -> URL? {
        guard let scheme = customScheme else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = "referral"
        components.queryItems = [URLQueryItem(name: codeParameter, value: code.value)]
        return components.url
    }

    // MARK: - Extract Code from Incoming URLs

    /// Extract a referral code string from an incoming URL.
    ///
    /// Handles both universal links (`https://yourapp.com/referral?code=X`)
    /// and custom scheme links (`myapp://referral?code=X`).
    func extractCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            logger.warning("Failed to parse URL components from \(url.absoluteString)")
            return nil
        }

        // Check universal link
        if components.host == host, components.path == path {
            return extractCodeFromQuery(components)
        }

        // Check custom scheme
        if let scheme = customScheme, components.scheme == scheme, components.host == "referral" {
            return extractCodeFromQuery(components)
        }

        logger.debug("URL does not match referral pattern: \(url.absoluteString)")
        return nil
    }

    /// Validate that an extracted code string looks legitimate.
    ///
    /// Checks length and character set to filter obviously invalid codes
    /// before hitting the database.
    func isPlausibleCode(_ code: String) -> Bool {
        let validCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        guard code.unicodeScalars.allSatisfy({ validCharacters.contains($0) }) else {
            return false
        }
        // Minimum 4 characters, maximum 30 (for prefixed/username codes)
        return code.count >= 4 && code.count <= 30
    }

    // MARK: - Private

    private func extractCodeFromQuery(_ components: URLComponents) -> String? {
        guard let codeValue = components.queryItems?.first(where: { $0.name == codeParameter })?.value,
              !codeValue.isEmpty else {
            logger.warning("Referral URL missing code parameter")
            return nil
        }

        guard isPlausibleCode(codeValue) else {
            logger.warning("Referral code failed plausibility check: \(codeValue)")
            return nil
        }

        logger.info("Extracted referral code: \(codeValue)")
        return codeValue
    }
}
```
