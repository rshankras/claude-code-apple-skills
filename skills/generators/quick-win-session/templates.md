# Quick Win Session Code Templates

Production-ready Swift templates for a quick win session system. All code targets iOS 17+ / macOS 14+ and uses @Observable with modern Swift concurrency.

## QuickWinTask.swift

```swift
import Foundation

/// A quick win task that guides a new user to their first meaningful action.
///
/// Each task has a sequence of steps and a completion criteria identifier
/// used to check whether the user has already achieved this quick win.
struct QuickWinTask: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let description: String
    let estimatedSeconds: Int
    let steps: [QuickWinStep]
    let completionCriteria: String
    let iconName: String

    var stepCount: Int { steps.count }
}

/// A single step within a quick win task.
///
/// Each step describes an instruction for the user and identifies
/// the target view element that the user should interact with.
struct QuickWinStep: Identifiable, Codable, Sendable {
    var id: String { "\(actionType.rawValue)_\(targetView)" }
    let instruction: String
    let actionType: ActionType
    let targetView: String

    enum ActionType: String, Codable, Sendable {
        case tap
        case input
        case navigate
    }
}

// MARK: - Test Helpers

extension QuickWinTask {
    /// Creates a test task with the specified number of placeholder steps.
    static func testTask(stepCount: Int) -> QuickWinTask {
        QuickWinTask(
            id: "test-task",
            title: "Test Task",
            description: "A task for testing.",
            estimatedSeconds: 30,
            steps: (0..<stepCount).map { index in
                QuickWinStep(
                    instruction: "Step \(index + 1)",
                    actionType: .tap,
                    targetView: "target_\(index)"
                )
            },
            completionCriteria: "testCompleted",
            iconName: "checkmark.circle"
        )
    }
}
```

## QuickWinSession.swift

```swift
import Foundation
import SwiftUI

/// Manages the lifecycle of a quick win session.
///
/// Tracks progress through task steps, measures completion time,
/// handles abandonment, and persists completion status so the
/// quick win is never shown again after finishing.
///
/// Usage:
/// ```swift
/// @State private var session = QuickWinSession()
///
/// .onAppear {
///     if !session.hasCompletedQuickWin(id: "create-first-note") {
///         session.start(task: .createFirstNote)
///     }
/// }
/// ```
@Observable
final class QuickWinSession {
    // MARK: - Public State

    private(set) var currentTask: QuickWinTask?
    private(set) var currentStepIndex: Int = 0
    private(set) var isActive: Bool = false
    private(set) var isCompleted: Bool = false
    private(set) var completionTimeSeconds: TimeInterval = 0
    private(set) var abandonedAtStep: Int?

    var completedTask: QuickWinTask? {
        isCompleted ? currentTask : nil
    }

    var currentStep: QuickWinStep? {
        guard let task = currentTask,
              currentStepIndex < task.steps.count else { return nil }
        return task.steps[currentStepIndex]
    }

    var progress: Double {
        guard let task = currentTask, task.stepCount > 0 else { return 0 }
        return Double(currentStepIndex) / Double(task.stepCount)
    }

    // MARK: - Private

    private var startTime: Date?
    private let storage: QuickWinStorage

    // MARK: - Init

    init(storage: QuickWinStorage = UserDefaultsQuickWinStorage()) {
        self.storage = storage
    }

    // MARK: - Session Control

    /// Start a quick win session for the given task.
    ///
    /// If the user has already completed this task, the session
    /// will not activate.
    func start(task: QuickWinTask) {
        guard !hasCompletedQuickWin(id: task.id) else { return }

        currentTask = task
        currentStepIndex = 0
        isActive = true
        isCompleted = false
        completionTimeSeconds = 0
        abandonedAtStep = nil
        startTime = Date()
    }

    /// Mark the current step as complete and advance to the next.
    ///
    /// If this was the final step, the session completes automatically.
    func completeCurrentStep() {
        guard isActive, let task = currentTask else { return }

        let nextIndex = currentStepIndex + 1

        if nextIndex >= task.stepCount {
            completeSession()
        } else {
            currentStepIndex = nextIndex
        }
    }

    /// Abandon the session without completing.
    ///
    /// Records which step the user was on for analytics.
    func abandon() {
        guard isActive else { return }

        abandonedAtStep = currentStepIndex
        isActive = false
    }

    /// Skip the quick win entirely and mark it as dismissed.
    func skip() {
        guard isActive, let task = currentTask else { return }

        storage.markDismissed(taskID: task.id)
        abandonedAtStep = currentStepIndex
        isActive = false
    }

