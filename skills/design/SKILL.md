---
name: design
description: Design system skills for modern Apple platform UI including Liquid Glass, animations, and visual design patterns. Use when implementing new design language features.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# Design Skills

Skills for implementing Apple's modern design systems across platforms.

## When This Skill Activates

Use this skill when the user:
- Asks about Liquid Glass design
- Wants to implement modern Apple UI effects
- Needs guidance on visual design patterns
- Asks about materials, transparency, or blur effects
- Wants to create fluid animations
- Asks about **spring**, **bounce**, or **snappy** animations
- Wants **PhaseAnimator** or **KeyframeAnimator** help
- Needs **view transitions**, **matched geometry**, or **hero transitions**
- Wants **SF Symbol effects** (bounce, pulse, wiggle, breathe)
- Asks about **animation completions** or **withAnimation**

## Available Skills

### liquid-glass/
Comprehensive Liquid Glass implementation for iOS 26+, macOS 26+.
- SwiftUI `.glassEffect()` API
- AppKit `NSGlassEffectView`
- GlassEffectContainer patterns
- Morphing transitions
- Interactive effects
- Button styles

### animation-patterns/
SwiftUI animation patterns for iOS 13–18+.
- Spring configurations (3 API generations)
- PhaseAnimator and KeyframeAnimator (iOS 17+)
- View transitions, matched geometry, navigation transitions
- SF Symbol effects
- Animation completions, transactions, timing curves

## Key Principles

### 1. Platform Consistency
- Follow Apple Human Interface Guidelines
- Use system-provided APIs
- Respect user appearance preferences

### 2. Performance
- Use GlassEffectContainer for multiple effects
- Limit number of glass effects per view
- Consider GPU resources

### 3. Visual Hierarchy
- Glass effects create depth and layering
- Use tints to indicate prominence
- Combine with appropriate shadows

## Reference Documentation

- `/Users/ravishankar/Downloads/docs/SwiftUI-Implementing-Liquid-Glass-Design.md`
- `/Users/ravishankar/Downloads/docs/AppKit-Implementing-Liquid-Glass-Design.md`
