# Energy Diagnostics

## Why Energy Matters
- Battery drain is the #1 reason users delete apps
- Excessive energy use triggers **App Store review flags**
- iOS throttles apps with high energy impact in the background
- Thermal throttling degrades performance for all apps, not just yours

## Energy Impact Instrument

### Setup
1. **Xcode > Product > Profile** (Cmd+I)
2. Choose **Energy Log** template (iOS) or **Activity Monitor** template (macOS)
3. Record on **physical device** (energy profiling requires real hardware)
4. Reproduce typical usage patterns

### Reading the Energy Log
The Energy Impact gauge shows a composite score:

| Level | Score | Meaning |
|-------|-------|---------|
| Low | 0-3 | Good — minimal battery drain |
| Medium | 3-8 | Acceptable for active use, not idle |
| High | 8+ | Investigate — significant drain |
| Overhead | Red bar | System overhead from your app |

### Component Breakdown
| Component | What It Measures |
|-----------|-----------------|
| CPU | Processing time (biggest energy consumer) |
| GPU | Graphics rendering, Metal, animations |
| Network | Radio usage (cellular is most expensive) |
| Location | GPS, Wi-Fi, cell tower ranging |
| Display | Screen brightness influence (indirect) |
| Overhead | System services your app triggers |

## Power Profiler Instrument (WWDC25 226)

The deep-dive tool after Energy Gauges flag a problem:

1. **Product ▸ Profile** (device can be connected wirelessly) → blank Instruments template → add **Power Profiler** + **CPU Profiler**
2. Record while reproducing the drain scenario
3. Read the lanes:
   - **System Power Usage** — whole-device energy rate in **%/hr** (the demo idled at 10.5 %/hr)
   - Per-app **Power Impact** score lanes for **CPU, GPU, Display, Networking** — the score is unitless; read it comparatively (baseline vs. spike) and attack the highest-impact subsystem first

Case study from the session: opening a Library pane spiked CPU power impact to **21** (baseline 1) because a `VStack` built every video thumbnail up front. Switching to `LazyVStack` measured **4.3** — roughly an 80% reduction (WWDC25 226).

```swift
// Bad — builds every row (and decodes every thumbnail) immediately
ScrollView { VStack { ForEach(videos) { VideoThumbnailRow($0) } } }

// Good — builds rows only as they approach the viewport
ScrollView { LazyVStack { ForEach(videos) { VideoThumbnailRow($0) } } }
```

## On-Device Performance Trace (WWDC25 226)

Catches drains you can't reproduce at a desk (commutes, real networks, teammates' devices):

