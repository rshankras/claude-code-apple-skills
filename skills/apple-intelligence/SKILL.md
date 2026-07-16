---
name: apple-intelligence
description: Apple Intelligence skills for on-device AI features including Foundation Models, Visual Intelligence, App Intents, and intelligent assistants. Use when implementing AI-powered features.
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion]
last_verified: 2026-07-16
review_by: 2027-06-22
os_version: iOS 27 / macOS 27
---

# Apple Intelligence Skills

Skills for implementing Apple Intelligence features including on-device LLMs, visual recognition, App Intents integration, and intelligent assistants.

## When This Skill Activates

Use this skill when the user:
- Wants to add AI/LLM features to their app
- Needs on-device text generation or understanding
- Asks about Foundation Models or Apple Intelligence
- Wants to implement structured AI output
- Needs prompt engineering guidance
- Wants camera-based visual intelligence features
- Needs Siri, Shortcuts, or Spotlight integration via App Intents
- Wants to expose app actions or content to the system

## Available Skills

### foundation-models/
On-device LLM integration with prompt engineering best practices.
- Model availability checking
- Session management
- @Generable structured output (property-order + schema-injection rules)
- Tool calling patterns
- Snapshot streaming
- Prompt engineering techniques
- `safety-and-guardrails.md` — model limits, the instructions-over-prompts hierarchy, guardrail handling, the four-layer safety stack, evals
- `models-and-agents.md` — Private Cloud Compute, LanguageModel protocol (third-party backends), vision input, DynamicProfile agents, tool-calling modes, KV-cache rules

### visual-intelligence/
Integrate with iOS Visual Intelligence for camera-based search.
- IntentValueQuery implementation
- SemanticContentDescriptor handling
- AppEntity for searchable content
- Display representations
- Deep linking from results

### app-intents/
App Intents for Siri, Shortcuts, Spotlight, and Apple Intelligence.
- AppIntent protocol, parameters, perform()
- AppEntity and entity queries
- App Shortcuts with voice phrases
- IndexedEntity and Spotlight indexing
- Intent modes (background, foreground)
- Interactive snippets with SnippetIntent
- Visual intelligence integration
- Onscreen entities for Siri/ChatGPT
- Multiple choice API
- Swift package support

## Key Principles

### 1. Privacy First
- On-device processing by default; Private Cloud Compute extends capacity without storing prompts (no account/API keys — WWDC26 241)
- When routing to less-private backends, redact context first (see foundation-models/models-and-agents.md)

### 2. Graceful Degradation
- Always check model availability
- Provide fallback UI for unsupported devices
- Handle errors gracefully (incl. guardrail violations — silent for proactive features, explained for user-initiated)

### 3. Efficient Prompting
- Keep prompts focused and specific
- Use structured output when possible
- Respect context window limits — query `model.contextSize`, never hardcode (4,096 first-gen on-device; 8,192 iOS 27 on-device; 32,000 Private Cloud Compute)

## Reference Documentation

- [Foundation Models](https://developer.apple.com/documentation/foundationmodels)
- [Visual Intelligence](https://developer.apple.com/documentation/visualintelligence)
- [App Intents](https://developer.apple.com/documentation/appintents)
- Local captured docs (optional): if `~/Downloads/docs/` contains `FoundationModels-Using-on-device-LLM-in-your-app.md`, `Implementing-Visual-Intelligence-in-iOS.md`, or `AppIntents-Updates.md`, read them for extra detail; skip silently if absent.
