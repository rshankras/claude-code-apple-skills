# Memory Profiling

## Memory Footprint: What Actually Counts (WWDC21 10180)

Three categories of memory — only two count against you:

| Category | What it is | Counts toward footprint? |
|----------|-----------|--------------------------|
| **Dirty** | Memory your app wrote: heap allocations (malloc), decoded image buffers, frameworks' written pages | Yes |
| **Compressed** | Dirty pages not recently accessed, compressed by the memory compressor; decompressed on access | Yes |
| **Clean** | Never written or page-out-able: memory-mapped files, frameworks' clean pages | No |

- **The equation: footprint = dirty + compressed.** Clean memory is free (WWDC21 10180).
- **iOS has no swap** — swap is macOS-specific. In `vmmap` output on iOS, the **"swapped" column means "compressed"**; only the "dirty size" and "swapped size" columns matter for footprint (WWDC21 10180).
- **All malloc allocations are ≥ 16 bytes and 16-byte aligned** — a 4-byte request costs 16 bytes (WWDC24 10173).
- A **page** is a fixed-size, indivisible chunk (16 KB OS pages) — writing to any part dirties the whole page and your process is charged for all of it (WWDC21 10180, WWDC24 10173).
- Under pressure the system compresses/swaps dirty pages, evicts clean ones, kills background tasks, then your app (WWDC24 10173).
- Why a smaller footprint matters: less likely to be terminated in background → state preserved → faster activations; more headroom for features; equal behavior on older devices with less RAM (WWDC21 10180).

### Fragmentation: The ≤25% Rule (WWDC21 10180)

**Fragmentation** = dirty pages not 100% utilized. It's a footprint multiplier — "50% fragmentation doubled my footprint from 2 to 4 dirty pages."

- **Rule of thumb: aim for about 25% fragmentation or less.**
- Fixes: **allocate objects with similar lifetimes close together in memory**; use **autorelease pools** (everything allocated inside is released when the pool exits scope → similar lifetimes). Transient spikes that get freed still leave fragmentation holes (WWDC24 10173).
- **Long-running processes (e.g. extensions) are especially fragmentation-prone.**
- Measure: `vmmap -summary`, bottom section by malloc zone — the **% FRAG** column is % wasted per zone. Normally only DefaultMallocZone matters, but **with Malloc Stack Logging enabled all heap allocations land in MallocStackLoggingLiteZone** — read that one instead.

## Instruments Setup

### Choosing the Right Tool (WWDC24 10173)

| Tool | What it answers | Cost model |
|------|-----------------|------------|
| Xcode memory report | "Is memory growing?" — can't say *why* | Free |
| **Allocations** (template includes VM Tracker) | Full event history of every alloc/free over time — transient *and* persistent growth | Continuous per-event cost |
| **Leaks** | Periodic snapshots for unreachable memory | Snapshot-based, briefly suspends the app |
| **Memory Graph Debugger** | One snapshot of all allocations + references — "who is keeping this alive?" | Snapshot-based, briefly suspends the app |
| CLI: `leaks`, `heap`, `vmmap`, `malloc_history` | Scriptable triage on live processes or memgraphs | Snapshot |

Enable **MallocStackLogging** first (Scheme ▸ Diagnostics) — it records the backtrace + timestamp of every allocation, powers the memory graph's backtraces and `malloc_history`, and gives type context where C/C++ has none (WWDC24 10173). A device is needed for timing work; **Simulator is acceptable for heap-shape analysis**.

### Allocations Instrument
1. **Xcode > Product > Profile** (Cmd+I)
2. Choose **Allocations** template
3. Record, reproduce the issue, stop

### Leaks Instrument
- Included in the Allocations template by default
- Runs periodic scans for unreachable memory
- Red crosses in the Leaks lane indicate detected leaks

## Allocations Instrument

### Key Metrics
| Metric | Meaning |
|--------|---------|
| All Heap Allocations | Total memory allocated on the heap |
| Live Bytes | Currently allocated (not freed) memory |
| Transient Bytes | Allocated and freed during recording |
| # Living | Count of live allocation objects |
| # Transient | Count of freed allocations |

### Reading the Results
- Sort by **Live Bytes** to find largest memory consumers
- Sort by **# Living** to find most numerous allocations
- Click a category to see individual allocations with stack traces
- **Persistent** column shows objects that survive across generations

