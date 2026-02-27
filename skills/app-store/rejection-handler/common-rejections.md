# Common App Store Rejections

The top 20 App Store rejection reasons, organized by guideline. For each: what triggers it, example rejection message, how to fix, and a response template snippet.

## Guideline 2.1: App Completeness

### 2.1 — Crashes

**What triggers it:** App crashes during review, on launch, or during core flows. Apple tests on current-generation devices with the latest OS.

**Example rejection message:**
> We discovered one or more bugs in your app. Specifically, the app crashed when we tapped on the "Export" button on iPhone 15 Pro running iOS 18.2.

**How to fix:**
- Reproduce on the exact device/OS cited (use Xcode Simulator or physical device)
- Check crash logs in App Store Connect → App Analytics → Crashes
- Test all core flows on the latest OS release
- Pay special attention to edge cases: no network, empty data, permissions denied

**Response template:**
```
We've identified and resolved the crash in the export flow.
The issue was caused by [root cause]. Build [X.X (XX)] includes
the fix, verified on iPhone 15 Pro / iOS 18.2.
```

### 2.1 — Broken Links or Placeholder Content

**What triggers it:** Links that 404, screens that say "Coming Soon", lorem ipsum text, test data visible in the UI.

**Example rejection message:**
> Your app includes placeholder content. Specifically, the "Community" tab displays "Coming Soon" text without functional content.

**How to fix:**
- Remove or hide any unfinished features entirely
- Replace placeholder text with real content
- Ensure all URLs (privacy policy, support, terms) resolve to live pages
- Remove any "beta" or "test" labels

**Response template:**
```
We've removed the placeholder content from the Community tab.
This feature has been removed from the current release and will
be included in a future update when fully implemented.
```

### 2.1 — Missing Demo Account

**What triggers it:** App requires login but no test credentials were provided in App Review Notes.

**Example rejection message:**
> We were unable to review your app as it requires a login but no demo account was provided.

**How to fix:**
- Provide a valid demo account in App Store Connect → App Review Information → Notes
- Ensure the demo account has access to all features
- Don't use an account that might be rate-limited or expire
- Format: "Demo account: user@example.com / password123"

**Response template:**
```
We apologize for the oversight. Demo credentials have been added
to the App Review notes: [email] / [password]. This account has
full access to all app features.
```

## Guideline 2.3: Accurate Metadata

### 2.3 — Misleading Description or Screenshots

**What triggers it:** Screenshots don't match the current app UI, description promises features that don't exist, or marketing overstates capabilities.

**Example rejection message:**
> Your app's screenshots do not accurately reflect the app in use. Specifically, screenshot 3 shows a feature that is not present in the current version.

**How to fix:**
- Retake all screenshots from the current build
- Ensure every feature mentioned in the description exists in the app
- Remove any claims that can't be substantiated
- Match What's New text to actual changes in this version

**Response template:**
```
We've updated all screenshots to reflect the current app UI.
Screenshot 3 has been replaced with an accurate representation
of the [feature name] screen as it appears in this build.
```

### 2.3 — Keyword Stuffing or Misleading Keywords

**What triggers it:** Irrelevant keywords in the keyword field, competitor names, category names, or misleading terms.

**Example rejection message:**
> Your app's metadata includes misleading content. Specifically, the keyword field contains competitor app names.

**How to fix:**
- Remove all competitor brand names from keywords
- Remove category names (already indexed automatically)
- Remove irrelevant terms that don't describe your app
- Use only keywords directly relevant to your app's functionality

**Response template:**
```
We've updated the keyword field to remove all third-party brand
names and irrelevant terms. Keywords now accurately reflect our
app's features and functionality.
```

## Guideline 2.5.1: Software Requirements

### 2.5.1 — Private API Usage

**What triggers it:** App calls private Apple frameworks or undocumented APIs. Apple's static analysis detects these automatically.

**Example rejection message:**
> Your app uses non-public API/framework: UIWebDocumentView. This is not permitted on the App Store.

**How to fix:**
- Search your codebase for the cited API name
- Check third-party SDKs and libraries — they often contain private API calls
- Replace with public alternatives
- Update any outdated libraries that may use deprecated private APIs
- Use `nm` or `otool` on your binary to check for private symbols

