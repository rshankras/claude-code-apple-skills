---
name: product-agent
description: Discover and validate product ideas, analyze markets, scope MVPs, and optimize app store presence for iOS/macOS apps. Use when user asks to discover, validate, assess, scope, or analyze product ideas, market opportunities, or when they mention "product agent", "app idea validation", "should I build this", "MVP", "market analysis", or "ASO".
allowed-tools: Bash(product-agent:*), Read
---

# Product Agent Skill

Product Agent is an AI-powered CLI tool for iOS/macOS app product development. It uses specialized agents to guide you from idea to launch.

## When to Use This Skill

Use this Skill when the user wants to:
- Discover or validate product ideas
- Analyze market opportunities
- Check if an app idea is worth building
- Understand competitive landscape
- Assess problem severity
- Get honest feedback on app concepts

## Quick Start

The most common use case is **Problem Discovery** - validating whether an app idea solves a real problem:

```bash
product-agent discover \
  --idea "APP_IDEA_DESCRIPTION" \
  --output-format json
```

**Always use `--output-format json`** for structured, machine-readable output.

## Available Commands

### `discover` - Problem Discovery Agent

Validates product ideas by analyzing:
- Core problem statement
- Target users
- Pain points
- Severity and frequency
- Current solutions and their limitations
- Market opportunity
- **Honest recommendation** (build/don't build)

**Required Options:**
- `--idea TEXT` - The app idea to analyze (required)

**Optional Options:**
- `--platform TEXT` - Target platform (default: "iOS/macOS")
- `--target-user TEXT` - Target user persona if known
- `--output-format FORMAT` - Output format: `text`, `json`, or `markdown` (default: text)
- `--save` - Save output to file
- `--output PATH` - Output file path (default: problem-analysis.json)
- `--verbose` - Show execution time and model info

**Example:**
```bash
product-agent discover \
  --idea "Menu bar app that reminds developers to take breaks every 20 minutes" \
  --platform "macOS" \
  --target-user "developers" \
  --output-format json
```

### `info` - System Information

Shows configuration and system status:

```bash
product-agent info
```

No options needed. Displays:
- Current mode (development/production)
- Claude CLI path or API key status
- Environment variables
- Available agents

## Output Formats

### JSON (Recommended for Analysis)

Use `--output-format json` when you need to:
- Analyze results programmatically
- Chain with other tools/agents
- Extract specific fields
- Save structured data

**JSON Schema:**
```json
{
  "problem_statement": "One-sentence core problem",
  "target_users": "Who experiences this problem",
  "pain_points": ["List of specific pain points"],
  "severity_score": "1-10 rating",
  "frequency": "How often users encounter this",
  "current_solutions": ["Existing alternatives and their limitations"],
  "opportunity": "Market opportunity assessment",
  "recommendation": "Honest verdict: build or don't build, and why"
}
```

### Text (Human-Readable)

Use `--output-format text` for:
- Quick validation during conversation
- Human review
- Terminal-friendly output

### Markdown (Documentation)

Use `--output-format markdown` for:
- Saving reports
- Sharing with stakeholders
- Documentation

## Interpreting Results

### Key Field: `recommendation`

This is the **most important field**. It contains:
- Honest assessment of whether to build
- Market reality check
- Competitive analysis
- Specific reasons for the verdict

**The agent is brutally honest** - if it says "don't build", there's usually a good reason.

### Severity Score

- **1-3**: Weak problem, low urgency
- **4-6**: Moderate problem, decent opportunity
- **7-8**: Strong problem, good opportunity
- **9-10**: Critical problem, excellent opportunity

### Opportunity Assessment

Look for keywords:
- "WEAK" - Saturated market or marginal problem
- "MODERATE" - Some opportunity with differentiation
- "STRONG" - Clear gap in market
- "EXCELLENT" - Underserved need with high demand

## Common Workflows

### 1. Quick Idea Validation

```bash
product-agent discover \
  --idea "YOUR_IDEA" \
  --output-format json
```

Then analyze the `recommendation` and `severity_score` fields.

### 2. Deep Market Analysis

```bash
product-agent discover \
  --idea "YOUR_IDEA" \
  --platform "iOS/macOS" \
  --target-user "specific persona" \
  --output-format json \
  --verbose
```

Review all fields, especially `current_solutions` and `opportunity`.

### 3. Save for Later

```bash
product-agent discover \
  --idea "YOUR_IDEA" \
  --output-format markdown \
  --save \
  --output "idea-analysis"
```

Creates `idea-analysis.md` with full report.

### 4. Compare Multiple Ideas

Run discovery on each idea, save as JSON, then compare the:
- `severity_score`
- `opportunity` assessment
- `recommendation` verdict

## Best Practices

### 1. Always Use JSON Format

Unless the user specifically asks for text or markdown, use:
```bash
--output-format json
```

JSON enables better analysis and integration.

### 2. Provide Context When Available

If you know the platform or target user:
```bash
--platform "macOS" \
--target-user "software developers"
```

More context = better analysis.

### 3. Read the Recommendation Carefully

The `recommendation` field often includes:
- Specific reasons not to build
- Alternative approaches
- Market insights
- Risk factors

Don't just look at the score - read the reasoning.

### 4. Save Important Results

When the user might want to reference results later:
```bash
--save --output "descriptive-name"
```

### 5. Use Verbose Mode for Debugging

If execution seems slow or behaves unexpectedly:
```bash
--verbose
```

Shows execution time, model, and token usage.

## Handling Results

### After Running Discovery

1. **Parse the JSON output** (if using json format)
2. **Highlight the recommendation** - this is what the user cares about most
3. **Explain the severity score** - put it in context
4. **Summarize pain points** - these validate the problem
5. **Discuss opportunity** - is the market good?
6. **Present alternatives** - if "don't build", what should they do instead?

### Example Analysis Flow

```
1. Run: product-agent discover --idea "..." --output-format json
2. Parse JSON
3. Check recommendation field
4. If "DO NOT BUILD":
   - Explain why (market saturation, weak problem, etc.)
   - Suggest alternatives or pivots
5. If "BUILD" or "PROCEED WITH CAUTION":
   - Highlight key differentiators needed
   - Discuss risks
   - Suggest next steps
```

## Troubleshooting

### "Claude CLI not found"

The tool is configured for development mode but can't find Claude Code CLI.

**Solution:** Run `product-agent info` to check configuration.

### "Invalid output format"

Valid formats are: `text`, `json`, `markdown` (lowercase only).

### JSON Parsing Issues

Sometimes the LLM returns JSON wrapped in markdown code blocks. The tool automatically extracts it, but if you see issues, check the raw output.

### Slow Execution

Normal execution time is 20-40 seconds. The tool is calling an LLM to do deep analysis.

Use `--verbose` to see exact execution time.

## Configuration

Product Agent uses environment variables for configuration:

- `CLAUDE_PATH` - Path to Claude CLI binary (default: /usr/local/bin/claude)
- `PRODUCT_AGENT_MODE` - `development` or `production`
- `ANTHROPIC_API_KEY` - API key for production mode
- `CLAUDE_MODEL` - Model to use

**For this Skill, always use development mode** (default). It's free and uses Claude Code CLI.

## Advanced Usage

For advanced patterns like agent chaining, batch processing, and custom workflows, see [REFERENCE.md](REFERENCE.md).

## Example Session

**User asks:** "Should I build a password manager for the Apple ecosystem?"

**You run:**
```bash
product-agent discover \
  --idea "Password manager built specifically for Apple ecosystem with iCloud sync" \
  --platform "iOS/macOS" \
  --output-format json
```

**You analyze:**
- Parse JSON output
- Check `recommendation` field
- Read `current_solutions` (iCloud Keychain, 1Password, etc.)
- Assess `opportunity` (likely WEAK - Apple already provides this)
- Present findings:
  "Based on the analysis, this is not recommended. The market is saturated with Apple's own iCloud Keychain as a free, deeply-integrated solution. The opportunity is weak unless you have a truly novel approach or serve a specific underserved niche."

## Tips for Effective Use

1. **Be specific in idea descriptions** - More detail = better analysis
2. **Trust the recommendation** - The agent is trained to be honest
3. **Look for patterns** - Similar apps getting "don't build" = saturated market
4. **Focus on severity + opportunity** - Both must be strong
5. **Read current_solutions** - Shows what you're competing against
6. **Save your analyses** - Build a knowledge base of validated/invalidated ideas

## Deep-Dive Skills

After running discovery, use these specialized Skills for deeper analysis:

### **competitive-analysis** Skill
When you need detailed competitor research:
- Feature comparison matrices
- Pricing analysis across competitors
- SWOT for each competitor
- Differentiation opportunities
- Market positioning maps

**Use when:** Discovery shows potential and you need to understand competition in detail.

### **market-research** Skill
When you need market sizing and opportunity assessment:
- TAM/SAM/SOM calculations
- Growth trends and projections
- Market maturity assessment
- Entry barriers analysis
- Revenue potential estimates

**Use when:** Discovery shows potential and you need to size the opportunity.

**Workflow:**
```
1. product-agent discover → Quick validation (30 seconds)
2. If promising, use deep-dive Skills:
   - competitive-analysis → Understand players
   - market-research → Size opportunity
3. Make go/no-go decision with full data
```

## Coming Soon

Future agents that will be added:
- MVP Scoping Agent - Define what to build
- Positioning Agent - Craft messaging
- ASO Optimization Agent - App store optimization
- Launch Planning Agent - Distribution strategy

This Skill will be updated when these agents are available.

---

**Remember:** Product Agent is brutally honest. If it says "don't build", listen. It's saving you months of wasted effort on weak ideas.
