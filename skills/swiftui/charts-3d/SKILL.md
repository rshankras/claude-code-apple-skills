---
name: charts-3d
description: 3D chart visualization with Swift Charts using Chart3D, SurfacePlot, interactive pose control, and surface styling — plus a 2D Swift Charts construction reference (marks, axes, selection, SectorMark, scrollable charts). Use when creating data visualizations with Swift Charts.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# 3D Charts with Swift Charts

Create 3D data visualizations using `Chart3D` and `SurfacePlot`. Covers math-driven surfaces, data-driven surfaces, interactive camera pose control, surface styling, and camera projection modes.

## When This Skill Activates

Use this skill when the user:
- Wants to create a 3D chart or 3D data visualization
- Asks about `Chart3D`, `SurfacePlot`, or 3D surface plots
- Needs to visualize a mathematical function as a 3D surface
- Wants interactive drag-to-rotate on a 3D chart
- Asks about 3D chart camera angles, pose, or projection
- Needs to style 3D surfaces with gradients or height-based coloring
- Wants to render multiple surfaces in a single 3D chart
- Asks about data-driven 3D plots from an array of points
- Needs the 2D Swift Charts API layer: marks, axes, series styling, selection, SectorMark pies/donuts, or scrollable charts

## Decision Tree

```
What 3D chart feature do you need?
|
+-- Visualize a math function f(x, y) -> z
|   +-- Use SurfacePlot(x:y:z:function:)
|
+-- Visualize data points as a surface
|   +-- Use Chart3D(data) { point in SurfacePlot(...) }
|
+-- Interactive drag-to-rotate
|   +-- Bind pose: .chart3DPose($pose) with @State var pose: Chart3DPose
|
+-- Fixed viewing angle (no interaction)
|   +-- Read-only pose: .chart3DPose(Chart3DPose.front) or custom
|
+-- Style the surface color
|   +-- Solid color -> .foregroundStyle(Color.blue)
|   +-- Gradient -> .foregroundStyle(LinearGradient(...))
|   +-- Height-based -> .foregroundStyle(.heightBased(gradient, yRange:))
|   +-- Normal-based -> .foregroundStyle(.normalBased)
|
+-- Camera projection
|   +-- Perspective (depth) -> .chart3DCameraProjection(.perspective)
|   +-- Orthographic (flat) -> .chart3DCameraProjection(.orthographic)
|   +-- System default -> .chart3DCameraProjection(.automatic)
|
+-- Multiple surfaces in one chart
    +-- Place multiple SurfacePlot calls inside a single Chart3D { }
```

## API Availability

| API | Minimum Version | Import | Notes |
|-----|----------------|--------|-------|
| `Chart3D` | iOS 26 / macOS 26 | `Charts` | Main 3D chart container |
| `SurfacePlot` | iOS 26 / macOS 26 | `Charts` | 3D surface mark |
| `Chart3DPose` | iOS 26 / macOS 26 | `Charts` | Viewing angle control |
| `Chart3DCameraProjection` | iOS 26 / macOS 26 | `Charts` | `.automatic`, `.perspective`, `.orthographic` |
| `Chart3DSurfaceStyle` | iOS 26 / macOS 26 | `Charts` | `.heightBased`, `.normalBased` |

## Quick Start

### Math-Driven Surface

Render a surface from a function `f(x, y) -> z`:

```swift
import SwiftUI
import Charts

struct WaveSurfaceView: View {
    var body: some View {
        Chart3D {
            SurfacePlot(
                x: "X",
                y: "Height",
                z: "Z",
                function: { x, z in
                    sin(x) * cos(z)
                }
            )
            .foregroundStyle(.blue)
        }
    }
}
```

### Data-Driven Surface

Render a surface from an array of data points:

```swift
import SwiftUI
import Charts

struct DataPoint: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let z: Double
}

struct DataSurfaceView: View {
    let points: [DataPoint]

    var body: some View {
        Chart3D(points) { point in
            SurfacePlot(
                x: .value("X", point.x),
                y: .value("Height", point.y),
                z: .value("Z", point.z)
            )
        }
    }
}
```

### Interactive Rotation

Allow the user to drag to rotate the chart:

