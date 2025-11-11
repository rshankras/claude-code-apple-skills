# Claude Code Skills for iOS/Swift Development

A collection of professional, well-structured Claude Code skills for iOS and Swift development. These skills help you **plan new apps**, **analyze existing apps**, maintain code quality, ensure HIG compliance, and create new skills with best practices.

## ✨ Key Highlights

- **📱 app-planner**: Complete app planning & analysis with **automatic documentation generation**
  - New apps: Creates 8 planning docs (features, architecture, tech stack, roadmap, etc.)
  - Existing apps: Creates 10 analysis docs (current state + improvement recommendations)
- **🔍 Code Review**: Swift/iOS best practices and architecture patterns
- **🎨 UI/UX Review**: HIG compliance and accessibility auditing
- **🛠️ Skill Creation**: Meta-skill for creating new Claude Code skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📦 Skills Included

### 🔍 coding-best-practices

Reviews Swift/iOS code for adherence to modern Swift idioms, Apple platform best practices, architecture patterns, and code quality standards.

**Features:**
- **Swift Language Patterns**: Optionals handling, type safety, collections, error handling, naming conventions
- **SwiftUI Best Practices**: State management, view composition, performance optimization
- **MVVM Architecture**: Separation of concerns, code organization, memory management
- **Core Data Patterns**: Context management, saving/fetching, relationships, CloudKit integration

**When to use:**
- Code reviews
- Refactoring sessions
- Architecture reviews
- Quality audits

**Modular Structure:**
- `SKILL.md` - Main review process
- `swift-patterns.md` - Swift language best practices
- `swiftui-patterns.md` - SwiftUI-specific patterns
- `architecture-patterns.md` - MVVM and organization
- `coredata-patterns.md` - Core Data best practices

### 🎨 ui-review

Comprehensive UI/UX review of SwiftUI code against Apple's Human Interface Guidelines, font best practices, and accessibility standards for iOS and watchOS.

**Features:**
- **HIG Compliance**: Layout, spacing, navigation, colors, tap targets
- **Font Usage**: Dynamic Type support, text styles, typography hierarchy
- **Accessibility**: VoiceOver, labels, hints, traits, testing guidelines
- **Platform-Specific**: iOS and watchOS requirements

**When to use:**
- UI/UX reviews
- Accessibility audits
- HIG compliance checks
- Design system validation

**Modular Structure:**
- `SKILL.md` - Main review process
- `hig-checklist.md` - Comprehensive HIG checklist
- `font-guidelines.md` - Typography and Dynamic Type
- `accessibility-quick-ref.md` - Accessibility quick reference

### 🛠️ skill-creator

Meta-skill that guides you through creating well-structured, modularized Claude Code skills with best practices.

**Features:**
- **Step-by-Step Guide**: Complete skill creation workflow
- **Templates**: Ready-to-use templates for simple and complex skills
- **Best Practices**: Naming, structure, modularization strategies
- **Examples**: Real-world skill examples

**When to use:**
- Creating new skills
- Refactoring existing skills
- Learning skill best practices
- Planning skill architecture

**Modular Structure:**
- `SKILL.md` - Main creation guide
- `skill-template.md` - Simple skill template
- `complex-skill-template.md` - Modularized skill template

### 📱 app-planner

Comprehensive iOS/Swift app planning and analysis tool. Works with both **new apps** (concept to architecture) and **existing apps** (audit, evaluate, improve).

**Features for New Apps:**
- **Product Planning**: Features, user personas, user journeys, MVP prioritization
- **Technical Planning**: Architecture selection (MVVM/TCA/etc.), data modeling, tech stack decisions
- **UI/UX Planning**: Design system, navigation patterns, accessibility, screen planning
- **Non-Functional Requirements**: Performance, security, testing strategy, analytics
- **Distribution Planning**: App Store preparation, monetization, timeline, localization
- **Documentation Generation**: Creates markdown files (overview.md, features.md, architecture.md, tech-stack.md, ui-ux.md, data-model.md, personas.md, roadmap.md) for version control and team sharing

