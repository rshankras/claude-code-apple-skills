# Model Landscape & Agentic Sessions (iOS 27 Wave)

The WWDC26 layer of the Foundation Models framework: Private Cloud Compute, the `LanguageModel` protocol, vision input, built-in tools, and the `DynamicProfile` agentic primitives. Distilled from Apple's WWDC26 "What's new in the Foundation Models framework" (241) and "Build agentic app experiences with the Foundation Models framework" (242).

## The Model Landscape (WWDC26 241)

| Model | Context | Traits |
|---|---|---|
| `SystemLanguageModel` (on-device, rebuilt for iOS 27) | **8,192 tokens** (`model.contextSize`) | Better logic + tool calling; gains **image input**; private, offline, free |
| `PrivateCloudComputeLanguageModel` | **32,000 tokens** | **Reasoning model** (`ContextOptions(reasoningLevel: .light/.deep)`); no account/auth/API keys; prompts never stored; free below **2M first-time downloads** (users get a daily allowance, higher with iCloud+); brings FM to **watchOS 27** |
| `CoreAILanguageModel` / `MLXLanguageModel` (open source) | varies | Run arbitrary local models on ANE / Mac GPU |
| Anthropic / Google Swift packages; Chat-Completions model (utilities package) | varies | Frontier server models as drop-in `LanguageModel` conformers — you handle auth + billing |

