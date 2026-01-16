# How to Use These Skills

## New App: Idea → App Store

### Phase 1: Validate
**Say:** "I have an idea for a [iOS/macOS] app that does X. Should I build it?"

Claude checks if it's worth building and gives you a BUILD / DON'T BUILD recommendation.

### Phase 2: Research (Optional)
**Say:** "Analyze competitors" and "Do market research"

### Phase 3: Generate Specs
**Say:** "Generate implementation specifications"

Creates 7 docs: PRD, Architecture, UX, Design System, Implementation Guide, Test Spec, Release Spec.

### Phase 4: Build
Follow the Implementation Guide, or ask Claude to generate specific features.

### Phase 5: Review & Release
**Say:** "Review for release" → then follow the Release Spec to submit.

---

## Existing App: Quick Reference

| I want to... | Say this... |
|--------------|-------------|
| Fix code issues | "Review my code for best practices" |
| Check UI compliance | "Review my UI for HIG" |
| Add logging | "Add logging to my app" |
| Add analytics | "Add analytics with TelemetryDeck" |
| Add settings | "Add settings screen" |
| Add auth | "Add Sign in with Apple" |
| Add payments | "Add subscription paywall" |
| Add onboarding | "Add onboarding flow" |
| Add notifications | "Add push notifications" |
| Add deep links | "Add deep linking" |
| Add crash reporting | "Add error monitoring" |
| Set up CI/CD | "Set up GitHub Actions" |
| Modernize UI | "Update to Liquid Glass design" |
| Add AI features | "Add on-device LLM features" |
| Prepare for release | "Review for release" |
| Improve App Store listing | "Optimize my App Store keywords" |
| Respond to review | "Help respond to this review: [text]" |

---

## Multi-Platform (iOS + macOS)

**Same workflow** - just say "iOS and macOS app" when describing your idea.

Differences:
- Architecture includes shared code + platform-specific UI layers
- UI review checks both iOS HIG and macOS HIG
- Two App Store submissions (one per platform)
- Screenshots needed for both platforms

---

## Skill Categories

| Category | Purpose | When to Use |
|----------|---------|-------------|
| `ios/` | iOS development | Code review, UI review, app planning |
| `macos/` | macOS development | Code review, UI review, Tahoe APIs |
| `product/` | Idea → specs | New app planning, full workflow |
| `generators/` | Generate code | Add features to any app |
| `apple-intelligence/` | AI features | Foundation Models, Visual Intelligence |
| `design/` | Modern UI | Liquid Glass effects |
| `app-store/` | ASO | Descriptions, keywords, screenshots |
| `release-review/` | Pre-release | Security, privacy, UX audit |

---

## FAQ

### Can I skip phases for a new app?
Yes, but not recommended. Specs build on each other. Skipping means less structured implementation.

### Do I need to invoke skills manually?
No. Just describe what you want. Claude picks the right skill automatically.

### How do generators work with existing code?
Claude reads your project first, then generates code that matches your patterns and structure.

### What if a generator doesn't fit my architecture?
Generator output is a starting point. Modify it to fit your needs, or ask Claude to adjust.

### iOS vs macOS - what's different?
Just the platform-specific review skills. Everything else (generators, product workflow, App Store skills) works the same.

### Can I use this for watchOS/visionOS?
watchOS: Yes, mention "watchOS" and relevant patterns apply.
visionOS: Limited - check `docs/ROADMAP.md` for planned visionOS skills.

### Where are the detailed skill docs?
Each skill has a `SKILL.md` with full documentation. Browse `skills/` directory.
