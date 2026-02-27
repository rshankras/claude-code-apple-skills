# Legal Document Templates

Ready-to-use legal document templates for Apple platform apps. Replace placeholders with your app's details before publishing.

## Placeholders

Use these placeholders throughout all templates. The generator fills them automatically based on project context and user answers.

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `[APP_NAME]` | App display name | "FocusTimer" |
| `[DEVELOPER_NAME]` | Developer or company name | "Jane Smith" or "Acme LLC" |
| `[CONTACT_EMAIL]` | Privacy/support email | "privacy@example.com" |
| `[EFFECTIVE_DATE]` | Document effective date | "January 1, 2026" |
| `[WEBSITE_URL]` | Developer website or app page | "https://example.com" |

---

## Privacy Policy Template

```markdown
# Privacy Policy for [APP_NAME]

**Effective Date:** [EFFECTIVE_DATE]
**Last Updated:** [EFFECTIVE_DATE]

[DEVELOPER_NAME] ("we," "our," or "us") built [APP_NAME] as a [commercial / freemium / free] app. This Privacy Policy explains how we collect, use, and protect your information when you use [APP_NAME].

By using [APP_NAME], you agree to the practices described in this Privacy Policy. If you do not agree, please do not use the app.

---

## 1. Information We Collect

### Information You Provide Directly

<!-- Include if app has accounts or user-provided content -->

- **Account information:** If you create an account, we collect your email address and display name.
- **User content:** Any content you create within the app (e.g., notes, tasks, projects) is stored to provide the service.
- **Support requests:** If you contact us for support, we collect your email address and the content of your message.

### Information Collected Automatically

<!-- Include if app uses analytics or crash reporting -->

- **Usage data:** We collect anonymous usage data such as which features you use, session duration, and interaction patterns. This data is not linked to your identity.
- **Device information:** We may collect device model, operating system version, and app version for compatibility and debugging purposes.
- **Crash data:** If the app crashes, we collect diagnostic data including crash logs and device state to help us fix issues.

<!-- Include if app uses location -->

- **Location data:** [APP_NAME] collects [precise / approximate] location data to [provide location-based features / improve recommendations]. Location data is collected only while you are using the app and only with your explicit permission.

### Information from Third Parties

<!-- Include if app uses third-party login -->

- **Sign in with Apple:** If you sign in with Apple, we receive your Apple ID, name (if you choose to share it), and email address (which may be a private relay address).
- **Third-party login:** If you sign in with a third-party service, we receive your name and email address as authorized by you through that service.

### Information We Do NOT Collect

<!-- Include for minimal data collection apps -->

- We do not collect personal information.
- We do not require account creation.
- We do not track you across other apps or websites.
- All data stays on your device unless you explicitly enable cloud sync.

---

## 2. How We Use Your Information

We use the information we collect to:

- Provide and maintain [APP_NAME]'s core functionality
- Improve and optimize the app experience
- Fix bugs and resolve technical issues
- Respond to your support requests
- Send important service-related notices (e.g., security alerts, terms updates)
- Understand aggregate usage patterns to guide product development

We do NOT use your information to:

- Sell your data to third parties
- Build advertising profiles
- Make automated decisions that significantly affect you

---

## 3. How We Share Your Information

We do not sell, rent, or trade your personal information.

We may share information in the following limited circumstances:

- **Service providers:** We use third-party services to help operate [APP_NAME] (see Section 4). These providers only access data necessary to perform their services and are contractually required to protect it.
- **Legal requirements:** We may disclose information if required by law, regulation, legal process, or government request.
- **Safety:** We may disclose information to protect the safety, rights, or property of [DEVELOPER_NAME], our users, or the public.
- **Business transfers:** If [DEVELOPER_NAME] is involved in a merger, acquisition, or sale of assets, your information may be transferred as part of that transaction. We will notify you of any such change.

---

## 4. Third-Party Services

<!-- List actual services used by the app -->

[APP_NAME] uses the following third-party services:

| Service | Purpose | Privacy Policy |
|---------|---------|----------------|
| Apple Analytics | App usage analytics | [Apple Privacy Policy](https://www.apple.com/privacy/) |
| TelemetryDeck | Privacy-focused analytics | [TelemetryDeck Privacy](https://telemetrydeck.com/privacy/) |
| Sentry | Crash reporting | [Sentry Privacy Policy](https://sentry.io/privacy/) |
| RevenueCat | Subscription management | [RevenueCat Privacy](https://www.revenuecat.com/privacy/) |
| Firebase Analytics | Usage analytics | [Google Privacy Policy](https://policies.google.com/privacy) |
| AdMob | Advertising | [Google Privacy Policy](https://policies.google.com/privacy) |

<!-- Remove services not used by the app -->

---

## 5. Data Retention

- **Account data:** Retained while your account is active. Deleted within 30 days of account deletion request.
- **Usage analytics:** Aggregated and anonymized. Raw data retained for up to 12 months, then deleted.
- **Crash data:** Retained for up to 12 months to facilitate bug resolution, then deleted.
- **User content:** Retained while your account is active. You may export or delete your content at any time through the app.

---

## 6. Data Security

We implement reasonable technical and organizational measures to protect your information, including:

- Encryption in transit (TLS/HTTPS) for all network communications
- Encryption at rest for sensitive data stored on device (Keychain, encrypted Core Data)
- Access controls limiting who within our organization can access user data
- Regular review of data collection and storage practices

No method of transmission or storage is 100% secure. We cannot guarantee absolute security, but we take commercially reasonable steps to protect your data.

---

## 7. Your Rights

You have the following rights regarding your personal information:

- **Access:** Request a copy of the personal data we hold about you.
- **Correction:** Request correction of inaccurate personal data.
- **Deletion:** Request deletion of your personal data.
- **Export:** Request a portable copy of your data.
- **Withdraw consent:** Withdraw consent for data processing at any time.

To exercise any of these rights, contact us at [CONTACT_EMAIL]. We will respond within 30 days.

### For European Union Residents (GDPR)

If you are located in the European Economic Area (EEA), you have additional rights under the General Data Protection Regulation (GDPR):

- **Data controller:** [DEVELOPER_NAME], [CONTACT_EMAIL]
- **Lawful basis for processing:** We process your data based on:
  - Your consent (analytics, marketing -- which you can withdraw at any time)
  - Performance of a contract (providing the service you requested)
  - Legitimate interests (improving our service, security, fraud prevention)
- **Data subject rights:** In addition to the rights above, you have the right to:
  - Restrict processing of your data
  - Object to processing based on legitimate interests
  - Lodge a complaint with your local Data Protection Authority
- **Data transfers:** If we transfer data outside the EEA, we ensure appropriate safeguards are in place (Standard Contractual Clauses or adequacy decisions).
- **Data retention:** We retain personal data only as long as necessary for the purposes outlined in Section 5.

### For California Residents (CCPA)

If you are a California resident, you have additional rights under the California Consumer Privacy Act (CCPA):

- **Right to know:** You may request the categories and specific pieces of personal information we have collected about you.
- **Right to delete:** You may request deletion of your personal information.
- **Right to opt-out:** We do not sell your personal information. If this changes, we will provide a "Do Not Sell or Share My Personal Information" link.
- **Non-discrimination:** We will not discriminate against you for exercising your CCPA rights.

To exercise your CCPA rights, contact us at [CONTACT_EMAIL].

### For Indian Residents (DPDP)

If you are located in India, you have rights under the Digital Personal Data Protection Act (DPDP):

- **Data fiduciary:** [DEVELOPER_NAME], [CONTACT_EMAIL]
- **Purpose:** Your data is processed for the purposes described in Section 2.
- **Consent:** We obtain your consent before processing personal data, except where permitted by law.
- **Data principal rights:** You have the right to:
  - Access your personal data
  - Correct inaccurate or incomplete data
  - Erase your personal data
  - Nominate a representative to exercise your rights
  - File a grievance with us or the Data Protection Board of India
- **Contact:** For data-related requests, contact us at [CONTACT_EMAIL].

---

## 8. Children's Privacy

<!-- Standard version (app does not target children) -->

[APP_NAME] is not intended for children under 13. We do not knowingly collect personal information from children under 13. If we discover that we have collected data from a child under 13, we will delete it promptly. If you believe a child has provided us with personal information, please contact us at [CONTACT_EMAIL].

<!-- COPPA version (app targets or allows children under 13) -->

[APP_NAME] complies with the Children's Online Privacy Protection Act (COPPA). For users under 13:

- We require verifiable parental consent before collecting any personal information.
- We collect only the minimum data necessary for the app to function.
- We do not serve behavioral advertising to children.
- Parents/guardians may:
  - Review the personal information we have collected from their child
  - Request deletion of their child's personal information
  - Refuse to permit further collection
- To exercise parental rights, contact us at [CONTACT_EMAIL].

---

## 9. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. When we make significant changes, we will:

- Update the "Last Updated" date at the top of this document
- Notify you through the app or via email (for significant changes)
- Post the updated policy at [WEBSITE_URL]/privacy-policy

Your continued use of [APP_NAME] after changes are posted constitutes acceptance of the updated Privacy Policy.

---

## 10. Contact Us

If you have questions or concerns about this Privacy Policy or our data practices, contact us at:

- **Email:** [CONTACT_EMAIL]
- **Developer:** [DEVELOPER_NAME]
- **Website:** [WEBSITE_URL]
```

