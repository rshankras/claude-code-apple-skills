---
name: visionos-widgets
description: visionOS widget patterns including mounting styles, glass/paper textures, proximity-aware layouts, and spatial widget families. Use when creating or adapting widgets for visionOS.
allowed-tools: [Read, Glob, Grep]
---

# visionOS Widgets

Patterns for building widgets that live in physical space on visionOS. Covers mounting styles, textures, proximity-aware detail levels, spatial widget families, and rendering modes.

## When This Skill Activates

Use this skill when the user:
- Asks to create or adapt a **widget for visionOS**
- Mentions **mounting styles** (elevated, recessed)
- Wants **glass or paper texture** on a widget
- Asks about **proximity awareness** or **level of detail** in widgets
- Mentions **spatial widget families** or `.systemExtraLargePortrait`
- Wants to control **container backgrounds** or **rendering modes** (full color vs accented)
- Is porting an existing iOS/iPadOS widget to visionOS

## Decision Tree

```
What do you need for your visionOS widget?
|
+- Where should the widget appear?
|  +- On a surface (table, shelf) -> .elevated (default)
|  +- Embedded in a wall -> .recessed
|  +- Both -> .supportedMountingStyles([.elevated, .recessed])
|
+- What visual treatment?
|  +- Transparent, blends with environment -> .glass (default)
|  +- Opaque, poster-like appearance -> .paper
|
+- How should it respond to user distance?
|  +- Full detail when close -> @Environment(\.levelOfDetail) == .default
|  +- Simplified when far -> @Environment(\.levelOfDetail) == .simplified
|
+- What size families?
|  +- Standard -> .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge
|  +- Tall portrait -> .systemExtraLargePortrait (visionOS only)
|
+- How should colors render?
|  +- Full color (default) -> No extra work
|  +- System-tinted monochrome -> Mark backgrounds with .containerBackground(for:)
```

## API Availability

| API | Minimum Version | Notes |
|-----|----------------|-------|
| WidgetKit on visionOS | visionOS 1.0 | Basic widget support |
| `.containerBackground(for: .widget)` | visionOS 1.0 | Removable background marking |
| `@Environment(\.showsWidgetContainerBackground)` | visionOS 1.0 | Background visibility check |
| `.supportedMountingStyles()` | visionOS 2.0 | Elevated and recessed placement |
| `.widgetTexture(.glass / .paper)` | visionOS 2.0 | Widget surface material |
| `@Environment(\.levelOfDetail)` | visionOS 2.0 | Proximity-aware layouts |
| `.systemExtraLargePortrait` | visionOS 2.0 | Tall portrait widget family |

## Complete Widget Example

This example demonstrates mounting styles, textures, families, and proximity awareness together:

```swift
struct MyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.example.mywidget",
            provider: Provider()
        ) { entry in
            MyWidgetView(entry: entry)
        }
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .systemExtraLarge, .systemExtraLargePortrait
        ])
        .supportedMountingStyles([.elevated, .recessed])
        .widgetTexture(.glass)        // .glass is default, .paper for opaque
    }
}
```

**Mounting styles**: `.elevated` (default) sits on surfaces like tables. `.recessed` embeds into walls like a framed picture. Omit `.supportedMountingStyles()` to use elevated only.

**Textures**: `.glass` (default) is transparent and blends with the environment. `.paper` is opaque and poster-like, best for rich imagery.

## Proximity Awareness (Level of Detail)

The system tracks user distance and transitions between detail levels automatically with animation.

```swift
struct MyWidgetView: View {
    let entry: Provider.Entry
    @Environment(\.levelOfDetail) private var levelOfDetail

    var body: some View {
        switch levelOfDetail {
        case .default:
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.title).font(.headline)
                Text(entry.subtitle).font(.subheadline).foregroundStyle(.secondary)
                DetailChart(data: entry.chartData)
            }
            .padding()
        case .simplified:
            VStack(spacing: 4) {
                Image(systemName: entry.iconName).font(.largeTitle)
                Text(entry.title).font(.headline)
            }
            .padding()
        @unknown default:
            Text(entry.title).padding()
        }
    }
}
```

Always handle `@unknown default` for forward compatibility.

## Widget Families

| Family | Description |
|--------|-------------|
| `.systemSmall` | Compact square -- glanceable info |
| `.systemMedium` | Wide rectangle -- two-column or list preview |
| `.systemLarge` | Large square -- charts, detailed content |
| `.systemExtraLarge` | Extra-large landscape -- dashboards |
| `.systemExtraLargePortrait` | Extra-large portrait -- visionOS only |

