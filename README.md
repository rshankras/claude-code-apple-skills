# Claude Code Skills for Apple Platform Development

A comprehensive collection of Claude Code skills for iOS, macOS, and product development. These skills help you **plan and build apps**, **maintain code quality**, **ensure HIG compliance**, and guide you from **idea to App Store**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What's Included

| Category | Skills | Purpose |
|----------|--------|---------|
| **iOS** | 3 skills | iOS app planning, code review, UI/UX review |
| **macOS** | 8 skills | macOS development, Tahoe APIs, SwiftData, AppKit bridge |
| **Product** | 10 skills | Idea validation to App Store (complete workflow) |
| **Shared** | 1 skill | Skill creation templates |

**Total: 22 skills** covering the entire Apple development lifecycle.

## Directory Structure

```
skills/
├── ios/                        # iOS-specific skills
│   ├── app-planner/            # iOS app architecture planning
│   ├── coding-best-practices/  # Swift/iOS code review
│   └── ui-review/              # HIG compliance, accessibility
│
├── macos/                      # macOS-specific skills
│   ├── app-planner/            # macOS app planning
│   ├── appkit-swiftui-bridge/  # NSViewRepresentable, hosting controllers
│   ├── architecture-patterns/  # SOLID, design patterns, modular design
│   ├── coding-best-practices/  # macOS Swift 6+ code review
│   ├── macos-capabilities/     # Sandboxing, extensions, menubar, background
│   ├── macos-tahoe-apis/       # macOS 26 APIs, Apple Intelligence, MLX
│   ├── swiftdata-architecture/ # SwiftData patterns, queries, performance
│   └── ui-review-tahoe/        # macOS Tahoe HIG, Liquid Glass design
│
├── product/                    # Product development workflow
│   ├── product-agent/          # Idea validation, problem discovery
│   ├── competitive-analysis/   # Competitor research, feature gaps
│   ├── market-research/        # TAM/SAM/SOM, market sizing
│   ├── prd-generator/          # Product Requirements Document
│   ├── architecture-spec/      # Technical architecture spec
│   ├── ux-spec/                # UI/UX specifications
│   ├── implementation-guide/   # Development roadmap, pseudo-code
│   ├── implementation-spec/    # Orchestrator for all specs
│   ├── test-spec/              # Testing strategy
│   ├── release-spec/           # App Store launch guide
│   └── WORKFLOW.md             # Complete idea-to-App Store workflow
│
└── shared/                     # Platform-agnostic skills
    └── skill-creator/          # Templates for creating new skills
```

## Installation

### Option 1: Copy to Project

```bash
# Clone the repository
git clone https://github.com/rshankras/claude-code-apple-skills.git

# Copy skills to your project
mkdir -p your-project/.claude/skills
cp -r claude-code-apple-skills/skills/* your-project/.claude/skills/
```

### Option 2: Global Installation

```bash
# Clone to a permanent location
git clone https://github.com/rshankras/claude-code-apple-skills.git ~/claude-code-apple-skills

# Copy to global Claude config
mkdir -p ~/.claude/skills
cp -r ~/claude-code-apple-skills/skills/* ~/.claude/skills/
```

### Option 3: Symlink (for active development)

```bash
# Create skills directory if needed
mkdir -p ~/.claude/skills

# Symlink skill categories
ln -s /path/to/claude-code-apple-skills/skills/ios ~/.claude/skills/ios
ln -s /path/to/claude-code-apple-skills/skills/macos ~/.claude/skills/macos
ln -s /path/to/claude-code-apple-skills/skills/product ~/.claude/skills/product
ln -s /path/to/claude-code-apple-skills/skills/shared ~/.claude/skills/shared
```

## How Skills Are Organized

Each category directory contains a **SKILL.md** entry point that acts as a router to sub-skills:

```
~/.claude/skills/
├── ios/SKILL.md          → Routes to app-planner/, coding-best-practices/, ui-review/
├── macos/SKILL.md        → Routes to 8 sub-skills (SwiftData, Tahoe APIs, etc.)
├── product/SKILL.md      → Routes to 10 product workflow skills
└── shared/SKILL.md       → Skill creation templates
```

When you invoke a skill (e.g., `/macos`), Claude:
1. Reads the category's `SKILL.md` entry point
2. Based on your question, reads relevant module files from subdirectories
3. Applies the guidance to your specific context

This modular approach keeps individual files focused while allowing each skill to cover a broad domain.

## Skills Reference

### iOS Skills

#### `ios/coding-best-practices`
Reviews Swift/iOS code for modern Swift idioms, Apple platform best practices, architecture patterns, and code quality.

**Modules:**
- `swift-patterns.md` - Optionals, type safety, collections, error handling
- `swiftui-patterns.md` - State management, view composition, performance
- `architecture-patterns.md` - MVVM, code organization, memory management
- `coredata-patterns.md` - Core Data best practices

**Trigger phrases:** "review my code", "check best practices", "code quality audit"

#### `ios/ui-review`
Comprehensive UI/UX review against Apple's Human Interface Guidelines, accessibility standards.

**Modules:**
- `hig-checklist.md` - Layout, spacing, navigation, colors
- `font-guidelines.md` - Dynamic Type, typography
- `accessibility-quick-ref.md` - VoiceOver, labels, traits

**Trigger phrases:** "review the UI", "HIG compliance", "accessibility audit"

#### `ios/app-planner`
Complete iOS app planning from concept to architecture with automatic documentation generation.