    /// Resume a previously interrupted session.
    ///
    /// Call this when the app returns to foreground during
    /// an active quick win.
    func resumeIfNeeded() {
        // Session state is held in memory; just verify it's valid
        guard currentTask != nil, !isCompleted else {
            isActive = false
            return
        }
    }

    // MARK: - Query

    /// Check whether a quick win has already been completed.
    func hasCompletedQuickWin(id: String) -> Bool {
        storage.isCompleted(taskID: id)
    }

    // MARK: - Private

    private func completeSession() {
        guard let task = currentTask, let startTime else { return }

        completionTimeSeconds = Date().timeIntervalSince(startTime)
        isCompleted = true
        isActive = false
        storage.markCompleted(taskID: task.id, timeSeconds: completionTimeSeconds)
    }
}

// MARK: - Storage Protocol

/// Abstracts persistence of quick win completion status.
///
/// Conform to this protocol for custom storage backends
/// (SwiftData, CloudKit, etc.).
protocol QuickWinStorage: Sendable {
    func isCompleted(taskID: String) -> Bool
    func isDismissed(taskID: String) -> Bool
    func markCompleted(taskID: String, timeSeconds: TimeInterval)
    func markDismissed(taskID: String)
}

// MARK: - UserDefaults Storage

/// Default storage implementation using UserDefaults.
final class UserDefaultsQuickWinStorage: QuickWinStorage, @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isCompleted(taskID: String) -> Bool {
        defaults.bool(forKey: storageKey(taskID, suffix: "completed"))
    }

    func isDismissed(taskID: String) -> Bool {
        defaults.bool(forKey: storageKey(taskID, suffix: "dismissed"))
    }

    func markCompleted(taskID: String, timeSeconds: TimeInterval) {
        defaults.set(true, forKey: storageKey(taskID, suffix: "completed"))
        defaults.set(timeSeconds, forKey: storageKey(taskID, suffix: "completionTime"))
    }

    func markDismissed(taskID: String) {
        defaults.set(true, forKey: storageKey(taskID, suffix: "dismissed"))
    }

    private func storageKey(_ taskID: String, suffix: String) -> String {
        "quickWin_\(taskID)_\(suffix)"
    }
}

// MARK: - Mock Storage (Testing)

/// In-memory storage for unit tests.
final class MockQuickWinStorage: QuickWinStorage, @unchecked Sendable {
    private var store: [String: Any] = [:]

    func isCompleted(taskID: String) -> Bool {
        store["quickWin_\(taskID)_completed"] as? Bool ?? false
    }

    func isDismissed(taskID: String) -> Bool {
        store["quickWin_\(taskID)_dismissed"] as? Bool ?? false
    }

    func markCompleted(taskID: String, timeSeconds: TimeInterval) {
        store["quickWin_\(taskID)_completed"] = true
        store["quickWin_\(taskID)_completionTime"] = timeSeconds
    }

    func markDismissed(taskID: String) {
        store["quickWin_\(taskID)_dismissed"] = true
    }

    func set(_ value: Any, forKey key: String) {
        store[key] = value
    }
}
```

## QuickWinGuideView.swift

```swift
import SwiftUI

/// Overlay that guides the user through quick win steps.
///
/// Displays the current instruction at the top of the screen,
/// a progress indicator, and a Skip button. Uses matched geometry
/// for smooth transitions between steps.
///
/// Usage:
/// ```swift
/// ZStack {
///     MainContentView()
///     QuickWinGuideView(session: session)
/// }
/// ```
struct QuickWinGuideView: View {
    let session: QuickWinSession
    @Namespace private var animation

    var body: some View {
        if session.isActive, let step = session.currentStep, let task = session.currentTask {
            VStack(spacing: 0) {
                instructionCard(task: task, step: step)
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: session.currentStepIndex)
        }
    }

    // MARK: - Instruction Card

