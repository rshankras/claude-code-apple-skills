---
name: app-planner
description: Guides you through comprehensive iOS/Swift app planning and analysis. Use for new apps (concept to architecture) or existing apps (audit current state, plan improvements, evaluate tech stack). Covers product planning, technical decisions, UI/UX design, and distribution strategy.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion]
---

# App Planner Skill

Comprehensive guide for planning iOS/Swift applications and analyzing existing apps, covering product, technical, UI/UX, and distribution considerations.

## When This Skill Activates

Use this skill when the user:

**For New Apps:**
- Wants to plan a new iOS/Swift app from scratch
- Asks about app planning, architecture planning, or project setup
- Needs help defining features, requirements, or technical stack
- Wants to create a comprehensive app plan or design document
- Asks "what should I consider when building a new app?"

**For Existing Apps:**
- Wants to analyze or audit their current iOS app
- Asks to "run through my existing app"
- Needs architecture evaluation or recommendations
- Wants tech stack assessment
- Planning major refactoring or improvements
- Evaluating app health and identifying gaps

## Planning Process

### 1. Understand Project Context

First, determine if this is a **new app** or **existing app**, then gather context:

**App Status:**
- New app (planning from scratch)
- Existing app (analyze/improve)

**For NEW Apps - gather:**
- **Project Type**: Personal, client, startup, learning
- **Current Stage**: Just an idea, have requirements, have designs, technical only
- **Scope**: Full planning, feature planning, architecture only, tech stack only

**For EXISTING Apps - gather:**
- **Project Type**: Personal, client, startup, enterprise
- **App Age**: How long in development/production
- **Codebase Size**: Small (<10 screens), medium (10-30), large (30+)
- **Current Issues**: Performance, maintainability, feature additions, technical debt
- **Analysis Scope**: Full audit, architecture review, tech stack evaluation, specific area
- **Existing Tech Stack**: SwiftUI/UIKit, architecture pattern, persistence layer
- **Pain Points**: What's not working well, what needs improvement

**Then proceed to appropriate workflow:**
- **New App** → Continue to "Planning Phases for New Apps" (Section 3)
- **Existing App** → Jump to "Analysis Process for Existing Apps" (Section 6)

### 2. Load Reference Materials

Before detailed planning, familiarize yourself with these references in `.claude/skills/app-planner/`:

- **planning-checklist.md** - Comprehensive planning checklist covering all phases
- **architecture-guide.md** - Architecture patterns, decisions, and trade-offs
- **tech-stack-options.md** - Technology choices for different requirements

### 3. Planning Phases for New Apps

**Note**: For existing apps, skip to Section 6 "Analysis Process for Existing Apps"

Guide the user through these planning phases based on their scope:

#### Phase 1: Product Planning

**Goals:**
- Define what the app does and who it's for
- Identify core features and prioritization
- Understand user needs and workflows

**Activities:**
1. **Define App Purpose**
   - What problem does it solve?
   - What's the core value proposition?
   - What makes it different?

2. **Identify Target Users**
   - Who will use this app?
   - What are their goals and pain points?
   - Create 1-2 user personas if helpful

3. **Feature Definition**
   - List all potential features
   - Categorize: MVP (must-have), v2 (nice-to-have), future
   - Prioritize based on value and complexity

4. **User Journeys**
   - Map key user workflows
   - Identify main user paths through the app
   - Note critical touchpoints

#### Phase 2: Technical Planning

**Goals:**
- Choose appropriate architecture and patterns
- Design data models
- Select technology stack
- Plan project structure

**Activities:**
1. **Architecture Selection**
   - Review architecture-guide.md for options (MVVM, TCA, etc.)
   - Consider project size, team experience, requirements
   - Ask user about preferences and constraints
   - Recommend architecture with rationale

2. **Data Modeling**
   - Identify main entities and relationships
   - Define data flow (where data comes from, where it goes)
   - Choose persistence layer:
     - Core Data (complex data, relationships, offline-first)
     - SwiftData (iOS 17+, modern alternative)
     - UserDefaults (simple settings only)
     - Realm (alternative to Core Data)
     - Custom backend + caching

3. **Tech Stack Decisions**
   - Review tech-stack-options.md for guidance
   - **UI Framework**: SwiftUI, UIKit, or hybrid
   - **Minimum iOS version**: Based on features needed
   - **Networking**: URLSession, Alamofire, or custom
   - **Dependencies**: SPM, CocoaPods, or manual
   - **Third-party libraries**: Based on requirements
   - Ask about user preferences and constraints

4. **Project Structure**
   - Folder organization (features, layers, modules)
   - Modularization strategy (monolith vs multi-module)
   - Code organization patterns

#### Phase 3: UI/UX Planning

**Goals:**
- Plan user interface and experience
- Ensure HIG compliance
- Design navigation and flows

**Activities:**
1. **Design System**
   - Color palette (consider dark mode)
   - Typography (SF Pro, custom fonts)
   - Spacing system (8pt grid recommended)
   - Component library planning

2. **Navigation Pattern**
   - Tab bar (2-5 main sections)
   - Sidebar (iPad, complex hierarchies)
   - Navigation stack (linear flows)
   - Sheet/modal presentations
   - Recommend based on app structure

3. **Screen Planning**
   - List all main screens
   - Create simple wireframes or descriptions
   - Define screen hierarchy
   - Plan empty states, loading states, error states

4. **Accessibility First**
   - Dynamic Type support
   - VoiceOver compatibility
   - Color contrast requirements
   - Accessibility features priority

5. **Onboarding & UX Flows**
   - First-time user experience
   - Key user flows
   - Error handling UX
   - Feedback mechanisms

#### Phase 4: Non-Functional Requirements

**Goals:**
- Define performance, security, testing requirements
- Plan for scalability and maintainability

**Activities:**
1. **Performance Targets**
   - Target device range (iPhone only, iPad support, Mac Catalyst)
   - Performance benchmarks
   - Memory constraints
   - Battery usage considerations

2. **Security & Privacy**
   - Authentication needs (if any)
   - Data encryption requirements
   - Privacy policy requirements
   - Secure storage for sensitive data
   - App Transport Security compliance

3. **Testing Strategy**
   - Unit testing approach and coverage goals
   - UI testing requirements
   - Beta testing plan
   - QA process

4. **Monitoring & Analytics**
   - Analytics needs (user behavior tracking)
   - Crash reporting (essential for production apps)
   - Performance monitoring
   - User feedback mechanism

#### Phase 5: Distribution & Business

**Goals:**
- Plan for App Store distribution
- Define monetization (if applicable)
- Set timeline and milestones

**Activities:**
1. **App Store Planning**
   - App name availability check
   - Bundle identifier decision
   - Screenshots/preview planning
   - App description and keywords

2. **Monetization** (if applicable)
   - Free, paid, freemium, subscription
   - In-app purchases planning
   - Ad integration strategy

3. **Localization**
   - Initial language(s)
   - Internationalization strategy
   - Future localization plans

4. **Timeline & Milestones**
   - MVP timeline estimate
   - Feature milestones
   - Release schedule
   - Version planning (1.0, 1.1, 2.0, etc.)

### 4. Create Planning Documentation Files

**IMPORTANT**: After completing planning phases, create actual documentation files that the user can keep, update, and version control.

#### Ask User About Documentation Location

Before creating files, ask where to put documentation:
- `docs/planning/` (recommended for most projects)
- `planning/` (root-level planning folder)
- `.claude/planning/` (keep with Claude Code files)
- Custom location

#### Documentation Files to Create

For comprehensive planning, create these files:

**1. docs/planning/overview.md** - Executive summary and key decisions
**2. docs/planning/features.md** - Feature list, priorities, and roadmap
**3. docs/planning/architecture.md** - Architecture pattern and rationale
**4. docs/planning/tech-stack.md** - Technology choices and justification
**5. docs/planning/ui-ux.md** - Design system, navigation, screens
**6. docs/planning/data-model.md** - Data entities and relationships (if applicable)
**7. docs/planning/personas.md** - User personas (if created)
**8. docs/planning/roadmap.md** - Timeline and milestones

