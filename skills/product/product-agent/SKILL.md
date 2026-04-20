---
name: product-agent
description: Discover and validate product ideas, analyze markets, scope MVPs, and optimize app store presence for iOS/macOS apps. Use when user asks to discover, validate, assess, scope, or analyze product ideas, market opportunities, or when they mention "product agent", "app idea validation", "should I build this", "MVP", "market analysis", or "ASO".
allowed-tools: [Read, Write, WebSearch, WebFetch, AskUserQuestion]
---

# Product Agent Skill

Product Agent validates iOS/macOS app ideas by analyzing problems, markets, and competition. It provides honest, structured assessments to help you decide whether to build.

## When This Skill Activates

Use this Skill when the user wants to:
- Discover or validate product ideas
- Analyze market opportunities
- Check if an app idea is worth building
- Understand competitive landscape
- Assess problem severity
- Get honest feedback on app concepts

## How It Works

This skill performs structured product analysis using reasoning and web research. No external tools required — Claude analyzes the idea directly and researches the market via WebSearch/WebFetch.

## Quick Start

When the user provides an app idea, perform the **Problem Discovery Analysis** below and present the results.

If the user hasn't provided enough detail, ask:
1. What's the app idea? (required)
2. What platform? (iOS, macOS, or both — default: iOS/macOS)
3. Who's the target user? (optional but improves analysis)

## Problem Discovery Analysis

For each idea, analyze and produce these fields:

### 1. Problem Statement
One-sentence description of the core problem the app solves.

### 2. Target Users
Who experiences this problem most acutely? Be specific about demographics, roles, and context.

### 3. Pain Points
List 4-8 specific, concrete pain points users experience today. Each should be observable and verifiable.

### 4. Severity Score (1-10)
Rate how painful this problem is:
- **1-3**: Weak problem, low urgency — users barely notice
- **4-6**: Moderate problem, decent opportunity — users work around it
- **7-8**: Strong problem, good opportunity — users actively seek solutions
- **9-10**: Critical problem, excellent opportunity — users are desperate (rare)

### 5. Frequency
How often do target users encounter this problem? Daily problems are stronger than weekly ones.

### 6. Current Solutions
Research existing alternatives using WebSearch. For each competitor:
- Name and brief description
- Key strengths
- Main limitations
- Pricing model

### 7. Market Opportunity
Assess the opportunity using one of: **WEAK**, **MODERATE**, **STRONG**, **EXCELLENT**.
Include reasoning about market saturation, differentiation potential, and timing.

### 8. Recommendation
The most important field. Provide an honest verdict:
- **BUILD** — Clear opportunity, go for it
- **PROCEED WITH CAUTION** — Opportunity exists but significant risks
- **DO NOT BUILD** — Market saturated, weak problem, or better alternatives exist

Include:
- Specific reasons for the verdict
- Key risks
- What would need to be true for this to succeed
- Alternative approaches if "don't build"

## Output Format

Present results as structured JSON for easy consumption by other skills:

```json
{
  "problem_statement": "One-sentence core problem",
  "target_users": "Who experiences this problem",
  "pain_points": ["List of specific pain points"],
  "severity_score": "N/10",
  "frequency": "How often users encounter this",
  "current_solutions": ["Existing alternatives and their limitations"],
  "opportunity": "WEAK|MODERATE|STRONG|EXCELLENT — reasoning",
  "recommendation": "Honest verdict with detailed reasoning"
}
```

Follow the JSON with a human-readable summary highlighting the key takeaway.

## Research Process

1. **Analyze the idea** — Break down the problem, users, and value proposition
2. **Search for competitors** — Use WebSearch for "[category] apps iOS", "[competitor] features", "[competitor] pricing"
3. **Check App Store landscape** — Search for similar apps, ratings, reviews
4. **Assess market trends** — Search for "[category] market growth", "[category] trends 2026"
5. **Synthesize findings** — Combine analysis into structured output

## Interpreting Results

### Key Field: `recommendation`

This is the **most important field**. It contains:
- Honest assessment of whether to build
- Market reality check
- Competitive analysis
- Specific reasons for the verdict

**The analysis is brutally honest** — if it says "don't build", there's usually a good reason.

### Severity Score

- **1-3**: Weak problem, low urgency
- **4-6**: Moderate problem, decent opportunity
- **7-8**: Strong problem, good opportunity
- **9-10**: Critical problem, excellent opportunity

### Opportunity Assessment

