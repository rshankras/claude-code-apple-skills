# Launch Time Optimization

## App Launch Phases

```
Cold Launch Timeline
────────────────────────────────────────────────────────
│  Pre-main                │  Post-main               │
│                          │                           │
│  DYLD        Runtime     │  App Init    First Frame  │
│  loading     init        │  UIKit/SwiftUI setup      │
│  ──────────  ──────────  │  ────────────  ──────────  │
│  dylibs      +load       │  AppDelegate   viewDidLoad│
│  rebasing    static      │  @main App     .body      │
│  binding     initializers│  scene setup   layout     │
│              ObjC setup  │  root view     render     │
────────────────────────────────────────────────────────
                                              ↑
                                    First Frame Rendered
                                    (launch complete)
```

### Target Budgets
| Launch Type | Good | Acceptable | Poor |
|-------------|------|------------|------|
| Cold launch | < 400ms | < 1s | > 2s |
| Warm launch | < 200ms | < 500ms | > 1s |
| Resume | < 100ms | < 200ms | > 500ms |

**Cold launch**: App not in memory — full DYLD load, runtime init, UI setup. Slowest, highest variance.
**Warm launch**: Process spawned fresh, but app/data recently in memory and system services running.
**Resume**: App was suspended in background — already running, **not a launch; don't count it in launch measurements** (WWDC19 423).

Apple's headline goal: **first frame in 400ms** — roughly the duration of the launch animation, so the app appears ready the moment it ends. Rough split: ~100ms of system-side work, leaving **~300ms for you** to create views, load content, and render (WWDC19 423). Measure **warm** launches — they're more consistent than cold.

### The Six Launch Phases (WWDC19 423)

| # | Phase | What runs | Your lever |
|---|-------|-----------|------------|
| 1 | dyld | Shared libraries/frameworks load | dyld3 caches runtime dependencies on warm launches — but only if you **hard-link all dependencies**, **avoid `dlopen`/`NSBundle.load`**, and remove unused linked frameworks |
| 2 | libSystem init | Fixed-cost system-side setup | Nothing — leave it alone |
| 3 | Static runtime init | ObjC/Swift runtimes; **static initializers and `+load` run here and block launch** | Avoid static init entirely; frameworks should expose an explicit setup API; move `+load` (every launch) to `+initialize` (lazy, first use). Demo: a logging framework's `+load` burned **~370ms** for a feature used only on a row tap |
| 4 | UIKit init | `UIApplication`/delegate instantiation, event loop | Fixed cost (~28ms in the demo) **unless** you subclass `UIApplication` or do work in delegate initializers — don't |
| 5 | Application init | Launch delegate callbacks, scene connection | **Create view controllers in exactly ONE place** — `scene(_:willConnectTo:)` on UIScene apps, `didFinishLaunching` otherwise; doing it in both wastes time and breeds unpredictable bugs |
| 6 | First frame render | Views created → layout → draw → commit | Flatten the hierarchy, subclass less, lazily load views not visible at launch, reduce Auto Layout constraint count |

There's also an optional **extended phase** after first frame: async-load remaining data while the app is already interactive, and **instrument it with os_signpost** so you know exactly what runs between first frame and fully loaded (WWDC19 423).

The session's demo went **2.5s → ~300ms** by fixing phases 3, 5, and 6 — see the two case studies under Post-main Optimization below.

## App Launch Instrument

### Setup
1. **Xcode > Product > Profile** (Cmd+I)
2. Choose **App Launch** template
3. Record — the app launches and Instruments captures the entire timeline (the template runs the app for five seconds, gathering a Time Profile + Thread State Trace of the launch — WWDC21 10181)
4. Stop after app is fully interactive

### Reading the Results
- **Process Lifecycle** lane shows app state transitions
- **Thread State** lane shows main thread activity during launch
- **Time Profiler** lane shows CPU work during launch
- Focus on the region between process start and first frame
- Timeline colors: **purple = pre-main phases, green = post-main** (UIKit init, app init, first frame). Thread states: **gray = blocked, red = runnable but starved of CPU, orange = preempted, blue = running**. The left pane narrates the selected phase; the event list shows which thread unblocked the main thread (WWDC19 423)
- Distinguish **CPU time vs wall clock** — the 423 demo's dyld phase showed 149ms wall clock but only 6ms CPU (the rest was profiling overhead)

### Key Measurements
- **Time to first frame**: Total duration from process start to first CA commit
- **Pre-main time**: From process start to `main()` / `@main` entry
- **Post-main time**: From `main()` to first frame rendered

