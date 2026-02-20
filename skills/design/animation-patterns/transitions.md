# Transitions

View insertion/removal transitions, matched geometry effects, navigation transitions, and content transitions.

## View Transitions

Transitions define how a view appears and disappears when added to or removed from the view hierarchy via conditional rendering (`if`, `switch`, `ForEach`).

### Built-in Transitions

```swift
.transition(.opacity)                   // Fade in/out (iOS 13+)
.transition(.slide)                     // Slide from leading edge (iOS 13+)
.transition(.scale)                     // Scale from center (iOS 13+)
.transition(.scale(scale: 0.5))         // Scale from 50%
.transition(.scale(scale: 0, anchor: .bottom))  // Scale from bottom
.transition(.move(edge: .bottom))       // Slide from specific edge (iOS 13+)
.transition(.move(edge: .trailing))
.transition(.offset(x: 0, y: 50))      // Move from offset position (iOS 13+)
.transition(.push(from: .bottom))       // Push from edge with depth (iOS 16+)
.transition(.blurReplace)               // Blur out old, blur in new (iOS 17+)
.transition(.blurReplace(.downUp))      // Directional blur replace
.transition(.blurReplace(.upUp))
```

### Combined Transitions

```swift
// Both effects applied simultaneously
.transition(.opacity.combined(with: .scale))
.transition(.move(edge: .bottom).combined(with: .opacity))
```

### Asymmetric Transitions

Different animation for insertion vs removal:

```swift
.transition(.asymmetric(
    insertion: .push(from: .bottom),
    removal: .opacity
))

.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .move(edge: .trailing).combined(with: .opacity)
))
```

### Usage with Conditional Views

Transitions only work on views that are conditionally rendered:

```swift
VStack {
    if showDetail {
        DetailView()
            .transition(.slide)  // ✅ Works — view is added/removed
    }
}

VStack {
    DetailView()
        .opacity(showDetail ? 1 : 0)  // This is NOT a transition — it's an animation
        .transition(.slide)             // ❌ No effect — view is always present
}
```

Animate the state change to see the transition:

```swift
Button("Toggle") {
    withAnimation(.spring) {
        showDetail.toggle()
    }
}
```

### Custom Transitions

Build custom transitions using `ViewModifier`:

```swift
struct SlideAndFade: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: isActive ? 30 : 0)
            .opacity(isActive ? 0 : 1)
            .scaleEffect(isActive ? 0.9 : 1)
    }
}

extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .modifier(
            active: SlideAndFade(isActive: true),
            identity: SlideAndFade(isActive: false)
        )
    }
}

// Usage
DetailView()
    .transition(.slideAndFade)
```

## matchedGeometryEffect (iOS 14+)

Creates a visual connection between two views by matching their geometry (position, size). Used for shared element transitions within the same view hierarchy.

### How It Works

Two views share an `id` and `namespace`. When one disappears and the other appears, SwiftUI animates the geometry change.

```swift
struct ExpandableCard: View {
    @Namespace private var animation
    @State private var isExpanded = false

    var body: some View {
        if isExpanded {
            ExpandedView()
                .matchedGeometryEffect(id: "card", in: animation)
                .onTapGesture {
                    withAnimation(.spring) {
                        isExpanded = false
                    }
                }
        } else {
            CompactView()
                .matchedGeometryEffect(id: "card", in: animation)
                .onTapGesture {
                    withAnimation(.spring) {
                        isExpanded = true
                    }
                }
        }
    }
}
```

### Rules

1. **@Namespace** — must declare a namespace with `@Namespace private var animation`
2. **Same id, same namespace** — both views use the same `id` and `in:` namespace
3. **Only one view at a time** — at any given moment, only one view with a given id should be in the hierarchy (use `if/else`, not showing both)
4. **isSource parameter** — when both views exist simultaneously (e.g., overlay), set `isSource: true` on the source and `isSource: false` on the target

```swift
// When both views coexist — source dictates geometry
SmallPhoto()
    .matchedGeometryEffect(id: "photo", in: ns, isSource: true)

LargePhoto()
    .matchedGeometryEffect(id: "photo", in: ns, isSource: false)
```

### Anti-Patterns

