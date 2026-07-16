# Concurrency Runtime Internals and Profiling

How Swift concurrency actually executes — the cooperative thread pool, the forward-progress contract, actor scheduling, and the Swift Concurrency Instrument workflow for diagnosing main-actor blocking, actor contention, and thread-pool exhaustion. Distilled from Apple's WWDC21 "Swift concurrency: Behind the scenes" (10254), WWDC22 "Visualize and optimize Swift concurrency" (110350), and WWDC23 "What's new in Swift" (10164).

## The Runtime Contract: Forward Progress

The entire cooperative pool design depends on one invariant (WWDC21 10254): **threads must always be able to make forward progress**. `await` does not block a thread — it suspends the *task* and frees the thread for other work. Code that *blocks* a cooperative-pool thread (GCD `sync`, semaphores, long-held locks) violates the contract the runtime is built on.

- "Swift makes no guarantee that the thread which executed the code before the await is the same thread which will pick up the continuation… await is an explicit point in your code which indicates that atomicity is broken since the task may be voluntarily descheduled."
- Any code assuming thread locality — thread-local storage, run-loop affinity, `Thread.current` checks — must be revisited: none of it survives an `await`.

## Cooperative Thread Pool vs GCD

The pool spawns **only as many threads as there are CPU cores** — never more.

**Thread explosion** is the GCD failure mode this replaces. Apple's numbers: on a six-core iPhone, 100 feed-update work items each blocking on a serial `databaseQueue.sync` left the phone "overcommitted with 16 times more threads than cores." Each blocked thread holds a stack and kernel data structures, may hold locks, and with hundreds of threads timesharing a few cores, "scheduling latencies outweigh useful work."

```swift
// ❌ GCD: 100 completion handlers each block a thread on a serial queue → thread explosion
let dataTask = urlSession.dataTask(with: feed.url) { data, _, _ in
    let articles = try! deserializeArticles(from: data!)
    databaseQueue.sync {                    // blocks this thread; GCD spawns more
        updateDatabase(with: articles, for: feed)
    }
}

// ✅ Swift concurrency: awaits suspend instead of block; pool stays at core count
await withThrowingTaskGroup(of: [Article].self) { group in
    for feed in feedsToUpdate {
        group.addTask {
            let (data, _) = try await URLSession.shared.data(from: feed.url)
            let articles = try deserializeArticles(from: data)
            try await updateDatabase(with: articles, for: feed)  // suspends, no block
            return articles
        }
    }
}
```

Pool size scales with hardware — "for smaller devices like a watch, there might only be one or two threads in the pool" (WWDC25 268). Never design assuming a particular thread count.

## How Async Functions Execute

- State that must survive a suspension lives in **async frames on the heap**; state used only between suspension points lives in ordinary stack frames (WWDC21 10254).
- Each async function is split into **partial functions** at suspension points. At most one partial function is on the C stack at a time; on suspension it simply returns to the runtime and the thread is immediately reusable (WWDC24 10217).
- Async frames are allocated from **task-owned slabs** with stack discipline — "typically significantly faster than malloc." Net cost model: async ≈ sync "just with a bit higher overhead for calls" (WWDC24 10217).
- The runtime tracks real dependencies — continuation on callee, parent on children, actor work-item ordering — which is what lets it keep threads busy without blocking (WWDC21 10254).

## Unsafe Primitives: The Explicit Rules

From WWDC21 10254, verbatim doctrine:

| Primitive | Verdict | Why |
|---|---|---|
| `DispatchSemaphore`, condition variables | ❌ **Unsafe with Swift concurrency, always** | "They hide dependency information from the Swift runtime, but introduce a dependency in execution" |
| Semaphore to make a `Task` synchronous | ❌ **Never** | "A thread can block indefinitely against the semaphore… This violates the runtime contract of forward progress" |
| `os_unfair_lock`, `NSLock` in synchronous code | ⚠️ Safe **only** around a tight, well-known critical section | The thread holding the lock can always make progress toward releasing it |
| Any lock held across an `await` | ❌ Never | The resuming thread may differ from the locking thread; the pool can deadlock |

```swift
// ❌ Never: blocks a cooperative-pool thread on work the pool may never get to schedule
let sem = DispatchSemaphore(value: 0)
Task { await doWork(); sem.signal() }
sem.wait()   // can deadlock the entire pool
```

**Debug enforcement**: run with the environment variable `LIBDISPATCH_COOPERATIVE_POOL_STRICT=1` (scheme → Run → Arguments) — a modified debug runtime that enforces forward progress, so a hung pool thread points directly at an unsafe blocking primitive (WWDC21 10254).

## Actor Scheduling: Not FIFO

- Actors schedule by priority, not FIFO like serial dispatch queues — do not port order-dependent DispatchQueue code onto an actor expecting FIFO.
- **Actor hopping is cheap when uncontended**: the same pool thread hops from one actor to the next — no blocking, no new thread. Contended, the work item queues on the target actor and the caller suspends.
- **MainActor hopping is not cheap**: the main thread is disjoint from the cooperative pool, so each hop is a real context switch. Batch main-actor work:

```swift
// ❌ 2 context switches per loop iteration
@MainActor func updateArticles(for ids: [ID]) async throws {
    for id in ids {
        let article = try await database.loadArticle(with: id)  // hop off main
        updateUI(for: article)                                  // hop back
    }
}

// ✅ 2 context switches total — batch the load
@MainActor func updateArticles(for ids: [ID]) async throws {
    let articles = try await database.loadArticles(with: ids)
    updateUI(for: articles)
}
```

## Task Creation Cost

Don't spawn tasks for trivial work: for a child task that just reads `UserDefaults`, "the useful work done by the child task is diminished by the cost of creating and managing the task" (WWDC21 10254). Introduce concurrency only where its benefit outweighs its management cost — and profile with Instruments as you adopt it.

## The Swift Concurrency Instrument (Instruments 14+)

Cmd-I from Xcode → **Swift Concurrency** template. Two instruments: **Swift Tasks** and **Swift Actors** (WWDC22 110350).

**Top-level statistics lanes**: Running Tasks (executing simultaneously), Alive Tasks (at a point in time), Total Tasks (cumulative created). First diagnostic read from Apple's demo: "For most of the time, only one Task is running. This tells us part of the problem is that all of our work is being forced to serialize."

**Detail views**: Task Forest (parent-child structured-concurrency tree), Task Summary (time per task state), Narrative view (per-task story — "if it's waiting on a Task, it will inform you which Task you are waiting on"). Right-click a task to **pin a Task track** (also pins child tasks, threads, or actors); a pinned track shows the state timeline, the task-creation backtrace, and the narrative.

**Task states to read**: Running, **Enqueued** (waiting for actor access), Suspended, Waiting on a continuation.

### Diagnosis 1 — main actor blocking

Symptom: hang; the narrative shows the task "ran on a background thread for a short amount of time, and then ran on the Main Thread for a long time." Apple's demo cause: a `@MainActor class … : ObservableObject` (forced there by `@Published`) contained CPU-heavy compression.

Rule: "Code running on the main Actor must finish quickly, and either complete its work or move computation off of the main Actor and into the background."

✅ Fix: split state by isolation need — `@Published` UI state stays on the `@MainActor` type; the heavy work and its bookkeeping move to a separate `actor`.

### Diagnosis 2 — actor contention

Symptom: UI responsive but no parallel speedup; "Task Summary view shows us that our concurrency code is spending an alarming amount of time in the **Enqueued** state. This means we have a lot of Tasks waiting to get exclusive access to an Actor."

✅ Fix, two parts (WWDC22 110350):
1. Make the hot function `nonisolated func compressFile(url: URL) async -> Data` — it leaves the actor and runs freely on the pool, hopping back (`await log(…)`) only to touch actor state.
2. Create the work with `Task.detached` "to ensure the Task does not inherit the Actor-context that it was created in" — the original bug was plain `Task {}` inside a `@MainActor` type, so every task started on the main actor.

Result: "the compress function can be executed freely, on any thread in the thread pool, until it needs to access Actor-protected state." Verify in Swift Actors: work intervals short, "the queue size never gets out of hand." Success criteria are qualitative: Running Tasks > 1, responsive UI, small actor queues.

### Diagnosis 3 — continuation leaks

A continuation never resumed leaves its task stuck indefinitely in the **continuation** state in the instrument, and "a message is printed to the console when the continuation is destroyed warning you that the continuation leaked." Prefer `withCheckedContinuation` — see `continuations-bridging.md`.

## Custom Actor Executors (Swift 5.9)

An actor can supply its own serialization mechanism — the key migration tool when existing code (or Obj-C/C++ sharing the queue) already synchronizes on a `DispatchSerialQueue` (WWDC23 10164):

```swift
actor MyConnection {
    private let queue: DispatchSerialQueue

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        queue.asUnownedSerialExecutor()
    }
}
```

"All of the synchronization for our actor instances will happen through that queue" — an actor call becomes a dispatch onto it, while Swift still guarantees mutually-exclusive access to the actor's storage. `DispatchSerialQueue` conforms to `SerialExecutor`; `isSameExclusiveExecutionContext(other:)` supports "are we on the main thread?"-style assertions.

## Checklist

- [ ] No semaphores or condition variables anywhere in Swift-concurrency code paths
- [ ] Locks (`NSLock`, `os_unfair_lock`) only around tight synchronous critical sections, never across `await`
- [ ] No thread-locality assumptions (TLS, run loops, `Thread.current`) across suspension points
- [ ] Main-actor round trips batched, not per-element in loops
- [ ] No tasks spawned for trivial work — task management cost considered
- [ ] Hangs profiled with the Swift Concurrency Instrument: check Enqueued time (contention) and long main-thread intervals (blocking)
- [ ] `LIBDISPATCH_COOPERATIVE_POOL_STRICT=1` used in debug when hunting blocked pool threads
- [ ] Legacy serial-queue synchronization bridged with a custom actor executor rather than duplicated

## References

- [WWDC21 — Swift concurrency: Behind the scenes](https://developer.apple.com/videos/play/wwdc2021/10254/)
- [WWDC22 — Visualize and optimize Swift concurrency](https://developer.apple.com/videos/play/wwdc2022/110350/)
- [WWDC23 — What's new in Swift (custom actor executors)](https://developer.apple.com/videos/play/wwdc2023/10164/)
