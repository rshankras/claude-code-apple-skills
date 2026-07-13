# Time Profiler & Hang Detection

## Instruments Setup

### Time Profiler Template
1. **Xcode > Product > Profile** (Cmd+I) — builds Release and opens Instruments
2. Choose **Time Profiler** template
3. Click record, reproduce the slow operation, stop recording

### Key Settings
- **Recording Mode**: Deferred — analyze after recording stops instead of live; minimizes tool overhead, especially when the workload runs on the same machine as Instruments (WWDC25 308)
- **Sampling**: Time Profiler samples on a hardware timer at a 1ms default interval; calls that begin and end between samples are never recorded, though frequently-called functions are likelier to be sampled (WWDC26 268)
- **Record Waiting Threads**: Enable to see threads blocked on locks/IO
- **Always profile a Release build** — Product > Profile builds Release automatically; Debug builds trade runtime performance for debuggability and their profiles can be misleading (WWDC26 268)

## Reading Time Profiler Results

### Call Tree Navigation
- **Weight**: Total time spent in function + all children
- **Self Weight**: Time in just that function (no children)
- **Symbol Name**: Function/method being sampled

### Essential Filters
| Filter | Purpose |
|--------|---------|
| Separate by Thread | Isolate main thread from background |
| Invert Call Tree | Show leaf functions first (where time is actually spent) |
| Hide System Libraries | Focus on your code |
| Flatten Recursion | Collapse recursive calls into one entry |

### Typical Workflow
1. **Separate by Thread** — find Main Thread
2. **Invert Call Tree** — heaviest leaf functions appear at top
3. **Hide System Libraries** — focus on your functions
4. Click disclosure triangle to trace back through the call chain
5. Double-click a function to jump to source code

## Time Profiler vs CPU Profiler (WWDC25 308)

Two different sampling models — pick deliberately:

| | Time Profiler | CPU Profiler |
|---|---|---|
| Sampling | All CPUs on one shared **timer** | Each CPU independently, driven by that CPU's **cycle counter** |
| Best for | How work distributes over time; which threads run simultaneously | Measuring and optimizing CPU cost |
| Weakness | **Aliasing** — periodic work at the same cadence as the timer gets unfairly over-represented | Not a timeline of wall-clock behavior |

- Apple silicon cores are **asymmetric** (E-cores clock slower); CPU Profiler samples faster cores more often, so function weights are fair. **Prefer CPU Profiler over Time Profiler when the goal is CPU optimization** (WWDC25 308).
- Before optimizing at all, try to **avoid the work**, in this order: delete the code → defer it off the critical path → precompute (even at build time) → cache repeated same-input operations. Only then make the CPU faster (WWDC25 308).
- Handy call-tree shortcuts: Option-click a chevron expands until sample counts diverge; the arrow next to a function name offers **Focus on Subtree**; secondary-click a Points of Interest region → **Set Inspection Range** (WWDC25 308).

## Hang Detection

### What Counts as a Hang
| Duration | Classification | User Perception |
|----------|---------------|-----------------|
| < 100ms | Instant | Feels immediate — keep every main-thread work item under ~100ms (WWDC23 10248) |
| 100–250ms | Gray zone | Becoming noticeable (WWDC23 10248) |
| 250–500ms | Micro-hang | Noticeable but easy to miss; 250ms is the OS-level hang reporting threshold (WWDC23 10248, WWDC21 10181) |
| 500ms–1s | Hang | Clearly noticeable, unacceptable (WWDC23 10248) |
| > 1s | Severe hang | "A delay of over one second will always look like a hang" (WWDC21 10258) |
| ~20s during launch/background/foreground transitions | Watchdog kill | System terminates the app; never reproduces with the debugger attached (WWDC20 10078) |

Context matters: a half-second delay **while scrolling** is jarring, the same delay entering a view is far less noticeable (WWDC21 10258). Request-response interactions can tolerate ~500ms **if** there's intermediate feedback (e.g. button highlight) before the result (WWDC23 10248). Hang detection flags long main-thread work items regardless of whether input actually arrived — input could come at any time (WWDC23 10248).