```swift
// ❌ WRONG: Both set isSource: true
view1.matchedGeometryEffect(id: "x", in: ns, isSource: true)
view2.matchedGeometryEffect(id: "x", in: ns, isSource: true)
// ✅ Only ONE should be isSource: true

// ❌ WRONG: Forgetting @Namespace
let animation = Namespace()  // This is wrong
// ✅ @Namespace private var animation

// ❌ WRONG: Using for NavigationStack push/pop transitions
NavigationLink { DetailView().matchedGeometryEffect(id: "item", in: ns) }
// matchedGeometryEffect does NOT work across NavigationStack push/pop
// ✅ Use matchedTransitionSource (iOS 18+) instead — see below
```

## Navigation Transitions (iOS 18+)

### matchedTransitionSource + navigationTransition(.zoom)

The correct way to create hero/zoom transitions with NavigationStack. **Do not use matchedGeometryEffect for this.**

```swift
struct GalleryView: View {
    @Namespace private var namespace
    let photos: [Photo]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(photos) { photo in
                        NavigationLink(value: photo) {
                            PhotoThumbnail(photo: photo)
                                .matchedTransitionSource(id: photo.id, in: namespace)
                        }
                    }
                }
            }
            .navigationDestination(for: Photo.self) { photo in
                PhotoDetailView(photo: photo)
                    .navigationTransition(.zoom(sourceID: photo.id, in: namespace))
            }
        }
    }
}
```

### How It Differs from matchedGeometryEffect

| | matchedGeometryEffect | matchedTransitionSource |
|---|---|---|
| **Purpose** | Shared element within same hierarchy | Navigation push/pop transitions |
| **Works with NavigationStack** | No | Yes |
| **Availability** | iOS 14+ | iOS 18+ |
| **Both views exist** | Must coordinate with `isSource` | Source and destination are separate screens |
| **Configuration** | On both views | Source: `.matchedTransitionSource`, Destination: `.navigationTransition(.zoom)` |

### Other Navigation Transitions

```swift
// Slide transition (default NavigationStack behavior)
.navigationTransition(.slide)

// Zoom from a source
.navigationTransition(.zoom(sourceID: id, in: namespace))

// Automatic — system chooses based on context
.navigationTransition(.automatic)
```

### Customizing Zoom Appearance

```swift
PhotoThumbnail(photo: photo)
    .matchedTransitionSource(id: photo.id, in: namespace) { source in
        source
            .clipShape(.rect(cornerRadius: 12))
            .shadow(radius: 5)
    }

PhotoDetailView(photo: photo)
    .navigationTransition(.zoom(sourceID: photo.id, in: namespace))
```

## Content Transitions

Animate the content inside a view without adding/removing the view itself.

### Numeric Text (iOS 16+)

Animates number changes digit-by-digit:

```swift
Text(score, format: .number)
    .contentTransition(.numericText())
    .animation(.snappy, value: score)
```

With counting direction:

```swift
Text(value, format: .number)
    .contentTransition(.numericText(countsDown: value < previousValue))
```

### Interpolate (iOS 16+)

Smoothly interpolates between text styles (color, size):

```swift
Text("Status")
    .foregroundStyle(isActive ? .green : .red)
    .fontWeight(isActive ? .bold : .regular)
    .contentTransition(.interpolate)
    .animation(.smooth, value: isActive)
```

### Symbol Effect Replace (iOS 17+)

Animate SF Symbol changes:

```swift
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
    .contentTransition(.symbolEffect(.replace))
    .animation(.smooth, value: isPlaying)
```

With direction:

```swift
.contentTransition(.symbolEffect(.replace.downUp))
.contentTransition(.symbolEffect(.replace.upUp))
.contentTransition(.symbolEffect(.replace.offUp))
```

### Identity (No Transition)

Opt out of content transitions:

```swift
.contentTransition(.identity)
```

## Accessibility — Reduce Motion

Always provide alternatives for users with reduced motion enabled.

### Check Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    if showDetail {
        DetailView()
            .transition(reduceMotion ? .opacity : .slide.combined(with: .opacity))
    }
}
```

### Conditional Animation

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

func toggleDetail() {
    if reduceMotion {
        showDetail.toggle()  // No animation
    } else {
        withAnimation(.spring) {
            showDetail.toggle()
        }
    }
}
```

### Simplified Transitions

Replace complex multi-step transitions with simple fades:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var transition: AnyTransition {
    if reduceMotion {
        .opacity
    } else {
        .asymmetric(
            insertion: .push(from: .bottom).combined(with: .opacity),
            removal: .push(from: .top).combined(with: .opacity)
        )
    }
}
```
