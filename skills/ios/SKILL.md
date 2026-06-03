---
name: ios-development
description: Comprehensive iOS development guidance including Swift best practices, SwiftUI patterns, UI/UX review against HIG, and app planning. Use for iOS code review, best practices, accessibility audits, or planning new iOS apps.
allowed-tools: [Read, Glob, Grep, WebFetch]
---

# iOS Development Expert

Comprehensive guidance for iOS app development. This skill aggregates specialized modules for different aspects of iOS development.

## When This Skill Activates

Use this skill when the user:
- Asks about iOS development best practices
- Wants code review for iOS/Swift projects
- Needs UI/UX review against Human Interface Guidelines
- Wants accessibility audit for iOS apps
- Is planning a new iOS app
- Needs help with SwiftUI patterns for iOS
- Asks about navigation architecture (NavigationStack, NavigationSplitView, TabView)
- Wants to run/launch the app in the Simulator or screenshot it to verify a change

## Available Modules

Read relevant module files based on the user's needs:

### coding-best-practices/
Swift code quality and modern idioms for iOS.
- Modern Swift patterns and idioms
- Architecture patterns (MVVM, Clean Architecture)
- Code quality standards
- Performance optimization

### ui-review/
UI/UX review against Apple HIG.
- Human Interface Guidelines compliance
- Font usage and Dynamic Type support
- Accessibility review (VoiceOver, color contrast)
- SwiftUI best practices for iOS/watchOS

### navigation-patterns/
SwiftUI navigation architecture patterns.
- NavigationStack, NavigationLink, navigationDestination
- NavigationSplitView (two/three column, iPad/macOS)
- TabView (iOS 18 customizable tabs, sidebar mode)
- Programmatic navigation (NavigationPath, pop-to-root, state restoration)
- Navigation transitions (zoom, custom animations)

### app-planner/
iOS app planning and analysis.
- New app concept to architecture
- Existing app audits
- Tech stack evaluation
- Product planning guidance

### run-simulator/
Build, install, launch, and screenshot the app in the Simulator to verify a
change visually (operational — uses Bash, not just guidance).
- Discover scheme + an available simulator (no hardcoded device names)
- Build for the simulator and resolve the `.app` + bundle id
- Boot, install, launch, then screenshot and read it back
- Drive navigation / deep links to reach the changed screen

### run-device/
Run an app on a physical iPhone/iPad from the CLI (no Xcode GUI).
- Build + code-sign for a device with `xcodebuild -allowProvisioningUpdates`
- Install and launch via `devicectl`
- Screenshot on hardware via `libimobiledevice`
- Device prerequisites (Developer Mode, pairing) and signing gotchas

## How to Use

1. Identify user's need from their question
2. Read relevant module files from subdirectories
3. Apply the guidance to their specific context
4. Reference Apple HIG documentation when needed

## Example Workflow

**User asks for UI review:**
1. Read `ui-review/SKILL.md` for the full review process
2. Check their SwiftUI code against HIG
3. Verify accessibility compliance
4. Report findings with specific recommendations