### Using the Hangs Instrument
1. Open Instruments, choose **Time Profiler** (includes Hang detection lane)
2. Or use the standalone **Animation Hitches** template for scroll/animation stalls — see [hitches.md](hitches.md) for the full render-loop workflow and hitch fix catalog
3. Record and reproduce the interaction
4. Orange = micro-hang band (250–500ms), red = severe (> 500ms) in the Hangs lane (WWDC23 10248)
5. Right-click a hang interval → **Set Inspection Range and Zoom** to filter every detail view to it, then read the main thread call stack (WWDC23 10248)
6. A standalone **Hang Tracing** instrument can be added to any trace and supports a custom hang-duration threshold (WWDC22 10082)

Trust the **Hangs instrument** — not the thread state — to decide whether an interval is a user-visible hang: a blocked main thread is not automatically a responsiveness bug (WWDC23 10248).

### The Hang-Detection Ladder (WWDC22 10082)

Fix hangs at the earliest stage possible; proactively profile new features rather than waiting for field data.

**Stage 1 — Development (at your desk):**
- **Thread Performance Checker** (Scheme > Run > Diagnostics) — flags priority inversions and non-UI work on the main thread in the Issue navigator, no trace recording needed
- **Time Profiler / CPU Profiler** — hangs are detected and labeled by default in the process track with their duration; triple-click a hang interval to set a time filter

**Stage 2 — Beta / dogfooding (no Xcode attached):**
- **On-device hang detection** (iOS 16+): *Settings ▸ Developer ▸ Hang Detection*. Works for **development-signed and TestFlight builds**. Selectable threshold (250ms / 500ms / higher). Shows real-time hang notifications, then produces a **text hang log** (transfer to a Mac to symbolicate) and a **tailspin** (open in Instruments for full thread-interaction detail). Diagnostics process in the background at low priority, best-effort — the notification may arrive later if the system is busy.
- **MetricKit** — per-user (non-aggregated) hang-rate metrics and hang diagnostics; works in beta **and** App Store builds.

**Stage 3 — Public release (App Store):**
- **Xcode Organizer ▸ Hangs** (Xcode 14) — aggregated hang reports from customers who opted in to share analytics. Similar main-thread stacks are grouped into **signatures sorted by user impact**, with per-signature log counts, % of total hang time, OS/device breakdown, and sample logs.
- **Submit symbols with your build** so Organizer shows function names with one-click jump to source (only function names, file paths, and line numbers are uploaded).
- Turn on **regression notifications** (Notifications button, top-right of Organizer) to get alerted when hang rate spikes after a release.
- **Power & Performance REST API** — the same hang-report data for your own dashboards.

### Busy vs Blocked: The First Triage Question (WWDC23 10248, WWDC26 268)

During the hang interval, what is the main thread's CPU doing?

- **CPU high (~100%) → busy.** The code is a performance bottleneck: optimize the algorithm or offload to a background task. Diagnose with Time Profiler call trees, using the direction rule:
  - Function slow in a **single call** → look **down** at its callees and optimize them
  - Function cheap per call but **called many times** → look **up** at callers and cut the call count (100 calls × 5ms = a 500ms hang)
  - Use **Heaviest Stack Trace** to jump to the hot node; enable *Call Tree ▸ Hide System Libraries*
- **CPU low/idle → blocked.** Optimizing algorithms won't help; the main thread is waiting on file I/O, a lock, or IPC. Time Profiler only sees active CPU cycles and is blind here — use the **Thread State Trace** instrument (its narrative names the blocking syscall; in the backtrace the leaf is the syscall, the parent frames are your cause) or **System Trace**. In Instruments 27, the System Trace **Inspector panel** shows exact syscall arguments — the demo caught a 1.7 GB `write` on the main thread taking > 500ms (WWDC26 268). Note that low-but-nonzero CPU (~20%) can still mean blocked: brief wake-ups between waits produce that shape.
- Two hang shapes: **synchronous** (the interaction itself triggers the long work) and **asynchronous** (work enqueued earlier via `dispatch_async` / a main-actor Task delays a later event) (WWDC23 10248).
- Time Profiler is a **sampler** — it cannot distinguish one long call from many short calls. Disambiguate with `os_signpost` or specialized instruments: **SwiftUI View Body** (per-body execution count + duration) and **Swift Concurrency Tasks** (which thread each task runs on — catches tasks unexpectedly on the main thread) (WWDC23 10248).

### The 7 Hang Anti-Patterns (WWDC21 10258)

Watch for these in code review — three make the main thread **busy**, four **block** it:

**Busy:**
1. Proactively doing unnecessary work (loading ALL images when the view shows only 4)
2. Irrelevant work pushed onto main (e.g. via `dispatch_sync` from other queues)
3. Suboptimal APIs (CPU-based image processing where GPU/Core Animation would do)

**Blocked:**
4. Synchronous network requests on main
5. File I/O on main / synchronous APIs with unpredictable duration
6. Blocking on synchronization primitives: `@synchronized`, `dispatch_sync`, `os_unfair_lock`, POSIX locks — and the named anti-pattern: faking sync by **waiting on a semaphore, which "should always be avoided on the main thread"**
7. Expensive on-demand queries of frequently-read but rarely-changing values (e.g. querying the contacts database on every tap)

Also: `dispatch_sync` onto a low-priority serial queue with a backlog stalls main for the **whole backlog**, not just your block.

**The four fix patterns (WWDC21 10258):**
- **Cache** frequently used assets / previously queried values (`NSCache` for formatted image tiles: "the overhead of generating assets is replaced by a quick memory read"). Two obligations: an accurate invalidation mechanism, and cache updates happening asynchronously on a secondary queue. Caches use memory — watch their size.
- **Notification observers over polling**: register for change notifications (any class can post them; see the `NSNotification.Name` docs for system ones), update a cached value in a handler dispatched to another queue. Filter or coalesce chatty notifications.
- **Async API counterparts**: spot them by the word "asynchronously" or a completion handler in the method name.
- **GCD**: `dispatch_async` to another queue, completion handler dispatched back to main. **Pre-warm**: async the task onto a prefetch queue early; when main finally needs the result, `dispatch_sync` onto that serial queue to wait only for the remainder.

```swift
// ❌ Faking sync with a semaphore on main — "should always be avoided" (WWDC21 10258)
let sem = DispatchSemaphore(value: 0)
fetchAsync { result = $0; sem.signal() }
sem.wait()                                    // main thread blocked

// ✅ Async offload + completion back on main
queue.async {
    let image = process(data)
    DispatchQueue.main.async { imageView.image = image }
}
```

### Common Hang Causes and Fixes

#### Synchronous File I/O on Main Thread

```swift
// Bad — blocks main thread
func loadData() -> Data {
    return try! Data(contentsOf: largeFileURL)
}

// Good — move to background
func loadData() async -> Data {
    return try! await Task.detached {
        try Data(contentsOf: largeFileURL)
    }.value
}
```

#### Synchronous Network Call

```swift
// Bad — URLSession.shared.dataTask is async but
// this pattern blocks main thread waiting for result
let data = try! Data(contentsOf: remoteURL)

// Good — use async/await
let (data, _) = try await URLSession.shared.data(from: remoteURL)
```

#### Heavy Computation on Main Thread

```swift
// Bad — sorting/filtering large arrays on main thread
func updateUI() {
    let sorted = hugeArray.sorted { $0.score > $1.score }
    tableView.reloadData()
}

// Good — offload computation
func updateUI() async {
    let sorted = await Task.detached {
        hugeArray.sorted { $0.score > $1.score }
    }.value
    tableView.reloadData()
}
```

#### Core Data / SwiftData Fetch on Main Thread

```swift
// Bad — fetching thousands of objects blocks UI
let items = try context.fetch(FetchDescriptor<Item>())

// Good — use background context (SwiftData)
let items = try await Task.detached {
    let context = ModelContext(container)
    return try context.fetch(FetchDescriptor<Item>())
}.value
```

#### Image Decoding on Main Thread

```swift
// Bad — decoding happens lazily on first display, blocking main thread
imageView.image = UIImage(contentsOfFile: path)

// Good — decode off main thread (iOS 15+)
let thumbnail = await UIImage(contentsOfFile: path)?
    .byPreparingThumbnail(ofSize: targetSize)
imageView.image = thumbnail

// Good — using preparingForDisplay
let decoded = await UIImage(contentsOfFile: path)?
    .byPreparingForDisplay()
```

#### Lazy Singleton Blocking Inside .task (WWDC23 10248)

Two rules that make "async" code hang the main thread anyway:
- `View.body` is `@MainActor`, and `.task {}` / `.onAppear {}` closures **inherit that isolation** — an async task can still run entirely on the main thread.
- `await` only suspends at calls to `async` functions. `try await Service.shared.doWork()` still runs the synchronous `shared` initializer (e.g. a lazy `static let` loading an ML model) **on the main thread** — the `await` belongs to `doWork`, not `shared`.

