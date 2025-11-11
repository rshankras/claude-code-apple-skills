# Comprehensive App Planning Checklist

Complete checklist for iOS/Swift app planning covering all phases from concept to distribution, plus existing app audit checklist.

---

## Existing App Audit Checklist

**Use this section when analyzing an existing iOS app. For new apps, skip to "Phase 1: Product Planning" below.**

### Discovery & Understanding

#### Codebase Structure
- [ ] Identify project organization (by feature, by layer, by module)
- [ ] Count total Swift files
- [ ] Identify number of screens/features
- [ ] Locate main entry points (App/SceneDelegate)
- [ ] Find configuration files (Info.plist, xcconfig)
- [ ] Check for documentation (README, inline docs)

#### Tech Stack Detection
- [ ] **UI Framework**: Determine SwiftUI vs UIKit vs Hybrid
- [ ] **iOS Deployment Target**: Check minimum iOS version
- [ ] **Architecture Pattern**: Identify MVVM, MVC, TCA, VIPER, or mixed
- [ ] **Persistence**: Detect Core Data, SwiftData, Realm, UserDefaults, or other
- [ ] **Networking**: Identify URLSession, Alamofire, or custom implementation
- [ ] **Dependency Management**: Check for SPM (Package.swift), CocoaPods (Podfile), Carthage
- [ ] **Third-Party Dependencies**: List all external libraries
- [ ] **Testing Framework**: Check for XCTest, Quick/Nimble, or other

### Architecture Analysis

#### Pattern Consistency
- [ ] Architecture pattern used consistently across features
- [ ] Clear separation of concerns (Model/View/ViewModel or equivalent)
- [ ] Business logic properly separated from UI
- [ ] Data layer properly abstracted
- [ ] No massive view controllers (files >500 lines)

#### Code Organization
- [ ] Logical folder structure
- [ ] Related code grouped together
- [ ] Clear naming conventions followed
- [ ] Appropriate use of MARK comments
- [ ] Extensions organized logically

#### Architecture Quality Rating
- [ ] Rate overall architecture (1-10)
- [ ] Note major architecture issues
- [ ] Identify inconsistencies
- [ ] Document mixed patterns

### Tech Stack Evaluation

#### UI Framework Assessment
- [ ] SwiftUI/UIKit choice appropriate for requirements
- [ ] If hybrid, transition strategy is clear
- [ ] UI framework usage is consistent
- [ ] No unnecessary framework mixing

#### Dependency Health
- [ ] All dependencies actively maintained
- [ ] No deprecated dependencies
- [ ] Dependencies are up to date
- [ ] No conflicting dependencies
- [ ] Dependency count is reasonable (<10 recommended)
- [ ] Each dependency has clear purpose

#### iOS Version Support
- [ ] Deployment target is appropriate
- [ ] Not supporting unnecessarily old iOS versions
- [ ] Using modern APIs where possible
- [ ] Not missing features due to low deployment target

### Code Quality Assessment

#### File Size Analysis
- [ ] Identify files over 300 lines
- [ ] Note files over 500 lines (refactoring candidates)
- [ ] Check for massive files (>1000 lines - urgent refactoring)
- [ ] Average file size is reasonable

#### Code Quality Checks
- [ ] Consistent naming conventions
- [ ] No force unwrapping (!) without good reason
- [ ] Proper optional handling (guard, if let, ??)
- [ ] No retain cycles (weak self in closures)
- [ ] Proper error handling (not silent try?)
- [ ] Comments where needed (not excessive)
- [ ] No commented-out code
- [ ] No TODO/FIXME without tracking

#### Code Duplication
- [ ] Check for repeated code patterns
- [ ] Identify opportunities for extraction
- [ ] Note copy-pasted code
- [ ] Identify missing abstractions

### Feature Analysis

#### Current Features
- [ ] List all major features
- [ ] Document feature completeness
- [ ] Identify half-implemented features
- [ ] Note feature quality issues