**For focused planning** (architecture only, tech stack only), create only relevant files.

#### Templates for Each Documentation File

**File 1: overview.md**
```markdown
# [App Name] - Overview

**Last Updated**: [Date]

## Quick Summary
- **Purpose**: [One sentence - what problem does this solve?]
- **Target Users**: [Primary audience]
- **Platform**: iOS [version]+
- **Project Type**: [Personal/Client/Startup/Enterprise]
- **Status**: [Planning/In Development/Production]

## Vision
[2-3 sentences describing the app's vision and core value proposition]

## Key Decisions

### Architecture
- **Pattern**: [MVVM/TCA/MVC/etc.]
- **Rationale**: [Why this choice]

### Tech Stack
- **UI**: [SwiftUI/UIKit/Hybrid]
- **Min iOS**: [Version]
- **Persistence**: [Core Data/SwiftData/etc.]
- **Backend**: [CloudKit/Firebase/Custom/None]

### Timeline
- **MVP**: [Date/timeframe]
- **v1.0**: [Target launch]

## Key Risks & Mitigation
1. [Risk 1] - [Mitigation strategy]
2. [Risk 2] - [Mitigation strategy]

## Success Metrics
- [Metric 1]
- [Metric 2]
- [Metric 3]

## Related Documents
- [features.md](./features.md) - Feature list and roadmap
- [architecture.md](./architecture.md) - Architecture details
- [tech-stack.md](./tech-stack.md) - Technology choices
- [ui-ux.md](./ui-ux.md) - Design and UX
```

**File 2: features.md**
```markdown
# [App Name] - Features

**Last Updated**: [Date]

## MVP Features (v1.0)

### Feature 1: [Name]
- **Priority**: High/Medium/Low
- **Complexity**: Low/Medium/High
- **Description**: [What it does]
- **User Value**: [Why users need this]
- **Dependencies**: [Other features needed first]
- **Status**: [ ] Not Started / [ ] In Progress / [x] Complete

### Feature 2: [Name]
[Same structure]

## Post-MVP Features (v1.1+)

### Feature 3: [Name]
- **Target Version**: v1.1 / v2.0
- **Priority**: High/Medium/Low
- **Description**: [What it does]
- **Why Later**: [Rationale for not including in MVP]

## Future Considerations

- [Feature idea 1]
- [Feature idea 2]

## Feature Dependencies

```
Feature A
├── Feature B (depends on A)
└── Feature C (depends on A)
```

## Feature Estimates

| Feature | Complexity | Effort | Priority |
|---------|-----------|--------|----------|
| Feature 1 | Medium | 2 weeks | High |
| Feature 2 | Low | 3 days | High |
| Feature 3 | High | 4 weeks | Medium |
```

**File 3: architecture.md**
```markdown
# [App Name] - Architecture

**Last Updated**: [Date]

## Architecture Pattern

**Chosen Pattern**: [MVVM/TCA/MVC/VIPER]

### Rationale
[Why this pattern was chosen for this specific app]

### Alternatives Considered
- **[Pattern 1]**: [Why not chosen]
- **[Pattern 2]**: [Why not chosen]

## Project Structure

```
AppName/
├── App/
│   ├── AppName.swift
│   └── Configuration/
├── Features/
│   ├── FeatureA/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   └── FeatureB/
├── Shared/
│   ├── Components/
│   ├── Extensions/
│   └── Utilities/
├── Services/
│   ├── DataService/
│   └── NetworkService/
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

## Layer Responsibilities

### Presentation Layer (Views)
- SwiftUI views or UIKit view controllers
- UI presentation only
- Binds to ViewModels
- No business logic

### Business Logic Layer (ViewModels)
- Presentation logic
- State management
- Coordinates between View and Data layers
- Testable without UI

### Data Layer (Models & Services)
- Domain models
- Data access (repositories)
- API communication
- Persistence management

## Data Flow

```
User Action
    ↓
View
    ↓
ViewModel (handles action)
    ↓
Service/Repository
    ↓
Model (data)
    ↓
ViewModel (transforms for presentation)
    ↓
View (updates UI)
```

## Key Architectural Decisions

### 1. [Decision Name]
- **Decision**: [What was decided]
- **Context**: [Why it mattered]
- **Rationale**: [Why this choice]
- **Consequences**: [Trade-offs]

### 2. [Decision Name]
[Same structure]

## Testing Strategy

### Unit Tests
- ViewModels (business logic)
- Services and repositories
- Utilities and extensions
- **Coverage Goal**: 70%+

### UI Tests
- Critical user flows
- Key navigation paths

## Future Considerations

- [Potential architecture evolution]
- [Migration strategy if needed]
```

**File 4: tech-stack.md**
```markdown
# [App Name] - Tech Stack

**Last Updated**: [Date]

## UI Framework

**Choice**: [SwiftUI/UIKit/Hybrid]

### Rationale
[Why this choice for this app]

### Version Support
- **Minimum iOS**: [e.g., iOS 15]
- **Target iOS**: [e.g., iOS 17]
- **Rationale**: [Why these versions]

## Persistence

**Choice**: [Core Data/SwiftData/Realm/UserDefaults/File System]

### Rationale
[Why this persistence layer]

### Data Sync
- **Strategy**: [CloudKit/Firebase/Custom/None]
- **Offline Support**: [Yes/No - approach]

## Networking

**Choice**: [URLSession/Alamofire/Moya/Custom]

### Rationale
[Why this networking approach]

### API Details
- **Type**: REST/GraphQL/None
- **Base URL**: [If applicable]
- **Authentication**: [Method if needed]

## Dependency Management

**Choice**: [Swift Package Manager/CocoaPods/Carthage]

### Rationale
[Why this dependency manager]

## Third-Party Dependencies

| Dependency | Purpose | Version | Justification |
|-----------|---------|---------|---------------|
| [Name] | [What it does] | [Version] | [Why needed] |
| [Name] | [What it does] | [Version] | [Why needed] |

### Dependency Guidelines
- Minimize external dependencies
- Prefer native solutions when possible
- All dependencies must be actively maintained

## Development Tools

- **Linting**: SwiftLint
- **Formatting**: SwiftFormat (optional)
- **Analytics**: [Tool if needed]
- **Crash Reporting**: [Tool if needed]

## Backend Services

**Choice**: [CloudKit/Firebase/Supabase/Custom/None]

### Services Used
- [ ] Authentication
- [ ] Database/Storage
- [ ] Analytics
- [ ] Push Notifications
- [ ] Cloud Functions

### Rationale
[Why this backend choice]

## CI/CD

**Choice**: [Xcode Cloud/GitHub Actions/Bitrise/Other]

### Pipeline
- Automated builds
- Automated testing
- TestFlight deployment

## Alternative Considered

### [Alternative 1]
- **What**: [Alternative tech choice]
- **Pros**: [Benefits]
- **Cons**: [Drawbacks]
- **Why Not Chosen**: [Reason]

## Tech Stack Summary

```
UI:          [SwiftUI]
iOS:         [15+]
Architecture: [MVVM]
Persistence: [Core Data]
Backend:     [CloudKit]
Networking:  [URLSession]
Dependencies: [SPM]
CI/CD:       [Xcode Cloud]
```

## Migration Considerations

[If tech stack might change later, note migration paths]
```

**File 5: ui-ux.md**
```markdown
# [App Name] - UI/UX Design

**Last Updated**: [Date]

## Design System

### Color Palette

**Light Mode:**
- Primary: `#XXXXXX` (Purpose)
- Secondary: `#XXXXXX` (Purpose)
- Background: System background
- Text: System label

**Dark Mode:**
- Primary: `#XXXXXX`
- Secondary: `#XXXXXX`
- Background: System background
- Text: System label

### Typography

**Font**: [SF Pro/Custom font]

**Text Styles:**
- Large Title: 34pt, Bold
- Title: 28pt, Regular
- Headline: 17pt, Semibold
- Body: 17pt, Regular
- Caption: 12pt, Regular

**Dynamic Type**: ✅ Supported

### Spacing

