# Product Agent - Analysis Reference

This document contains the detailed output schema and analysis methodology for the Product Agent skill.

## JSON Output Schema

### Discovery Analysis Output

```typescript
{
  problem_statement: string,        // One-sentence core problem description
  target_users: string,              // Who experiences this problem most
  pain_points: string[],             // Array of specific pain points
  severity_score: string,            // Format: "N/10" where N is 1-10
  frequency: string,                 // How often users encounter this problem
  current_solutions: string[],       // Existing alternatives and their limitations
  opportunity: string,               // Market opportunity assessment
  recommendation: string             // Detailed verdict: build/don't build with reasoning
}
```

### Field Descriptions

#### `problem_statement`
- **Type:** String
- **Format:** One sentence
- **Purpose:** Clear, concise statement of the core problem
- **Example:** "Users need to capture fleeting thoughts before they're forgotten, but existing note apps have too much friction."

#### `target_users`
- **Type:** String
- **Purpose:** Describes who experiences this problem most acutely
- **Example:** "Knowledge workers, writers, and students who have frequent spontaneous ideas throughout the day."

#### `pain_points`
- **Type:** Array of strings
- **Count:** Typically 4-8 items
- **Purpose:** Specific, concrete pain points users experience
- **Example:**
  ```json
  [
    "Ideas evaporate in the 5-10 seconds it takes to open a traditional note app",
    "Context switching from current task to note-taking breaks flow state",
    "Existing apps force premature organization decisions"
  ]
  ```

#### `severity_score`
- **Type:** String
- **Format:** "N/10" where N is 1-10
- **Interpretation:**
  - 1-3: Weak problem, low urgency
  - 4-6: Moderate problem, decent opportunity
  - 7-8: Strong problem, good opportunity
  - 9-10: Critical problem, excellent opportunity (rare)
- **Example:** "7/10"

#### `frequency`
- **Type:** String
- **Purpose:** How often users encounter this problem
- **Example:** "Multiple times per day for target users, but most users have workable alternatives"

#### `current_solutions`
- **Type:** Array of strings
- **Purpose:** Existing alternatives and their limitations
- **Format:** Each item typically includes the solution name and its key limitation
- **Example:**
  ```json
  [
    "Apple Notes - Fast but still requires unlock, app launch, new note. Good iCloud sync.",
    "Drafts app - Already solves this problem very well with instant capture and automation",
    "iOS Lock Screen widgets - Can launch straight to new note in some apps"
  ]
  ```

#### `opportunity`
- **Type:** String
- **Purpose:** Market opportunity assessment with reasoning
- **Common Keywords:** WEAK, MODERATE, STRONG, EXCELLENT
- **Example:** "MODERATE - There's a narrow opportunity IF you can differentiate with fastest possible capture and unique organizing philosophy."

#### `recommendation`
- **Type:** String (often multi-paragraph)
- **Purpose:** **Most important field** - honest verdict with detailed reasoning
- **Format:** Often includes:
  - Opening statement (BUILD / DO NOT BUILD / PROCEED WITH CAUTION)
  - Reasons for verdict
  - Specific risks or opportunities
  - Alternative suggestions if "don't build"
  - Bottom line summary
- **Example:** See examples/discovery.json

## Research Methodology

### Web Research Strategy

When analyzing an idea, search for:

1. **Competitor discovery:**
   - "[category] apps iOS"
   - "[category] apps macOS"
   - "best [category] apps Apple"

2. **Competitor details (for each):**
   - "[competitor name] features"
   - "[competitor name] pricing 2026"
   - "[competitor name] reviews"

3. **Market context:**
   - "[category] market size 2026"
   - "[category] market growth"
   - "[category] app trends"

4. **User sentiment:**
   - "[category] app complaints reddit"
   - "[category] app reviews"

### Analysis Framework

**Problem Validation:**
- Is the problem real? (Do people actually complain about this?)
- Is it frequent? (Daily > weekly > monthly)
- Is it severe? (Workaround exists vs. no good solution)
- Are people paying to solve it? (Willingness to pay signals real pain)

**Market Assessment:**
- How many competitors exist?
- How strong are the incumbents?
- Is Apple likely to build this natively?
- What's the differentiation angle?

**Honesty Principles:**
- If Apple already does this well for free, say "don't build"
- If the market has 10+ strong competitors, say "don't build" unless there's a clear gap
- If severity is below 4, the problem isn't painful enough
- Never recommend building just because the technology is interesting

## Anti-Patterns

### Ignoring "Don't Build" Recommendations
If the analysis says "don't build", there's usually a strong market reason. Don't override this because "mine will be simpler" or "I'll make a better UI."

### Not Reading the Full Recommendation
A severity score of 7/10 alone doesn't tell the story. The recommendation field contains the nuanced reasoning.

### Lack of Context
"Task app" produces a weaker analysis than "Task manager with AI auto-prioritization for busy professionals on iOS." More context = better analysis.

### Building Despite Weak Validation
Severity 3/10 + WEAK opportunity = months of wasted effort. If it's a learning project, fine. But don't expect commercial success.

## Integration with Other Skills

### Workflow

```
1. product-agent → Quick validation (this skill)
2. If promising:
   - competitive-analysis → Deep competitor insights
   - market-research → Market sizing (TAM/SAM/SOM)
3. Go/no-go decision with full data
4. If go:
   - idea-generator → Refine the concept
   - prd-generator → Product requirements
   - architecture-spec → Technical design
```

## Best Practices

1. **Always produce JSON output** for structured analysis
2. **Read the recommendation field first** — it's the most important
3. **Provide platform and target user** when known for better results
4. **Trust "don't build" verdicts** — the analysis is designed to be honest
5. **Compare multiple ideas** before committing to one
6. **Use web research** to validate assumptions about competitors and market