### Generation Analysis (Mark Generation)
Track memory growth over repeated operations:

1. Start recording
2. Click **Mark Generation** to baseline
3. Perform an operation (open screen, load data, etc.)
4. Click **Mark Generation** again
5. Repeat the same operation
6. Compare generations — growth between identical operations = leak or unbounded cache

**What to look for:**
- Stable: Each generation has similar Live Bytes
- Leaking: Each generation grows — objects from previous generations persist
- Caching: Growth that plateaus after a few generations (may be intentional)

**Drilling into persistent growth (WWDC24 10173):** each generation = allocations made after that mark and still alive at the end. Expand a growing generation, sort by size, drill to an individual address — then hand that address to the **Memory Graph Debugger** (filter by address), walk the reference chain to the owner, and use the Inspector backtrace to reach source. The session's bug: a cache key built from `Date.now` instead of the file's creation date meant **every lookup missed**, so every thumbnail was re-created and retained forever in a static cache. Doctrine: **a cache that never hits is a leak with extra steps — verify key stability.**

### Transient Spikes (WWDC24 10173)

Spikes that get freed still hurt: memory pressure at the peak, plus long-term fragmentation holes.

- **One spike**: drag-select the track from low point to peak → statistics show allocations **Created & Still Living** in that window → sort by total bytes.
- **Repeated spikes**: select a wide range → lifespan filter **"Created & Destroyed"** → switch to the **call tree** to see which code creates the temporaries. The session demo found 8 GB of temporaries across three gallery opens, dominated by autorelease-pool content pages.
- Calling ObjC frameworks from Swift yields autoreleased objects; in a loop they pile into the thread's top-level pool (visible as "content pages" in Allocations) and free only when it drains — a memory cliff. Fix: nested `autoreleasepool` per iteration (see Autorelease Pool Optimization below).

### Common Memory Issues

#### Unbounded Cache Growth

```swift
// Bad — cache grows forever
class ImageCache {
    var cache: [URL: UIImage] = [:]

    func image(for url: URL) -> UIImage? {
        return cache[url]
    }
}

// Good — use NSCache for automatic eviction
class ImageCache {
    private let cache = NSCache<NSURL, UIImage>()

    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }

    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }

    func store(_ image: UIImage, for url: URL) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}
```

#### Large Images Not Downsampled

```swift
// Bad — full resolution image loaded into memory
let image = UIImage(contentsOfFile: photoPath)
// 4032x3024 photo = ~48 MB in memory

// Good — downsample to display size
func downsample(imageAt url: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
    let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
    ]

    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    else { return nil }

    return UIImage(cgImage: cgImage)
}
```

## Leaks Instrument

### How Leaks Detection Works
- Scans heap at intervals for objects with no root references
- Detects **unreachable** memory — allocated but no path from stack/globals
- Does NOT detect **logical leaks** (reachable but never used, like unbounded caches)

**The three reachability states (WWDC24 10173):** **useful** (reachable, will be used), **abandoned** (reachable but never used again — over-caching, fat singletons; wastes footprint and *no tool flags it*), and **leaked** (unreachable — cycles, lost pointers). Leaks-the-tool only finds the third kind. "Strive to have zero leaks in your app" (WWDC21 10180).

**Leak-tool limits (WWDC24 10173):**
- Tools classify references as strong / weak / unowned / unmanaged / **conservative** — raw bytes that merely *look* like pointers (all C, and C++ without virtual methods). Conservative references cause **false negatives and non-determinism** (4 leaks one run, 5 the next). Trick: **run the suspect code in a loop ~100×** — multiplied leaks are easy to spot.
- **noreturn gotcha**: locals in a function ending in `dispatchMain()` (noreturn) get their cleanup optimized away and are falsely reported leaked — store app-lifetime objects in a static/global instead.
- If weak/unowned edges are missing from the memory graph, set build setting **Reflection Metadata Level = All**.

### Common Retain Cycle Patterns

#### Closure Capturing Self

```swift
// Bad — retain cycle: self -> timer -> closure -> self
class ViewModel {
    var timer: Timer?

    func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.refresh() // Strong capture of self
        }
    }
}

// Good — weak capture
timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
    self?.refresh()
}
```

