# Live Activity Code Templates

Production-ready Swift templates for ActivityKit Live Activities. All code targets iOS 16.1+ and uses modern Swift concurrency.

## ActivityAttributes Definition

The attributes struct is shared between the main app target and the widget extension target.

```swift
import ActivityKit
import Foundation

/// Defines the static and dynamic data for the Live Activity.
///
/// - Static properties (on the struct itself): Set once when the activity starts.
/// - Dynamic properties (in ContentState): Updated throughout the activity lifetime.
struct DeliveryActivityAttributes: ActivityAttributes {

    // MARK: - Content State (Dynamic)

    /// The dynamic data that changes over the lifetime of the Live Activity.
    struct ContentState: Codable, Hashable {
        /// Current delivery status.
        var status: DeliveryStatus
        /// Estimated delivery time.
        var estimatedDelivery: Date
        /// Name of the delivery driver (nil until assigned).
        var driverName: String?
    }

    // MARK: - Static Properties

    /// The order number displayed throughout the activity.
    var orderNumber: String
    /// The name of the restaurant.
    var restaurantName: String
}

// MARK: - Status Enum

/// Represents the stages of a delivery.
enum DeliveryStatus: String, Codable, Hashable {
    case placed
    case preparing
    case enRoute
    case delivered

    /// Human-readable label for display.
    var label: String {
        switch self {
        case .placed: return "Order Placed"
        case .preparing: return "Preparing"
        case .enRoute: return "On the Way"
        case .delivered: return "Delivered"
        }
    }

    /// SF Symbol name for each status.
    var systemImage: String {
        switch self {
        case .placed: return "checkmark.circle"
        case .preparing: return "frying.pan"
        case .enRoute: return "car.fill"
        case .delivered: return "bag.fill"
        }
    }
}
```

## Live Activity Widget View

This file lives in the widget extension target. It defines all presentation surfaces: Lock Screen, Dynamic Island compact, Dynamic Island expanded, and minimal.

```swift
import ActivityKit
import SwiftUI
import WidgetKit

/// The Live Activity configuration that provides all presentation layouts.
struct DeliveryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeliveryActivityAttributes.self) { context in

            // MARK: - Lock Screen / StandBy Presentation

            LockScreenView(context: context)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Regions

                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }

                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }

            } compactLeading: {
                // MARK: - Compact Leading
                CompactLeadingView(context: context)

            } compactTrailing: {
                // MARK: - Compact Trailing
                CompactTrailingView(context: context)

            } minimal: {
                // MARK: - Minimal
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Lock Screen View

/// The primary Lock Screen and StandBy presentation.
private struct LockScreenView: View {
    let context: ActivityViewContext<DeliveryActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: context.state.status.systemImage)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.blue.gradient, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.status.label)
                    .font(.headline)

                Text(context.attributes.restaurantName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.estimatedDelivery, style: .timer)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.blue)

                if let driver = context.state.driverName {
                    Text(driver)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Dynamic Island Expanded Views

/// Leading region of the expanded Dynamic Island.
private struct ExpandedLeadingView: View {
    let context: ActivityViewContext<DeliveryActivityAttributes>

    var body: some View {
        Image(systemName: context.state.status.systemImage)
            .font(.title2)
            .foregroundStyle(.blue)
    }
}

/// Trailing region of the expanded Dynamic Island.
private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<DeliveryActivityAttributes>

    var body: some View {
        Text(context.state.estimatedDelivery, style: .timer)
            .font(.callout.monospacedDigit())
            .foregroundStyle(.blue)
            .multilineTextAlignment(.trailing)
    }
}

/// Center region of the expanded Dynamic Island.
private struct ExpandedCenterView: View {
    let context: ActivityViewContext<DeliveryActivityAttributes>

    var body: some View {
        VStack(spacing: 2) {
            Text(context.state.status.label)
                .font(.headline)

            Text("Order #\(context.attributes.orderNumber)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// Bottom region of the expanded Dynamic Island.
private struct ExpandedBottomView: View {
    let context: ActivityViewContext<DeliveryActivityAttributes>

    var body: some View {
        HStack {
            Text(context.attributes.restaurantName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if let driver = context.state.driverName {
                Label(driver, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Dynamic Island Compact Views

/// Compact leading view -- shown in the left pill of the Dynamic Island.
private struct CompactLeadingView: View {
    let context: ActivityViewContext<DeliveryActivityAttributes>

    var body: some View {
        Image(systemName: context.state.status.systemImage)
            .foregroundStyle(.blue)
    }
}

/// Compact trailing view -- shown in the right pill of the Dynamic Island.
private struct CompactTrailingView: View {
    let context: ActivityViewContext<DeliveryActivityAttributes>

    var body: some View {
        Text(context.state.estimatedDelivery, style: .timer)
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.blue)
    }
}

// MARK: - Minimal View

/// Minimal presentation -- shown when multiple Live Activities are active.
private struct MinimalView: View {
    let context: ActivityViewContext<DeliveryActivityAttributes>

    var body: some View {
        Image(systemName: context.state.status.systemImage)
            .foregroundStyle(.blue)
    }
}

// MARK: - Previews

#if DEBUG
struct DeliveryLiveActivity_Previews: PreviewProvider {
    static let attributes = DeliveryActivityAttributes(
        orderNumber: "1234",
        restaurantName: "Pizza Place"
    )

    static let contentState = DeliveryActivityAttributes.ContentState(
        status: .enRoute,
        estimatedDelivery: Date().addingTimeInterval(15 * 60),
        driverName: "Alex"
    )

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Lock Screen")

        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Compact")

        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Expanded")

        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
    }
}
#endif
```

