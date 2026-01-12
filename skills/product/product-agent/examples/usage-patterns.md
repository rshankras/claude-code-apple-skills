# Common Usage Patterns

This document shows real-world workflows for using Product Agent effectively.

## Pattern 1: Quick Idea Validation

**Use Case:** You have a single app idea and want quick validation before investing time.

**Workflow:**
```bash
product-agent discover \
  --idea "Markdown editor with AI writing assistance" \
  --output-format json
```

**What to Check:**
1. `severity_score` - Is it 6+?
2. `opportunity` - Does it say "STRONG" or "MODERATE"?
3. `recommendation` - Does it say "BUILD" or "PROCEED WITH CAUTION"?

**Decision Making:**
- **Score 7+, STRONG opportunity, BUILD verdict** → Green light
- **Score 4-6, MODERATE opportunity, CAUTION verdict** → Needs differentiation strategy
- **Score <4, WEAK opportunity, DON'T BUILD verdict** → Red light

**Time:** 30 seconds to analyze results

---

## Pattern 2: Comparing Multiple Ideas

**Use Case:** You have 3-5 ideas and want to pick the best one.

**Workflow:**
```bash
# Run discovery on each idea
ideas=(
  "AI calendar optimizer"
  "Developer productivity tracker"
  "Focus mode app for macOS"
)

for idea in "${ideas[@]}"; do
  slug=$(echo "$idea" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  product-agent discover \
    --idea "$idea" \
    --output-format json \
    --save \
    --output "analysis-$slug"
done
```

**Analysis:**
```bash
# Extract scores
for file in analysis-*.json; do
  echo "$file:"
  jq -r '.severity_score, .opportunity' "$file"
  echo "---"
done
```

**Compare:**
1. Severity scores (higher = better)
2. Opportunity assessments (STRONG > MODERATE > WEAK)
3. Recommendation verdicts
4. Current solutions (fewer/weaker competitors = better)

**Time:** 2 minutes setup + 30 seconds per idea

---

## Pattern 3: Deep Market Analysis

**Use Case:** You're serious about an idea and want comprehensive analysis.

**Workflow:**
```bash
product-agent discover \
  --idea "Task manager with AI auto-prioritization based on context" \
  --platform "iOS/macOS" \
  --target-user "busy professionals juggling multiple projects" \
  --output-format json \
  --verbose \
  --save \
  --output "deep-analysis-taskmanager"
```

**Review Checklist:**
- [ ] Read complete `recommendation` (all paragraphs)
- [ ] Analyze all `pain_points` (are they real?)
- [ ] Research each item in `current_solutions` (visit websites)
- [ ] Verify `opportunity` assessment (do independent research)
- [ ] Consider `frequency` (daily = good, weekly = less urgent)
- [ ] Look for patterns (multiple competitors = saturated)

**Follow-up Questions:**
1. What specific differentiation is needed?
2. Can we serve a niche the competitors don't?
3. What would make this 10x better, not 10% better?

**Time:** 5 minutes analysis + 30 minutes research

---

## Pattern 4: Stakeholder Presentation

**Use Case:** Need to present findings to team/stakeholders.

**Workflow:**
```bash
# Generate markdown report
product-agent discover \
  --idea "Your validated idea" \
  --platform "iOS/macOS" \
  --target-user "specific persona" \
  --output-format markdown \
  --save \
  --output "stakeholder-presentation"
```

**Creates:** `stakeholder-presentation.md` with:
- Problem statement
- Target users
- Severity score
- Pain points (bullet list)
- Competitive landscape
- Market opportunity
- Recommendation with reasoning

**Present:**
1. Share the markdown file
2. Walk through key sections
3. Focus on recommendation and opportunity
4. Discuss risks and mitigation

**Time:** 2 minutes to generate + 15 minutes to present

---

## Pattern 5: Iterative Refinement

**Use Case:** Initial analysis suggests "don't build", but you want to explore pivots.

**Initial Analysis:**
```bash
product-agent discover \
  --idea "Note-taking app for quick capture" \
  --output-format json

# Result: "DO NOT BUILD - market saturated"
```

**Refinement Strategy:**

Try narrower niches:
```bash
# Pivot 1: Specific use case
product-agent discover \
  --idea "Note-taking app specifically for academic research with citation management" \
  --target-user "graduate students and researchers" \
  --output-format json

# Pivot 2: Different target market
product-agent discover \
  --idea "Voice-first note capture for field workers who can't use keyboards" \
  --target-user "construction site managers and field technicians" \
  --output-format json

# Pivot 3: Unique workflow
product-agent discover \
  --idea "Notes that auto-organize into project contexts using AI" \
  --target-user "consultants managing multiple client projects" \
  --output-format json
```

**Look for:**
- Severity score improving (4+ → 6+)
- Opportunity changing (WEAK → MODERATE)
- Fewer/weaker competitors in niche
- More specific pain points

**Time:** 30 minutes for 3-4 pivots

---

## Pattern 6: Batch Processing from File

**Use Case:** You have a list of ideas to validate.

**Setup:**
Create `ideas.txt`:
```
Password manager for Apple ecosystem
AI calendar scheduling assistant
Focus timer with analytics
Developer time tracking tool
Markdown editor with AI
```

**Workflow:**
```bash
#!/bin/bash

while IFS= read -r idea; do
  # Create slug from idea
  slug=$(echo "$idea" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 40)

  echo "Analyzing: $idea"

  product-agent discover \
    --idea "$idea" \
    --output-format json \
    --save \
    --output "batch-$slug"

  echo "---"
done < ideas.txt

echo "All analyses complete. Files: batch-*.json"
```

