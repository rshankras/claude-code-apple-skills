---
name: alarmkit
description: AlarmKit integration for scheduling alarms and timers with custom UI, Live Activities, and snooze support. Use when implementing alarm or timer features in iOS 18+ apps.
allowed-tools: [Read, Glob, Grep]
---

# AlarmKit

Framework for scheduling alarms and countdown timers with custom UI, Live Activities integration, and focus/silent mode override. Prevents the most common mistakes: using the wrong authorization property name, omitting the Info.plist key, and forgetting the widget extension for countdown presentations.

## When This Skill Activates

Use this skill when the user:
- Asks to add, fix, or review **alarm** or **timer** functionality
- Mentions **AlarmKit**, **AlarmManager**, or **AlarmPresentation**
- Wants to schedule **one-time**, **repeating**, or **countdown** alarms
- Asks about **snooze**, **stop**, or **repeat** buttons on alarm alerts
- Wants alarms to appear on **Dynamic Island** or **Lock Screen** (Live Activities)
- Mentions overriding **Focus** or **silent mode** for alarms
- Asks about **AlarmAttributes** or **AlarmMetadata**

## Decision Tree

Choose the right reference file based on what the user needs:

```
What do you need?
|
+-- Schedule an alarm (one-time, repeating, or timer)
|   --> scheduling.md
|       +-- One-time alarm: Alarm.Schedule.relative + .repeats: .never
|       +-- Repeating alarm: Alarm.Schedule.relative + .repeats: .weekly(weekdays)
|       +-- Countdown timer: CountdownDuration (no schedule)
|       +-- Authorization & Info.plist setup
|       +-- Managing alarms: pause, resume, cancel
|
+-- Customize alarm UI (alert, countdown, paused screens)
|   --> presentation.md
|       +-- AlarmPresentation.Alert: title, stop, snooze/repeat buttons
|       +-- AlarmPresentation.Countdown: title, pause button
|       +-- AlarmPresentation.Paused: title, resume button
|       +-- Custom buttons with AlarmButton
|       +-- Tint color and metadata via AlarmAttributes
|
+-- Show alarm on Dynamic Island / Lock Screen
    --> live-activities.md
        +-- Widget extension with ActivityConfiguration
        +-- AlarmAttributes conformance
        +-- Custom AlarmMetadata protocol
```

## API Availability

| API | Minimum Version | Reference |
|-----|----------------|-----------|
| `AlarmManager` | iOS 18 | scheduling.md |
| `Alarm` / `Alarm.Schedule` | iOS 18 | scheduling.md |
| `AlarmPresentation` (.alert, .countdown, .paused) | iOS 18 | presentation.md |
| `AlarmAttributes` | iOS 18 | live-activities.md |
| `AlarmMetadata` | iOS 18 | live-activities.md |
| `AlarmButton` | iOS 18 | presentation.md |
| `CountdownDuration` | iOS 18 | scheduling.md |
| `alarmUpdates` async sequence | iOS 18 | scheduling.md |
| `authorizationUpdates` async sequence | iOS 18 | scheduling.md |

## Top Mistakes -- Quick Reference

| # | Mistake | Fix | Details |
|---|---------|-----|---------|
| 1 | Using `.authorizationStatus` instead of `.authorizationState` | The property is `AlarmManager.shared.authorizationState` -- there is no `authorizationStatus` | scheduling.md |
| 2 | Forgetting `NSAlarmKitUsageDescription` in Info.plist | Add the key with a user-facing string before calling `requestAuthorization()` | scheduling.md |
| 3 | Creating countdown timer with a schedule | Timers use `CountdownDuration` only -- do not pass a schedule | scheduling.md |
| 4 | Missing widget extension for countdown presentations | Countdown and paused UI requires an `ActivityConfiguration(for: AlarmAttributes.self)` widget | live-activities.md |
| 5 | Not persisting alarm UUIDs | Store the `Alarm.id` (UUID) so you can pause, resume, or cancel later | scheduling.md |
| 6 | Not observing `alarmUpdates` for state sync | Use the `alarmUpdates` async sequence to keep local state in sync with the system | scheduling.md |

## Review Checklist

When reviewing AlarmKit code, verify:

- [ ] **Info.plist** -- `NSAlarmKitUsageDescription` is present with a meaningful description
- [ ] **Authorization** -- `requestAuthorization()` is called before scheduling; denial is handled gracefully
- [ ] **Correct property** -- uses `.authorizationState`, not `.authorizationStatus`
- [ ] **Alarm ID persistence** -- alarm UUIDs are stored (e.g., UserDefaults, SwiftData) for later management
- [ ] **State observation** -- `alarmUpdates` async sequence is used to keep UI in sync
- [ ] **Widget extension** -- exists if countdown or paused presentations are used
- [ ] **Error handling** -- `schedule()`, `pause()`, `resume()`, `cancel()` calls handle errors
- [ ] **System limits** -- code accounts for the system limit on number of active alarms
- [ ] **Real device testing** -- alarms are tested on physical devices, not just Simulator

## Reference Files

| File | Content |
|------|---------|
| [scheduling.md](scheduling.md) | Authorization, one-time/repeating/timer creation, managing alarms, observing updates |
| [presentation.md](presentation.md) | Alert, countdown, paused UI customization, buttons, tint color |
| [live-activities.md](live-activities.md) | Widget extension, AlarmAttributes, AlarmMetadata, Dynamic Island |
