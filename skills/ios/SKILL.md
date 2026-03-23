---
name: ios-development
description: >
  iOS development guidance covering Swift best practices, SwiftUI patterns,
  Human Interface Guidelines UI/UX review, accessibility audits, navigation
  architecture (NavigationStack, NavigationSplitView, TabView), and app planning.
  Activate when a user asks for iOS code review, Swift pattern advice,
  HIG compliance checks, accessibility audit, or new iOS app architecture planning.
allowed-tools: "Read, Glob, Grep, Bash, WebFetch"
---

# iOS Development Expert

Comprehensive guidance for iOS app development. This skill aggregates specialized modules for Swift code quality, UI/UX review, navigation architecture, and app planning.

## Activation

Trigger this skill when the user:

- Requests iOS or Swift code review
- Asks about SwiftUI best practices or modern Swift patterns
- Needs a UI/UX audit against Apple Human Interface Guidelines
- Wants an accessibility review (VoiceOver, Dynamic Type, color contrast)
- Is planning a new iOS app (architecture, tech stack, product scope)
- Asks about navigation patterns (NavigationStack, NavigationSplitView, TabView)

## Modules

Read the relevant module files based on the user's request:

### coding-best-practices/
Swift code quality and modern idioms for iOS.
- Read `coding-best-practices/SKILL.md` for Swift patterns, MVVM/Clean Architecture, code quality standards, and performance tips.

### ui-review/
UI/UX review against Apple HIG.
- Read `ui-review/SKILL.md` for HIG compliance checks, font/Dynamic Type support, accessibility review (VoiceOver, color contrast), and SwiftUI best practices.

### navigation-patterns/
SwiftUI navigation architecture patterns.
- Read `navigation-patterns/SKILL.md` for NavigationStack, NavigationSplitView, TabView (iOS 18 customizable tabs), programmatic navigation (NavigationPath, pop-to-root, state restoration), and navigation transitions.

### app-planner/
iOS app planning and analysis.
- Read `app-planner/SKILL.md` for new app concept-to-architecture workflows, existing app audits, tech stack evaluation, and product planning.

## Workflow

1. Identify the user's need from their question.
2. Read the matching module SKILL.md file(s) from the subdirectories listed above.
3. Apply the module's guidance to the user's specific code or project context.
4. Reference Apple HIG documentation where relevant.
5. Provide concrete, actionable recommendations with code examples when appropriate.
