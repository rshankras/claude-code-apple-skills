# Milestone Celebration Code Templates

Production-ready Swift templates for milestone celebration UI. All code targets iOS 17+ / macOS 14+ and uses `@Observable`, modern Swift concurrency, and accessibility-aware animations.

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

## Milestone.swift

```swift
import Foundation

/// A milestone achievement that can be unlocked when a threshold is reached.
///
/// Milestones are immutable value types that describe an achievement.
/// Unlock state is tracked separately by `MilestoneTracker`.
///
/// Usage:
/// ```swift
/// let milestone = Milestone(
///     id: "workouts-50",
///     title: "Half Century",
///     milestoneDescription: "Complete 50 workouts",
///     threshold: 50,
///     iconName: "flame.fill"
/// )
/// ```
struct Milestone: Identifiable, Codable, Sendable, Hashable {
    /// Unique identifier for this milestone.
    let id: String

    /// Display title shown in the celebration overlay and badge.
    let title: String

    /// Longer description explaining how to earn this milestone.
    let milestoneDescription: String

    /// The numeric value that must be reached or exceeded to unlock.
    let threshold: Double

    /// SF Symbol name for the badge icon.
    let iconName: String

    /// Optional category for grouping milestones (e.g., "workouts", "streaks", "social").
    var category: String?
}

/// Tracks the unlock state of a single milestone.
struct MilestoneUnlockState: Codable, Sendable {
    let milestoneID: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    var currentProgress: Double

    /// Progress as a fraction from 0.0 to 1.0.
    func progressFraction(threshold: Double) -> Double {
        guard threshold > 0 else { return 1.0 }
        return min(currentProgress / threshold, 1.0)
    }
}

/// A milestone paired with its current unlock state for display purposes.
struct MilestoneWithState: Identifiable, Sendable {
    let milestone: Milestone
    let state: MilestoneUnlockState

    var id: String { milestone.id }
    var isUnlocked: Bool { state.isUnlocked }
    var unlockedDate: Date? { state.unlockedDate }
    var progressFraction: Double { state.progressFraction(threshold: milestone.threshold) }
}
```

## MilestoneTracker.swift

```swift
import Foundation
import SwiftUI

/// Tracks progress toward milestones and triggers celebrations on unlock.
///
/// Persists unlock state so celebrations fire only once per milestone.
/// Supports registering milestones, updating progress, and querying state.
///
/// Usage:
/// ```swift
/// @State private var tracker = MilestoneTracker()
///
/// // Register milestones at app launch
/// tracker.register(Milestone(id: "first-10", title: "First 10", ...))
///
/// // Check after an action
/// if let unlocked = tracker.checkThreshold(value: newCount, for: "first-10") {
///     celebratingMilestone = unlocked
/// }
/// ```
@Observable
final class MilestoneTracker {
    /// All registered milestones with their current state.
    private(set) var milestones: [String: Milestone] = [:]
    private(set) var states: [String: MilestoneUnlockState] = [:]

    private let store: any MilestoneStore

    init(store: any MilestoneStore = UserDefaultsMilestoneStore()) {
        self.store = store
        loadStates()
    }

    // MARK: - Registration

    /// Register a milestone to be tracked.
    func register(_ milestone: Milestone) {
        milestones[milestone.id] = milestone
        if states[milestone.id] == nil {
            states[milestone.id] = MilestoneUnlockState(
                milestoneID: milestone.id,
                isUnlocked: false,
                unlockedDate: nil,
                currentProgress: 0
            )
        }
    }

    /// Register multiple milestones at once.
    func register(_ milestones: [Milestone]) {
        for milestone in milestones {
            register(milestone)
        }
    }

    // MARK: - Threshold Checking

    /// Update progress and check if a milestone should unlock.
    ///
    /// Returns the `MilestoneWithState` if this call caused an unlock,
    /// or `nil` if already unlocked or threshold not yet reached.
    @discardableResult
    func checkThreshold(value: Double, for milestoneID: String) -> MilestoneWithState? {
        guard let milestone = milestones[milestoneID],
              var state = states[milestoneID] else {
            return nil
        }

        // Already unlocked — do not celebrate again
        guard !state.isUnlocked else { return nil }

        state.currentProgress = value

        if value >= milestone.threshold {
            state.isUnlocked = true
            state.unlockedDate = Date()
            states[milestoneID] = state
            saveStates()
            return MilestoneWithState(milestone: milestone, state: state)
        }

        states[milestoneID] = state
        saveStates()
        return nil
    }