#### Delegate Retain Cycle

```swift
// Bad — strong delegate creates cycle
protocol ServiceDelegate: AnyObject {
    func didComplete()
}

class Service {
    var delegate: ServiceDelegate? // Strong reference
}

class ViewModel: ServiceDelegate {
    let service = Service() // ViewModel -> Service -> ViewModel
    init() { service.delegate = self }
}

// Good — weak delegate
class Service {
    weak var delegate: ServiceDelegate?
}
```

#### Closure in Collection

```swift
// Bad — closures in array capture self strongly
class Coordinator {
    var handlers: [() -> Void] = []

    func register() {
        handlers.append {
            self.handleEvent() // Each closure retains self
        }
    }
}

// Good — weak capture in each closure
handlers.append { [weak self] in
    self?.handleEvent()
}
```

#### NotificationCenter (Pre-iOS 9 / Manual)

```swift
// Modern iOS/macOS: system auto-removes observers on dealloc
// But if using block-based API, the token retains the closure:

// Bad — token keeps closure alive
let token = NotificationCenter.default.addObserver(
    forName: .dataChanged, object: nil, queue: .main
) { _ in
    self.reload() // Retained by token
}

// Good — store and remove, or use weak self
let token = NotificationCenter.default.addObserver(
    forName: .dataChanged, object: nil, queue: .main
) { [weak self] _ in
    self?.reload()
}
```

#### Closure Contexts and the Implicit-self Trap (WWDC24 10173)

- Every capturing closure allocates a **closure context** on the heap (1:1 with the closure); captures are **strong by default**. The memory graph shows contexts with references labeled only "capture" (no variable names) — double-click one to jump to the closure's source.
- **Implicit self trap**: assigning a *method* as a closure value (`generator = defaultAction`) strongly captures `self` → self-cycle. Replace with an explicit closure and a capture list.

#### weak vs unowned — Real Costs (WWDC24 10173)

- **weak**: the first weak reference to an object allocates a separate **weak-reference storage** side allocation, and accesses go through `swift_weakLoadStrong()`. At scale it matters — with 1,000,000 small objects the weak-storage overhead was about the size of the objects themselves. Still the safe default when lifetime isn't guaranteed.
- **unowned**: no side allocation, faster access, non-optional — but accessing after deallocation is a deterministic crash. Use **only** when the reference provably cannot outlive its destination (e.g. a closure stored by the very object it captures, never escaping): `generator = { [unowned self] in self.defaultAction($0) }`.
- Reducing reference-counting overhead generally: enable Whole-Module Optimization, specialize hot generics, and keep your most-copied structs **trivial** — avoid reference-type, copy-on-write (String/Array/Dictionary), and `any`-existential fields in hot structs. ❌ Never circumvent ARC with `Unmanaged`/manual retain-release to "save" refcount traffic — the resulting leaks cost far more than the overhead (WWDC24 10173).

## Xcode Memory Graph Debugger

### When to Use
- Leaks instrument shows leaks but you need to see **why** objects are retained
- You suspect retain cycles but can't find them in code review
- You need to see the **full ownership graph** of an object

### How to Use
1. Run app in **Debug** mode (not Profile)
2. Reproduce the state where objects should be deallocated
3. Click the **Memory Graph** button in Xcode's debug bar (looks like interconnected nodes)
4. Xcode pauses and captures the heap

### Reading the Graph
- **Left sidebar**: List of all live objects grouped by type
- **Purple exclamation marks**: Xcode-detected leaks / retain cycles
- **Center canvas**: Visual graph of object references
- Click an object to see its retain graph — who holds a strong reference to it

### Debugging Tips
- Filter by your module name to ignore system objects
- Look for **cycles** — two objects pointing at each other
- Check **backtrace** in the right sidebar to see where the object was allocated
- Export the graph: **File > Export Memory Graph** for sharing

### Enable Malloc Stack Logging
For full allocation backtraces in Memory Graph Debugger:
1. **Scheme > Run > Diagnostics**
2. Enable **Malloc Stack Logging** (Live Allocations Only)
3. Now the right sidebar shows the exact call stack that allocated each object

