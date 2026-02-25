# Variable Rewards Code Templates

Production-ready Swift templates for a variable reward system. All code targets iOS 17+ / macOS 14+ and uses @Observable, SwiftData, and modern Swift concurrency. All types are Sendable where applicable.

## Reward.swift

```swift
import Foundation

/// A reward that can be granted to the user.
///
/// Rewards have a type (what the user receives), a rarity (how likely it is
/// to appear), and display metadata for UI presentation.
struct Reward: Codable, Sendable, Identifiable, Hashable {
    let id: UUID
    let type: RewardType
    let value: Int
    let rarity: Rarity
    let displayName: String
    let iconName: String

    init(
        id: UUID = UUID(),
        type: RewardType,
        value: Int,
        rarity: Rarity,
        displayName: String,
        iconName: String
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.rarity = rarity
        self.displayName = displayName
        self.iconName = iconName
    }

    // MARK: - Reward Type

    enum RewardType: String, Codable, Sendable, CaseIterable {
        case points
        case item
        case feature
        case badge
    }

    // MARK: - Rarity

    enum Rarity: String, Codable, Sendable, CaseIterable, Comparable {
        case common
        case uncommon
        case rare
        case epic

        var color: String {
            switch self {
            case .common: return "secondary"
            case .uncommon: return "green"
            case .rare: return "blue"
            case .epic: return "purple"
            }
        }

        var label: String {
            rawValue.capitalized
        }

        private var sortOrder: Int {
            switch self {
            case .common: return 0
            case .uncommon: return 1
            case .rare: return 2
            case .epic: return 3
            }
        }

        static func < (lhs: Rarity, rhs: Rarity) -> Bool {
            lhs.sortOrder < rhs.sortOrder
        }
    }
}
```

## RewardPool.swift

```swift
import Foundation
import GameplayKit

/// Manages the pool of available rewards with weighted probability distribution.
///
/// Uses `GKRandomSource` with an optional seed for deterministic testing.
/// Rarity weights control how often each tier appears:
/// - Common: 60% (default)
/// - Uncommon: 25%
/// - Rare: 10%
/// - Epic: 5%
///
/// Usage:
/// ```swift
/// let pool = RewardPool()               // Random (production)
/// let pool = RewardPool(seed: 42)       // Deterministic (testing)
/// let reward = pool.drawReward()
/// ```
final class RewardPool: Sendable {

    /// Rarity weights controlling probability distribution.
    /// Values are relative — they don't need to sum to 100.
    struct RarityWeights: Sendable {
        let common: Double
        let uncommon: Double
        let rare: Double
        let epic: Double

        static let `default` = RarityWeights(
            common: 60,
            uncommon: 25,
            rare: 10,
            epic: 5
        )

        /// Total weight for normalization.
        var total: Double {
            common + uncommon + rare + epic
        }

        /// Returns the weight for a given rarity.
        func weight(for rarity: Reward.Rarity) -> Double {
            switch rarity {
            case .common: return common
            case .uncommon: return uncommon
            case .rare: return rare
            case .epic: return epic
            }
        }

        /// Returns probability (0-1) for a given rarity.
        func probability(for rarity: Reward.Rarity) -> Double {
            weight(for: rarity) / total
        }
    }

    let weights: RarityWeights
    private let rewards: [Reward]
    private let randomSource: GKRandomSource

    /// Creates a reward pool.
    /// - Parameters:
    ///   - rewards: Available rewards. If empty, uses built-in defaults.
    ///   - weights: Rarity probability weights.
    ///   - seed: Optional seed for deterministic random. Omit for system entropy.
    init(
        rewards: [Reward]? = nil,
        weights: RarityWeights = .default,
        seed: UInt64? = nil
    ) {
        self.weights = weights
        self.rewards = rewards ?? Self.defaultRewards

        if let seed {
            self.randomSource = GKMersenneTwisterRandomSource(seed: seed)
        } else {
            self.randomSource = GKMersenneTwisterRandomSource()
        }
    }

    /// Draw a random reward based on rarity weights.
    func drawReward() -> Reward {
        let rarity = drawRarity()
        let candidates = rewards.filter { $0.rarity == rarity }

        guard !candidates.isEmpty else {
            // Fallback: if no rewards for this rarity, pick any
            let index = randomSource.nextInt(upperBound: rewards.count)
            return rewards[index]
        }

        let index = randomSource.nextInt(upperBound: candidates.count)
        return candidates[index]
    }

