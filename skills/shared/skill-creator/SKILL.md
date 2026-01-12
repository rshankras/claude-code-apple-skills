---
name: skill-creator
description: Guides you through creating well-structured Claude Code skills with proper modularization, templates, and best practices. Use when creating new skills or improving existing ones.
allowed-tools: [Read, Write, Glob, Grep, Bash]
---

# Skill Creator

Helps you create well-structured, modularized Claude Code skills with best practices.

## When This Skill Activates

Use this skill when the user:
- Wants to create a new skill
- Asks about skill structure or organization
- Wants to improve or refactor existing skills
- Needs help with skill modularization
- Asks about skill best practices

## Skill Creation Process

### 1. Understand Requirements

Ask the user:
- **Purpose**: What should this skill do?
- **Activation**: When should it activate?
- **Tools**: What tools will it need? (Read, Write, Edit, Glob, Grep, Bash, WebFetch, etc.)
- **Scope**: Is it project-specific or general-purpose?
- **Complexity**: Will it need reference files or can it be self-contained?

### 2. Plan the Skill Structure

Based on complexity:

**Simple Skills** (Self-contained):
```
.claude/skills/skill-name/
└── SKILL.md
```

**Complex Skills** (Modularized):
```
.claude/skills/skill-name/
├── SKILL.md                  # Main skill definition
├── reference-1.md           # Supporting reference
├── reference-2.md           # Additional reference
└── examples.md              # Code examples/templates
```

### 3. Create the Main SKILL.md

The main SKILL.md should include:

#### Front Matter (Required)
```yaml
---
name: skill-name
description: Brief description of what the skill does and when to use it
allowed-tools: [Read, Write, Edit]
---
```

**Front Matter Fields:**
- `name`: kebab-case skill name (e.g., `code-reviewer`, `ui-audit`)
- `description`: 1-2 sentences describing the skill and when to use it
- `allowed-tools`: Array of tools the skill can use

**Common Tool Combinations:**
- **Read-only analysis**: `[Read, Glob, Grep]`
- **Code modification**: `[Read, Write, Edit]`
- **Full access**: `[Read, Write, Edit, Glob, Grep, Bash]`
- **Web research**: `[Read, Glob, Grep, WebFetch]`

#### Main Content Structure

```markdown
# Skill Name

Brief description of what this skill does.

## When This Skill Activates

Use this skill when the user:
- [Specific trigger 1]
- [Specific trigger 2]
- [Specific trigger 3]

## Process/Workflow

### 1. Step One
- Instructions for first step
- What to check or do
- Expected outputs

### 2. Step Two
- Instructions for second step
- References to supporting files if needed

### 3. Output Format

How to present results to the user.

## References

Links to relevant documentation, files, or resources.
```

### 4. Create Supporting Reference Files

For complex skills, create modular reference files:

**When to Modularize:**
- Main SKILL.md exceeds 300-400 lines
- Contains extensive checklists or examples
- Has multiple distinct topics/categories
- Would benefit from focused reference materials

**Common Reference File Types:**
- **Checklists**: `checklist.md`, `review-checklist.md`
- **Patterns**: `patterns.md`, `anti-patterns.md`
- **Examples**: `examples.md`, `templates.md`
- **Quick References**: `quick-ref.md`, `commands.md`
- **Guidelines**: `guidelines.md`, `standards.md`

**Reference File Structure:**
```markdown
# Reference Topic

Brief description of this reference.

## Section 1

### Subsection
- Checklist items
- Code examples
- Explanations

## Section 2

[Content organized logically]

## References
[External links if needed]
```

### 5. Link References in Main SKILL.md

In the main SKILL.md, reference supporting files:

```markdown
### 2. Load Reference Materials

Before starting, familiarize yourself with these references:

- **patterns.md** - Common patterns and anti-patterns
- **examples.md** - Code examples and templates
- **checklist.md** - Comprehensive review checklist
```

## Skill Writing Best Practices

### Clear Activation Triggers

```markdown
## When This Skill Activates

Use this skill when the user:
- Asks for code review or quality check
- Mentions "best practices" or "refactoring"
- Wants to improve code quality
- Requests architecture review
```

### Actionable Instructions

```markdown
// ❌ Vague
- Check the code

// ✅ Specific
- Check for force unwrapping (!)
- Verify all optionals use safe unwrapping patterns
- Flag any instances for review with line numbers
```

### Examples and Templates

Always provide:
- ✅ Good examples (what to do)
- ❌ Bad examples (what to avoid)
- Explanations (why it matters)

