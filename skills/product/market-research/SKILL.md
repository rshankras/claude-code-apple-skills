---
name: market-research
description: Deep market analysis for iOS/macOS apps including market sizing (TAM/SAM/SOM), growth trends, market maturity, entry barriers, distribution channels, and revenue potential. Use when user asks for market research, market size, market opportunity, growth potential, TAM/SAM/SOM, or market trends.
allowed-tools: Bash(product-agent:*), Read, WebSearch, WebFetch
---

# Market Research Skill

Performs deep market research for iOS/macOS app ideas. Provides market sizing, growth analysis, and opportunity assessment.

## When to Use This Skill

Use this Skill when the user wants to:
- Understand market size and potential
- Analyze market growth trends
- Calculate TAM/SAM/SOM
- Assess market maturity
- Identify entry barriers
- Understand distribution channels
- Estimate revenue potential
- Deep-dive after initial problem discovery

**This is a follow-up to product-agent discovery** - use this when you need market depth.

## What This Skill Does

### 1. Market Sizing (TAM/SAM/SOM)

- **TAM (Total Addressable Market):** Total revenue opportunity if you captured 100% of the market
- **SAM (Serviceable Available Market):** Segment of TAM you can reach with your product/distribution
- **SOM (Serviceable Obtainable Market):** Realistic share you can capture in near term (1-3 years)

### 2. Growth Analysis
- Historical growth rates
- Future projections (3-5 years)
- Growth drivers
- Market trends

### 3. Market Maturity Assessment
- Stage: Emerging, Growing, Mature, or Declining
- Market lifecycle position
- Implications for new entrants

### 4. Entry Barriers
- Technical barriers
- Brand/network effects
- Regulatory requirements
- Capital requirements
- Customer acquisition costs

### 5. Distribution Channels
- How apps in this category reach users
- App Store dynamics
- Alternative channels (web, enterprise, etc.)

### 6. Revenue Potential
- Average revenue per user (ARPU)
- Conversion rates
- LTV (Lifetime Value)
- Revenue models in use

## Output Structure

```json
{
  "market_category": "Task Management",
  "market_sizing": {
    "tam": {
      "value": "$4.5B",
      "description": "Global productivity software market",
      "methodology": "Total potential revenue if product served all users globally"
    },
    "sam": {
      "value": "$900M",
      "description": "iOS/macOS task management apps (20% of TAM)",
      "methodology": "Addressable via App Store distribution on Apple platforms"
    },
    "som": {
      "value": "$45M",
      "description": "Realistic 3-year capture (5% of SAM)",
      "methodology": "Based on typical indie app market share penetration"
    }
  },
  "market_growth": {
    "historical_growth": "12% CAGR (2021-2025)",
    "projected_growth": "10% CAGR (2026-2030)",
    "growth_drivers": [
      "Remote work adoption",
      "Increased digital task management",
      "Mobile-first workflows"
    ],
    "headwinds": [
      "Market saturation",
      "Consolidation toward major players"
    ]
  },
  "market_maturity": {
    "stage": "Mature",
    "characteristics": [
      "Established leaders (Todoist, Things)",
      "Clear product categories",
      "Slowing growth rate",
      "Focus on feature differentiation"
    ],
    "implications": "Differentiation critical. Hard to compete on basics. Must have unique angle."
  },
  "entry_barriers": {
    "low": [
      "Technical implementation (task management is straightforward)"
    ],
    "medium": [
      "Building user base in crowded market",
      "Achieving reliable sync across devices"
    ],
    "high": [
      "Brand recognition (Todoist, Things have 10+ years)",
      "Network effects (team collaboration features)",
      "Customer switching costs (data lock-in)"
    ],
    "overall_assessment": "Medium-High - Technical execution is achievable, but market position is difficult"
  },
  "distribution_channels": {
    "primary": {
      "channel": "App Store",
      "percentage": "75%",
      "dynamics": "Discoverability challenging. ASO critical. Top charts dominated by established apps."
    },
    "secondary": [
      {
        "channel": "Direct website",
        "percentage": "15%",
        "dynamics": "For power users. Allows higher pricing. Better for subscription retention."
      },
      {
        "channel": "Word of mouth / Communities",
        "percentage": "10%",
        "dynamics": "Productivity communities, Reddit, Twitter. High-intent users."
      }
    ]
  },
  "revenue_potential": {
    "arpu": {
      "freemium": "$12/year (5% convert at $20/year)",
      "paid_only": "$30-40/year",
      "premium": "$60-100/year"
    },
    "conversion_rates": {
      "free_to_paid": "3-7% industry average",
      "trial_to_paid": "15-25% with 14-day trial"
    },
    "ltv": "$150-300 (2-5 year user lifecycle)",
    "realistic_year_1": "$50K-200K (1K-5K users at $40 ARPU)",
    "realistic_year_3": "$500K-2M (10K-50K users with growth)",
    "path_to_scale": "Requires strong differentiation, word-of-mouth growth, and retention >85%"
  },
  "market_opportunity_score": "6/10 - Moderate",
  "reasoning": "Large market with growth, but mature and competitive. Success requires clear differentiation and excellent execution. Not a 'gold rush' market, but sustainable business possible for well-positioned product."
}
```