    /// Draw a rarity tier based on weights.
    private func drawRarity() -> Reward.Rarity {
        let roll = Double(randomSource.nextInt(upperBound: 10000)) / 10000.0
        var cumulative = 0.0
        let total = weights.total

        for rarity in Reward.Rarity.allCases {
            cumulative += weights.weight(for: rarity) / total
            if roll < cumulative {
                return rarity
            }
        }

        return .common // Fallback
    }

    // MARK: - Default Rewards

    static let defaultRewards: [Reward] = [
        // Common rewards (points)
        Reward(type: .points, value: 10, rarity: .common, displayName: "10 Points", iconName: "star.fill"),
        Reward(type: .points, value: 25, rarity: .common, displayName: "25 Points", iconName: "star.fill"),
        Reward(type: .points, value: 50, rarity: .common, displayName: "50 Points", iconName: "star.fill"),

        // Uncommon rewards
        Reward(type: .points, value: 100, rarity: .uncommon, displayName: "100 Points", iconName: "star.circle.fill"),
        Reward(type: .item, value: 1, rarity: .uncommon, displayName: "Sticker Pack", iconName: "face.smiling.fill"),
        Reward(type: .badge, value: 1, rarity: .uncommon, displayName: "Explorer Badge", iconName: "shield.fill"),

        // Rare rewards
        Reward(type: .points, value: 500, rarity: .rare, displayName: "500 Points", iconName: "sparkles"),
        Reward(type: .item, value: 1, rarity: .rare, displayName: "Premium Theme", iconName: "paintpalette.fill"),
        Reward(type: .feature, value: 1, rarity: .rare, displayName: "24h Pro Trial", iconName: "crown.fill"),

        // Epic rewards
        Reward(type: .points, value: 1000, rarity: .epic, displayName: "1000 Points", iconName: "flame.fill"),
        Reward(type: .feature, value: 7, rarity: .epic, displayName: "7-Day Pro Trial", iconName: "crown.fill"),
        Reward(type: .badge, value: 1, rarity: .epic, displayName: "Legendary Badge", iconName: "medal.fill"),
    ]
}
```

## RewardManager.swift

```swift
import Foundation
import SwiftData
import Observation

/// Persisted record of a reward claim.
@Model
final class RewardClaim {
    var rewardID: UUID
    var rewardType: String
    var rewardValue: Int
    var rewardRarity: String
    var rewardDisplayName: String
    var rewardIconName: String
    var mechanism: String          // "daily-spin", "mystery-box", "random-bonus"
    var claimDate: Date            // Normalized to start of day
    var createdAt: Date            // Raw timestamp for audit

    init(reward: Reward, mechanism: String, date: Date = .now) {
        self.rewardID = reward.id
        self.rewardType = reward.type.rawValue
        self.rewardValue = reward.value
        self.rewardRarity = reward.rarity.rawValue
        self.rewardDisplayName = reward.displayName
        self.rewardIconName = reward.iconName
        self.mechanism = mechanism
        self.claimDate = Calendar.current.startOfDay(for: date)
        self.createdAt = Date.now
    }

    /// Reconstruct the Reward value from persisted fields.
    var reward: Reward {
        Reward(
            id: rewardID,
            type: Reward.RewardType(rawValue: rewardType) ?? .points,
            value: rewardValue,
            rarity: Reward.Rarity(rawValue: rewardRarity) ?? .common,
            displayName: rewardDisplayName,
            iconName: rewardIconName
        )
    }
}

/// Manages reward claiming, daily resets, caps, cooldowns, and history.
///
/// Persists claims via SwiftData. Enforces daily and weekly caps
/// to maintain ethical engagement patterns.
///
/// Usage:
/// ```swift
/// let manager = RewardManager(modelContext: context)
/// if manager.canClaimToday {
///     let reward = try await manager.claimDailySpin()
/// }
/// ```
@Observable
final class RewardManager {
    // MARK: - Configuration

    let dailyCap: Int
    let weeklyCap: Int

    // MARK: - State

