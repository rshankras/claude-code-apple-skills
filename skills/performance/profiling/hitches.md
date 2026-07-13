# Hitches and the Render Loop

Scroll and animation hitches: what they are, the exact budgets and thresholds, the commit-phase and render-phase fix catalogs, and the Instruments/View Debugger workflow. Distilled from Apple's hitch Tech Talk trilogy: "Explore UI animation hitches and the render loop" (10855), "Find and fix hitches in the commit phase" (10856), and "Demystify and eliminate hitches in the render phase" (10857).

## The Render Loop (10855)

Five phases across three stages, each with a **VSYNC deadline**:

```
App process:      Events → Commit          (your code)
Render server:    Render Prepare → Render Execute   (separate process, YOUR layer tree)
Display:          frame on glass
```

- Frame budgets: **16.67 ms @ 60 Hz** (iPhone/iPad), **8.33 ms @ 120 Hz** (ProMotion).
- The pipeline is **double-buffered**: a frame is in flight two frame durations before display (app commits frame N while the render server renders N−1). The system may fall back to **triple buffering** (one extra frame of latency) to catch up — treat that as a fallback, reason in double-buffered terms.
- The render server is out-of-process, "but it works on your app's behalf — **you own the cost of rendering your layer tree**."

**A hitch = any frame that appears later than expected.** Hitch time is always a multiple of the frame duration: a **commit hitch** (your event+commit work misses VSYNC) or a **render hitch** (prepare/execute misses VSYNC) each slip delivery ≥1 frame.

## Hitch Time Ratio — The Metric and Its Thresholds (10855)

Raw hitch counts don't compare across runs (scroll durations differ, and iOS doesn't submit frames when nothing commits). Use **hitch time ratio = total hitch ms ÷ interval seconds**:

| Ratio (ms of hitch per second) | Verdict |
|---|---|
| 0 | The goal |
| < 5 | Good — mostly unnoticeable |
| 5–10 | Warning — users notice; investigate |
| > 10 | Critical — severely impacts UX; fix now |

Track it in production via MetricKit (`MXAnimationMetric` scroll hitch time ratio — WWDC20 10081) and in CI via XCTest (`XCTOSSignpostMetric.scrollDecelerationMetric`).

## Commit-Phase Hitches (10856)

The commit transaction has four sub-phases; know what triggers each:

| Sub-phase | What runs | Triggered by |
|---|---|---|
| Layout | `layoutSubviews` for every invalidated view | frame/position changes, add/remove views, `setNeedsLayout` |
| Display | `draw(_:)` into a CPU texture | `draw(_:)` overrides in newly added views, `setNeedsDisplay` |
| Prepare | image **decode** + color-format conversion copies | undecoded/GPU-unfriendly images |
| Package (commit) | layer tree serialized to the render server, **recursively** | deep hierarchies cost more — keep them shallow |

Fix catalog (all 10856):
- **`prepareForReuse` must not incur additional work.** The demo bug: `menuItem = nil` in `prepareForReuse` fired a `didSet` that tore down every tag subview per dequeue — defeating cell reuse entirely. Reconfigure existing subviews on the set-new-value path instead.
- **Never ship an empty `draw(_:)` override** — its mere presence forces a backing store allocation and extra commit work.
- Prefer GPU-accelerated `CALayer` properties over CPU custom drawing; **`isHidden` beats remove-from-hierarchy** for temporary hiding.
- **`setNeedsLayout`, not `layoutIfNeeded`** — `layoutIfNeeded` extends the *current* transaction and can itself cause the hitch; the coalesced next-runloop layout is almost always fine.
- Minimum Auto Layout constraints; and the invalidation rule: **a view may only invalidate itself or its children — never siblings or its parent** (otherwise layout re-invalidates recursively).

## Render-Phase Hitches: Offscreen Passes (10857)

**Offscreen pass = the GPU renders a layer somewhere other than the final texture, then copies it back.** The four triggers, and the fix for each:

| Trigger | Fix |
|---|---|
| Dynamic shadow (no `shadowPath`) | Set `layer.shadowPath` (demo: −5 passes/cell) |
| `layer.mask` around a subtree | `masksToBounds` for rect/rounded/ellipse clipping — or **no masking** if sublayers can't exceed bounds |
| `CAShapeLayer` rounded-rect "squircle" masks | `cornerRadius` + `cornerCurve = .continuous` (−2 passes) |
| `UIVisualEffectView` blur/vibrancy | Inherent cost (nav/tab bars) — accept it once, don't multiply it |

```swift
// ❌ dynamic shadow — renderer resolves the shape offscreen (5 passes in Apple's demo)
view.layer.shadowColor = UIColor.black.cgColor
view.layer.shadowOpacity = 0.5

// ✅ tell the renderer the exact shape
view.layer.shadowPath = UIBezierPath(
    roundedRect: view.layer.bounds,
    cornerRadius: view.layer.cornerRadius).cgPath
```

```swift
// ❌ CAShapeLayer mask for a squircle ("simple shape masking")
let shape = CAShapeLayer()
shape.path = UIBezierPath(roundedRect: imageView.bounds, cornerRadius: 10).cgPath
imageView.layer.mask = shape

// ✅ built-in continuous corners — zero offscreen passes
imageView.layer.cornerRadius = 10
imageView.layer.cornerCurve = .continuous
```

Apple's demo removed **36 offscreen passes → 0 with three small changes** — this class of fix is cheap and high-yield.

## Tooling Workflow

- **Instruments → Animation Hitches template**: lanes for Hitches (duration each), User Events, Commits (per phase), Renders/GPU, Frame Lifetimes, Display. Per-hitch details show **Hitch Duration**, **Acceptable Latency** (your real deadline — 33.34 ms double-buffered @ 60 Hz), **Hitch Type** (which phase — your starting hint), and **Buffer Count** (2 normally; 3 = system already catching up). The embedded Time Profiler pinpoints the code: select the hitch interval → committing process → main thread → call tree (10856).
- **Render/GPU track detail**: the **render count column = offscreen passes** for that frame (10857).
- **Xcode View Debugger**: Editor → Show Layers; the layer inspector shows per-layer **offscreen count + flags** (the reason). **Editor → Show Optimization Opportunities** surfaces purple badges written by Apple's performance teams. File → Export View Hierarchy… shares the whole thing (10857).
- The intended loop: Instruments finds the hitching frames → View Debugger confirms which layer and why → fix → re-profile.

## Checklist

- [ ] Hitch time ratio < 5 ms/s on target devices (0 is the goal); tracked in MetricKit + XCTest
- [ ] No work in `prepareForReuse`; cells reconfigure subviews in place
- [ ] No empty `draw(_:)` overrides; custom drawing justified by measurement
- [ ] `setNeedsLayout` (never `layoutIfNeeded` mid-transaction); views invalidate only self/children
- [ ] All shadows have `shadowPath`; rounded corners use `cornerRadius` + `cornerCurve`, never mask layers
- [ ] Masking dropped entirely where content can't exceed bounds
- [ ] View hierarchies shallow (package phase is recursive)
- [ ] Offscreen passes verified at ~0 in the View Debugger after fixes

## References

- [Tech Talk — Explore UI animation hitches and the render loop](https://developer.apple.com/videos/play/tech-talks/10855/)
- [Tech Talk — Find and fix hitches in the commit phase](https://developer.apple.com/videos/play/tech-talks/10856/)
- [Tech Talk — Demystify and eliminate hitches in the render phase](https://developer.apple.com/videos/play/tech-talks/10857/)
