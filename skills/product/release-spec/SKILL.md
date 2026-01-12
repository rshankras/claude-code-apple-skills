---
name: release-spec
description: Generates App Store release documentation including submission guide, assets, privacy compliance, and marketing strategy. Creates RELEASE_SPEC.md for app launch. Use when preparing for App Store submission.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion]
---

# Release Specification Skill

Generate comprehensive App Store release and deployment documentation for iOS/macOS apps.

## Metadata
- **Name**: release-spec
- **Version**: 1.0.0
- **Role**: Release Manager
- **Author**: ProductAgent Team

## Activation

This skill activates when the user says:
- "generate release spec"
- "create App Store submission guide"
- "write deployment documentation"
- "generate release documentation"
- "create App Store preparation guide"

## Description

You are a Release Manager AI agent specializing in iOS/macOS app releases and App Store submissions. Your job is to transform all previous specifications (PRD, Architecture, UX, Implementation, Testing, ASO) into a comprehensive release specification that guides the user through every step of preparing, submitting, and launching their app on the App Store.

## Prerequisites

Before activating this skill, ensure:
1. ASO optimization exists (from product-agent orchestration) with App Store metadata
2. ARCHITECTURE and IMPLEMENTATION_GUIDE exist with technical details
3. TEST_SPEC exists with quality checklist
4. All previous specifications are complete and approved

## Input Sources

Read and extract information from:

1. **Product development plan** (product-plan-*.md)
   - ASO optimization section (app name, subtitle, keywords, description, screenshots)
   - Positioning and brand personality
   - Target market

2. **docs/ARCHITECTURE.md**
   - Tech stack and dependencies
   - Build configuration
   - Privacy requirements

3. **docs/IMPLEMENTATION_GUIDE.md**
   - Project configuration details
   - Dependencies
   - Version numbering

4. **docs/TEST_SPEC.md**
   - Pre-submission checklist
   - Quality gates
   - Beta testing plan

## Output

Generate: **docs/RELEASE_SPEC.md**

Structure:

```markdown
# Release Specification: [App Name]

**Version**: 1.0.0
**Last Updated**: [Date]
**Release Manager**: Release Manager AI
**Platform**: iOS [Version]+
**Target Release Date**: [Date]

---

## 0. Quick Start Checklist

For the impatient release manager:

**Week -2: Preparation**
- [ ] All development complete (from IMPLEMENTATION_GUIDE)
- [ ] All tests passing (from TEST_SPEC)
- [ ] App Store assets prepared (see Section 2)
- [ ] Privacy manifest added
- [ ] TestFlight beta started

**Week -1: Beta Testing**
- [ ] Beta testers recruited (20-50 people)
- [ ] Feedback collected and addressed
- [ ] No P0 bugs reported in last 3 days
- [ ] Crash-free rate > 99.5%

**Day of Submission**:
- [ ] Final build archived
- [ ] App validated in Xcode (no errors)
- [ ] App Store Connect metadata filled
- [ ] Submit for review
- [ ] Monitor review status daily

**Post-Submission**:
- [ ] App approved (24-48 hours typically)
- [ ] Choose release date or release immediately
- [ ] Monitor crash reports and reviews
- [ ] Respond to user reviews within 24-48 hours

---

## 1. App Store Metadata

All metadata is pre-filled from ASO optimization. Verify and copy to App Store Connect.

### 1.1 Basic Information

**App Name**: [From ASO optimization]
- Character limit: 30 characters
- Must be unique on App Store
- Can include keywords for ASO

**Subtitle**: [From ASO optimization]
- Character limit: 30 characters
- Summarizes app in one line
- Appears below app name in search results

**Primary Category**: [Choose most relevant]
- Productivity
- Business
- Lifestyle
- Finance
- Health & Fitness
- Social Networking
- Photo & Video
- Entertainment
- Utilities
- Education
- [Other - see full list in App Store Connect]

**Secondary Category**: [Optional]
- Choose if app fits multiple categories
- Increases discoverability

**Content Rating**:
- [ ] 4+ (No objectionable content)
- [ ] 9+ (Infrequent/mild content)
- [ ] 12+ (Frequent/intense content)
- [ ] 17+ (Frequent/intense mature content)

**Pricing**:
- [Free] (recommended for MVP launch)
- [Paid] - Price Tier: [Select tier, e.g., $0.99, $2.99, $4.99]
- [Freemium] - Free with In-App Purchases

### 1.2 Description

**Promotional Text** (170 characters, updateable without app review):
```
[Hook from ASO optimization - first 170 characters]
```

**Full Description** (4000 characters max):
```
[Complete description from ASO optimization]

[Paste the full ASO-optimized description here]

Features:
• [Feature 1 from PRD - user benefit focused]
• [Feature 2 from PRD]
• [Feature 3 from PRD]
• [Feature 4 from PRD]

[Social proof section if available]

[Call to action]
```

**What's New** (Version 1.0.0):
```
🎉 Initial Release!

Introducing [App Name]! [One-line value proposition]

Key Features:
• [Feature 1]
• [Feature 2]
• [Feature 3]

We'd love to hear your feedback! Rate us and let us know how we can improve.
```

### 1.3 Keywords

**Keyword Field** (100 characters, comma-separated, no spaces):
```
[High-priority keywords from ASO optimization, comma-separated, exactly 100 chars]
Example: productivity,task,manager,organize,notes,planner,calendar,todo,reminder
```

**Keyword Strategy**:
- Use high-priority keywords from ASO optimization
- No spaces (use commas only)
- Don't repeat app name (automatically indexed)
- Don't use competitor names
- Use both singular and plural if room

### 1.4 Support Information

**Support URL**: https://[yourwebsite].com/support
- Must be live and functional
- Include FAQ, contact form, or email
- Respond to inquiries within 24-48 hours

**Marketing URL**: https://[yourwebsite].com
- Landing page for the app
- Can include features, screenshots, testimonials
- Optional but recommended

**Privacy Policy URL**: https://[yourwebsite].com/privacy
- **REQUIRED** for all apps
- Must disclose all data collection
- Must be accessible and readable
- Can use privacy policy generator if needed

**Copyright**: © 2024 [Your Company Name]

---

## 2. App Store Assets

### 2.1 App Icon

**Requirements**:
- Size: 1024x1024 pixels
- Format: PNG (no transparency)
- Color space: sRGB or Display P3
- File size: < 1 MB

**Design Specifications** (from DESIGN_SYSTEM.md):
```
Based on your brand colors and design system:

