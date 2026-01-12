# Product Agent - Complete Reference

This document contains detailed documentation for advanced usage of Product Agent. Claude reads this when needed for deep technical questions.

## Complete CLI Reference

### Global Options

These work with all commands:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--help`, `-h` | Flag | - | Show help |
| `--version`, `-v` | Flag | - | Show version |

### Command: `discover`

**Purpose:** Discover and validate product problems/opportunities

**Usage:**
```bash
product-agent discover [OPTIONS]
```

**Required Options:**

| Option | Type | Description | Example |
|--------|------|-------------|---------|
| `--idea TEXT` | String | The app idea to analyze | `--idea "Calendar app with AI"` |

**Optional Options:**

| Option | Type | Default | Valid Values | Description |
|--------|------|---------|--------------|-------------|
| `--platform TEXT` | String | "iOS/macOS" | iOS, macOS, iOS/macOS, or any text | Target platform |
| `--target-user TEXT` | String | nil | Any text | Target user persona |
| `--output-format FORMAT` | String | "text" | text, json, markdown | Output format |
| `--save` | Flag | false | - | Save output to file |
| `--output PATH` | String | "problem-analysis.json" | Any valid path | Output file path |
| `--verbose` | Flag | false | - | Enable verbose logging |
| `--production` | Flag | false | - | Use production mode (Claude API) |

**Examples:**

```bash
# Minimal usage
product-agent discover --idea "Task manager app"

# Full options
product-agent discover \
  --idea "AI-powered calendar that suggests optimal meeting times" \
  --platform "iOS" \
  --target-user "busy professionals" \
  --output-format json \
  --save \
  --output "calendar-analysis" \
  --verbose

# Quick validation
product-agent discover --idea "Note-taking app" --output-format json

# Save markdown report
product-agent discover \
  --idea "Fitness tracker" \
  --output-format markdown \
  --save \
  --output "fitness-report"
```

###Command: `info`

**Purpose:** Show system configuration and information

**Usage:**
```bash
product-agent info
```

**No options required.**

**Output:**
- Current mode (development/production)
- Claude CLI path and status (or API key status)
- Environment variables
- Available agents

## JSON Output Schema

### Discovery Agent Output

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

**Field Descriptions:**

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
    "Apple Notes - Fast but still requires unlock → app launch → new note. Good iCloud sync.",
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

## Mode Switching

Product Agent supports two modes:

### Development Mode (Default)

**Uses:** Claude Code CLI
**Cost:** Free
**Setup:** Requires Claude Code installed

**Environment Variables:**
- `CLAUDE_PATH` - Path to Claude CLI binary (default: /usr/local/bin/claude)
- `CLAUDE_MODEL` - Model to use (default: claude-sonnet-4-20250514)

**How to Use:**
```bash
# Just run normally (default mode)
product-agent discover --idea "Your idea"

# Or explicitly set
export PRODUCT_AGENT_MODE=development
product-agent discover --idea "Your idea"
```

### Production Mode

**Uses:** Claude API directly
**Cost:** Per-token pricing from Anthropic
**Setup:** Requires ANTHROPIC_API_KEY

**Environment Variables:**
- `ANTHROPIC_API_KEY` - Your Anthropic API key (required)
- `CLAUDE_MODEL` - Model to use (default: claude-sonnet-4-20250514)

**How to Use:**
```bash
# Set API key
export ANTHROPIC_API_KEY="your-key-here"

# Use --production flag
product-agent discover --idea "Your idea" --production

# Or set mode globally
export PRODUCT_AGENT_MODE=production
product-agent discover --idea "Your idea"
```

**When to Use Production Mode:**
- Claude Code CLI is unavailable
- Need guaranteed reliability
- Building automated pipelines
- Token usage tracking required

## Configuration

All configuration via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PRODUCT_AGENT_MODE` | development | Mode: development or production |
| `CLAUDE_PATH` | /usr/local/bin/claude | Path to Claude CLI binary |
| `ANTHROPIC_API_KEY` | - | API key for production mode |
| `CLAUDE_MODEL` | claude-sonnet-4-20250514 | Model to use |
| `PRODUCT_AGENT_VERBOSE` | false | Enable verbose logging |

**Configuration Priority:**
1. CLI flags (--verbose, --production)
2. Environment variables
3. Defaults

**Check Current Configuration:**
```bash
product-agent info
```

## Error Handling

### Common Errors

#### "Claude CLI not found"

**Cause:** Development mode but Claude Code CLI not installed or not at expected path

**Solutions:**
1. Install Claude Code
2. Set `CLAUDE_PATH` to correct location:
   ```bash
   export CLAUDE_PATH=/path/to/claude
   ```
3. Use production mode instead:
   ```bash
   export ANTHROPIC_API_KEY="your-key"
   product-agent discover --idea "..." --production
   ```

#### "Missing API Key"

**Cause:** Production mode but no ANTHROPIC_API_KEY set

**Solution:**
```bash
export ANTHROPIC_API_KEY="your-key-here"
```

#### "Invalid output format"

