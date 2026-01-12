# ProductAgent Complete Workflow

## Overview

ProductAgent provides a complete "Idea to App Store" workflow through a combination of CLI commands and Claude Code Skills. This document describes the complete workflow with all phases.

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           IDEA INPUT                                     │
│                    "Luxury rental car payment app"                       │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 1: PRODUCT PLANNING                                               │
│  ───────────────────────────                                             │
│  Command: product-agent run --idea "..." --interactive                   │
│                                                                          │
│  Agents Executed:                                                        │
│  1. Problem Discovery Agent    → Problem validation, severity score      │
│  2. MVP Scoping Agent          → Core features, development phases       │
│  3. Positioning Agent          → Value proposition, messaging            │
│  4. ASO Optimization Agent     → App Store metadata, keywords            │
│                                                                          │
│  Output: product-plan-*.md (complete product development plan)           │
│                                                                          │
│  User Decision: BUILD / DON'T BUILD / INVESTIGATE MORE                   │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 2: MARKET RESEARCH (Optional but Recommended)                     │
│  ───────────────────────────────────────────────────                     │
│                                                                          │
│  Skills Used:                                                            │
│  • competitive-analysis → Deep competitor insights, feature gaps         │
│  • market-research      → TAM/SAM/SOM, market trends, revenue potential  │
│                                                                          │
│  Requires: WebSearch, WebFetch (works best in Claude Code)               │
│                                                                          │
│  Output:                                                                 │
│  • competitive-analysis.md (or embedded in product plan)                 │
│  • market-research.md (or embedded in product plan)                      │
│                                                                          │
│  User Decision: CONTINUE / PIVOT / ABANDON                               │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 3: SPECIFICATION GENERATION                                       │
│  ─────────────────────────────────                                       │
│  Activation: "Generate implementation specifications"                    │
│  Skill: implementation-spec (orchestrator)                               │
│                                                                          │
│  Sub-phases with Decision Gates:                                         │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Phase 3.1: PRD Generation (prd-generator skill)                  │    │
│  │ Input: Product plan + competitive + market research              │    │
│  │ Output: docs/PRD.md                                              │    │
│  │ User Reviews: Features, user stories, acceptance criteria        │    │
│  └──────────────────────────────┬──────────────────────────────────┘    │
│                                 ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Phase 3.2: Technical Architecture (architecture-spec skill)      │    │
│  │ Input: PRD                                                       │    │
│  │ Output: docs/ARCHITECTURE.md                                     │    │
│  │ User Reviews: Tech stack, data models, patterns                  │    │
│  └──────────────────────────────┬──────────────────────────────────┘    │
│                                 ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Phase 3.3: UI/UX Specifications (ux-spec skill)                  │    │
│  │ Input: PRD, Architecture                                         │    │
│  │ Output: docs/UX_SPEC.md, docs/DESIGN_SYSTEM.md                   │    │
│  │ User Reviews: Wireframes, design system, interactions            │    │
│  └──────────────────────────────┬──────────────────────────────────┘    │
│                                 ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Phase 3.4: Implementation Guide (implementation-guide skill)     │    │
│  │ Input: PRD, Architecture, UX                                     │    │
│  │ Output: docs/IMPLEMENTATION_GUIDE.md                             │    │
│  │ User Reviews: Pseudo-code, development phases, patterns          │    │
│  └──────────────────────────────┬──────────────────────────────────┘    │
│                                 ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Phase 3.5: Test Specification (test-spec skill)                  │    │
│  │ Input: PRD, Implementation Guide                                 │    │
│  │ Output: docs/TEST_SPEC.md                                        │    │
│  │ User Reviews: Test cases, coverage, beta plan                    │    │
│  └──────────────────────────────┬──────────────────────────────────┘    │
│                                 ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ Phase 3.6: Release Documentation (release-spec skill)            │    │
│  │ Input: ASO (from product plan), Architecture, Test Spec          │    │
│  │ Output: docs/RELEASE_SPEC.md                                     │    │
│  │ User Reviews: App Store metadata, submission checklist           │    │
│  └──────────────────────────────┬──────────────────────────────────┘    │
│                                                                          │
│  Complete Output: 7 specification files in docs/                         │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 4: IMPLEMENTATION                                                 │
│  ───────────────────────────                                             │
│                                                                          │
│  Options:                                                                │
│                                                                          │
│  A. Manual Implementation                                                │
│     Follow IMPLEMENTATION_GUIDE.md step-by-step                          │
│     - Week 1: Core infrastructure                                        │
│     - Week 2-4: Feature implementation                                   │
│     - Week 5-6: Testing and polish                                       │
│                                                                          │
│  B. Claude-Assisted Implementation                                       │
│     Ask Claude to implement specific components:                         │
│     "Implement HomeView from the specifications"                         │
│     "Generate the User data model"                                       │
│     "Create the APIClient networking layer"                              │
│                                                                          │
│  C. Hire Developer                                                       │
│     Share docs/ folder with developer                                    │
│     Specifications are comprehensive enough for implementation           │
│                                                                          │
│  Output: Working Xcode project                                           │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 5: TESTING                                                        │
│  ───────────────────                                                     │
│                                                                          │
│  Follow TEST_SPEC.md:                                                    │
│  • Unit tests for all models and ViewModels                              │
│  • Integration tests for data layer                                      │
│  • UI tests for critical user journeys                                   │
│  • Accessibility testing                                                 │
│  • Performance benchmarking                                              │
│                                                                          │
│  Beta Testing:                                                           │
│  • TestFlight distribution (20-50 testers)                               │
│  • 2-week testing period                                                 │
│  • Feedback collection and iteration                                     │
│                                                                          │
│  Output: Tested, stable app ready for release                            │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 6: APP STORE RELEASE                                              │
│  ─────────────────────────────                                           │
│                                                                          │
│  Follow RELEASE_SPEC.md:                                                 │
│  • Prepare App Store assets (icon, screenshots, video)                   │
│  • Create Privacy Manifest (PrivacyInfo.xcprivacy)                       │
│  • Fill App Store Connect metadata                                       │
│  • Submit for review                                                     │
│  • Launch and monitor                                                    │
│                                                                          │
│  Output: App live on App Store!                                          │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  PHASE 7: POST-LAUNCH                                                    │
│  ─────────────────────                                                   │
│                                                                          │
│  • Monitor crash reports and reviews                                     │
│  • Release v1.0.1 bug fixes (1-2 weeks after launch)                     │
│  • Implement deferred features                                           │
│  • Release v1.1.0 first feature update                                   │
│  • Iterate based on user feedback                                        │
│                                                                          │
│  Output: Successful, growing app                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Quick Reference