## How to Perform Market Research

### Step 1: Define Market Scope

```
Question: What exact market are you analyzing?
- "Task management apps" (broad)
- "iOS task management apps" (narrower)
- "AI-powered task management for Apple users" (specific)

Start specific for better analysis.
```

### Step 2: Size the Market (TAM/SAM/SOM)

**TAM Calculation:**
```
Method 1: Top-down
- Global productivity software market: $50B
- Task management segment: ~10% = $5B TAM

Method 2: Bottom-up
- Potential users globally: 500M knowledge workers
- Willing to pay for task management: 20% = 100M
- Average spend: $50/year
- TAM = 100M × $50 = $5B
```

**SAM Calculation:**
```
Filter TAM by what you can reach:
- TAM: $5B global
- Your distribution: iOS/macOS App Store only
- Apple users: ~30% of market = $1.5B
- Addressable via App Store: 60% = $900M SAM
```

**SOM Calculation:**
```
Realistic capture in 3 years:
- SAM: $900M
- New entrant market share: 0.5-2% realistic
- With strong differentiation: 5% optimistic
- SOM = $900M × 1-5% = $9M-45M
```

### Step 3: Assess Growth

Use WebSearch to find:
- Market research reports
- Growth rate data
- Trend articles

**Key searches:**
```
"[category] market size 2026"
"[category] growth rate"
"[category] market trends 2026"
```

### Step 4: Determine Maturity

**Indicators:**

**Emerging** (Good for new entrants):
- High growth (>20% CAGR)
- No clear leaders
- Rapid innovation
- Unclear best practices

**Growing** (Good opportunity):
- Strong growth (10-20% CAGR)
- Leaders emerging
- Product-market fit established
- Room for differentiation

**Mature** (Differentiation required):
- Moderate growth (5-10% CAGR)
- Clear leaders
- Established patterns
- Compete on specific niches

**Declining** (Avoid):
- Negative or flat growth
- Consolidation
- Commoditization

### Step 5: Identify Barriers

**Low barriers → Easier entry but more competition**
**High barriers → Harder entry but better moat if you succeed**

Assess:
- Technical complexity
- Brand importance
- Network effects
- Switching costs
- Capital needs

### Step 6: Map Distribution

**For iOS/macOS apps:**
- App Store (primary) - understand ranking factors
- TestFlight (beta)
- Direct website (for pro users)
- SetApp / Bundle services
- Enterprise/B2B channels

### Step 7: Estimate Revenue

**Key metrics to research:**
- Industry ARPU
- Typical conversion rates
- Churn rates
- User acquisition costs

**Reality check:**
```
Year 1: 1K-5K users (realistic for indie)
Year 2: 5K-20K users (with growth)
Year 3: 20K-100K users (if successful)

At $40 ARPU:
Year 1: $40K-200K
Year 2: $200K-800K
Year 3: $800K-4M
```

## Common Questions

### "How do I calculate TAM without market reports?"