```swift
// Bad — lazy singleton with a seconds-long MLModel load; first access blocks main
class ColorizingService { static let shared = ColorizingService() }
.task { let c = ColorizingService.shared            // blocks main thread
        image = try await c.colorize(image) }

// Good — async accessor: await suspends; init runs off the main actor
class ColorizingService {
    static var shared: ColorizingService { get async { /* build off-main */ } }
}
.task { let c = await ColorizingService.shared      // suspends, no block
        image = try await c.colorize(image) }
```

`Task.detached` also works but is the last resort: it's an expensive unstructured task and SwiftUI's `.task` cancellation does **not** propagate into it (WWDC23 10248).

#### Main-Actor-Inherited Tasks (WWDC26 268)

A `Task {}` created in SwiftUI context inherits the Main Actor — heavy work inside it competes with UI updates (the session demo: thumbnail renders each burning a few hundred ms on the Main Actor → janky scrolling). Mark the closure `@concurrent` to route it to the global concurrent executor; the compiler verifies the move introduces no data races.

```swift
// Bad — task inherits the Main Actor from SwiftUI; rendering blocks UI
thumbnail = await Task(name: "Render Thumbnail") {
    await renderThumbnail(...)
}.value

// Good — @concurrent routes the task to the global concurrent executor
thumbnail = await Task(name: "Render Thumbnail") { @concurrent in
    await renderThumbnail(...)
}.value
```

The same pattern fixes synchronous writes: encode + `data.write(to:options:.atomic)` inside a `Task { @concurrent in }` instead of on the main thread (WWDC26 268).

## os_signpost API for Custom Profiling

Add signposts to measure specific operations in Instruments:

```swift
import os

extension OSSignpostID {
    static let dataLoad = OSSignpostID(log: .performance)
}

extension OSLog {
    static let performance = OSLog(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "Performance"
    )
}

// Mark intervals
func loadData() async throws -> [Item] {
    let signpostID = OSSignpostID(log: .performance)
    os_signpost(.begin, log: .performance, name: "DataLoad", signpostID: signpostID)
    defer {
        os_signpost(.end, log: .performance, name: "DataLoad", signpostID: signpostID)
    }

    // ... actual work
    return items
}

// Mark events (single point)
os_signpost(.event, log: .performance, name: "CacheMiss")
```

### Viewing Signposts in Instruments
1. Add **os_signpost** instrument to your trace
2. Filter by subsystem/category to find your markers
3. Intervals show as bars with duration, events show as points

### OSSignposter with Points of Interest (WWDC26 268)

Use `category: .pointsOfInterest` so Instruments surfaces your intervals automatically — no extra instrument needed — and use the interval's context menu to filter the trace to exactly that time period. Reliable signpost intervals are also what make before/after Run Comparisons trustworthy.

```swift
let signposter = OSSignposter(subsystem: "Demo App", category: .pointsOfInterest)
let state = signposter.beginInterval("Lasso Selection")
// ... work ...
signposter.endInterval("Lasso Selection", state)
```

For lightweight throughput tests, wrap a repeat-while loop calling the workload in a Points of Interest signpost interval and time it with **`ContinuousClock`, not `Date`** — ContinuousClock can't go backwards and has low overhead (WWDC25 308).

## Thread Performance Checker

Enable in **Scheme > Run > Diagnostics > Thread Performance Checker** (WWDC22 10082).

Detects at runtime:
- **Priority inversions**: High-priority thread (e.g. main) synchronously waiting on a lower-priority thread
- **Non-UI work on main thread**: Disk I/O, network calls detected on main
- **Excessive thread creation**: Spawning too many threads

Issues appear as purple runtime warnings in Xcode's Issue Navigator — no trace recording required. This is stage 1 of the hang-detection ladder above.

## Processor Trace and CPU Counters (WWDC25 308)

When sampling profilers aren't enough, escalate in this order: **profilers → Processor Trace → CPU Counters**. Fix software/runtime overheads first, or the CPU-hardware tools are confounded by them.