**Base Unit**: 8pt

**Scale**:
- XXS: 4pt
- XS: 8pt
- S: 12pt
- M: 16pt
- L: 24pt
- XL: 32pt
- XXL: 48pt

## Navigation

**Primary Pattern**: [Tab Bar/Sidebar/Navigation Stack]

### Rationale
[Why this navigation pattern]

### Tab Bar Structure (if applicable)
1. **Tab 1**: [Name] - [Icon] - [Purpose]
2. **Tab 2**: [Name] - [Icon] - [Purpose]
3. **Tab 3**: [Name] - [Icon] - [Purpose]

## Screens

### Screen 1: [Name]
- **Purpose**: [What users do here]
- **Navigation**: [How users get here]
- **Key Elements**: [Main UI components]
- **States**: Loading, Empty, Error, Success

### Screen 2: [Name]
[Same structure]

## User Flows

### Flow 1: [Primary User Flow]
```
Launch
  ↓
Home Screen
  ↓
Action Button
  ↓
Detail View
  ↓
Completion
```

### Flow 2: [Another Flow]
[Same structure]

## Accessibility

### VoiceOver
- [ ] All interactive elements labeled
- [ ] Meaningful labels (not just "Button")
- [ ] Logical navigation order
- [ ] Tested with VoiceOver

### Dynamic Type
- [ ] All text uses text styles
- [ ] Layout adapts to larger text
- [ ] Tested at largest size

### Color Contrast
- [ ] WCAG AA compliance (4.5:1 for text)
- [ ] Not relying on color alone for information

### Other
- [ ] Reduce Motion support
- [ ] Haptic feedback
- [ ] Clear tap targets (44pt minimum)

## Platform Considerations

### iPhone
- Supported sizes: [All/iPhone 13 and newer]
- Orientation: [Portrait only/Both]

### iPad
- Support: [Yes/No/Future]
- Layout: [Adaptive/Optimized]

### Mac Catalyst
- Support: [Yes/No/Future]

## Design Assets

- **App Icon**: [Status - designed/placeholder]
- **Launch Screen**: [Approach]
- **SF Symbols**: [Symbols used]
- **Custom Icons**: [If any]

## Onboarding

### First Launch
- [ ] Welcome screen
- [ ] Feature highlights
- [ ] Permission requests (with rationale)
- [ ] Optional tutorial

## Empty States

- [Screen] when empty: [Message/visual]
- [Feature] when no data: [Message/visual]

## Error States

- Network error: [Message and UI]
- Data error: [Message and UI]
- Permission denied: [Message and UI]

## Loading States

- Initial load: [Loading indicator type]
- Pull to refresh: [System/Custom]
- Pagination: [Approach]
```

**File 6: data-model.md** (if applicable)
```markdown
# [App Name] - Data Model

**Last Updated**: [Date]

## Entities

### Entity 1: [Name]

**Purpose**: [What this entity represents]

**Attributes**:
- `id`: UUID (unique identifier)
- `attribute1`: String (description)
- `attribute2`: Date (description)
- `attribute3`: Double (description)

**Relationships**:
- `relationshipName`: Relationship to [OtherEntity] (one-to-many/many-to-one)

**Validation**:
- [Validation rule 1]
- [Validation rule 2]

### Entity 2: [Name]
[Same structure]

## Relationships

```
Entity1
  ├── one-to-many → Entity2
  └── many-to-one → Entity3

Entity2
  └── many-to-many → Entity4
```

## Data Flow

### Create
1. User creates [entity] via UI
2. ViewModel validates input
3. Repository creates entity in persistence layer
4. UI updates with new entity

### Read
1. ViewModel requests data from repository
2. Repository fetches from persistence layer
3. Data transformed for presentation
4. UI displays data

### Update
1. User modifies [entity]
2. ViewModel validates changes
3. Repository updates persistence layer
4. UI reflects changes

### Delete
1. User confirms deletion
2. ViewModel requests deletion
3. Repository removes from persistence
4. UI updates

## Persistence Strategy

**Technology**: [Core Data/SwiftData]

**Context Management**:
- Main context: UI operations
- Background context: Heavy operations

**Fetch Strategies**:
- Batching: [Yes/No - batch size]
- Faulting: [Approach]
- Prefetching: [Relationships to prefetch]

## Cloud Sync

**Strategy**: [CloudKit/Firebase/None]

**Conflict Resolution**:
[How conflicts are handled]

**Sync Triggers**:
- App launch
- Significant data change
- Manual sync option

## Migration Strategy

**Version 1**: Initial schema

**Future Migrations**:
[Plan for schema changes]

## Sample Data

```swift
// Example entity
let example = Entity1(
    id: UUID(),
    attribute1: "Example",
    attribute2: Date(),
    attribute3: 123.45
)
```
```

**File 7: personas.md** (if created)
```markdown
# [App Name] - User Personas

**Last Updated**: [Date]

## Persona 1: [Name]

**Photo/Avatar**: [Optional]

### Demographics
- **Age**: [Age range]
- **Occupation**: [Job/role]
- **Location**: [Where they live]
- **Tech Savviness**: Low/Medium/High

