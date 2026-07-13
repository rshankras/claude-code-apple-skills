---
name: performance-profiling
description: Guide performance profiling with Instruments, diagnose hangs, memory issues, slow launches, and energy drain. Use when reviewing app performance or investigating specific bottlenecks.
allowed-tools: [Read, Glob, Grep, Bash]
---

# Performance Profiling

Systematic guide for profiling Apple platform apps using Instruments, Xcode diagnostics, and MetricKit. Covers CPU, memory, launch time, and energy analysis with actionable fix patterns.

## When This Skill Activates

Use this skill when the user:
- Reports app hangs, stutters, or dropped frames
- Needs to profile CPU usage or find hot code paths
- Has memory leaks, high memory usage, or OOM crashes
- Wants to optimize app launch time
- Needs to reduce battery/energy impact
- Asks about Instruments, Time Profiler, Allocations, or Leaks
- Wants to add `os_signpost` or performance measurement to code
- Is preparing for App Store review and needs performance validation

## Decision Tree

```
What performance problem are you investigating?
│
├─ App hangs / unresponsive to taps / slow UI
│  └─ Read time-profiler.md
│
├─ Scroll or animation stutter / dropped frames / hitches
│  └─ Read hitches.md
│
├─ High memory / leaks / OOM crashes / growing footprint
│  └─ Read memory-profiling.md
│
├─ Slow app launch / time to first frame
│  └─ Read launch-optimization.md
│
├─ Battery drain / thermal throttling / background energy
│  └─ Read energy-diagnostics.md
│
├─ General "app feels slow" (unknown cause)
│  └─ Start with time-profiler.md, then memory-profiling.md
│
└─ Pre-release performance audit
   └─ Read ALL reference files, use Review Checklist below
```

## Quick Reference

| Problem | Instrument / Tool | Key Metric | Reference |
|---------|-------------------|------------|-----------|
| UI hangs > 250ms | Time Profiler + Hangs | Hang duration, main thread stack | time-profiler.md |
| Scroll/animation hitches | Animation Hitches template | Hitch time ratio (< 5 ms/s good, > 10 critical) | hitches.md |
| High CPU usage | Time Profiler / CPU Profiler | CPU % by function, call tree weight | time-profiler.md |
| Memory leak | Leaks + Memory Graph | Leaked bytes, retain cycle paths | memory-profiling.md |
| Memory growth | Allocations | Live bytes, generation analysis | memory-profiling.md |
| Slow launch | App Launch | Time to first frame (pre-main + post-main) | launch-optimization.md |
| Battery drain | Energy Log / Power Profiler | Energy Impact score, CPU/GPU/network | energy-diagnostics.md |
| Thermal issues | Activity Monitor | Thermal state transitions | energy-diagnostics.md |
| Network waste | Network profiler | Redundant fetches, large payloads | energy-diagnostics.md |

## The 8 Key Metrics (WWDC21 10181)

Apple enumerates exactly eight things to track for app performance, all coverable with five tools (Xcode Organizer, MetricKit, Instruments, XCTest, App Store Connect API):

| # | Metric | Threshold / signal | Tool |
|---|--------|--------------------|------|
| 1 | Battery usage | Energy Gauge flags **CPU use > 20%** as High CPU, plus CPU Wake Overhead regions; top subsystems to watch: CPU, Networking, Location | Energy Gauge → Time Profiler |
| 2 | Launch time | Time between icon tap and first frame rendered | App Launch template, XCTApplicationLaunchMetric |
| 3 | Hang rate | Unresponsive to input for **≥ 250ms** | Hangs instrument, Organizer |
| 4 | Memory | Organizer charts **peak memory** and **memory at suspension**; a spike with no termination spike yet is your early warning | Allocations, Leaks, VM Tracker |
| 5 | Disk writes | Exception report when the app writes **> 1 GB in 24 hours** (with stack trace + Insights annotations) | File Activity template, XCTStorageMetric |
| 6 | Scrolling | Red bars in the Organizer scrolling chart = poor scroll experience, fix immediately | Animation Hitches, XCTOSSignpostMetric.scrollDecelerationMetric |
| 7 | Terminations | Every termination forces a slow cold launch next time and loses user state | MXAppExitMetric, Organizer |
| 8 | MXSignposts | Custom marked intervals for your critical code sections | MetricKit |

