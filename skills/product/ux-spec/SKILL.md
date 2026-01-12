---
name: ux-spec
description: Generates UI/UX specifications with wireframes and design system. Creates UX_SPEC.md and DESIGN_SYSTEM.md from PRD and Architecture specs. Use when designing app interface and creating design system.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion]
---

# UX Specification Skill

Generate comprehensive UI/UX specifications with wireframes and design system for iOS/macOS apps.

## Metadata
- **Name**: ux-spec
- **Version**: 1.0.0
- **Role**: UI/UX Designer
- **Author**: ProductAgent Team

## Activation

This skill activates when the user says:
- "generate UI spec"
- "create UX specification"
- "design wireframes"
- "create design system"
- "generate UX spec from PRD"

## Description

You are a UI/UX Designer AI agent specializing in iOS/macOS app design. Your job is to transform product requirements and architecture into comprehensive, actionable UI/UX specifications that developers can implement directly.

## Prerequisites

Before activating this skill, ensure:
1. PRD exists (from prd-generator skill)
2. ARCHITECTURE.md exists (from architecture-spec skill)
3. Product development plan with positioning and brand personality

## Input Sources

Read and extract information from:
1. **docs/PRD.md**
   - All features and requirements
   - User flows and user stories
   - Target audience
   - Acceptance criteria

2. **docs/ARCHITECTURE.md**
   - App structure and navigation
   - Data models (to understand what to display)
   - Platform (iOS/macOS)

3. **Product development plan** (product-plan-*.md)
   - Positioning and brand personality
   - Value proposition
   - Target market

4. **User clarifications** (ask if needed):
   - Preferred design style (minimalist, colorful, professional, playful)
   - Any brand colors or existing branding
   - Key screens to prioritize

## Output

Generate two comprehensive documents:

### 1. docs/UX_SPEC.md

```markdown
# UI/UX Specification: [App Name]

**Version**: 1.0.0
**Last Updated**: [Date]
**Status**: Draft / In Review / Approved
**Designer**: UX Designer AI
**Platform**: iOS / macOS

---

## 1. Design Principles

### 1.1 Core Principles
1. **[Principle 1]**: [e.g., "Simplicity over features - Every screen should have one primary action"]
2. **[Principle 2]**: [e.g., "Glanceable information - Users should understand content in < 5 seconds"]
3. **[Principle 3]**: [e.g., "Gesture-first interaction - Leverage native iOS gestures"]
4. **[Principle 4]**: [e.g., "Progressive disclosure - Show advanced features only when needed"]

### 1.2 Brand Personality
**From Positioning**: [e.g., "Professional, trustworthy, modern with a human touch"]

**Design Expression**:
- Visual style: [Clean, minimal, lots of whitespace]
- Tone: [Friendly but professional]
- Imagery: [Photography-based vs. illustration-based]

---

## 2. Information Architecture

### 2.1 App Structure

**Navigation Pattern**: [TabView / NavigationStack / Sidebar (iPad)]

**Screen Hierarchy**:
```
App Root
├── Tab 1: [Home]
│   ├── [Home Screen]
│   ├── [Item Detail Screen]
│   └── [Edit Item Screen]
├── Tab 2: [Discover]
│   ├── [Discover Screen]
│   └── [Category Detail Screen]
├── Tab 3: [Profile]
│   ├── [Profile Screen]
│   └── [Settings Screen]
└── Shared
    ├── [Login Screen]
    ├── [Onboarding Flow]
    └── [Error/Empty States]
```

### 2.2 Screen Inventory

| Screen Name | Purpose | Navigation | Priority |
|-------------|---------|------------|----------|
| Onboarding | First-time user education | Modal → Home | P0 |
| Home | Primary content view | Root tab | P0 |
| Item Detail | View single item details | Push from Home | P0 |
| Add/Edit Item | Create or modify item | Modal/Push | P0 |
| Profile | User profile and settings | Root tab | P1 |
| Settings | App preferences | Push from Profile | P1 |

### 2.3 Navigation Flow Diagram

```
[Splash] → [Onboarding] → [Home (Tab 1)]
                              ↓
                         [Item Detail]
                              ↓
                         [Edit Item]

[Profile (Tab 3)] → [Settings]
                  → [Account]
```

---

## 3. Screen Specifications

### 3.1 Onboarding Flow

**Purpose**: Help new users understand value and complete initial setup

**Screens**: 3 screens + Welcome

#### Screen 1: Welcome

**Layout** (ASCII wireframe):
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│          [App Icon/Logo]            │
│                                     │
│                                     │
│         Welcome to [AppName]        │
│                                     │
│      [One-line value proposition]   │
│                                     │
│                                     │
│                                     │
│         [Get Started Button]        │
│                                     │
│      Already have an account?       │
│             [Sign In]               │
│                                     │
└─────────────────────────────────────┘
```

**Components**:
- **App Icon/Logo**: Centered, large (120pt)
- **Welcome Title**: .largeTitle, bold, centered
- **Value Proposition**: .title3, secondary color, centered, max 2 lines
- **Get Started Button**: Primary button style, full width with margin
- **Sign In Link**: Text button, smaller, muted color

**Interactions**:
- Tap "Get Started" → Navigate to Onboarding Screen 1
- Tap "Sign In" → Navigate to Login Screen
- Swipe not enabled (no skip on welcome)

**States**:
- Default: All elements visible
- Loading: Show activity indicator if checking auth state

**Animations**:
- Fade in on appear (0.5s)
- Button press: Scale 0.95 with haptic feedback

---

#### Screen 2: Onboarding Step 1

**Purpose**: Explain primary feature/benefit

**Layout**:
```
┌─────────────────────────────────────┐
│  ○ ● ○                     [Skip]   │  (Progress + Skip)
├─────────────────────────────────────┤
│                                     │
│                                     │
│         [Feature Illustration]      │
│              or Screenshot          │
│                                     │
│                                     │
├─────────────────────────────────────┤
│                                     │
│       [Headline - Feature Name]     │
│                                     │
│     [Description - 2-3 lines        │
│      explaining the benefit]        │
│                                     │
├─────────────────────────────────────┤
│                                     │
│            [Next Button]            │
│                                     │
└─────────────────────────────────────┘
```

**Components**:
- **Progress Indicator**: 3 dots, current = filled circle
- **Skip Button**: Text button, top-right
- **Illustration**: Hero image or screenshot, 300pt height
- **Headline**: .title2, bold, benefit-focused
- **Description**: .body, 2-3 lines, explain value not feature
- **Next Button**: Primary button, full width

**Interactions**:
- Tap "Next" → Navigate to Onboarding Step 2
- Tap "Skip" → Navigate to Home (mark onboarding complete)
- Swipe left → Next screen
- Swipe right → Previous screen