1. Enable **Developer Mode** (Settings, after first Xcode connect)
2. **Settings ▸ Performance Trace** → enable; under it enable **Power Profiler** and pick the target app — must be installed via **Xcode, TestFlight, or Enterprise** distribution (App Store builds can't be selected)
3. Add the **Performance Trace** control to Control Center; tap to start, live your life (recording can run for hours), tap again to stop
4. Share the trace file (AirDrop/Files) and open it in Instruments on the Mac

## Comparing Implementations with Power Data (WWDC25 226)

- Profile approach A and approach B as separate runs; compare per-subsystem power-impact numbers
- Control the confounders: **thermal state, device state, system pressure, data size, network conditions**
- **Run multiple iterations and average** before deciding
- ❌ Never pick an implementation from a single run or from code inspection alone

## Common Energy Drains and Fixes

### Excessive Timer Usage

```swift
// Bad — timer fires every second even when app is idle
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    self.checkForUpdates() // Keeps CPU awake
}

// Good — use tolerance for coalescing, stop when not needed
let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    self.updateTimestamp()
}
timer.tolerance = 0.5 // System can defer ±0.5s to coalesce with other work

// Better — use system notifications instead of polling
NotificationCenter.default.addObserver(
    forName: .significantTimeChange, // System fires this at midnight, timezone change
    object: nil, queue: .main
) { _ in self.updateDate() }
```

### Repeated Work on High-Frequency Triggers (WWDC25 226)

The session's commute drain: a suggestion function ran on **every location update**, each time re-reading a rules file and re-parsing hundreds of JSON rules — file I/O + decode on every trigger. The rules never change while the app runs.

```swift
// Bad — expensive I/O + decode on every location callback
func videoSuggestionsForLocation(_ loc: CLLocation) -> [Video] {
    let data = try! Data(contentsOf: rulesURL)                    // every time
    let rules = try! JSONDecoder().decode(Rules.self, from: data) // every time
    return rules.match(loc)
}

// Good — parse once, cache for the process lifetime
private lazy var rules: Rules = {
    let data = try! Data(contentsOf: rulesURL)
    return try! JSONDecoder().decode(Rules.self, from: data)
}()
func videoSuggestionsForLocation(_ loc: CLLocation) -> [Video] { rules.match(loc) }
```

Applies to any high-frequency trigger: location updates, timers, scroll callbacks (WWDC25 226).

### Location Accuracy Over-specification

```swift
// Bad — GPS accuracy when you only need city-level
let manager = CLLocationManager()
manager.desiredAccuracy = kCLLocationAccuracyBest // GPS radio stays on
manager.startUpdatingLocation() // Continuous updates

// Good — match accuracy to need
// For weather/city features:
manager.desiredAccuracy = kCLLocationAccuracyKilometer
manager.requestLocation() // Single update, not continuous

// For navigation:
manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
manager.activityType = .automotiveNavigation // Optimizes for driving
manager.allowsBackgroundLocationUpdates = true
manager.pausesLocationUpdatesAutomatically = true // Pauses when stationary

// For "nearby" features:
manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
manager.distanceFilter = 100 // Only notify on 100m movement
```

### Network Request Inefficiency

```swift
// Bad — separate requests that could be batched
func refreshAll() async {
    let profile = try? await api.fetchProfile()
    let posts = try? await api.fetchPosts()
    let notifications = try? await api.fetchNotifications()
    let settings = try? await api.fetchSettings()
    // 4 separate radio activations
}

// Good — batch into single request or parallel group
func refreshAll() async {
    async let profile = api.fetchProfile()
    async let posts = api.fetchPosts()
    async let notifications = api.fetchNotifications()
    // 3 requests but radio stays active for one burst

    let results = await (profile, posts, notifications)
}

// Better — single batch endpoint
func refreshAll() async {
    let batch = try? await api.fetchDashboard()
    // 1 request with all data
}
```

### Cellular vs WiFi Awareness

```swift
import Network

let monitor = NWPathMonitor()

monitor.pathUpdateHandler = { path in
    if path.usesInterfaceType(.cellular) {
        // Reduce data usage
        self.imageQuality = .low
        self.prefetchEnabled = false
        self.analyticsFlushInterval = 300 // 5 min instead of 30s
    } else if path.usesInterfaceType(.wifi) {
        self.imageQuality = .high
        self.prefetchEnabled = true
        self.analyticsFlushInterval = 30
    }
}

monitor.start(queue: .main)
```

### Background Task Energy

```swift
// Bad — long-running background work without proper task
func applicationDidEnterBackground(_ application: UIApplication) {
    syncAllData() // May be killed, wastes energy if interrupted
}

// Good — use BGTaskScheduler for deferrable work
import BackgroundTasks

func scheduleSync() {
    let request = BGProcessingTaskRequest(identifier: "com.app.sync")
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = false // Set true for heavy work
    try? BGTaskScheduler.shared.submit(request)
}

func handleSync(task: BGProcessingTask) {
    let syncTask = Task {
        await performSync()
        task.setTaskCompleted(success: true)
    }

    task.expirationHandler = {
        syncTask.cancel()
        task.setTaskCompleted(success: false)
    }
}
```

### Animation Energy

```swift
// Bad — continuous animation running when not visible
struct PulsingView: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 1).repeatForever(), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// Good — stop animation when not visible
struct PulsingView: View {
    @State private var isPulsing = false
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        Circle()
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .animation(
                isPulsing ? .easeInOut(duration: 1).repeatForever() : .default,
                value: isPulsing
            )
            .onChange(of: scenePhase) { _, phase in
                isPulsing = (phase == .active)
            }
    }
}
```

## Thermal State Monitoring

```swift
import Foundation

func monitorThermalState() {
    NotificationCenter.default.addObserver(
        forName: ProcessInfo.thermalStateDidChangeNotification,
        object: nil, queue: .main
    ) { _ in
        handleThermalState(ProcessInfo.processInfo.thermalState)
    }
}

func handleThermalState(_ state: ProcessInfo.ThermalState) {
    switch state {
    case .nominal:
        // Full performance
        enableAllFeatures()
    case .fair:
        // Slightly warm — reduce optional work
        disablePreloading()
    case .serious:
        // Hot — reduce significantly
        reduceAnimations()
        lowerImageQuality()
        pauseBackgroundSync()
    case .critical:
        // Thermal throttling imminent — minimize everything
        stopNonEssentialWork()
        showThermalWarningIfAppropriate()
    @unknown default:
        break
    }
}
```

## MetricKit Energy Metrics

Production energy data:

```swift
func didReceive(_ payloads: [MXMetricPayload]) {
    for payload in payloads {
        // CPU usage
        if let cpu = payload.cpuMetrics {
            log("Cumulative CPU time: \(cpu.cumulativeCPUTime)")
            log("CPU instructions: \(cpu.cumulativeCPUInstructions)")
        }

        // GPU usage
        if let gpu = payload.gpuMetrics {
            log("Cumulative GPU time: \(gpu.cumulativeGPUTime)")
        }

        // Cellular condition
        if let cellular = payload.cellularConditionMetrics {
            log("Cell condition time: \(cellular.histogrammedCellularConditionTime)")
        }

        // Network transfer
        if let network = payload.networkTransferMetrics {
            log("WiFi upload: \(network.cumulativeWifiUpload)")
            log("WiFi download: \(network.cumulativeWifiDownload)")
            log("Cellular upload: \(network.cumulativeCellularUpload)")
            log("Cellular download: \(network.cumulativeCellularDownload)")
        }

        // Location activity
        if let location = payload.locationActivityMetrics {
            log("Best accuracy time: \(location.cumulativeBestAccuracyTime)")
            log("10m accuracy time: \(location.cumulativeBestAccuracyForNavigationTime)")
        }
    }
}
```

## Xcode Energy Organizer

Access in **Xcode > Window > Organizer > Energy**:
- Shows energy reports from **real users** via TestFlight and App Store
- Breaks down by: CPU, Location, Display, Network, GPU, Accessories
- Filter by app version to track regressions
- Shows **background energy** separately — critical for battery complaints

## The Energy Toolchain Ladder (WWDC25 226)

| Stage | Tool |
|-------|------|
| While coding | Xcode **Energy Gauges** (instant feedback in the Debug navigator; can jump straight to Time Profiler, and the Location Energy Model verifies Core Location isn't running when it shouldn't — WWDC21 10181) |
| Deep dive | Instruments **Power Profiler** (+ on-device Performance Trace for field conditions) |
| CI | Automated **XCTests** to catch energy regressions early |
| Post-ship | **Xcode Organizer** field reports, **MetricKit** battery metrics, **App Store Connect API** for dashboards |

Expectation to hold your code to: CPU spikes are normal while drawing UI or processing data, but **once tasks complete and the app is waiting for user input, CPU should be at or near zero** (WWDC21 10181).

## Energy Optimization Checklist

### CPU
- [ ] No polling timers without `tolerance` set
- [ ] Background work uses `BGTaskScheduler`, not continuous timers
- [ ] Heavy computation offloaded and cancellable
- [ ] Idle state truly idle — no periodic wake-ups without reason

### Network
- [ ] Requests batched when possible (single endpoint > multiple calls)
- [ ] Reduced data on cellular (lower image quality, less prefetch)
- [ ] No redundant requests (proper caching with `URLCache` / ETags)
- [ ] Background uploads use `URLSession` background configuration

### Location
- [ ] Accuracy matches actual need (`kCLLocationAccuracyKilometer` for weather)
- [ ] `requestLocation()` for one-shot needs, not `startUpdatingLocation()`
- [ ] `distanceFilter` set to avoid unnecessary updates
- [ ] `pausesLocationUpdatesAutomatically = true` when appropriate

### GPU / Animations
- [ ] Animations pause when app enters background
- [ ] No offscreen rendering (shadow, cornerRadius + clipsToBounds)
- [ ] Metal workloads respect thermal state
- [ ] Continuous animations stop when not visible

### Thermal
- [ ] App monitors `ProcessInfo.thermalState`
- [ ] Graceful degradation at `.serious` and `.critical` states
- [ ] Heavy features disabled proactively, not reactively

### Methodology
- [ ] No expensive work re-run on high-frequency triggers (location updates, timers, scroll callbacks) — parse/compute once, cache
- [ ] A/B implementation choices backed by averaged multi-run power profiles with controlled thermals/device/network, never a single run
