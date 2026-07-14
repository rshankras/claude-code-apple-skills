# Foundation Models Utilities (the open-source package)

Apple ships a companion Swift package — **`apple/foundation-models-utilities`** — that adds three things the framework itself leaves to you: a client for OpenAI-compatible endpoints, just-in-time **Skills**, and ready-made **history-compression** modifiers. It exists to move faster than the OS: Apple describes it as *emerging and experimental patterns*, and it updates **between** OS releases rather than at WWDC cadence.

Treat it accordingly — it's a proving ground, not a frozen API. Pin a commit if you need stability.

```swift
// Package.swift
.package(url: "https://github.com/apple/foundation-models-utilities", branch: "main")
```

Requires **iOS / macOS / visionOS / watchOS 27** (no tvOS); also builds on Linux. At the time of writing the repo has **no tagged releases**, so a `from: "1.0.0"` requirement — which its own README suggests — will not resolve. Depend on a branch or a revision.

## When to reach for it

| You want to… | Use |
|---|---|
| Run against a local or hosted OpenAI-compatible model through `LanguageModelSession` | `ChatCompletionsLanguageModel` |
| Load a big reference document into context **only when the model needs it** | `Skills` |
| Stop a long conversation from outgrowing the context window | `droppingCompletedToolCalls()` / `rollingWindow()` / `summarizeHistory()` |

---

## ChatCompletionsLanguageModel — any OpenAI-compatible endpoint

Conforms to `LanguageModel`, so it drops into a session exactly like `SystemLanguageModel`. Guided generation, tools, and streaming keep working — the endpoint just changes.

```swift
let model = ChatCompletionsLanguageModel(
    name: "qwen3-30b",                              // sent verbatim as the `model` field
    url: URL(string: "http://localhost:8000/v1")!,  // base URL — no /chat/completions suffix
    additionalHeaders: ["Authorization": "Bearer \(token)"],
    supportsGuidedGeneration: false                 // most local servers can't enforce a schema
)

let session = LanguageModelSession(model: model)
let response = try await session.respond(to: "Summarize this changelog.")
```

Under the hood it POSTs a streaming request, walks the transcript into `system`/`user`/`assistant`/`tool` messages, forwards `temperature` and `max_completion_tokens`, maps `toolCallingMode` onto `tool_choice`, and parses the SSE stream back into transcript entries.

**Pitfalls**

- ❌ **`supportsGuidedGeneration` defaults to `true`.** Against a server that ignores `response_format`, a `respond(to:generating:)` call will *not* fail — it will hand back free-form text where you expected a decoded `@Generable`. Set it to `false` explicitly for local servers; then the framework throws `unsupportedCapability` instead of lying to you.
- ❌ **`additionalHeaders` replaces, it doesn't merge per-header.** Setting `Content-Type` or `User-Agent` clobbers the package's default for that header. In practice you only want to *add* `Authorization`.
- ⚠️ **Base-URL rule:** if the URL already contains a `v1` path component the client appends `/chat/completions`; otherwise it appends `/v1/chat/completions`. Pass the base, never the full path.
- Custom segments aren't supported — this executor throws `unsupportedTranscriptContent` for them.

---

## Skills — load context only when the model asks for it

A `Skill` is a named, described block of guidance. Until the model activates it (**by issuing a tool call**), only its *name* and *description* sit in the prompt — the body stays out. That keeps the prompt small and time-to-first-token low, and it's the framework-blessed answer to "I have a 4,000-word style guide but only need it on some turns."

```swift
@Observable final class Assistant {
    let activations = SkillActivations()   // one per session — never recreate per render
}

struct ReviewProfile: LanguageModelSession.DynamicProfile {
    let assistant: Assistant

    var body: some DynamicProfile {
        Profile {
            Instructions("You review pull requests for an iOS team.")

            Skills(activations: assistant.activations) {
                Skill(
                    name: "swift-style",
                    description: "The team's Swift style rules — apply when reviewing Swift",
                    prompt: swiftStyleGuideMarkdown          // big; only when needed
                )
                Skill(
                    name: "release-tone",
                    description: "House tone for release notes",
                    instructions: "Write release notes in second person, present tense.",
                    allowsDeactivation: true                 // model may unload it later
                )
            }
        }
    }
}
```

### The two flavors, and why the choice is a cache decision

This is the part worth internalizing, because it's the practical application of the KV-cache rule in `models-and-agents.md`: **appending preserves the cache; rewriting the prefix invalidates it.**

