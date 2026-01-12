# Complex Skill Template

Template for creating modularized skills with supporting reference files.

## When to Use This Template

Use for complex skills that:
- ✅ Have extensive checklists (50+ items)
- ✅ Cover multiple distinct topics
- ✅ Include lots of code examples
- ✅ Need comprehensive reference material
- ✅ Would exceed 400-500 lines in a single file

## Recommended Structure

```
.claude/skills/skill-name/
├── SKILL.md                    # Main skill definition (200-300 lines)
├── checklist.md               # Comprehensive checklists
├── patterns.md                # Code patterns and anti-patterns
├── examples.md                # Extensive code examples
├── quick-ref.md               # Quick reference guide
└── guidelines.md              # Detailed guidelines
```

## Main SKILL.md Template

```markdown
---
name: skill-name
description: Brief description of what the skill does and when to use it
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Skill Name

One-paragraph description of the skill's purpose and capabilities.

## When This Skill Activates

Use this skill when the user:
- [Specific trigger 1]
- [Specific trigger 2]
- [Specific trigger 3]
- [Additional triggers as needed]

## Review Process

### 1. Identify Scope

- How to determine what to review
- What to prioritize
- Scope clarification steps

### 2. Load Reference Materials

Before starting, familiarize yourself with these references in `.claude/skills/skill-name/`:

- **patterns.md** - Common patterns and anti-patterns
- **checklist.md** - Comprehensive review checklist
- **examples.md** - Code examples and templates
- **quick-ref.md** - Quick reference for common issues
- **guidelines.md** - Detailed guidelines and standards

### 3. Review Categories

Apply these review categories:

**Category 1:**
- High-level checks
- What to look for
- Key considerations

**Category 2:**
- Another set of checks
- Related concerns
- Important patterns

**Category 3:**
- Additional checks
- Special cases
- Edge cases

### 4. Output Format

Present findings in this structure:

#### ✅ Strengths Found
- [List well-implemented patterns]
- [Highlight good practices]

#### ⚠️ Issues Found

**Category: [Category Name]**

**[Priority]: [File:Line]** - [Description]
```language
// Current code
[problematic code]

// Suggested fix
[improved code]

// Reason: [explanation]
```

#### 📊 Quality Score

**Overall: X/10**

- Category 1: X/10
- Category 2: X/10
- Category 3: X/10

#### 📋 Recommendations

1. **High Priority**: [Critical issues]
2. **Medium Priority**: [Improvements]
3. **Low Priority**: [Nice-to-haves]

#### 🔧 Quick Wins

List 3-5 easy fixes that provide immediate value

## Quick Reference Checklist

Brief, high-level checklist for quick validation:

### Essential Checks
- [ ] Critical item 1
- [ ] Critical item 2
- [ ] Critical item 3

(Full checklist available in checklist.md)

## Tips for Effective Reviews

### Be Constructive
- Provide examples
- Explain reasoning
- Be educational

### Consider Context
- Some patterns have valid uses
- Balance idealism with pragmatism
- Consider project constraints

### Prioritize Impact
- Correctness first
- Performance second
- Style last

## References

- [External documentation link]
- [Related resource link]
- Supporting files in this skill directory

## Notes

- Important considerations
- Known limitations
- Future enhancements
```

## patterns.md Template

```markdown
# Patterns and Anti-Patterns

Common patterns and anti-patterns for [skill topic].

## Category 1

### Anti-patterns

```language
// ❌ Bad - [Why it's bad]
[problematic code example]

// ❌ Bad - [Another reason]
[another bad example]
```

### Good Patterns

```language
// ✅ Good - [Why it's good]
[good code example]

// ✅ Good - [Another good pattern]
[another good example]
```

### When to Use

- [Scenario 1]
- [Scenario 2]
- [Scenario 3]

### When to Avoid

- [Scenario where pattern doesn't apply]
- [Edge case to watch for]

## Category 2

[Repeat structure for each category]

## Pattern Comparison Table

| Pattern | Use When | Avoid When | Complexity |
|---------|----------|------------|------------|
| Pattern A | [Use case] | [Avoid case] | Low |
| Pattern B | [Use case] | [Avoid case] | Medium |
| Pattern C | [Use case] | [Avoid case] | High |

## References

- [Pattern documentation]
- [Best practices guide]
```

## checklist.md Template

```markdown
# Comprehensive Checklist

Detailed checklist for [skill topic] review.

## Category 1

### Subcategory 1.1
- [ ] Check item 1
- [ ] Check item 2
- [ ] Check item 3

### Subcategory 1.2
- [ ] Check item 4
- [ ] Check item 5
- [ ] Check item 6

## Category 2

### Subcategory 2.1
- [ ] Check item 7
- [ ] Check item 8
- [ ] Check item 9

### Subcategory 2.2
- [ ] Check item 10
- [ ] Check item 11
- [ ] Check item 12

## Category 3

[Continue with additional categories]

## Priority Matrix

| Priority | Category | Items |
|----------|----------|-------|
| High | [Category] | [Item numbers] |
| Medium | [Category] | [Item numbers] |
| Low | [Category] | [Item numbers] |

## Quick Check

Essential items to always verify:
- [ ] Critical item 1
- [ ] Critical item 2
- [ ] Critical item 3
```

## examples.md Template

