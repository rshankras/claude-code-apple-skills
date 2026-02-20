---
name: concurrency-patterns
description: Swift concurrency patterns including Swift 6.2 approachable concurrency, structured concurrency, actors, continuations, and migration. Use when reviewing or building async code, fixing data race errors, or migrating to Swift 6.
allowed-tools: [Read, Glob, Grep]
---

# Swift Concurrency Patterns

Comprehensive guide for Swift concurrency covering async/await, structured concurrency, actors, and the Swift 6.2 "Approachable Concurrency" features. Focuses on patterns that prevent data races and common mistakes that cause crashes.

## When This Skill Activates

- User has data race errors or actor isolation compiler errors
- User is migrating to Swift 6 strict concurrency
- User asks about async/await, actors, Sendable, TaskGroup, or MainActor
- User needs to bridge legacy completion-handler APIs to async/await
- User is working with Swift 6.2 features (@concurrent, isolated conformances)
- User has concurrency bugs (actor reentrancy, task cancellation, UI freezes)

## Decision Tree

```
What concurrency problem are you solving?
│
├─ Swift 6 compiler errors / migration
│  └─ migration-guide.md
│
├─ Swift 6.2 new features (@concurrent, isolated conformances)
│  └─ swift62-concurrency.md
│
├─ Running work in parallel (async let, TaskGroup)
│  └─ structured-concurrency.md
│
├─ Thread safety for shared mutable state
│  └─ actors-and-isolation.md
│
├─ Bridging old APIs (delegates, callbacks) to async/await
│  └─ continuations-bridging.md
│
└─ General async/await patterns
   └─ See macos/coding-best-practices/modern-concurrency.md for basics
```

## Quick Reference

| Pattern | When to Use | Reference |
|---------|-------------|-----------|
| `async let` | Fixed number of parallel operations | `structured-concurrency.md` |
| `withTaskGroup` | Dynamic number of parallel operations | `structured-concurrency.md` |
| `withDiscardingTaskGroup` | Fire-and-forget parallel operations | `structured-concurrency.md` |
| `.task { }` modifier | Load data when view appears | `structured-concurrency.md` |
| `.task(id:)` modifier | Re-load when a value changes | `structured-concurrency.md` |
| `actor` | Shared mutable state protection | `actors-and-isolation.md` |
| `@MainActor` | UI-bound state and updates | `actors-and-isolation.md` |
| `@concurrent` | Explicitly offload to background (6.2) | `swift62-concurrency.md` |
| Isolated conformances | `@MainActor` type conforming to protocol (6.2) | `swift62-concurrency.md` |
| `withCheckedContinuation` | Bridge callback API to async | `continuations-bridging.md` |
| `AsyncStream` | Bridge delegate/notification API to async sequence | `continuations-bridging.md` |
| Strict concurrency migration | Incremental Swift 6 adoption | `migration-guide.md` |

## Process

### 1. Identify the Problem

Read the user's code or error messages to determine:
- Is this a compiler error (strict concurrency) or a runtime issue (data race, crash)?
- What Swift version and concurrency checking level are they using?
- Are they migrating existing code or writing new code?

### 2. Load Relevant Reference Files

Based on the problem, read from this directory:
- `swift62-concurrency.md` — Swift 6.2 approachable concurrency features
- `structured-concurrency.md` — async let, TaskGroup, .task modifier lifecycle
- `actors-and-isolation.md` — Actor patterns, reentrancy, @MainActor, Sendable
- `continuations-bridging.md` — withCheckedContinuation, AsyncStream, legacy bridging
- `migration-guide.md` — Incremental Swift 6 strict concurrency adoption

### 3. Review Checklist

- [ ] No blocking calls on `@MainActor` (use `await` for long operations)
- [ ] Shared mutable state protected by an actor (not locks or DispatchQueue)
- [ ] `Sendable` conformance correct for types crossing isolation boundaries
- [ ] Task cancellation handled (check `Task.isCancelled` or `Task.checkCancellation()`)
- [ ] No unstructured `Task {}` where structured concurrency (`.task`, `TaskGroup`) would work
- [ ] Actor reentrancy considered at suspension points
- [ ] `withCheckedContinuation` called exactly once (not zero, not twice)
- [ ] `.task(id:)` used instead of manual `onChange` + cancel patterns

### 4. Cross-Reference

- For **async/await basics and actor fundamentals**, see `macos/coding-best-practices/modern-concurrency.md`
- For **networking concurrency patterns**, see `generators/networking-layer/networking-patterns.md`
- For **SwiftData concurrency** (@ModelActor), see `macos/swiftdata-architecture/repository-pattern.md`
- For **auth token refresh with actors**, see `generators/auth-flow/auth-patterns.md`

## References

- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Migrating to Swift 6](https://www.swift.org/migration/documentation/migrationguide/)
- Apple doc: `/Users/ravishankar/Downloads/docs/Swift-Concurrency-Updates.md`
