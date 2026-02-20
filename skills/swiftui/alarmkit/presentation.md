# Alarm Presentation

Customizing the alarm UI for alert, countdown, and paused states. Includes button configuration, tint color, and AlarmAttributes.

## Presentation States

AlarmKit defines three presentation states. Each state has its own UI configuration type.

| State | Type | When Shown |
|-------|------|------------|
| Alert | `AlarmPresentation.Alert` | Alarm fires or timer reaches zero |
| Countdown | `AlarmPresentation.Countdown` | Timer is counting down (before alert) |
| Paused | `AlarmPresentation.Paused` | Timer is paused by the user |

## AlarmPresentation.Alert

The alert state is shown when an alarm fires. It always has a title and a stop button, with an optional secondary button.

### Basic Alert

```swift
AlarmPresentation.Alert(
    title: "Wake Up!",
    stopButton: AlarmButton(label: "Stop")
)
```

### Alert with Snooze

```swift
AlarmPresentation.Alert(
    title: "Morning Alarm",
    stopButton: AlarmButton(label: "Stop"),
    secondaryButton: .snoozeButton()
)
```

### Alert with Open App Button

```swift
AlarmPresentation.Alert(
    title: "Meditation Time",
    stopButton: AlarmButton(label: "Dismiss"),
    secondaryButton: .openAppButton()
)
```

### Alert with Repeat Button

Useful for timers that the user may want to restart immediately.

```swift
AlarmPresentation.Alert(
    title: "Time's Up!",
    stopButton: AlarmButton(label: "Done"),
    secondaryButton: .repeatButton()
)
```

### Secondary Button Types

| Factory Method | Behavior |
|---------------|----------|
| `.snoozeButton()` | Snoozes the alarm for the system default duration |
| `.openAppButton()` | Dismisses the alarm and opens your app |
| `.repeatButton()` | Repeats the alarm/timer |

### Secondary Button Behavior

The `secondaryButtonBehavior` parameter controls what happens visually when the secondary button is tapped:

```swift
AlarmPresentation.Alert(
    title: "Cooking Timer",
    stopButton: AlarmButton(label: "Stop"),
    secondaryButton: .snoozeButton(),
    secondaryButtonBehavior: .countdown  // Shows a countdown after snooze
)
```

| Behavior | Effect |
|----------|--------|
| `.countdown` | Shows a countdown until the alarm fires again |
| `.custom` | Custom handling -- your app controls the behavior |

### Custom Buttons

Create buttons with custom labels using `AlarmButton`:

```swift
AlarmPresentation.Alert(
    title: "Study Break",
    stopButton: AlarmButton(label: "End Session"),
    secondaryButton: .snoozeButton()
)
```

## AlarmPresentation.Countdown

Shown while a timer is actively counting down. Requires a widget extension to render on the Lock Screen and Dynamic Island.

```swift
AlarmPresentation.Countdown(
    title: "Cooking Timer",
    pauseButton: AlarmButton(label: "Pause")
)
```

The countdown UI displays the remaining time automatically. You only configure the title and pause button.

## AlarmPresentation.Paused

Shown when a countdown timer has been paused by the user.

```swift
AlarmPresentation.Paused(
    title: "Timer Paused",
    resumeButton: AlarmButton(label: "Resume")
)
```

## AlarmAttributes

`AlarmAttributes` bundles all presentation information together. It includes the presentations, optional metadata, and a tint color.

### Tint Color

Apply a tint color to the alarm UI:

```swift
try await AlarmManager.shared.schedule(id: alarmID) {
    // ... schedule and presentations ...

    AlarmAttributes(tintColor: .blue)
}
```

### Complete Configuration Example

A fully configured timer with all three presentation states and a tint color:

```swift
func scheduleFullTimer() async throws -> Alarm {
    let alarmID = UUID()

    let alarm = try await AlarmManager.shared.schedule(id: alarmID) {
        CountdownDuration(preAlert: 1800, postAlert: 120)

        AlarmPresentation.Countdown(
            title: "Focus Session",
            pauseButton: AlarmButton(label: "Pause")
        )

        AlarmPresentation.Alert(
            title: "Focus Session Complete",
            stopButton: AlarmButton(label: "Done"),
            secondaryButton: .repeatButton(),
            secondaryButtonBehavior: .countdown
        )

        AlarmPresentation.Paused(
            title: "Session Paused",
            resumeButton: AlarmButton(label: "Resume")
        )

        AlarmAttributes(tintColor: .purple)
    }

    return alarm
}
```

## Common Patterns

### Alarm-Only (No Timer)

For a simple alarm with no countdown phase, you only need the alert presentation:

```swift
try await AlarmManager.shared.schedule(id: UUID()) {
    Alarm.Schedule.relative(.repeats: .never)

    AlarmPresentation.Alert(
        title: "Reminder",
        stopButton: AlarmButton(label: "OK")
    )
}
```

### Timer with All States

For a countdown timer, provide all three presentations so the user has a complete experience:

```swift
try await AlarmManager.shared.schedule(id: UUID()) {
    CountdownDuration(preAlert: 600, postAlert: 30)

    AlarmPresentation.Countdown(
        title: "Egg Timer",
        pauseButton: AlarmButton(label: "Pause")
    )

    AlarmPresentation.Alert(
        title: "Eggs are Ready!",
        stopButton: AlarmButton(label: "Done"),
        secondaryButton: .repeatButton()
    )

    AlarmPresentation.Paused(
        title: "Egg Timer Paused",
        resumeButton: AlarmButton(label: "Resume")
    )
}
```

### Anti-Patterns

```swift
// ❌ WRONG: Countdown presentation without a widget extension
// The countdown UI will not appear on Lock Screen or Dynamic Island
// without implementing ActivityConfiguration(for: AlarmAttributes.self)
AlarmPresentation.Countdown(title: "Timer", pauseButton: AlarmButton(label: "Pause"))
// ✅ Implement the widget extension -- see live-activities.md

// ❌ WRONG: Alert without a stop button
// AlarmPresentation.Alert always requires a stopButton
AlarmPresentation.Alert(title: "Alarm")
// ✅ Always provide a stopButton
AlarmPresentation.Alert(title: "Alarm", stopButton: AlarmButton(label: "Stop"))
```
