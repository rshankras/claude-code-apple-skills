# Prompt Design, Safety & Guardrails

What the on-device model can and can't do, how to design prompts for it, and the four-layer safety architecture. Distilled from Apple's WWDC25 "Explore prompt design & safety for on-device foundation models" (248), "Meet the Foundation Models framework" (286), and "Deep dive into the Foundation Models framework" (301).

## Know the Model's Limits (WWDC25 248/286)

The on-device model is **~3 billion parameters, quantized to 2 bits** — device-scale, not server-scale. "It's not designed for world knowledge or advanced reasoning."

| Task | Verdict | Apple's rule |
|---|---|---|
| Summarization, extraction, classification, tagging, text revision, multi-turn chat | ✅ Designed for these | Break bigger tasks into these pieces |
| Complex reasoning | ⚠️ | "Try breaking down your task prompt into simpler steps" |
| Math | ❌ | "Avoid asking this small model to act as a calculator. Non-AI code is much more reliable for math" |
| Code generation | ❌ | "The system model is not optimized for code" |
| Facts / world knowledge | ❌ | "Avoid relying on the system language model for facts… consider providing the model with verified information written into your prompt," then fact-check outputs |

Hallucination stakes rule: where facts are critical (user instructions), don't risk it; low-stakes creative output (game NPC dialogue) tolerates errors.

## Prompt Design Rules (WWDC25 248)

- **One specific task per prompt**, phrased as a clear command. ❌ multi-task mega-prompts.
- **Control length by asking**: "in three sentences", "in a few words" to shorten; "in detail" to lengthen.
- **Role prompting works**: "You are a fox who speaks Shakespearean English."
- **Few-shot**: fewer than 5 inline examples of the outputs you want.
- **Suppress behavior with an all-caps command**: the model "will respond well to an all caps command: 'DO NOT' — kind of like talking to it in a stern voice."
- Iterate in Xcode's `#Playground` macro — responses render in the canvas like a SwiftUI preview, with access to your project's types.

## Instructions vs Prompts: The Trust Hierarchy

"The model is trained to obey **instructions over prompts**. This helps protect against prompt injection attacks, but is by no means bulletproof" (WWDC25 286).

- Instructions come from **you**; prompts may come from the user.
- **Hard rule (verbatim)**: "make sure the instructions only come from you and never include untrusted content or user input. Instead, you can include user input in your prompts."
- Instructions persist for all subsequent prompts in the session — put safety phrasing there (e.g. "Respond to negative prompts in an empathetic and wholesome way").

### User-input patterns, safest → riskiest

1. ✅ **Built-in prompt list** the user picks from — full control, curated prompts that shine.
2. ⚠️ **Your prompt template + user input** (`"Generate a story about: \(userInput)"`) — "a good way to reduce risks without sacrificing flexibility."
3. ❌ **Raw user input as the whole prompt** (chatbot) — when unavoidable, instruct the model "to handle a wide range of user input with care."

## Guardrails (WWDC25 248)

- Apple-trained guardrails apply to **both input and output**: "Your instructions, prompts, and tool calls are all considered inputs… harmful model outputs are blocked, even if the prompts were crafted to bypass input guardrails."
- Violations throw `LanguageModelError.guardrailViolation` (iOS 27; was `LanguageModelSession.GenerationError.guardrailViolation`, deprecated — see the migration table in `SKILL.md`). Handle by feature type:
  - **Proactive feature** (not user-initiated): "simply ignore the error and not interrupt the UI."
  - **User-initiated feature**: explain the app can't process the request (alert) and offer alternatives (Image Playground offers undoing the offending prompt).
- Guardrail false positives were reduced in the iOS 26.4 model update and refined again in the iOS 27 wave (WWDC26 241).

### A guardrail block is not the only way the model says no

`LanguageModelError.refusal` is a **separate, non-safety decline** — the model chose not to answer (out of scope, won't speculate), and nothing was flagged as harmful. It carries an `explanation` (and an `explanationStream`).

Treat the two differently. A guardrail violation is a safety event: say little, offer an alternative, never echo the offending content back. A refusal is an ordinary conversational outcome: it's safe to surface `explanation` to the user, and the fix is usually a better prompt, not a safer one.

❌ Don't fold `refusal` into your `guardrailViolation` branch — you'll show a scary safety message for a mundane "I don't have enough information to answer that."

## The Swiss-Cheese Safety Stack (WWDC25 248)

A safety problem should require **all** layers to fail — "like a stack of Swiss cheese slices."

1. Apple's built-in guardrails (input + output)
2. Safety wording in your **instructions** (obeyed over prompts)
3. App design controlling **how user input enters prompts** (ladder above)
4. **Use-case-specific mitigations** — yours: deny lists of keywords, extra instructions avoiding controversial topics, UI-level warnings (recipe generator → allergen warning / dietary-restriction filters), or a trained classifier for robustness

"Ultimately, **you are responsible** for applying mitigations for your own use case."

## Evaluation & Red-Teaming (WWDC25 248)

- Curate prompt datasets for **quality and safety** — include prompts that may trigger safety issues.
- Automate end-to-end runs (a CLI or UI-tester app); inspect small sets manually, use **LLM-as-judge** grading at scale.
- "Don't forget to test the **unhappy path**" — verify app behavior under safety errors.
- Re-run evals when you change prompts **and when Apple updates the model**; greedy sampling is only deterministic per model version. WWDC26 adds a dedicated Swift **Evaluations framework** for exactly this (see `models-and-agents.md`).
- Report safety issues via Feedback Assistant; `LanguageModelFeedbackAttachment(input:output:sentiment:issues:desiredOutputExamples:)` structures the report.

## Language Support

Pre-check the locale rather than only catching the error (WWDC25 301):

```swift
let supportedLanguages = SystemLanguageModel.default.supportedLanguages
guard supportedLanguages.contains(Locale.current.language) else {
    // show unsupported-language disclaimer
    return
}
// …and still catch LanguageModelError.unsupportedLanguageOrLocale
```

## Apple's Closing Safety Checklist (WWDC25 248, verbatim order)

1. Handle guardrail errors when prompting the model.
2. Safety should be part of your instructions.
3. When including user input in prompts, balance flexibility vs safety.
4. Anticipate impact when people act on generated content; apply use-case-specific mitigations.
5. Invest in evaluation and testing.
6. Report safety issues via Feedback Assistant.

## References

- [WWDC25 — Explore prompt design & safety for on-device foundation models](https://developer.apple.com/videos/play/wwdc2025/248/)
- [Improving the safety of generative model output](https://developer.apple.com/documentation/FoundationModels/improving-the-safety-of-generative-model-output)
- [HIG: Generative AI](https://developer.apple.com/design/human-interface-guidelines/generative-ai)