---

## Terms of Service Template

```markdown
# Terms of Service for [APP_NAME]

**Effective Date:** [EFFECTIVE_DATE]
**Last Updated:** [EFFECTIVE_DATE]

Please read these Terms of Service ("Terms") carefully before using [APP_NAME] ("the App") operated by [DEVELOPER_NAME] ("we," "our," or "us").

By downloading, installing, or using [APP_NAME], you agree to be bound by these Terms. If you do not agree, do not use the App.

---

## 1. Acceptance of Terms

By accessing or using [APP_NAME], you confirm that you are at least 13 years of age (or the minimum age required in your jurisdiction) and agree to comply with these Terms. If you are using the App on behalf of an organization, you represent that you have authority to bind that organization to these Terms.

---

## 2. License Grant

We grant you a limited, non-exclusive, non-transferable, revocable license to use [APP_NAME] on Apple devices that you own or control, subject to these Terms and the Apple Media Services Terms and Conditions.

This license does not allow you to:

- Copy, modify, or distribute the App
- Reverse-engineer, decompile, or disassemble the App
- Rent, lease, lend, sell, or sublicense the App
- Use the App for any unlawful purpose
- Remove or alter any proprietary notices in the App

---

## 3. User Accounts

<!-- Include if app has accounts -->

If [APP_NAME] requires an account:

- You are responsible for maintaining the confidentiality of your account credentials.
- You are responsible for all activity under your account.
- You must provide accurate and complete information when creating your account.
- You must notify us immediately of any unauthorized access to your account.

We reserve the right to suspend or terminate accounts that violate these Terms.

---

## 4. User Content

<!-- Include if app allows user-generated content -->

You retain ownership of any content you create within [APP_NAME] ("User Content"). By using the App, you grant us a limited license to store, process, and display your User Content solely to provide the service.

You agree not to create or upload content that:

- Is illegal, harmful, threatening, abusive, or harassing
- Infringes on intellectual property rights of others
- Contains malware or harmful code
- Violates any applicable law or regulation

We reserve the right to remove User Content that violates these Terms.

---

## 5. Intellectual Property

[APP_NAME], including its design, code, features, content, and branding, is owned by [DEVELOPER_NAME] and protected by copyright, trademark, and other intellectual property laws.

All trademarks, service marks, and trade names used in the App are the property of [DEVELOPER_NAME] or their respective owners.

---

## 6. Subscriptions and Purchases

<!-- Include if app has in-app purchases or subscriptions -->

### Pricing

- All prices are displayed in your local currency through the App Store.
- Prices may change with notice. Existing subscribers will be notified before renewal at a new price.

### Subscriptions

- Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.
- Your Apple ID account will be charged for renewal within 24 hours prior to the end of the current period.
- You can manage and cancel subscriptions in your Apple ID account settings.

### Refunds

- All purchases are processed through Apple. Refund requests must be submitted through Apple's support: [https://reportaproblem.apple.com](https://reportaproblem.apple.com)
- We do not process refunds directly.

### Free Trials

- If offered, free trials automatically convert to paid subscriptions unless cancelled before the trial ends.
- Trial eligibility is determined by Apple and limited to one trial per Apple ID.

---

## 7. Termination

We may suspend or terminate your access to [APP_NAME] at any time, with or without cause, with or without notice. Reasons for termination include:

- Violation of these Terms
- Conduct that we determine is harmful to other users or to us
- Extended periods of inactivity (for account-based services)

Upon termination:

- Your license to use the App is revoked.
- We may delete your account and associated data after a reasonable notice period.
- Provisions that by their nature should survive termination will survive (e.g., limitations of liability, intellectual property).

You may terminate your use at any time by deleting the App and, if applicable, requesting account deletion.

---

## 8. Disclaimer of Warranties

[APP_NAME] IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

We do not warrant that:

- The App will be uninterrupted, error-free, or secure
- Defects will be corrected
- The App will meet your specific requirements
- Data will not be lost

---

## 9. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, [DEVELOPER_NAME] SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF DATA, LOSS OF PROFITS, OR BUSINESS INTERRUPTION, ARISING OUT OF OR IN CONNECTION WITH YOUR USE OF [APP_NAME].

OUR TOTAL LIABILITY FOR ALL CLAIMS ARISING FROM OR RELATED TO THE APP SHALL NOT EXCEED THE AMOUNT YOU PAID FOR THE APP IN THE 12 MONTHS PRECEDING THE CLAIM, OR $50 USD, WHICHEVER IS GREATER.

---

## 10. Governing Law

These Terms are governed by the laws of [your state/country], without regard to conflict of law principles. Any disputes arising from these Terms will be resolved in the courts of [your jurisdiction].

---

## 11. Changes to Terms

We may update these Terms from time to time. When we make significant changes, we will:

- Update the "Last Updated" date at the top
- Notify you through the App or via email for material changes

Continued use of [APP_NAME] after changes are posted constitutes acceptance of the updated Terms.

---

## 12. Contact Us

If you have questions about these Terms, contact us at:

- **Email:** [CONTACT_EMAIL]
- **Developer:** [DEVELOPER_NAME]
- **Website:** [WEBSITE_URL]
```