Background: [Brand primary color or gradient]
Icon/Symbol: [From brand identity]
Style: [Flat, skeuomorphic, gradient - match design system]

Design Tips:
- Simple and recognizable at small sizes
- No words or detailed graphics
- Avoid transparencies and rounded corners (iOS adds automatically)
- Test at multiple sizes (iPhone, iPad, App Store)
```

**Creation**:
1. Design in Figma/Sketch/Illustrator at 1024x1024px
2. Export as PNG
3. Add to `Assets.xcassets/AppIcon.appiconset/`
4. Xcode will generate all required sizes automatically

**Tools**:
- [App Icon Generator](https://appicon.co) - Generate from 1024px source
- [IconKit](https://apps.apple.com/app/iconkit/id507135296) - Mac app for icon generation

### 2.2 Screenshots

**Required Sizes**:
- **iPhone 6.7" Display** (1290 x 2796 px) - iPhone 15 Pro Max - **REQUIRED**
- **iPhone 6.5" Display** (1242 x 2688 px) - iPhone 11 Pro Max - **Recommended**
- **iPad Pro 12.9" Display** (2048 x 2732 px) - If supporting iPad

**Quantity**: 3-10 screenshots per size (5 recommended)

**Screenshot Strategy** (from ASO optimization):

**Screenshot 1: Hero/Value Proposition**
```
Content: [Main screen showing primary feature]
Caption: "[Benefit-focused headline from ASO]"

Design:
- Show actual app UI (not marketing fluff)
- Highlight key benefit with overlay text
- Use brand colors for text
- Clear, large, readable text

Device Frame: Optional (makes it look polished)
```

**Screenshot 2: Key Feature #1**
```
Content: [Feature in action - from PRD P0 features]
Caption: "[Clear outcome or benefit]"

Example for task manager:
Show: Today view with tasks checked off
Caption: "Get things done. Stay organized."
```

**Screenshot 3: Key Feature #2**
```
Content: [Second most important feature]
Caption: "[Supporting benefit]"
```

**Screenshot 4: Key Feature #3 or Social Proof**
```
Content: [Third feature OR testimonial/rating visual]
Caption: "[Supporting benefit]" OR "Loved by users - 4.8★ rating"
```

**Screenshot 5: Call to Action**
```
Content: [Final screen with clear CTA]
Caption: "Download now and [achieve benefit]"
```

**Design Tips**:
- Use localized screenshots (translate text)
- Show diverse representation
- Use actual app data (not lorem ipsum)
- Keep text minimal and large (readable on phone)
- Maintain consistent style across all screenshots
- Use status bar with good signal/battery (looks polished)

**Tools**:
- [Screenshot](https://screenshot.app) - Mac app for creating App Store screenshots
- [DaVinci Apps](https://www.davinciapps.com) - Web-based screenshot builder
- [Previewed](https://previewed.app) - Screenshot mockup tool

**Capture from Simulator**:
```bash
# Launch app in simulator (iPhone 15 Pro Max)
# Navigate to screen
# Cmd+S to save screenshot
# Screenshots saved to ~/Desktop
```

### 2.3 App Preview Video (Optional but Highly Recommended)

**Requirements**:
- Duration: 15-30 seconds
- Format: MOV or MP4, H.264 or HEVC
- Resolution: Match screenshot sizes
- File size: < 500 MB
- Orientation: Portrait

**Storyboard** (from ASO optimization):
```
0-3s:   Problem statement
        Visual: User frustrated with current solution
        Voiceover/Text: "Tired of [pain point]?"

4-10s:  Solution demonstration
        Visual: App in action, core feature
        Voiceover/Text: "Meet [App Name]. [Value proposition]"

11-20s: Key benefits showcase
        Visual: Quick cuts of 3 key features
        Voiceover/Text: "• [Benefit 1] • [Benefit 2] • [Benefit 3]"

21-25s: Additional features
        Visual: Supporting features
        Voiceover/Text: "Plus [feature 4], [feature 5]"

26-30s: Call to action
        Visual: App icon + brand
        Text: "Download [App Name] today!"
```

**Production Tips**:
- Record screen with QuickTime or built-in screen recording
- Add captions/overlays with iMovie or Final Cut Pro
- Keep it fast-paced (attention span is short)
- Use upbeat background music (royalty-free)
- Show actual app usage, not just animations

**Music Sources** (royalty-free):
- YouTube Audio Library
- Epidemic Sound
- Artlist
- Apple GarageBand loops

---

## 3. Privacy & Compliance

### 3.1 Privacy Manifest (PrivacyInfo.xcprivacy)

**Location**: `[AppName]/Resources/PrivacyInfo.xcprivacy`

**Template**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Tracking -->
    <key>NSPrivacyTracking</key>
    <false/>  <!-- Set to true if using third-party tracking SDKs -->

    <key>NSPrivacyTrackingDomains</key>
    <array>
        <!-- List domains used for tracking (if NSPrivacyTracking is true) -->
    </array>

    <!-- Data Collection -->
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <!-- Example: If collecting email for account -->
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeEmailAddress</string>

            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>  <!-- Linked to user identity -->

            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>  <!-- Not used for tracking -->

            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>

        <!-- Add more data types if collecting: -->
        <!-- NSPrivacyCollectedDataTypeName -->
        <!-- NSPrivacyCollectedDataTypePhoneNumber -->
        <!-- NSPrivacyCollectedDataTypePhysicalAddress -->
        <!-- NSPrivacyCollectedDataTypeUserID -->
        <!-- NSPrivacyCollectedDataTypePurchaseHistory -->
        <!-- NSPrivacyCollectedDataTypeLocation -->
        <!-- NSPrivacyCollectedDataTypePhotos -->
        <!-- NSPrivacyCollectedDataTypeContacts -->
        <!-- NSPrivacyCollectedDataTypeCrashData -->
        <!-- NSPrivacyCollectedDataTypePerformanceData -->
        <!-- NSPrivacyCollectedDataTypeCustomerSupport -->
        <!-- [See Apple documentation for full list] -->
    </array>

    <!-- Required Reason API Usage -->
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- Example: If using UserDefaults for app state -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>

            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>  <!-- App functionality -->
            </array>
        </dict>

        <!-- Add if using: -->
        <!-- File timestamp APIs (NSPrivacyAccessedAPICategoryFileTimestamp) -->
        <!-- System boot time APIs (NSPrivacyAccessedAPICategorySystemBootTime) -->
        <!-- Disk space APIs (NSPrivacyAccessedAPICategoryDiskSpace) -->
        <!-- Active keyboards APIs (NSPrivacyAccessedAPICategoryActiveKeyboards) -->
        <!-- [See Apple documentation for required reasons codes] -->
    </array>
</dict>
</plist>
```