#### Feature Organization
- [ ] Features logically organized
- [ ] Feature code is cohesive
- [ ] Features properly separated
- [ ] Shared code properly extracted

#### Missing or Incomplete
- [ ] Identify missing critical features
- [ ] Note incomplete implementations
- [ ] Document feature gaps
- [ ] Identify user pain points

### Performance & Best Practices

#### SwiftUI Patterns (if applicable)
- [ ] Proper @State, @StateObject, @ObservedObject usage
- [ ] No heavy computation in body
- [ ] Views broken into components
- [ ] Single source of truth maintained
- [ ] No ViewModels created in body

#### UIKit Patterns (if applicable)
- [ ] Proper view controller lifecycle
- [ ] No view logic in controllers
- [ ] Reusable views extracted
- [ ] Proper delegation patterns

#### Core Data Usage (if applicable)
- [ ] Using appropriate context (viewContext, background)
- [ ] Checking hasChanges before save
- [ ] Proper error handling on saves
- [ ] Efficient fetch requests
- [ ] No NSFetchRequest in loops
- [ ] Proper relationship handling

#### Memory Management
- [ ] Check for [weak self] in closures
- [ ] Delegates marked as weak
- [ ] No obvious retain cycles
- [ ] Proper deinit for cleanup

#### Error Handling
- [ ] Consistent error handling approach
- [ ] User-facing error messages
- [ ] Not swallowing errors silently (try?)
- [ ] Logging errors appropriately

### UI/UX Assessment

#### HIG Compliance (Basic Check)
- [ ] Standard navigation patterns used
- [ ] Appropriate spacing and layout
- [ ] Consistent visual design
- [ ] Platform-appropriate controls

#### Accessibility
- [ ] VoiceOver labels present
- [ ] Dynamic Type support
- [ ] Color contrast adequate
- [ ] Accessibility traits set
- [ ] Accessibility tested

#### Navigation
- [ ] Clear navigation hierarchy
- [ ] Navigation pattern is consistent
- [ ] Back navigation works correctly
- [ ] Deep linking (if applicable)

#### Design Consistency
- [ ] Consistent color usage
- [ ] Consistent typography
- [ ] Consistent spacing
- [ ] Reusable UI components

### Testing

#### Test Coverage
- [ ] Unit tests exist
- [ ] Estimate test coverage (%)
- [ ] Critical paths tested
- [ ] ViewModels tested
- [ ] Business logic tested

#### Test Quality
- [ ] Tests are meaningful
- [ ] Tests are maintainable
- [ ] Tests run reliably
- [ ] No flaky tests
- [ ] Good test organization

#### Testing Gaps
- [ ] Identify untested critical code
- [ ] Note missing test categories
- [ ] Assess risk of low coverage

### Security & Privacy

#### Security Checks
- [ ] No hardcoded secrets/API keys
- [ ] Sensitive data in Keychain
- [ ] HTTPS for all connections
- [ ] Proper authentication handling
- [ ] Input validation present

#### Privacy
- [ ] Privacy policy exists (if needed)
- [ ] Proper permission requests
- [ ] User data handled correctly
- [ ] No unnecessary data collection

### Distribution & Deployment

#### App Store Presence
- [ ] App Store listing complete
- [ ] App screenshots current
- [ ] App description accurate
- [ ] Version number scheme
- [ ] Release notes maintained

#### Build Configuration
- [ ] Proper build configurations (Debug/Release)
- [ ] Code signing setup correctly
- [ ] No debug code in release builds
- [ ] Build optimization enabled

### Issues Prioritization

#### Critical Issues (Must Fix)
- [ ] List critical bugs
- [ ] Note security vulnerabilities
- [ ] Document crashes
- [ ] Identify data loss risks

#### High Priority (Should Fix Soon)
- [ ] Architecture problems
- [ ] Major performance issues
- [ ] Serious technical debt
- [ ] User experience problems