**Content Guidelines**:
- Focus on BENEFITS not features
- Use "you" language ("You can organize all your tasks")
- Keep concise (< 20 words per description)

---

#### Screen 3: Onboarding Step 2 & 3
[Repeat structure for remaining onboarding screens]

---

### 3.2 Home Screen

**Purpose**: Display primary content and enable main user actions

**Layout** (iPhone Portrait):
```
┌─────────────────────────────────────┐
│  ←  Home              [+]  [⚙️]     │  (Navigation Bar)
├─────────────────────────────────────┤
│                                     │
│  Search...                    [🔍]  │  (Search Bar)
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │  [Thumbnail]  Card Title      │ │  (Card Component)
│  │               Subtitle • Meta │ │
│  │               [Status Badge]  │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  [Thumbnail]  Card Title      │ │
│  │               Subtitle • Meta │ │
│  │               [Status Badge]  │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  [Thumbnail]  Card Title      │ │
│  │               Subtitle • Meta │ │
│  │               [Status Badge]  │ │
│  └───────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│  [Tab1]  [Tab2]  [Tab3]  [Tab4]    │  (Tab Bar)
└─────────────────────────────────────┘
```

**Components**:

**Navigation Bar**:
- Title: "Home" (.largeTitle when scrolled to top, .inline when scrolling)
- Leading: Back button (if navigated from elsewhere)
- Trailing:
  - [+] Add button → Navigate to Add Item
  - [⚙️] Settings button → Navigate to Settings

**Search Bar** (Optional, based on requirements):
- Placeholder: "Search [items]..."
- Style: .searchable modifier
- Clear button when text entered
- Dismiss on scroll down

**Card List**:
- Container: SwiftUI List with .plain style
- Card spacing: 12pt between cards
- Card style: See "Card Component" section below

**Tab Bar** (if using tabs):
- 3-5 tabs maximum
- Active tab: Primary color
- Inactive tabs: Secondary/gray color
- Badge: Red dot for notifications (if applicable)

**Interactions**:
- **Tap card** → Navigate to Item Detail Screen
- **Swipe left on card** → Show Delete action (red background, trash icon)
- **Swipe right on card** → Show Archive action (if applicable)
- **Pull down** → Refresh content (show activity indicator)
- **Tap [+]** → Present Add Item sheet
- **Tap [⚙️]** → Navigate to Settings
- **Search** → Filter list in real-time as user types
- **Scroll to top** → Navigation bar title animates to large title

**States**:

**Empty State**:
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│           [Empty Icon]              │
│              (tray)                 │
│                                     │
│          No Items Yet               │
│                                     │
│     Get started by tapping the      │
│           + button above            │
│                                     │
│                                     │
└─────────────────────────────────────┘
```
- Use ContentUnavailableView (iOS 17+)
- Icon: SF Symbol related to content type
- Title: Friendly, not error-focused
- Description: Clear call to action

**Loading State**:
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│       [Loading Spinner]             │
│          Loading...                 │
│                                     │
│                                     │
└─────────────────────────────────────┘
```
- Full-screen overlay with .ultraThinMaterial background
- Activity indicator (.large size)
- Optional "Loading..." text below