## Pre-main Optimization

### Reduce Dynamic Frameworks
Each dynamic framework adds ~10-30ms to launch:

```
Before: 15 dynamic frameworks → ~300ms DYLD loading
After:  3 dynamic frameworks  → ~50ms DYLD loading
```

**How to fix:**
- Convert dynamic frameworks to **static libraries** where possible
- Use Swift Package Manager (static by default) instead of dynamic frameworks
- Merge small frameworks into fewer larger ones
- Check with: `otool -L YourApp.app/YourApp` to list linked dylibs

More dylibs = more dyld work + more dirty DATA pages; too many static libs = slow iterative builds. The ld64 rewrite in Xcode 14 (~2× faster linking) moved the sweet spot toward **fewer dylibs** (WWDC22 110362). Play to dyld3's warm-launch caching: hard-link all dependencies, avoid `dlopen`/`NSBundle.load` (dynamic loading forfeits the cache), prune unused frameworks (WWDC19 423).

### Remove Static Initializers
Static initializers (`+load`, `__attribute__((constructor))`) run before `main()`:

```swift
// Bad — runs before main(), delays launch
class LegacyManager: NSObject {
    override class func load() { // ObjC +load
        setup()
    }
}

// Bad — C-style constructor
@_cdecl("initEarly")
func initEarly() { /* runs before main */ }

// Good — defer to first use
class LegacyManager {
    static let shared = LegacyManager() // Lazy, created on first access
}
```

- Move `+load` (runs on every launch) to `+initialize` (lazy, on first use); the 423 demo saved 300+ ms this way (WWDC19 423)
- If your framework needs setup, **expose an explicit API** instead of a static initializer
- ❌ Static initializers doing I/O, networking, or anything beyond a few milliseconds — they always run before `main()`; in the 110362 TextEdit measurement, static initializers dominated launch after fixups shrank to ~1ms (WWDC22 110362)

### Minimize ObjC Metadata
- Large ObjC class hierarchies increase rebasing/binding time
- Swift classes without `@objc` are more efficient
- Reduce ObjC category usage (each category adds metadata)

### Linker & Runtime Levers (WWDC22 110362 / 110363)

Raising your deployment target is itself a launch/size optimization:

| Lever | Requirement | Effect |
|-------|-------------|--------|
| Protocol-conformance metadata precomputed in the dyld closure | Runs on iOS 16 / tvOS 16 / watchOS 9 — automatic, even for existing binaries | `is`/`as` protocol checks previously built metadata at launch — "up to half of the launch time" on real-world apps (WWDC22 110363) |
| objc_msgSend selector stubs | Build with Xcode 14, any deployment target | Per-call site cost 12 → 4 bytes on arm64, up to 2% smaller binary. Keep the default stub mode; `-objc_stubs_small` only if severely size-constrained (WWDC22 110363) |
| retain/release custom calling convention | Xcode 14 build AND deployment target iOS 16 / tvOS 16 / watchOS 9 | Another up-to-2% code-size win; combined with stubs ≈ 4% (WWDC22 110363) |
| Faster autorelease elision | Runs on iOS 16-era OSes; extra size saving needs the Xcode 14 rebuild + iOS 16 target | Pointer-compare handshake replaces a pipeline-hostile data load (WWDC22 110363) |
| Chained fixups | Deployment target ≥ iOS 13.4 | Smaller `__LINKEDIT`, enables **page-in linking** — the kernel applies fixups lazily as DATA pages fault in. Caveat: applies only at main launch; `dlopen`'d dylibs take the eager path (WWDC22 110362) |
| `-no_exported_symbols` (Other Linker Flags) | Check `dyld_info -exports <binary>` first | Skips building the exports trie (an app with ~1M exported symbols saved 2–3s of *link* time). ❌ Don't use if the app hosts plugins that link back to it or serves as an XCTest host (WWDC22 110362) |

Verify with **`dyld_usage`** (macOS, Simulator, Catalyst: per-launch dyld time breakdown) and **`dyld_info -exports` / `-fixups`** (inspect any binary, even inside the dyld shared cache) (WWDC22 110362).

## Post-main Optimization

### Defer Non-Essential Initialization