### Background
[2-3 sentences about this person's background and context]

### Goals
- [Goal 1]
- [Goal 2]
- [Goal 3]

### Pain Points
- [Pain point 1]
- [Pain point 2]
- [Pain point 3]

### How [App Name] Helps
[How your app solves their problems]

### User Journey
1. [Discovery - how they find the app]
2. [Onboarding - first experience]
3. [Regular Usage - typical use case]
4. [Value Realization - when they see benefit]

### Quote
> "[A quote that represents this persona's perspective]"

## Persona 2: [Name]
[Same structure]

## Persona Comparison

| Aspect | Persona 1 | Persona 2 |
|--------|-----------|-----------|
| Primary Goal | [Goal] | [Goal] |
| Key Pain Point | [Pain] | [Pain] |
| Usage Frequency | Daily | Weekly |
| Key Feature | [Feature] | [Feature] |
```

**File 8: roadmap.md**
```markdown
# [App Name] - Roadmap

**Last Updated**: [Date]

## Timeline Overview

```
Planning        Development      Testing     Launch
|==============|===============|===========|=====>
[Date range]   [Date range]    [Date range] [Date]
```

## Milestones

### Milestone 1: Project Setup
**Target**: [Date/Week 1]
- [ ] Create Xcode project
- [ ] Set up git repository
- [ ] Configure CI/CD
- [ ] Create initial project structure
- [ ] Set up dependencies

### Milestone 2: Core Architecture
**Target**: [Date/Week 2]
- [ ] Implement MVVM structure
- [ ] Set up Core Data/persistence
- [ ] Create base ViewModels
- [ ] Set up networking layer

### Milestone 3: MVP Features
**Target**: [Date/Weeks 3-6]
- [ ] Feature 1 implementation
- [ ] Feature 2 implementation
- [ ] Feature 3 implementation
- [ ] Basic UI/UX
- [ ] Integration testing

### Milestone 4: Polish & Testing
**Target**: [Date/Week 7-8]
- [ ] UI polish
- [ ] Accessibility implementation
- [ ] Performance optimization
- [ ] Bug fixes
- [ ] User testing

### Milestone 5: Launch Prep
**Target**: [Date/Week 9]
- [ ] App Store assets
- [ ] Privacy policy
- [ ] App Store submission
- [ ] Marketing materials
- [ ] Support documentation

### Milestone 6: v1.0 Launch
**Target**: [Date]
- [ ] Submit to App Store
- [ ] App Review
- [ ] Public release
- [ ] Monitor analytics & crashes
- [ ] Gather user feedback

## Version Planning

### v1.0 - MVP (Launch)
- Core features only
- Stable and polished
- **Target**: [Date]

### v1.1 - Quick Improvements
- User feedback incorporated
- Quick wins
- Performance improvements
- **Target**: [Date - 1 month after launch]

### v2.0 - Major Update
- [Major feature 1]
- [Major feature 2]
- Significant improvements
- **Target**: [Date - 3-6 months after launch]

## Feature Release Schedule

| Version | Features | Target Date |
|---------|----------|-------------|
| v1.0 | [Feature 1, 2, 3] | [Date] |
| v1.1 | [Feature 4, improvements] | [Date] |
| v1.2 | [Feature 5, 6] | [Date] |
| v2.0 | [Major features] | [Date] |

## Dependencies & Blockers

### Current Blockers
- [Blocker 1 - impact and mitigation]
- [Blocker 2 - impact and mitigation]

### External Dependencies
- [Dependency 1 - impact on timeline]
- [Dependency 2 - impact on timeline]

## Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk 1] | High/Med/Low | High/Med/Low | [Strategy] |
| [Risk 2] | High/Med/Low | High/Med/Low | [Strategy] |

## Resource Allocation

- **Development**: [X hours/weeks]
- **Design**: [X hours/weeks]
- **Testing**: [X hours/weeks]
- **Marketing**: [X hours/weeks]

## Success Metrics

### Launch Metrics (v1.0)
- Downloads: [Target]
- Active users: [Target]
- Crash-free rate: >99%
- App Store rating: >4.0

### 3-Month Metrics
- Downloads: [Target]
- Daily active users: [Target]
- Retention: [Target]%
- [Custom metric]: [Target]

## Notes

[Any additional timeline notes, assumptions, or considerations]
```

### 5. Provide Recommendations

After planning, provide tailored recommendations:

#### Recommendations Format

```markdown
## 📋 Planning Recommendations

### High Priority Decisions Needed
1. [Critical decision 1 - options and recommendation]
2. [Critical decision 2 - options and recommendation]

### Suggested Next Steps
1. **Immediate**: [What to do first]
2. **Week 1**: [Early tasks]
3. **Week 2-4**: [MVP development focus]

### Resource Recommendations
- [Tool recommendations]
- [Library recommendations]
- [Learning resources if needed]

### Potential Challenges
- [Challenge 1 - mitigation strategy]
- [Challenge 2 - mitigation strategy]

### Time Estimates
- Planning & Setup: [X days/weeks]
- MVP Development: [X weeks/months]
- Testing & Polish: [X weeks]
- App Store Submission: [X weeks]
```

### 6. Analysis Process for Existing Apps

**Note**: This section is for analyzing existing apps. For new apps, use Section 3 instead.

When analyzing an existing app, follow this systematic approach:

#### Step 1: Discover the Codebase

Use Glob and Grep tools to understand the project structure:

**Key Discovery Tasks:**
1. **Identify project structure**
   - Use Glob to find main directories
   - Identify file organization pattern
   - Locate main app files, views, models

2. **Detect tech stack**
   - SwiftUI vs UIKit (search for "import SwiftUI" vs "UIViewController")
   - Architecture hints (look for ViewModels, Coordinators, Interactors)
   - Persistence layer (search for Core Data, SwiftData, Realm imports)
   - Third-party dependencies (check Package.swift, Podfile)

3. **Assess codebase size and complexity**
   - Count Swift files
   - Identify main features/modules
   - Note file sizes (potential massive files)

#### Step 2: Analyze Current State

Based on the analysis scope, evaluate different aspects:

**Architecture Analysis:**
- **Current Pattern**: What architecture is being used (MVVM, MVC, mixed)?
- **Consistency**: Is the pattern applied consistently?
- **Separation of Concerns**: Are responsibilities properly separated?
- **Code Organization**: How is code organized (by feature, by layer)?
- **Recommendation**: Should architecture be changed or improved?

**Tech Stack Evaluation:**
- **UI Framework**: SwiftUI/UIKit usage, is it appropriate?
- **Minimum iOS**: What's the deployment target, should it change?
- **Persistence**: What's being used, is it the right choice?
- **Dependencies**: List third-party dependencies, are they necessary?
- **Networking**: How is networking handled?
- **Recommendation**: Tech stack improvements or migrations

**Code Quality Assessment:**
- **File Sizes**: Any massive files (>500 lines)?
- **Code Duplication**: Patterns of repeated code
- **Naming Conventions**: Consistent and clear?
- **Comments**: Adequate documentation?
- **Testing**: Test coverage, test quality
- **Recommendation**: Priority refactoring areas

**Feature Analysis:**
- **Current Features**: List what the app does
- **Feature Organization**: How are features structured?
- **Missing Features**: Gaps or incomplete features
- **Feature Quality**: Well-implemented or need work?
- **Recommendation**: Feature priorities

**Performance & Best Practices:**
- **Memory Management**: Retain cycles, memory leaks
- **SwiftUI Patterns**: State management issues
- **Core Data Usage**: Context management, fetch patterns
- **Error Handling**: How errors are handled
- **Recommendation**: Performance improvements

**UI/UX State:**
- **HIG Compliance**: Basic compliance check
- **Accessibility**: VoiceOver support, Dynamic Type
- **Navigation**: Navigation patterns used
- **Design Consistency**: Consistent UI patterns
- **Recommendation**: UI/UX improvements

#### Step 3: Identify Issues and Gaps

Create a comprehensive issues list:

**Critical Issues** (must fix):
- Architecture problems causing bugs
- Performance bottlenecks
- Security vulnerabilities
- Crashes or critical bugs

**Medium Priority** (should fix):
- Code maintainability issues
- Missing best practices
- Incomplete features
- Technical debt

**Low Priority** (nice to have):
- Code style improvements
- Minor optimizations
- Documentation gaps

#### Step 4: Create Analysis Documentation Files

**IMPORTANT**: Create actual documentation files for the analysis that can be tracked and referenced.

##### Ask User About Documentation Location

Before creating files, ask where to put analysis documentation:
- `docs/analysis/` (recommended)
- `analysis/` (root-level)
- `.claude/analysis/` (keep with Claude Code files)
- Custom location

##### Documentation Files to Create

For existing app analysis, create TWO sets of files:

**Current State Documentation** (what exists now):
**1. docs/current/overview.md** - Current app overview and status
**2. docs/current/features.md** - Current features and capabilities
**3. docs/current/architecture.md** - Current architecture and patterns
**4. docs/current/tech-stack.md** - Current technology stack
**5. docs/current/ui-ux.md** - Current UI/UX state (optional)
**6. docs/current/data-model.md** - Current data model (if applicable)

**Analysis & Improvement Documentation** (what needs to change):
**7. docs/analysis/analysis-report.md** - Full analysis and assessment
**8. docs/analysis/recommendations.md** - Prioritized improvement recommendations
**9. docs/analysis/issues.md** - Issues tracker with priorities
**10. docs/analysis/roadmap.md** - Improvement roadmap and timeline

**Rationale**: Separating current state from improvements provides:
- Clear baseline documentation (what exists)
- Clear improvement path (what to change)
- Knowledge transfer for new team members
- Historical record of app state
- Comparison point for measuring progress

##### Current State Documentation Templates

**File 1: docs/current/overview.md**
```markdown
# [App Name] - Current State Overview

**Last Updated**: [Date]
**Analysis Date**: [Date]

## App Summary
- **Name**: [App Name]
- **Bundle ID**: [Bundle identifier]
- **Current Version**: [Version in App Store / Development]
- **Platform**: iOS [deployment target]+
- **Status**: [In Development / Production / Maintenance]
- **Team Size**: [Solo / Small / Medium / Large]

## Purpose
[What the app does - 2-3 sentences]

## Current Users
- **Target Audience**: [Who uses it]
- **User Base**: [Number of users if known]
- **Primary Use Cases**: [How users use it]

## Key Information

### Technical Overview
- **Architecture**: [MVVM/MVC/TCA/Mixed]
- **UI Framework**: [SwiftUI/UIKit/Hybrid]
- **Min iOS Version**: [Version]
- **Persistence**: [Core Data/SwiftData/Realm/etc.]
- **Backend**: [CloudKit/Firebase/Custom/None]

### Codebase Stats
- **Swift Files**: [Count]
- **Screens/Features**: [Count]
- **Lines of Code**: [Approximate]
- **Test Coverage**: [Percentage if known]

### App Store Presence
- **Listed**: [Yes/No]
- **Category**: [Category]
- **Rating**: [Rating if applicable]
- **Last Update**: [Date]

## Current State Assessment
- **Overall Health**: [Excellent/Good/Fair/Needs Work]
- **Code Quality**: [X/10]
- **Architecture**: [X/10]
- **Documentation**: [X/10]
- **Test Coverage**: [X/10]

## Known Issues
1. [Major known issue 1]
2. [Major known issue 2]
3. [Major known issue 3]

## Recent Changes
- [Recent significant change 1]
- [Recent significant change 2]

## Related Documents
- [features.md](./features.md) - Current features
- [architecture.md](./architecture.md) - Current architecture
- [tech-stack.md](./tech-stack.md) - Current tech stack
- [../analysis/analysis-report.md](../analysis/analysis-report.md) - Analysis & recommendations
```

**File 2: docs/current/features.md**
```markdown
# [App Name] - Current Features

**Last Updated**: [Date]

## Core Features

### Feature 1: [Name]
- **Status**: ✅ Complete / 🚧 Partial / ❌ Broken
- **Location**: [File/Module]
- **Description**: [What it does]
- **Quality**: [Well-implemented / Needs work / Has issues]
- **Usage**: [Heavily used / Moderately used / Rarely used]
- **Known Issues**: [List issues if any]

### Feature 2: [Name]
[Same structure]

### Feature 3: [Name]
[Same structure]

## Secondary Features

### Feature 4: [Name]
[Same structure]

## Incomplete/Partial Features

### Feature X: [Name]
- **Status**: 🚧 Incomplete
- **What Works**: [Completed parts]
- **What's Missing**: [Missing functionality]
- **Why Incomplete**: [Reason if known]

## Deprecated/Legacy Features

### Old Feature: [Name]
- **Status**: ⚠️ Deprecated
- **Replacement**: [New feature or none]
- **Should Remove**: [Yes/No - why]

## Feature Categories

### User-Facing Features
- [Feature 1]
- [Feature 2]
- [Feature 3]

### System Features
- [Authentication]
- [Data sync]
- [Notifications]

## Feature Quality Matrix

| Feature | Status | Quality | Issues | Priority |
|---------|--------|---------|--------|----------|
| [Feature 1] | ✅ | Good | None | High |
| [Feature 2] | 🚧 | Fair | [Issues] | Medium |
| [Feature 3] | ✅ | Poor | [Issues] | High |

## Features by Module/Screen

### [Module/Screen 1]
- Feature A
- Feature B

### [Module/Screen 2]
- Feature C
- Feature D

## User Journeys

### Journey 1: [Primary Use Case]
```
[Screen 1] → [Action] → [Screen 2] → [Completion]
```
**Status**: [Works well / Has issues]

### Journey 2: [Another Use Case]
[Same structure]

## Related Documents
- [overview.md](./overview.md) - App overview
- [architecture.md](./architecture.md) - How features are implemented
- [../analysis/recommendations.md](../analysis/recommendations.md) - Feature improvements
```

**File 3: docs/current/architecture.md**
```markdown
# [App Name] - Current Architecture

**Last Updated**: [Date]

## Architecture Pattern

**Current Pattern**: [MVVM/MVC/TCA/VIPER/Mixed]

**Consistency**: [Highly consistent / Mostly consistent / Inconsistent / Very mixed]

**Assessment**: [2-3 sentences about architecture state]

## Current Project Structure

```
[AppName]/
├── [Actual folder structure from codebase]
├──
├──
└──
```

**Organization Method**: [By feature / By layer / Mixed / Unclear]

**Assessment**: [Is structure logical and maintainable?]

## Layer Breakdown

### Presentation Layer
**Files**: [Count]
**Pattern**: [SwiftUI Views / UIViewControllers]
**Quality**: [Assessment]
**Issues**: [List issues]

### Business Logic Layer
**Files**: [Count]
**Pattern**: [ViewModels / Presenters / Controllers]
**Quality**: [Assessment]
**Issues**: [List issues]

### Data Layer
**Files**: [Count]
**Pattern**: [Repositories / Services / Direct access]
**Quality**: [Assessment]
**Issues**: [List issues]

## Actual Data Flow

**Observed Pattern**:
```
[How data actually flows in the current app]
```

**Issues**: [Any flow issues observed]

## Architecture Debt

### Mixed Patterns
- [Location where pattern 1 used]
- [Location where pattern 2 used]
- **Impact**: [How this affects development]

### Massive Files
| File | Lines | Should Be | Effort to Fix |
|------|-------|-----------|---------------|
| [File1.swift] | [XXX] | [Split into X files] | [Effort] |
| [File2.swift] | [XXX] | [Split into X files] | [Effort] |

### Tight Coupling
- [Component 1] ↔ [Component 2] - [Issue]
- [Component 3] ↔ [Component 4] - [Issue]

### Missing Abstractions
- [Area lacking abstraction 1]
- [Area lacking abstraction 2]

## Code Organization

### Strengths
- ✅ [What's good about current organization]
- ✅ [Another strength]

### Weaknesses
- ❌ [What's problematic]
- ❌ [Another issue]

## Testing Architecture

**Current State**:
- **Unit Tests**: [Count] files, [X%] coverage
- **UI Tests**: [Count] files
- **Test Quality**: [Assessment]
- **Testability**: [How easy to test - Good/Fair/Poor]

## Dependencies

**External Dependencies**: [Count]
**Dependency Management**: [SPM/CocoaPods/Carthage/Mixed]
**Dependency Issues**: [Any problematic dependencies]

## Related Documents
- [overview.md](./overview.md) - App overview
- [tech-stack.md](./tech-stack.md) - Technology details
- [../analysis/recommendations.md](../analysis/recommendations.md) - Architecture improvements
```

**File 4: docs/current/tech-stack.md**
```markdown
# [App Name] - Current Tech Stack

**Last Updated**: [Date]

## UI Framework

**Current**: [SwiftUI/UIKit/Hybrid]

**Details**:
- SwiftUI: [Percentage or areas]
- UIKit: [Percentage or areas]
- Hybrid Strategy: [How mixed]

**Assessment**: [Is current choice appropriate?]

## iOS Version Support

**Deployment Target**: iOS [X]
**Latest Tested**: iOS [X]

**Assessment**:
- [Too old / Appropriate / Could be higher]
- **Impact**: [Benefits/limitations of current target]

## Persistence

**Current**: [Core Data/SwiftData/Realm/UserDefaults/File System]

**Details**:
- Entities: [Count]
- Complexity: [Simple/Medium/Complex]
- Performance: [Good/Fair/Poor]

**Assessment**: [Is choice appropriate for needs?]

## Data Sync

**Strategy**: [CloudKit/Firebase/Custom/None]

**Details**:
- Working: [Yes/No/Partially]
- Conflicts: [How handled]
- Issues: [Any sync issues]

## Networking

**Library**: [URLSession/Alamofire/Moya/Custom]

**Details**:
- API Type: [REST/GraphQL/None]
- Error Handling: [Good/Fair/Poor]
- Offline Support: [Yes/No/Partial]

**Assessment**: [Appropriate for needs?]

## Dependency Management

**Current**: [SPM/CocoaPods/Carthage/Mixed/None]

**Details**:
- Total Dependencies: [Count]
- Management Quality: [Good/Fair/Poor]

## Third-Party Dependencies

| Dependency | Version | Purpose | Status | Issues |
|-----------|---------|---------|--------|--------|
| [Name] | [X.X.X] | [Purpose] | ✅ Updated / ⚠️ Outdated | [Any issues] |
| [Name] | [X.X.X] | [Purpose] | ✅ Updated / ⚠️ Outdated | [Any issues] |

### Deprecated Dependencies
- [Dependency name] - [Why deprecated, what to use instead]

### Unnecessary Dependencies
- [Dependency that could be removed] - [Why not needed]

## Development Tools

**Currently Used**:
- **Linting**: [SwiftLint / None]
- **Formatting**: [SwiftFormat / None]
- **Analytics**: [Tool / None]
- **Crash Reporting**: [Tool / None]

## Backend Services

**Provider**: [CloudKit/Firebase/Supabase/Custom/None]

**Services Used**:
- [x] Authentication - [Status]
- [x] Database - [Status]
- [ ] Analytics - [Not used]
- [ ] Push Notifications - [Not used]

**Assessment**: [Working well / Has issues / Could be improved]

## CI/CD

**Current Setup**: [Xcode Cloud/GitHub Actions/Bitrise/None]

**Pipeline**:
- Automated builds: [Yes/No]
- Automated testing: [Yes/No]
- TestFlight deployment: [Yes/No]

**Assessment**: [Adequate / Needs improvement / Not setup]

## Build Configuration

**Configurations**: [Debug, Release, other]
**Build Time**: [Approximate time]
**Issues**: [Slow builds, configuration issues, etc.]

## Tech Stack Summary

```
UI:           [SwiftUI/UIKit]
iOS Target:   [Version]
Architecture: [Pattern]
Persistence:  [Technology]
Backend:      [Service/None]
Networking:   [Library]
Dependencies: [Manager]
CI/CD:        [Tool/None]
```

## Technology Debt

### Outdated Technologies
- [Technology 1] - Current: [Version], Latest: [Version]
- [Technology 2] - Current: [Version], Latest: [Version]

### Missing Modern Features
- [Feature available in newer iOS] - Requires iOS [X]
- [Another feature] - Requires iOS [X]

## Related Documents
- [overview.md](./overview.md) - App overview
- [architecture.md](./architecture.md) - Architecture patterns
- [../analysis/recommendations.md](../analysis/recommendations.md) - Tech stack improvements
```

**File 5: docs/current/ui-ux.md** (Optional - if doing UI/UX analysis)
```markdown
# [App Name] - Current UI/UX State

**Last Updated**: [Date]

## Current Design System

### Colors
**Current Usage**: [Consistent / Mixed / Inconsistent]

**Observed Colors**:
- Primary: [Color/None defined]
- Secondary: [Color/None defined]
- Background: [System/Custom]

**Assessment**: [Has design system / Inconsistent / No system]

### Typography
**Font**: [SF Pro/Custom/Mixed]
**Dynamic Type**: [Supported / Partial / Not supported]

**Assessment**: [Consistent / Inconsistent]

### Spacing
**System**: [8pt grid / Inconsistent / No system]

**Assessment**: [Consistent / Needs improvement]

## Navigation

**Pattern**: [Tab Bar/Sidebar/Stack/Mixed]

**Details**:
- Tabs: [Count if applicable]
- Hierarchy: [Clear / Confusing]
- Back navigation: [Works well / Has issues]

**Assessment**: [Good / Could be improved / Confusing]

## Screen Inventory

### Main Screens
1. **[Screen Name]** - [Brief description] - Quality: [Good/Fair/Poor]
2. **[Screen Name]** - [Brief description] - Quality: [Good/Fair/Poor]
3. **[Screen Name]** - [Brief description] - Quality: [Good/Fair/Poor]

### Secondary Screens
[List]

## HIG Compliance

**Overall**: [Compliant / Mostly / Many issues]

**Issues Found**:
- [HIG violation 1]
- [HIG violation 2]
- [HIG violation 3]

## Accessibility

**VoiceOver**: [Supported / Partial / Not supported]
**Dynamic Type**: [Supported / Partial / Not supported]
**Color Contrast**: [Good / Some issues / Many issues]

**Assessment**: [Well implemented / Needs work / Poor]

## User Experience Issues

### Major Issues
- [UX issue 1]
- [UX issue 2]

### Minor Issues
- [Minor issue 1]
- [Minor issue 2]

## Strengths
- ✅ [UI/UX strength 1]
- ✅ [UI/UX strength 2]

## Related Documents
- [../analysis/recommendations.md](../analysis/recommendations.md) - UI/UX improvements
```

**File 6: docs/current/data-model.md** (If applicable)
```markdown
# [App Name] - Current Data Model

**Last Updated**: [Date]

## Persistence Technology
[Core Data / SwiftData / Realm / Other]

## Current Entities

### Entity 1: [Name]
**Attributes**:
- [attribute1]: [Type]
- [attribute2]: [Type]

**Relationships**:
- [relationship]: to [Entity]

**Issues**: [Any issues with this entity]

### Entity 2: [Name]
[Same structure]

## Current Relationships

```
[Entity1] ←→ [Entity2] (relationship type)
[Entity2] → [Entity3] (relationship type)
```

## Data Flow

**Current**: [How data currently flows through the app]

**Issues**: [Any data flow problems]

## Performance

**Fetch Performance**: [Good / Fair / Slow]
**Save Performance**: [Good / Fair / Slow]
**Known Bottlenecks**: [List if any]

## Migration History

**Current Version**: [Schema version]
**Migrations**: [Count of migrations performed]
**Issues**: [Any migration issues]

## Related Documents
- [architecture.md](./architecture.md) - How data layer is organized
- [../analysis/recommendations.md](../analysis/recommendations.md) - Data model improvements
```

---

##### Analysis File Templates

**File 7: docs/analysis/analysis-report.md**

```markdown
# [App Name] - Analysis Report

## Executive Summary
- **App Purpose**: [What the app does]
- **Codebase Size**: [Number of files, screens]
- **Current Tech Stack**: [List main technologies]
- **Overall Health**: [Rating: Excellent/Good/Fair/Needs Work]
- **Primary Concerns**: [Top 3 issues]

## Current State

### Architecture
- **Pattern**: [MVVM/MVC/etc.]
- **Consistency**: [Assessment]
- **Rating**: X/10
- **Notes**: [Key observations]

### Tech Stack
- **UI Framework**: [SwiftUI/UIKit/Hybrid]
- **iOS Target**: [Version]
- **Persistence**: [Core Data/etc.]
- **Dependencies**: [List]
- **Rating**: X/10
- **Notes**: [Assessment]

### Code Quality
- **Organization**: [Assessment]
- **File Sizes**: [Average, largest files]
- **Naming**: [Assessment]
- **Testing**: [Coverage, quality]
- **Rating**: X/10
- **Notes**: [Key findings]

### Features
- **Current Features**: [List]
- **Feature Quality**: [Assessment]
- **Gaps**: [Missing features]
- **Rating**: X/10

### UI/UX
- **HIG Compliance**: [Basic assessment]
- **Accessibility**: [State]
- **Navigation**: [Patterns used]
- **Rating**: X/10

## Issues Found

### Critical (Must Fix)
1. [Issue 1 - Location - Impact - Recommendation]
2. [Issue 2 - Location - Impact - Recommendation]

### Medium Priority (Should Fix)
1. [Issue - Recommendation]
2. [Issue - Recommendation]

### Low Priority (Nice to Have)
1. [Issue - Recommendation]

## Recommendations

### Immediate Actions (Week 1)
1. [Action 1 - Why - Impact]
2. [Action 2 - Why - Impact]

### Short-term Improvements (Month 1)
1. [Improvement - Benefits]
2. [Improvement - Benefits]

### Long-term Strategy (3-6 months)
1. [Strategic change - Rationale]
2. [Strategic change - Rationale]

### Architecture Recommendations
- **Current**: [Current pattern]
- **Recommendation**: [Keep/Migrate/Improve]
- **Rationale**: [Why]
- **Migration Path**: [If applicable]

### Tech Stack Recommendations
- **SwiftUI Migration**: [If UIKit] - [Timeline, approach]
- **Dependency Updates**: [What to update/remove]
- **iOS Version**: [Should deployment target change?]
- **New Additions**: [Recommended libraries/tools]

### Refactoring Priorities
1. **High Priority**: [What - Why - Effort]
2. **Medium Priority**: [What - Why - Effort]
3. **Low Priority**: [What - Why - Effort]

## Estimated Effort

### Quick Wins (1-2 weeks)
- [Item 1]
- [Item 2]

### Medium Effort (1-2 months)
- [Item 1]
- [Item 2]

### Large Effort (3-6 months)
- [Item 1]
- [Item 2]

## Next Steps

1. [ ] [Immediate action 1]
2. [ ] [Immediate action 2]
3. [ ] [Plan refactoring strategy]
4. [ ] [Address critical issues]
5. [ ] [Implement quick wins]
```

**File 2: recommendations.md**
```markdown
# [App Name] - Recommendations

**Last Updated**: [Date]
**Analysis Date**: [Date]

## Executive Summary

**Overall App Health**: [Excellent/Good/Fair/Needs Work]

**Top 3 Priorities**:
1. [Priority 1 - Impact]
2. [Priority 2 - Impact]
3. [Priority 3 - Impact]

## Immediate Actions (Week 1)

### 1. [Action Name]
- **Category**: [Architecture/Code Quality/Performance/etc.]
- **Priority**: Critical/High/Medium
- **Effort**: [Hours/Days]
- **Impact**: [Description of benefit]
- **Action Items**:
  - [ ] [Specific task 1]
  - [ ] [Specific task 2]

### 2. [Action Name]
[Same structure]

## Short-term Improvements (1-2 Months)

### Architecture Improvements
- **Current State**: [Current architecture issues]
- **Recommended Changes**:
  - [Change 1 - Rationale]
  - [Change 2 - Rationale]
- **Effort**: [Estimate]
- **Benefits**: [Expected improvements]

### Code Quality Improvements
- **Current State**: [Code quality issues]
- **Recommended Changes**:
  - [Change 1 - Rationale]
  - [Change 2 - Rationale]
- **Effort**: [Estimate]
- **Benefits**: [Expected improvements]

### Tech Stack Updates
- **Current State**: [Tech stack issues]
- **Recommended Changes**:
  - [Change 1 - Rationale - Migration path]
  - [Change 2 - Rationale - Migration path]
- **Effort**: [Estimate]
- **Benefits**: [Expected improvements]

## Long-term Strategy (3-6 Months)

### Strategic Recommendation 1: [Name]
- **Current State**: [Where we are]
- **Target State**: [Where we want to be]
- **Rationale**: [Why this change]
- **Approach**: [How to get there]
- **Timeline**: [Phases and milestones]
- **Risks**: [Potential issues and mitigation]

### Strategic Recommendation 2: [Name]
[Same structure]

## Technology Migrations

### SwiftUI Migration (if UIKit app)
- **Recommended**: [Yes/No/Partial]
- **Rationale**: [Why or why not]
- **Approach**: [Strategy - feature by feature, new features only, etc.]
- **Timeline**: [When to start, expected completion]
- **Risks**: [Challenges and mitigation]

### Architecture Migration (if recommended)
- **From**: [Current pattern]
- **To**: [Recommended pattern]
- **Rationale**: [Why change]
- **Approach**: [Migration strategy]
- **Timeline**: [Phases]
- **Risks**: [Challenges]

### iOS Version Update
- **Current**: iOS [X]
- **Recommended**: iOS [X]
- **Rationale**: [Benefits of updating]
- **Impact**: [What breaks, what becomes available]
- **Timeline**: [When to update]

## Dependency Recommendations

### Dependencies to Remove
| Dependency | Reason to Remove | Alternative |
|-----------|------------------|-------------|
| [Name] | [Why remove] | [What to use instead] |

### Dependencies to Add
| Dependency | Purpose | Justification |
|-----------|---------|---------------|
| [Name] | [What it does] | [Why needed] |

### Dependencies to Update
| Dependency | Current | Target | Breaking Changes |
|-----------|---------|--------|------------------|
| [Name] | [Version] | [Version] | [Yes/No - Details] |

## Refactoring Priorities

### High Priority
| File/Area | Issue | Recommendation | Effort |
|-----------|-------|----------------|--------|
| [File:Line] | [Problem] | [Solution] | [Hours/Days] |

### Medium Priority
[Same table structure]

### Low Priority
[Same table structure]

## Testing Recommendations

### Unit Testing
- **Current Coverage**: [X%]
- **Target Coverage**: [X%]
- **Priority Areas**:
  - [Area 1 - Why important]
  - [Area 2 - Why important]
- **Effort**: [Estimate]

### UI Testing
- **Current State**: [Assessment]
- **Recommendations**:
  - [Test 1 - Rationale]
  - [Test 2 - Rationale]
- **Effort**: [Estimate]

## Performance Optimization

### Performance Issues Found
| Area | Issue | Impact | Recommendation |
|------|-------|--------|----------------|
| [Location] | [Problem] | [User impact] | [Solution] |

### Optimization Priorities
1. **[Optimization 1]** - High impact, low effort
2. **[Optimization 2]** - Medium impact, medium effort
3. **[Optimization 3]** - High impact, high effort

## Security & Privacy

### Security Improvements
- [ ] [Security improvement 1]
- [ ] [Security improvement 2]

### Privacy Enhancements
- [ ] [Privacy enhancement 1]
- [ ] [Privacy enhancement 2]

## UI/UX Improvements

### HIG Compliance
- **Current State**: [Assessment]
- **Recommendations**:
  - [Issue 1 - Fix]
  - [Issue 2 - Fix]

### Accessibility
- **Current State**: [Assessment]
- **Priority Improvements**:
  - [ ] [Improvement 1]
  - [ ] [Improvement 2]

## Documentation

### Documentation to Create
- [ ] [Doc 1 - Purpose]
- [ ] [Doc 2 - Purpose]

### Documentation to Update
- [ ] [Doc 1 - What needs updating]
- [ ] [Doc 2 - What needs updating]

## Success Metrics

### Before Improvements
- [Metric 1]: [Current value]
- [Metric 2]: [Current value]
- [Metric 3]: [Current value]

### After Improvements (Expected)
- [Metric 1]: [Target value]
- [Metric 2]: [Target value]
- [Metric 3]: [Target value]

## Related Documents
- [analysis-report.md](./analysis-report.md) - Full analysis
- [issues.md](./issues.md) - Issues tracker
- [roadmap.md](./roadmap.md) - Improvement roadmap
```

**File 3: issues.md**
```markdown
# [App Name] - Issues Tracker

**Last Updated**: [Date]

## Critical Issues (Fix Immediately)

### Issue 1: [Title]
- **Category**: [Bug/Architecture/Performance/Security]
- **Location**: `File.swift:Line`
- **Severity**: Critical
- **Impact**: [How this affects users or app stability]
- **Description**: [Detailed description]
- **Reproduction**: [How to reproduce if bug]
- **Recommendation**: [How to fix]
- **Effort**: [Estimate]
- **Status**: [ ] Open / [ ] In Progress / [ ] Fixed

### Issue 2: [Title]
[Same structure]

## High Priority Issues (Fix Soon)

### Issue 3: [Title]
- **Category**: [Category]
- **Location**: `File.swift:Line`
- **Severity**: High
- **Impact**: [Impact description]
- **Description**: [Details]
- **Recommendation**: [Solution]
- **Effort**: [Estimate]
- **Status**: [ ] Open / [ ] In Progress / [ ] Fixed

## Medium Priority Issues (Plan to Fix)

### Issue 4: [Title]
- **Category**: [Category]
- **Location**: `File.swift:Line`
- **Severity**: Medium
- **Impact**: [Impact description]
- **Description**: [Details]
- **Recommendation**: [Solution]
- **Effort**: [Estimate]
- **Status**: [ ] Open

## Low Priority Issues (Nice to Have)

### Issue 5: [Title]
- **Category**: [Category]
- **Location**: `File.swift:Line`
- **Severity**: Low
- **Impact**: [Impact description]
- **Description**: [Details]
- **Recommendation**: [Solution]
- **Effort**: [Estimate]
- **Status**: [ ] Open

## Issues by Category

### Architecture Issues
- [Issue #1 - Title]
- [Issue #2 - Title]

### Code Quality Issues
- [Issue #3 - Title]
- [Issue #4 - Title]

### Performance Issues
- [Issue #5 - Title]

### Security Issues
- [Issue #6 - Title]

### UI/UX Issues
- [Issue #7 - Title]

### Testing Issues
- [Issue #8 - Title]

## Issues Summary

| Priority | Count | Resolved | Remaining |
|----------|-------|----------|-----------|
| Critical | [X] | [X] | [X] |
| High | [X] | [X] | [X] |
| Medium | [X] | [X] | [X] |
| Low | [X] | [X] | [X] |
| **Total** | **[X]** | **[X]** | **[X]** |

## Resolution Progress

- [X] Issue #1 - [Title] - Fixed on [Date]
- [ ] Issue #2 - [Title] - In progress
- [ ] Issue #3 - [Title] - Open

## Notes

[Any additional context about issues, patterns observed, or considerations]
```

**File 4: roadmap.md**
```markdown
# [App Name] - Improvement Roadmap

**Last Updated**: [Date]
**Analysis Date**: [Date]

## Roadmap Overview

```
Stabilize      Improve        Modernize      Enhance
|=============|=============|=============|============>
Weeks 1-2     Weeks 3-8     Months 3-6    Ongoing
```

## Phase 1: Stabilize (Weeks 1-2)

**Goal**: Fix critical issues and implement quick wins

### Critical Fixes
- [ ] [Critical issue 1] - [Effort] - Due: [Date]
- [ ] [Critical issue 2] - [Effort] - Due: [Date]

### Quick Wins
- [ ] [Quick win 1] - [Benefit] - [Effort]
- [ ] [Quick win 2] - [Benefit] - [Effort]
- [ ] [Quick win 3] - [Benefit] - [Effort]

### Success Criteria
- All critical issues resolved
- No crashes on critical paths
- Quick wins shipped

## Phase 2: Improve (Weeks 3-8)

**Goal**: Refactor priority areas and improve code quality

### Week 3-4: Architecture Improvements
- [ ] [Refactoring 1] - [Files affected]
- [ ] [Refactoring 2] - [Files affected]
- [ ] [Improvement 1]

### Week 5-6: Code Quality
- [ ] [Quality improvement 1]
- [ ] [Add tests for critical areas]
- [ ] [Update dependencies]

### Week 7-8: Performance & UX
- [ ] [Performance optimization 1]
- [ ] [UX improvement 1]
- [ ] [Accessibility improvements]

### Success Criteria
- Code quality score improved to [X/10]
- Test coverage at [X%]
- Performance metrics improved by [X%]

## Phase 3: Modernize (Months 3-6)

**Goal**: Major technical improvements and migrations

### Month 3: [Focus Area]
- [ ] [Major improvement 1]
- [ ] [Migration step 1]

### Month 4: [Focus Area]
- [ ] [Major improvement 2]
- [ ] [Migration step 2]

### Month 5-6: [Focus Area]
- [ ] [Complete migration]
- [ ] [Feature enhancements]
- [ ] [Comprehensive testing]

### Success Criteria
- [Major goal achieved]
- [Migration completed]
- [New capabilities enabled]

## Phase 4: Enhance (Ongoing)

**Goal**: Continuous improvement and new features

### Continuous Improvements
- Regular dependency updates
- Code quality maintenance
- Performance monitoring
- Technical debt management

### New Features
- [Feature 1] - [When]
- [Feature 2] - [When]
- [Feature 3] - [When]

## Milestones

### Milestone 1: Critical Issues Resolved
**Target**: [Date - Week 2]
- All critical issues fixed
- Quick wins implemented
- App stability improved

### Milestone 2: Code Quality Improved
**Target**: [Date - Week 8]
- Refactoring complete
- Test coverage at target
- Dependencies updated

### Milestone 3: Modernization Complete
**Target**: [Date - Month 6]
- Migrations finished
- New architecture stabilized
- Performance optimized

## Effort Estimates

### Quick Wins (1-2 Weeks Total)
| Item | Effort | Priority |
|------|--------|----------|
| [Quick win 1] | [X hours] | High |
| [Quick win 2] | [X hours] | High |
| [Quick win 3] | [X hours] | Medium |

### Medium Effort (1-2 Months Total)
| Item | Effort | Priority |
|------|--------|----------|
| [Item 1] | [X weeks] | High |
| [Item 2] | [X weeks] | Medium |

### Large Effort (3-6 Months Total)
| Item | Effort | Priority |
|------|--------|----------|
| [Item 1] | [X months] | High |
| [Item 2] | [X months] | Medium |

## Resource Requirements

- **Development**: [X hours/week]
- **Testing**: [X hours/week]
- **Code Review**: [X hours/week]
- **Documentation**: [X hours]

## Risks & Dependencies

### Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk 1] | High/Med/Low | [Strategy] |
| [Risk 2] | High/Med/Low | [Strategy] |

### Dependencies
- [Dependency 1 - Impact if delayed]
- [Dependency 2 - Impact if delayed]

## Success Metrics

### Technical Metrics
- **Code Quality**: [Current X/10] → [Target Y/10]
- **Test Coverage**: [Current X%] → [Target Y%]
- **Build Time**: [Current Xs] → [Target Ys]
- **Crash-Free Rate**: [Current X%] → [Target Y%]

### User-Facing Metrics
- **App Launch Time**: [Current Xs] → [Target Ys]
- **Screen Load Time**: [Current Xs] → [Target Ys]
- **User Rating**: [Current X.X] → [Target Y.Y]

## Related Documents
- [analysis-report.md](./analysis-report.md) - Full analysis
- [recommendations.md](./recommendations.md) - Detailed recommendations
- [issues.md](./issues.md) - Issues tracker
```

#### Step 5: Provide Actionable Roadmap

Summarize the created documentation and next steps:

**Phase 1: Stabilize (Weeks 1-2)**
- Fix critical issues
- Address immediate bugs
- Implement quick wins

**Phase 2: Improve (Weeks 3-8)**
- Refactor priority areas
- Improve architecture consistency
- Add missing tests
- Update dependencies

**Phase 3: Modernize (Months 3-6)**
- Architecture migration (if needed)
- Tech stack updates (SwiftUI, etc.)
- Feature enhancements
- Performance optimization

**Phase 4: Enhance (Ongoing)**
- New features
- Continuous improvement
- Best practices maintenance

#### Existing App Analysis Tips

**Be Thorough but Practical:**
- Don't recommend rewriting unless truly necessary
- Prioritize impact vs effort
- Consider team bandwidth
- Balance idealism with pragmatism

**Respect Existing Decisions:**
- Understand why current choices were made
- Some "anti-patterns" may have valid reasons
- Consider historical context
- Be constructive, not critical

**Focus on Value:**
- Prioritize user-facing improvements
- Balance technical debt with features
- Quick wins build momentum
- Long-term vision with short-term gains

**Consider Migration Paths:**
- Incremental over big-bang
- Feature-by-feature migration
- Hybrid approaches during transition
- Risk mitigation strategies

## Planning Tips

### Ask Questions Early
- Don't assume requirements
- Clarify ambiguous needs
- Understand constraints upfront
- Use AskUserQuestion tool to gather context

### Tailor to Project Type

**Personal Projects:**
- Simpler architecture often better
- Focus on learning and shipping
- Can use latest iOS versions
- Fewer third-party dependencies

**Client Projects:**
- Document everything
- Consider maintenance burden
- Balance features vs timeline
- Professional testing standards

**Startups:**
- Ship fast, iterate
- Plan for scale but start simple
- Analytics crucial
- User feedback loops important

### Be Pragmatic
- Perfect is enemy of good
- Start simple, refine later
- Don't over-engineer for MVP
- Focus on core value proposition

### Think Mobile-First
- Offline-first considerations
- Battery and performance
- Small screen constraints
- Touch interactions
- iOS platform conventions

## References

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- architecture-guide.md - Detailed architecture decisions
- tech-stack-options.md - Technology selection guide
- planning-checklist.md - Comprehensive planning checklist

## Notes

- Use planning-checklist.md for comprehensive phase-by-phase planning
- Refer to architecture-guide.md for detailed architecture patterns
- Check tech-stack-options.md for technology recommendations
- Always generate the planning document for user reference
- Tailor depth of planning to user's needs and project type
- Use AskUserQuestion to clarify requirements and preferences