## Activity Lifecycle Manager

This file lives in the main app target. It provides a protocol-based interface for starting, updating, and ending Live Activities.

### Protocol

```swift
import ActivityKit
import Foundation

/// Protocol defining Live Activity lifecycle operations.
///
/// Use this protocol to abstract activity management for testing and
/// to swap implementations (e.g., mock manager in previews).
protocol LiveActivityManaging: Sendable {
    associatedtype Attributes: ActivityAttributes

    /// Start a new Live Activity.
    /// - Parameters:
    ///   - attributes: Static attributes for the activity.
    ///   - state: Initial content state.
    ///   - staleDate: Optional date after which the system considers the content stale.
    /// - Returns: The activity ID string.
    @discardableResult
    func startActivity(
        attributes: Attributes,
        state: Attributes.ContentState,
        staleDate: Date?
    ) async throws -> String

    /// Update the currently running Live Activity.
    /// - Parameters:
    ///   - state: New content state.
    ///   - alertConfiguration: Optional alert to display with the update.
    ///   - staleDate: Optional new stale date.
    func updateActivity(
        state: Attributes.ContentState,
        alertConfiguration: AlertConfiguration?,
        staleDate: Date?
    ) async

    /// End the currently running Live Activity.
    /// - Parameters:
    ///   - state: Final content state to display.
    ///   - dismissalPolicy: When the system should remove the activity from the Lock Screen.
    ///   - alertConfiguration: Optional alert to display when ending.
    func endActivity(
        state: Attributes.ContentState?,
        dismissalPolicy: ActivityUIDismissalPolicy,
        alertConfiguration: AlertConfiguration?
    ) async

    /// End all running Live Activities for this attribute type.
    func endAllActivities() async

    /// The push token for the current activity, if available.
    var currentPushToken: Data? { get }

    /// Whether a Live Activity is currently running.
    var isActivityActive: Bool { get }
}

// MARK: - Default Parameter Values

extension LiveActivityManaging {
    @discardableResult
    func startActivity(
        attributes: Attributes,
        state: Attributes.ContentState,
        staleDate: Date? = nil
    ) async throws -> String {
        try await startActivity(attributes: attributes, state: state, staleDate: staleDate)
    }

    func updateActivity(
        state: Attributes.ContentState,
        alertConfiguration: AlertConfiguration? = nil,
        staleDate: Date? = nil
    ) async {
        await updateActivity(state: state, alertConfiguration: alertConfiguration, staleDate: staleDate)
    }

    func endActivity(
        state: Attributes.ContentState? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy = .default,
        alertConfiguration: AlertConfiguration? = nil
    ) async {
        await endActivity(state: state, dismissalPolicy: dismissalPolicy, alertConfiguration: alertConfiguration)
    }
}
```

