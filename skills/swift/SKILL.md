---
name: swift-development
description: Swift language patterns and best practices including concurrency, performance, and modern idioms. Use for Swift language-level code review or architecture guidance.
allowed-tools: [Read, Glob, Grep]
---

# Swift Development

Swift language-level guidance that applies across all Apple platforms.

## When This Skill Activates

Use this skill when the user:
- Asks about Swift concurrency (async/await, actors, Sendable, TaskGroup)
- Needs help with Swift 6 strict concurrency migration
- Has data race or actor isolation errors
- Asks about **InlineArray**, **Span**, or low-level memory performance
- Wants to eliminate heap allocations or replace unsafe pointers
- Asks about modern Swift patterns independent of any specific platform

## Available Modules

### concurrency-patterns/
Swift concurrency architecture and patterns.
- Swift 6.2 approachable concurrency features
- Structured concurrency (async let, TaskGroup, .task modifier)
- Actors, isolation, reentrancy, @MainActor
- Continuations for bridging legacy APIs
- Swift 6 strict concurrency migration guide

### memory/
Swift 6.2 InlineArray and Span for low-level memory performance.
- InlineArray: fixed-size, stack-allocated collections with zero heap overhead
- Span family: safe, non-escapable access to contiguous memory
- Lifetime dependencies and non-escapable type constraints
- Performance guidance: when to use InlineArray/Span vs Array/UnsafePointer

## How to Use

1. Identify user's need from their question
2. Read relevant module files from subdirectories
3. Apply the guidance to their specific context
4. Cross-reference with platform-specific skills (ios/, macos/) as needed
