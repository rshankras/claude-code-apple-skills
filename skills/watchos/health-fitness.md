# Health & Fitness on watchOS

Detailed guide for HealthKit, workout sessions, sensor data, and extended runtime on Apple Watch.

## HealthKit Authorization

### Requesting Permissions

```swift
import HealthKit

@Observable
final class HealthManager {
    let healthStore = HKHealthStore()

    var isAuthorized = false

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthError.notAvailable
        }

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.vo2Max),
            HKObjectType.workoutType()
        ]

        let typesToWrite: Set<HKSampleType> = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKObjectType.workoutType()
        ]

        try await healthStore.requestAuthorization(
            toShare: typesToWrite,
            read: typesToRead
        )

        isAuthorized = true
    }
}
```

### Info.plist Keys

Add these keys to the watchOS app's `Info.plist`:

| Key | Purpose |
|-----|---------|
| `NSHealthShareUsageDescription` | Why you read health data |
| `NSHealthUpdateUsageDescription` | Why you write health data |

### Authorization Status

```swift
func checkAuthorizationStatus(for type: HKQuantityType) -> HKAuthorizationStatus {
    healthStore.authorizationStatus(for: type)
}

// Note: HealthKit only tells you if the user has responded,
// not whether they granted or denied access (for privacy).
// .notDetermined = user hasn't been asked
// .sharingAuthorized = user allowed writing
// .sharingDenied = user denied writing
// Reading status is always .notDetermined for privacy reasons.
```

## Workout Sessions

### Complete Workout Manager

```swift
import HealthKit

@Observable
final class WorkoutManager: NSObject {
    let healthStore = HKHealthStore()

    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?

    // Real-time metrics
    var heartRate: Double = 0
    var activeCalories: Double = 0
    var distance: Double = 0
    var elapsedTime: TimeInterval = 0

    var isActive: Bool { session?.state == .running }

    // MARK: - Start Workout

    func startWorkout(type: HKWorkoutActivityType, location: HKWorkoutSessionLocationType = .outdoor) async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = type
        config.locationType = location

        session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        builder = session?.associatedWorkoutBuilder()

        session?.delegate = self
        builder?.delegate = self

        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: config
        )

        let startDate = Date.now
        session?.startActivity(with: startDate)
        try await builder?.beginCollection(at: startDate)
    }

    // MARK: - Pause / Resume / End

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func endWorkout() async throws {
        session?.end()
        try await builder?.endCollection(at: .now)
        try await builder?.finishWorkout()

        // Reset state
        session = nil
        builder = nil
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        // Handle state changes (running, paused, ended)
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        print("Workout session error: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events (pause, resume markers)
    }

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            for type in collectedTypes {
                guard let quantityType = type as? HKQuantityType else { continue }
                updateMetric(for: quantityType, from: workoutBuilder)
            }
        }
    }

    @MainActor
    private func updateMetric(for type: HKQuantityType, from builder: HKLiveWorkoutBuilder) {
        guard let statistics = builder.statistics(for: type) else { return }

        switch type {
        case HKQuantityType(.heartRate):
            let unit = HKUnit.count().unitDivided(by: .minute())
            heartRate = statistics.mostRecentQuantity()?.doubleValue(for: unit) ?? 0

        case HKQuantityType(.activeEnergyBurned):
            activeCalories = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0

        case HKQuantityType(.distanceWalkingRunning):
            distance = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0

        default:
            break
        }

        elapsedTime = builder.elapsedTime
    }
}
```

### Workout SwiftUI View

```swift
struct WorkoutView: View {
    let manager: WorkoutManager

    var body: some View {
        VStack(spacing: 8) {
            // Heart rate
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("\(Int(manager.heartRate))")
                    .font(.system(.title, design: .rounded).monospacedDigit())
                Text("BPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Calories
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(Int(manager.activeCalories))")
                    .font(.system(.title2, design: .rounded).monospacedDigit())
                Text("CAL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Distance
            HStack {
                Image(systemName: "figure.run")
                    .foregroundStyle(.green)
                Text(Measurement(value: manager.distance, unit: UnitLength.meters),
                     format: .measurement(width: .abbreviated, usage: .road))
                    .font(.system(.title2, design: .rounded).monospacedDigit())
            }

            // Elapsed time
            Text(Duration.seconds(manager.elapsedTime),
                 format: .time(pattern: .hourMinuteSecond))
                .font(.system(.title3, design: .rounded).monospacedDigit())
                .foregroundStyle(.yellow)
        }
    }
}
```