```swift
import SwiftUI
import Charts

struct InteractiveChartView: View {
    @State private var pose = Chart3DPose.default

    var body: some View {
        Chart3D {
            SurfacePlot(
                x: "X",
                y: "Height",
                z: "Z",
                function: { x, z in
                    sin(x) * cos(z)
                }
            )
            .foregroundStyle(.blue)
        }
        .chart3DPose($pose)
    }
}
```

## Surface Styling Patterns

### Solid Color

```swift
SurfacePlot(x: "X", y: "Y", z: "Z", function: { x, z in x * z })
    .foregroundStyle(.blue)
```

### Linear Gradient

```swift
SurfacePlot(x: "X", y: "Y", z: "Z", function: { x, z in x * z })
    .foregroundStyle(
        LinearGradient(
            colors: [.blue, .green, .yellow],
            startPoint: .bottom,
            endPoint: .top
        )
    )
```

### Height-Based Surface Style

Color the surface based on height values, mapping a gradient across the y-axis range:

```swift
SurfacePlot(x: "X", y: "Y", z: "Z", function: { x, z in sin(x) * cos(z) })
    .foregroundStyle(
        Chart3DSurfaceStyle.heightBased(
            Gradient(colors: [.blue, .cyan, .green, .yellow, .red]),
            yRange: -1...1
        )
    )
```

### Normal-Based Surface Style

Color based on surface normals, giving a lighting-aware appearance:

```swift
SurfacePlot(x: "X", y: "Y", z: "Z", function: { x, z in sin(x) * cos(z) })
    .foregroundStyle(Chart3DSurfaceStyle.normalBased)
```

### Surface Roughness

Control surface shininess (0 = reflective, 1 = matte):

```swift
SurfacePlot(x: "X", y: "Y", z: "Z", function: { x, z in sin(x) * cos(z) })
    .foregroundStyle(.blue)
    .roughness(0.3)
```

## Interactive Pose Control

### Preset Poses

`Chart3DPose` provides built-in presets for common viewing angles:

```swift
.chart3DPose(.default)   // Standard 3/4 angle
.chart3DPose(.front)     // Viewing from front
.chart3DPose(.back)      // Viewing from back
.chart3DPose(.top)       // Top-down view
.chart3DPose(.bottom)    // Bottom-up view
.chart3DPose(.right)     // Right side view
.chart3DPose(.left)      // Left side view
```

### Custom Pose

Specify exact azimuth (horizontal rotation) and inclination (vertical tilt):

```swift
.chart3DPose(
    Chart3DPose(azimuth: .degrees(45), inclination: .degrees(30))
)
```

### Anti-Patterns

```swift
// ❌ Passing a literal where a binding is needed for interactivity
.chart3DPose(.default) // This is read-only; drag gestures will not work

// ✅ Use a @State binding for interactive rotation
@State private var pose = Chart3DPose.default
// ...
.chart3DPose($pose)
```

## Camera Projection

Control how 3D depth is rendered:

```swift
Chart3D {
    SurfacePlot(x: "X", y: "Y", z: "Z", function: { x, z in sin(x) * cos(z) })
        .foregroundStyle(.blue)
}
.chart3DCameraProjection(.perspective)   // Objects farther away appear smaller
// .chart3DCameraProjection(.orthographic)  // No perspective distortion
// .chart3DCameraProjection(.automatic)     // System decides
```

## Multiple Surfaces

Render multiple surfaces in a single chart for comparison:

```swift
import SwiftUI
import Charts

struct ComparisonChartView: View {
    @State private var pose = Chart3DPose.default

    var body: some View {
        Chart3D {
            SurfacePlot(
                x: "X",
                y: "Wave A",
                z: "Z",
                function: { x, z in sin(x) * cos(z) }
            )
            .foregroundStyle(.blue.opacity(0.8))

            SurfacePlot(
                x: "X",
                y: "Wave B",
                z: "Z",
                function: { x, z in cos(x) * sin(z) }
            )
            .foregroundStyle(.red.opacity(0.8))
        }
        .chart3DPose($pose)
        .chart3DCameraProjection(.perspective)
    }
}
```

## Complete Example

A full-featured 3D chart with height-based coloring, interactive rotation, and perspective projection:

```swift
import SwiftUI
import Charts

struct TerrainView: View {
    @State private var pose = Chart3DPose(
        azimuth: .degrees(30),
        inclination: .degrees(25)
    )

    var body: some View {
        VStack {
            Text("Terrain Visualization")
                .font(.headline)

            Chart3D {
                SurfacePlot(
                    x: "Longitude",
                    y: "Elevation",
                    z: "Latitude",
                    function: { x, z in
                        let distance = sqrt(x * x + z * z)
                        return sin(distance) / max(distance, 0.1)
                    }
                )
                .foregroundStyle(
                    Chart3DSurfaceStyle.heightBased(
                        Gradient(colors: [
                            .blue, .cyan, .green, .yellow, .orange, .red
                        ]),
                        yRange: -0.5...1.0
                    )
                )
                .roughness(0.4)
            }
            .chart3DPose($pose)
            .chart3DCameraProjection(.perspective)
        }
        .padding()
    }
}
```

## Chart Design Fundamentals (WWDC22)

These apply to every chart you build — 2D or 3D. The pillars: **focused, approachable, accessible**.

- **Pick marks by goal**: bars for patterns, ranges, and individual values; points for spotting outliers; lines for rates of change.
- **Test with real, noisy data early** — placeholder sine waves hide layout failures. Design the edge cases explicitly (e.g., gaps in a line chart where data is missing).
- **~4 horizontal gridlines** is a good baseline; pick intuitive intervals — multiples of 20 for counts, multiples of 7 for day-based axes.
- **Descriptive takeaway title** ("Total Sales: 1,234 Pancakes"), not a generic label ("Sales") — and give the chart surrounding context.
- **Touch targets stretch to full chart height** — a tap anywhere in a bar's column selects it, not just the drawn pixels.
- Support **touch, keyboard, Voice Control, Switch Control, and VoiceOver equally** — every interaction needs a non-pointer path.
- **Color enhances, never solely conveys** — differentiate series with symbols/shapes first, color second. Verify contrast in Dark, Light, and Increase Contrast, and balance saturation so no series visually outweighs the others.
- **Every visual encoding needs a non-visual representation** — per-mark VoiceOver labels and an Audio Graph descriptor; Swift Charts provides both by default, so don't break them with custom drawing. Custom-drawn charts implement them by hand — see "Audio Graphs: AXChartDescriptor" below.

## Swift Charts Construction Reference (2D)

The design fundamentals above apply to every chart; this is the API layer for standard 2D charts (iOS 16+ unless noted; selection, SectorMark, and scrolling are iOS 17+).

### Marks Compose

A `Chart` is a composition of marks — `BarMark`, `LineMark`, `PointMark`, `AreaMark`, `RuleMark`, `RectangleMark`. The `.value("Label", v)` factory arguments do double duty: they bind data AND drive the automatic axes and legend, so label them meaningfully:

```swift
Chart(salesData) { sale in          // Identifiable data — no explicit ForEach needed
    BarMark(
        x: .value("Day", sale.day, unit: .day),   // unit: .day buckets temporal values per day
        y: .value("Sales", sale.count)
    )
}
```

- Transpose a chart by swapping the x/y value pairs — horizontal bars need no other change.
- `unit:` (`.day`, `.month`, `.hour`) controls temporal bucketing; omit it and every timestamp is its own position.

### Series: Style + Symbol, Never Color Alone

`.foregroundStyle(by:)` splits marks into series; pair it with `.symbol(by:)` so series stay distinguishable without color (WWDC22):

```swift
Chart(data) { point in
    LineMark(x: .value("Day", point.day), y: .value("Sales", point.sales))
        .foregroundStyle(by: .value("City", point.city))
        .symbol(by: .value("City", point.city))
}
```

- Remap series colors with `.chartForegroundStyleScale(["Cupertino": .indigo, "San Francisco": .teal])`.
- `.position(by: .value("City", point.city))` converts stacked bars into grouped bars.

### Pin Scales for Stability

Pin scales so a filtered dataset doesn't make the whole chart jump:

```swift
.chartYScale(domain: 0...maxExpectedSales)
.chartXScale(domain: startDate...endDate)
```

### Composing Statistics into a Chart

Marks compose freely, so summary statistics are just more marks:

```swift
Chart {
    ForEach(data) { point in
        AreaMark(                                    // min–max band
            x: .value("Day", point.day),
            yStart: .value("Min", point.min),
            yEnd: .value("Max", point.max)
        )
        .opacity(0.3)

        LineMark(x: .value("Day", point.day), y: .value("Average", point.average))
    }

    RuleMark(y: .value("Overall", overallAverage))   // overall average line
        .foregroundStyle(.secondary)
        .annotation(position: .top, alignment: .leading) {
            Text("Avg: \(overallAverage, format: .number.precision(.fractionLength(0)))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
}
```