Look for keywords:
- "WEAK" — Saturated market or marginal problem
- "MODERATE" — Some opportunity with differentiation
- "STRONG" — Clear gap in market
- "EXCELLENT" — Underserved need with high demand

## Common Workflows

### 1. Quick Idea Validation

User provides an idea. Run the full analysis and focus on the `recommendation` and `severity_score`.

**Decision framework:**
- **Score 7+, STRONG opportunity, BUILD verdict** — Green light
- **Score 4-6, MODERATE opportunity, CAUTION verdict** — Needs differentiation strategy
- **Score <4, WEAK opportunity, DON'T BUILD verdict** — Red light

### 2. Comparing Multiple Ideas

Run analysis on each idea, then compare:
- Severity scores (higher = better)
- Opportunity assessments (STRONG > MODERATE > WEAK)
- Recommendation verdicts
- Current solutions (fewer/weaker competitors = better)

### 3. Iterative Refinement

If initial analysis says "don't build", explore pivots:
- Narrow the niche (e.g., "note-taking" -> "note-taking for academic researchers")
- Change the target user
- Add a unique angle (e.g., AI-powered, privacy-focused)

Re-run analysis for each pivot and look for improving severity and opportunity scores.

## After Running Discovery

1. **Highlight the recommendation** — this is what the user cares about most
2. **Explain the severity score** — put it in context
3. **Summarize pain points** — these validate the problem
4. **Discuss opportunity** — is the market good?
5. **Present alternatives** — if "don't build", what should they do instead?

## Deep-Dive Skills

After running discovery, use these specialized Skills for deeper analysis:

### **competitive-analysis** Skill
When discovery shows potential and you need to understand competition in detail:
- Feature comparison matrices
- Pricing analysis across competitors
- SWOT for each competitor
- Differentiation opportunities

### **market-research** Skill
When discovery shows potential and you need to size the opportunity:
- TAM/SAM/SOM calculations
- Growth trends and projections
- Market maturity assessment
- Revenue potential estimates

**Workflow:**
```
1. product-agent → Quick validation (problem discovery)
2. If promising, use deep-dive Skills:
   - competitive-analysis → Understand players
   - market-research → Size opportunity
3. Make go/no-go decision with full data
```

## Example

**User asks:** "Should I build a password manager for the Apple ecosystem?"

**You research and analyze**, then present:

```json
{
  "problem_statement": "Users need secure password management that seamlessly integrates across Apple devices without relying on third-party services.",
  "target_users": "Apple ecosystem loyalists who own multiple Apple devices and prioritize privacy and native integration.",
  "pain_points": [
    "Existing password managers prioritize cross-platform over deep Apple integration",
    "Third-party managers don't fully integrate with iOS autofill and Face ID",
    "Subscription fatigue from cross-platform services they don't need",
    "UIs that don't follow Apple Human Interface Guidelines"
  ],
  "severity_score": "3/10",
  "frequency": "Daily, but existing solutions work adequately",
  "current_solutions": [
    "iCloud Keychain - Free, deeply integrated, improving rapidly. Limited organization.",
    "1Password - Polished, $36-48/year, cross-platform focused",
    "Bitwarden - Open source, cheaper, generic UI"
  ],
  "opportunity": "WEAK - Highly saturated market with Apple's own iCloud Keychain as dominant free incumbent. Any differentiating feature risks being absorbed by Apple in the next OS update.",
  "recommendation": "DO NOT BUILD. Apple's iCloud Keychain is free, pre-installed, and continuously improving. The differentiation window is tiny, willingness to pay for marginal improvements is low, and one security breach would be catastrophic for an indie developer. Consider instead: tools that augment iCloud Keychain, niche password management (API keys for developers), or a different underserved problem in the Apple ecosystem."
}
```

**Summary:** This is not recommended. iCloud Keychain dominates as a free, deeply-integrated solution. Unless you have a truly novel approach or serve a specific underserved niche, the market is too saturated.

## Tips for Effective Use

1. **Be specific in idea descriptions** — More detail = better analysis
2. **Trust the recommendation** — The analysis is designed to be honest
3. **Look for patterns** — Similar apps getting "don't build" = saturated market
4. **Focus on severity + opportunity** — Both must be strong
5. **Read current_solutions** — Shows what you're competing against
6. **Save your analyses** — Build a knowledge base of validated/invalidated ideas

---

**Remember:** This analysis is brutally honest. If it says "don't build", listen. It's saving you months of wasted effort on weak ideas.