### Concrete Implementation

```swift
import ActivityKit
import Foundation
import os.log

/// Manages the lifecycle of a Live Activity for the given attributes type.
///
/// Usage:
/// ```swift
/// let manager = LiveActivityManager<DeliveryActivityAttributes>()
/// try await manager.startActivity(attributes: attributes, state: initialState)
/// ```
@MainActor
final class LiveActivityManager<Attributes: ActivityAttributes>: LiveActivityManaging {

    // MARK: - Properties

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "LiveActivity")

    /// The currently running activity, if any.
    private(set) var currentActivity: Activity<Attributes>?

    /// Task that observes push token updates.
    private var pushTokenTask: Task<Void, Never>?

    /// Callback invoked when the push token changes. Send this token to your server.
    var onPushTokenUpdate: ((Data) -> Void)?

    /// The current push token for the running activity.
    var currentPushToken: Data? {
        currentActivity?.pushToken
    }

    /// Whether a Live Activity is currently active.
    var isActivityActive: Bool {
        guard let currentActivity else { return false }
        return currentActivity.activityState == .active
    }

    // MARK: - Initialization

    init() {}

    deinit {
        pushTokenTask?.cancel()
    }

    // MARK: - Start

    /// Start a new Live Activity.
    @discardableResult
    func startActivity(
        attributes: Attributes,
        state: Attributes.ContentState,
        staleDate: Date? = nil
    ) async throws -> String {

        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.error("Live Activities are not enabled on this device.")
            throw LiveActivityError.activitiesNotEnabled
        }

        // End any existing activity before starting a new one
        if currentActivity != nil {
            await endActivity()
        }

        let content = ActivityContent(
            state: state,
            staleDate: staleDate
        )

        let activity = try Activity.request(
            attributes: attributes,
            content: content,
            pushType: .token  // Remove this parameter if not using push updates
        )

        currentActivity = activity
        logger.info("Started Live Activity: \(activity.id)")

        // Begin observing push token updates
        observePushTokenUpdates(for: activity)

        return activity.id
    }

    // MARK: - Update

    /// Update the running Live Activity with new state.
    func updateActivity(
        state: Attributes.ContentState,
        alertConfiguration: AlertConfiguration? = nil,
        staleDate: Date? = nil
    ) async {

        guard let currentActivity else {
            logger.warning("No active Live Activity to update.")
            return
        }

        let content = ActivityContent(
            state: state,
            staleDate: staleDate
        )

        await currentActivity.update(
            content,
            alertConfiguration: alertConfiguration
        )

        logger.info("Updated Live Activity: \(currentActivity.id)")
    }

    // MARK: - End

    /// End the running Live Activity.
    func endActivity(
        state: Attributes.ContentState? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy = .default,
        alertConfiguration: AlertConfiguration? = nil
    ) async {

        guard let currentActivity else {
            logger.warning("No active Live Activity to end.")
            return
        }

        let finalContent: ActivityContent<Attributes.ContentState>?
        if let state {
            finalContent = ActivityContent(state: state, staleDate: nil)
        } else {
            finalContent = nil
        }

        await currentActivity.end(
            finalContent,
            dismissalPolicy: dismissalPolicy
        )

        logger.info("Ended Live Activity: \(currentActivity.id)")
        pushTokenTask?.cancel()
        pushTokenTask = nil
        self.currentActivity = nil
    }

    /// End all running Live Activities for this attribute type.
    func endAllActivities() async {
        for activity in Activity<Attributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
            logger.info("Ended activity: \(activity.id)")
        }

        pushTokenTask?.cancel()
        pushTokenTask = nil
        currentActivity = nil
    }

    // MARK: - Push Token Observation

    /// Observe push token updates for the given activity.
    /// The push token can change during the activity lifetime; always send the latest to your server.
    private func observePushTokenUpdates(for activity: Activity<Attributes>) {
        pushTokenTask?.cancel()

        pushTokenTask = Task {
            for await token in activity.pushTokenUpdates {
                let tokenString = token.map { String(format: "%02x", $0) }.joined()
                logger.info("Push token updated: \(tokenString)")

                onPushTokenUpdate?(token)
            }
        }
    }

    // MARK: - Query

    /// Returns all currently running activities for this attribute type.
    func allActivities() -> [Activity<Attributes>] {
        Activity<Attributes>.activities
    }

    /// Check if Live Activities are enabled on this device.
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
}

