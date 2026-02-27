---
name: privacy-policy
description: Generate privacy policies, terms of service, and EULAs for Apple platform apps. Detects data collection patterns, third-party SDKs, and generates region-specific legal documents with Apple Privacy Nutrition Label mapping. Use when user needs legal documents or data collection disclosure for App Store submission.
allowed-tools: [Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# Privacy Policy & Legal Document Generator

Generate ready-to-use privacy policies, terms of service, and EULAs tailored to your app's data practices, third-party services, and target markets.

> **Disclaimer:** This skill generates template legal documents based on common indie app scenarios. Consult a qualified lawyer for apps handling sensitive data (health, financial, children's data), apps with complex data sharing arrangements, or apps operating in highly regulated industries. These templates are a strong starting point -- not a substitute for legal counsel.

## When This Skill Activates

Use this skill when the user:
- Needs a privacy policy for their app
- Needs terms of service or EULA
- Apple requires a privacy policy for App Store submission
- Is adding analytics, ads, or crash reporting and needs to update their privacy policy
- Asks about data collection disclosure or privacy compliance
- Mentions GDPR, CCPA, DPDP, or COPPA requirements for their app
- Wants to know what to declare in Apple's Privacy Nutrition Labels

## Pre-Generation Checks

Before generating documents, gather context from the project.

### 1. Look for Existing Legal Documents

```
Glob: **/privacy*.md, **/privacy*.html, **/privacy*.txt
Glob: **/terms*.md, **/terms*.html, **/terms*.txt
Glob: **/eula*.md, **/eula*.html, **/eula*.txt
Glob: **/legal/**
```

If existing documents found, ask user whether to replace or update them.

### 2. Check for Third-Party SDK Usage

```
Grep: "Firebase" or "GoogleAnalytics" or "Crashlytics"
Grep: "Mixpanel" or "Amplitude" or "PostHog"
Grep: "AdMob" or "AppLovin" or "UnityAds"
Grep: "FacebookSDK" or "GoogleSignIn" or "SignInWithApple"
Grep: "Sentry" or "Bugsnag" or "DataDog"
Grep: "RevenueCat" or "Adapty" or "Qonversion"
Grep: "TelemetryDeck" or "Plausible" or "CountlySDK"
```

Note detected SDKs to auto-populate data collection sections.

### 3. Detect Data Collection Patterns in Code

```
Grep: "UserDefaults" -- Local preferences storage
Grep: "CoreData" or "SwiftData" or "NSPersistentContainer" -- Local database
Grep: "CloudKit" or "CKContainer" -- Cloud sync
Grep: "URLSession" or "Alamofire" -- Network calls
Grep: "HealthKit" or "HKHealthStore" -- Health data
Grep: "CLLocationManager" or "CoreLocation" -- Location data
Grep: "AVCaptureSession" or "PHPhotoLibrary" -- Camera/photos
Grep: "Contacts" or "CNContactStore" -- Contacts access
Grep: "ATTrackingManager" -- App Tracking Transparency
Grep: "ASAuthorizationAppleIDProvider" -- Sign in with Apple
```

### 4. Check Info.plist for Permission Usage Descriptions

```
Grep: "NSCameraUsageDescription" or "NSPhotoLibraryUsageDescription"
Grep: "NSLocationWhenInUseUsageDescription" or "NSLocationAlwaysUsageDescription"
Grep: "NSHealthShareUsageDescription" or "NSHealthUpdateUsageDescription"
Grep: "NSContactsUsageDescription" or "NSMicrophoneUsageDescription"
Grep: "NSUserTrackingUsageDescription"
```

## Configuration Questions

Ask the user via AskUserQuestion:

### 1. What documents do you need?

- Privacy Policy only
- Terms of Service only
- EULA only
- All three (recommended for App Store apps)

### 2. What data does your app collect?

- No user data (fully offline, no accounts)
- Anonymous analytics only (usage events, crash data)
- Account with email (sign-in required)
- Account with personal info (name, email, profile, preferences)
- Health or financial data (triggers additional compliance sections)

### 3. What third-party services does your app use?

- None
- Analytics only (e.g., TelemetryDeck, Firebase Analytics)
- Analytics + crash reporting (e.g., Sentry, Crashlytics)
- Advertising (e.g., AdMob, AppLovin)
- Social login (e.g., Sign in with Apple, Google Sign-In)
- Multiple of the above (list them)

### 4. Does your app target or allow children under 13?

- No
- Yes (triggers COPPA section and stricter data practices)

### 5. Where will you host these documents?

- GitHub Pages (free, Markdown to HTML)
- In-app (Settings screen with WKWebView or Text view)
- Personal/company website
- All of the above (recommended -- Apple requires a publicly accessible URL)

## Generation Process

### Step 1: Select Template Sections

Read `templates.md` for the document templates.

Based on configuration answers, include or exclude sections:

| Answer | Sections Added |
|--------|---------------|
| No user data | Minimal privacy policy (no collection, no sharing) |
| Anonymous analytics | Analytics disclosure, third-party services list |
| Account with email | Account data, authentication, data retention |
| Personal info | Full data collection, user rights, data portability |
| Health/financial | Sensitive data handling, enhanced security, additional consent |
| Children under 13 | COPPA section, parental consent, limited data collection |

### Step 2: Fill in App-Specific Details

Replace template placeholders with detected or user-provided values:
- `[APP_NAME]` -- App display name
- `[DEVELOPER_NAME]` -- Developer or company name
- `[CONTACT_EMAIL]` -- Privacy contact email
- `[EFFECTIVE_DATE]` -- Document effective date
- `[WEBSITE_URL]` -- Developer website or privacy page URL

### Step 3: Add Region-Specific Sections

Include sections based on target markets:

**GDPR (European Union users):**
- Data controller identification
- Lawful basis for processing (consent, legitimate interest, contract)
- Data subject rights (access, rectification, erasure, portability, objection)
- Data Protection Officer contact (if applicable)
- Data retention periods
- Right to lodge complaint with supervisory authority

**CCPA (California users):**
- Categories of personal information collected
- Business purposes for collection
- "Do Not Sell or Share My Personal Information" notice
- Right to know, delete, and opt-out
- Non-discrimination for exercising rights
- Financial incentive disclosure (if applicable)

**DPDP (India users):**
- Data fiduciary identification
- Purpose of data processing
- Consent mechanism
- Data principal rights (access, correction, erasure, grievance redressal)
- Data retention limitations
- Processing of children's data (under 18)

**COPPA (children under 13):**
- Parental consent requirement
- Limited data collection (only what is strictly necessary)
- No behavioral advertising to children
- Parental rights (review, delete, refuse further collection)
- Safe harbor program compliance (if applicable)

### Step 4: Generate Apple Privacy Nutrition Label Mapping

Based on detected data practices, generate a mapping for App Store Connect:

```
Apple Privacy Nutrition Label Mapping
=====================================

Data Types to Declare:
- [ ] Contact Info: Email Address -- Used for: App Functionality, Account
- [ ] Identifiers: User ID -- Used for: App Functionality
- [ ] Usage Data: Product Interaction -- Used for: Analytics
- [ ] Diagnostics: Crash Data -- Used for: App Functionality
- [ ] Diagnostics: Performance Data -- Used for: Analytics

Data Linked to User: [List items linked to user identity]
Data Used to Track: [List items used for cross-app tracking, if any]

Tracking: [Yes/No -- triggers ATT requirement if Yes]
```

### Step 5: Output Documents

Generate documents in Markdown format. Place files based on user's hosting preference:

- **GitHub Pages**: `docs/privacy-policy.md`, `docs/terms-of-service.md`, `docs/eula.md`
- **In-app**: `Resources/Legal/privacy-policy.md`, etc.
- **Website**: Output to clipboard/file for manual upload
- **All**: Generate in `docs/` with guidance for in-app integration

## Apple-Required Privacy Disclosures

### App Store Connect Privacy Questions

When submitting to the App Store, Apple asks about data practices. Map generated privacy policy to these questions:

| Apple Question | Where to Find Answer |
|---------------|---------------------|
| Do you or your third-party partners collect data? | "Information We Collect" section |
| Data types collected | Privacy Nutrition Label mapping (Step 4) |
| Is data linked to user identity? | "How We Use Information" section |
| Is data used for tracking? | "Third-Party Services" section |

### Privacy Nutrition Labels

Declare these data types based on your app's practices:

| If Your App... | Declare These Types |
|----------------|-------------------|
| Has user accounts | Contact Info, Identifiers |
| Uses analytics | Usage Data (Product Interaction) |
| Has crash reporting | Diagnostics (Crash Data, Performance Data) |
| Shows ads | Identifiers (Device ID), Usage Data |
| Uses location | Location (Precise or Coarse) |
| Accesses photos | Photos or Videos |
| Accesses health data | Health & Fitness |
| Uses Sign in with Apple | Contact Info (Email), Identifiers (User ID) |

### When ATT (App Tracking Transparency) Is Required

ATT is required when your app:
- Accesses the IDFA (Identifier for Advertisers)
- Links user data with third-party data for advertising
- Shares user data with data brokers

ATT is NOT required for:
- First-party analytics that stays on your server
- Crash reporting
- Fraud detection
- Attribution that does not use IDFA (e.g., SKAdNetwork)

## Hosting Guidance

### GitHub Pages (Free, Recommended for Indie Devs)

1. Create `docs/` folder in your repo
2. Add privacy-policy.md, terms-of-service.md, eula.md
3. Enable GitHub Pages in repo Settings > Pages > Source: `/docs`
4. Your URL: `https://yourusername.github.io/yourapp/privacy-policy`

### In-App Display

```swift
// Option 1: WKWebView for hosted HTML
import WebKit

struct LegalDocumentView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView { WKWebView() }
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}

// Option 2: Bundled Markdown rendered as Text
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text(LocalizedStringKey(privacyPolicyMarkdown))
                .padding()
                .textSelection(.enabled)
        }
        .navigationTitle("Privacy Policy")
    }
}
```

### Apple Requirements for Privacy Policy URL

- Must be publicly accessible (not behind login or in-app only)
- Must be a working URL at all times (Apple checks during review)
- Required in App Store Connect under "App Privacy"
- Must also be accessible from within the app (Settings or About screen)

## Output Format

After generation, provide:

### Files Created

```
docs/
 ├── privacy-policy.md     # Privacy policy with region-specific sections
 ├── terms-of-service.md   # Terms of service (if requested)
 └── eula.md               # End-user license agreement (if requested)
```

### Apple Privacy Nutrition Label Checklist

Provide a checklist the user can follow in App Store Connect.

### Integration Checklist

- [ ] Host documents at a publicly accessible URL
- [ ] Add privacy policy URL to App Store Connect
- [ ] Add legal links to app Settings or About screen
- [ ] Complete Privacy Nutrition Labels in App Store Connect
- [ ] If using ATT, add `NSUserTrackingUsageDescription` to Info.plist
- [ ] Test that privacy policy URL loads correctly
- [ ] Set a calendar reminder to review documents annually

## References

- **templates.md** -- Full legal document templates with placeholders
- Related: `generators/consent-flow` -- GDPR/CCPA consent UI generation
- Related: `generators/account-deletion` -- Account deletion flow (App Store requirement)
- Related: `generators/permission-priming` -- Pre-permission UI for ATT
- Related: `monetization/` -- Subscription terms and pricing disclosures
- Apple App Review Guidelines Section 5.1 (Privacy)
- Apple App Store Connect Privacy Details documentation