| Flavor | Where the body lands | KV cache | Model's obedience |
|---|---|---|---|
| `prompt:` | Returned as the **tool output** of the activation call — an *append* | ✅ Preserved | Normal — it's context, not instruction |
| `instructions:` | Spliced into the **existing instructions entry** at the top of the transcript | ❌ Invalidated for the whole conversation | Higher — models are trained to weight instructions |

✅ **Prefer `prompt:`** for anything large or single-turn — style guides, reference docs, retrieved passages. You pay nothing in cache.

✅ **Reach for `instructions:`** only when the guidance is short and must bind across many turns, and you accept re-processing the prefix.

`allowsDeactivation: true` (instructions-only) lets the model issue a second tool call to *unload* the skill and restore the original instructions. Pair it with `droppingCompletedToolCalls()` to evict the activation/deactivation pair too, and the context is genuinely reclaimed rather than merely ignored.

### `SkillActivations`

`Sendable`, observable, and mutation-safe across actors. It exposes `activeSkillNames` and `isActive(_:)`, plus `activate(_:)` / `deactivate(_:)` for restoring state from disk or writing tests — in normal use the synthesized tool drives it. Because it's observable, SwiftUI can show the user which skills the model pulled in.

❌ **Don't recreate it per render.** It's a reference type holding live state; hold one on your `@Observable` model, or you lose activations and break observation.

> ⚠️ Older docs describe `SkillActivations` as conforming to `RandomAccessCollection`. That conformance was **removed**; iterate `activeSkillNames` instead.

---

## History — keeping the transcript inside the context window

Three `DynamicProfile` modifiers. They rewrite `history` before each generation.

```swift
Profile { Instructions("…") }
    .summarizeHistory(entryThreshold: 50)   // heaviest — innermost, runs last
    .rollingWindow(entries: 20)
    .droppingCompletedToolCalls()           // cheapest — outermost, runs FIRST
```

⚠️ **Modifiers apply outside-in, so source order is the reverse of execution order.** The last one you write runs first. Put the cheap compression outermost so the expensive one sees an already-smaller transcript.

| Modifier | What it does |
|---|---|
| `droppingCompletedToolCalls()` | Drops every tool-call/tool-output pair except the most recent. Cheap, lossless-ish, and the natural partner to deactivatable skills. |
| `rollingWindow(entries:)` | Hard cap — keeps the last *N* entries. Predictable and free. |
| `summarizeHistory(entryThreshold:model:instructions:summaryPostamble:)` | Once the transcript exceeds the threshold, runs a **second session** to compress the prior conversation into one summary entry. |

**`summarizeHistory` footguns** — none of these are obvious, and all of them bite:

- ❌ **`entryThreshold` counts entries, not tokens.** A chat with few but enormous entries may never trip it. Apple's own README implies a token threshold; the code does not. Add a `rollingWindow` as a size-bounded backstop.
- ❌ **It's a silent no-op unless the trailing entry is a `.prompt`.** It will not fire mid-tool-call. Don't rely on it as your only defense against overflow.
- ⚠️ **Once the threshold trips, the summarizer runs on every prompt** — a whole extra model round-trip on the user-facing critical path. Give it a small, fast `model:`; it defaults to `SystemLanguageModel()`.
- The default `summaryPostamble` exists to stop the downstream model leaking *"Based on the summary provided…"* into its answers. If you override it, keep that instruction or the seam becomes visible to users.

## Checklist

- [ ] Package pinned to a branch/revision — there are no tagged releases
- [ ] `supportsGuidedGeneration: false` set for any server that doesn't enforce a schema
- [ ] `Authorization` added via `additionalHeaders`; no API key hardcoded in the binary (see `models-and-agents.md`)
- [ ] Large or single-turn skill bodies use `prompt:` (cache-preserving), not `instructions:`
- [ ] One `SkillActivations` per session, held on an `@Observable` model
- [ ] History modifiers ordered with the cheapest outermost
- [ ] `summarizeHistory` backed by a `rollingWindow` — entry-count thresholds don't bound tokens
- [ ] Transcript strategy profiled with the Foundation Models Instrument (it flags cache invalidations)

## References

- [apple/foundation-models-utilities](https://github.com/apple/foundation-models-utilities) — the package (Apache-2.0)
- [WWDC26 — Build agentic app experiences with the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2026/242/)
- [Foundation Models framework](https://developer.apple.com/documentation/foundationmodels)