#### Medium Priority (Plan to Fix)
- [ ] Code quality issues
- [ ] Minor performance issues
- [ ] Missing best practices
- [ ] Maintainability concerns

#### Low Priority (Nice to Have)
- [ ] Code style improvements
- [ ] Minor optimizations
- [ ] Documentation improvements

### Analysis Summary

#### Overall Assessment
- [ ] Overall app health rating (Excellent/Good/Fair/Needs Work)
- [ ] Top 3 strengths
- [ ] Top 3 concerns
- [ ] Biggest risk
- [ ] Biggest opportunity

#### Recommendations Summary
- [ ] Immediate actions (this week)
- [ ] Short-term improvements (1-2 months)
- [ ] Long-term strategy (3-6 months)
- [ ] Tech stack changes (if any)
- [ ] Architecture changes (if any)

#### Effort Estimates
- [ ] Quick wins identified (1-2 weeks)
- [ ] Medium efforts listed (1-2 months)
- [ ] Large efforts noted (3-6 months)
- [ ] Total estimated effort for main improvements

---

## NEW APP PLANNING

**Use the sections below when planning a new iOS app from scratch.**

## Phase 1: Product Planning

### App Concept
- [ ] Define core problem the app solves
- [ ] Identify unique value proposition
- [ ] Research competing apps (if applicable)
- [ ] Define success criteria