**Features for Existing Apps:**
- **Architecture Analysis**: Evaluate current pattern, consistency, separation of concerns
- **Tech Stack Assessment**: Review UI framework, dependencies, identify improvements
- **Code Quality Review**: File sizes, organization, naming, testing coverage
- **Performance Audit**: Memory management, best practices, optimization opportunities
- **Improvement Roadmap**: Prioritized recommendations with effort estimates
- **Current State Documentation**: Creates markdown files documenting what exists (overview.md, features.md, architecture.md, tech-stack.md, ui-ux.md, data-model.md)
- **Analysis Documentation**: Creates markdown files for improvements (analysis-report.md, recommendations.md, issues.md, roadmap.md)

**When to use:**
- **New apps**: Starting a new iOS app project, planning features, choosing architecture
- **Existing apps**: Analyzing current app, evaluating tech stack, planning refactoring or improvements

**Modular Structure:**
- `SKILL.md` - Main planning process and workflow
- `planning-checklist.md` - Comprehensive phase-by-phase planning checklist
- `architecture-guide.md` - Detailed architecture patterns and decision framework
- `tech-stack-options.md` - Technology choices for iOS development

## 🚀 Installation

### Option 1: Manual Installation

1. Clone this repository:
```bash
git clone https://github.com/rshankras/claude-code-ios-skills.git
```

2. Copy the skills to your project's `.claude/skills/` directory:
```bash
# From your project root
mkdir -p .claude/skills
cp -r /path/to/claude-code-ios-skills/skills/* .claude/skills/
```

3. The skills will be automatically available in Claude Code

### Option 2: Symlink (Advanced)

For active development or if you want automatic updates:

```bash
# From your project root
mkdir -p .claude/skills
cd .claude/skills

# Create symlinks
ln -s /path/to/claude-code-ios-skills/skills/coding-best-practices coding-best-practices
ln -s /path/to/claude-code-ios-skills/skills/ui-review ui-review
ln -s /path/to/claude-code-ios-skills/skills/skill-creator skill-creator
ln -s /path/to/claude-code-ios-skills/skills/app-planner app-planner
```

## 📖 Usage

### Using coding-best-practices

```
You: "Can you review my ExpenseViewModel for best practices?"

Claude: [Activates coding-best-practices skill]
- Reviews Swift idioms
- Checks MVVM architecture
- Validates Core Data usage
- Provides scored feedback
```

**Trigger phrases:**
- "review my code"
- "check for best practices"
- "audit code quality"
- "refactor this code"

### Using ui-review

```
You: "Review AddExpenseView for HIG compliance and accessibility"

Claude: [Activates ui-review skill]
- Checks HIG compliance
- Validates font usage
- Audits accessibility
- Tests Dynamic Type support
```

**Trigger phrases:**
- "review the UI"
- "check HIG compliance"
- "accessibility audit"
- "review fonts"

### Using skill-creator

```
You: "Help me create a new skill for API testing"

Claude: [Activates skill-creator skill]
- Guides through requirements
- Suggests structure
- Provides templates
- Helps with modularization
```

**Trigger phrases:**
- "create a new skill"
- "how do I make a skill"
- "skill best practices"

### Using app-planner

**For New Apps:**
```
You: "I want to plan a new expense tracking app"

Claude: [Activates app-planner skill]
- Gathers project context
- Guides through product planning
- Helps choose architecture and tech stack
- Plans UI/UX and accessibility
- Creates documentation files:
  • docs/planning/overview.md
  • docs/planning/features.md
  • docs/planning/architecture.md
  • docs/planning/tech-stack.md
  • docs/planning/ui-ux.md
  • docs/planning/roadmap.md
  • (+ personas.md, data-model.md if applicable)
```

**For Existing Apps:**
```
You: "Run through my existing iOS app and analyze it"

Claude: [Activates app-planner skill]
- Discovers codebase structure
- Analyzes architecture and tech stack
- Evaluates code quality and patterns
- Identifies issues and gaps
- Creates current state documentation:
  • docs/current/overview.md (what the app is)
  • docs/current/features.md (current features)
  • docs/current/architecture.md (current patterns)
  • docs/current/tech-stack.md (current tech)
  • docs/current/ui-ux.md (current UI state)
  • docs/current/data-model.md (current data)
- Creates analysis documentation:
  • docs/analysis/analysis-report.md (full assessment)
  • docs/analysis/recommendations.md (improvements)
  • docs/analysis/issues.md (issue tracker)
  • docs/analysis/roadmap.md (improvement plan)
```

