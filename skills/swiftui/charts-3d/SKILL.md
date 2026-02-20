---
name: charts-3d
description: 3D chart visualization with Swift Charts using Chart3D, SurfacePlot, interactive pose control, and surface styling. Use when creating 3D data visualizations.
allowed-tools: [Read, Glob, Grep]
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

Control how shiny or matte the surface appears. A value of 0 is perfectly smooth (reflective), and 1 is fully rough (matte):

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

### Read-Only vs Interactive

```swift
// ✅ Read-only — user cannot rotate the chart
.chart3DPose(Chart3DPose.front)

// ✅ Interactive — user can drag to rotate, pose updates automatically
@State private var pose = Chart3DPose.default
// ...
.chart3DPose($pose)
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

- **Perspective**: Gives natural depth perception. Objects farther from the camera appear smaller. Good for presentations and visual appeal.
- **Orthographic**: No size distortion with distance. Good for precise data reading and scientific visualization.
- **Automatic**: System selects based on context.

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

## References

- [Swift Charts — Chart3D](https://developer.apple.com/documentation/Charts/Chart3D)
- [Swift Charts — SurfacePlot](https://developer.apple.com/documentation/Charts/SurfacePlot)
- [Swift Charts — Chart3DPose](https://developer.apple.com/documentation/Charts/Chart3DPose)
- [Swift Charts — Chart3DCameraProjection](https://developer.apple.com/documentation/Charts/Chart3DCameraProjection)
- [Swift Charts — Chart3DSurfaceStyle](https://developer.apple.com/documentation/Charts/Chart3DSurfaceStyle)