**How to Fill Out**:
1. Review ARCHITECTURE.md for all data collected
2. For each data type collected:
   - Add to NSPrivacyCollectedDataTypes array
   - Specify if linked to user identity
   - Specify if used for tracking
   - Specify purpose (app functionality, analytics, etc.)
3. Review code for Required Reason APIs:
   - Search codebase for UserDefaults, FileManager, etc.
   - Add to NSPrivacyAccessedAPITypes with appropriate reason code

**Resources**:
- [Apple Privacy Manifest Documentation](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Required Reason API List](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)

### 3.2 App Privacy Details (App Store Connect)

When filling out privacy questions in App Store Connect:

**Data Collection Questions**:

For each data type (Contact Info, Health, Financial, Location, etc.):
1. **Do you collect this data?** Yes/No
2. **Is this data linked to the user?** Yes/No
3. **Is this data used for tracking?** Yes/No
4. **For what purposes?**
   - [ ] App Functionality
   - [ ] Analytics
   - [ ] Product Personalization
   - [ ] Advertising
   - [ ] Other

**Example** (Email for account creation):
```
Data Type: Email Address
Collected: Yes
Linked to User: Yes
Used for Tracking: No
Purposes: App Functionality
```

**Complete for all data from ARCHITECTURE.md**:
- User profile data (name, email, etc.)
- Usage data (if using analytics)
- Crash data (if using crash reporting)
- Device identifiers (if any)

### 3.3 Age Rating Questionnaire

Answer honestly based on app content:

**Violence**: None / Cartoon or Fantasy / Realistic / [etc.]
**Sexual Content**: None / Infrequent/Mild / Frequent/Intense
**Profanity**: None / Infrequent/Mild / Frequent/Intense
**Horror/Fear Themes**: None / Infrequent/Mild / Frequent/Intense
**Mature/Suggestive Themes**: None / Infrequent/Mild / Frequent/Intense
**Alcohol, Tobacco, Drugs**: None / Infrequent/Mild / Frequent/Intense
**Medical/Treatment Info**: None / Infrequent/Mild / Frequent/Intense
**Gambling**: None / Simulated Gambling / [etc.]
**Contests**: None / Infrequent/Mild / Frequent/Intense

**Resulting Rating**: Based on answers, App Store will assign 4+, 9+, 12+, or 17+

**For most productivity/business apps**: All "None" → 4+ rating

---

## 4. Build Configuration

### 4.1 Version Numbering

**Semantic Versioning**: MAJOR.MINOR.PATCH

```
Version: 1.0.0
├── MAJOR (1): Breaking changes, major new features
├── MINOR (0): New features, backwards compatible
└── PATCH (0): Bug fixes only

Examples:
- 1.0.0: Initial release
- 1.0.1: Bug fix (crash fix, minor issue)
- 1.1.0: New feature (added dark mode)
- 2.0.0: Major update (complete redesign)
```

**Build Number**: Auto-increment or date-based

```
Option 1: Auto-increment
1, 2, 3, 4, ...
Xcode can auto-increment on archive

Option 2: Date-based
20240115 (YYYYMMDD)
20240115.1 (if multiple builds per day)
```

**Set in Xcode**:
1. Select project → Target → General
2. Version: `1.0.0`
3. Build: `1` or `20240115`

### 4.2 Build Configuration

**Debug Configuration**:
```
Optimization Level: None [-O0]
Swift Compilation Mode: Incremental
Active Compilation Conditions: DEBUG
Other Swift Flags: -Xfrontend -debug-time-function-bodies
```

**Release Configuration**:
```
Optimization Level: Optimize for Speed [-O]
Swift Compilation Mode: Whole Module Optimization
Strip Swift Symbols: Yes
Strip Debug Symbols During Copy: Yes
Validate Workspace: Yes
Dead Code Stripping: Yes
```

**Recommended Settings**:
- Enable Bitcode: No (deprecated by Apple)
- Enable TestFlight Internal Testing: Yes
- Embed Swift Standard Libraries: Yes (automatic)

### 4.3 Code Signing

**Automatic Signing** (Recommended for individuals/small teams):
1. Select project → Target → Signing & Capabilities
2. Check "Automatically manage signing"
3. Select your Team
4. Xcode handles provisioning profiles

**Manual Signing** (For larger teams with multiple developers):
1. Create App ID in Developer Portal
2. Create Distribution Certificate
3. Create App Store Distribution Provisioning Profile
4. Download and install
5. Select profile in Xcode

**Certificate Types**:
- **Development**: For testing on devices
- **Distribution**: For TestFlight and App Store
- **Both valid**: Keep both certificates on your Mac

### 4.4 Capabilities

**Add if needed** (based on ARCHITECTURE.md):

- [ ] **Push Notifications**: If implementing notifications
- [ ] **iCloud**: If using CloudKit sync (Documents or Key-Value Storage)
- [ ] **Sign in with Apple**: If using Apple authentication
- [ ] **App Groups**: If sharing data with extensions
- [ ] **Background Modes**: If running in background (Audio, Location, Fetch)
- [ ] **Associated Domains**: If using universal links
- [ ] **Apple Pay**: If accepting payments via Apple Pay
- [ ] **In-App Purchase**: If offering IAP

**Configure in Xcode**:
1. Select Target → Signing & Capabilities
2. Click "+ Capability"
3. Select capability
4. Configure as needed

---

## 5. Pre-Submission Checklist

Before archiving and submitting, verify:

### 5.1 Development Complete
- [ ] All features from PRD implemented (P0 features)
- [ ] All acceptance criteria met (from PRD user stories)
- [ ] All screens from UX_SPEC implemented
- [ ] All P0 bugs fixed
- [ ] Code reviewed (if team)
- [ ] No TODO comments or debug code
- [ ] No hardcoded values (API endpoints, keys)
- [ ] Analytics integrated (if using)

### 5.2 Testing Complete
- [ ] All unit tests pass (from TEST_SPEC)
- [ ] All UI tests pass (critical user journeys)
- [ ] Manual regression testing complete
- [ ] Tested on multiple devices (iPhone SE, Pro Max, iPad if supported)
- [ ] Tested on iOS minimum version (iOS 17.0)
- [ ] Tested on latest iOS version
- [ ] Dark mode tested
- [ ] VoiceOver tested (accessibility)
- [ ] Dynamic Type tested (all text sizes)
- [ ] Network conditions tested (offline, slow, timeout)
- [ ] Edge cases tested (empty states, errors, invalid inputs)
- [ ] Performance acceptable (no lag, smooth scrolling)
- [ ] No memory leaks (checked with Instruments)
- [ ] Crash-free rate > 99.5% (TestFlight data)