    /// Convenience: check a threshold against all milestones in a category.
    func checkThreshold(value: Double, category: String) -> MilestoneWithState? {
        for (id, milestone) in milestones where milestone.category == category {
            if let result = checkThreshold(value: value, for: id) {
                return result
            }
        }
        return nil
    }

    // MARK: - Queries

    /// All milestones with their current state, sorted by threshold.
    var allMilestones: [MilestoneWithState] {
        milestones.values
            .sorted { $0.threshold < $1.threshold }
            .map { milestone in
                let state = states[milestone.id] ?? MilestoneUnlockState(
                    milestoneID: milestone.id,
                    isUnlocked: false,
                    unlockedDate: nil,
                    currentProgress: 0
                )
                return MilestoneWithState(milestone: milestone, state: state)
            }
    }

    /// Only unlocked milestones, sorted by unlock date (newest first).
    var unlockedMilestones: [MilestoneWithState] {
        allMilestones
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockedDate ?? .distantPast) > ($1.unlockedDate ?? .distantPast) }
    }

    /// Count of unlocked vs total.
    var progressSummary: (unlocked: Int, total: Int) {
        let unlocked = states.values.filter(\.isUnlocked).count
        return (unlocked, milestones.count)
    }

    // MARK: - Persistence

    private func loadStates() {
        if let loaded = try? store.load() {
            for state in loaded {
                states[state.milestoneID] = state
            }
        }
    }

    private func saveStates() {
        try? store.save(Array(states.values))
    }

    /// Reset all milestone progress (for testing or account reset).
    func resetAll() {
        states = states.mapValues { state in
            MilestoneUnlockState(
                milestoneID: state.milestoneID,
                isUnlocked: false,
                unlockedDate: nil,
                currentProgress: 0
            )
        }
        saveStates()
    }
}

// MARK: - Persistence Protocol

/// Protocol for milestone state persistence.
protocol MilestoneStore: Sendable {
    func load() throws -> [MilestoneUnlockState]
    func save(_ states: [MilestoneUnlockState]) throws
}

/// UserDefaults-based persistence for milestone unlock state.
final class UserDefaultsMilestoneStore: MilestoneStore {
    private let key: String
    private let defaults: UserDefaults

    init(key: String = "milestone_unlock_states", defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    func load() throws -> [MilestoneUnlockState] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return try JSONDecoder().decode([MilestoneUnlockState].self, from: data)
    }

    func save(_ states: [MilestoneUnlockState]) throws {
        let data = try JSONEncoder().encode(states)
        defaults.set(data, forKey: key)
    }
}

/// In-memory store for testing and previews.
final class InMemoryMilestoneStore: MilestoneStore {
    private var stored: [MilestoneUnlockState] = []

    func load() throws -> [MilestoneUnlockState] {
        stored
    }

    func save(_ states: [MilestoneUnlockState]) throws {
        stored = states
    }
}
```

## ConfettiView.swift

```swift
import SwiftUI

#if canImport(UIKit)
import UIKit

/// Configuration for the confetti particle animation.
struct ConfettiConfiguration: Sendable {
    /// Colors for confetti particles.
    var colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]

    /// Duration of the confetti burst in seconds.
    var duration: TimeInterval = 3.0

    /// Number of particles emitted per second (capped for performance).
    var birthRate: Float = 60

    /// Override for Reduce Motion preference (used in testing).
    var reduceMotionOverride: Bool?

    /// Whether animation should play based on accessibility settings.
    var shouldAnimate: Bool {
        if let override = reduceMotionOverride {
            return !override
        }
        return !UIAccessibility.isReduceMotionEnabled
    }
}

/// A SwiftUI view that displays a confetti particle animation using CAEmitterLayer.
///
/// Automatically respects Reduce Motion accessibility settings.
/// Particles burst from the top and fall with gravity and spin.
///
/// Usage:
/// ```swift
/// ConfettiView(isEmitting: $showConfetti)
/// ```
struct ConfettiView: UIViewRepresentable {
    @Binding var isEmitting: Bool
    var configuration: ConfettiConfiguration = ConfettiConfiguration()

    func makeUIView(context: Context) -> ConfettiUIView {
        ConfettiUIView(configuration: configuration)
    }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {
        if isEmitting {
            uiView.startEmitting()

            // Auto-stop after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + configuration.duration) {
                uiView.stopEmitting()
                isEmitting = false
            }
        } else {
            uiView.stopEmitting()
        }
    }
}