**Response template:**
```
We've removed the non-public API usage. The reference to
[API name] was in [library name], which has been updated to
version [X.X] that uses only public APIs.
```

## Guideline 3.1.1: In-App Purchase

### 3.1.1 — Digital Goods Not Using IAP

**What triggers it:** App sells digital content, features, or subscriptions through external payment processors (Stripe, PayPal, etc.) instead of Apple's In-App Purchase.

**Example rejection message:**
> Your app offers digital content for purchase but does not use the In-App Purchase API. Specifically, the premium themes are available for purchase via an external payment system.

**How to fix:**
- Implement StoreKit 2 for all digital content purchases
- Remove external payment links/buttons for digital goods
- Physical goods and services CAN use external payment
- Reader apps have specific exemptions (Guideline 3.1.3)

**Response template:**
```
We've migrated all digital content purchases to Apple's In-App
Purchase system. Premium themes are now available as non-consumable
IAPs through StoreKit 2. External payment references have been
removed.
```

### 3.1.1 — Directing Users to External Purchase

**What triggers it:** App includes language, buttons, or links encouraging users to purchase outside the app (even if IAP is also offered).

**Example rejection message:**
> Your app includes a button or link that directs users to an external payment mechanism for items that are required to be purchased through In-App Purchase.

**How to fix:**
- Remove all "buy on our website" buttons or text for digital goods
- Remove pricing pages that link to external checkout
- Don't mention that content is cheaper on your website
- Reader app entitlement allows linking out for account management only

**Response template:**
```
We've removed all references to external purchasing for digital
content. The "Buy on Web" button and associated links have been
removed. All digital purchases now go through IAP exclusively.
```

## Guideline 3.1.2: Subscriptions

### 3.1.2 — Subscription Requirements

**What triggers it:** Subscription doesn't provide ongoing value, unclear pricing terms, no way to manage subscription in-app, or auto-renewal terms not clearly communicated.

**Example rejection message:**
> Your app's subscription does not provide ongoing value to the user. The content available through the subscription is static and does not justify a recurring charge.

**How to fix:**
- Ensure subscription includes regularly updated content or ongoing service
- Add clear subscription terms on the paywall (price, duration, renewal terms)
- Include in-app access to subscription management
- Link to Apple's subscription management page
- Show what users get for their ongoing payment

**Response template:**
```
Our subscription provides ongoing value through [specific
ongoing benefits: weekly content updates, cloud sync, continuous
AI processing, etc.]. We've also added clearer subscription
terms on the purchase screen and a direct link to subscription
management.
```

## Guideline 4.0: Design

### 4.0 — Not Enough Native UI / Web Wrapper

**What triggers it:** App is primarily a web view wrapping an existing website without meaningful native functionality.

**Example rejection message:**
> Your app is primarily a web-based experience and does not provide enough native iOS functionality. We encourage you to consider building a native app that takes advantage of iOS features.

**How to fix (if web-based is intentional):**
- Add meaningful native features: push notifications, widgets, Shortcuts/Siri
- Use native navigation (NavigationStack, TabView) instead of web navigation
- Implement offline functionality
- Add native sharing, haptics, or device-specific features
- If the app truly should be a website, consider not submitting it

**Response template:**
```
While [App Name] does use web views for [specific content],
it provides significant native functionality including:
- Push notifications for [purpose]
- Home screen widget showing [content]
- Offline access to [feature]
- Native [iOS feature] integration

These features require a native app and cannot be delivered
through a website alone.
```

### 4.0 — Poor UI Quality

**What triggers it:** App has obviously unfinished UI, uses no standard iOS patterns, has layout issues, or looks unprofessional.

**Example rejection message:**
> Your app does not comply with the design guidelines for iOS apps. Specifically, the app includes UI elements that are inconsistent with standard iOS design patterns.

**How to fix:**
- Use system components (SwiftUI standard views, UIKit standard controls)
- Follow Human Interface Guidelines for spacing, typography, and color
- Support Dynamic Type for accessibility
- Support Dark Mode
- Ensure layouts work on all supported screen sizes

**Response template:**
```
We've updated the app's design to align with iOS Human Interface
Guidelines. Changes include [specific UI improvements]. The app
now uses standard iOS components for [navigation/buttons/lists]
and supports Dynamic Type and Dark Mode.
```