### Axes Are Builders

```swift
.chartXAxis {
    AxisMarks(values: .stride(by: .month)) { value in
        AxisGridLine()
        AxisTick()
        AxisValueLabel(format: .dateTime.month(.narrow))
    }
}
.chartYAxis {
    AxisMarks(position: .leading)   // move the value axis to the leading edge
}
```

- Conditional styling belongs *inside* the builder — check `value.as(Date.self)` in the closure to, say, bold only the first month of each quarter.
- `.chartXAxis(.hidden)` removes an axis entirely; `.chartPlotStyle { $0.frame(height: 200).background(.gray.opacity(0.05)).border(.quaternary) }` sizes and styles the plot area itself.

### Interactivity: Selection First

Prefer the built-in selection binding over hand-rolled overlay gestures (iOS 17):

```swift
@State private var selectedDay: Date?

Chart(data) { ... }
    .chartXSelection(value: $selectedDay)
```

Render the selection as marks — a `RuleMark` with `zIndex(-1)` so it draws behind the data, and an annotation that stays inside the plot:

```swift
if let selectedDay {
    RuleMark(x: .value("Selected", selectedDay, unit: .day))
        .foregroundStyle(.gray.opacity(0.3))
        .zIndex(-1)
        .annotation(
            position: .top, spacing: 0,
            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
        ) {
            SelectionDetailCard(day: selectedDay)
        }
}
```

For fully custom hit-testing, drop to `ChartProxy` inside `.chartOverlay` with a `GeometryReader`: `proxy.value(atX:)` converts gesture locations to data values, `proxy.position(forX:)` converts back.

### SectorMark: Pies and Donuts (iOS 17+)

```swift
Chart(data) { item in
    SectorMark(
        angle: .value("Sales", item.sales),
        innerRadius: .ratio(0.62),     // donut hole
        angularInset: 1.5              // 1.5 per side = 3pt gaps between sectors
    )
    .cornerRadius(4)
    .foregroundStyle(by: .value("Name", item.name))
}
.chartBackground { proxy in
    GeometryReader { geo in            // headline metric in the donut hole
        if let anchor = proxy.plotFrame {
            let frame = geo[anchor]
            Text("Best: \(topSellerName)")
                .position(x: frame.midX, y: frame.midY)
        }
    }
}
```

### Large Datasets: Scroll a Window

Don't cram a year into one screen — show a window and scroll (WWDC23):

```swift
Chart(yearOfData) { ... }
    .chartScrollableAxes(.horizontal)
    .chartXVisibleDomain(length: 3600 * 24 * 30)   // 30-day window
    .chartScrollPosition(x: $scrollDate)           // read/write the scroll offset
    .chartScrollTargetBehavior(
        .valueAligned(
            matching: DateComponents(hour: 0),                    // land on day boundaries
            majorAlignment: .matching(DateComponents(day: 1))     // snap paging to month starts
        )
    )
```

### Accessibility Per Mark

Auto-generated VoiceOver descriptions read raw values; per-mark labels beat them:

```swift
BarMark(x: .value("Day", sale.day, unit: .day), y: .value("Sales", sale.count))
    .accessibilityLabel(sale.day.formatted(date: .abbreviated, time: .omitted))
    .accessibilityValue("\(sale.count) pancakes sold")
```

With hundreds or thousands of points, bucket into reasonable intervals and expose one
accessibility element per interval rather than per point (WWDC21 10122).

### Audio Graphs: AXChartDescriptor (WWDC21 10122)

Audio Graphs let VoiceOver play a data series as a continuous tone — pitch = Y value,
time = X position — with an explorer view (rotor → "Audio Graph" → Chart Details) that
plays the sonification, scrubs it (double-tap-and-hold; pausing speaks the value at the
current position), and shows automatically computed summary statistics. Swift Charts
generates a default descriptor; custom-drawn charts conform to `AXChart` (UIKit) or use
the `.accessibilityChartDescriptor(_:)` modifier with an `AXChartDescriptorRepresentable`
(SwiftUI, iOS 15+):