/// UIKit view that manages the CAEmitterLayer for confetti particles.
final class ConfettiUIView: UIView {
    private let emitterLayer = CAEmitterLayer()
    private let configuration: ConfettiConfiguration

    init(configuration: ConfettiConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        setupEmitter()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)
    }

    private func setupEmitter() {
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .additive
        emitterLayer.birthRate = 0 // Start paused

        let shapes: [String] = ["circle.fill", "square.fill", "triangle.fill"]
        let uiColors = configuration.colors.map { UIColor($0) }

        emitterLayer.emitterCells = uiColors.flatMap { color in
            shapes.prefix(2).map { shape in
                makeCell(color: color, shape: shape)
            }
        }

        layer.addSublayer(emitterLayer)
    }

    private func makeCell(color: UIColor, shape: String) -> CAEmitterCell {
        let cell = CAEmitterCell()

        // Render a small colored rectangle as the particle image
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            if shape == "circle.fill" {
                ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            } else if shape == "triangle.fill" {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.close()
                path.fill()
            } else {
                ctx.fill(CGRect(origin: .zero, size: size))
            }
        }
        cell.contents = image.cgImage

        cell.birthRate = configuration.birthRate / Float(configuration.colors.count * 2)
        cell.lifetime = 4.0
        cell.lifetimeRange = 1.0
        cell.velocity = 250
        cell.velocityRange = 80
        cell.emissionLongitude = .pi // Downward
        cell.emissionRange = .pi / 4 // Spread angle
        cell.spin = 3.0
        cell.spinRange = 6.0
        cell.scale = 0.6
        cell.scaleRange = 0.3
        cell.scaleSpeed = -0.05
        cell.yAcceleration = 200 // Gravity
        cell.alphaSpeed = -0.3

        return cell
    }

    func startEmitting() {
        guard configuration.shouldAnimate else { return }
        emitterLayer.birthRate = 1
    }

    func stopEmitting() {
        emitterLayer.birthRate = 0
    }
}

#elseif canImport(AppKit)
import AppKit

/// Configuration for the confetti particle animation (macOS).
struct ConfettiConfiguration: Sendable {
    var colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    var duration: TimeInterval = 3.0
    var birthRate: Float = 60
    var reduceMotionOverride: Bool?

    var shouldAnimate: Bool {
        if let override = reduceMotionOverride {
            return !override
        }
        return !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
}

/// macOS confetti view using Core Animation.
struct ConfettiView: NSViewRepresentable {
    @Binding var isEmitting: Bool
    var configuration: ConfettiConfiguration = ConfettiConfiguration()

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .additive
        emitterLayer.birthRate = 0
        view.layer?.addSublayer(emitterLayer)

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let emitterLayer = nsView.layer?.sublayers?.first as? CAEmitterLayer else { return }
        emitterLayer.frame = nsView.bounds
        emitterLayer.emitterPosition = CGPoint(x: nsView.bounds.midX, y: nsView.bounds.maxY + 20)
        emitterLayer.emitterSize = CGSize(width: nsView.bounds.width, height: 1)

        if isEmitting && configuration.shouldAnimate {
            emitterLayer.birthRate = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + configuration.duration) {
                emitterLayer.birthRate = 0
                isEmitting = false
            }
        } else {
            emitterLayer.birthRate = 0
        }
    }
}
#endif
```

## CelebrationOverlay.swift

```swift
import SwiftUI

/// A full-screen celebration overlay that combines confetti, badge reveal,
/// and a congratulations message.
///
/// Auto-dismisses after the configured duration. Uses spring animations
/// for the badge entrance. Falls back to a simple fade when Reduce Motion
/// is enabled.
///
/// Usage:
/// ```swift
/// .overlay {
///     if let milestone = celebratingMilestone {
///         CelebrationOverlay(milestone: milestone) {
///             celebratingMilestone = nil
///         }
///     }
/// }
/// ```
struct CelebrationOverlay: View {
    let milestone: MilestoneWithState
    let onDismiss: () -> Void

    var duration: TimeInterval = 4.0

