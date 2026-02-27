---
name: product-page-optimization
description: Generates A/B test plans and optimization checklists for your App Store product page — icon, screenshots, and app previews. Use when running Product Page Optimization tests or improving conversion rates.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion, WebSearch]
---

# Product Page Optimization Generator

Create structured A/B test plans for App Store Product Page Optimization (PPO), including test hypotheses, variant designs, success metrics, and iteration strategy.

## When This Skill Activates

Use this skill when the user:
- Asks to "optimize product page" or "A/B test App Store page"
- Mentions "product page optimization" or "PPO"
- Wants to improve "App Store conversion rate"
- Asks about "screenshot testing" or "icon testing"
- Mentions improving download rate or tap-through rate

## How PPO Works

- Test up to **3 treatments** against your original (control)
- Testable elements: **app icon**, **screenshots**, **app previews**
- Traffic split: Evenly distributed among variants
- Duration: Apple recommends minimum 7 days (typically run 14-28 days)
- Statistical confidence: Apple shows results when statistically significant
- Localization: Tests can run in specific localizations

### Important Limitations
- Cannot test: app name, subtitle, description, keyword field, or price
- One test at a time per localization
- Results apply to organic App Store traffic only
- Minimum traffic required for statistical significance

### Minimum Traffic Thresholds
**PPO requires sufficient impression volume to produce meaningful results.** If the app doesn't meet these thresholds, skip A/B testing and make direct qualitative improvements instead.

| Monthly Impressions | Can You PPO? | Recommendation |
|--------------------|--------------|----|
| **Under 1,000** | No | Don't bother — tests will never reach significance. Apply screenshot best practices directly. |
| **1,000-5,000** | Barely | Test ONE element at a time with only 1 variant (A/B, not A/B/C). Expect 4-8 week test cycles. |
| **5,000-20,000** | Yes | Standard testing. Run 2 variants per test, 2-4 week cycles. |
| **20,000+** | Aggressively | Test 3 variants, rapid iteration. Can test icon + screenshots sequentially. |

**If below threshold:** Focus on qualitative improvements (follow the Quick Win Checklist in the output) rather than running inconclusive A/B tests.

## Configuration Questions

Ask user via AskUserQuestion:

1. **What do you want to test?**
   - App icon variants
   - Screenshot order/design
   - App preview video
   - Multiple elements (run sequentially)

2. **What's your current conversion rate concern?**
   - Low impression-to-page-view rate (need better icon/name)
   - Low page-view-to-download rate (need better screenshots/description)
   - Low overall conversion (need comprehensive optimization)
   - Don't know (need baseline measurement)

3. **Monthly impression volume?**
   - Under 1,000 (PPO may not reach significance — focus on qualitative improvements)
   - 1,000-10,000 (test one element at a time, longer test duration)
   - 10,000-100,000 (can test 2-3 variants, standard duration)
   - 100,000+ (can test aggressively, quick results)

## Generation Process

### Step 1: Audit Current Page

Review the existing product page:
- Current screenshot sequence and messaging
- Icon design and distinctiveness
- App preview presence and quality
- Promotional text and description

### Step 2: Generate Test Plan

Produce a structured test plan with:
- Hypothesis for each test
- Variant descriptions
- Expected impact
- Duration and traffic requirements

### Step 3: Design Variant Specs

For each variant, specify:
- What changes from control
- Design direction and mockup description
- Why this variant might outperform

## Output Format

```markdown
# Product Page Optimization Plan: [App Name]

## Current State Assessment

| Element | Current | Strength | Weakness |
|---------|---------|----------|----------|
| Icon | [Description] | [What works] | [What doesn't] |
| Screenshots | [Description] | [What works] | [What doesn't] |
| Preview | [Present/Absent] | [What works] | [What doesn't] |
| Promo Text | [Description] | [What works] | [What doesn't] |

**Estimated current conversion rate**: [X%] (category average: [Y%])

---

## Test 1: [Element Being Tested]

### Hypothesis
"If we [change], then [metric] will improve because [rationale]."

### Variants

| Variant | Description | Key Difference from Control |
|---------|-------------|---------------------------|
| Control (A) | [Current design] | — |
| Treatment B | [Description] | [What's different] |
| Treatment C | [Description] | [What's different] |

### Test Configuration
- **Element**: [Icon / Screenshots / Preview]
- **Localization**: [All / Specific locale]
- **Duration**: [14-28 days]
- **Traffic requirement**: [~X impressions per variant]
- **Success metric**: [Conversion rate improvement > X%]

### Design Specs per Variant
[Detailed specs for each variant]

---

## Test 2: [Next Element]
[Same format — run after Test 1 concludes]

---

## Testing Roadmap

| Order | Test | Element | Duration | Expected Lift |
|-------|------|---------|----------|--------------|
| 1 | [Name] | [Element] | [Weeks] | [%] |
| 2 | [Name] | [Element] | [Weeks] | [%] |
| 3 | [Name] | [Element] | [Weeks] | [%] |

## Quick Win Checklist

While waiting for PPO results, implement these proven improvements:
- [ ] First screenshot shows core value in under 2 seconds
- [ ] Screenshots use benefit-focused captions (not feature names)
- [ ] App preview starts with the "wow moment" in first 3 seconds
- [ ] Icon is distinct and recognizable at small sizes
- [ ] Promotional text includes a current hook or seasonal relevance
```

## Common Test Ideas

### Icon Tests
| Test | Control | Variant | Expected Impact |
|------|---------|---------|----------------|
| Color | Current color | Contrasting color | Higher tap-through from search |
| Style | 3D/detailed | Flat/minimal | Modernized perception |
| Element | Full logo | Key symbol only | Better small-size recognition |
| Background | Solid | Gradient | Shelf standout |

### Screenshot Tests
| Test | Control | Variant | Expected Impact |
|------|---------|---------|----------------|
| First screenshot | Feature-focused | Benefit-focused | Higher engagement |
| Layout | Device frames | Full-bleed | More immersive |
| Text | Feature names | User outcomes | Stronger conversion |
| Order | Standard flow | Problem→Solution | Better storytelling |
| Social proof | None | Reviews/awards | Trust building |

### App Preview Tests
| Test | Control | Variant | Expected Impact |
|------|---------|---------|----------------|
| Hook | Slow intro | Immediate action | Higher watch-through |
| Length | 30 seconds | 15 seconds | Less drop-off |
| Style | Screen recording | Lifestyle + UI | Emotional connection |

## Seasonal Optimization Calendar

| Season | Focus | Screenshot Refresh |
|--------|-------|-------------------|
| Jan | New Year energy, fresh starts | Resolution-themed captions |
| Mar-Apr | Spring cleaning, organization | Productivity-focused |
| Jun | WWDC, new OS features | "Updated for iOS [X]" |
| Aug-Sep | Back to school | Student/education focus |
| Nov-Dec | Holiday, gift-giving | Gift-worthy messaging |

## References

- Related: `generators/custom-product-pages` — Targeted pages per audience
- Related: `app-store/screenshot-planner` — Screenshot design guidance
- Related: `app-store/keyword-optimizer` — Text optimization
- Related: `app-store/marketing-strategy` — Overall optimization strategy