**Error State**:
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│      [Error Icon] (exclamationmark) │
│                                     │
│       Couldn't load items           │
│                                     │
│   [Error description message]       │
│                                     │
│         [Try Again Button]          │
│                                     │
└─────────────────────────────────────┘
```
- ContentUnavailableView with error styling
- Clear error message (user-friendly, not technical)
- Retry button to attempt reload

**Skeleton/Shimmer State** (Alternative to loading spinner):
```
┌─────────────────────────────────────┐
│  ┌───────────────────────────────┐ │
│  │  [▓▓▓]  ▓▓▓▓▓▓▓▓▓▓           │ │  (Shimmer effect)
│  │         ▓▓▓▓▓▓▓ • ▓▓▓         │ │
│  └───────────────────────────────┘ │
│  ┌───────────────────────────────┐ │
│  │  [▓▓▓]  ▓▓▓▓▓▓▓▓▓▓           │ │
│  │         ▓▓▓▓▓▓▓ • ▓▓▓         │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```
- Show 3-5 placeholder cards
- Animated shimmer effect (subtle, not distracting)
- Replace with real content when loaded

**Data Requirements**:
- Array of items: [Item]
- Each item needs: id, title, subtitle, thumbnailURL, status, metadata
- Sorting: By date (newest first) or user preference
- Filtering: Based on search query

**Accessibility**:
- VoiceOver label for each card: "[Title], [Subtitle], [Status]"
- Add button: "Add new item"
- Settings button: "Settings"
- Swipe actions announced: "Swipe right or left for actions"
- Search bar: "Search [items]"

---

### 3.3 Item Detail Screen

**Purpose**: Display full details of a single item

**Layout**:
```
┌─────────────────────────────────────┐
│  ← [Item Title]          [Edit]     │  (Navigation Bar)
├─────────────────────────────────────┤
│                                     │
│        [Hero Image/Thumbnail]       │
│              (Full width)           │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [Item Title]                       │
│  [Subtitle or Category]             │
│                                     │
│  [Status Badge]  [Metadata]         │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Description                        │
│  ─────────────                      │
│  [Full description text, can be     │
│   multiple paragraphs. Lorem ipsum  │
│   dolor sit amet...]                │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Details                            │
│  ────────                           │
│  Created: [Date]                    │
│  Modified: [Date]                   │
│  Author: [Name]                     │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Related Items                      │
│  ──────────────                     │
│  ┌─────────┐ ┌─────────┐           │
│  │ [Item1] │ │ [Item2] │           │
│  └─────────┘ └─────────┘           │
│                                     │
├─────────────────────────────────────┤
│                                     │
│         [Primary Action]            │
│         [Secondary Action]          │
│                                     │
└─────────────────────────────────────┘
```

**Components**:
- **Navigation Bar**: Item title (truncate if > 25 chars), Edit button
- **Hero Image**: Full-width, 16:9 aspect ratio, 250pt height
- **Title Section**: .title2 bold, subtitle .subheadline
- **Status Badge**: Rounded rectangle, color-coded by status
- **Description**: .body text, full paragraph formatting
- **Details Section**: Key-value pairs, .callout size, secondary color
- **Related Items**: Horizontal scroll, 100pt width cards
- **Action Buttons**: Primary (full width), Secondary (outlined)

**Interactions**:
- Tap "Edit" → Navigate to Edit Screen
- Tap Hero Image → Open full-screen image viewer (pinch to zoom)
- Tap Related Item → Navigate to that item's detail screen
- Swipe back → Return to Home
- Scroll → Navigation bar collapses to inline title

**States**:
- **Loading**: Show skeleton for all sections while data loads
- **Error**: Show error message inline (not full-screen)
- **No Image**: Show placeholder icon/gradient
- **No Description**: Hide section entirely (don't show empty)
- **No Related Items**: Hide section

---

### 3.4 Add/Edit Item Screen

**Purpose**: Create new item or modify existing

**Layout** (Sheet/Modal):
```
┌─────────────────────────────────────┐
│  [Cancel]  Add Item        [Save]   │  (Modal Header)
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │   + Add Photo                 │ │  (Image Picker)
│  └───────────────────────────────┘ │
│                                     │
│  Title                              │
│  ┌───────────────────────────────┐ │
│  │ [Enter title...]              │ │
│  └───────────────────────────────┘ │
│                                     │
│  Category                           │
│  ┌───────────────────────────────┐ │
│  │ [Select category]       [▼]   │ │
│  └───────────────────────────────┘ │
│                                     │
│  Description                        │
│  ┌───────────────────────────────┐ │
│  │ [Enter description...]        │ │
│  │                               │ │
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
│  Status                             │
│  ○ Active    ○ Pending    ○ Done   │
│                                     │
│                                     │
│         [Delete Item]               │  (Edit only)
│                                     │
└─────────────────────────────────────┘
```

**Components**:
- **Modal Header**: Cancel (leading), Title (center), Save (trailing, blue)
- **Image Picker**: Dashed border, + icon, tap to open photo picker
- **Text Fields**: Native iOS style, floating labels
- **Dropdown**: Chevron indicator, opens picker/sheet
- **Text Area**: Multiline, min 3 lines
- **Radio Group**: Horizontal segmented control or vertical radio buttons
- **Delete Button**: Destructive style, bottom of form (edit mode only)

**Interactions**:
- Tap "Cancel" → Dismiss sheet, confirm if unsaved changes
- Tap "Save" → Validate, save, dismiss, return to previous screen
- Tap Image Picker → Present photo picker (Camera + Photo Library)
- Tap Dropdown → Present selection sheet/picker
- Typing → Show character count if there's a limit
- Tap Delete → Show destructive alert confirmation

**Validation**:
- Required fields: Show red outline + error message on save attempt
- Character limits: Show count (e.g., "120/150 characters")
- Invalid format: Show inline error below field

**States**:
- **Add Mode**: Empty fields, no Delete button
- **Edit Mode**: Pre-filled fields, Delete button visible
- **Saving**: Disable Save button, show spinner
- **Error**: Show alert with error message, keep form open

---

### 3.5 Settings Screen

**Purpose**: App preferences and account management

**Layout**:
```
┌─────────────────────────────────────┐
│  ← Settings                         │
├─────────────────────────────────────┤
│                                     │
│  Account                            │
│  ┌───────────────────────────────┐ │
│  │  [👤]  [User Name]        [>] │ │
│  │        user@email.com          │ │
│  └───────────────────────────────┘ │
│                                     │
│  Preferences                        │
│  ┌───────────────────────────────┐ │
│  │  Notifications          [○●]  │ │  (Toggle)
│  │  Dark Mode              [○●]  │ │
│  │  Language               [>]   │ │
│  └───────────────────────────────┘ │
│                                     │
│  Data & Privacy                     │
│  ┌───────────────────────────────┐ │
│  │  Privacy Policy         [>]   │ │
│  │  Terms of Service       [>]   │ │
│  │  Delete Account         [>]   │ │
│  └───────────────────────────────┘ │
│                                     │
│  About                              │
│  ┌───────────────────────────────┐ │
│  │  App Version      1.0.0       │ │
│  │  Rate Us                [>]   │ │
│  │  Contact Support        [>]   │ │
│  └───────────────────────────────┘ │
│                                     │
│                                     │
│          [Sign Out]                 │
│                                     │
└─────────────────────────────────────┘
```

**Components**:
- **Section Headers**: .caption uppercase, secondary color, 24pt top padding
- **Grouped List**: iOS native .insetGrouped style
- **Row**: 44pt min height, tap area full width
- **Toggle**: iOS native switch, tappable label + switch
- **Disclosure**: Chevron on trailing edge
- **Sign Out Button**: Destructive style, centered, bottom

**Interactions**:
- Tap row with [>] → Navigate to detail screen
- Tap toggle → Immediate change (save to UserDefaults/CloudKit)
- Tap "Sign Out" → Show confirmation alert

---

## 4. Component Library

### 4.1 Buttons

#### Primary Button
**Style**:
- Background: Brand Primary color
- Text: White, .headline font
- Corner radius: 12pt
- Height: 50pt
- Padding: 16pt horizontal
- Shadow: radius 4, y: 2, opacity 0.1

**States**:
- Normal: Full color
- Pressed: Opacity 0.8 + scale 0.98
- Disabled: Opacity 0.5, no interaction
- Loading: Show spinner, disable interaction

**Code Example**:
```swift
.font(.headline)
.foregroundColor(.white)
.frame(maxWidth: .infinity)
.frame(height: 50)
.background(Color.brandPrimary)
.cornerRadius(12)
.shadow(radius: 4, y: 2)
```

#### Secondary Button
**Style**:
- Background: Clear
- Border: 2pt, Brand Primary color
- Text: Brand Primary color, .headline
- Corner radius: 12pt
- Height: 50pt

**States**: Same as Primary Button

#### Text Button
**Style**:
- Background: None
- Text: Brand Primary color, .body or .callout
- No border
- Height: Auto (text height + padding)

**States**:
- Normal: Primary color
- Pressed: Opacity 0.6
- Disabled: Secondary color, no interaction

---

### 4.2 Cards

#### Standard Card
**Style**:
- Background: White (light mode) / .secondarySystemBackground (dark mode)
- Corner radius: 12pt
- Padding: 16pt
- Shadow: radius 8, y: 2, opacity 0.1
- Border: None (use shadow for elevation)

**Layout**:
```
┌───────────────────────────────┐
│  [Thumbnail]  Title           │
│  (60x60pt)    Subtitle        │
│               Metadata        │
└───────────────────────────────┘
```

**Spacing**:
- Thumbnail to text: 12pt
- Title to subtitle: 4pt
- Text to edge: 16pt

#### Highlighted Card
**Differences from Standard**:
- Border: 2pt, Brand Primary color
- Background: Tinted (Primary color at 5% opacity)
- Shadow: Slightly larger (radius 10)

---

### 4.3 Forms

#### Text Input
**Style**:
- Height: 50pt
- Padding: 16pt horizontal
- Background: .secondarySystemBackground
- Corner radius: 10pt
- Border: 1pt, clear (2pt primary color when focused)
- Font: .body

**States**:
- Default: Gray background, no border
- Focused: White background, blue border
- Error: Red border, red tint
- Disabled: Reduced opacity, no interaction

**With Label**:
- Label above input, .caption size, secondary color
- 8pt spacing between label and input

**With Error**:
- Error message below input, .caption size, red color
- Error icon (exclamationmark.circle) leading

---

### 4.4 Typography Styles

**Usage Guide**:
- **Large Title**: Screen titles (Home, Settings)
- **Title**: Section headers
- **Title 2**: Card titles, detail screen main heading
- **Title 3**: Subsection headers
- **Headline**: Button labels, emphasized text
- **Body**: Default text, descriptions
- **Callout**: Metadata, secondary information
- **Subheadline**: Subtitles, labels
- **Footnote**: Timestamps, hints
- **Caption**: Section headers (uppercase), disclaimers

---

## 5. Interaction Patterns

### 5.1 Gestures

| Gesture | Use Case | Feedback |
|---------|----------|----------|
| Tap | Primary action, select, open | Visual (highlight), Haptic (light) |
| Long Press | Context menu, preview | Visual (scale up), Haptic (medium) |
| Swipe Left | Delete, remove | Visual (red background), Haptic (none) |
| Swipe Right | Archive, mark done | Visual (green background), Haptic (success) |
| Pull Down | Refresh content | Visual (activity indicator), Haptic (light when triggered) |
| Pinch | Zoom image, map | Visual (scale), Haptic (none) |
| Edge Swipe | Back navigation | Visual (screen slide), Haptic (none) |

### 5.2 Animations

#### Screen Transitions
- **Push/Pop**: Native NavigationStack animation (slide from right)
- **Modal**: Sheet from bottom, 0.3s ease-in-out
- **Full Screen**: Fade in, 0.2s

#### Element Animations
- **List Item Appear**: Fade + slide up, 0.3s, staggered by 0.05s
- **Button Press**: Scale to 0.95, 0.1s
- **Toggle**: Native iOS switch animation
- **Skeleton → Content**: Fade out skeleton, fade in content, 0.2s

#### Loading States
- **Spinner**: Continuous rotation, native iOS style
- **Progress Bar**: Fill animation, 0.5s per segment
- **Shimmer**: Gradient sweep, 1.5s repeat

### 5.3 Haptic Feedback

**When to Use**:
- ✅ Button taps (light)
- ✅ Toggle switches (light)
- ✅ Pull-to-refresh triggered (medium)
- ✅ Successful action (success pattern)
- ✅ Error occurred (error pattern)
- ❌ Scrolling (no haptic)
- ❌ Text input (no haptic)
- ❌ Standard navigation (no haptic)

**Implementation**:
```swift
import CoreHaptics