**Trigger phrases:**
- **New apps**: "plan a new app", "what should I consider for a new app", "architecture planning"
- **Existing apps**: "analyze my app", "run through my existing app", "evaluate my iOS app", "tech stack review"

## 📄 Documentation Files Created

### For New Apps (8 files)

```
your-project/
└── docs/
    └── planning/
        ├── overview.md          # Executive summary & key decisions
        ├── features.md          # Feature list, priorities, estimates
        ├── architecture.md      # Architecture pattern & structure
        ├── tech-stack.md        # Technology choices & justification
        ├── ui-ux.md            # Design system, navigation, screens
        ├── data-model.md       # Entities, relationships, sync
        ├── personas.md         # User personas (if created)
        └── roadmap.md          # Timeline, milestones, risks
```

### For Existing Apps (10 files)

```
your-project/
└── docs/
    ├── current/              # What EXISTS now
    │   ├── overview.md       # Current app state & health
    │   ├── features.md       # All current features
    │   ├── architecture.md   # Current patterns & structure
    │   ├── tech-stack.md     # Current technologies
    │   ├── ui-ux.md         # Current design & UX
    │   └── data-model.md    # Current data structure
    └── analysis/             # What NEEDS IMPROVEMENT
        ├── analysis-report.md    # Full assessment
        ├── recommendations.md    # Prioritized improvements
        ├── issues.md            # Issue tracker
        └── roadmap.md           # 4-phase improvement plan
```

**Benefits:**
- ✅ Version controlled (lives in your git repo)
- ✅ Team collaboration (easy to share and edit)
- ✅ Living documentation (update as project evolves)
- ✅ Professional standards (complete project documentation)
- ✅ Onboarding (new team members can understand quickly)

## 🏗️ Skill Architecture

### Modularization Strategy

These skills demonstrate best practices for skill organization:

**Simple Skills** (< 400 lines):
```
skill-name/
└── SKILL.md
```

**Complex Skills** (> 400 lines):
```
skill-name/
├── SKILL.md                # Main entry point (200-300 lines)
├── patterns.md            # Code patterns and anti-patterns
├── checklist.md           # Comprehensive checklists
├── examples.md            # Code examples
└── quick-ref.md           # Quick reference
```

### Benefits of Modularization

- **Maintainability**: Easy to update specific sections
- **Scalability**: Can add references without bloating main file
- **Usability**: Quick access to focused information
- **Clarity**: Main file stays concise and readable

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ways to Contribute

- Report bugs or issues
- Suggest new skills
- Improve existing skills
- Add more examples
- Improve documentation
- Share your use cases

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Roadmap

### Recently Added

- [x] **app-planner** - Comprehensive iOS app planning from concept to architecture ✨ **NEW**

### Future Skills

- [ ] **unit-testing** - Unit test generation and review
- [ ] **swiftui-preview** - SwiftUI preview generator
- [ ] **api-client** - REST API client generator
- [ ] **migration-helper** - Data model migration assistant
- [ ] **performance-analyzer** - Performance optimization suggestions
- [ ] **localization-checker** - Localization completeness checker
- [ ] **feature-designer** - Individual feature design and specification
- [ ] **data-modeler** - Core Data model design assistant

## 📚 Resources

### Apple Documentation
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)

### Claude Code
- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Claude Code Skills Guide](https://docs.claude.com/claude-code/skills)

## ⭐ Show Your Support

If you find these skills useful, please consider:
- Starring this repository
- Sharing with other iOS developers
- Contributing improvements
- Creating issues for bugs or suggestions

## 👤 Author

**Ravishankar**

- GitHub: [@rshankras]

## 🙏 Acknowledgments

- Apple for comprehensive development guidelines
- Claude Code team for the skills framework
- iOS development community for best practices
- Contributors and users of these skills

## 📧 Contact

For questions, suggestions, or feedback:
- Open an issue on GitHub
- Start a discussion in the Discussions tab

---

**Note**: These skills are designed for iOS/Swift development but can be adapted for other Apple platforms (macOS, watchOS, tvOS).
