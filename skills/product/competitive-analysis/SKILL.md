---
name: competitive-analysis
description: Deep competitive analysis for iOS/macOS apps including feature comparison, pricing analysis, strengths/weaknesses, market positioning, and differentiation opportunities. Use when user asks for competitive analysis, competitor research, feature comparison, market positioning, or wants to understand competition in detail.
allowed-tools: Bash(product-agent:*), Read, WebSearch, WebFetch
---

# Competitive Analysis Skill

Performs deep competitive analysis for iOS/macOS app ideas. Goes beyond basic discovery to provide detailed competitor insights, feature matrices, and differentiation opportunities.

## When to Use This Skill

Use this Skill when the user wants to:
- Understand competitors in detail
- Compare features across competitors
- Analyze competitor pricing strategies
- Identify competitive strengths/weaknesses
- Find differentiation opportunities
- Map market positioning
- Deep-dive after initial problem discovery

**This is a follow-up to product-agent discovery** - use this when you need more competitive depth.

## What This Skill Does

### 1. Competitor Identification
- Identifies direct and indirect competitors
- Categorizes by market position (leaders, challengers, niche)
- Includes App Store rankings and ratings

### 2. Feature Comparison
- Creates feature comparison matrix
- Identifies unique features per competitor
- Highlights feature gaps (opportunities)

### 3. Pricing Analysis
- Compares pricing models (free, paid, subscription, freemium)
- Analyzes price points
- Identifies pricing strategies

### 4. SWOT Analysis
- Strengths of each competitor
- Weaknesses and limitations
- Opportunities for differentiation
- Threats to new entrants

### 5. Market Positioning
- How competitors position themselves
- Target audience differences
- Brand messaging analysis

### 6. Differentiation Strategy
- **Key output:** How to be different
- Feature gaps in market
- Underserved user segments
- Unique value propositions

## How to Use

### Basic Usage

For competitive analysis, construct a detailed prompt and use product-agent's general capabilities combined with web research:

```bash
# The approach: Use product-agent discover for baseline,
# then enhance with web research
product-agent discover \
  --idea "IDEA_DESCRIPTION - focus on competitive landscape" \
  --output-format json
```

**Then enhance with web research** using WebSearch and WebFetch tools to:
- Visit competitor websites
- Check App Store listings
- Analyze pricing pages
- Review feature documentation

### Workflow

1. **Start with discovery** to identify competitors:
   ```bash
   product-agent discover --idea "YOUR_IDEA" --output-format json
   ```
   Extract the `current_solutions` field for competitor list.

2. **Research each competitor** using WebSearch/WebFetch:
   - Search for "[competitor name] app features"
   - Search for "[competitor name] pricing"
   - Fetch their App Store page
   - Fetch their website

3. **Create comparison matrix** from gathered data

4. **Identify differentiation opportunities** based on gaps

## Output Structure

When performing competitive analysis, create this structure:

```json
{
  "competitors": [
    {
      "name": "Competitor Name",
      "category": "market_leader | challenger | niche",
      "app_store_rating": "4.5/5",
      "downloads": "estimated range",
      "pricing": {
        "model": "subscription | one-time | freemium",
        "price": "$X/month or $Y one-time",
        "tiers": ["free", "pro", "business"]
      },
      "key_features": [
        "Feature 1",
        "Feature 2"
      ],
      "unique_features": [
        "Feature only they have"
      ],
      "strengths": [
        "What they do well"
      ],
      "weaknesses": [
        "What they lack or do poorly"
      ],
      "target_audience": "Who they target",
      "positioning": "How they position themselves"
    }
  ],
  "feature_matrix": {
    "Feature A": {"Competitor1": true, "Competitor2": false, "Competitor3": true},
    "Feature B": {"Competitor1": false, "Competitor2": true, "Competitor3": true}
  },
  "feature_gaps": [
    "Feature nobody offers well",
    "Feature with poor implementation across board"
  ],
  "pricing_insights": {
    "average_price": "$X",
    "pricing_range": "$Y - $Z",
    "common_model": "subscription",
    "pricing_gaps": ["No good free tier", "No lifetime option"]
  },
  "differentiation_opportunities": [
    {
      "opportunity": "AI-powered feature X",
      "reasoning": "None of the competitors do this well",
      "potential_impact": "high | medium | low"
    }
  ],
  "market_positioning_map": {
    "axes": ["Price (low to high)", "Features (simple to complex)"],
    "competitors": [
      {"name": "Competitor1", "position": [3, 8]},
      {"name": "Competitor2", "position": [8, 9]}
    ],
    "opportunity_quadrant": "Low price, high features"
  },
  "recommendation": "Strategic positioning recommendation"
}
```

## Best Practices

### 1. Start Broad, Then Focus

```
Step 1: Use product-agent discover to identify competitors
Step 2: Pick top 3-5 most relevant competitors
Step 3: Deep dive on each using web research
Step 4: Create comparison matrix
```

### 2. Look Beyond Direct Competitors

Include:
- **Direct competitors:** Same problem, same solution
- **Indirect competitors:** Same problem, different solution
- **Alternative solutions:** How users solve this today without apps

### 3. Focus on Actionable Insights

Don't just list features. Answer:
- **What can we do better?**
- **What gaps exist?**
- **Where can we differentiate?**

### 4. Verify with App Store Data

When analyzing iOS/macOS apps:
- Check App Store ratings
- Read recent reviews (last 3 months)
- Note update frequency
- Check developer responsiveness

### 5. Pricing Intelligence

Understand:
- How competitors monetize
- What features are behind paywall
- Trial periods and refund policies
- Upgrade paths

## Example Analysis Flow

**User asks:** "Do competitive analysis for task management apps"

**You do:**