### Commands and Activation Phrases

| Phase | How to Activate | Output |
|-------|-----------------|--------|
| Product Planning | `product-agent run --idea "..." --interactive` | product-plan-*.md |
| Competitive Analysis | Say "analyze competitors" or "competitive analysis" | competitive-analysis.md |
| Market Research | Say "market research" or "market sizing" | market-research.md |
| Generate All Specs | Say "generate implementation specifications" | docs/*.md (7 files) |
| Generate PRD only | Say "generate PRD" | docs/PRD.md |
| Generate Architecture only | Say "generate architecture" | docs/ARCHITECTURE.md |
| Generate UX Spec only | Say "generate UX spec" | docs/UX_SPEC.md |
| Generate Implementation Guide | Say "generate implementation guide" | docs/IMPLEMENTATION_GUIDE.md |
| Generate Test Spec | Say "generate test spec" | docs/TEST_SPEC.md |
| Generate Release Spec | Say "generate release spec" | docs/RELEASE_SPEC.md |

### File Locations

```
project/
├── product-plan-*.md              # Product development plan (from CLI)
├── competitive-analysis.md        # Competitive analysis (from skill)
├── market-research.md             # Market research (from skill)
└── docs/
    ├── PRD.md                     # Product Requirements Document
    ├── ARCHITECTURE.md            # Technical Architecture
    ├── UX_SPEC.md                 # UI/UX Specifications
    ├── DESIGN_SYSTEM.md           # Design System
    ├── IMPLEMENTATION_GUIDE.md    # Development Roadmap
    ├── TEST_SPEC.md               # Testing Strategy
    └── RELEASE_SPEC.md            # App Store Launch Guide
```

## Specification Dependency Graph

Understanding dependencies helps when updating specs:

```
Product Plan (Source)
    │
    ├──► Competitive Analysis
    │         │
    ├──► Market Research
    │         │
    └──► PRD ◄┴─────────────────────────┐
          │                              │
          ├──► ARCHITECTURE              │
          │         │                    │
          │         └──► IMPLEMENTATION ◄┤
          │                   ▲          │
          ├──► UX_SPEC ───────┘          │
          │         │                    │
          │         └──► DESIGN_SYSTEM   │
          │                              │
          ├──► TEST_SPEC ◄───────────────┤
          │                              │
          └──► RELEASE_SPEC ◄────────────┘
```

### Update Impact Matrix

When you change one spec, here's what might need updating:

| If you change... | Check these specs... |
|------------------|---------------------|
| PRD (features) | Architecture, UX, Implementation, Test |
| Architecture | Implementation Guide |
| UX Spec | Implementation Guide, Design System |
| Design System | (usually standalone) |
| Test Spec | (usually standalone) |
| Release Spec | (usually standalone) |

## Estimated Timeline

| Phase | Duration | Notes |
|-------|----------|-------|
| Product Planning | 5-10 min | CLI execution + user review |
| Market Research | 10-15 min | Optional, requires WebSearch |
| Specification Generation | 10-15 min | User review time at each gate |
| Implementation | 4-8 weeks | Depends on app complexity |
| Testing | 2-3 weeks | Including beta testing |
| App Store Release | 1-2 weeks | Review time varies |

**Total: Idea to App Store in 8-14 weeks** (for MVP)

## Tips for Success

### Phase 1: Product Planning
- Be specific about your app idea
- Use `--interactive` flag for decision points
- Review all agent outputs carefully

### Phase 2: Market Research
- Don't skip this phase - it significantly improves specs
- WebSearch may not work in all regions (US recommended)
- Save research as markdown files for reuse

### Phase 3: Specification Generation
- Review each phase before approving
- Request changes early (upstream changes cascade down)
- Use the dependency graph when making updates

### Phase 4: Implementation
- Follow IMPLEMENTATION_GUIDE.md step-by-step
- Implement one feature at a time
- Write tests as you go (don't defer)

### Phase 5: Testing
- Target 80%+ code coverage
- Test on multiple devices and iOS versions
- Beta test for at least 2 weeks

### Phase 6: Release
- Prepare all assets before submission
- Review Apple's latest guidelines
- Respond to reviews promptly

## Common Questions

### Q: Can I skip phases?
Yes, but not recommended. Each phase builds on the previous. Skipping market research means less informed specs. Skipping specs means less structured implementation.

### Q: What if I want to change features after specs are generated?
Update the PRD first, then regenerate downstream specs as needed. See the Update Impact Matrix above.

### Q: Can I use this for macOS apps?
Yes! The workflow is designed for iOS/macOS apps. Specify your platform in the product planning phase.

### Q: What if WebSearch doesn't work in my region?
Competitive analysis and market research are optional. You can proceed with the product plan data only, or manually gather research.

### Q: How do I implement a specific component?
After specs are generated, ask: "Implement [component name] from the specifications" and Claude will generate actual Swift code following the pseudo-code in IMPLEMENTATION_GUIDE.md.

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | Initial | Complete workflow documentation |

---

**Generated by ProductAgent**