    @ViewBuilder
    private func instructionCard(task: QuickWinTask, step: QuickWinStep) -> some View {
        VStack(spacing: 12) {
            // Progress dots
            progressIndicator(
                currentStep: session.currentStepIndex,
                totalSteps: task.stepCount
            )

            // Instruction
            HStack(spacing: 12) {
                stepIcon(for: step.actionType)
                    .font(.title2)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Step \(session.currentStepIndex + 1) of \(task.stepCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(step.instruction)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        session.skip()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Progress Indicator

    @ViewBuilder
    private func progressIndicator(currentStep: Int, totalSteps: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(height: 4)
                    .matchedGeometryEffect(
                        id: "progress_\(index)",
                        in: animation
                    )
            }
        }
    }

    // MARK: - Step Icon

    private func stepIcon(for actionType: QuickWinStep.ActionType) -> Image {
        switch actionType {
        case .tap:
            Image(systemName: "hand.tap")
        case .input:
            Image(systemName: "keyboard")
        case .navigate:
            Image(systemName: "arrow.right.circle")
        }
    }
}
```

## SpotlightHintView.swift

```swift
import SwiftUI

/// Overlay that cuts out a spotlight circle around a target view,
/// dimming everything else. Shows an instruction callout with an
/// arrow pointing to the target.
///
/// Usage:
/// ```swift
/// // 1. Mark target views with preference key
/// Button("Add") { }
///     .quickWinTarget(id: "addButton")
///
/// // 2. Show spotlight
/// SpotlightHintView(
///     targetID: "addButton",
///     instruction: "Tap here to create your first item"
/// )
/// ```
struct SpotlightHintView: View {
    let targetID: String
    let instruction: String
    var onTapTarget: (() -> Void)?

    @State private var targetFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed background with spotlight cutout
                spotlightMask(in: geometry.size)
                    .onTapGesture {
                        // Tapping the spotlight area triggers the action
                        if targetFrame.contains(CGPoint(x: targetFrame.midX, y: targetFrame.midY)) {
                            onTapTarget?()
                        }
                    }

                // Instruction callout
                calloutView
                    .position(calloutPosition(in: geometry.size))
            }
        }
        .ignoresSafeArea()
        .onPreferenceChange(QuickWinTargetPreferenceKey.self) { targets in
            if let frame = targets[targetID] {
                withAnimation(.easeInOut(duration: 0.3)) {
                    targetFrame = frame
                }
            }
        }
    }

    // MARK: - Spotlight Mask

    @ViewBuilder
    private func spotlightMask(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            // Full dimmed overlay
            context.fill(
                Path(CGRect(origin: .zero, size: canvasSize)),
                with: .color(.black.opacity(0.6))
            )

            // Cut out spotlight circle
            let spotlightRadius: CGFloat = max(targetFrame.width, targetFrame.height) * 0.75 + 16
            let center = CGPoint(x: targetFrame.midX, y: targetFrame.midY)
            let spotlightRect = CGRect(
                x: center.x - spotlightRadius,
                y: center.y - spotlightRadius,
                width: spotlightRadius * 2,
                height: spotlightRadius * 2
            )

            context.blendMode = .destinationOut
            context.fill(
                Path(ellipseIn: spotlightRect),
                with: .color(.white)
            )
        }
        .compositingGroup()
        .allowsHitTesting(true)
    }

    // MARK: - Callout

    @ViewBuilder
    private var calloutView: some View {
        VStack(spacing: 8) {
            Text(instruction)
                .font(.callout.weight(.medium))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor)
                }

            // Arrow pointing to target
            Image(systemName: arrowDirection)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
        }
    }

    // MARK: - Positioning

    private var arrowDirection: String {
        // Arrow points down if callout is above target, up otherwise
        targetFrame.minY > 200 ? "arrow.down" : "arrow.up"
    }

    private func calloutPosition(in containerSize: CGSize) -> CGPoint {
        let x = min(max(targetFrame.midX, 100), containerSize.width - 100)
        let isAbove = targetFrame.minY > 200
        let y = isAbove
            ? targetFrame.minY - 80
            : targetFrame.maxY + 80
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Target Preference Key

/// Preference key that collects the frames of quick win target views.
struct QuickWinTargetPreferenceKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Target View Modifier

extension View {
    /// Marks this view as a quick win spotlight target.
    ///
    /// ```swift
    /// Button("Add") { }
    ///     .quickWinTarget(id: "addButton")
    /// ```
    func quickWinTarget(id: String) -> some View {
        self.background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: QuickWinTargetPreferenceKey.self,
                    value: [id: geometry.frame(in: .global)]
                )
            }
        }
    }
}
```

## QuickWinCelebrationView.swift

```swift
import SwiftUI

/// Compact celebration displayed when the user completes a quick win.
///
/// Shows an animated checkmark, congratulations message,
/// completion time stat, and a Continue CTA.
///
/// Usage:
/// ```swift
/// if session.isCompleted {
///     QuickWinCelebrationView(
///         taskTitle: session.completedTask?.title ?? "",
///         completionTime: session.completionTimeSeconds,
///         onContinue: { session.currentTask = nil }
///     )
/// }
/// ```
struct QuickWinCelebrationView: View {
    let taskTitle: String
    let completionTime: TimeInterval
    var onContinue: (() -> Void)?