## Extended Runtime Sessions

Use `WKExtendedRuntimeSession` to keep your app running in the background for workouts, health monitoring, or self-care.

### Session Types

| Type | Duration | Use Case |
|------|----------|----------|
| `.workout` | Unlimited (while workout active) | Workout tracking via HKWorkoutSession |
| `.selfCare` | Up to 10 minutes | Guided breathing, stretching |
| `.mindfulness` | Up to 10 minutes | Meditation sessions |
| `.smartAlarm` | Up to 30 minutes before alarm | Smart wake-up |
| `.physicalTherapy` | Up to 1 hour | Guided exercises |

### Background Workout Session

```swift
@Observable
final class ExtendedWorkoutManager: NSObject {
    private var extendedSession: WKExtendedRuntimeSession?

    func startExtendedSession() {
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        self.extendedSession = session
    }

    func stopExtendedSession() {
        extendedSession?.invalidate()
        extendedSession = nil
    }
}

extension ExtendedWorkoutManager: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        // Session started, app continues running in background
    }

    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        // Save state, session is about to end
    }

    func extendedRuntimeSession(
        _ session: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        // Session ended
        extendedSession = nil
    }
}
```

**Note:** HKWorkoutSession automatically provides background execution. Use `WKExtendedRuntimeSession` only when you need background time outside of a workout (e.g., a meditation timer).

## HealthKit Queries

### Statistics Query (Aggregated Data)

```swift
func fetchTodaySteps() async throws -> Double {
    let stepsType = HKQuantityType(.stepCount)
    let startOfDay = Calendar.current.startOfDay(for: .now)
    let predicate = HKQuery.predicateForSamples(
        withStart: startOfDay,
        end: .now,
        options: .strictStartDate
    )

    let descriptor = HKStatisticsQueryDescriptor(
        predicate: HKSamplePredicate<HKQuantitySample>.quantitySample(
            type: stepsType,
            predicate: predicate
        ),
        options: .cumulativeSum
    )

    let result = try await descriptor.result(for: healthStore)
    return result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
}
```

### Anchored Object Query (Incremental Updates)

```swift
func observeHeartRate() -> AsyncStream<Double> {
    AsyncStream { continuation in
        let heartRateType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: .now,
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { _, samples, _, _, _ in
            guard let sample = samples?.last as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            continuation.yield(bpm)
        }

        query.updateHandler = { _, samples, _, _, _ in
            guard let sample = samples?.last as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            continuation.yield(bpm)
        }

        healthStore.execute(query)

        continuation.onTermination = { @Sendable _ in
            self.healthStore.stop(query)
        }
    }
}
```

### Statistics Collection Query (Time Series)

```swift
func fetchHourlyHeartRate() async throws -> [(date: Date, bpm: Double)] {
    let heartRateType = HKQuantityType(.heartRate)
    let startOfDay = Calendar.current.startOfDay(for: .now)
    let interval = DateComponents(hour: 1)

    let predicate = HKQuery.predicateForSamples(
        withStart: startOfDay,
        end: .now,
        options: .strictStartDate
    )

    let descriptor = HKStatisticsCollectionQueryDescriptor(
        predicate: HKSamplePredicate<HKQuantitySample>.quantitySample(
            type: heartRateType,
            predicate: predicate
        ),
        options: .discreteAverage,
        anchorDate: startOfDay,
        intervalComponents: interval
    )

    let results = try await descriptor.result(for: healthStore)
    let unit = HKUnit.count().unitDivided(by: .minute())

    var hourlyData: [(date: Date, bpm: Double)] = []
    results.enumerateStatistics(from: startOfDay, to: .now) { stats, _ in
        if let avg = stats.averageQuantity()?.doubleValue(for: unit) {
            hourlyData.append((date: stats.startDate, bpm: avg))
        }
    }

    return hourlyData
}
```

## Workout Route Tracking