### Processor Trace
- Records **every instruction executed in user space** — no sampling bias, ~1% performance impact. Available starting Instruments 16.3.
- Hardware: Mac and iPad Pro with **M4**, or iPhone with **A18**. Enable via Settings > Privacy & Security > Developer Tools (Mac) or the Developer section (iOS).
- Data volume can be **gigabytes per second** — limit tracing to a few seconds; a single run of the target code suffices (no batching needed, unlike samplers).
- UI: a per-thread **function-call flame graph over time** showing calls exactly as executed (inspect a single call that ran a few hundred nanoseconds). Colors: brown = system frameworks, magenta = Swift runtime/stdlib, blue = your code.

### CPU Counters — Guided Bottleneck Analysis
- Instruments 26 adds **preset modes** with guided, iterative bottleneck analysis. Start in **CPU Bottlenecks** mode: all CPU potential is split into four categories as a stacked bar chart + summary table.
- A dominant category produces a **remark** in the timeline; the details table's **Suggested Next Mode** column tells you which mode to re-profile in (e.g. "Discarded Sampling" for branch mispredictions, "L1D Cache Miss Sampling" for memory-layout problems). Sampling modes capture the **exact instruction** causing the event, not a call stack.
- After each fix, return to CPU Bottlenecks mode to see how the change shifted the remaining bottlenecks — and **know when to stop**: once the code no longer impacts the critical path, optimize elsewhere.

Typical escalation payoffs from the session's binary-search demo: replace generic `Collection` with `Span` for contiguous data (4×), specialize generics across framework boundaries via `@inlinable` or manual specialization (1.7×), branchless rewrites for random-direction branches (2×), cache-friendly data layout (2×) — but Apple's own caveat: the last two are where micro-optimization becomes "fragile and easy to disrupt."

## Instruments 27 Additions (WWDC26 268)

- **Top Functions mode** — a third analysis mode beside call tree and flame graph. It discards call hierarchy and merges every scattered node of a function into one block ranked by **self weight**; the right side shows a flame graph of all code paths that called into the selected function. Use it when cost is smeared across many call sites (Swift runtime functions, shared helpers) with no single hot spot.
- **Run Comparisons** — record baseline and optimized runs in one document, filter **both to the same os_signpost interval**, select the main-thread track, click the compare button, pick the baseline. Per-function deltas: **red = regression, green = improvement**; comparisons are saved in the document. Caveat: a fix that introduces new functions (e.g. generic specializations replacing existentials) shows them as "regressions" — judge the overall delta.
- **Swift Executors instrument** — visualizes the Main Actor, the global concurrent executor, and custom executors as tracks; selecting the Main Actor track summarizes every task that ran on it. The tool that catches Main-Actor-inherited tasks (see fix above).
- **Inspector panel** — right-hand contextual panel with details + actions for the current selection (pin the main thread, read syscall arguments).
- A classic Top Functions find: **`swift_project_boxed_opaque_existential`** ranked #1 — the runtime function that unwraps `any Protocol` values on every access. Fix: replace existentials with **concrete types, generics, or enums**.

```swift
// Bad — existential parameter: boxed, runtime unwrap on every access (hot path)
func bar(_ foo: any Foo) { ... }

// Good — generic, specialized at compile time
func bar<T: Foo>(_ generic: T) { ... }
// or concrete overloads, or an enum: enum Foo { case a(TypeA); case b(TypeB) }
```

## Profiling Tips

### Profile What Matters
- Always profile on **physical device** — Simulator has different CPU/memory characteristics
- Use **Release** configuration — Debug builds disable compiler optimizations
- Profile with **realistic data** — 10 items vs 10,000 items reveals different bottlenecks
- **Warm the app first** — first run includes one-time setup that skews results

### Interpreting Results
- Focus on **Self Weight** to find actual bottlenecks (not just call tree weight)
- A function with high weight but low self-weight is just a caller — dig deeper
- Compare **before/after** traces to validate fixes
- Look for **repeated patterns** — a function called 1000x at 1ms each = 1s hang

### Quick Wins Checklist
- [ ] Move all file I/O off main thread
- [ ] Decode images asynchronously
- [ ] Use `@MainActor` sparingly — only for actual UI updates
- [ ] Batch database writes instead of single-row inserts
- [ ] Cache expensive computations (JSON parsing, date formatting)
- [ ] Use `DateFormatter` / `NumberFormatter` as shared instances (creation is expensive)