    @State private var showCheckmark = false
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 20) {
            // Animated checkmark
            checkmarkAnimation

            // Message
            if showContent {
                messageContent
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                showCheckmark = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Checkmark

    @ViewBuilder
    private var checkmarkAnimation: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 80, height: 80)

            Circle()
                .strokeBorder(Color.green, lineWidth: 3)
                .frame(width: 80, height: 80)

            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.green)
                .scaleEffect(showCheckmark ? 1.0 : 0.3)
                .opacity(showCheckmark ? 1.0 : 0.0)
        }
    }

    // MARK: - Message Content

    @ViewBuilder
    private var messageContent: some View {
        VStack(spacing: 12) {
            Text("Great job!")
                .font(.title2.bold())

            Text(taskTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Completion time stat
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Completed in \(formattedTime)")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            // Continue button
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    onContinue?()
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
    }

    // MARK: - Formatting

    private var formattedTime: String {
        let seconds = Int(completionTime)
        if seconds < 60 {
            return "\(seconds) seconds"
        } else {
            let minutes = seconds / 60
            let remaining = seconds % 60
            return "\(minutes)m \(remaining)s"
        }
    }
}
```

## QuickWinModifier.swift

```swift
import SwiftUI

/// ViewModifier that triggers a quick win session for new users.
///
/// Attaches to the root view and checks whether the user has
/// already completed the specified quick win. If not, it presents
/// the guide overlay and celebration on completion.
///
/// Usage:
/// ```swift
/// ContentView()
///     .quickWinSession(task: .createFirstNote)
/// ```
struct QuickWinModifier: ViewModifier {
    let task: QuickWinTask
    var guidanceStyle: GuidanceStyle

    @State private var session = QuickWinSession()

    enum GuidanceStyle {
        case stepByStep
        case spotlight
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if session.isActive {
                    quickWinOverlay
                }
            }
            .overlay {
                if session.isCompleted {
                    celebrationOverlay
                }
            }
            .onAppear {
                if !session.hasCompletedQuickWin(id: task.id) {
                    session.start(task: task)
                }
            }
            .environment(session)
    }

    // MARK: - Overlays

    @ViewBuilder
    private var quickWinOverlay: some View {
        switch guidanceStyle {
        case .stepByStep:
            QuickWinGuideView(session: session)

        case .spotlight:
            if let step = session.currentStep {
                SpotlightHintView(
                    targetID: step.targetView,
                    instruction: step.instruction
                ) {
                    withAnimation {
                        session.completeCurrentStep()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            QuickWinCelebrationView(
                taskTitle: session.completedTask?.title ?? "",
                completionTime: session.completionTimeSeconds
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    session = QuickWinSession()
                }
            }
        }
        .transition(.opacity)
    }
}

// MARK: - View Extension

extension View {
    /// Attach a quick win session to this view.
    ///
    /// The quick win will activate for new users and show a guided
    /// overlay. Returning users who have already completed it will
    /// see nothing.
    ///
    /// ```swift
    /// ContentView()
    ///     .quickWinSession(task: .createFirstNote)
    /// ```
    func quickWinSession(
        task: QuickWinTask,
        style: QuickWinModifier.GuidanceStyle = .stepByStep
    ) -> some View {
        modifier(QuickWinModifier(task: task, guidanceStyle: style))
    }

    /// Attach a quick win overlay driven by an external session.
    ///
    /// Use this when you manage the session lifecycle yourself
    /// (e.g., starting the session after an existing onboarding flow).
    ///
    /// ```swift
    /// MainView()
    ///     .quickWinOverlay(session: session)
    /// ```
    func quickWinOverlay(
        session: QuickWinSession,
        style: QuickWinModifier.GuidanceStyle = .stepByStep
    ) -> some View {
        self
            .overlay {
                if session.isActive {
                    switch style {
                    case .stepByStep:
                        QuickWinGuideView(session: session)
                    case .spotlight:
                        if let step = session.currentStep {
                            SpotlightHintView(
                                targetID: step.targetView,
                                instruction: step.instruction
                            ) {
                                withAnimation {
                                    session.completeCurrentStep()
                                }
                            }
                        }
                    }
                }
            }
            .overlay {
                if session.isCompleted {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        QuickWinCelebrationView(
                            taskTitle: session.completedTask?.title ?? "",
                            completionTime: session.completionTimeSeconds
                        )
                    }
                    .transition(.opacity)
                }
            }
    }
}
```