- The **`LanguageModel` protocol** abstracts the backend: pass any conformer to `LanguageModelSession` and "everything downstream stays the same" — guided generation, tools, streaming all work.
- ❌ Never ship private API keys in the binary; ✅ fetch tokens via OAuth-style flows and store in the **Keychain** (Apple's explicit warning for third-party models).
- Choose per-feature models by **privacy boundaries, capabilities, and cost** — e.g. brainstorming on PCC (creativity, breadth), quick review passes on-device (no server cost).
- Token accounting for billing/budgets: `response.usage.input.totalTokenCount` / `.cachedTokenCount`, `.output.totalTokenCount` / `.reasoningTokenCount`.
- Sizing APIs (shipped iOS 26.4): `model.contextSize`, `try await model.tokenCount(for: "…")`.
- The FM core framework is going **open source** (usable wherever Swift runs, incl. Linux); the **Foundation Models framework utilities** package updates *between* OS releases. Also new: the `fm` CLI in macOS 27 (`fm chat`, pipeable in scripts) and a Python SDK (`apple_fm_sdk`).

## Vision Input (WWDC26 241)

The on-device model accepts images inline in prompt builders:

```swift
let response = try await session.respond {
    "What animal is this?"
    Attachment(UIImage(named: "photo")!)
}
```

`Attachment` accepts `UIImage`, `NSImage`, `CGImage`, Core Image types, CoreVideo pixel buffers, and file URLs. Any size/aspect ratio works — but **larger images cost more tokens and latency**; downscale when responsiveness matters.

## Built-In System Tools (WWDC26 241)

Attach like any custom `Tool`: **`BarcodeReaderTool`** and **`OCRTool`** (Vision-backed), and a **Spotlight search tool** — fully local RAG over a Spotlight index for up-to-date personal/domain knowledge.

## DynamicProfile: Declarative Agent Configuration (WWDC26 241/242)

A **`Profile`** = instructions + tools + modifiers (`.model()`, `.temperature`, `.samplingMode`, `.reasoningLevel()`); "each Profile is an agent." A `DynamicProfile`'s `body` is **re-evaluated on every prompt**, resolving to **exactly one active Profile at a time** — drive it from an `@Observable` orchestrator:

```swift
struct CraftProfile: LanguageModelSession.DynamicProfile {
    let states: CraftProjectStates
    var body: some DynamicProfile {
        switch states.mode {
        case .craftAnalysis:
            Profile {
                Instructions { "You are an expert crafting assistant…" }
                RecordImageAnalysisTool()
                SwitchModeTool(states: states)   // a tool can flip the mode itself
            }
        case .brainstorm:
            Profile {
                Instructions { "Brainstorm some ideas…" }
                BrainstormRecordTool()
            }
            .model(states.privateCloudCompute)   // per-profile model override
            .reasoningLevel(.deep)
        }
    }
}
let session = LanguageModelSession(profile: CraftProfile())
```

This replaces the old pattern of one session per mode plus manual transcript surgery. **`DynamicInstructions`** are composable instruction+tool bundles — nesting concatenates them; custom `DynamicProfileModifier`s package reusable behavior.

## Orchestration Patterns (WWDC26 242)

| Pattern | Shape | Who answers | Use when |
|---|---|---|---|
| **Baton-pass** | Profiles share the full transcript; a tool flips the active-profile state (`.onToolCall { orchestrator.mode = .tutorial }`) | Whoever holds the baton | Shared context + handoff of authorship |
| **Phone-a-friend** | A tool spawns an isolated child `LanguageModelSession` with its own profile/transcript, returns the answer as tool output | Always the parent | Isolated sub-task whose result feeds back |
| **Skills** (utilities package) | `Skill(name:description:prompt:)` payloads loaded into context only when activated | The single profile | Procedural context loading — big reference text on demand |

## Tool-Calling Mode (WWDC26 242)

`ToolCallingMode` — profile modifier `.toolCallingMode(_)` or per-request `GenerationOptions(toolCallingMode:)`: `.allowed` (default), `.disallowed` (tools known irrelevant now), `.required` (agentic systems where every action is a tool call).

❌ **`.required` with no exit condition is an infinite loop** — the model calls tools forever. Two sanctioned exits:

```swift
// Exit 1: conditionalize the mode — flip off once the needed tool fired
Profile { Instructions("Answer questions about origami"); QueryOrigamiDatabaseTool() }
    .toolCallingMode(state.queriedDatabase ? .disallowed : .required)
    .onToolCall { state.queriedDatabase = true }

// Exit 2: a final-answer tool that THROWS — throwing aborts the tool loop
struct FinalAnswerTool: Tool {
    var output: String?
    @Generable struct Arguments { var answer: String }
    func call(arguments: Arguments) async throws -> Never {
        output = arguments.answer
        throw CancellationError()
    }
}
```

## Context Management: historyTransform vs history (WWDC26 242)

The transcript *is* the model's context; different backends have different limits (8,192 on-device vs 32,000 PCC), so routing between models may require trimming — and moving to a less-private model may require **redacting**.

| Mechanism | Nature | Rule |
|---|---|---|
| `historyTransform` (profile modifier) | Stateless, **lossless**, per-request, applied just before prompting; never mutates the stored transcript | ✅ **Prefer** for profile-targeted transformations (e.g. drop tool-call entries only for the on-device profile) |
| `history` session property | Stateful window; mutations are **lossy and visible to all profiles** | Use for real, permanent context reclamation (summarize-and-drop) |

- **Lifecycle modifiers** run imperative code at defined points; **`onResponse`** is the sanctioned clean point to summarize earlier entries and reclaim context; `onToolCall` powers baton-passing.
- **Session properties** (`@SessionPropertyEntry` macro in an `extension SessionPropertyValues`) are shared state visible to every tool and profile — mutable, initial value required. Pattern: `onResponse` writes a running summary; each profile injects it into its `Instructions` so context survives dropped entries.
- `session.transcript` is now **mutable** — but only while `isResponding == false` (mutating mid-response is a programmer error). `TranscriptErrorHandlingPolicy`: `.revertTranscript` (default — roll back on tool errors/cancellation) vs `.preserveTranscript` (resume-after-cancel flows; *you* must restore a good state).

## Performance & Accuracy Rules (WWDC26 242)

- **KV-cache rule**: *appending* to the transcript preserves the cache (fast time-to-first-token); **removing entries, changing tools, or changing instructions invalidates it**. Backends differ — "the only way to be certain is by measuring."
- The **Foundation Models Instrument** in Xcode was revamped and **detects cache invalidations** — profile the latency cost of your transcript strategy.
- ❌ **History rewriting can confuse the model about its own past behavior.** Apple's failure case: after adding a `generate_title` tool, the model saw older transcript entries where it had answered without the tool — and imitated them, skipping the tool. Mitigate with eval sets in the new **Evaluations framework** (Swift-native): "data-driven optimization is the only way to be confident."

## Checklist

- [ ] Model chosen per feature by privacy/capability/cost; on-device preferred where it suffices
- [ ] No API keys in the binary; third-party model tokens in the Keychain
- [ ] `model.contextSize` queried, never hardcoded; trimming strategy exists before switching models
- [ ] `.required` tool mode always has an exit (conditional mode flip or throwing final-answer tool)
- [ ] `historyTransform` for lossless per-profile trims; `history` mutations only for deliberate, permanent reclamation
- [ ] Transcript mutated only while `isResponding == false`
- [ ] Transcript strategy profiled with the Foundation Models Instrument (watch cache invalidations)
- [ ] Context-engineering changes validated with Evaluations-framework eval sets, not eyeballed
- [ ] Large images downscaled before `Attachment` when latency matters

## References

- [WWDC26 — What's new in the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2026/241/)
- [WWDC26 — Build agentic app experiences with the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2026/242/)