```swift
import CoreLocation

@Observable
final class RouteTracker: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var routeBuilder: HKWorkoutRouteBuilder?
    private let healthStore = HKHealthStore()

    var locations: [CLLocation] = []

    func startTracking() {
        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }

    func stopTracking(workout: HKWorkout) async throws {
        locationManager.stopUpdatingLocation()
        guard let routeBuilder else { return }
        try await routeBuilder.finishRoute(with: workout, metadata: nil)
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations newLocations: [CLLocation]) {
        let filtered = newLocations.filter { $0.horizontalAccuracy < 20 }
        guard !filtered.isEmpty else { return }

        locations.append(contentsOf: filtered)
        routeBuilder?.insertRouteData(filtered) { success, error in
            if let error {
                print("Route insert error: \(error)")
            }
        }
    }
}
```

**Required entitlements and Info.plist keys:**

| Key | Value |
|-----|-------|
| `NSLocationWhenInUseUsageDescription` | Why you track location |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | For background tracking |
| Background Modes | `location` enabled |

## Haptics During Workouts

```swift
import WatchKit

enum WorkoutHaptic {
    /// Notify user of a milestone (e.g., 1 km reached)
    static func milestone() {
        WKInterfaceDevice.current().play(.success)
    }

    /// Heart rate zone change
    static func zoneChange() {
        WKInterfaceDevice.current().play(.directionUp)
    }

    /// Workout paused or resumed
    static func stateChange() {
        WKInterfaceDevice.current().play(.click)
    }

    /// Countdown beep (3, 2, 1, Go)
    static func countdownTick() {
        WKInterfaceDevice.current().play(.start)
    }

    /// Workout complete
    static func workoutComplete() {
        WKInterfaceDevice.current().play(.success)
    }
}
```

### Water Lock

```swift
// Enable water lock during swimming workouts
WKInterfaceDevice.current().enableWaterLock()
```

## Saving Workout Data

### Adding Samples to a Workout

```swift
func saveWorkoutWithSamples(
    builder: HKLiveWorkoutBuilder,
    type: HKWorkoutActivityType
) async throws {
    // End collection
    let endDate = Date.now
    try await builder.endCollection(at: endDate)

    // The builder automatically collects samples from its data source.
    // To add manual samples:
    let caloriesSample = HKQuantitySample(
        type: HKQuantityType(.activeEnergyBurned),
        quantity: HKQuantity(unit: .kilocalorie(), doubleValue: 320),
        start: builder.startDate ?? endDate,
        end: endDate
    )
    try await builder.addSamples([caloriesSample])

    // Finish and save the workout
    let workout = try await builder.finishWorkout()
    print("Workout saved: \(workout)")
}
```

### Adding Workout Events

```swift
// Mark intervals, laps, or segments
let lapEvent = HKWorkoutEvent(
    type: .lap,
    dateInterval: DateInterval(start: lapStart, end: .now),
    metadata: ["lapNumber": lapCount]
)
builder?.addWorkoutEvents([lapEvent]) { success, error in
    if let error { print("Event error: \(error)") }
}
```

## Privacy Considerations

1. **Request only needed types** -- Never request more HealthKit data types than your app requires. Apple reviews this during App Review.

2. **Explain clearly** -- The usage description strings must clearly explain why the data is needed in the user's language.

3. **Graceful denial** -- The app must function (with reduced features) if the user denies health data access.

4. **No external sharing** -- HealthKit data must not be sold, shared with advertising, or transmitted to third parties without explicit consent.

5. **Encrypted storage** -- Any health data cached locally must use Data Protection (`FileProtectionType.complete`).

6. **No iCloud backup** -- Do not store HealthKit data in iCloud or unprotected containers. Use HealthKit itself as the source of truth.

## Best Practices

1. **Always check availability** -- `HKHealthStore.isHealthDataAvailable()` returns `false` on iPad and other unsupported devices.

2. **Use async/await APIs** -- Prefer the `HKStatisticsQueryDescriptor` and `HKStatisticsCollectionQueryDescriptor` async APIs over completion-handler queries when targeting watchOS 10+.

3. **Batch saves** -- Collect samples during the workout and let `HKLiveWorkoutBuilder` handle saving. Don't save individual samples mid-workout.

4. **Handle background delivery** -- Use `healthStore.enableBackgroundDelivery(for:frequency:)` to receive updates when your app is in the background.

5. **Test on device** -- HealthKit simulation in Xcode is limited. Always test sensor data, workout sessions, and background behavior on a real Apple Watch.