```markdown
### Pattern Example

#### ❌ Anti-pattern
// Bad code example
let value = optional!

#### ✅ Good pattern
// Good code example
guard let value = optional else { return }

#### Why?
Force unwrapping crashes if nil. Guard provides safe unwrapping.
```

### Structured Output Formats

Provide clear output templates:

```markdown
## Output Format

Present findings in this structure:

### ✅ Strengths
- [List strengths]

### ⚠️ Issues Found
**[Category]**
**[Priority]: [File:Line]** - [Description]
// Current code
// Suggested fix
// Reason

### 📋 Recommendations
1. High priority items
2. Medium priority items
3. Low priority items
```

### Tool Selection

Choose appropriate tools:

| Task | Tools |
|------|-------|
| Reading code | `Read, Glob, Grep` |
| Modifying code | `Read, Write, Edit` |
| Running tests | `Read, Bash` |
| Web research | `WebFetch` |
| File operations | `Read, Write, Glob` |

### Checklists

Use checklists for systematic reviews:

```markdown
### Review Checklist

#### Category 1
- [ ] Check item 1
- [ ] Check item 2
- [ ] Check item 3

#### Category 2
- [ ] Check item 4
- [ ] Check item 5
```

## Example Skills

### Simple Skill Example

```yaml
---
name: greeting-responder
description: Responds to user greetings with helpful information about the project
allowed-tools: [Read]
---

# Greeting Responder

Provides helpful project context when users greet Claude.

## When This Skill Activates

Use this skill when the user:
- Says "hello", "hi", or similar greetings
- Asks "what can you help with?"

## Process

1. Greet the user warmly
2. Provide brief overview of the project
3. List 3-5 common tasks you can help with
4. Invite them to ask questions

## Example Output

"Hello! I can help you with this Swift/iOS project. Here are some things I can do:

- Review code for best practices
- Help implement new features
- Debug issues
- Refactor code
- Write tests

What would you like to work on?"
```

### Complex Skill Example

See the existing `coding-best-practices` or `ui-review` skills as examples of well-modularized complex skills.

## Skill Maintenance

### When to Refactor

Refactor a skill when:
- Main SKILL.md exceeds 400-500 lines
- Adding new content becomes difficult
- Multiple distinct topics exist
- Reference material is repeated
- Finding information takes too long

### How to Refactor

1. **Identify logical sections** in the main SKILL.md
2. **Extract sections** into focused reference files
3. **Update main SKILL.md** to reference new files
4. **Test the skill** to ensure references work
5. **Update descriptions** if scope changed

### File Organization

```
.claude/skills/skill-name/
├── SKILL.md                      # Main entry point
├── process.md                    # Detailed workflow
├── patterns/
│   ├── good-patterns.md
│   └── anti-patterns.md
├── references/
│   ├── checklist.md
│   └── examples.md
└── templates/
    └── output-template.md
```

## Testing Your Skill

After creating a skill:

1. **Verify metadata**: Check front matter is valid YAML
2. **Test activation**: Ensure description triggers appropriately
3. **Check references**: Verify all referenced files exist
4. **Run through workflow**: Follow the process end-to-end
5. **Validate output**: Ensure output format is clear and useful

## Common Pitfalls

### ❌ Avoid

- Vague activation criteria
- Missing tool permissions
- Overly complex single-file skills
- No examples or templates
- Unclear output formats
- Broken reference links

### ✅ Do

- Clear, specific activation triggers
- Appropriate tool selection
- Modularize complex skills
- Provide examples for everything
- Define structured output formats
- Keep references organized

## Skill Naming Conventions

**Name Format**: `kebab-case`

**Good Names:**
- `code-reviewer`
- `ui-audit`
- `test-generator`
- `api-analyzer`

**Bad Names:**
- `CodeReviewer` (PascalCase)
- `code_reviewer` (snake_case)
- `reviewer` (too vague)
- `cr` (too abbreviated)

## Templates

See the following reference files for templates:
- **skill-template.md** - Basic skill template
- **complex-skill-template.md** - Modularized skill template

## References

- [Claude Code Skills Documentation](https://docs.claude.com/claude-code/skills)
- Existing skills in `.claude/skills/` for examples
- This project's `coding-best-practices` and `ui-review` skills

## Notes

- Keep skills focused on a single purpose
- Use modularization for maintainability
- Provide clear examples and templates
- Test skills after creation
- Update skills as needs evolve