// MARK: - Errors

/// Errors that can occur during Live Activity lifecycle management.
enum LiveActivityError: LocalizedError {
    case activitiesNotEnabled
    case activityNotFound
    case startFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .activitiesNotEnabled:
            return "Live Activities are not enabled. The user may have disabled them in Settings."
        case .activityNotFound:
            return "No active Live Activity was found."
        case .startFailed(let error):
            return "Failed to start Live Activity: \(error.localizedDescription)"
        }
    }
}
```

### Alert Configuration Helper

```swift
import ActivityKit

/// Convenience factory for creating alert configurations.
///
/// Alerts are displayed on the Lock Screen when an activity is updated or ended.
/// They are only shown when the device is locked.
enum LiveActivityAlertBuilder {

    /// Create an alert configuration for an activity update.
    /// - Parameters:
    ///   - title: The alert title shown on the Lock Screen.
    ///   - body: The alert body text.
    ///   - sound: The alert sound. Defaults to `.default`.
    /// - Returns: An `AlertConfiguration` instance.
    static func updateAlert(
        title: String,
        body: String,
        sound: AlertConfiguration.AlertSound = .default
    ) -> AlertConfiguration {
        AlertConfiguration(
            title: LocalizedStringResource(stringLiteral: title),
            body: LocalizedStringResource(stringLiteral: body),
            sound: sound
        )
    }

    /// Create an alert configuration for ending an activity.
    static func endAlert(
        title: String,
        body: String,
        sound: AlertConfiguration.AlertSound = .default
    ) -> AlertConfiguration {
        AlertConfiguration(
            title: LocalizedStringResource(stringLiteral: title),
            body: LocalizedStringResource(stringLiteral: body),
            sound: sound
        )
    }
}
```

## Authorization Observation

Observe whether the user has enabled or disabled Live Activities in Settings.

```swift
import ActivityKit
import Foundation

/// Observes Live Activity authorization changes.
///
/// Use this to update your UI when the user toggles Live Activities in Settings.
@MainActor
@Observable
final class LiveActivityAuthObserver {

    /// Whether Live Activities are currently enabled.
    private(set) var areActivitiesEnabled: Bool

    private var observationTask: Task<Void, Never>?