    private(set) var claimHistory: [RewardClaim] = []
    private(set) var lastClaimDate: Date?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let rewardPool: RewardPool
    private let calendar: Calendar
    private let timeProvider: () -> Date

    init(
        modelContext: ModelContext,
        rewardPool: RewardPool = RewardPool(),
        dailyCap: Int = 3,
        weeklyCap: Int = 10,
        calendar: Calendar = .current,
        timeProvider: @escaping () -> Date = { .now }
    ) {
        self.modelContext = modelContext
        self.rewardPool = rewardPool
        self.dailyCap = dailyCap
        self.weeklyCap = weeklyCap
        self.calendar = calendar
        self.timeProvider = timeProvider

        refreshSync()
    }

    // MARK: - Computed State

    var canClaimToday: Bool {
        dailyClaimCount < dailyCap
    }

    var canClaimThisWeek: Bool {
        weeklyClaimCount < weeklyCap
    }

    var dailyClaimCount: Int {
        let today = calendar.startOfDay(for: timeProvider())
        return claimHistory.filter { $0.claimDate == today }.count
    }

    var weeklyClaimCount: Int {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: timeProvider())?.start else {
            return 0
        }
        return claimHistory.filter { $0.claimDate >= weekStart }.count
    }

    /// Seconds until midnight reset.
    var timeUntilNextClaim: TimeInterval {
        let now = timeProvider()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return 0
        }
        return tomorrow.timeIntervalSince(now)
    }

    /// Claims grouped by calendar day for display.
    var claimHistoryByDay: [Date: [RewardClaim]] {
        Dictionary(grouping: claimHistory) { $0.claimDate }
    }

    // MARK: - Claim Methods

    /// Claim a reward via daily spin mechanism.
    /// Returns `nil` if daily or weekly cap is reached.
    @discardableResult
    func claimDailySpin(date: Date? = nil) async throws -> Reward? {
        try await claim(mechanism: "daily-spin", date: date)
    }

    /// Claim a reward via mystery box mechanism.
    /// Returns `nil` if daily or weekly cap is reached.
    @discardableResult
    func claimMysteryBox(date: Date? = nil) async throws -> Reward? {
        try await claim(mechanism: "mystery-box", date: date)
    }

    /// Claim a reward via random bonus mechanism.
    /// Returns `nil` if daily or weekly cap is reached.
    @discardableResult
    func claimRandomBonus(date: Date? = nil) async throws -> Reward? {
        try await claim(mechanism: "random-bonus", date: date)
    }

    /// Filter claims by rarity.
    func claims(withRarity rarity: Reward.Rarity) -> [RewardClaim] {
        claimHistory.filter { $0.rewardRarity == rarity.rawValue }
    }

    /// Refresh claim history from SwiftData.
    func refresh() async {
        refreshSync()
    }

    // MARK: - Private

    private func claim(mechanism: String, date: Date?) async throws -> Reward? {
        let claimDate = date ?? timeProvider()

        // Check caps
        let today = calendar.startOfDay(for: claimDate)
        let todayClaims = claimHistory.filter { $0.claimDate == today }.count
        guard todayClaims < dailyCap else { return nil }

        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: claimDate)?.start {
            let weekClaims = claimHistory.filter { $0.claimDate >= weekStart }.count
            guard weekClaims < weeklyCap else { return nil }
        }

        // Draw and persist
        let reward = rewardPool.drawReward()
        let claim = RewardClaim(reward: reward, mechanism: mechanism, date: claimDate)
        modelContext.insert(claim)
        try modelContext.save()

        lastClaimDate = claimDate
        refreshSync()

        return reward
    }

    private func refreshSync() {
        let descriptor = FetchDescriptor<RewardClaim>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        claimHistory = (try? modelContext.fetch(descriptor)) ?? []
        lastClaimDate = claimHistory.first?.createdAt
    }
}
```

## DailySpinView.swift

```swift
import SwiftUI

/// An animated spin wheel that grants a random reward once per day.
///
/// Displays a segmented wheel with reward icons. When tapped, the wheel
/// spins with a spring animation and lands on a random segment.
/// Disabled when the user has already claimed today.
///
/// Usage:
/// ```swift
/// DailySpinView(manager: rewardManager)
/// ```
struct DailySpinView: View {
    let manager: RewardManager
    var onRewardClaimed: ((Reward) -> Void)?

