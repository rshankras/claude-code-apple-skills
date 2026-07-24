---
name: swift-development
description: Swift language patterns and best practices including concurrency, performance, and modern idioms. Use for Swift language-level code review or architecture guidance.
allowed-tools: [Read, Glob, Grep]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
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
- Wants complexity/size limits (SwiftLint thresholds) on agent-written code

## Available Modules

### concurrency-patterns/
Swift concurrency architecture and patterns.
- Swift 6.2 approachable concurrency features (incl. `nonisolated(nonsending)`, Apple's adoption doctrine)
- Structured concurrency (async let, TaskGroup, .task modifier, task-local values)
- Actors, isolation, reentrancy, @MainActor, Sendable
- Runtime internals + profiling (cooperative pool, unsafe primitives, Swift Concurrency Instrument)
- Continuations for bridging legacy APIs
- Swift 6 strict concurrency migration guide

### concurrency/
Swift 6.2 concurrency **updates** reference — the what-changed view (async-stays-on-caller, default MainActor inference, isolated conformances, @concurrent) with migration steps from 6.0/6.1 and top mistakes. Overlaps `concurrency-patterns/swift62-concurrency.md` by design: use this file when the question is "what changed in 6.2?", use concurrency-patterns when building or reviewing async code.

### code-size/
Complexity and size limits for Swift code — SwiftLint threshold rules (cyclomatic complexity, function/type/file length, parameter count) with a violations-baseline adoption path so existing code never blocks. Part of the deterministic gauntlet with `testing/fitness-functions` and `testing/coverage-ratchet`.

### memory/
InlineArray, Span, and the Swift performance cost model.
- InlineArray: fixed-size, stack-allocated collections with zero heap overhead
- Span family: safe, non-escapable access to contiguous memory (+ OutputRawSpan, swift-binary-parsing)
- Lifetime dependencies and non-escapable type constraints
- `swift-performance.md`: the cost model — allocation, ARC/retain-release, exclusivity checks, dispatch, generics vs existentials, closures, `~Copyable` ownership

## How to Use

1. Identify user's need from their question
2. Read relevant module files from subdirectories
3. Apply the guidance to their specific context
4. Cross-reference with platform-specific skills (ios/, macos/) as needed
