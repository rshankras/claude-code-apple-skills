---
name: ui-review
description: Review SwiftUI code for iOS/watchOS Human Interface Guidelines compliance, font usage, Dynamic Type support, and accessibility. Use when user mentions UI review, HIG, accessibility audit, font checks, or wants to verify interface design against Apple standards.
allowed-tools: [Read, Glob, Grep, WebFetch]
---

# UI Review Skill

Performs comprehensive UI/UX review of SwiftUI code against Apple's Human Interface Guidelines, font best practices, and accessibility standards for iOS and watchOS.

## When This Skill Activates

Use this skill when the user:
- Asks to review UI/UX code
- Mentions HIG compliance or Apple guidelines
- Requests accessibility audit
- Wants font usage checked
- Asks about Dynamic Type support
- Requests design review against Apple standards

## Review Process

### 1. Identify Files to Review

- If user specifies files/views, review those
- Otherwise, ask which views to review or scan recent SwiftUI files
- Prioritize user-facing views over components

### 2. Load Reference Materials

Before starting the review, familiarize yourself with the reference materials by reading the following files in `.claude/skills/ui-review/`:

- **hig-checklist.md** - Comprehensive HIG compliance checklist for iOS and watchOS
- **font-guidelines.md** - Font usage, Dynamic Type, and typography best practices
- **accessibility-quick-ref.md** - Quick reference for accessibility implementation

You may also reference the official Apple guidelines using WebFetch when needed:
- **iOS HIG**: https://developer.apple.com/design/human-interface-guidelines/designing-for-ios
- **watchOS HIG**: https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos

### 3. Review Categories

Apply these review categories based on the code type:

**HIG Compliance:**
- Layout & spacing (tap targets, safe areas, padding)
- Navigation patterns (NavigationStack, sheets, alerts)
- Colors & visuals (semantic colors, dark mode, contrast)
- Platform-specific requirements (iOS vs watchOS)
- Loading/empty/error states

**Font Usage:**
- Dynamic Type support
- System text styles vs fixed sizes
- Font hierarchy and semantic usage
- Custom fonts scaling properly
- Text formatting and truncation

**Accessibility:**
- Labels and hints for interactive elements
- Traits and roles
- VoiceOver navigation order
- Custom actions
- Dynamic content announcements
- Testing with assistive technologies

### 4. Common Issues to Flag

**Anti-patterns:**
- Hardcoded colors (`.foregroundColor(.black)`)
- Fixed font sizes (`.font(.system(size: 14))`)
- Missing accessibility labels on icon-only buttons
- Tap targets smaller than 44pt (iOS) or 40pt (watchOS)
- Important info conveyed by color only
- Missing loading/error states
- Direct UIColor usage (use `Color(.systemBackground)`)
- `.frame()` without considering Dynamic Type expansion
- Missing keyboard shortcuts (iPad/Mac)

**Good Patterns:**
- Semantic color usage
- System font styles with Dynamic Type
- Comprehensive accessibility labels
- Clear visual hierarchy
- Consistent spacing
- Proper error handling
- Responsive layouts

## Output Format

Provide review in this structure:

### ✅ HIG Compliance
- List items that comply well
- Highlight good practices

### ⚠️ HIG Issues Found
- Specific line references: `filename.swift:lineNumber`
- Description of issue
- Suggested fix with code example

### ✅ Font Usage
- Proper Dynamic Type usage
- Good font hierarchy

### ⚠️ Font Issues Found
- Hardcoded sizes or missing Dynamic Type support
- Suggested fixes

### ✅ Accessibility
- Well-implemented accessibility features
- Good label/hint usage

### ⚠️ Accessibility Issues Found
- Missing labels or hints
- Incorrect traits
- Navigation problems
- Suggested fixes with code examples

### 📋 Testing Recommendations
- Specific tests to run (VoiceOver, Dynamic Type, Dark Mode)
- Accessibility Inspector checks
- Device/simulator testing suggestions

## Example Review Output

```
Reviewing: AddOrUpdateExpenseView.swift

✅ HIG Compliance
- Good use of semantic colors throughout
- Proper NavigationStack implementation
- Safe area handling is correct

⚠️ HIG Issues Found
1. AddOrUpdateExpenseView.swift:145 - Delete button tap target may be small
   Suggested fix: Ensure .frame(minWidth: 44, minHeight: 44)

2. AddOrUpdateExpenseView.swift:203 - Hardcoded color
   Current: .foregroundColor(.red)
   Suggested: .foregroundColor(Color(.systemRed))

✅ Font Usage
- Excellent use of .headline for section headers
- Proper .body for content text

⚠️ Font Issues Found
1. AddOrUpdateExpenseView.swift:178 - Hardcoded font size
   Current: .font(.system(size: 14))
   Suggested: .font(.subheadline)

✅ Accessibility
- Good labels on most form fields
- Proper form structure

⚠️ Accessibility Issues Found
1. AddOrUpdateExpenseView.swift:92 - Icon button missing label
   Current: Button { } label: { Image(systemName: "calendar") }
   Suggested: Add .accessibilityLabel("Select date")

📋 Testing Recommendations
1. Test with VoiceOver enabled
2. Test at largest Dynamic Type size (Accessibility → Display)
3. Verify in Dark Mode
4. Use Accessibility Inspector to check contrast ratios
```

## References

Always reference these when in doubt:
- [iOS HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios)
- [watchOS HIG](https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Accessibility on Apple platforms](https://developer.apple.com/accessibility/)

## Notes

- Be constructive and specific
- Provide code examples for fixes
- Reference exact line numbers
- Prioritize user-impacting issues
- Consider context (some exceptions are valid)
