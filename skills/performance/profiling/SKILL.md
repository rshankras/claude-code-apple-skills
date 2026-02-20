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
├─ App hangs / stutters / dropped frames / slow UI
│  └─ Read time-profiler.md
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
| High CPU usage | Time Profiler | CPU % by function, call tree weight | time-profiler.md |
| Memory leak | Leaks + Memory Graph | Leaked bytes, retain cycle paths | memory-profiling.md |
| Memory growth | Allocations | Live bytes, generation analysis | memory-profiling.md |
| Slow launch | App Launch | Time to first frame (pre-main + post-main) | launch-optimization.md |
| Battery drain | Energy Log | Energy Impact score, CPU/GPU/network | energy-diagnostics.md |
| Thermal issues | Activity Monitor | Thermal state transitions | energy-diagnostics.md |
| Network waste | Network profiler | Redundant fetches, large payloads | energy-diagnostics.md |

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

For production monitoring, recommend MetricKit:

```swift
import MetricKit

final class PerformanceReporter: NSObject, MXMetricManagerSubscriber {
    func startCollecting() {
        MXMetricManager.shared.add(self)
    }

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

- **time-profiler.md** — CPU profiling, hang detection, signpost API
- **memory-profiling.md** — Allocations, Leaks, memory graph debugger
- **launch-optimization.md** — App launch phases, cold/warm start optimization
- **energy-diagnostics.md** — Battery, thermal state, network efficiency
- [WWDC: Ultimate Application Performance Survival Guide](https://developer.apple.com/videos/play/wwdc2021/10181/)
- [WWDC: Analyze Hangs with Instruments](https://developer.apple.com/videos/play/wwdc2023/10248/)
- [WWDC: Detect and Diagnose Memory Issues](https://developer.apple.com/videos/play/wwdc2021/10180/)