    @State private var rotationDegrees: Double = 0
    @State private var isSpinning = false
    @State private var claimedReward: Reward?
    @State private var showResult = false

    private let segments = RewardPool.defaultRewards.prefix(8)
    private let segmentAngle: Double = 360.0 / 8.0

    var body: some View {
        VStack(spacing: 24) {
            Text("Daily Spin")
                .font(.title2.bold())

            ZStack {
                // Wheel
                wheelView
                    .rotationEffect(.degrees(rotationDegrees))
                    .frame(width: 280, height: 280)

                // Center button
                spinButton
            }

            // Countdown or status
            statusText
        }
        .sheet(isPresented: $showResult) {
            if let reward = claimedReward {
                RewardResultView(reward: reward)
            }
        }
    }

    // MARK: - Wheel

    @ViewBuilder
    private var wheelView: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, reward in
                WheelSegmentView(
                    reward: reward,
                    index: index,
                    totalSegments: segments.count,
                    segmentAngle: segmentAngle
                )
            }

            Circle()
                .stroke(Color.primary.opacity(0.2), lineWidth: 2)
        }
    }

    // MARK: - Spin Button

    @ViewBuilder
    private var spinButton: some View {
        Button {
            spin()
        } label: {
            Circle()
                .fill(.thinMaterial)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.title2.bold())
                        .foregroundStyle(manager.canClaimToday ? .blue : .secondary)
                }
                .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .disabled(!manager.canClaimToday || isSpinning)
    }

    // MARK: - Status

    @ViewBuilder
    private var statusText: some View {
        if !manager.canClaimToday {
            let remaining = manager.timeUntilNextClaim
            let hours = Int(remaining) / 3600
            let minutes = (Int(remaining) % 3600) / 60
            Text("Next spin in \(hours)h \(minutes)m")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else if isSpinning {
            Text("Spinning...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text("Tap to spin!")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
    }

    // MARK: - Spin Action

    private func spin() {
        guard manager.canClaimToday, !isSpinning else { return }
        isSpinning = true

        // Spin 5-8 full rotations plus a random offset
        let fullRotations = Double.random(in: 5...8) * 360
        let randomOffset = Double.random(in: 0..<360)
        let targetRotation = rotationDegrees + fullRotations + randomOffset

        withAnimation(.spring(duration: 3.0, bounce: 0.15)) {
            rotationDegrees = targetRotation
        }

        // Claim reward after animation completes
        Task {
            try? await Task.sleep(for: .seconds(3.2))

            if let reward = try? await manager.claimDailySpin() {
                claimedReward = reward
                showResult = true
                onRewardClaimed?(reward)
            }
            isSpinning = false
        }
    }
}

/// A single segment of the spin wheel.
struct WheelSegmentView: View {
    let reward: Reward
    let index: Int
    let totalSegments: Int
    let segmentAngle: Double

    var body: some View {
        let startAngle = Angle(degrees: Double(index) * segmentAngle - 90)
        let endAngle = Angle(degrees: Double(index + 1) * segmentAngle - 90)

        ZStack {
            // Segment shape
            Path { path in
                path.move(to: CGPoint(x: 140, y: 140))
                path.addArc(
                    center: CGPoint(x: 140, y: 140),
                    radius: 140,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(index.isMultiple(of: 2) ? Color.blue.opacity(0.15) : Color.purple.opacity(0.15))

            // Icon
            let midAngle = Angle(degrees: (Double(index) + 0.5) * segmentAngle - 90)
            let iconRadius: CGFloat = 100
            let iconX = 140 + iconRadius * cos(midAngle.radians)
            let iconY = 140 + iconRadius * sin(midAngle.radians)

            Image(systemName: reward.iconName)
                .font(.title3)
                .foregroundStyle(rarityColor(reward.rarity))
                .position(x: iconX, y: iconY)
        }
    }

    private func rarityColor(_ rarity: Reward.Rarity) -> Color {
        switch rarity {
        case .common: return .secondary
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        }
    }
}

/// Displays the reward result after a spin or mystery box reveal.
struct RewardResultView: View {
    let reward: Reward
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: reward.iconName)
                .font(.system(size: 64))
                .foregroundStyle(rarityColor)
                .scaleEffect(showContent ? 1.0 : 0.3)
                .opacity(showContent ? 1.0 : 0.0)

            Text(reward.displayName)
                .font(.title.bold())
                .opacity(showContent ? 1.0 : 0.0)

            Text(reward.rarity.label)
                .font(.headline)
                .foregroundStyle(rarityColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(rarityColor.opacity(0.15), in: Capsule())
                .opacity(showContent ? 1.0 : 0.0)

            if reward.type == .points {
                Text("+\(reward.value) points")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .opacity(showContent ? 1.0 : 0.0)
            }

            Spacer()

            Button("Collect") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.4).delay(0.2)) {
                showContent = true
            }
        }
    }

    private var rarityColor: Color {
        switch reward.rarity {
        case .common: return .secondary
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        }
    }
}
```

## MysteryBoxView.swift

```swift
import SwiftUI