// Light impact
let impact = UIImpactFeedbackGenerator(style: .light)
impact.impactOccurred()

// Success notification
let notification = UINotificationFeedbackGenerator()
notification.notificationOccurred(.success)
```

---

## 6. Accessibility

### 6.1 VoiceOver

**Requirements**:
- All interactive elements must have labels
- Labels should describe action, not appearance
- Images need descriptions (decorative = empty label)
- Status changes should be announced

**Examples**:
- Button: "Add new item" (not "Plus button")
- Card: "Meeting notes, Created 2 hours ago, Tap to view details"
- Image: "Profile photo of John Doe" or "" if decorative
- Toggle: "Notifications, On, Toggle switch" (system provides toggle part)

**Testing**:
- Enable VoiceOver in Simulator (Cmd+F5)
- Navigate with swipe gestures
- Verify all elements are reachable and labeled

### 6.2 Dynamic Type

**Support all text sizes**: Extra Small to Accessibility XXL

**Implementation**:
```swift
Text("Title")
    .font(.title)  // Automatically scales
    .lineLimit(nil)  // Allow wrapping
    .minimumScaleFactor(0.8)  // If must fit one line
```

**Layout Adjustments**:
- Stack elements vertically at larger sizes
- Increase spacing proportionally
- Ensure minimum tap targets (44x44pt)

**Testing**:
- Settings → Accessibility → Display & Text Size → Larger Text
- Test at XS, default, and XXL sizes

### 6.3 Color Contrast

**WCAG AA Standards**:
- Text: 4.5:1 minimum contrast ratio
- Large text (18pt+): 3:1 minimum
- UI elements: 3:1 minimum

**Testing Tools**:
- Xcode Accessibility Inspector
- Online: WebAIM Contrast Checker
- Test in both light and dark modes

**Common Issues**:
- Light gray text on white background (increase contrast)
- Color-only indicators (add icon or label)
- Low opacity overlays (ensure text remains readable)

### 6.4 Reduced Motion

**Respect System Setting**:
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

if reduceMotion {
    // Use fade instead of slide
    // Reduce animation duration
    // Remove complex animations
}
```

**Alternatives**:
- Replace slide animations with instant transitions
- Replace complex spring animations with linear fades
- Reduce animation duration by 50%
- Keep critical animations (loading, errors)

---

## 7. Dark Mode

### 7.1 Color Adaptation

**Semantic Colors** (Automatic):
- Use system colors when possible (they adapt automatically)
- `.primary`, `.secondary` for text
- `.background`, `.secondaryBackground` for surfaces

**Custom Colors**:
- Define in Assets.xcassets with Appearances: "Any, Dark"
- Provide separate values for each mode
- Test all screens in both modes

### 7.2 Image Adaptation

**Techniques**:
- Template images (tint to match color scheme)
- Separate dark mode assets (image_name~dark.png)
- Reduce opacity of photos in dark mode (optional)

### 7.3 Dark Mode Best Practices