```swift
var accessibilityChartDescriptor: AXChartDescriptor? {
    let xAxis = AXNumericDataAxisDescriptor(
        title: "Cups of coffee",
        range: 0...10,
        gridlinePositions: [],                              // gridlines render as haptics during playback
        valueDescriptionProvider: { "\(Int($0)) cups" })    // "5 cups", never a bare "5"

    let yAxis = AXNumericDataAxisDescriptor(
        title: "Lines of code",
        range: 0...100,
        gridlinePositions: [],
        valueDescriptionProvider: { "\(Int($0)) lines of code" })

    let series = AXDataSeriesDescriptor(
        name: "Productivity",
        isContinuous: true,      // line → one continuous tone; false for bars/points → discrete tones
        dataPoints: model.points.map { AXDataPoint(x: $0.x, y: $0.y) })

    return AXChartDescriptor(
        title: model.title,
        summary: model.summary,  // 1–2 sentence alt text; spoken in the explorer view
        xAxis: xAxis,
        yAxis: yAxis,
        additionalAxes: [],
        series: [series])
}
```

- Categorical axes use `AXCategoricalDataAxisDescriptor`; localize and pluralize the
  `valueDescriptionProvider` output in production.
- Visual floor for any chart (WWDC21 10122): foreground/background contrast **≥ 4.5:1**
  (verify with Accessibility Inspector's Color Contrast Calculator); **never pair
  red + green** (the most common color blindness) and avoid **blue + yellow** (the second
  most common); use **symbols in addition to color** so series stay distinguishable with
  no color perception at all.

## Top Mistakes

| # | Mistake | Fix |
|---|---------|-----|
| 1 | Forgetting to `import Charts` | Both `SwiftUI` and `Charts` imports are required |
| 2 | Using `.chart3DPose(.default)` and expecting drag-to-rotate | Use a `@State` binding: `.chart3DPose($pose)` for interactive rotation |
| 3 | Setting `yRange` that does not cover actual function output | Match the `yRange` in `.heightBased()` to the actual min/max of your function output |
| 4 | Applying `.roughness()` without `.foregroundStyle()` | Roughness modifies existing surface appearance; set a foreground style first |
| 5 | Using orthographic projection for presentation/demo contexts | Prefer `.perspective` for visual appeal; use `.orthographic` for precise data reading |

## Review Checklist

### Imports and Setup
- [ ] Both `import SwiftUI` and `import Charts` are present
- [ ] Deployment target is iOS 26 / macOS 26 or later
- [ ] `Chart3D` wraps all `SurfacePlot` content

### Surface Configuration
- [ ] Axis labels (`x:`, `y:`, `z:`) are descriptive and meaningful
- [ ] `foregroundStyle` applied to each `SurfacePlot` for clear visual distinction
- [ ] `yRange` in `.heightBased()` matches the actual output range of the function
- [ ] `roughness` value makes sense for the use case (0 = reflective, 1 = matte)

### Interactivity
- [ ] Pose is a `@State` binding if drag-to-rotate is intended
- [ ] Pose is a constant (non-binding) if rotation should be locked
- [ ] Initial pose angle provides a good default view of the data

### Camera
- [ ] Camera projection set appropriately (`.perspective` for visual, `.orthographic` for precision)
- [ ] If using `.automatic`, verified the system choice looks acceptable

### Multiple Surfaces
- [ ] Each surface has a distinct color or opacity to differentiate
- [ ] Axis labels are unique per surface or shared where appropriate

### Accessibility
- [ ] Contrast ≥ 4.5:1; no red+green or blue+yellow series pairs; symbols supplement color (WWDC21 10122)
- [ ] Custom-drawn charts expose an `AXChartDescriptor` (Audio Graphs) — or keep Swift Charts' default intact
- [ ] Large datasets expose one accessibility element per interval, not per point

## References

- [Swift Charts](https://developer.apple.com/documentation/charts)
- [Swift Charts — Chart3D](https://developer.apple.com/documentation/Charts/Chart3D)
- [Swift Charts — SurfacePlot](https://developer.apple.com/documentation/Charts/SurfacePlot)
- [Swift Charts — Chart3DPose](https://developer.apple.com/documentation/Charts/Chart3DPose)
- [Swift Charts — Chart3DCameraProjection](https://developer.apple.com/documentation/Charts/Chart3DCameraProjection)
- [Swift Charts — Chart3DSurfaceStyle](https://developer.apple.com/documentation/Charts/Chart3DSurfaceStyle)