### Target Audience
- [ ] Identify primary user demographic
- [ ] Define user goals and pain points
- [ ] Create 1-2 user personas (if helpful)
- [ ] Understand user context (where, when, why they'll use the app)

### Feature Planning
- [ ] List all potential features
- [ ] Categorize features (MVP, v2, Future)
- [ ] Prioritize MVP features by value
- [ ] Estimate complexity for each feature
- [ ] Define feature dependencies
- [ ] Identify potential scope creep risks

### User Experience Planning
- [ ] Map primary user journeys
- [ ] Identify key touchpoints
- [ ] Define success metrics per journey
- [ ] Plan for edge cases and errors
- [ ] Consider first-time user experience
- [ ] Plan returning user experience

## Phase 2: Technical Planning

### Architecture Decisions
- [ ] Choose architecture pattern (MVVM, TCA, VIPER, MVC)
- [ ] Document architecture decision rationale
- [ ] Plan for testability
- [ ] Consider team experience with pattern
- [ ] Evaluate scalability needs

### Data Modeling
- [ ] Identify main entities
- [ ] Define entity relationships
- [ ] Plan data flow (source → storage → display)
- [ ] Consider data migration needs
- [ ] Plan for data validation
- [ ] Define data retention policies

### Persistence Layer
- [ ] Choose storage solution:
  - [ ] Core Data (complex data, relationships)
  - [ ] SwiftData (iOS 17+, modern approach)
  - [ ] UserDefaults (simple settings)
  - [ ] Realm (alternative to Core Data)
  - [ ] File system (documents, cache)
  - [ ] Keychain (sensitive data)
- [ ] Plan offline capabilities
- [ ] Design sync strategy (if cloud sync needed)
- [ ] Plan data backup/restore

### Tech Stack Selection
- [ ] **UI Framework**:
  - [ ] SwiftUI (modern, declarative)
  - [ ] UIKit (mature, more control)
  - [ ] Hybrid approach
- [ ] **Minimum iOS version**:
  - [ ] Consider feature requirements
  - [ ] Check target audience device stats
  - [ ] Balance new features vs user reach
- [ ] **Networking layer**:
  - [ ] URLSession (native, sufficient for most)
  - [ ] Alamofire (convenience, community)
  - [ ] Custom wrapper
- [ ] **Dependency management**:
  - [ ] Swift Package Manager (recommended)
  - [ ] CocoaPods
  - [ ] Carthage
  - [ ] Manual
- [ ] **Third-party libraries** (evaluate each):
  - [ ] Authentication (if needed)
  - [ ] Analytics
  - [ ] Crash reporting
  - [ ] Image loading/caching
  - [ ] UI components
  - [ ] Utility libraries

### Project Structure
- [ ] Define folder organization:
  - [ ] By feature (recommended for medium+ apps)
  - [ ] By layer (Model, View, ViewModel)
  - [ ] By module (for large apps)
- [ ] Plan file naming conventions
- [ ] Define code organization standards
- [ ] Plan for shared/common code
- [ ] Consider modularization needs

### Backend & APIs
- [ ] Define API requirements
- [ ] Choose backend approach:
  - [ ] Custom backend
  - [ ] BaaS (Firebase, Supabase, etc.)
  - [ ] CloudKit
  - [ ] No backend needed
- [ ] Define API contracts
- [ ] Plan API versioning strategy
- [ ] Design error handling for network issues
- [ ] Plan for API rate limiting

## Phase 3: UI/UX Planning

### Design System
- [ ] **Color Palette**:
  - [ ] Primary colors
  - [ ] Secondary colors
  - [ ] Semantic colors (success, error, warning)
  - [ ] Light mode palette
  - [ ] Dark mode palette
  - [ ] Verify WCAG contrast ratios
- [ ] **Typography**:
  - [ ] Font selection (SF Pro, custom)
  - [ ] Text styles hierarchy
  - [ ] Dynamic Type support plan
  - [ ] Minimum/maximum font sizes
- [ ] **Spacing System**:
  - [ ] Base unit (8pt recommended)
  - [ ] Spacing scale (8, 16, 24, 32, etc.)
  - [ ] Consistent padding/margins
- [ ] **Component Library**:
  - [ ] List reusable components
  - [ ] Define component states
  - [ ] Plan component customization

### Navigation Architecture
- [ ] Choose primary navigation pattern:
  - [ ] Tab Bar (2-5 main sections)
  - [ ] Sidebar (iPad, complex hierarchies)
  - [ ] Navigation Stack (linear flows)
  - [ ] Custom navigation
- [ ] Map navigation hierarchy
- [ ] Plan deep linking structure
- [ ] Define modal/sheet presentation rules
- [ ] Plan navigation state preservation

### Screen Planning
- [ ] List all screens/views
- [ ] Create screen hierarchy diagram
- [ ] Define screen relationships
- [ ] Plan screen transitions
- [ ] Design empty states for each screen
- [ ] Design loading states
- [ ] Design error states
- [ ] Plan pull-to-refresh patterns

### Accessibility Planning
- [ ] **Dynamic Type**:
  - [ ] Use system text styles
  - [ ] Test at all accessibility sizes
  - [ ] Ensure layout adapts
- [ ] **VoiceOver**:
  - [ ] Plan accessibility labels
  - [ ] Define accessibility hints
  - [ ] Set accessibility traits
  - [ ] Plan focus order
- [ ] **Other Accessibility**:
  - [ ] Color contrast compliance
  - [ ] Reduce motion support
  - [ ] Large content viewer support
  - [ ] Switch control compatibility
  - [ ] Voice control support

### Responsive Design
- [ ] Plan for different iPhone sizes
- [ ] Design for iPad (if supporting)
- [ ] Plan landscape orientations
- [ ] Test on smallest supported device
- [ ] Consider Dynamic Island (iPhone 14 Pro+)
- [ ] Plan for safe area insets

### Onboarding & Education
- [ ] Design first launch experience
- [ ] Plan permission requests (timing and rationale)
- [ ] Create educational moments
- [ ] Design tutorial/walkthrough (if needed)
- [ ] Plan skip options

## Phase 4: Non-Functional Requirements

### Performance Requirements
- [ ] Define target devices:
  - [ ] iPhone only
  - [ ] iPhone + iPad
  - [ ] Mac Catalyst
  - [ ] Apple Watch
- [ ] Set performance benchmarks:
  - [ ] App launch time target
  - [ ] Screen load time targets
  - [ ] Animation frame rate (60fps)
  - [ ] API response time tolerance
- [ ] Plan memory management strategy
- [ ] Consider battery usage optimization
- [ ] Plan app size target

### Security & Privacy
- [ ] **Authentication** (if needed):
  - [ ] Choose method (OAuth, Sign in with Apple, email, etc.)
  - [ ] Plan session management
  - [ ] Implement biometric auth option
  - [ ] Design password requirements
- [ ] **Data Protection**:
  - [ ] Identify sensitive data
  - [ ] Plan encryption at rest
  - [ ] Plan encryption in transit (HTTPS)
  - [ ] Use Keychain for credentials
  - [ ] Plan for data deletion
- [ ] **Privacy Compliance**:
  - [ ] Create privacy policy
  - [ ] Plan privacy nutrition label
  - [ ] Implement GDPR/CCPA if applicable
  - [ ] Plan user data export
  - [ ] Plan user data deletion
- [ ] **App Transport Security**:
  - [ ] Ensure all connections use HTTPS
  - [ ] Document any ATS exceptions

### Testing Strategy
- [ ] **Unit Testing**:
  - [ ] Define coverage goal (70%+ recommended)
  - [ ] Identify critical paths to test
  - [ ] Plan test data management
  - [ ] Choose testing framework (XCTest)
- [ ] **UI Testing**:
  - [ ] Identify key user flows to test
  - [ ] Plan UI test maintenance strategy
  - [ ] Consider snapshot testing
- [ ] **Integration Testing**:
  - [ ] Plan API integration tests
  - [ ] Test data layer
  - [ ] Test third-party integrations
- [ ] **Manual Testing**:
  - [ ] Create test plans
  - [ ] Plan device testing matrix
  - [ ] Beta testing approach
- [ ] **Accessibility Testing**:
  - [ ] Test with VoiceOver
  - [ ] Test with Dynamic Type
  - [ ] Use Accessibility Inspector

### Analytics & Monitoring
- [ ] **Analytics**:
  - [ ] Choose analytics tool
  - [ ] Define key events to track
  - [ ] Plan user property tracking
  - [ ] Ensure privacy compliance
  - [ ] Plan funnel analysis
- [ ] **Crash Reporting**:
  - [ ] Choose crash reporting tool
  - [ ] Plan symbolication process
  - [ ] Define crash severity levels
  - [ ] Set up alert thresholds
- [ ] **Performance Monitoring**:
  - [ ] Monitor app start time
  - [ ] Track screen load times
  - [ ] Monitor memory usage
  - [ ] Track network performance
- [ ] **User Feedback**:
  - [ ] Plan in-app feedback mechanism
  - [ ] Monitor App Store reviews
  - [ ] Plan feature request tracking

### Localization & Internationalization
- [ ] Plan initial language(s)
- [ ] Use NSLocalizedString for all text
- [ ] Avoid hardcoded strings
- [ ] Plan for RTL languages (if applicable)
- [ ] Consider number/date formatting
- [ ] Plan for text expansion
- [ ] Test with pseudo-localization

## Phase 5: Distribution & Business

### App Store Preparation
- [ ] **App Metadata**:
  - [ ] Choose app name
  - [ ] Check name availability
  - [ ] Write app description
  - [ ] Select app category
  - [ ] Define keywords
  - [ ] Choose age rating
- [ ] **Bundle Identifier**:
  - [ ] Choose bundle ID (com.company.appname)
  - [ ] Register bundle ID in Apple Developer
  - [ ] Plan for extensions/widgets
- [ ] **Screenshots & Media**:
  - [ ] Plan screenshot strategy
  - [ ] Design promotional images
  - [ ] Plan app preview video (optional)
  - [ ] Create app icon (required sizes)
- [ ] **App Store Listing**:
  - [ ] Write promotional text
  - [ ] Plan what's new descriptions
  - [ ] Design marketing assets

### Monetization (if applicable)
- [ ] Choose business model:
  - [ ] Free (with limitations/ads)
  - [ ] Paid (one-time purchase)
  - [ ] Freemium (IAP to unlock)
  - [ ] Subscription
- [ ] **In-App Purchases** (if using):
  - [ ] Define IAP products
  - [ ] Set pricing tiers
  - [ ] Plan purchase flow UX
  - [ ] Implement StoreKit
  - [ ] Plan receipt validation
- [ ] **Subscriptions** (if using):
  - [ ] Define subscription tiers
  - [ ] Plan free trial period
  - [ ] Design subscription management UI
  - [ ] Plan renewal reminders
- [ ] **Ads** (if using):
  - [ ] Choose ad network
  - [ ] Plan ad placement
  - [ ] Ensure non-intrusive
  - [ ] Plan ad-free option

### Legal & Compliance
- [ ] Create Terms of Service
- [ ] Create Privacy Policy
- [ ] Review App Store Review Guidelines
- [ ] Check for restricted content
- [ ] Plan for content moderation (if UGC)
- [ ] Consider COPPA compliance (if children's app)

### Timeline & Milestones
- [ ] Define MVP scope
- [ ] Estimate MVP timeline
- [ ] Plan sprint/iteration schedule
- [ ] Set feature freeze date
- [ ] Plan testing period
- [ ] Set submission target date
- [ ] Plan post-launch support

### Version Planning
- [ ] Define v1.0 scope
- [ ] Plan v1.1+ features
- [ ] Plan major version milestones (2.0, etc.)
- [ ] Define versioning strategy
- [ ] Plan deprecation policy
- [ ] Consider backward compatibility

### Launch Planning
- [ ] Plan soft launch strategy
- [ ] Define launch marketing
- [ ] Prepare support resources
- [ ] Plan social media presence
- [ ] Set up website/landing page
- [ ] Plan beta testing program
- [ ] Define success metrics

## Phase 6: Development Setup

### Xcode Project Setup
- [ ] Create new Xcode project
- [ ] Configure project settings
- [ ] Set deployment target
- [ ] Add app icon
- [ ] Configure signing & capabilities
- [ ] Set up schemes (Debug, Release)
- [ ] Configure build configurations

### Version Control
- [ ] Initialize git repository
- [ ] Create .gitignore
- [ ] Define branching strategy
- [ ] Set up remote repository (GitHub, etc.)
- [ ] Plan commit conventions
- [ ] Set up pull request process

### CI/CD
- [ ] Choose CI/CD platform (GitHub Actions, Xcode Cloud, etc.)
- [ ] Set up automated builds
- [ ] Configure automated tests
- [ ] Plan automated deployment
- [ ] Set up TestFlight automation
- [ ] Configure code signing for CI

### Development Environment
- [ ] Document required tools
- [ ] Set up linting (SwiftLint)
- [ ] Configure code formatting
- [ ] Set up code review process
- [ ] Plan pair programming (if team)
- [ ] Set up development documentation

## Quick Validation Checklist

Use this for quick planning validation:

### Must Have
- [ ] Clear app purpose defined
- [ ] Target users identified
- [ ] MVP features prioritized
- [ ] Architecture pattern chosen
- [ ] Data model designed
- [ ] Tech stack selected
- [ ] Primary navigation planned
- [ ] Privacy policy created

### Should Have
- [ ] User personas created
- [ ] Design system defined
- [ ] Accessibility planned
- [ ] Testing strategy defined
- [ ] Analytics planned
- [ ] Timeline estimated
- [ ] App Store metadata prepared

### Nice to Have
- [ ] Detailed wireframes
- [ ] Complete UI specifications
- [ ] Comprehensive test plans
- [ ] Marketing strategy
- [ ] Beta testing program
- [ ] Launch plan

## References

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Privacy Best Practices](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