### 5.3 Assets Prepared
- [ ] App icon 1024x1024 added to Assets.xcassets
- [ ] Launch screen configured
- [ ] App Store screenshots created (5 per size)
- [ ] App preview video created (optional)
- [ ] All images optimized (compressed)
- [ ] All required sizes provided

### 5.4 Metadata Ready
- [ ] App name finalized (30 chars max)
- [ ] Subtitle written (30 chars max)
- [ ] Description written (from ASO, 4000 chars max)
- [ ] Promotional text written (170 chars)
- [ ] Keywords optimized (100 chars)
- [ ] What's New written (v1.0.0)
- [ ] Support URL live and functional
- [ ] Privacy Policy URL live and accessible
- [ ] Categories selected (primary + secondary)
- [ ] Age rating determined

### 5.5 Privacy & Compliance
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) added
- [ ] All data collection disclosed in manifest
- [ ] Privacy details filled in App Store Connect
- [ ] Age rating questionnaire completed
- [ ] Terms of Service prepared (if needed)
- [ ] COPPA compliance verified (if targeting children < 13)
- [ ] GDPR compliance verified (if targeting EU users)
- [ ] No use of private APIs
- [ ] No trademark violations
- [ ] Third-party licenses attributed (if using OSS)

### 5.6 Technical Requirements
- [ ] Minimum deployment target set (iOS 17.0 or appropriate)
- [ ] No compiler warnings (or all warnings addressed)
- [ ] App validated in Xcode (no errors)
- [ ] No crashes on launch or critical flows
- [ ] Universal links working (if implemented)
- [ ] Deep links working (if implemented)
- [ ] Notifications working (if implemented)
- [ ] In-app purchases working (if implemented)

---

## 6. Submission Process

### 6.1 Create App in App Store Connect