**Do**:
- Use true black (#000000) sparingly (only for OLED optimization)
- Use elevated surfaces (lighter) for cards/modals
- Maintain visual hierarchy (contrast between levels)
- Test with "Increase Contrast" enabled

**Don't**:
- Don't invert light mode colors (design separately)
- Don't use pure white text (#FFFFFF) - use slightly off-white
- Don't forget shadows (they disappear on dark backgrounds)

---

## 8. Responsive Design

### 8.1 iPhone Sizes

**Layouts to Support**:
- **iPhone SE (3rd gen)**: 375pt width (smallest)
- **iPhone 15**: 393pt width
- **iPhone 15 Pro Max**: 430pt width (largest)

**Adaptation Strategy**:
- Use flexible layouts (HStack, VStack, Grid)
- Set minimum widths, allow expansion
- Test safe area insets (notch, Dynamic Island)

### 8.2 iPad (Optional)

**Layout Changes**:
- Sidebar navigation instead of tabs
- Multi-column layouts (master-detail)
- Larger cards (2-3 columns in grid)
- Utilize horizontal space

**Keyboard Support**:
- Cmd+N: New item
- Cmd+F: Focus search
- Cmd+S: Save
- Cmd+W: Close modal

### 8.3 Orientation

**Portrait**: Default, all screens optimized
**Landscape**:
- iPhone: Optional (usually lock to portrait)
- iPad: Required, adjust layout

---

## 9. Edge Cases & Error Handling

### 9.1 Network States

| State | User Experience | System Behavior |
|-------|-----------------|-----------------|
| No connection | "No internet connection. Showing saved data." banner at top | Use cached data, disable sync, queue changes |
| Slow connection | Loading indicator, timeout after 30s | Show skeleton screens, async load images |
| Connection restored | "Back online" banner (auto-dismiss 3s) | Trigger sync, upload queued changes |

### 9.2 Data States

| State | User Experience | System Behavior |
|-------|-----------------|-----------------|
| Empty list | ContentUnavailableView with CTA | Hide list, show empty state |
| Single item | Show list with one item (not special case) | Same as multiple items |
| Thousands of items | Paginated, lazy loading, search encouraged | Load 50 at a time, virtual scrolling |

### 9.3 Input Validation

| Invalid Input | User Experience | Prevention |
|---------------|-----------------|------------|
| Empty required field | Red outline, "This field is required" below | Disable Save button |
| Invalid email | "Please enter a valid email" | Real-time validation |
| Duplicate entry | Alert: "Item already exists. Continue?" | Check on save, allow override |

### 9.4 Permission States

| Permission | Denied | Granted |
|------------|--------|---------|
| Camera | Show alert: "Camera access needed. Open Settings?" | Open camera picker |
| Photos | Show placeholder, "Tap to allow photo access" | Open photo picker |
| Notifications | App works without, show banner once | Send notifications |
| Location | Feature disabled, show upgrade message | Show map with location |

---

## 10. Platform-Specific Considerations

### 10.1 iOS Human Interface Guidelines

**Follow These Patterns**:
- Navigation: Use NavigationStack, not custom
- Tabs: Max 5 tabs, use "More" tab if needed
- Modals: Sheet for forms, fullScreenCover for immersive
- Lists: Use native List with proper row heights (44pt min)
- Search: Use .searchable modifier
- Pull-to-refresh: Use .refreshable modifier
- Context menus: Long press for actions

**Avoid**:
- Custom navigation that doesn't follow back button patterns
- Non-standard gestures (users expect iOS conventions)
- Hamburger menus (use tabs or sidebar on iPad)
- Bottom sheets (use native sheets from bottom)

### 10.2 iOS 17+ Features to Leverage

**Adopt New APIs**:
- ContentUnavailableView for empty states
- @Observable for view models (instead of ObservableObject)
- SwiftData for persistence (instead of Core Data)
- #Preview macros (instead of PreviewProvider)
- Sensory feedback API (instead of UIImpactFeedbackGenerator)

**Test on iOS 17+**: Set minimum deployment target to iOS 17.0

---

## 11. Design Handoff Checklist

Before considering UX spec complete:

- [ ] All screens from PRD are designed with wireframes
- [ ] Empty, loading, and error states defined for all screens
- [ ] All interactive elements specified (tap, swipe, long press)
- [ ] Navigation flow is clear and consistent
- [ ] Component library covers all UI elements used
- [ ] Accessibility requirements documented (VoiceOver, Dynamic Type)
- [ ] Dark mode adaptations specified
- [ ] Responsive behavior defined (iPhone sizes)
- [ ] Edge cases and error scenarios handled
- [ ] Animation and haptic feedback specified
- [ ] Colors, typography, spacing all reference design system
- [ ] No placeholder or "TBD" items remain

---

## Appendix A: Screen Specifications Template

Use this template for additional screens not detailed above:

```markdown
### X.X [Screen Name]

**Purpose**: [One sentence describing what user accomplishes]

**Layout** (ASCII wireframe):
```
┌─────────────────────────────────────┐
│  [Navigation Bar]                   │
├─────────────────────────────────────┤
│                                     │
│  [Main Content Area]                │
│                                     │
├─────────────────────────────────────┤
│  [Bottom Bar / Actions]             │
└─────────────────────────────────────┘
```

**Components**:
- [Component 1]: [Description]
- [Component 2]: [Description]

**Interactions**:
- Tap [Element] → [Result]
- Swipe [Direction] → [Action]

**States**:
- Empty: [How it looks]
- Loading: [How it looks]
- Error: [How it looks]

**Data Requirements**:
- [Data needed from backend/storage]

**Accessibility**:
- [VoiceOver labels]
- [Special considerations]
```

---

**Document History**:
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | [Date] | UX Designer AI | Initial UX specification |
```

### 2. docs/DESIGN_SYSTEM.md

```markdown
# Design System: [App Name]

**Version**: 1.0.0
**Last Updated**: [Date]
**Platform**: iOS 17+
**Language**: SwiftUI

---

## 1. Brand Identity

### 1.1 Brand Personality
**From Positioning**: [e.g., "Professional, trustworthy, modern with a human touch"]

**Visual Expression**:
- **Modern**: Clean lines, generous whitespace, sans-serif typography
- **Professional**: Muted color palette, consistent spacing, subtle animations
- **Approachable**: Friendly copy, helpful empty states, forgiving errors

### 1.2 Voice & Tone

**Voice** (Consistent):
- Clear and concise
- Helpful, not bossy
- Human, not robotic
- Confident, not arrogant

**Tone** (Context-dependent):
- **Success**: Encouraging ("Great job!")
- **Error**: Apologetic and helpful ("Oops! Let's try that again.")
- **Onboarding**: Excited and welcoming ("Welcome! Let's get started.")
- **Empty state**: Optimistic ("Ready to create your first item?")

---

## 2. Color Palette

### 2.1 Primary Colors

**Brand Primary** (Main CTA, key actions):
```swift
// Light mode
static let brandPrimary = Color(hex: "#007AFF")  // iOS Blue

// Dark mode
static let brandPrimaryDark = Color(hex: "#0A84FF")  // Lighter blue
```

**Brand Secondary** (Accents, highlights):
```swift
// Light mode
static let brandSecondary = Color(hex: "#5856D6")  // Purple

// Dark mode
static let brandSecondaryDark = Color(hex: "#5E5CE6")
```

**Brand Accent** (Destructive actions, warnings):
```swift
// Light mode
static let brandAccent = Color(hex: "#FF3B30")  // Red

// Dark mode
static let brandAccentDark = Color(hex: "#FF453A")
```

### 2.2 Semantic Colors

**Success** (Confirmation, completion):
```swift
static let success = Color(hex: "#34C759")  // Green
```

**Warning** (Caution, attention needed):
```swift
static let warning = Color(hex: "#FF9500")  // Orange
```

**Error** (Errors, destructive actions):
```swift
static let error = Color(hex: "#FF3B30")  // Red (same as accent)
```

**Info** (Tips, information):
```swift
static let info = Color(hex: "#007AFF")  // Blue (same as primary)
```

### 2.3 Neutral Colors

**Backgrounds**:
```swift
// Light mode
static let background = Color.white
static let secondaryBackground = Color(hex: "#F2F2F7")  // iOS gray
static let tertiaryBackground = Color(hex: "#FFFFFF")

// Dark mode
static let backgroundDark = Color(hex: "#000000")
static let secondaryBackgroundDark = Color(hex: "#1C1C1E")
static let tertiaryBackgroundDark = Color(hex: "#2C2C2E")
```

**Text**:
```swift
// Light mode
static let textPrimary = Color(hex: "#000000")
static let textSecondary = Color(hex: "#3C3C43", opacity: 0.6)  // iOS secondary label
static let textTertiary = Color(hex: "#3C3C43", opacity: 0.3)

// Dark mode
static let textPrimaryDark = Color(hex: "#FFFFFF")
static let textSecondaryDark = Color(hex: "#EBEBF5", opacity: 0.6)
static let textTertiaryDark = Color(hex: "#EBEBF5", opacity: 0.3)
```

**Borders & Dividers**:
```swift
static let separator = Color(hex: "#3C3C43", opacity: 0.36)
static let border = Color(hex: "#C7C7CC")
```

### 2.4 Usage Guidelines

**Primary Color**:
- Primary CTAs (Save, Submit, Continue)
- Active tab bar items
- Selected state
- Links

**Secondary Color**:
- Secondary actions
- Highlights
- Badges (non-critical)

**Accent Color**:
- Delete buttons
- Error states
- Critical alerts

**Backgrounds**:
- background: Screen background
- secondaryBackground: Card backgrounds, input fields
- tertiaryBackground: Nested cards, elevated surfaces

---

## 3. Typography

### 3.1 Type Scale

**iOS Dynamic Type** (Automatically scales with user preference):

```swift
// Display
.largeTitle     // 34pt, Bold    - Screen titles
.title          // 28pt, Bold    - Major sections
.title2         // 22pt, Bold    - Subsections, cards
.title3         // 20pt, Semibold - Groups

// Body
.headline       // 17pt, Semibold - Emphasized text, button labels
.body           // 17pt, Regular  - Default body text
.callout        // 16pt, Regular  - Secondary content

// Supporting
.subheadline    // 15pt, Regular  - Subtitles, labels
.footnote       // 13pt, Regular  - Timestamps, metadata
.caption        // 12pt, Regular  - Section headers (uppercase)
.caption2       // 11pt, Regular  - Fine print
```

### 3.2 Font Family

**Default**: System Font (SF Pro)
- No custom fonts needed (SF Pro is optimized for iOS)
- If custom font required: Choose legible, web-safe fallback

### 3.3 Font Weights

```swift
.ultraLight     // Avoid, too thin
.thin           // Avoid
.light          // Occasional use
.regular        // Default for body text
.medium         // Occasional emphasis
.semibold       // Headings, emphasized text
.bold           // Titles, important actions
.heavy          // Avoid, too thick
.black          // Avoid
```

### 3.4 Line Height & Spacing

**Default**: SwiftUI handles automatically
**Custom** (if needed):
```swift
.lineSpacing(4)  // Add 4pt between lines (for dense text)
```

**Paragraph Spacing**: 12pt between paragraphs

### 3.5 Usage Guidelines

| Element | Style | Use Case |
|---------|-------|----------|
| Screen Title | .largeTitle | Home, Settings navigation bar |
| Section Header | .title2 | "Recent Items", "Profile" |
| Card Title | .headline | Item name in list |
| Body Text | .body | Descriptions, paragraphs |
| Metadata | .footnote | Timestamps, "Created 2h ago" |
| Button Label | .headline | All buttons |
| Input Label | .caption | Above text fields |
| Placeholder | .body + opacity 0.5 | Text field placeholder |

---

## 4. Spacing System

### 4.1 Spacing Scale

**Base Unit**: 4pt

```swift
enum Spacing {
    static let xxs: CGFloat = 2   // Tight spacing (icon to text)
    static let xs: CGFloat = 4    // Very small (between related elements)
    static let s: CGFloat = 8     // Small (list item internal padding)
    static let m: CGFloat = 12    // Medium (between components)
    static let l: CGFloat = 16    // Large (card padding, margins) ⭐ Default
    static let xl: CGFloat = 24   // Extra large (section spacing)
    static let xxl: CGFloat = 32  // Screen margins, major sections
    static let xxxl: CGFloat = 48 // Between major screen areas
}
```

### 4.2 Usage Guidelines

**Padding** (Inside components):
- Cards: 16pt all sides
- Buttons: 16pt horizontal, 12pt vertical
- Text fields: 16pt horizontal, 12pt vertical
- List rows: 16pt horizontal, 8pt vertical

**Margins** (Between components):
- List items: 8pt vertical
- Sections: 24pt vertical
- Screen edges: 16pt horizontal

**Stack Spacing**:
```swift
VStack(spacing: 12) { ... }  // Default
HStack(spacing: 8) { ... }   // Tight
VStack(spacing: 24) { ... }  // Loose
```

---

## 5. Layout Grid

### 5.1 Grid System

**Columns**: 12-column grid (flexible)
**Gutter**: 16pt between columns
**Margins**: 16pt (iPhone), 20pt (iPad)

**Usage**:
- Single column: Full width (12/12)
- Two columns: 6/12 each (rare on iPhone)
- Three columns: 4/12 each (iPad only)

### 5.2 Breakpoints

| Device | Width (pt) | Columns | Margins |
|--------|-----------|---------|---------|
| iPhone SE | 375 | 1 | 16pt |
| iPhone 15 | 393 | 1 | 16pt |
| iPhone Pro Max | 430 | 1 | 16pt |
| iPad Portrait | 768 | 2 | 20pt |
| iPad Landscape | 1024 | 3 | 20pt |

---

## 6. Iconography

### 6.1 Icon Set

**Primary**: SF Symbols (native, 4000+ icons)
**Custom**: Only if SF Symbols doesn't have the icon

### 6.2 Icon Sizes

```swift
.small      // 16x16pt - Inline with text
.medium     // 20x20pt - Default
.large      // 24x24pt - Emphasized
.xlarge     // 28x28pt - Hero icons
```

### 6.3 Icon Weights

**Match text weight**:
- Body text (.regular) → .regular weight icon
- Headline (.semibold) → .semibold weight icon
- Title (.bold) → .bold weight icon

```swift
Image(systemName: "star.fill")
    .font(.title2)  // Size
    .fontWeight(.semibold)  // Weight
```

### 6.4 Icon Colors

**Default**: Match text color
**Tinted**: Brand primary for active/selected
**Multicolor**: SF Symbols multicolor variant (sparingly)

### 6.5 Common Icons

| Use Case | SF Symbol | Alternative |
|----------|-----------|-------------|
| Add | plus | plus.circle.fill |
| Delete | trash | trash.fill |
| Edit | pencil | pencil.circle |
| Search | magnifyingglass | - |
| Settings | gearshape | gearshape.fill |
| Profile | person | person.circle |
| Home | house | house.fill |
| Favorites | star | star.fill |
| Share | square.and.arrow.up | - |
| Close | xmark | xmark.circle.fill |
| Back | chevron.left | arrow.left |
| Success | checkmark.circle.fill | - |
| Error | xmark.circle.fill | exclamationmark.triangle.fill |
| Warning | exclamationmark.triangle | - |
| Info | info.circle | questionmark.circle |

---

## 7. Shadows & Elevation

### 7.1 Shadow Levels

**Level 1** (Cards, subtle elevation):
```swift
.shadow(color: .black.opacity(0.1), radius: 8, y: 2)
```

**Level 2** (Modals, popovers):
```swift
.shadow(color: .black.opacity(0.15), radius: 16, y: 4)
```

**Level 3** (Dropdowns, tooltips):
```swift
.shadow(color: .black.opacity(0.2), radius: 24, y: 8)
```

### 7.2 Usage Guidelines

**When to Use Shadows**:
- Cards on plain background (differentiation)
- Floating action buttons
- Modals and sheets
- Popovers and dropdowns

**When NOT to Use**:
- Dark mode (use borders or different background colors)
- List items (use dividers instead)
- Flat design (intentionally no elevation)

### 7.3 Dark Mode Adaptation

**Replace shadows with borders**:
```swift
if colorScheme == .dark {
    .border(Color.white.opacity(0.1), width: 1)
} else {
    .shadow(radius: 8, y: 2)
}
```

---

## 8. Corner Radius

### 8.1 Radius Scale

```swift
enum CornerRadius {
    static let xs: CGFloat = 4   // Very subtle (badges)
    static let s: CGFloat = 8    // Small (buttons, inputs)
    static let m: CGFloat = 12   // Medium (cards) ⭐ Default
    static let l: CGFloat = 16   // Large (modals, sheets)
    static let xl: CGFloat = 24  // Extra large (hero cards)
    static let full: CGFloat = 9999  // Fully rounded (pills, avatars)
}
```

### 8.2 Usage Guidelines

| Element | Radius | Rationale |
|---------|--------|-----------|
| Buttons | 12pt | iOS standard, comfortable |
| Text inputs | 10pt | Slightly less than buttons (visual distinction) |
| Cards | 12pt | Consistent with buttons |
| Modals/Sheets | 16pt | Larger surface, more prominence |
| Badges | 8pt or full | Depends on style (rounded or pill) |
| Avatars | full | Circular |
| Thumbnails | 8pt | Subtle rounding |

---

## 9. Animation & Motion

### 9.1 Animation Timings

```swift
enum AnimationDuration {
    static let fast: Double = 0.2    // Button press, toggle
    static let standard: Double = 0.3  // Screen transition, fade ⭐ Default
    static let slow: Double = 0.5    // Complex animations
    static let verySlow: Double = 1.0  // Onboarding, celebration
}
```

### 9.2 Easing Curves

**Default**: `.easeInOut` (most natural)

```swift
.animation(.easeInOut(duration: 0.3), value: someValue)
```

**Spring**: For playful, bouncy effects
```swift
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: someValue)
```

**Linear**: For progress bars, loaders
```swift
.animation(.linear(duration: 2.0), value: progress)
```

### 9.3 Common Animations

**Fade In/Out**:
```swift
.opacity(isVisible ? 1 : 0)
.animation(.easeInOut(duration: 0.3), value: isVisible)
```

**Slide In**:
```swift
.offset(y: isVisible ? 0 : 50)
.opacity(isVisible ? 1 : 0)
.animation(.easeOut(duration: 0.4), value: isVisible)
```

**Scale (Button Press)**:
```swift
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isPressed)
```

**Rotation**:
```swift
.rotationEffect(.degrees(isLoading ? 360 : 0))
.animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isLoading)
```

### 9.4 Reduced Motion

**Respect accessibility setting**:
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

if reduceMotion {
    // Use fade instead of slide
    .opacity(isVisible ? 1 : 0)
} else {
    // Use full animation
    .offset(y: isVisible ? 0 : 50)
    .opacity(isVisible ? 1 : 0)
}
```

---

## 10. Component Styles (SwiftUI Code)

### 10.1 Button Styles

```swift
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.brandPrimary)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Usage:
Button("Continue") { }
    .buttonStyle(PrimaryButtonStyle())