**Cause:** Provided format not in: text, json, markdown

**Solution:** Use lowercase: `--output-format json`

#### "Rate limit exceeded"

**Cause:** (Production mode) Hit Anthropic API rate limit

**Solutions:**
1. Wait and retry
2. Switch to development mode (uses Claude Code CLI, no rate limits)

#### JSON Parsing Errors

**Cause:** LLM returned malformed JSON

**Note:** Tool auto-extracts JSON from markdown code blocks. Usually works automatically.

**If persists:**
1. Try again (LLMs are non-deterministic)
2. Check raw output with `--verbose`
3. File an issue if repeatable

## Advanced Patterns

### 1. Agent Chaining

Run multiple discoveries and compare:

```bash
# Discover multiple ideas
for idea in "idea1" "idea2" "idea3"; do
  product-agent discover \
    --idea "$idea" \
    --output-format json \
    --save \
    --output "analysis-$idea"
done

# Then compare the JSON outputs
```

### 2. Batch Processing

Process a list of ideas from a file:

```bash
while IFS= read -r idea; do
  product-agent discover \
    --idea "$idea" \
    --output-format json \
    --save
done < ideas.txt
```

### 3. Markdown Reports

Generate shareable reports:

```bash
product-agent discover \
  --idea "Your idea" \
  --output-format markdown \
  --save \
  --output "stakeholder-report"

# Creates: stakeholder-report.md
# Ready to share with team
```

### 4. Pipeline Integration

Use in CI/CD or automation:

```bash
#!/bin/bash
# Validate product idea before starting work

result=$(product-agent discover \
  --idea "$APP_IDEA" \
  --output-format json)

recommendation=$(echo "$result" | jq -r '.recommendation')

if [[ "$recommendation" == *"DO NOT BUILD"* ]]; then
  echo "Idea not validated. Stopping."
  exit 1
fi

echo "Idea validated. Proceeding..."
```

### 5. Integration with Other Tools

Combine with jq for JSON processing:

```bash
# Extract just the severity score
product-agent discover --idea "..." --output-format json | \
  jq -r '.severity_score'

# Extract pain points
product-agent discover --idea "..." --output-format json | \
  jq -r '.pain_points[]'

# Get recommendation verdict only
product-agent discover --idea "..." --output-format json | \
  jq -r '.recommendation' | head -1
```

## Performance Considerations

### Execution Time

**Typical Duration:** 20-40 seconds per discovery

**Factors Affecting Speed:**
- LLM response time (varies by load)
- Complexity of idea (more complex = deeper analysis)
- Network latency (production mode)

**Note:** This is normal for AI-powered analysis. The tool is doing deep market research and competitive analysis.

### Token Usage

**Development Mode:** No token tracking (uses Claude Code CLI)

**Production Mode:**
- Use `--verbose` to see token counts
- Typical usage: 1,500-3,000 input tokens, 1,000-2,000 output tokens per discovery

### Cost Optimization

**For development/testing:** Use development mode (free)

**For production:**
- Use production mode only when needed
- Batch similar analyses
- Cache results (save JSON outputs)

## Troubleshooting Checklist

1. **Check configuration:**
   ```bash
   product-agent info
   ```

2. **Verify Claude CLI (development mode):**
   ```bash
   which claude
   echo $CLAUDE_PATH
   ```

3. **Verify API key (production mode):**
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

4. **Test with minimal command:**
   ```bash
   product-agent discover --idea "test" --output-format json
   ```

5. **Try verbose mode:**
   ```bash
   product-agent discover --idea "test" --verbose
   ```

6. **Check for updates:**
   ```bash
   product-agent --version
   ```

## Future Agents

Coming soon (update this Skill when available):

### MVP Scoping Agent
```bash
product-agent scope \
  --problem-file problem.json \
  --output-format json
```

### Positioning Agent
```bash
product-agent position \
  --mvp-file mvp.json \
  --output-format json
```

### ASO Optimization Agent
```bash
product-agent aso \
  --app-description "..." \
  --output-format json
```

### Launch Planning Agent
```bash
product-agent launch \
  --positioning-file positioning.json \
  --output-format json
```

## File Extension Auto-Detection

When using `--save`, the tool automatically adds the correct extension:

| Format | Extension | Example |
|--------|-----------|---------|
| text | .txt | analysis.txt |
| json | .json | analysis.json |
| markdown | .md | analysis.md |

**Example:**
```bash
--output "report" --output-format markdown
# Creates: report.md (not report.markdown)
```

## Best Practices Summary

1. **Always use JSON format** for analysis and chaining
2. **Read the recommendation field first** - it's the most important
3. **Save important analyses** - build a knowledge base
4. **Provide platform and target user** when known
5. **Trust "don't build" verdicts** - the agent is honest
6. **Use verbose mode for debugging**
7. **Compare multiple ideas** before committing
8. **Share markdown reports** with stakeholders
9. **Batch process** when validating many ideas
10. **Stay in development mode** unless you need production features

---

For questions or issues, refer to the main documentation or file an issue on GitHub.
