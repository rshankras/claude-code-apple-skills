---
name: generators
description: Code generator skills that produce production-ready Swift code for common app components. Use when user wants to add logging, analytics, onboarding, review prompts, or other common features.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
---

# Code Generators

Production-ready code generators for iOS and macOS apps. Unlike advisory skills (review, audit), these skills generate working code tailored to your project.

## When This Skill Activates

Use this skill when the user:
- Wants to add a common app component (logging, analytics, onboarding, etc.)
- Asks to "set up" or "add" infrastructure code
- Mentions replacing print() with proper logging
- Wants to add App Store review prompts
- Needs analytics or crash reporting setup

## Key Principles

### 1. Context-Aware Generation
Before generating code, skills will:
- Read existing project structure and patterns
- Detect deployment targets and Swift version
- Identify architecture patterns (MVVM, TCA, etc.)
- Check for existing implementations to avoid conflicts

### 2. Protocol-Based Architecture
Provider-dependent code uses protocols for easy swapping:
```swift
protocol AnalyticsService { ... }
class TelemetryDeckAnalytics: AnalyticsService { ... }
class FirebaseAnalytics: AnalyticsService { ... }
// Change provider by swapping ONE line
```

### 3. Platform Detection
Skills detect iOS vs macOS and App Store vs direct distribution to generate appropriate code.

## Available Generators

Read relevant module files based on the user's needs:

### logging-setup/
Replace print() statements with structured os.log/Logger.
- Audit existing print() usage
- Generate AppLogger infrastructure
- Migrate print → Logger with proper privacy levels

### analytics-setup/
Protocol-based analytics with swappable providers.
- TelemetryDeck, Firebase, Mixpanel support
- NoOp implementation for testing/privacy
- Easy provider switching

### onboarding-generator/
Multi-step onboarding flow with persistence.
- Paged or stepped navigation
- @AppStorage persistence
- Skip option configuration
- Accessibility support

### review-prompt/
Smart App Store review prompts.
- Platform detection (skips for non-App Store macOS)
- Configurable trigger conditions
- Smart timing logic
- Debug override for testing

## How to Use

1. User requests a component (e.g., "add logging to my app")
2. Read the relevant skill's SKILL.md
3. Run pre-generation checks (conflicts, deployment target, etc.)
4. Ask configuration questions via AskUserQuestion
5. Generate code from templates, adapting to project context
6. Provide integration instructions

## Output Format

After generation, always provide:
- **Files created** (with full paths)
- **Integration steps** (how to wire into existing code)
- **Required capabilities** (entitlements, dependencies)
- **Testing instructions** (how to verify it works)