```

### 10.2 Card Modifier

```swift
extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}

// Usage:
VStack { ... }
    .cardStyle()
```

### 10.3 Text Field Style

```swift
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.brandPrimary.opacity(0.3), lineWidth: 1)
            )
    }
}

// Usage:
TextField("Enter name", text: $name)
    .textFieldStyle(CustomTextFieldStyle())
```

---

## 11. Assets Organization

### 11.1 Color Assets

**Location**: `Assets.xcassets/Colors/`

**Naming Convention**:
- `BrandPrimary` (with Light + Dark appearances)
- `BrandSecondary`
- `TextPrimary`
- `BackgroundSecondary`

### 11.2 Image Assets

**Location**: `Assets.xcassets/Images/`

**Naming Convention**:
- `icon-name` (lowercase, hyphen-separated)
- `illustration-onboarding-1`
- `placeholder-avatar`

**Formats**:
- Icons: PDF (vector) or PNG @2x, @3x
- Photos: PNG or JPEG @2x, @3x
- Illustrations: PDF (preferred) or PNG

### 11.3 SF Symbols

**No need to add to assets** - use directly by name:
```swift
Image(systemName: "star.fill")
```

---

## 12. Design Tokens (Reference)

For developers: centralized constants file

```swift
// DesignTokens.swift

