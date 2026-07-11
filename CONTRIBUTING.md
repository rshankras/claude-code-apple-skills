# Contributing to Claude Code iOS Skills

First off, thank you for considering contributing to this project! It's people like you that make these skills better for the entire iOS development community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Contribution Guidelines](#contribution-guidelines)
- [Skill Development Guidelines](#skill-development-guidelines)
- [Testing Your Changes](#testing-your-changes)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow:

- Be respectful and inclusive
- Welcome newcomers and learners
- Focus on what is best for the community
- Show empathy towards others

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When creating a bug report, include:

- **Clear title**: Describe the issue concisely
- **Description**: Detailed explanation of the problem
- **Steps to reproduce**: How to trigger the issue
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: Claude Code version, OS, etc.

**Example:**

```markdown
**Title**: coding-best-practices skill not detecting force unwrapping

**Description**: The skill misses force unwrapping when used in guard statements

**Steps to Reproduce**:
1. Create a Swift file with `guard let x = y! else { return }`
2. Run coding-best-practices skill
3. Observe that force unwrap is not flagged

**Expected**: Should flag the force unwrapping with High priority
**Actual**: No warning given
**Environment**: Claude Code 1.0, macOS 14
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title**: Short, descriptive name
- **Use case**: Why is this enhancement needed?
- **Proposed solution**: How should it work?
- **Alternatives**: Other approaches considered
- **Examples**: Code examples if applicable

### Contributing New Skills

We welcome new skills! Before creating a new skill:

1. **Check roadmap**: See if it's already planned
2. **Open an issue**: Discuss the skill idea first
3. **Get feedback**: Ensure it fits the project
4. **Follow guidelines**: Use skill-creator skill for structure

### Improving Existing Skills

Ways to improve existing skills:

- Add missing patterns or anti-patterns
- Improve examples and explanations
- Fix incorrect recommendations
- Update for new Swift/iOS versions
- Improve documentation
- Better modularization

### Documentation

Help improve documentation:

- Fix typos or unclear instructions
- Add usage examples
- Improve installation guide
- Create tutorials or blog posts
- Add screenshots or GIFs

## Contribution Guidelines

### Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-code-apple-skills.git
   cd claude-code-apple-skills
   ```
3. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Branch Naming

Use descriptive branch names:

- `feature/skill-name` - New skills
- `fix/issue-description` - Bug fixes
- `docs/update-description` - Documentation
- `refactor/skill-name` - Refactoring

**Examples:**
- `feature/unit-testing-skill`
- `fix/swift-patterns-force-unwrap`
- `docs/add-usage-examples`
- `refactor/ui-review-modularization`

## Skill Development Guidelines

### File Structure

Follow the established pattern:

**Simple Skills** (< 400 lines):
```
skills/skill-name/
└── SKILL.md
```

**Complex Skills** (> 400 lines):
```
skills/skill-name/
├── SKILL.md           # Main entry point
├── patterns.md        # Patterns and anti-patterns
├── checklist.md       # Comprehensive checklist
└── examples.md        # Code examples
```

### SKILL.md Format

Every SKILL.md must have:

```yaml
---
name: skill-name
description: Brief description (1-2 sentences)
allowed-tools: [Read, Write, Edit]
---
```

Followed by:

1. **Skill Name**: H1 heading
2. **When This Skill Activates**: Clear trigger conditions
3. **Process**: Step-by-step workflow
4. **Output Format**: How to present results
5. **Examples**: Concrete examples (optional)
6. **References**: External links (optional)

### Naming Conventions

- **Skill names**: `kebab-case` (e.g., `code-reviewer`)
- **File names**: `kebab-case.md` (e.g., `swift-patterns.md`)
- **No spaces or underscores**

### Code Examples

All code examples should:

- Be syntactically correct
- Show both bad (❌) and good (✅) patterns
- Include explanatory comments
- Use realistic scenarios

**Format:**

```markdown
### Example: Handling Optionals

#### ❌ Anti-pattern
```swift
let name = user.name! // Crashes if nil
```

#### ✅ Good pattern
```swift
guard let name = user.name else {
    return
}
```

#### Why?
Force unwrapping will crash if the value is nil. Guard provides safe unwrapping with early return.
```

### Markdown Style

- Use `###` for sections, `####` for subsections
- Code blocks with language: ` ```swift `
- Lists with `-` or `1.`
- Tables for comparisons
- Bold for **emphasis**, italic for *terms*

### Content Guidelines

**Do:**
- ✅ Be clear and concise
- ✅ Provide concrete examples
- ✅ Explain the "why," not just "what"
- ✅ Reference official documentation
- ✅ Use proper technical terms
- ✅ Keep it up-to-date

**Don't:**
- ❌ Use vague descriptions
- ❌ Provide opinions without reasoning
- ❌ Include outdated practices
- ❌ Copy copyrighted material
- ❌ Add project-specific details

## Testing Your Changes

Before submitting, test your changes:

### 1. Validate Structure

```bash
# Check files exist
ls -la skills/your-skill/

# Validate YAML front matter
head -n 5 skills/your-skill/SKILL.md
```

### 2. Test in Real Project

```bash
# Copy to a test project
cp -r skills/your-skill /path/to/test-project/.claude/skills/

# Test with Claude Code
# - Verify skill activates correctly
# - Check output format
# - Validate recommendations
```

### 3. Test Examples

- All code examples should compile
- Examples should be runnable
- Both good and bad examples included

### 4. Review Checklist

- [ ] YAML front matter is valid
- [ ] All referenced files exist
- [ ] No broken links
- [ ] Code examples are correct
- [ ] Markdown renders properly
- [ ] No typos or grammar errors
- [ ] Follows project structure
- [ ] Tested in real project
- [ ] Content-changing PRs: add a line under `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md) (advisory, not CI-enforced)

## Submitting Changes

### 1. Commit Your Changes

Use clear, descriptive commit messages:

```bash
git add .
git commit -m "Add unit-testing skill for test generation"
```

**Commit message format:**

```
Type: Brief description

- Detailed change 1
- Detailed change 2
- Detailed change 3
```

**Types:**
- `feat`: New feature/skill
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Testing improvements
- `chore`: Maintenance

**Examples:**

```
feat: Add unit-testing skill

- Created SKILL.md with test generation process
- Added test patterns and examples
- Included XCTest and Quick/Nimble support
```

```
fix: Correct force unwrap detection in coding-best-practices

- Fixed regex for detecting force unwraps in guards
- Added test cases
- Updated examples
```

### 2. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 3. Create Pull Request

1. Go to the original repository on GitHub
2. Click "New Pull Request"
3. Select your fork and branch
4. Fill in the PR template:

**PR Title**: Clear, descriptive title

**Description:**
```markdown
## Changes
- List of changes made

## Motivation
Why these changes are needed

## Testing
How you tested the changes

## Checklist
- [ ] Tested in real project
- [ ] Updated documentation
- [ ] Added examples
- [ ] No breaking changes (or documented)
```

### 4. Respond to Feedback

- Be open to suggestions
- Make requested changes
- Update PR with improvements
- Be patient and respectful

## Skill Approval Criteria

For a skill to be merged, it must:

- [ ] Follow project structure
- [ ] Have valid YAML front matter
- [ ] Include clear activation triggers
- [ ] Provide detailed process/workflow
- [ ] Include code examples (where applicable)
- [ ] Use proper markdown formatting
- [ ] Be tested in real project
- [ ] Add value to iOS/Swift developers
- [ ] Not duplicate existing functionality
- [ ] Follow naming conventions

## Release Process

Maintainers will:

1. Review PR for quality and fit
2. Test changes in multiple scenarios
3. Request changes if needed
4. Merge when approved (every commit to `main` is a release — no version numbers)
5. Curate [CHANGELOG.md](CHANGELOG.md) and create the yearly `wwdc<NN>-era-final` tag before each post-WWDC content refresh

## Recognition

Contributors will be recognized:

- Listed in README.md
- Credited in release notes
- Mentioned in documentation

## Questions?

- Open an issue for questions
- Join discussions
- Reach out to maintainers

## Resources

- [skill-creator skill](skills/shared/skill-creator/) - Guide for creating skills
- [Swift Style Guide](https://google.github.io/swift/)
- [iOS HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [Claude Code Docs](https://docs.claude.com/claude-code)

---

Thank you for contributing! 🎉
