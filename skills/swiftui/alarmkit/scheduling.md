# Scheduling Alarms and Timers

Authorization setup, creating one-time/repeating alarms and countdown timers, managing alarm lifecycle, and observing state changes.

## Authorization

### Info.plist Requirement

You **must** add `NSAlarmKitUsageDescription` to your app's Info.plist before requesting authorization. Without it, the authorization request will fail silently.

```xml
<key>NSAlarmKitUsageDescription</key>
<string>This app needs alarm access to wake you up at your scheduled times.</string>
```

### Requesting Authorization

```swift
import AlarmKit

func requestAlarmAccess() async {
    let state = await AlarmManager.shared.requestAuthorization()

    switch state {
    case .authorized:
        // Can schedule alarms
        break
    case .denied:
        // Show settings prompt to the user
        break
    case .notDetermined:
        // Should not happen after request, but handle gracefully
        break
    @unknown default:
        break
    }
}
```

### Checking Current Authorization

```swift
// ✅ Correct property name
let state = AlarmManager.shared.authorizationState

// ❌ WRONG: This property does NOT exist
let state = AlarmManager.shared.authorizationStatus
```

### Observing Authorization Changes

```swift
func observeAuthorizationChanges() async {
    for await state in AlarmManager.shared.authorizationUpdates {
        switch state {
        case .authorized:
            // Update UI to show alarm features
            break
        case .denied:
            // Hide alarm features, show explanation
            break
        default:
            break
        }
    }
}
```

## Creating Alarms

All alarms are created through `AlarmManager.shared.schedule(id:configuration:)`.

### One-Time Alarm

A single alarm that fires once and does not repeat.

```swift
import AlarmKit

func scheduleOneTimeAlarm() async throws -> Alarm {
    let alarmID = UUID()

    let alarm = try await AlarmManager.shared.schedule(id: alarmID) {
        Alarm.Schedule.relative(
            .repeats: .never
        )

        AlarmPresentation.Alert(
            title: "Wake Up!",
            stopButton: AlarmButton(label: "Stop"),
            secondaryButton: .snoozeButton()
        )
    }

    // Persist the alarm ID for later management
    UserDefaults.standard.set(alarmID.uuidString, forKey: "morningAlarmID")

    return alarm
}
```

### Repeating Alarm

An alarm that fires on specific days of the week.

```swift
func scheduleWeekdayAlarm() async throws -> Alarm {
    let alarmID = UUID()

    let alarm = try await AlarmManager.shared.schedule(id: alarmID) {
        Alarm.Schedule.relative(
            .repeats: .weekly([.monday, .tuesday, .wednesday, .thursday, .friday])
        )

        AlarmPresentation.Alert(
            title: "Time for Work",
            stopButton: AlarmButton(label: "Dismiss"),
            secondaryButton: .snoozeButton()
        )
    }

    return alarm
}
```

### Countdown Timer

Timers use `CountdownDuration` and do **not** include a schedule. The `preAlert` parameter is the countdown duration in seconds before the alert fires. The `postAlert` parameter defines an optional snooze duration.

```swift
// ✅ Timer with countdown -- no schedule
func startTimer(minutes: Int) async throws -> Alarm {
    let alarmID = UUID()

    let alarm = try await AlarmManager.shared.schedule(id: alarmID) {
        CountdownDuration(
            preAlert: TimeInterval(minutes * 60),
            postAlert: 60  // 60-second snooze after alert
        )

        AlarmPresentation.Countdown(
            title: "Timer",
            pauseButton: AlarmButton(label: "Pause")
        )

        AlarmPresentation.Alert(
            title: "Time's Up!",
            stopButton: AlarmButton(label: "Done"),
            secondaryButton: .repeatButton()
        )

        AlarmPresentation.Paused(
            title: "Timer Paused",
            resumeButton: AlarmButton(label: "Resume")
        )
    }

    return alarm
}
```

```swift
// ❌ WRONG: Do not pass a schedule with a timer
func wrongTimer() async throws -> Alarm {
    let alarmID = UUID()
    return try await AlarmManager.shared.schedule(id: alarmID) {
        Alarm.Schedule.relative(.repeats: .never)  // Wrong -- timers don't use schedules
        CountdownDuration(preAlert: 300, postAlert: 60)
        // ...
    }
}
```

## Managing Alarms

### Listing Active Alarms

```swift
let activeAlarms = AlarmManager.shared.alarms
for alarm in activeAlarms {
    print("Alarm \(alarm.id)")
}
```

### Pause, Resume, and Cancel

```swift
let alarmID: UUID = // ... retrieved from persistence

// Pause a countdown timer
try await AlarmManager.shared.pause(id: alarmID)

// Resume a paused timer
try await AlarmManager.shared.resume(id: alarmID)

// Cancel an alarm entirely
try await AlarmManager.shared.cancel(id: alarmID)
```

### Observing Alarm Updates

Use the `alarmUpdates` async sequence to keep your app's state synchronized with the system. This is the recommended way to track alarm state changes rather than polling.

```swift
func observeAlarms() async {
    for await alarms in AlarmManager.shared.alarmUpdates {
        // alarms is the updated [Alarm] array
        await MainActor.run {
            self.activeAlarms = alarms
        }
    }
}
```

## Persisting Alarm IDs

AlarmKit does not provide a way to look up alarms by custom identifiers. You must store the `UUID` returned from scheduling so you can pause, resume, or cancel alarms later.

```swift
// ✅ Persist alarm IDs
struct AlarmStore {
    private let defaults = UserDefaults.standard
    private let key = "scheduledAlarmIDs"

    func save(alarmID: UUID, label: String) {
        var stored = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        stored[alarmID.uuidString] = label
        defaults.set(stored, forKey: key)
    }

    func alarmID(for label: String) -> UUID? {
        let stored = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        return stored.first(where: { $0.value == label }).map { UUID(uuidString: $0.key)! }
    }

    func remove(alarmID: UUID) {
        var stored = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        stored.removeValue(forKey: alarmID.uuidString)
        defaults.set(stored, forKey: key)
    }
}
```

## Error Handling

Always wrap scheduling and management calls in do/catch blocks. The system imposes a limit on the number of active alarms, and calls can fail for various reasons (authorization denied, system limit reached, invalid configuration).

```swift
do {
    let alarm = try await AlarmManager.shared.schedule(id: UUID()) {
        // ... configuration
    }
} catch {
    // Handle error -- could be authorization, system limit, or invalid config
    print("Failed to schedule alarm: \(error.localizedDescription)")
}
```

## Common Patterns

### Alarm Manager View Model

```swift
import AlarmKit
import SwiftUI

@Observable
final class AlarmViewModel {
    private(set) var alarms: [Alarm] = []
    private(set) var isAuthorized = false

    func setup() async {
        let state = await AlarmManager.shared.requestAuthorization()
        isAuthorized = (state == .authorized)

        // Start observing in a detached task
        Task {
            await observeAlarms()
        }
    }

    private func observeAlarms() async {
        for await updatedAlarms in AlarmManager.shared.alarmUpdates {
            await MainActor.run {
                self.alarms = updatedAlarms
            }
        }
    }

    func cancelAlarm(id: UUID) async {
        do {
            try await AlarmManager.shared.cancel(id: id)
        } catch {
            print("Cancel failed: \(error)")
        }
    }
}
```