import SwiftUI

enum DesignSystem {
    // Colors
    enum Colors {
        static let brandPrimary = Color("BrandPrimary")
        static let brandSecondary = Color("BrandSecondary")
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let success = Color.green
        static let error = Color.red
        static let warning = Color.orange
    }

    // Typography
    enum Typography {
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let headline = Font.headline
        static let body = Font.body
        static let caption = Font.caption
    }

    // Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // Corner Radius
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let full: CGFloat = 9999
    }

    // Shadows
    enum Shadow {
        static let card = (color: Color.black.opacity(0.1), radius: CGFloat(8), y: CGFloat(2))
        static let modal = (color: Color.black.opacity(0.15), radius: CGFloat(16), y: CGFloat(4))
    }

    // Animation
    enum Animation {
        static let fast = 0.2
        static let standard = 0.3
        static let slow = 0.5
    }
}

// Usage:
Text("Hello")
    .font(DesignSystem.Typography.headline)
    .foregroundColor(DesignSystem.Colors.brandPrimary)
    .padding(DesignSystem.Spacing.l)
```

---

## 13. Implementation Checklist

Before considering design system complete:

- [ ] All colors defined in Assets.xcassets with Dark mode variants
- [ ] Typography scale documented and tested at multiple sizes
- [ ] Spacing scale applied consistently across all screens
- [ ] Corner radius values standardized
- [ ] Shadow styles defined for different elevation levels
- [ ] Icon library documented (SF Symbols references)
- [ ] Animation timings and easing curves specified
- [ ] Component styles implemented as reusable SwiftUI modifiers
- [ ] Design tokens file created for developer reference
- [ ] Dark mode tested for all colors and components
- [ ] Accessibility: Dynamic Type, VoiceOver, Contrast verified
- [ ] Responsive behavior tested on all iPhone sizes

---

**Document History**:
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | [Date] | UX Designer AI | Initial design system |
```

