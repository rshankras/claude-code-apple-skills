---
name: legal
description: Legal document generation and compliance guidance for indie Apple developers. Covers privacy policies, terms of service, EULAs, GDPR/CCPA/DPDP compliance, and Apple App Store legal requirements. Use when user needs legal documents or compliance guidance.
allowed-tools: [Read, Glob, Grep, AskUserQuestion]
---

# Legal Document Generation & Compliance

Legal document generation and compliance guidance for indie Apple developers. Generate privacy policies, terms of service, and EULAs tailored to your app's data practices and target markets.

## When This Skill Activates

Use this skill when the user:
- Needs a privacy policy for their app
- Needs terms of service or EULA
- Asks about legal compliance for App Store submission
- Mentions GDPR, CCPA, DPDP, or COPPA compliance
- Wants to update legal documents after adding analytics, ads, or tracking
- Asks about Apple's privacy requirements or Privacy Nutrition Labels
- Needs legal document hosting guidance (GitHub Pages, in-app, website)

## Available Skills

### privacy-policy/
Generate privacy policies, terms of service, and EULAs tailored to your app's data collection practices, third-party SDKs, and target regions. Includes Apple Privacy Nutrition Label mapping and hosting guidance.

## How to Use

1. User requests legal documents or compliance guidance
2. Read `privacy-policy/SKILL.md` for the full generation workflow
3. The skill will ask configuration questions about data practices
4. Documents are generated in Markdown with app-specific placeholders filled in

## Related Skills

- `generators/consent-flow` -- GDPR/CCPA consent UI and tracking consent management
- `generators/account-deletion` -- Account deletion flow (App Store requirement)
- `generators/permission-priming` -- Pre-permission UI patterns (ATT priming)
- `monetization/` -- Subscription terms and pricing disclosures