**Bottom-up approach:**
1. Estimate target user count (e.g., "iOS users who manage tasks")
2. Research willingness to pay (look at competitor pricing)
3. Multiply: TAM = Users × Average Spend

**Proxy approach:**
1. Find similar market (e.g., "Calendar apps")
2. Adjust for your market differences
3. Validate with multiple sources

### "What's a 'good' market size?"

**For indie developers:**
- **SOM > $5M:** Good opportunity
- **SOM $1-5M:** Viable if low competition
- **SOM < $1M:** Likely too small unless niche/passion project

**Remember:** $1M SOM = ~25K users at $40 ARPU (achievable!)

### "How mature is too mature?"

**Mature markets CAN work if:**
- You have clear differentiation
- Targeting underserved niche
- Better execution than incumbents
- Novel business model

**Avoid if:**
- No differentiation angle
- Dominant players with network effects
- Declining growth
- Your idea is "me too"

## Integration with Other Skills

Use market-research **after** initial discovery:

```
1. product-agent discover → Problem validation
2. market-research → Market opportunity sizing
3. competitive-analysis → Understand players
4. → Decision: Build vs. Don't Build
```

## Example Research Flow

**User asks:** "Research the market for habit tracking apps"

**You do:**

1. **Define scope:**
   - "iOS habit tracking apps targeting personal development users"

2. **Calculate TAM/SAM/SOM:**
   - TAM: Personal development app market $3B
   - SAM: iOS habit tracking apps $300M (10%)
   - SOM: Realistic 3-year capture $15M (5%)

3. **Growth analysis (WebSearch):**
   - Search: "habit tracking app market growth 2026"
   - Result: 15% CAGR, driven by wellness trends

4. **Maturity:**
   - Stage: Growing (strong leaders emerging but room for innovation)
   - Key players: Streaks, Habitica, Way of Life

5. **Barriers:**
   - Low: Technical (habit tracking is simple)
   - Medium: Building habit formation psychology
   - High: Established apps have user data (switching cost)

6. **Distribution:**
   - App Store: 80% (ASO critical)
   - Wellness communities: 15%
   - Influencer partnerships: 5%

7. **Revenue potential:**
   - ARPU: $20/year (mix of $2.99 one-time and $5/mo subscriptions)
   - Year 3 realistic: $300K (15K users)

8. **Present findings:**
   ```
   Market Research: Habit Tracking Apps

   Market Size:
   - TAM: $3B (personal development apps)
   - SAM: $300M (iOS habit tracking)
   - SOM: $15M (5% realistic 3-year capture)

   Growth: 15% CAGR (wellness trend-driven)
   Maturity: Growing (opportunity for innovation)

   Opportunity Score: 7/10 - Good

   Reasoning: Growing market with room for differentiation.
   Not overcrowded like task management. Wellness trend tailwind.
   Success depends on unique habit formation approach and
   strong retention (>70%).

   Revenue Potential:
   - Year 1: $20K-100K
   - Year 3: $200K-1M
   - Requires: Good ASO, word-of-mouth, community building
   ```

## Tips for Accurate Research

1. **Use Multiple Sources:** Don't rely on one number
2. **Be Conservative:** Better to underestimate than over
3. **Validate with Proxies:** Compare to similar successful apps
4. **Check App Annie/Sensor Tower:** For actual app market data
5. **Read Financial Reports:** Public companies disclose market data

## When to Run This Analysis

**Perfect timing:**
- After discovery shows potential
- Before committing to development
- When seeking funding (investors want market size)
- When setting revenue goals

**Skip if:**
- Discovery showed "DON'T BUILD"
- Just experimenting/learning
- Building for personal use only

## Output File Location

Save market research results to one of these locations:
- `market-research.md` (project root)
- `docs/market-research.md` (if docs folder exists)

**Format**: Use the JSON structure in the Output Structure section, wrapped in a markdown code block with context and summary.

**Integration**: The PRD generator skill will automatically look for this file and integrate the insights into the PRD's Market Context section (TAM/SAM/SOM, growth trends, entry barriers, revenue expectations).

---

**Remember:** Market research informs GO/NO-GO decisions. A big market with competition beats a tiny market with no competition (usually).