**Aggregate Results:**
```bash
# Create summary
for file in batch-*.json; do
  echo "File: $file"
  jq -r '{
    idea: .problem_statement[:50] + "...",
    score: .severity_score,
    opportunity: .opportunity[:30] + "...",
    verdict: .recommendation[:50] + "..."
  }' "$file"
  echo "---"
done > summary.txt
```

**Time:** 30 seconds per idea + 2 minutes for summary

---

## Pattern 7: Integration with Project Management

**Use Case:** Validate idea before creating project tickets.

**Workflow:**
```bash
# 1. Validate idea
result=$(product-agent discover \
  --idea "$PROPOSED_FEATURE" \
  --output-format json)

# 2. Check verdict
verdict=$(echo "$result" | jq -r '.recommendation')

# 3. Decision point
if [[ "$verdict" == *"DO NOT BUILD"* ]]; then
  echo "Idea not validated. Stopping."
  echo "$verdict"
  exit 1
fi

# 4. Extract insights for tickets
echo "$result" | jq -r '.pain_points[]' > user-stories.txt

echo "Idea validated. User stories extracted to user-stories.txt"
# Proceed with creating GitHub issues, Jira tickets, etc.
```

**Time:** Automated (30 seconds)

---

## Pattern 8: Continuous Validation

**Use Case:** Re-validate ideas periodically as market changes.

**Setup:**
```bash
# Create tracking directory
mkdir product-validations
cd product-validations
```

**Monthly Validation:**
```bash
#!/bin/bash
DATE=$(date +%Y-%m)

product-agent discover \
  --idea "Your product idea" \
  --output-format json \
  --save \
  --output "validation-$DATE"

# Compare with last month
if [ -f "validation-last-month.json" ]; then
  echo "Comparing with last month..."
  diff validation-last-month.json "validation-$DATE.json"
fi

ln -sf "validation-$DATE.json" validation-last-month.json
```

**Look for Changes:**
- Severity score trends (improving/degrading)
- New competitors in `current_solutions`
- Opportunity shifts (MODERATE → STRONG)
- Recommendation changes

**Time:** 2 minutes per month

---

## Pattern 9: Team Brainstorming Session

**Use Case:** Team meeting to validate multiple ideas quickly.

**Live Session:**
```bash
# As ideas come up, validate in real-time
alias validate='product-agent discover --output-format json --idea'

# During meeting
validate "Team member idea 1" | jq -r '.recommendation' | head -3
validate "Team member idea 2" | jq -r '.recommendation' | head -3
validate "Team member idea 3" | jq -r '.recommendation' | head -3
```

**Post-Meeting:**
```bash
# Save promising ideas for deep analysis
for idea in "${promising_ideas[@]}"; do
  product-agent discover \
    --idea "$idea" \
    --output-format markdown \
    --save
done
```

**Time:** 30 seconds per idea (live)

---

## Pattern 10: Documentation for Decisions

**Use Case:** Document why you chose/rejected an idea.

**Workflow:**
```bash
# For accepted ideas
product-agent discover \
  --idea "$ACCEPTED_IDEA" \
  --output-format markdown \
  --save \
  --output "decision-accepted-${PROJECT_NAME}"

# For rejected ideas
product-agent discover \
  --idea "$REJECTED_IDEA" \
  --output-format markdown \
  --save \
  --output "decision-rejected-${PROJECT_NAME}"
```

**Add to Git:**
```bash
git add decisions/
git commit -m "docs: document product validation for ${PROJECT_NAME}"
```

**Benefit:**
- Historical record of decision rationale
- Reference for future similar ideas
- Onboarding for new team members

**Time:** 5 minutes

---

## Anti-Patterns (Don't Do This)

### ❌ Ignoring "Don't Build" Recommendations

**Bad:**
```
Agent says: "DO NOT BUILD - saturated market"
You: "But I'll make mine simpler!"
```

**Why it fails:** Agent analyzed the market. If it says don't build, there's usually a very good reason.

### ❌ Not Reading the Full Recommendation

**Bad:**
```
Check severity_score: 7/10
Conclusion: "Great, let's build!"
```

**Why it fails:** Score alone doesn't tell the story. Read the full `recommendation` field.

### ❌ Using Text Format for Analysis

**Bad:**
```bash
product-agent discover --idea "..." --output-format text
```

**Why suboptimal:** Text is for humans. Use JSON for analysis and processing.

### ❌ Not Providing Context

**Bad:**
```bash
product-agent discover --idea "Task app"
```

**Better:**
```bash
product-agent discover \
  --idea "Task manager with AI auto-prioritization and calendar integration" \
  --platform "iOS" \
  --target-user "busy professionals"
```

**Why:** More context = better analysis.

### ❌ Building Despite Weak Validation

**Bad:**
```
Result: Severity 3/10, WEAK opportunity, "DO NOT BUILD"
Decision: "Let's build it anyway as a learning project"
```

**Why it fails:** If it's a learning project, fine. But don't expect commercial success.

---

## Quick Reference

| Goal | Command Pattern |
|------|-----------------|
| Quick validation | `--idea "..." --output-format json` |
| Deep analysis | Add `--platform`, `--target-user`, `--verbose` |
| Comparison | Loop with `--save` and unique output names |
| Presentation | `--output-format markdown` |
| Automation | Use JSON + jq for parsing |
| Documentation | `--save --output descriptive-name` |

---

## Success Metrics

Track your validation success:
- **Ideas validated:** Count total discoveries
- **Ideas rejected:** Count "DON'T BUILD" verdicts
- **Time saved:** Rejected ideas * avg build time
- **Success rate:** (Shipped products / Validated ideas) * 100

**Example:**
- 20 ideas validated
- 15 rejected by agent
- Average build time: 3 months
- Time saved: 15 * 3 = 45 months of wasted effort prevented!

---

**Remember:** Product Agent saves you time by being brutally honest. Trust the analysis.