```swift
@main
struct MyApp: App {
    init() {
        // Bad — all of this delays first frame
        AnalyticsManager.shared.configure()
        CrashReporter.shared.start()
        RemoteConfig.shared.fetch()
        ImageCache.shared.warmUp()
        DatabaseMigrator.run()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Good — only essential work at init, defer the rest
@main
struct MyApp: App {
    init() {
        // Only crash reporter is truly needed immediately
        CrashReporter.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Defer everything else to after first frame
                    await deferredSetup()
                }
        }
    }

    private func deferredSetup() async {
        AnalyticsManager.shared.configure()
        RemoteConfig.shared.fetch()
        ImageCache.shared.warmUp()
    }
}
```

Phase-5 rules from WWDC19 423: **minimize** (defer undisplayed views and speculative pre-warming; no network or file I/O on the main thread), **prioritize** (correct QoS everywhere), **optimize** (lazy compute, fetch only first-frame data, cache computed values), and **share resources between scenes**.

### Priority Inversion at Launch (WWDC19 423)

The 423 demo's `didFinishLaunching` took 791ms — the main thread spent 754ms blocked on a semaphore waiting for a background worker: main runs at user-interactive QoS (47), the async'd worker at QoS 4, and the semaphore hid the dependency from the scheduler.

```swift
// ❌ async + semaphore — worker keeps background QoS; main (UI QoS) blocks on it
queue.async { result = loadAllStars(); semaphore.signal() }
semaphore.wait()

// ✅ queue.sync propagates the main thread's QoS to the worker (boosted to
//    user-interactive) — and load only what the first frame needs
queue.sync { firstScreenStars = loadStars(limit: 20) }   // ~20 visible rows, not 10,000
// remainder loads lazily in the background after first frame
```

### Don't Pre-Warm Speculatively (WWDC19 423)

The demo's first frame took 951ms because `cellForRowAt` "cleverly" instantiated and cached a `DetailViewController` per row — **882ms** of speculative pre-warming for screens the user might never open. Moving creation to `didSelectRowAt` fixed it. **Measure, don't guess**: profiling disproved the optimization the code was written around.

### Lazy View Loading

```swift
// Bad — all tabs initialize their full view hierarchy at launch
TabView {
    HomeView()        // Heavy: fetches data, builds complex layout
    SearchView()      // Heavy: initializes search index
    ProfileView()     // Heavy: loads user data
}

// Good — use lazy containers, each tab builds only when selected
TabView {
    NavigationStack {
        HomeView()
    }
    .tabItem { Label("Home", systemImage: "house") }

    NavigationStack {
        SearchView()
    }
    .tabItem { Label("Search", systemImage: "magnifyingglass") }
}
// SwiftUI NavigationStack already lazy-loads destination views
// For custom containers, use LazyVStack instead of VStack
```

### Reduce Initial View Complexity

```swift
// Bad — loading everything at once
struct ContentView: View {
    @State private var allItems: [Item] = []

    var body: some View {
        List(allItems) { item in
            ComplexItemView(item: item)
        }
        .onAppear {
            allItems = try! ModelContext(container).fetch(
                FetchDescriptor<Item>(sortBy: [SortDescriptor(\.date)])
            )
        }
    }
}

// Good — show skeleton immediately, load data async
struct ContentView: View {
    @State private var items: [Item]?

    var body: some View {
        Group {
            if let items {
                List(items) { item in
                    ItemRow(item: item)
                }
            } else {
                SkeletonListView() // Lightweight placeholder
            }
        }
        .task {
            items = await loadItems()
        }
    }
}
```

### Database Migration at Launch

```swift
// Bad — blocking migration on main thread
let container = try ModelContainer(for: Item.self)
// If migration runs, this blocks until complete

// Good — show migration UI if needed
struct AppEntry: View {
    @State private var container: ModelContainer?
    @State private var isMigrating = false

    var body: some View {
        Group {
            if let container {
                ContentView()
                    .modelContainer(container)
            } else if isMigrating {
                MigrationProgressView()
            } else {
                ProgressView()
            }
        }
        .task {
            await setupContainer()
        }
    }

    private func setupContainer() async {
        // Check if migration needed
        if await needsMigration() {
            isMigrating = true
        }
        container = try? await Task.detached {
            try ModelContainer(for: Item.self)
        }.value
        isMigrating = false
    }
}
```

## Measurement Discipline (WWDC19 423)

Launch numbers are only comparable under controlled conditions:

- **Reboot the device and let it settle** several minutes before measuring
- Kill network variance: **Airplane Mode** or mocked networking
- **Pin iCloud state**: fixed account/data, or signed out
- Use a **Release build via the Profile scheme**
- Measure **warm** launches (consistent); use consistent mock datasets (small + large)
- Keep a fixed device set that **always includes the oldest supported device on the oldest supported OS**
- Track longitudinally across the release cycle — regressions of 2–3ms compound

### XCTApplicationLaunchMetric (CI Gate)

```swift
func testLaunchPerformance() {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
    }
}
```

One throwaway launch absorbs cold-launch variance, then **5 iterations by default** with statistical output — CI-friendly and lower overhead than Instruments (WWDC19 423, WWDC21 10181). Set a baseline so regressions fail the test.

## Measuring Launch Time in Code

### Using os_signpost

```swift
import os

@main
struct MyApp: App {
    static let launchLog = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Launch")
    static let launchSignpost = OSSignpostID(log: launchLog)

    init() {
        os_signpost(.begin, log: Self.launchLog, name: "AppLaunch", signpostID: Self.launchSignpost)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    os_signpost(.end, log: Self.launchLog, name: "AppLaunch", signpostID: Self.launchSignpost)
                }
        }
    }
}
```

### Using CFAbsoluteTimeGetCurrent

```swift
// Quick and dirty launch measurement
@main
struct MyApp: App {
    static let launchStart = CFAbsoluteTimeGetCurrent()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let elapsed = CFAbsoluteTimeGetCurrent() - Self.launchStart
                    print("Launch time: \(String(format: "%.3f", elapsed))s")
                }
        }
    }
}
```

## MetricKit Launch Metrics

Production launch time data from real users:

```swift
func didReceive(_ payloads: [MXMetricPayload]) {
    for payload in payloads {
        if let launch = payload.applicationLaunchMetrics {
            // Histogram of time-to-first-draw
            let histogram = launch.histogrammedTimeToFirstDraw
            for bucket in histogram.bucketEnumerator {
                guard let bucket = bucket as? MXHistogramBucket<UnitDuration> else { continue }
                print("[\(bucket.bucketStart) - \(bucket.bucketEnd)]: \(bucket.bucketCount) launches")
            }

            // Resume time histogram
            let resumeHistogram = launch.histogrammedResumeTime
            // Same enumeration pattern
        }
    }
}
```

The **Xcode Organizer** shows the same class of data aggregated: real-user launch-time histograms per app version/device over 24-hour windows from opted-in users — launch time is reported as average "time to first frame" across the last 16 versions (WWDC19 423, WWDC21 10181). Terminations also force a full cold launch next time, so watch the terminations metric alongside launch time (WWDC21 10181).

## Launch Optimization Checklist

### Pre-main
- [ ] Minimize dynamic frameworks (prefer static linking)
- [ ] No `+load` methods or static initializers (`+load` → `+initialize`; frameworks expose explicit setup APIs)
- [ ] Remove unused frameworks from Link Binary With Libraries
- [ ] Strip unused architectures in release builds
- [ ] No `dlopen` / `NSBundle.load` — hard-link dependencies so dyld3's warm-launch cache applies
- [ ] Deployment target ≥ iOS 13.4 (chained fixups / page-in linking); iOS 16 unlocks protocol-metadata precompute + retain/release convention

### Post-main (App Init)
- [ ] Only essential setup in `App.init()` or `AppDelegate` (crash reporter only)
- [ ] Analytics, remote config, and prefetch deferred to `.task {}` after first frame
- [ ] No synchronous network calls at launch
- [ ] No blocking database migrations on main thread
- [ ] View controllers created in exactly one place (`scene(_:willConnectTo:)` OR `didFinishLaunching`, never both)
- [ ] No semaphore waits on async'd work (priority inversion) — use `queue.sync` for QoS propagation or async/await
- [ ] First frame fetches only first-frame data; no speculative pre-warming of unopened screens

### First Frame
- [ ] Initial view is lightweight (skeleton/placeholder)
- [ ] Data loading is async with `.task {}`
- [ ] Heavy views (maps, web views, complex lists) lazy-loaded
- [ ] Images use thumbnails, not full resolution

### Verification
- [ ] Measure with App Launch Instrument on oldest supported device (controlled conditions: reboot + settle, Airplane Mode, pinned iCloud, Release/Profile build)
- [ ] First frame < 400ms, measured on warm launches
- [ ] `XCTApplicationLaunchMetric` baseline set in CI
- [ ] No regressions after changes (compare Instruments traces)
- [ ] MetricKit / Organizer showing stable or improving launch times in production