    @State private var showConfetti = false
    @State private var showBadge = false
    @State private var showText = false
    @State private var badgeScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Confetti layer
            ConfettiView(isEmitting: $showConfetti)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Badge and message
            VStack(spacing: 24) {
                MilestoneBadgeView(
                    milestone: milestone,
                    size: .large
                )
                .scaleEffect(badgeScale)

                VStack(spacing: 8) {
                    Text("Achievement Unlocked!")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(milestone.milestone.title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text(milestone.milestone.milestoneDescription)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            triggerCelebration()
        }
        #if os(iOS)
        .sensoryFeedback(.success, trigger: showBadge)
        #endif
    }

    private func triggerCelebration() {
        if reduceMotion {
            // Reduced motion: simple fade-in, no confetti
            withAnimation(.easeIn(duration: 0.3)) {
                badgeScale = 1.0
                textOpacity = 1.0
            }
        } else {
            // Full animation: confetti + spring badge + fade text
            showConfetti = true

            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                badgeScale = 1.0
            }

            withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
                textOpacity = 1.0
            }
        }

        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            badgeScale = 0.8
            textOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}
```

## MilestoneBadgeView.swift

```swift
import SwiftUI

/// A badge view representing a single milestone with locked/unlocked states.
///
/// Shows an SF Symbol icon inside a circle. When locked, displays in grayscale
/// with a lock overlay. When partially complete, shows a progress ring.
/// When unlocked, displays in full color with a subtle glow.
///
/// Usage:
/// ```swift
/// MilestoneBadgeView(milestone: milestoneWithState, size: .medium)
/// ```
struct MilestoneBadgeView: View {
    let milestone: MilestoneWithState
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var dimension: CGFloat {
            switch self {
            case .small: return 48
            case .medium: return 72
            case .large: return 120
            }
        }

        var iconFont: Font {
            switch self {
            case .small: return .body
            case .medium: return .title2
            case .large: return .largeTitle
            }
        }

        var ringLineWidth: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 5
            }
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(backgroundFill)
                .frame(width: size.dimension, height: size.dimension)

            // Progress ring (when not yet unlocked)
            if !milestone.isUnlocked {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: size.ringLineWidth)
                    .frame(width: size.dimension, height: size.dimension)

                Circle()
                    .trim(from: 0, to: milestone.progressFraction)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: size.ringLineWidth, lineCap: .round)
                    )
                    .frame(width: size.dimension, height: size.dimension)
                    .rotationEffect(.degrees(-90))
            }

            // Icon
            Image(systemName: milestone.milestone.iconName)
                .font(size.iconFont)
                .foregroundStyle(iconColor)
                .symbolEffect(.bounce, value: milestone.isUnlocked)

            // Lock overlay for locked milestones
            if !milestone.isUnlocked {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size.dimension, height: size.dimension)

                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .shadow(color: milestone.isUnlocked ? .accentColor.opacity(0.4) : .clear, radius: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var backgroundFill: some ShapeStyle {
        if milestone.isUnlocked {
            return AnyShapeStyle(Color.accentColor.opacity(0.15))
        } else {
            return AnyShapeStyle(Color.secondary.opacity(0.08))
        }
    }

    private var iconColor: Color {
        milestone.isUnlocked ? .accentColor : .secondary
    }

    private var accessibilityLabel: String {
        if milestone.isUnlocked {
            return "\(milestone.milestone.title), unlocked"
        } else {
            let percent = Int(milestone.progressFraction * 100)
            return "\(milestone.milestone.title), locked, \(percent) percent progress"
        }
    }
}
```

## MilestoneCollectionView.swift

```swift
import SwiftUI

/// A grid layout displaying all milestones with their locked/unlocked states
/// and progress indicators.
///
/// Shows a summary header ("12 of 20 unlocked") and a responsive grid
/// of badge views. Tapping a badge navigates to a detail view.
///
/// Usage:
/// ```swift
/// MilestoneCollectionView(milestones: tracker.allMilestones, columns: 3)
/// ```
struct MilestoneCollectionView: View {
    let milestones: [MilestoneWithState]
    var columns: Int = 3

    @State private var selectedMilestone: MilestoneWithState?

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Summary header
            summaryHeader