MSL also powers `malloc_history` and `leaks`' per-leak allocation stacks, and gives type context (e.g. "malloc in `PalmTree::growCoconut()`") where C/C++ allocations otherwise have none (WWDC24 10173). It has continuous per-allocation cost — enable it for investigations, not day-to-day runs.

## Command-Line memgraph Triage (WWDC21 10180)

A **memgraph** is a snapshot of your process's address space: address + size of every VM region and malloc block, plus the pointers between them. Capture one from Xcode's memory graph debugger (File > Export Memory Graph) or get them from performance tests (below). Apple's exact triage order:

1. **Always check leaks first**: `leaks post.memgraph`. A **ROOT CYCLE** header = retain cycle; with MSL you also get each leak's allocation call stack.
2. **No leaks? Check the heap**:
   - `vmmap -summary pre.memgraph` vs `post.memgraph` → confirm the footprint delta and find which region holds it — heap objects live in regions starting `MALLOC_`
   - `heap -diffFrom pre.memgraph post.memgraph` → objects in post but not pre, by class with counts + byte sums ("non-object" = raw malloc'd bytes in Swift)
   - `heap -addresses` (filterable, e.g. only non-objects ≥ 500 KB) → get culprit addresses
   - `leaks --traceTree <addr>` → tree of objects referencing that address (best when MSL is NOT available)
   - `leaks --referenceTree` (+ `--groupByType`) → top-down reference tree with root guesses — best when you know there's a big regression but not which objects
   - `malloc_history -fullStacks <addr>` → the allocation call stack for that address (requires MSL)
3. **Fragmentation**: `vmmap -summary`, per-zone `% FRAG` column and `dirty+swap frag size` (see the ≤25% rule above). In Instruments, the Allocations list's "persisted" objects keep pages dirty and "destroyed" objects created the free slots — investigate both.

## Memory Performance Tests: XCTMemoryMetric (WWDC21 10180)

Gate memory regressions in CI:

```swift
func testSaveMeal() {
    let app = XCUIApplication()
    let options = XCTMeasureOptions()
    options.invocationOptions = [.manuallyStart]
    measure(metrics: [XCTMemoryMetric(application: app)], options: options) {
        app.launch()
        startMeasuring()
        app.cells.firstMatch.buttons["Save meal"].firstMatch.tap()
        let savedButton = app.cells.firstMatch.buttons["Saved"].firstMatch
        XCTAssertTrue(savedButton.waitForExistence(timeout: 30))
    }
}
```

- Results average five iterations; set that average as a **baseline** so a future run failing it is a regression — "stop, investigate, and fix" (WWDC21 10180).
- Run via `xcodebuild` with the **`enablePerformanceTestsDiagnostics`** flag to collect **ktrace files** (for non-memory metrics — open in Instruments) and **memgraphs** (for memory metrics) attached to the `.xcresult` bundle.
- XCTest automatically enables malloc stack logging, and you get **two memgraphs per run** — `pre`-prefixed (start of the measured iteration) and `post`-prefixed (end) — ready for the `heap -diffFrom pre.memgraph post.memgraph` workflow above.

## Autorelease Pool Optimization

In tight loops creating Objective-C bridged objects:

```swift
// Bad — autoreleased objects accumulate until loop ends
for item in largeDataSet {
    let string = item.name as NSString       // Autoreleased
    let data = string.data(using: .utf8)     // Autoreleased
    process(data)
}
// Memory spikes until loop completes and pool drains

// Good — drain pool each iteration
for item in largeDataSet {
    autoreleasepool {
        let string = item.name as NSString
        let data = string.data(using: .utf8)
        process(data)
    }
}
// Memory stays flat — pool drains each iteration
```

### When autoreleasepool Matters
- Processing large collections (1000+ items)
- Creating temporary `NSString`, `NSData`, `NSNumber` objects in loops
- Image processing pipelines
- **Not needed** for pure Swift value types (String, Data, Array)

## Memory Footprint Tracking in Code

```swift
import os

func logMemoryFootprint() {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(
        MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
    )
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    if result == KERN_SUCCESS {
        let usedMB = Double(info.resident_size) / 1_048_576
        os_log("Memory footprint: %.1f MB", usedMB)
    }
}
```

## Why Your App Gets Killed (WWDC20 10078)

The six termination reasons — rank which actually hits your users with `MXAppExitMetric` (daily counts per exit cause, foreground + background) before debugging locally:

| # | Reason | Key facts | Field diagnostic |
|---|--------|-----------|------------------|
| 1 | Crash | Segfaults, illegal instructions, asserts | `MXCrashDiagnostic`, Organizer |
| 2 | Watchdog | Long hang during launch/background/foreground transitions — time limit on the order of **20 seconds**; never fires with debugger attached | `MXCrashDiagnostic` |
| 3 | CPU resource limit | Sustained high CPU **in the background** | `MXCPUExceptionDiagnostic`, Organizer energy logs |
| 4 | Memory footprint limit | Killed as footprint crosses the limit — **the limit is the same in foreground and background**; stay **< 200 MB** to support devices older than iPhone 6s | Allocations/Leaks, Memory Debugger |
| 5 | Jetsam (memory pressure) | The most common background kill; foreground app evicts backgrounded ones — **inevitable and unpredictable** | `MXAppExitMetric` |
| 6 | Background task timeout | `beginBackgroundTask` never ended within **30 seconds** of suspension — produces **no crash log**; counts appear only in `MXBackgroundExitData` | `MXAppExitMetric` |

Rules that follow:
- **Going to background, aim for < 50 MB** footprint — the smaller, the better. Drop caches and anything re-readable from disk in `didEnterBackground` (WWDC20 10078).
- ❌ Don't assume a kill will reproduce under the debugger — watchdog and jetsam kills specifically never do.
- **Save state on going background** (text field content, media playback position — UIKit State Restoration does the heavy lifting) so a jetsam relaunch is invisible: "many users won't even realize the app had been killed."
- For sustained background CPU work, use **BGProcessingTask** — several minutes of runtime while charging, without CPU resource limits.

### Background Task Hygiene (WWDC20 10078)

```swift
// ❌ Leaks the assertion: no name, no expiration handler, ID clobbered on reuse
self.taskID = UIApplication.shared.beginBackgroundTask()
upload(data) { self.taskID = .invalid }   // handler may never run

// ✅ Named task, local identifier, expiration handler that only cleans up + ends
var taskID: UIBackgroundTaskIdentifier = .invalid
taskID = UIApplication.shared.beginBackgroundTask(withName: "UploadPhotos") {
    // cleanup only — never kick off new work here
    UIApplication.shared.endBackgroundTask(taskID)
    taskID = .invalid
}
upload(data) {
    UIApplication.shared.endBackgroundTask(taskID)
    taskID = .invalid
}
```

- Always use the **named** variant so an unended task is identifiable in logs; always provide an expiration handler (it's safe to call `endBackgroundTask` inside it); call `endBackgroundTask()` immediately when work finishes — holding the assertion keeps the device awake.
- Budget before starting: estimate the work's duration (**use 5s as the lower bound**) and compare against `UIApplication.shared.backgroundTimeRemaining`; too little time → enqueue a `BGProcessingTask` instead.
- iOS 13.4+ prints a console message when a background task is held too long — watch for it during development. In the field, pair os_signpost begin/end events around the handler and compare counts in MetricKit payloads — imbalanced counts mean the handler hung or crashed.

## Quick Diagnosis Checklist
- [ ] Run Allocations with Generation Analysis — does memory grow across identical operations?
- [ ] Run Leaks instrument — any detected leaks? (Run suspect code ~100× in a loop to defeat conservative-reference false negatives)
- [ ] Check Memory Graph Debugger for retain cycles (purple warnings)
- [ ] Search for `self` in closures without `[weak self]` or `[unowned self]`
- [ ] Verify delegates are declared `weak`
- [ ] Check `NSCache` usage instead of plain dictionaries for caches — and verify cache **keys are stable** (a cache that never hits is a leak with extra steps)
- [ ] Verify images are downsampled to display size
- [ ] Use `autoreleasepool` in tight loops with ObjC-bridged objects
- [ ] Footprint = dirty + compressed — check `vmmap -summary` dirty/swapped columns, not virtual size
- [ ] Fragmentation ≤ 25% per malloc zone (`% FRAG` in `vmmap -summary`)
- [ ] Background footprint < 50 MB; total < 200 MB if supporting devices older than iPhone 6s
- [ ] Every `beginBackgroundTask` is named, has an expiration handler, and is ended on all paths