```markdown
# Code Examples and Templates

Comprehensive examples for [skill topic].

## Example 1: [Scenario Name]

### Description
What this example demonstrates and when to use it.

### Before (Anti-pattern)

```language
// ❌ Problematic code
[bad code example]
```

**Problems:**
- [Issue 1]
- [Issue 2]
- [Issue 3]

### After (Good Pattern)

```language
// ✅ Improved code
[good code example]
```

**Improvements:**
- [Improvement 1]
- [Improvement 2]
- [Improvement 3]

### Why It Matters
[Explanation of impact and benefits]

## Example 2: [Another Scenario]

[Repeat structure]

## Templates

### Template 1: [Template Name]

```language
// Template for [purpose]
[code template with placeholders]
```

**Usage:**
1. Replace [placeholder1] with [description]
2. Replace [placeholder2] with [description]
3. [Additional steps]

### Template 2: [Another Template]

[Repeat structure]

## Real-World Examples

### Example from [Project/Context]

[Complete, realistic example with full context]

```language
[full code example]
```

**Analysis:**
- [What's good]
- [What could be improved]
- [Lessons learned]
```

## quick-ref.md Template

```markdown
# Quick Reference

Fast lookup guide for common [skill topic] issues and solutions.

## Common Issues

### Issue 1: [Issue Name]

**Problem:**
```language
[problematic code]
```

**Solution:**
```language
[fixed code]
```

**Quick Fix:** [One-line explanation]

### Issue 2: [Another Issue]

[Repeat structure]

## Common Patterns

### Pattern 1: [Pattern Name]

**When:** [When to use]

**Code:**
```language
[pattern code]
```

**Note:** [Important consideration]

## Command Reference

| Command/Syntax | Description | Example |
|----------------|-------------|---------|
| [Syntax 1] | [What it does] | `[example]` |
| [Syntax 2] | [What it does] | `[example]` |

## Keyboard Shortcuts

| Action | Shortcut | Notes |
|--------|----------|-------|
| [Action 1] | [Keys] | [When to use] |
| [Action 2] | [Keys] | [When to use] |

## Decision Trees

### When to use Pattern A vs Pattern B

```
Start
├─ Need [Feature X]?
│  ├─ Yes → Use Pattern A
│  └─ No → Continue
└─ Need [Feature Y]?
   ├─ Yes → Use Pattern B
   └─ No → Use default
```

## Resources

- [Quick link 1]
- [Quick link 2]
```

## guidelines.md Template

```markdown
# Detailed Guidelines

Comprehensive guidelines for [skill topic].

## Philosophy

Core principles behind these guidelines:
1. [Principle 1]
2. [Principle 2]
3. [Principle 3]

## Category 1: [Category Name]

### Overview
What this category covers and why it matters.

### Guidelines

#### Guideline 1.1: [Guideline Name]

**Description:**
Detailed explanation of the guideline.

**Rationale:**
Why this guideline exists and what problems it solves.

**Examples:**

```language
// ❌ Violates guideline
[bad example]

// ✅ Follows guideline
[good example]
```

**Exceptions:**
- [Scenario where exception is valid]
- [Another valid exception]

#### Guideline 1.2: [Another Guideline]

[Repeat structure]

## Category 2: [Another Category]

[Repeat structure]

## Best Practices Summary

### Must Do (Critical)
- [Critical practice 1]
- [Critical practice 2]

### Should Do (Recommended)
- [Recommended practice 1]
- [Recommended practice 2]

### Could Do (Optional)
- [Optional practice 1]
- [Optional practice 2]

## Anti-Patterns to Avoid

### Anti-Pattern 1: [Name]

**Description:** [What it is]

**Why Avoid:** [Problems it causes]

**Better Approach:** [What to do instead]

## Decision Guidelines

### When to Choose Option A
- [Criterion 1]
- [Criterion 2]

### When to Choose Option B
- [Criterion 1]
- [Criterion 2]

## References

- [Authoritative source 1]
- [Best practices documentation]
- [Style guide reference]
```

## Modularization Strategy

### Step 1: Identify Topics

Break down your skill into logical topics:
- Core concepts
- Patterns and practices
- Examples and templates
- Reference materials
- Guidelines and standards

### Step 2: Assign Files

Map topics to files:
- **Main logic** → SKILL.md
- **Comprehensive lists** → checklist.md
- **Code patterns** → patterns.md
- **Examples** → examples.md
- **Quick lookup** → quick-ref.md
- **Detailed rules** → guidelines.md

### Step 3: Cross-Reference

In SKILL.md, reference supporting files:
```markdown
### 2. Load Reference Materials

Before starting, read:
- **patterns.md** - [Brief description]
- **checklist.md** - [Brief description]
```

### Step 4: Keep SKILL.md Lean

Main SKILL.md should be:
- 200-300 lines ideally
- High-level process and workflow
- References to detailed materials
- Essential checklists only
- Output format definition

## File Size Guidelines

| File | Ideal Size | Max Size | Purpose |
|------|-----------|----------|---------|
| SKILL.md | 200-300 | 400 | Main entry point |
| checklist.md | 100-200 | 400 | Comprehensive checklist |
| patterns.md | 200-400 | 600 | Patterns and anti-patterns |
| examples.md | 200-400 | 800 | Code examples |
| quick-ref.md | 50-100 | 200 | Quick lookup |
| guidelines.md | 200-400 | 600 | Detailed guidelines |

## Testing Your Complex Skill

1. **Verify structure**: All referenced files exist
2. **Check links**: References are accurate
3. **Test workflow**: Follow process end-to-end
4. **Validate output**: Output format works as expected
5. **Review modularization**: Information is well-organized

## Example: Existing Complex Skills

See these skills for reference:
- **coding-best-practices** - Well-modularized code review skill
- **ui-review** - UI/accessibility review with references

## Tips

- Start with basic template, modularize when needed
- Keep each file focused on one topic
- Use consistent formatting across files
- Cross-reference related information
- Update all files when changing structure
- Test after major refactoring

## References

- [Claude Code Skills Documentation]
- Example skills in `.claude/skills/`