---

## EULA Template

```markdown
# End-User License Agreement (EULA) for [APP_NAME]

**Effective Date:** [EFFECTIVE_DATE]

This End-User License Agreement ("EULA") is a legal agreement between you ("User") and [DEVELOPER_NAME] ("Licensor") for the use of [APP_NAME] ("the App").

By installing or using [APP_NAME], you agree to be bound by this EULA. If you do not agree, do not install or use the App.

This EULA supplements the Apple Licensed Application End User License Agreement (the "Standard EULA") available at [https://www.apple.com/legal/internet-services/itunes/dev/stdeula/](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/). In the event of a conflict between this EULA and the Standard EULA, this EULA shall govern.

---

## 1. License Grant

Subject to your compliance with this EULA, [DEVELOPER_NAME] grants you a limited, non-exclusive, non-transferable, revocable license to download, install, and use [APP_NAME] on Apple-branded devices that you own or control, as permitted by the Apple Media Services Terms and Conditions.

---

## 2. Restrictions

You may NOT:

- Copy, modify, or create derivative works of the App
- Reverse-engineer, decompile, disassemble, or attempt to derive the source code of the App
- Rent, lease, lend, sell, redistribute, or sublicense the App
- Remove, alter, or obscure any copyright, trademark, or proprietary notices
- Use the App for any illegal or unauthorized purpose
- Use the App to develop a competing product or service

---

## 3. Intellectual Property

The App, including all content, features, functionality, design, code, and documentation, is and remains the exclusive property of [DEVELOPER_NAME]. This EULA does not grant you any ownership rights in the App.

All feedback, suggestions, or ideas you provide about the App may be used by [DEVELOPER_NAME] without obligation to you.

---

## 4. Updates and Modifications

[DEVELOPER_NAME] may release updates, patches, or new versions of the App. Updates may be required for continued use. We are not obligated to provide updates, maintenance, or support, though we intend to continue improving the App.

---

## 5. Termination

This EULA is effective until terminated. It terminates automatically if you fail to comply with any term. Upon termination:

- You must cease all use of the App
- You must delete all copies of the App from your devices
- Sections that by their nature should survive will remain in effect

You may terminate this EULA at any time by deleting the App from your devices.

---

## 6. No Warranty

THE APP IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND. [DEVELOPER_NAME] DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

[DEVELOPER_NAME] DOES NOT WARRANT THAT THE APP WILL BE ERROR-FREE, UNINTERRUPTED, OR FREE OF HARMFUL COMPONENTS.

---

## 7. Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL [DEVELOPER_NAME] BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO YOUR USE OF THE APP.

[DEVELOPER_NAME]'S TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT PAID BY YOU FOR THE APP IN THE TWELVE (12) MONTHS PRECEDING THE EVENT GIVING RISE TO LIABILITY, OR FIFTY DOLLARS ($50 USD), WHICHEVER IS GREATER.

---

## 8. Governing Law

This EULA is governed by the laws of [your state/country]. Any disputes will be resolved in the courts of [your jurisdiction].

---

## 9. Contact

For questions about this EULA, contact:

- **Email:** [CONTACT_EMAIL]
- **Developer:** [DEVELOPER_NAME]
- **Website:** [WEBSITE_URL]
```