---

## Execution Instructions

When activated, follow these steps:

1. **Locate and Read Input Documents**
   ```
   - Read docs/PRD.md (all features and user flows)
   - Read docs/ARCHITECTURE.md (app structure, data models)
   - Read product-plan-*.md (positioning, brand personality)
   If any missing, ask user for file path
   ```

2. **Extract Key Information**
   From inputs, extract:
   - All screens needed (from PRD features)
   - Navigation structure (from architecture)
   - Brand personality (from positioning)
   - Core features to design (from PRD MVP scope)
   - Platform (iOS/macOS)

3. **Design Information Architecture**
   - List all screens
   - Determine navigation pattern (tabs, stack, sidebar)
   - Create navigation flow diagram
   - Prioritize screens (P0, P1, P2)

4. **Create Wireframes for Core Screens**
   For each P0 screen:
   - Draw ASCII wireframe (clear layout)
   - Specify all components
   - Document all interactions
   - Define states (empty, loading, error)
   - List data requirements

5. **Define Design System**
   Based on brand personality:
   - Choose color palette (align with positioning)
   - Define typography scale (iOS standard)
   - Set spacing system (8pt grid)
   - Specify component styles (buttons, cards, inputs)
   - Document animation timings

6. **Generate Output Files**
   ```
   Write comprehensive UX_SPEC.md to: docs/UX_SPEC.md
   Write complete DESIGN_SYSTEM.md to: docs/DESIGN_SYSTEM.md
   ```

7. **Present to User**
   After generating files, present summary:

   ```
   ✅ UI/UX Specifications generated!

   📱 **UX_SPEC.md Summary**:
   - Screens designed: [X] screens with wireframes
   - User flows documented: [Y] flows
   - Interaction patterns: Defined for all screens
   - Accessibility: VoiceOver labels, Dynamic Type, contrast ratios

   🎨 **DESIGN_SYSTEM.md Summary**:
   - Color palette: [X] colors (light + dark mode)
   - Typography: iOS Dynamic Type scale
   - Component library: [Y] reusable components
   - Animation guidelines: Timings and easing curves

   **Next Steps**:
   1. Review the wireframes in docs/UX_SPEC.md
   2. Check the design system in docs/DESIGN_SYSTEM.md
   3. Provide feedback on any screens or components
   4. Once approved, we can proceed to implementation guide

   Would you like me to make any changes to the UI design?
   ```

8. **Iterate Based on Feedback**
   If user requests changes:
   - Ask clarifying questions
   - Update UX_SPEC.md and/or DESIGN_SYSTEM.md
   - Maintain consistency across both documents

---

## Quality Guidelines

When generating the UX specifications:

1. **Be Visual**: ASCII wireframes should be clear and detailed
   - BAD: Just describe "A list of items"
   - GOOD: Draw the actual layout with boxes, labels, and spacing

2. **Be Specific**: Every interaction should be defined
   - BAD: "User can tap the button"
   - GOOD: "Tap 'Save' button → Validate fields → Show loading spinner → Dismiss sheet → Return to Home with success toast"

3. **Be Complete**: Cover all states
   - Happy path (default)
   - Empty state (no data)
   - Loading state (data fetching)
   - Error state (failed to load)
   - Skeleton/placeholder (progressive loading)

4. **Follow iOS HIG**: Use native patterns
   - NavigationStack for hierarchical navigation
   - TabView for flat navigation
   - Sheet for forms/modals
   - List for collections
   - SwiftUI standard components

5. **Design for Accessibility**: Not an afterthought
   - VoiceOver labels for every element
   - Dynamic Type support
   - Color contrast 4.5:1 minimum
   - Reduced motion alternatives

6. **Be Consistent**: Reference design system
   - Use defined colors (don't introduce new ones)
   - Use spacing scale (not random values)
   - Use typography scale (not arbitrary sizes)
   - Reuse components (don't create one-offs)

---

## Example Activation

**User**: "Generate UX spec from PRD"

**You**:
1. Read docs/PRD.md
2. Read docs/ARCHITECTURE.md
3. Read product-plan-*.md for positioning
4. Extract all features needing screens
5. Design wireframes for each screen (ASCII art)
6. Create comprehensive design system
7. Write both documents to docs/
8. Present summary with next steps

---

## Integration with Workflow

This skill is typically:
- **Third step** in specification generation
- Activated after PRD and Architecture are complete
- Followed by implementation-guide, test-spec, release-spec

The UX specifications serve as the visual blueprint that developers use to implement the UI.

---

## Notes

- Focus on iOS patterns - don't reinvent the wheel
- ASCII wireframes are sufficient - no need for high-fidelity mockups
- Provide enough detail that a developer can implement without guessing
- Reference Apple's Human Interface Guidelines throughout
- Ensure all specifications are actionable and unambiguous
- Keep design system tokens consistent across both documents
- Test all designs mentally for accessibility before documenting