1. **Go to App Store Connect**: [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **My Apps** → Click **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: [App Name from ASO] (must be unique)
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select from dropdown (must match Xcode)
   - **SKU**: Unique identifier (e.g., `com.yourcompany.appname`)
   - **User Access**: Full Access (or Limited Access if needed)
4. Click **Create**

### 6.2 Fill in App Information

**App Information Tab**:
- **Subtitle**: [30 chars from ASO]
- **Categories**: [Primary and Secondary]
- **Content Rights**: Check if contains, displays, or accesses third-party content
- **Age Rating**: Click Edit → Complete questionnaire
- **Privacy Policy URL**: [Your privacy URL]
- **User Privacy Choices URL**: (Optional, only if selling user data)

**Pricing and Availability Tab**:
- **Price Schedule**: Free / [Select tier]
- **Availability**: All territories (or select specific countries)
- **Pre-Order**: No (for initial launch)

### 6.3 Prepare for Submission

**Version Information** (under App Store → iOS App → Version):
- **Screenshot Previews**: Upload all sizes
  - iPhone 6.7": Upload 5 screenshots
  - iPhone 6.5": Upload 5 screenshots
  - iPad Pro 12.9": Upload screenshots (if supporting iPad)
- **App Preview Video**: Upload (optional)
- **Promotional Text**: [170 chars from ASO]
- **Description**: [Full description from ASO]
- **Keywords**: [100 chars from ASO]
- **Support URL**: [Your support URL]
- **Marketing URL**: [Your marketing URL] (optional)
- **Version**: 1.0.0
- **Copyright**: © 2024 [Your Company Name]
- **App Privacy**: Click "Get Started" → Fill out privacy questionnaire

### 6.4 Archive and Upload Build

**In Xcode**:

1. **Select Device**: Any iOS Device (not simulator)
2. **Product → Archive**
   - Xcode will build for release configuration
   - Archive will appear in Organizer window
3. **In Organizer**:
   - Select your archive
   - Click **Validate App** (checks for errors)
   - Fix any errors or warnings
   - Click **Distribute App**
   - Select **App Store Connect**
   - Select **Upload**
   - Choose options:
     - Upload symbols: Yes (for crash reports)
     - Manage version and build number: Yes
   - Click **Upload**
4. **Wait for Processing** (10-30 minutes)
   - Build will appear in App Store Connect under TestFlight
   - You'll receive email when ready

**Alternative: Using Fastlane** (automated):
```bash
# Install Fastlane
brew install fastlane

# Initialize
cd /path/to/project
fastlane init

# Edit Fastfile
# Add upload lane (see Section 9 for details)

# Upload to App Store Connect
fastlane release
```

### 6.5 Select Build and Submit

**In App Store Connect**:

1. **Go to App Store → iOS App → Version 1.0.0**
2. **Build**: Click **+** → Select your uploaded build
3. **App Review Information**:
   - **First Name**, **Last Name**: Your contact info
   - **Phone Number**: Your phone
   - **Email**: Your email
   - **Sign-In Required**: Check if app requires login
     - If yes, provide demo account credentials
   - **Notes**: Any special instructions for reviewers
     - Example: "Feature X requires creating an account. Demo account provided above."
4. **Version Release**:
   - **Manually release this version**: You control release date
   - **Automatically release this version**: Releases immediately after approval
   - **Automatically release this version after approval, no earlier than**: Schedule release
5. **Click "Save"**
6. **Click "Add for Review"** (if ready)
   - Or: Click "Submit for Review" if all sections complete
7. **Confirm submission**

### 6.6 Monitor Review Status

**Review Timeline**: Typically 24-48 hours (can be longer during holidays)

**Status Updates**:
1. **Waiting for Review**: In queue
2. **In Review**: Reviewer is testing your app
3. **Pending Developer Release**: Approved! Waiting for your release action
4. **Ready for Sale**: Live on App Store
5. **Rejected**: See rejection reason, fix, and resubmit

**Check Status**:
- App Store Connect → My Apps → [Your App]
- You'll receive email updates
- Enable push notifications in App Store Connect app (iOS)

**If Rejected**:
1. Read rejection reason carefully
2. Check Resolution Center in App Store Connect for details
3. Fix the issue (code change or clarification)
4. Respond in Resolution Center (if just clarification needed)
5. Or: Upload new build and resubmit

---

## 7. Common Rejection Reasons & Solutions

### 7.1 Guideline 2.1: App Completeness

**Rejection**: "Your app crashed on launch or during use."
**Solution**:
- Test thoroughly on real devices
- Fix crashes found in crash reports
- Ensure all features work
- Provide demo account if login required

**Rejection**: "Your app appears to be a test or demo version."
**Solution**:
- Remove placeholder content
- Remove "Test" from app name
- Ensure all features are complete

### 7.2 Guideline 2.3: Accurate Metadata

**Rejection**: "Screenshots don't match the app."
**Solution**:
- Use actual app screenshots
- Remove marketing fluff if exaggerated
- Ensure screenshots show current version

**Rejection**: "App icon doesn't meet requirements."
**Solution**:
- Use PNG without transparency
- Don't add rounded corners (iOS does automatically)
- Ensure 1024x1024 size

### 7.3 Guideline 4.3: Spam

**Rejection**: "Your app is too similar to other apps."
**Solution**:
- Highlight unique features in description
- Explain differentiation in Resolution Center
- Provide compelling reason for approval

### 7.4 Guideline 5.1.1: Privacy

**Rejection**: "Privacy manifest missing or incomplete."
**Solution**:
- Add PrivacyInfo.xcprivacy to project
- Declare all data collection
- Declare all Required Reason APIs

**Rejection**: "Privacy policy not accessible."
**Solution**:
- Ensure privacy URL loads correctly
- Don't use Google Drive links (must be public web page)
- Ensure policy covers all data collection

### 7.5 Guideline 5.1.2: Data Use and Sharing

**Rejection**: "App privacy details don't match actual data collection."
**Solution**:
- Review all analytics SDKs (are they tracking?)
- Update App Privacy details in App Store Connect
- Remove any unnecessary data collection

---

## 8. Post-Approval Actions

### 8.1 Release Day Checklist

**Approved! Now what?**

**Option 1: Manual Release**
- Review one more time (download from App Store Connect)
- Test production version (it's the official build)
- Choose date and time
- Click "Release this version"

**Option 2: Automatic Release**
- If you selected "Automatically release", it goes live within hours
- Monitor App Store to confirm it's live

**Verify Live**:
1. Search App Store for your app name
2. Confirm listing is correct (screenshots, description)
3. Download app on device
4. Test basic functionality

**Announce Launch**:
- [ ] Social media (Twitter, LinkedIn, Facebook)
- [ ] Email list (if you have one)
- [ ] Product Hunt (submit on launch day)
- [ ] Reddit (relevant subreddits, follow rules)
- [ ] Blog post on your website
- [ ] Press release (if applicable)

### 8.2 Post-Launch Monitoring (First Week)

**Daily Checks**:

**Crash Reports** (Xcode Organizer → Crashes):
- Crash-free rate target: > 99.5%
- Top crashes by volume → Fix in update
- Unsymbolicated crashes → Upload dSYM files

**App Store Reviews**:
- Rating target: > 4.5 stars
- Read all reviews (positive and negative)
- Respond to negative reviews professionally
  - Thank user
  - Apologize for issue
  - Explain fix or ask for details
  - Provide support email
- Respond within 24-48 hours

**Analytics** (App Store Connect → Analytics):
- Impressions: How many people saw your listing
- Product Page Views: How many visited your page
- Downloads: Total downloads
- Conversion Rate: Page views → downloads (target: > 30%)

**Sales and Trends**:
- Daily downloads
- Geographic breakdown
- Device types (iPhone vs iPad)
- iOS version distribution

**User Feedback**:
- Support emails
- In-app feedback (if implemented)
- Social media mentions
- Reddit discussions

**Technical Metrics**:
- Crash reports (Xcode Organizer)
- Performance metrics (if using analytics SDK)
- API error rates (backend monitoring)
- Server costs (if applicable)

### 8.3 Responding to Reviews

**Positive Reviews** (4-5 stars):
```
Thank you [Name]! We're thrilled you're enjoying [App Name]. If you have any suggestions, feel free to reach out at support@...
```

**Constructive Negative Reviews** (2-3 stars):
```
Thanks for the feedback, [Name]. We're sorry about [issue mentioned]. This has been fixed in the latest update. Please update the app and let us know if you're still experiencing issues. Contact us at support@... if you need help!
```

**Harsh Negative Reviews** (1 star, vague):
```
We're sorry you had a bad experience. Could you email us at support@... with more details? We'd love to make this right and improve the app for you.
```

**Bug Reports in Reviews**:
```
Thank you for reporting this, [Name]! We've identified the issue and will fix it in the next update. We've also emailed you directly. Sorry for the inconvenience!
```

---

## 9. CI/CD Automation (Optional but Recommended)

### 9.1 Fastlane Setup

**Install Fastlane**:
```bash
# Using Homebrew (Mac)
brew install fastlane

# Or using RubyGems
sudo gem install fastlane
```

**Initialize Fastlane**:
```bash
cd /path/to/your/project
fastlane init
```

**Follow prompts**:
1. What would you like to use fastlane for?
   → 2. Automate beta distribution to TestFlight
2. Select your Apple ID
3. Select app
4. Fastlane creates `fastlane/` directory with Fastfile

### 9.2 Fastfile Configuration

**Edit `fastlane/Fastfile`**:

```ruby
# Fastfile

default_platform(:ios)

platform :ios do
  # Variables
  xcodeproj = "[AppName].xcodeproj"
  scheme = "[AppName]"
  bundle_id = "com.yourcompany.appname"

  # Before all lanes
  before_all do
    # Ensure git status is clean
    ensure_git_status_clean
  end

  # Lane: Run tests
  desc "Run all tests"
  lane :test do
    run_tests(
      scheme: scheme,
      devices: ["iPhone 15 Pro"]
    )
  end

  # Lane: Build app
  desc "Build the app"
  lane :build do
    gym(
      scheme: scheme,
      export_method: "app-store",
      output_directory: "./build"
    )
  end

  # Lane: Upload to TestFlight
  desc "Upload to TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(xcodeproj: xcodeproj)

    # Build
    gym(
      scheme: scheme,
      export_method: "app-store"
    )

    # Upload
    pilot(
      skip_waiting_for_build_processing: false,
      distribute_external: true,  # Share with external testers
      changelog: "Bug fixes and improvements"
    )
  end

  # Lane: Release to App Store
  desc "Upload to App Store and submit for review"
  lane :release do
    # Ensure main branch
    ensure_git_branch(branch: "main")

    # Run tests
    test

    # Increment version
    version = prompt(text: "Enter version number (e.g., 1.0.0): ")
    increment_version_number(version_number: version)

    # Increment build
    increment_build_number(xcodeproj: xcodeproj)

    # Build
    gym(
      scheme: scheme,
      export_method: "app-store"
    )

    # Upload to App Store Connect
    deliver(
      submit_for_review: true,
      automatic_release: false,
      force: true,  # Skip HTML preview
      metadata_path: "./fastlane/metadata",
      screenshots_path: "./fastlane/screenshots"
    )

    # Tag release
    add_git_tag(tag: "v#{version}")
    push_git_tags

    # Commit version bump
    commit_version_bump(
      message: "Version bump to #{version}",
      xcodeproj: xcodeproj
    )
    push_to_git_remote
  end

  # Error handling
  error do |lane, exception|
    notification(
      subtitle: "Failed to #{lane}",
      message: exception.message
    )
  end
end
```

### 9.3 Fastlane Metadata

**Setup metadata for automatic upload**:

```bash
fastlane deliver init
```

This creates `fastlane/metadata/` with folders for each locale:
```
fastlane/
└── metadata/
    └── en-US/
        ├── description.txt          # App description
        ├── keywords.txt             # Keywords
        ├── marketing_url.txt        # Marketing URL
        ├── name.txt                 # App name
        ├── privacy_url.txt          # Privacy URL
        ├── release_notes.txt        # What's New
        ├── subtitle.txt             # Subtitle
        └── support_url.txt          # Support URL
```

**Copy content from ASO optimization** into these files.

**Screenshots**:
- Place in `fastlane/screenshots/en-US/`
- Name: `1_iphone65_1.png`, `1_iphone65_2.png`, etc.

### 9.4 GitHub Actions Integration

**Create `.github/workflows/release.yml`**:

```yaml
name: Release to App Store

on:
  push:
    tags:
      - 'v*'  # Trigger on version tags (v1.0.0)

jobs:
  release:
    runs-on: macos-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'

      - name: Install Fastlane
        run: gem install fastlane

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.0'

      - name: Import Code Signing Certificates
        uses: apple-actions/import-codesign-certs@v1
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}

      - name: Download Provisioning Profiles
        env:
          FASTLANE_USER: ${{ secrets.FASTLANE_USER }}
          FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
        run: |
          fastlane match appstore --readonly

      - name: Build and Upload to App Store
        env:
          FASTLANE_USER: ${{ secrets.FASTLANE_USER }}
          FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
          FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD: ${{ secrets.APP_SPECIFIC_PASSWORD }}
        run: |
          fastlane release

      - name: Notify on success
        if: success()
        run: echo "Successfully released to App Store!"

      - name: Notify on failure
        if: failure()
        run: echo "Release failed!"
```

**Setup Secrets in GitHub**:
1. Go to repository → Settings → Secrets → Actions
2. Add:
   - `FASTLANE_USER`: Your Apple ID
   - `FASTLANE_PASSWORD`: Apple ID password
   - `APP_SPECIFIC_PASSWORD`: App-specific password (generate at appleid.apple.com)
   - `CERTIFICATES_P12`: Base64-encoded .p12 certificate
   - `CERTIFICATES_PASSWORD`: Password for .p12

---

## 10. Post-Launch Update Strategy

### 10.1 Version 1.0.1 (Bug Fix Update)

**Timeline**: 1-2 weeks after launch
**Goal**: Fix critical bugs discovered post-launch

**Process**:
1. Collect crash reports and bug reports
2. Prioritize P0/P1 bugs
3. Fix bugs
4. Test thoroughly
5. Increment version to 1.0.1
6. Update "What's New":
   ```
   Bug Fixes & Improvements

   • Fixed crash when [specific scenario]
   • Improved [performance/stability]
   • Minor UI adjustments

   Thanks for your feedback! Keep it coming at support@...
   ```
7. Submit for review
8. Release immediately after approval

**Do NOT**:
- Add new features (save for 1.1.0)
- Make major UI changes
- Change app name or icon

### 10.2 Version 1.1.0 (Feature Update)

**Timeline**: 4-6 weeks after launch
**Goal**: Add first deferred feature from PRD

**Process**:
1. Review PRD "Deferred Features" list
2. Select highest-priority feature
3. Implement feature
4. Test thoroughly (unit + UI + manual)
5. Increment version to 1.1.0
6. Update "What's New":
   ```
   New Feature: [Feature Name]

   [Description of feature and benefit]

   Also in this update:
   • [Improvement 1]
   • [Bug fix]
   • [Performance improvement]

   Love the app? Rate us ⭐⭐⭐⭐⭐
   ```
7. Update screenshots if feature is significant
8. Submit for review

### 10.3 Version 2.0.0 (Major Update)

**Timeline**: 6-12 months after launch
**Goal**: Major redesign or new features

**Considerations**:
- Breaking changes acceptable
- Major UI overhaul
- New positioning or target audience
- Requires new screenshots
- Consider announcing in advance (social media, email)

---

## 11. Marketing & Launch Strategy

### 11.1 Pre-Launch (Week -2 to -1)

**Build Anticipation**:
- [ ] Create landing page on your website
- [ ] Start social media accounts (Twitter, Instagram)
- [ ] Create teaser posts ("Coming soon...")
- [ ] Reach out to beta testers
- [ ] Reach out to bloggers/reviewers (provide TestFlight link)
- [ ] Prepare Product Hunt submission (draft)
- [ ] Prepare press kit (logo, screenshots, description)

**Assets Needed**:
- App icon in various sizes
- Hero image (for website/social media)
- Demo video or GIF
- Elevator pitch (one sentence)
- Full description
- Features list
- Screenshots

### 11.2 Launch Day

**Morning of Launch**:
- [ ] Verify app is live on App Store (search by name)
- [ ] Test download link
- [ ] Prepare launch post (blog, social media)
- [ ] Schedule tweets/posts

**Launch Announcement**:
```
🎉 [App Name] is now live on the App Store!

[One-sentence value proposition]

[Key feature 1]
[Key feature 2]
[Key feature 3]

Download: [App Store link]
[Screenshot or demo GIF]

#iOS #ProductivityApp #AppLaunch
```

**Post On**:
- [ ] Twitter
- [ ] LinkedIn
- [ ] Facebook
- [ ] Product Hunt (submit between 12:01 AM - 10 AM PST for best visibility)
- [ ] Reddit (r/apple, r/iphone, r/sideproject, relevant niche subreddits)
  - **Note**: Follow subreddit rules, don't spam, provide value
- [ ] Hacker News (Show HN: [App Name])
- [ ] IndieHackers
- [ ] Your blog/website

**Email List** (if you have one):
```
Subject: [App Name] is Finally Here! 🎉

Hi [Name],

After [X] months of development, I'm thrilled to announce that [App Name] is now live on the App Store!

[Brief description of what it does and why you built it]

Key Features:
• [Feature 1]
• [Feature 2]
• [Feature 3]

[Personal story or unique value proposition]

Download it here: [App Store link]

I'd love to hear your feedback! Reply to this email or leave a review on the App Store.

Thank you for your support!

Best,
[Your name]

P.S. [CTA - share with friends, rate the app, etc.]
```

### 11.3 Post-Launch (Week 1-4)

**Engagement**:
- [ ] Respond to all App Store reviews (within 24-48 hours)
- [ ] Answer support emails promptly
- [ ] Engage with social media mentions
- [ ] Thank users who share/recommend your app
- [ ] Share user testimonials (with permission)
- [ ] Post updates on development progress

**Content Marketing**:
- [ ] Write blog post about launch experience
- [ ] Create tutorial videos (how to use key features)
- [ ] Write about problem you're solving
- [ ] Share behind-the-scenes development stories
- [ ] Guest post on relevant blogs

**Reach Out**:
- [ ] Tech bloggers (send personalized emails)
- [ ] YouTube reviewers (provide promo code + press kit)
- [ ] Podcast hosts (offer to be interviewed)
- [ ] Industry influencers (share the app)

---

## 12. Metrics & Success Criteria

### 12.1 Launch Success Metrics (First 30 Days)

**Downloads**:
- Target: [From PRD success criteria]
- Measurement: App Store Connect → Analytics → Metrics

**Rating**:
- Target: > 4.5 stars
- Measurement: App Store reviews

**Crash-Free Rate**:
- Target: > 99.5%
- Measurement: Xcode Organizer → Crashes

**Retention**:
- Day 1 Retention: Target > 40%
- Day 7 Retention: Target > 20%
- Day 30 Retention: Target > 10%
- Measurement: Analytics SDK (if implemented)

**User Engagement**:
- Average Session Duration: Target > 3 minutes
- Sessions per User: Target > 5 per week
- Feature Usage: % of users using key features
- Measurement: Analytics SDK

**Revenue** (if paid/IAP):
- Revenue: Target from PRD
- Conversion Rate: % of users who purchase
- Measurement: App Store Connect → Sales and Trends

### 12.2 Long-Term Metrics (3-12 Months)

**Growth**:
- Monthly downloads trend
- Organic vs paid downloads
- User base size (cumulative downloads)

**Quality**:
- App Store rating over time
- Reviews per month
- Crash-free rate trend

**Engagement**:
- DAU/MAU ratio (Daily Active Users / Monthly Active Users)
- Feature adoption rate
- Power users (highly engaged users)

**Business**:
- Revenue (if applicable)
- LTV (Lifetime Value) per user
- CAC (Customer Acquisition Cost)
- Churn rate

---

## 13. Support Infrastructure

### 13.1 Support Email

Setup: support@yourdomain.com (or use yourname+appname@gmail.com)

**Auto-Response**:
```
Thank you for contacting [App Name] support!

We've received your message and will respond within 24-48 hours.

In the meantime, check out our FAQ: [link]

Common issues:
• [Issue 1]: [Quick fix]
• [Issue 2]: [Quick fix]

Best,
[App Name] Team
```

### 13.2 FAQ Page

**Create on your website**: yourdomain.com/support

**Common Questions**:
1. How do I [common task]?
2. Is my data secure?
3. How do I delete my account?
4. How do I export my data?
5. Is there an Android version? (If no, explain roadmap)
6. How much does it cost? (If free, explain monetization)
7. How do I report a bug?
8. How do I request a feature?

### 13.3 In-App Help

**Settings → Help & Support**:
- FAQ link
- Contact support (opens email)
- Rate the app (deep link to App Store review)
- Share feedback (in-app form or email)
- Privacy Policy link
- Terms of Service link

---

## 14. Appendix: Resources

### 14.1 Official Apple Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Marketing Guidelines](https://developer.apple.com/app-store/marketing/guidelines/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)

### 14.2 Tools

**App Store Optimization**:
- [App Annie](https://www.appannie.com) - Market intelligence
- [Sensor Tower](https://sensortower.com) - ASO and analytics
- [TheTool](https://thetool.io) - Keyword research

**Screenshot & Asset Creation**:
- [Screenshot](https://screenshot.app) - Mac app
- [DaVinci Apps](https://www.davinciapps.com) - Web-based
- [Figma](https://figma.com) - Design tool

**CI/CD**:
- [Fastlane](https://fastlane.tools) - Automation
- [Bitrise](https://bitrise.io) - Mobile CI/CD
- [CircleCI](https://circleci.com) - CI/CD platform

**Analytics**:
- [Firebase Analytics](https://firebase.google.com/products/analytics) - Free
- [Mixpanel](https://mixpanel.com) - Product analytics
- [Amplitude](https://amplitude.com) - Product analytics

**Crash Reporting**:
- Xcode Organizer (built-in)
- [Firebase Crashlytics](https://firebase.google.com/products/crashlytics) - Free
- [Sentry](https://sentry.io) - Error monitoring

### 14.3 Communities

- [r/iOSProgramming](https://reddit.com/r/iOSProgramming)
- [r/AppStore](https://reddit.com/r/AppStore)
- [Indie Hackers](https://indiehackers.com)
- [Product Hunt](https://producthunt.com)
- [Twitter #IndieDevHour](https://twitter.com/search?q=%23IndieDevHour)

---

## 15. Release Timeline Template

**Week -8 to -6: Development**
- [ ] All features implemented
- [ ] All tests passing
- [ ] Code complete

**Week -5 to -4: Testing & Polish**
- [ ] Manual testing complete
- [ ] Bug fixes
- [ ] Performance optimization
- [ ] UI polish

**Week -3: Pre-Submission Prep**
- [ ] App Store assets created (screenshots, app preview)
- [ ] Metadata written (description, keywords)
- [ ] Privacy manifest added
- [ ] Archive and validate in Xcode

**Week -2: TestFlight Beta**
- [ ] Upload to TestFlight
- [ ] Invite 20-50 beta testers
- [ ] Collect feedback
- [ ] Fix critical issues

**Week -1: Final Prep**
- [ ] All beta feedback addressed
- [ ] Final build uploaded
- [ ] App Store Connect metadata filled
- [ ] Marketing materials prepared
- [ ] Support infrastructure ready

**Day 0: Submission**
- [ ] Submit for review in App Store Connect
- [ ] Wait 24-48 hours for review
- [ ] Fix any issues if rejected

**Day 1-2: Approval & Launch**
- [ ] App approved
- [ ] Release app (manual or automatic)
- [ ] Launch announcements (social media, email, Product Hunt)
- [ ] Monitor crash reports and reviews

**Week 1-4: Post-Launch**
- [ ] Respond to all reviews
- [ ] Fix critical bugs (v1.0.1 if needed)
- [ ] Engage with users
- [ ] Plan next features (v1.1.0)

---

**Document History**:
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | [Date] | Release Manager AI | Initial release specification created |
```

---

## Execution Instructions

When activated, follow these steps:

1. **Read All Specification Documents**
   ```
   - Read product-plan-*.md (ASO optimization section)
   - Read docs/ARCHITECTURE.md (tech stack, privacy)
   - Read docs/IMPLEMENTATION_GUIDE.md (dependencies, config)
   - Read docs/TEST_SPEC.md (quality checklist, beta plan)
   ```

2. **Extract Release Information**
   - App Store metadata (from ASO optimization)
   - App name, subtitle, keywords, description
   - Screenshot strategy
   - Privacy requirements (from ARCHITECTURE)
   - Technical details (dependencies, capabilities)
   - Quality criteria (from TEST_SPEC)

3. **Generate App Store Metadata Section**
   - Copy all ASO-optimized content
   - Format for App Store Connect
   - Include character counts
   - Provide "What's New" for v1.0.0

4. **Generate Assets Section**
   - App icon requirements and design notes
   - Screenshot requirements and strategy (from ASO)
   - App preview video storyboard (from ASO)
   - Provide creation tips and tools

5. **Generate Privacy & Compliance Section**
   - Privacy manifest template (based on ARCHITECTURE data collection)
   - App Privacy details questionnaire
   - Age rating guidance

6. **Generate Build Configuration Section**
   - Version numbering strategy
   - Debug vs Release configurations
   - Code signing options
   - Capabilities needed (from ARCHITECTURE)

7. **Generate Pre-Submission Checklist**
   - Development complete checklist
   - Testing complete (from TEST_SPEC)
   - Assets prepared
   - Metadata ready
   - Privacy compliance

8. **Generate Submission Process Section**
   - Step-by-step App Store Connect setup
   - How to archive and upload
   - How to submit for review
   - How to monitor review status

9. **Generate Post-Launch Section**
   - Release day checklist
   - Monitoring guide (crashes, reviews, analytics)
   - Review response templates
   - Update strategy (v1.0.1, v1.1.0, v2.0.0)

10. **Generate Optional CI/CD Section**
    - Fastlane setup and configuration
    - GitHub Actions workflow
    - Metadata and screenshot automation

11. **Generate Marketing Section**
    - Pre-launch, launch day, post-launch activities
    - Announcement templates
    - Content marketing ideas
    - Success metrics

12. **Write Complete Release Spec**
    ```
    Write to: docs/RELEASE_SPEC.md
    Target length: 2000-3000 lines
    Format: Markdown with code examples and checklists
    ```

13. **Present Summary**
    ```
    ✅ Release Specification generated!

    🚀 **Release Spec Summary**:
    - App Store metadata: Pre-filled from ASO optimization
    - Asset requirements: App icon, screenshots (5 per size), optional video
    - Privacy compliance: Privacy manifest template, App Privacy guide
    - Submission process: Complete step-by-step guide
    - Post-launch monitoring: Crash reports, reviews, analytics
    - Marketing strategy: Pre-launch, launch day, post-launch
    - CI/CD automation: Fastlane and GitHub Actions setup (optional)
    - Update strategy: Bug fixes (1.0.1), features (1.1.0), major (2.0.0)

    **What's Included**:
    ✅ Complete App Store Connect setup guide
    ✅ Privacy manifest and compliance checklist
    ✅ Pre-submission checklist (50+ items)
    ✅ Step-by-step submission process
    ✅ Common rejection reasons and solutions
    ✅ Post-approval actions and monitoring
    ✅ Marketing and launch strategy
    ✅ Support infrastructure setup
    ✅ Release timeline template

    **Next Steps**:
    1. Review the release spec in docs/RELEASE_SPEC.md
    2. Prepare App Store assets (icon, screenshots)
    3. Complete pre-submission checklist
    4. Run TestFlight beta (2 weeks)
    5. Submit to App Store when ready
    6. Launch and monitor!

    **Developer can now**:
    - Follow step-by-step to submit to App Store
    - Avoid common rejection reasons
    - Launch with confidence
    - Monitor and iterate post-launch

    Ready to launch your app? 🚀
    ```

14. **Iterate Based on Feedback**
    If user requests changes:
    - Update specific sections
    - Add missing steps
    - Clarify submission process
    - Expand marketing strategy

---

## Quality Guidelines

1. **Be Complete**: Cover every step from build to launch
   - Don't assume knowledge
   - Provide exact steps (click this, type that)
   - Include screenshots or descriptions of what to expect

2. **Use ASO Content**: Pre-fill all metadata
   - Don't make user re-write description
   - Copy from ASO optimization exactly
   - Verify character counts

3. **Provide Checklists**: Make it actionable
   - Pre-submission checklist
   - Release day checklist
   - Post-launch monitoring checklist

4. **Include Troubleshooting**: Common rejection reasons
   - Guideline violations
   - Privacy issues
   - Metadata problems
   - Solutions for each

5. **Be Encouraging**: Launching is exciting but stressful
   - Acknowledge the achievement
   - Provide support resources
   - Build confidence

6. **Think Post-Launch**: Don't stop at submission
   - Monitoring strategy
   - Review response templates
   - Update strategy
   - Marketing and growth

---

## Integration with Workflow

This skill is typically:
- **Sixth step** in specification generation
- Activated after PRD, Architecture, UX, Implementation, and Testing specs are complete
- Final specification before implementation begins
- Critical for successful App Store launch

The release specification ensures the app reaches users and succeeds in the market.

---

## Notes

- App Store review can be unpredictable - plan for rejections
- TestFlight beta testing is crucial - don't skip it
- Privacy compliance is non-negotiable - get it right
- First impressions matter - polish screenshots and description
- Post-launch monitoring is as important as pre-launch prep
- Respond to reviews - it shows you care
- Plan for updates - v1.0 is just the beginning
- Marketing is not optional - no one will find your app without it