---

## Template Usage Notes

### Selecting Sections

Not all sections apply to every app. Use these guidelines:

| App Type | Include | Exclude |
|----------|---------|---------|
| Offline utility, no accounts | "Information We Do NOT Collect" | Account sections, third-party services, user content |
| Analytics-only app | Auto-collected data, third-party services table | Account sections, user content |
| Account-based app | All data collection sections | "Information We Do NOT Collect" |
| Subscription app | All sections including subscription terms | None |
| Kids app | COPPA sections | Standard children's privacy section |

### Placeholder Checklist

Before publishing, verify all placeholders are replaced:

- [ ] `[APP_NAME]` replaced everywhere
- [ ] `[DEVELOPER_NAME]` replaced everywhere
- [ ] `[CONTACT_EMAIL]` replaced with a working email
- [ ] `[EFFECTIVE_DATE]` set to publication date
- [ ] `[WEBSITE_URL]` set to a live, accessible URL
- [ ] Conditional sections removed or included based on app type
- [ ] Third-party services table updated with actual services used
- [ ] Regional sections (GDPR/CCPA/DPDP) included for target markets
- [ ] COPPA section included or excluded based on audience

### Formatting for Different Hosts

**GitHub Pages:** Use the Markdown as-is. GitHub Pages renders it directly.

**In-app display:** Convert Markdown to attributed string or use a Markdown renderer. Tables may need special handling.

**Website:** Convert to HTML. Most static site generators (Jekyll, Hugo, Next.js) handle Markdown natively.

### Annual Review Reminder

Legal documents should be reviewed at least annually or whenever:

- You add new third-party SDKs or services
- You change data collection practices
- You add new features that collect data (location, health, contacts)
- Privacy regulations change in your target markets
- You expand to new geographic markets