            // Badge grid
            LazyVGrid(columns: gridColumns, spacing: 20) {
                ForEach(milestones) { item in
                    badgeCell(item)
                }
            }
        }
        .padding()
        .sheet(item: $selectedMilestone) { item in
            MilestoneDetailSheet(milestone: item)
        }
    }

    private var summaryHeader: some View {
        let unlocked = milestones.filter(\.isUnlocked).count
        let total = milestones.count

        return HStack {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.yellow)
            Text("\(unlocked) of \(total) Unlocked")
                .font(.headline)
            Spacer()
        }
    }

    private func badgeCell(_ item: MilestoneWithState) -> some View {
        Button {
            selectedMilestone = item
        } label: {
            VStack(spacing: 8) {
                MilestoneBadgeView(milestone: item, size: .medium)

                Text(item.milestone.title)
                    .font(.caption)
                    .foregroundStyle(item.isUnlocked ? .primary : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .help(item.milestone.title)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Detail sheet shown when tapping a milestone badge.
private struct MilestoneDetailSheet: View {
    let milestone: MilestoneWithState

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                MilestoneBadgeView(milestone: milestone, size: .large)

                Text(milestone.milestone.title)
                    .font(.title2.bold())

                Text(milestone.milestone.milestoneDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if milestone.isUnlocked, let date = milestone.unlockedDate {
                    Label(
                        "Unlocked \(date.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.green)
                } else {
                    let percent = Int(milestone.progressFraction * 100)
                    ProgressView(value: milestone.progressFraction) {
                        Text("\(percent)% complete")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
            .padding(.top, 32)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// Conform MilestoneWithState to Hashable for .sheet(item:) support
extension MilestoneWithState: Hashable {
    static func == (lhs: MilestoneWithState, rhs: MilestoneWithState) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

## HapticManager.swift

```swift
#if os(iOS)
import UIKit
import CoreHaptics

/// Thin wrapper around UIKit haptic generators for celebration feedback.
///
/// Checks device haptic capability before firing. Provides preset
/// patterns for different celebration intensities.
///
/// Usage:
/// ```swift
/// let haptics = HapticManager()
/// haptics.playSuccess()        // Milestone unlocked
/// haptics.playLevelUp()        // Multiple rapid taps for level-up
/// ```
final class HapticManager: Sendable {

    /// Whether the device supports haptic feedback.
    static let isSupported: Bool = {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }()

    /// Play a success notification haptic (milestone unlocked).
    func playSuccess() {
        guard Self.isSupported else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Play a warning notification haptic (approaching milestone).
    func playWarning() {
        guard Self.isSupported else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// Play a medium impact haptic (badge tap, selection).
    func playImpact(intensity: CGFloat = 0.7) {
        guard Self.isSupported else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    /// Play a level-up haptic pattern: three quick taps with rising intensity.
    func playLevelUp() {
        guard Self.isSupported else { return }

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()

        let delays: [(TimeInterval, CGFloat)] = [
            (0.0, 0.4),
            (0.1, 0.7),
            (0.2, 1.0)
        ]

        for (delay, intensity) in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                generator.impactOccurred(intensity: intensity)
            }
        }
    }

    /// Play a custom haptic pattern using CoreHaptics for richer feedback.
    func playCustomPattern(events: [CHHapticEvent]) {
        guard Self.isSupported else { return }

        do {
            let engine = try CHHapticEngine()
            try engine.start()

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)

            // Engine stops itself when pattern completes
            engine.notifyWhenPlayersFinished { _ in
                return .stopEngine
            }
        } catch {
            // Haptics are non-critical — fail silently
        }
    }
}
#endif
```

## Environment Integration

```swift
import SwiftUI

/// Environment key for injecting MilestoneTracker throughout the view hierarchy.
private struct MilestoneTrackerKey: EnvironmentKey {
    static let defaultValue = MilestoneTracker()
}

extension EnvironmentValues {
    var milestoneTracker: MilestoneTracker {
        get { self[MilestoneTrackerKey.self] }
        set { self[MilestoneTrackerKey.self] = newValue }
    }
}

/// View modifier that checks a milestone threshold and shows a celebration overlay.
///
/// Usage:
/// ```swift
/// ContentView()
///     .celebrateOnMilestone(value: workoutCount, milestoneID: "workouts-50")
/// ```
struct CelebrationModifier: ViewModifier {
    let value: Double
    let milestoneID: String

    @Environment(\.milestoneTracker) private var tracker
    @State private var celebratingMilestone: MilestoneWithState?

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, newValue in
                if let unlocked = tracker.checkThreshold(value: newValue, for: milestoneID) {
                    celebratingMilestone = unlocked
                }
            }
            .overlay {
                if let milestone = celebratingMilestone {
                    CelebrationOverlay(milestone: milestone) {
                        celebratingMilestone = nil
                    }
                }
            }
    }
}

extension View {
    /// Automatically trigger a celebration overlay when a value crosses a milestone threshold.
    func celebrateOnMilestone(value: Double, milestoneID: String) -> some View {
        modifier(CelebrationModifier(value: value, milestoneID: milestoneID))
    }
}
```