    init() {
        let authInfo = ActivityAuthorizationInfo()
        areActivitiesEnabled = authInfo.areActivitiesEnabled

        observationTask = Task {
            for await enabled in authInfo.activityEnablementUpdates {
                self.areActivitiesEnabled = enabled
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }
}
```

## SwiftUI Integration View

A reusable SwiftUI view that shows activity status and provides controls.

```swift
import SwiftUI
import ActivityKit

/// A view that displays the current Live Activity state and provides controls.
///
/// Usage:
/// ```swift
/// LiveActivityControlView(manager: deliveryActivityManager)
/// ```
struct LiveActivityControlView<Attributes: ActivityAttributes>: View {
    let manager: LiveActivityManager<Attributes>

    @State private var authObserver = LiveActivityAuthObserver()

    var body: some View {
        Group {
            if !authObserver.areActivitiesEnabled {
                ContentUnavailableView(
                    "Live Activities Disabled",
                    systemImage: "bell.slash",
                    description: Text("Enable Live Activities in Settings to see real-time updates on your Lock Screen and Dynamic Island.")
                )
            } else if manager.isActivityActive {
                activeActivityView
            } else {
                noActivityView
            }
        }
    }

    private var activeActivityView: some View {
        VStack(spacing: 16) {
            Label("Live Activity Running", systemImage: "dot.radiowaves.left.and.right")
                .font(.headline)
                .foregroundStyle(.green)

            if let activityId = manager.currentActivity?.id {
                Text("ID: \(activityId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("End Activity", role: .destructive) {
                Task {
                    await manager.endActivity(dismissalPolicy: .immediate)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var noActivityView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No Active Live Activity")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

## Widget Bundle Integration

If the project already has a widget bundle, add the Live Activity to it.

```swift
import SwiftUI
import WidgetKit

@main
struct MyAppWidgets: WidgetBundle {
    var body: some Widget {
        // Existing widgets
        MyHomeScreenWidget()

        // Live Activity
        DeliveryLiveActivity()
    }
}
```

If the widget extension only contains the Live Activity, the `@main` attribute can go directly on the `Widget` struct:

```swift
@main
struct DeliveryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeliveryActivityAttributes.self) { context in
            // Lock Screen view...
        } dynamicIsland: { context in
            // Dynamic Island views...
        }
    }
}
```

## Push-to-Update Server Payload Reference

### Update Payload

```json
{
  "aps": {
    "timestamp": 1234567890,
    "event": "update",
    "content-state": {
      "status": "enRoute",
      "estimatedDelivery": 1234568000,
      "driverName": "Alex"
    },
    "stale-date": 1234569000,
    "alert": {
      "title": "Order Update",
      "body": "Your driver Alex is on the way!"
    }
  }
}
```

### End Payload

```json
{
  "aps": {
    "timestamp": 1234567890,
    "event": "end",
    "dismissal-date": 1234571490,
    "content-state": {
      "status": "delivered",
      "estimatedDelivery": 1234567890,
      "driverName": "Alex"
    },
    "alert": {
      "title": "Delivered!",
      "body": "Your order from Pizza Place has arrived."
    }
  }
}
```

### Key Fields

| Field | Required | Description |
|-------|----------|-------------|
| `timestamp` | Yes | Unix timestamp (seconds). Must be greater than previous update. |
| `event` | Yes | `"update"` or `"end"`. |
| `content-state` | Yes | Must match the `ContentState` Codable structure exactly. |
| `stale-date` | No | Unix timestamp after which the system considers content stale. |
| `dismissal-date` | No | Unix timestamp when the ended activity should be removed from Lock Screen. |
| `alert` | No | Lock Screen alert shown with the update. Only shown when device is locked. |

### APNs Headers

| Header | Value |
|--------|-------|
| `apns-topic` | `{bundle-id}.push-type.liveactivity` |
| `apns-push-type` | `liveactivity` |
| `apns-priority` | `5` (low) or `10` (high, for time-sensitive updates) |

## Patterns: Good and Bad

### Starting Activities

```swift
// ✅ Good: Check authorization before starting
guard ActivityAuthorizationInfo().areActivitiesEnabled else {
    showEnableActivitiesPrompt()
    return
}
let activity = try Activity.request(attributes: attrs, content: content, pushType: .token)

// ❌ Bad: Start without checking authorization
let activity = try Activity.request(attributes: attrs, content: content, pushType: .token)
```

### Push Token Handling

```swift
// ✅ Good: Continuously observe token changes
for await token in activity.pushTokenUpdates {
    await sendTokenToServer(token)
}

// ❌ Bad: Read token once and assume it stays the same
let token = activity.pushToken
sendTokenToServer(token)
```

### Ending Activities

```swift
// ✅ Good: Provide final state when ending
await activity.end(
    ActivityContent(state: finalState, staleDate: nil),
    dismissalPolicy: .after(Date().addingTimeInterval(4 * 3600))
)

// ❌ Bad: End with nil content, leaving stale data displayed
await activity.end(nil, dismissalPolicy: .default)
```

### Content State Size

```swift
// ✅ Good: Keep ContentState small and Codable
struct ContentState: Codable, Hashable {
    var score: Int
    var timeRemaining: TimeInterval
    var statusMessage: String
}

// ❌ Bad: Large or complex data in ContentState
struct ContentState: Codable, Hashable {
    var allPlayerStats: [PlayerStats]  // Array can easily exceed 4KB
    var fullGameLog: String            // Unbounded string
    var imageData: Data                // Binary data
}
```

### Stale Dates

```swift
// ✅ Good: Set a stale date so the system can indicate outdated content
let content = ActivityContent(
    state: state,
    staleDate: Date().addingTimeInterval(15 * 60)
)

// ❌ Bad: No stale date; user sees outdated data with no indication
let content = ActivityContent(state: state, staleDate: nil)
```