## Guideline 4.2: Minimum Functionality

### 4.2 — App Is Too Simple

**What triggers it:** App provides functionality that could be achieved with a bookmark, a simple website, or is too basic for the App Store.

**Example rejection message:**
> We found that the usefulness of your app is limited by the minimal amount of content or features it includes. We encourage you to review your app concept and incorporate additional features and content.

**How to fix (if you agree it's too simple):**
- Add 2-3 meaningful features beyond the core function
- Include settings, customization, or personalization
- Add data visualization, history, or insights
- Implement native features: widgets, notifications, Siri Shortcuts
- Consider whether a more comprehensive app would serve users better

**How to push back (if your app is intentionally focused):**
- Explain the design philosophy of focused simplicity
- Reference comparable apps on the App Store
- Highlight native features that justify app vs. website
- Provide user testimonials or usage data if available

**Response template (fixing):**
```
We've added substantial functionality to the app:
- [New feature 1]
- [New feature 2]
- [New feature 3]
Build [X.X (XX)] includes these improvements.
```

**Response template (pushing back):**
```
[App Name] is intentionally designed as a focused [type] tool.
Despite its streamlined interface, it provides meaningful
functionality that requires a native app:
- [Native feature 1: widgets, notifications, etc.]
- [Native feature 2]
- [Unique value proposition]

The app has [X users / X positive reviews / serves a specific
use case] that demonstrates its value to users.
```

## Guideline 4.3: Spam

### 4.3 — Duplicate or Template Apps

**What triggers it:** App is substantially similar to other apps you've submitted, appears to be generated from a template without meaningful customization, or copies another developer's app.

**Example rejection message:**
> Your app duplicates the content and functionality of other apps currently available on the App Store, which is considered spam.

**How to fix:**
- Differentiate your app with unique features, content, or design
- If you have multiple similar apps, consider consolidating into one
- Remove template boilerplate and customize the experience
- Add unique content that distinguishes your app

**Response template:**
```
[App Name] is distinct from [other app] in the following ways:
- [Unique feature or audience 1]
- [Different content or purpose 2]
- [Technical differentiation 3]

These apps serve different user segments: [App 1] targets
[audience A] while [App 2] targets [audience B].
```

## Guideline 5.1.1: Data Collection and Storage

### 5.1.1 — Missing Privacy Policy

**What triggers it:** App collects any user data but doesn't provide a privacy policy URL, or the URL leads to a dead page.

**Example rejection message:**
> Your app collects user data but does not include a privacy policy URL in App Store Connect.

**How to fix:**
- Create a privacy policy covering all data your app collects
- Host it at a stable URL (your website, GitHub Pages, or a service like Termly)
- Add the URL in App Store Connect → App Information → Privacy Policy URL
- Ensure the page loads correctly on mobile

**Response template:**
```
We've added our privacy policy at [URL]. It covers all data
collection, usage, and sharing practices in the app. The URL
has been added to App Store Connect.
```

### 5.1.1 — Excessive Data Collection

**What triggers it:** App collects data that isn't necessary for its core functionality, or collects data without clear user consent.

**Example rejection message:**
> Your app collects user data that is not necessary for the app's core functionality. Specifically, the app requests access to Contacts, which does not appear to be needed.

**How to fix:**
- Remove permissions requests for data you don't strictly need
- Add clear usage descriptions for all permission requests (NSUsageDescription)
- Request permissions in context (when the user triggers the relevant feature)
- Don't request all permissions at launch

**Response template:**
```
We've removed the Contacts permission request as it is not
essential to the app's core functionality. The app now only
requests [remaining permissions] which are required for
[specific features].
```

## Guideline 5.1.2: Data Use and Sharing

### 5.1.2 — App Tracking Transparency

**What triggers it:** App tracks users across apps/websites without presenting the ATT prompt first, or collects IDFA without the ATT framework.

**Example rejection message:**
> Your app uses the AppTrackingTransparency framework but does not present the tracking permission request to the user before collecting data used to track them.

**How to fix:**
- Present ATT prompt before any tracking begins
- Don't track if user denies permission
- Ensure ATT prompt has a clear purpose string (NSUserTrackingUsageDescription)
- Don't incentivize users to allow tracking
- Check that all third-party SDKs (analytics, ad networks) respect ATT status

**Response template:**
```
We've updated the app to present the ATT permission prompt
before any tracking occurs. Third-party SDKs have been
configured to respect the user's tracking preference. No data
is collected for tracking purposes until explicit consent is
granted.
```

### 5.1.2 — Privacy Nutrition Label Mismatch

**What triggers it:** The privacy labels declared in App Store Connect don't match the app's actual data collection practices.

**Example rejection message:**
> Your app's privacy information does not accurately reflect the app's data collection practices. The app collects [data type] which is not declared in the privacy nutrition labels.

**How to fix:**
- Audit all data collection in your app AND third-party SDKs
- Update App Store Connect privacy labels to match actual behavior
- Use Apple's privacy manifest to document API usage (iOS 17+)
- Check SDK documentation for their data collection disclosures

**Response template:**
```
We've updated the privacy nutrition labels in App Store Connect
to accurately reflect all data collection. Specifically, we've
added [data type] under [category]. We've also audited all
third-party SDKs to ensure complete disclosure.
```

## Guideline 5.2.1: Legal Requirements

### 5.2.1 — Local Law Compliance

**What triggers it:** App content or functionality violates laws in specific territories (gambling, health claims, age restrictions, financial regulations).

**Example rejection message:**
> Your app includes [feature] that may not comply with local laws in [territory]. Please ensure your app complies with all applicable laws.

**How to fix:**
- Research laws in all territories where your app is available
- Restrict distribution to compliant territories using App Store Connect
- Add required disclaimers for health, financial, or legal content
- Implement age gates where required
- Consult legal counsel for regulated industries

**Response template:**
```
We've addressed the compliance concern by [specific action:
adding age gate / restricting distribution / adding disclaimer].
The app is now limited to territories where [feature] is
permitted and includes appropriate [disclaimers/restrictions].
```

## Quick Reference: Rejection to Fix Mapping

| Guideline | Common Cause | Typical Fix Time | Difficulty |
|-----------|-------------|-----------------|------------|
| 2.1 Crashes | Untested edge case | 1-3 days | Low-Medium |
| 2.1 Placeholder | Incomplete feature | 1-2 days | Low |
| 2.1 Demo account | Missing review notes | 10 minutes | Low |
| 2.3 Screenshots | Outdated assets | 1-2 hours | Low |
| 2.3 Keywords | Competitor names | 10 minutes | Low |
| 2.5.1 Private API | Third-party SDK | 1-3 days | Medium |
| 3.1.1 IAP | External payment | 3-7 days | High |
| 3.1.2 Subscription | Missing terms | 1-2 days | Medium |
| 4.0 Web wrapper | Insufficient native | 1-2 weeks | High |
| 4.0 Poor UI | Design quality | 3-7 days | Medium |
| 4.2 Too simple | Insufficient features | 1-2 weeks | High |
| 4.3 Spam | Duplicate apps | Varies | High |
| 5.1.1 Privacy policy | Missing URL | 1-2 hours | Low |
| 5.1.1 Data collection | Excess permissions | 1-2 days | Low-Medium |
| 5.1.2 ATT | Missing prompt | 1-2 days | Medium |
| 5.1.2 Nutrition labels | Inaccurate labels | 1-2 hours | Low |
| 5.2.1 Legal | Territory laws | Varies | High |

## When Each Strategy Applies

| Rejection Type | Fix | Clarify | Push Back | Appeal |
|---------------|-----|---------|-----------|--------|
| 2.1 Crashes | ✅ | | | |
| 2.1 Placeholder | ✅ | | | |
| 2.3 Metadata | ✅ | | | |
| 2.5.1 Private API | ✅ | | | |
| 3.1.1 IAP | ✅ | Sometimes | | |
| 3.1.2 Subscriptions | ✅ | Sometimes | | |
| 4.0 Design | ✅ | Sometimes | Sometimes | |
| 4.2 Minimum functionality | Sometimes | ✅ | ✅ | ✅ |
| 4.3 Spam | ✅ | ✅ | Sometimes | Sometimes |
| 5.1.1 Privacy | ✅ | | | |
| 5.1.2 Tracking | ✅ | | | |
| 5.2.1 Legal | ✅ | | | |