The Organizer aggregates all of these from consented user devices across the **last 16 app versions**; the **Regressions pane** (Xcode 13) isolates every metric that increased significantly in the most recent version, in one place. The same data is available as JSON via the **App Store Connect API** (WWDC21 10181).

## Process

### 1. Identify the Problem Category

Ask the user or inspect their description to classify the issue:
- **Responsiveness**: Hangs, stutters, animation drops
- **Memory**: Leaks, growth, OOM crashes
- **Launch**: Slow cold/warm start
- **Energy**: Battery drain, thermal throttling

### 2. Read the Appropriate Reference File

Each file contains:
- Which Instruments template to use
- Step-by-step profiling workflow
- How to interpret results
- Common fix patterns with code examples

### 3. Profile on Real Hardware

Always remind users:
- **Profile on device**, not Simulator (Simulator uses host CPU/memory)
- Use **Release** build configuration (optimizations change behavior)
- Profile with **representative data** (empty databases hide real perf)
- Close other apps to reduce noise

### 4. Apply Fixes and Verify

After identifying bottlenecks:
- Apply targeted fix from the reference file
- Re-profile to confirm improvement
- Add `os_signpost` markers for ongoing monitoring

## Xcode Diagnostic Settings

Recommend enabling these in **Scheme > Run > Diagnostics**:

| Setting | What It Catches |
|---------|-----------------|
| Main Thread Checker | UI work off main thread |
| Thread Sanitizer | Data races |
| Address Sanitizer | Buffer overflows, use-after-free |
| Malloc Stack Logging | Memory allocation call stacks |
| Zombie Objects | Messages to deallocated objects |

## MetricKit Integration

For production monitoring, recommend MetricKit (WWDC20 10081, WWDC21 10181):

```swift
import MetricKit

final class PerformanceReporter: NSObject, MXMetricManagerSubscriber {
    func startCollecting() {
        MXMetricManager.shared.add(self)   // subscribe once, early in launch
    }
    // best practice: remove(self) in deinit (WWDC21 10181)

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // Launch time
            if let launch = payload.applicationLaunchMetrics {
                log("Resume time: \(launch.histogrammedResumeTime)")
            }
            // Hang rate
            if let responsiveness = payload.applicationResponsivenessMetrics {
                log("Hang time: \(responsiveness.histogrammedApplicationHangTime)")
            }
            // Memory
            if let memory = payload.memoryMetrics {
                log("Peak memory: \(memory.peakMemoryUsage)")
            }
            // Scroll hitches (ratio of time hitching to time scrolling)
            if let animation = payload.animationMetrics {
                log("Scroll hitch ratio: \(animation.scrollHitchTimeRatio)")
            }
            // Exit reasons — daily counts per termination cause, fg + bg
            if let exits = payload.applicationExitMetrics {
                log("Exits: \(exits.backgroundExitData)")
            }
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            if let hangs = payload.hangDiagnostics {
                for hang in hangs {
                    log("Hang: \(hang.callStackTree)")
                }
            }
        }
    }
}
```

Key facts (WWDC20 10081, WWDC21 10181):
- ❌ Subscribing lazily (e.g. in a settings screen) silently misses delivered payloads — ✅ subscribe in App/AppDelegate init; the previous day's payloads are handed to you on launch.
- Metrics arrive as **24-hour payloads**, at most once per day, in three aggregation forms: cumulative, averaged, and bucketized (`MXHistogram`). On iOS 15+/macOS 12+, **all diagnostics are delivered immediately after the issue occurs** instead of daily.
- Termination and memory telemetry arrive in the daily metric payload by default — no extra instrumentation.
- Diagnostic types: **`MXHangDiagnostic`** (main-thread unresponsive time + backtraces), **`MXCrashDiagnostic`** (exception info, termination reason, VM region info), **`MXCPUExceptionDiagnostic`** (threads burning CPU — the programmatic form of Organizer energy logs), **`MXDiskWriteExceptionDiagnostic`** (fires on the 1 GB/day write threshold).
- **`MXCallStackTree`** backtraces are **unsymbolicated** by design — symbolicate off-device with `atos`-class tools + your dSYMs; ❌ don't try on-device.
- **`MXSignpost`** marks critical code sections for field telemetry; the animation variant captures hitch-rate telemetry for the interval:

```swift
let handle = MXMetricManager.makeLogHandle(category: "animation_telemetry")
mxSignpostAnimationIntervalBegin(log: handle, name: "custom_animation")
// ... animation ...
mxSignpost(OSSignpostType.end, log: handle, name: "custom_animation")
```

## Review Checklist

### Responsiveness
- [ ] No synchronous work on main thread > 100ms
- [ ] No file I/O or network calls on main thread
- [ ] Core Data / SwiftData fetches use background contexts for large queries
- [ ] Images decoded off main thread (use `.preparingThumbnail` or async decoding)
- [ ] `@MainActor` only on code that truly needs UI access

### Memory
- [ ] No retain cycles (check delegate patterns, closures with `self`)
- [ ] Large resources freed when not visible (images, caches)
- [ ] Collections don't grow unbounded (capped caches, pagination)
- [ ] `autoreleasepool` used in tight loops creating ObjC objects

### Launch Time
- [ ] No heavy work in `init()` of `@main App` struct
- [ ] Deferred non-essential initialization (analytics, prefetch)
- [ ] Minimal dynamic frameworks (prefer static linking)
- [ ] No synchronous network calls at launch

### Energy
- [ ] Background tasks use `BGProcessingTaskRequest` appropriately
- [ ] Location accuracy matches actual need (not always `.best`)
- [ ] Timers use `tolerance` to allow coalescing
- [ ] Network requests batched where possible

## References

- **time-profiler.md** — CPU profiling, hang detection ladder, signpost API, Instruments 27 tools
- **hitches.md** — Render loop, hitch time ratio, commit/render-phase fix catalogs
- **memory-profiling.md** — Allocations, Leaks, memory graph debugger, memgraph CLI, termination reasons
- **launch-optimization.md** — App launch phases, cold/warm start optimization, linker levers
- **energy-diagnostics.md** — Battery, thermal state, network efficiency, Power Profiler
- [WWDC: Ultimate Application Performance Survival Guide](https://developer.apple.com/videos/play/wwdc2021/10181/)
- [WWDC: Understand and Eliminate Hangs from Your App](https://developer.apple.com/videos/play/wwdc2021/10258/)
- [WWDC: Track Down Hangs with Xcode and On-Device Detection](https://developer.apple.com/videos/play/wwdc2022/10082/)
- [WWDC: Analyze Hangs with Instruments](https://developer.apple.com/videos/play/wwdc2023/10248/)
- [WWDC: Detect and Diagnose Memory Issues](https://developer.apple.com/videos/play/wwdc2021/10180/)
- [WWDC: Analyze Heap Memory](https://developer.apple.com/videos/play/wwdc2024/10173/)
- [WWDC: Why Is My App Getting Killed?](https://developer.apple.com/videos/play/wwdc2020/10078/)
- [WWDC: What's New in MetricKit](https://developer.apple.com/videos/play/wwdc2020/10081/)
- [WWDC: Optimizing App Launch](https://developer.apple.com/videos/play/wwdc2019/423/)
- [WWDC: Optimize CPU Performance with Instruments](https://developer.apple.com/videos/play/wwdc2025/308/)
- [WWDC: Profile and Optimize Power Usage in Your App](https://developer.apple.com/videos/play/wwdc2025/226/)
- [WWDC: Profile, Fix, and Verify — Improve App Responsiveness with Instruments](https://developer.apple.com/videos/play/wwdc2026/268/)