/// A mystery box that reveals a random reward with a card-flip animation.
///
/// Uses `matchedGeometryEffect` for a smooth transition between the
/// closed box and the revealed reward. Supports card-flip and chest-open
/// presentation styles.
///
/// Usage:
/// ```swift
/// MysteryBoxView(manager: rewardManager)
/// MysteryBoxView(manager: rewardManager, style: .chest)
/// ```
struct MysteryBoxView: View {
    let manager: RewardManager
    var style: RevealStyle = .cardFlip
    var onRewardClaimed: ((Reward) -> Void)?

    @State private var isRevealed = false
    @State private var claimedReward: Reward?
    @State private var isProcessing = false
    @Namespace private var revealAnimation

    enum RevealStyle {
        case cardFlip
        case chest
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Mystery Box")
                .font(.title2.bold())

            ZStack {
                if !isRevealed {
                    closedBox
                        .matchedGeometryEffect(id: "reward-container", in: revealAnimation)
                } else if let reward = claimedReward {
                    revealedReward(reward)
                        .matchedGeometryEffect(id: "reward-container", in: revealAnimation)
                }
            }
            .frame(width: 220, height: 280)

            actionButton

            if !manager.canClaimToday {
                let remaining = manager.timeUntilNextClaim
                let hours = Int(remaining) / 3600
                let minutes = (Int(remaining) % 3600) / 60
                Text("Next box in \(hours)h \(minutes)m")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Closed Box

    @ViewBuilder
    private var closedBox: some View {
        switch style {
        case .cardFlip:
            cardBack
        case .chest:
            chestClosed
        }
    }

    @ViewBuilder
    private var cardBack: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 48))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Tap to Reveal")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .shadow(color: .purple.opacity(0.3), radius: 12)
    }

    @ViewBuilder
    private var chestClosed: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.secondary.opacity(0.1))
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.orange)
                    Text("Tap to Open")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
    }

    // MARK: - Revealed Reward

    @ViewBuilder
    private func revealedReward(_ reward: Reward) -> some View {
        let rarityColor = color(for: reward.rarity)

        RoundedRectangle(cornerRadius: 16)
            .fill(rarityColor.opacity(0.1))
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: reward.iconName)
                        .font(.system(size: 48))
                        .foregroundStyle(rarityColor)

                    Text(reward.displayName)
                        .font(.title3.bold())

                    Text(reward.rarity.label)
                        .font(.caption.bold())
                        .foregroundStyle(rarityColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(rarityColor.opacity(0.15), in: Capsule())

                    if reward.type == .points {
                        Text("+\(reward.value)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .shadow(color: rarityColor.opacity(0.3), radius: 12)
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if isRevealed {
            Button("Claim Another") {
                withAnimation(.spring(duration: 0.5)) {
                    isRevealed = false
                    claimedReward = nil
                }
            }
            .buttonStyle(.bordered)
            .disabled(!manager.canClaimToday)
        } else {
            Button {
                reveal()
            } label: {
                Label("Open Box", systemImage: "gift.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!manager.canClaimToday || isProcessing)
        }
    }

    // MARK: - Reveal Action

    private func reveal() {
        guard manager.canClaimToday, !isProcessing else { return }
        isProcessing = true

        Task {
            if let reward = try? await manager.claimMysteryBox() {
                claimedReward = reward

                withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                    isRevealed = true
                }

                onRewardClaimed?(reward)
            }
            isProcessing = false
        }
    }

    // MARK: - Helpers

    private func color(for rarity: Reward.Rarity) -> Color {
        switch rarity {
        case .common: return .secondary
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        }
    }
}
```

## RewardHistoryView.swift

```swift
import SwiftUI

/// Displays a list of past reward claims grouped by day.
///
/// Each entry shows the reward icon, name, rarity badge, and claim mechanism.
/// Days are sorted most recent first.
///
/// Usage:
/// ```swift
/// RewardHistoryView(manager: rewardManager)
/// ```
struct RewardHistoryView: View {
    let manager: RewardManager

    private var sortedDays: [Date] {
        manager.claimHistoryByDay.keys.sorted(by: >)
    }

    var body: some View {
        Group {
            if manager.claimHistory.isEmpty {
                emptyState
            } else {
                rewardList
            }
        }
        .navigationTitle("Reward History")
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Rewards Yet", systemImage: "gift")
        } description: {
            Text("Claim your first reward from the daily spin or mystery box.")
        }
    }

    // MARK: - Reward List

    @ViewBuilder
    private var rewardList: some View {
        List {
            ForEach(sortedDays, id: \.self) { day in
                Section {
                    let claims = manager.claimHistoryByDay[day] ?? []
                    ForEach(claims, id: \.rewardID) { claim in
                        RewardHistoryRow(claim: claim)
                    }
                } header: {
                    Text(day, format: .dateTime.month(.wide).day().year())
                }
            }
        }
    }
}

/// A single row in the reward history list.
struct RewardHistoryRow: View {
    let claim: RewardClaim

    private var rarity: Reward.Rarity {
        Reward.Rarity(rawValue: claim.rewardRarity) ?? .common
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: claim.rewardIconName)
                .font(.title3)
                .foregroundStyle(rarityColor)
                .frame(width: 36, height: 36)
                .background(rarityColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(claim.rewardDisplayName)
                    .font(.body)

                HStack(spacing: 6) {
                    Text(rarity.label)
                        .font(.caption2.bold())
                        .foregroundStyle(rarityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(rarityColor.opacity(0.12), in: Capsule())

                    Text(mechanismLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Time
            Text(claim.createdAt, format: .dateTime.hour().minute())
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var rarityColor: Color {
        switch rarity {
        case .common: return .secondary
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        }
    }

    private var mechanismLabel: String {
        switch claim.mechanism {
        case "daily-spin": return "Daily Spin"
        case "mystery-box": return "Mystery Box"
        case "random-bonus": return "Bonus"
        default: return claim.mechanism.capitalized
        }
    }
}
```

## RewardNotificationView.swift

```swift
import SwiftUI

/// A toast/banner notification that appears when a reward is available to claim.
///
/// Overlay this on your root view. It slides in from the top with a spring
/// animation and auto-dismisses after a delay, or the user can tap to navigate
/// to the reward screen.
///
/// Usage:
/// ```swift
/// ZStack {
///     MainContentView()
///     RewardNotificationView(manager: rewardManager) {
///         // Navigate to rewards screen
///     }
/// }
/// ```
struct RewardNotificationView: View {
    let manager: RewardManager
    var onTap: (() -> Void)?

    @State private var isVisible = false
    @State private var hasShownToday = false

    var body: some View {
        VStack {
            if isVisible {
                notificationBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(duration: 0.5, bounce: 0.3), value: isVisible)
        .onChange(of: manager.canClaimToday) { _, canClaim in
            if canClaim && !hasShownToday {
                showNotification()
            }
        }
        .onAppear {
            if manager.canClaimToday && !hasShownToday {
                // Delay initial appearance for a natural feel
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    showNotification()
                }
            }
        }
    }

    // MARK: - Banner

    @ViewBuilder
    private var notificationBanner: some View {
        Button {
            onTap?()
            withAnimation {
                isVisible = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Reward Available!")
                        .font(.subheadline.bold())
                    Text("Tap to claim your daily reward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Show / Auto-Dismiss

    private func showNotification() {
        guard manager.canClaimToday, !hasShownToday else { return }
        hasShownToday = true

        withAnimation {
            isVisible = true
        }

        // Auto-dismiss after 5 seconds
        Task {
            try? await Task.sleep(for: .seconds(5))
            withAnimation {
                isVisible = false
            }
        }
    }
}
```