**Creates:** 8 planning documents (overview, features, architecture, tech-stack, ui-ux, data-model, personas, roadmap)

**Trigger phrases:** "plan a new iOS app", "architecture planning"

---

### macOS Skills

#### `macos/coding-best-practices`
macOS Swift 6+ code review with focus on modern concurrency, architecture principles.

**Modules:**
- `swift-language.md` - Modern Swift 6+ features
- `architecture-principles.md` - SOLID with examples
- `data-persistence.md` - SwiftData best practices
- `code-organization.md` - Modular architecture
- `modern-concurrency.md` - Async/await, actors

#### `macos/ui-review-tahoe`
macOS Tahoe (26) UI review including Liquid Glass design system.

**Modules:**
- `macos-tahoe-hig.md` - Tahoe-specific guidelines
- `liquid-glass-design.md` - Glass material implementation
- `swiftui-macos.md` - macOS SwiftUI patterns
- `appkit-modern.md` - Modern AppKit practices
- `accessibility.md` - macOS accessibility

#### `macos/macos-tahoe-apis`
macOS 26 specific APIs and features.

**Modules:**
- `tahoe-features.md` - New macOS 26 features
- `apple-intelligence.md` - On-device AI integration
- `mlx-framework.md` - MLX machine learning
- `continuity.md` - Cross-device features
- `xcode16.md` - Xcode 16 features

#### `macos/swiftdata-architecture`
SwiftData patterns for data modeling and persistence.

**Modules:**
- `schema-design.md` - Model design patterns
- `query-patterns.md` - Efficient querying
- `repository-pattern.md` - Data layer abstraction
- `performance.md` - Optimization techniques

#### `macos/architecture-patterns`
Software architecture principles and patterns.

**Modules:**
- `solid-detailed.md` - SOLID principles with Swift examples
- `design-patterns.md` - Common design patterns
- `modular-design.md` - Module architecture

#### `macos/appkit-swiftui-bridge`
Bridging AppKit and SwiftUI in hybrid apps.

**Modules:**
- `nsviewrepresentable.md` - Wrapping AppKit views
- `hosting-controllers.md` - SwiftUI in AppKit
- `state-management.md` - Cross-framework state

#### `macos/macos-capabilities`
macOS-specific capabilities and features.

**Modules:**
- `sandboxing.md` - App sandbox configuration
- `extensions.md` - App extensions
- `menubar.md` - Menu bar apps
- `background.md` - Background execution

#### `macos/app-planner`
macOS app planning for new and existing apps.

**Modules:**
- `new-app-planning.md` - New app workflow
- `existing-app-analysis.md` - Audit existing apps

---

### Product Skills

The product skills provide a complete **Idea to App Store** workflow. See `skills/product/WORKFLOW.md` for the full pipeline.

#### Workflow Overview

```
Idea → Discovery → Market Research → PRD → Architecture → UX → Implementation → Test → Release
```

#### `product/product-agent`
Validates product ideas with honest assessment of build/don't build.

**Output:** Problem statement, severity score, opportunity assessment, recommendation

#### `product/competitive-analysis`
Deep competitor research with feature gaps and positioning opportunities.

#### `product/market-research`
TAM/SAM/SOM calculations, growth trends, revenue potential.

#### `product/prd-generator`
Generates comprehensive Product Requirements Document.

#### `product/architecture-spec`
Technical architecture specification from PRD.

#### `product/ux-spec`
UI/UX specifications with wireframes and design system.

#### `product/implementation-guide`
Development roadmap with pseudo-code and patterns.

#### `product/implementation-spec`
Orchestrates generation of all specification documents.

#### `product/test-spec`
Testing strategy with unit, integration, and UI test plans.

#### `product/release-spec`
App Store launch guide with ASO and submission checklist.

---

### Shared Skills

#### `shared/skill-creator`
Meta-skill for creating new Claude Code skills with best practices.

**Templates:**
- `skill-template.md` - Simple skill template
- `complex-skill-template.md` - Modularized skill template

## Usage Examples

### iOS Code Review
```
You: "Review my ExpenseViewModel for best practices"
Claude: [Activates ios/coding-best-practices]
→ Reviews Swift idioms, MVVM architecture, Core Data usage
→ Provides scored feedback with specific improvements
```

### macOS UI Review
```
You: "Check my macOS app for Tahoe HIG compliance"
Claude: [Activates macos/ui-review-tahoe]
→ Reviews Liquid Glass implementation
→ Checks accessibility and platform conventions
```

### Product Validation
```
You: "Should I build a password manager for Apple ecosystem?"
Claude: [Activates product/product-agent]
→ Analyzes market saturation (iCloud Keychain, 1Password)
→ Returns honest recommendation with reasoning
```

### Full Product Workflow
```
You: "Generate implementation specifications for my app idea"
Claude: [Activates product/implementation-spec]
→ Orchestrates PRD → Architecture → UX → Implementation → Test → Release
→ Creates 7 specification documents in docs/
```

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md).

### Ways to Contribute
- Report bugs or issues
- Suggest new skills
- Improve existing skills
- Add more examples
- Share your use cases

## License

MIT License - see [LICENSE](LICENSE) file.

## Author

**Ravishankar** - [@rshankras](https://github.com/rshankras)

## Acknowledgments

- Apple for comprehensive development guidelines
- Claude Code team for the skills framework
- iOS/macOS development community for best practices

