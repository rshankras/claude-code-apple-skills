# Common Usage Patterns

This document shows real-world workflows for using the Product Agent skill effectively.

## Pattern 1: Quick Idea Validation

**Use Case:** You have a single app idea and want quick validation before investing time.

**What to do:** Provide the idea and let the skill run its analysis.

**What to Check:**
1. `severity_score` — Is it 6+?
2. `opportunity` — Does it say "STRONG" or "MODERATE"?
3. `recommendation` — Does it say "BUILD" or "PROCEED WITH CAUTION"?

**Decision Making:**
- **Score 7+, STRONG opportunity, BUILD verdict** — Green light
- **Score 4-6, MODERATE opportunity, CAUTION verdict** — Needs differentiation strategy
- **Score <4, WEAK opportunity, DON'T BUILD verdict** — Red light

---

## Pattern 2: Comparing Multiple Ideas

**Use Case:** You have 3-5 ideas and want to pick the best one.

**What to do:** Run discovery on each idea, then compare:
- Severity scores (higher = better)
- Opportunity assessments (STRONG > MODERATE > WEAK)
- Recommendation verdicts
- Current solutions (fewer/weaker competitors = better)

**Example:**
```
Idea A: Severity 7/10, STRONG, BUILD
Idea B: Severity 4/10, WEAK, DON'T BUILD
Idea C: Severity 6/10, MODERATE, PROCEED WITH CAUTION

Winner: Idea A (clear green light)
```

---

## Pattern 3: Deep Market Analysis

**Use Case:** You're serious about an idea and want comprehensive analysis.

**What to do:**
1. Run product-agent discovery with detailed context (platform, target user)
2. Follow up with **competitive-analysis** skill for competitor deep-dive
3. Follow up with **market-research** skill for TAM/SAM/SOM

**Review Checklist:**
- [ ] Read complete `recommendation` (all paragraphs)
- [ ] Analyze all `pain_points` (are they real?)
- [ ] Research each item in `current_solutions` (visit websites)
- [ ] Verify `opportunity` assessment (do independent research)
- [ ] Consider `frequency` (daily = good, weekly = less urgent)

---

## Pattern 4: Iterative Refinement

**Use Case:** Initial analysis suggests "don't build", but you want to explore pivots.

**Example flow:**

**Initial idea:** "Note-taking app for quick capture"
**Result:** "DO NOT BUILD — market saturated"

**Pivot attempts:**
1. "Note-taking app specifically for academic research with citation management" (targeting researchers)
2. "Voice-first note capture for field workers who can't use keyboards" (different use case)
3. "Notes that auto-organize into project contexts using AI" (unique workflow)

**Look for:**
- Severity score improving (4+ to 6+)
- Opportunity changing (WEAK to MODERATE)
- Fewer/weaker competitors in the niche
- More specific pain points

---

## Pattern 5: Stakeholder Presentation

**Use Case:** Need to present findings to team/stakeholders.

**What to do:**
1. Run discovery analysis
2. Save the JSON output
3. Create a summary highlighting:
   - Problem statement
   - Severity score
   - Key competitors
   - Market opportunity
   - Recommendation with reasoning

**Present:**
1. Walk through key sections
2. Focus on recommendation and opportunity
3. Discuss risks and mitigation

---

## Pattern 6: Documentation for Decisions

**Use Case:** Document why you chose/rejected an idea.

**What to do:**
1. Run analysis for each idea considered
2. Save results alongside your project documentation
3. Include both accepted and rejected ideas with reasoning

**Benefit:**
- Historical record of decision rationale
- Reference for future similar ideas
- Onboarding for new team members

---

## Anti-Patterns (Don't Do This)

### Ignoring "Don't Build" Recommendations

**Bad:** Agent says "DO NOT BUILD — saturated market." You think "But I'll make mine simpler!"

**Why it fails:** The analysis considered the market. If it says don't build, there's usually a very good reason.

### Not Reading the Full Recommendation

**Bad:** Check severity_score (7/10) and conclude "Great, let's build!"

**Why it fails:** Score alone doesn't tell the story. Read the full `recommendation` field.

### Not Providing Context

**Bad:** "Task app"

**Better:** "Task manager with AI auto-prioritization and calendar integration for busy professionals on iOS"

**Why:** More context = better analysis.

### Building Despite Weak Validation

**Bad:** Severity 3/10, WEAK opportunity, "DO NOT BUILD" — but you build anyway.

**Why it fails:** If it's a learning project, fine. But don't expect commercial success.

---

## Quick Reference

| Goal | Approach |
|------|----------|
| Quick validation | Provide idea, check recommendation and severity |
| Deep analysis | Add platform, target user, then use competitive-analysis and market-research skills |
| Compare ideas | Run analysis on each, compare scores and opportunities |
| Refine idea | If "don't build", try narrower niches or different angles |
| Present findings | Save JSON, create summary for stakeholders |
| Document decisions | Save analysis for both accepted and rejected ideas |

---

**Remember:** Product Agent saves you time by being brutally honest. Trust the analysis.