1. **Initial Discovery**
   ```bash
   product-agent discover \
     --idea "Task management app with AI prioritization" \
     --output-format json
   ```

   Result: Identifies Todoist, Things, OmniFocus, TickTick as main competitors

2. **Deep Research Each Competitor**

   For Todoist:
   - WebSearch: "Todoist features list 2026"
   - WebFetch: https://todoist.com/features
   - WebSearch: "Todoist pricing 2026"
   - WebFetch: https://todoist.com/pricing
   - WebSearch: "Todoist app store reviews"

   Repeat for Things, OmniFocus, TickTick

3. **Create Feature Matrix**

   | Feature | Todoist | Things | OmniFocus | TickTick |
   |---------|---------|--------|-----------|----------|
   | Subtasks | ✓ | ✓ | ✓ | ✓ |
   | AI Prioritization | ✗ | ✗ | ✗ | ✗ |
   | Calendar Integration | ✓ | ✓ | ✓ | ✓ |
   | Natural Language Input | ✓ | ✗ | ✗ | ✓ |

4. **Identify Gaps**
   - AI prioritization: Nobody does it well
   - Smart scheduling: Limited implementations
   - Context-aware suggestions: Missing entirely

5. **Present Findings**
   ```
   Competitive Analysis: Task Management Apps

   **Top 4 Competitors:**
   1. Todoist (Market Leader) - $4/mo, strong features, weak AI
   2. Things (Premium) - $50 one-time, beautiful UI, limited power features
   3. OmniFocus (Power Users) - $100 one-time, complex, steep learning curve
   4. TickTick (Budget) - $2/mo, feature-rich, less polished

   **Feature Gaps (Opportunities):**
   1. AI-powered prioritization - None do this well
   2. Context-aware task suggestions - Missing
   3. Smart deadline suggestions - Limited

   **Differentiation Strategy:**
   Position as "AI-first task manager" with:
   - Automatic prioritization based on context
   - Smart deadline suggestions
   - Learning from user behavior

   **Pricing Recommendation:**
   $3-4/month (between TickTick and Todoist)
   Free tier with core features to build user base
   ```

## Common Pitfalls to Avoid

### ❌ Don't Just List Competitors
```
Bad: "Competitors are Todoist, Things, OmniFocus"
Good: "Todoist leads with 30% market share at $4/mo, strong in
      collaboration but weak in AI features..."
```

### ❌ Don't Ignore Indirect Competition
```
Bad: Only analyzing dedicated task apps
Good: Also include: Notion (general productivity), Apple Reminders
      (free built-in), pen and paper (no-tech solution)
```

### ❌ Don't Skip Pricing Analysis
```
Bad: "They have a subscription"
Good: "Freemium model with $4/mo premium. 70% on free tier,
      30% convert to paid. Premium unlocks collaboration and integrations."
```

### ❌ Don't Forget the "So What?"
```
Bad: "Competitor X has feature Y"
Good: "Competitor X has feature Y, but it's poorly implemented
      (3.2/5 rating in reviews). This is an opportunity to do it better."
```

## Integration with Other Skills

This Skill works best **after** using the main product-agent Skill:

```
1. product-agent discover → Quick validation
2. competitive-analysis → Deep competitor insights
3. market-research → Market size and opportunity
4. MVP scoping → What to build based on competitive gaps
```

## Tips for Effective Analysis

1. **Recent Data Only**: Focus on 2025-2026 data. Old reviews don't matter.

2. **User Voice**: Read actual user reviews. What do they complain about? What do they love?

3. **Pricing Psychology**: Don't just note prices. Understand the strategy:
   - Freemium = land and expand
   - One-time = premium positioning
   - Subscription = recurring revenue focus

4. **Feature vs. Benefit**: Map features to benefits:
   - "Subtasks" = Benefit: "Break big tasks into manageable steps"

5. **Market Position**: Understand where you fit:
   - Cheaper? Position as "affordable alternative"
   - Better? Position as "premium experience"
   - Simpler? Position as "easy to use"
   - Different? Position as "unique approach"

## When to Run This Analysis

**Perfect timing:**
- After initial discovery shows "MODERATE" or "STRONG" opportunity
- Before starting development (validate differentiation strategy)
- When planning features (fill competitive gaps)
- Before pricing decisions (market rate analysis)
- When pitching to investors (competitive landscape)

**Too early:**
- Before basic discovery (use product-agent discover first)
- If discovery said "DON'T BUILD" (no point analyzing dead market)

**Too late:**
- After building MVP without checking competition (too late to differentiate)
- After pricing decision (should inform pricing)

## Deliverables

After running competitive analysis, you should have:

1. ✅ List of 3-5 main competitors with details
2. ✅ Feature comparison matrix
3. ✅ Pricing comparison table
4. ✅ SWOT for each competitor
5. ✅ 3-5 differentiation opportunities identified
6. ✅ Positioning recommendation
7. ✅ Pricing strategy recommendation

## Output File Location

Save competitive analysis results to one of these locations:
- `competitive-analysis.md` (project root)
- `docs/competitive-analysis.md` (if docs folder exists)

**Format**: Use the JSON structure in the Output Structure section, wrapped in a markdown code block.

**Integration**: The PRD generator skill will automatically look for this file and integrate the insights into the PRD's Competitive Context section.

## Follow-up Actions

Based on competitive analysis, next steps:

**If gaps found:**
- Proceed with MVP scoping
- Design features that fill gaps
- Position around differentiation

**If no clear gaps:**
- Consider pivoting idea
- Target different user segment
- Explore adjacent market

**If too competitive:**
- Find niche within market
- Bundle with other features
- Or abandon and try different idea

---

**Remember:** Competitive analysis should lead to action. The goal is not to document competitors, but to find your **unique wedge** into the market.