Guard the visionOS-only family in multiplatform targets:

```swift
.supportedFamilies({
    var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
    #if os(visionOS)
    families.append(.systemExtraLargePortrait)
    #endif
    return families
}())
```

## Container Backgrounds and Rendering Modes

In accented rendering mode, the system removes backgrounds and applies a tint color. Mark removable backgrounds so the widget renders correctly in both modes.

```swift
struct MyWidgetView: View {
    let entry: Provider.Entry
    @Environment(\.showsWidgetContainerBackground) var showsBackground

    var body: some View {
        VStack {
            Image(systemName: "star.fill").font(.largeTitle)
            Text(entry.title)
                .font(.headline)
                .foregroundStyle(showsBackground ? .white : .primary)
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
```

- **Full color** (default): All colors render intact.
- **Accented**: Container background is removed; system applies a monochrome tint.

## Previewing visionOS Widgets

```swift
#Preview("Close Up", as: .systemSmall) {
    MyWidget()
} timelineProvider: {
    Provider()
}

#Preview("Extra Large Portrait", as: .systemExtraLargePortrait) {
    MyWidget()
} timelineProvider: {
    Provider()
}
```

## Top 5 Mistakes

| # | Mistake | Fix |
|---|---------|-----|
| 1 | Missing `.containerBackground(for: .widget)` -- accented mode renders blank | Always wrap backgrounds in `.containerBackground(for: .widget) { }` |
| 2 | Ignoring `levelOfDetail` -- detailed views unreadable from across the room | Provide a `.simplified` layout with larger text, fewer elements |
| 3 | Using `.systemExtraLargePortrait` on iOS -- build error or runtime crash | Guard with `#if os(visionOS)` or visionOS-only targets |
| 4 | Hardcoding colors that clash with glass texture | Use `.foregroundStyle(.primary / .secondary)` and system colors |
| 5 | No `@unknown default` in `levelOfDetail` switch | Always include for forward compatibility |

### Anti-Patterns

```swift
// ❌ No container background — accented mode shows nothing
struct BadWidgetView: View {
    var body: some View {
        ZStack {
            Color.blue  // Not marked as removable
            Text("Hello")
        }
    }
}

// ✅ Background marked as removable
struct GoodWidgetView: View {
    var body: some View {
        Text("Hello")
            .containerBackground(for: .widget) { Color.blue }
    }
}
```

```swift
// ❌ Same complex layout at all distances
struct BadProximityView: View {
    var body: some View {
        VStack {
            Text(entry.title).font(.caption2)  // Unreadable far away
            DetailChart(data: entry.data)
        }
    }
}

// ✅ Simplified layout when far away
struct GoodProximityView: View {
    @Environment(\.levelOfDetail) private var levelOfDetail
    var body: some View {
        switch levelOfDetail {
        case .default: DetailedLayout(entry: entry)
        case .simplified: SimplifiedLayout(entry: entry)
        @unknown default: SimplifiedLayout(entry: entry)
        }
    }
}
```

## Review Checklist

### Mounting and Texture
- [ ] Mounting style explicitly set if widget should appear recessed or support both
- [ ] Texture set to `.paper` for widgets with rich imagery
- [ ] Widget tested in both elevated and recessed placements (if both supported)

### Proximity Awareness
- [ ] `@Environment(\.levelOfDetail)` provides simplified layout for distant viewers
- [ ] `.simplified` layout uses larger text, fewer elements, high-contrast visuals
- [ ] `@unknown default` case present in `levelOfDetail` switch

### Families and Layout
- [ ] `.systemExtraLargePortrait` guarded with `#if os(visionOS)` in multiplatform targets
- [ ] Widget content adapts to each supported family size
- [ ] Layout tested in all declared family sizes via Xcode previews

### Backgrounds and Rendering
- [ ] `.containerBackground(for: .widget) { }` used to mark removable backgrounds
- [ ] Widget renders correctly in both full color and accented modes
- [ ] `showsWidgetContainerBackground` checked if foreground colors depend on background
- [ ] System semantic colors used for glass texture compatibility

## References

- [Widgets for visionOS (WWDC)](https://developer.apple.com/documentation/widgetkit/widgets-for-visionos)
- [WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [visionOS Human Interface Guidelines - Widgets](https://developer.apple.com/design/human-interface-guidelines/widgets)
