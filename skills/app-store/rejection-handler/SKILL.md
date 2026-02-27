---
name: rejection-handler
description: Handle App Store rejections, prepare submissions to avoid common rejection reasons, write Resolution Center responses, and navigate the appeal process. Use when user's app was rejected, is preparing for submission, or needs help with App Review.
allowed-tools: [Read, Glob, Grep, AskUserQuestion]
---

# App Store Rejection Handler

Guide developers through handling App Store rejections — from understanding why the rejection happened, to crafting effective responses, to escalating when appropriate.

## When This Skill Activates

Use this skill when the user:
- Says their app was rejected by App Review
- Asks for help understanding a rejection notice
- Wants to prepare a submission to minimize rejection risk
- Needs help writing a response in Resolution Center
- Wants to appeal a rejection decision
- Asks about common App Store rejection reasons
- Mentions "App Review", "guideline violation", or "rejection"
- Wants a pre-submission audit for guideline compliance

## Reference Files

Before handling a rejection, load:

| File | Purpose |
|------|---------|
| **common-rejections.md** | Top 20 rejection reasons with fixes and response templates |

## Pre-Submission Audit Checklist

Run through this before submitting to avoid the most common rejections. Each item maps to a specific App Store Review Guideline.

### App Completeness (Guideline 2.1)

- [ ] App launches without crashing on all supported devices
- [ ] All features described in metadata are functional
- [ ] No placeholder content (lorem ipsum, test data, TODO screens)
- [ ] No broken links or dead-end navigation
- [ ] All buttons and interactive elements work
- [ ] Demo/test accounts provided in App Review notes if login is required
- [ ] Beta or test labels removed from UI and metadata

### Accurate Metadata (Guideline 2.3)

- [ ] App name matches what the app actually does
- [ ] Screenshots show the actual current app UI
- [ ] Description accurately represents functionality
- [ ] Category selection is appropriate
- [ ] No misleading claims ("best", "#1") without substantiation
- [ ] Age rating reflects actual content
- [ ] What's New text describes actual changes (not marketing copy)
- [ ] Keywords do not include competitor names or misleading terms

### Software Requirements (Guideline 2.5)

- [ ] App uses only public APIs (no private frameworks)
- [ ] No deprecated APIs that are marked for removal
- [ ] App works on the oldest supported iOS/macOS version claimed
- [ ] No remote code execution (no downloading and running code)
- [ ] IPv6 networking compatibility

### In-App Purchase Compliance (Guideline 3.1)

- [ ] All digital content/features use Apple's IAP (not Stripe, PayPal, etc.)
- [ ] Physical goods/services CAN use external payment
- [ ] Subscription terms are clear before purchase
- [ ] "Restore Purchases" button exists and works
- [ ] Subscription management is accessible within the app
- [ ] No language directing users to purchase outside the app
- [ ] Free trial terms are clearly stated

### Design Quality (Guideline 4.0)

- [ ] App uses native UI components (not a web wrapper for existing website)
- [ ] Supports current device screen sizes
- [ ] No empty states without guidance
- [ ] Error messages are user-friendly
- [ ] Loading states exist for async operations
- [ ] App provides meaningful functionality (not a glorified bookmark)

### Privacy Compliance (Guideline 5.1)

- [ ] Privacy policy URL is provided and accessible
- [ ] Privacy policy accurately describes data collection
- [ ] App Tracking Transparency prompt shown before tracking (if applicable)
- [ ] Privacy Nutrition Labels in App Store Connect match actual behavior
- [ ] Data minimization — only collect what you need
- [ ] User data deletion mechanism exists (if data is collected)
- [ ] Privacy manifest included (required for certain APIs, iOS 17+)

### Legal Requirements (Guideline 5.2)

- [ ] App complies with local laws in all territories where distributed
- [ ] Required age gates for restricted content
- [ ] Health/medical disclaimers if applicable
- [ ] Financial disclaimers if applicable

### App Review Notes (Submission)

- [ ] Demo account credentials provided (if login required)
- [ ] Special hardware instructions noted (if needed)
- [ ] Backend requirements explained (if features need server access)
- [ ] Explain non-obvious features or flows
- [ ] Mention any entitlements and why they're needed

## Rejection Handling Process

### Step 1: Read the Rejection Notice Carefully

When a user reports a rejection, gather:

1. **The exact guideline cited** (e.g., "Guideline 4.2 - Design - Minimum Functionality")
2. **The full rejection message text** (Apple provides specific details)
3. **Any screenshots or annotations** Apple included
4. **Whether this is a first submission or re-submission**

Ask via AskUserQuestion:
- "Can you paste the full rejection message from App Store Connect?"
- "Which guideline number was cited?"
- "Is this the first time this app has been submitted?"
- "Have you made changes since a previous rejection?"

### Step 2: Identify the Rejection Category

Read **common-rejections.md** and match the cited guideline to the detailed breakdown. Determine:

- Is the rejection objectively correct? (crash, privacy violation, missing IAP)
- Is the rejection subjective? (minimum functionality, design quality)
- Is the rejection possibly in error? (reviewer misunderstood the app)

### Step 3: Determine Response Strategy

```
Is the rejection objectively correct?
├── YES → Fix the issue and resubmit (Phase A)
└── NO → Did the reviewer misunderstand?
    ├── YES → Clarify with evidence (Phase B)
    └── NO → Is it a subjective judgment call?
        ├── YES → Evaluate: fix or push back? (Phase C)
        └── NO → Appeal (Phase D)
```

### Phase A: Fix and Resubmit

For clear violations (crashes, missing privacy policy, private API usage):

1. Fix the specific issue cited
2. Test thoroughly on the device types Apple may have tested on
3. In the Resolution Center reply, briefly state what was fixed
4. Resubmit the binary

**Response template (Fix and Resubmit):**
```
Thank you for the review.

We've addressed the issue cited in Guideline [X.X]:

- [Specific change made]
- [How it was verified]

The updated build ([version] [build number]) has been submitted
for review.

Please let us know if you have any further questions.
```

### Phase B: Clarify with Evidence

For rejections based on misunderstanding:

1. Do NOT be defensive or argumentative
2. Explain clearly what the app does and why it doesn't violate the guideline
3. Provide screenshots, video, or step-by-step instructions
4. Reference the specific guideline language and explain how you comply

**Response template (Clarification):**
```
Thank you for reviewing our app.

We'd like to provide additional context regarding Guideline [X.X].

[Clear explanation of how the feature/app works]

To demonstrate this:
1. [Step-by-step instructions to see the relevant feature]
2. [Step-by-step instructions continued]

[Optional: screenshot or video link]

We believe this addresses the concern raised. We're happy to
provide any additional information or make a call to discuss
further.
```

### Phase C: Evaluate Subjective Rejections

For "minimum functionality" (4.2), "spam" (4.3), or "design" (4.0) rejections, decide:

**When to fix (usually the better path):**
- If you honestly agree the app could be more substantial
- If adding 2-3 features would make a meaningful difference
- If the reviewer's feedback, while harsh, has a point
- If you're early in development and can improve quickly

**When to push back:**
- If the app intentionally does one thing well (it's a focused tool, not incomplete)
- If similar apps exist on the App Store with less functionality
- If the reviewer appears to have missed core features
- If you have user testimonials or metrics showing the app delivers value

**Response template (Pushing Back on Subjective Rejection):**
```
Thank you for your feedback on our app.

We respectfully believe [App Name] provides meaningful
functionality as outlined in Guideline [X.X]:

1. [Core value proposition]
2. [Specific features that demonstrate depth]
3. [User benefit that differentiates from a simple website]

[App Name] is designed as a focused [type of app] that excels
at [specific purpose]. This intentional focus is a design
decision, not a limitation.

[Optional: "Similar apps like [X] and [Y] are available on the
App Store with comparable scope."]

We'd welcome the opportunity to discuss this further or
demonstrate the app's functionality in detail.
```

### Phase D: Formal Appeal

If Resolution Center responses don't resolve the issue, escalate.

## Appeal Escalation Path

### Level 1: Resolution Center Reply (First Response)

- Reply directly in Resolution Center
- Be professional, concise, and evidence-based
- Include demo video if helpful
- Response time: 1-3 business days typically

### Level 2: Request a Phone Call

If the Resolution Center reply doesn't resolve it:

- In Resolution Center, explicitly request: "We'd appreciate the opportunity to discuss this via phone call with the App Review team."
- Apple sometimes offers this for complex cases
- Prepare a clear, concise verbal explanation
- Have the app ready to demo live
- Response time: 3-7 business days

### Level 3: App Review Board Appeal

If Level 1 and Level 2 fail:

- Submit a formal appeal at https://developer.apple.com/contact/app-store/
- Choose "App Review" and then "Appeal"
- This goes to a separate board, not the same reviewer
- One appeal per rejection — make it count
- Response time: 5-14 business days

**Appeal writing tips:**
- Lead with facts, not emotions
- Reference specific guideline language
- Explain why the rejection criteria don't apply or are being misapplied
- Mention comparable apps on the App Store (carefully — don't name-shame, but establish precedent)
- Keep it under 500 words
- Include a demo video link if the issue is about functionality

### When to Change Approach vs. Push Back

**Apple is usually right about:**
- Crashes and bugs (fix them)
- Privacy violations (fix them)
- Missing IAP for digital goods (implement IAP)
- Misleading metadata (fix it)
- Private API usage (use public APIs)

**Apple is sometimes wrong about:**
- "Minimum functionality" for intentionally focused apps
- "Spam" for apps that serve distinct user segments
- "Could be a website" for apps with native features (widgets, notifications, offline)
- "Not enough native UI" for apps with legitimate custom interfaces
- Feature misunderstandings when reviewers don't find non-obvious functionality

**Rule of thumb:** If 3 people independently look at the rejection and all say "Apple has a point," fix the issue. If they all say "this seems wrong," push back with evidence.

## Timeline Expectations

### Typical Review Times

| Scenario | Expected Timeline |
|----------|------------------|
| Initial submission | 1-3 days (24-48 hours typical) |
| Resubmission after rejection | 1-3 days |
| Expedited review request | Same day to 1 day |
| Resolution Center reply | 1-3 business days |
| Phone call request | 3-7 business days |
| App Review Board appeal | 5-14 business days |

### When to Request Expedited Review

Apple allows expedited review requests for:
- Critical bug fixes for live apps
- Time-sensitive events (conference launch, holiday tie-in)
- Security patches

Do NOT request expedited review for:
- Initial submissions (no urgency justification)
- Feature updates (plan ahead)
- Rejected apps (use Resolution Center instead)

### Seasonal Considerations

- **WWDC (June)**: Slight delays as team focuses on new OS reviews
- **September-October**: iPhone launch creates surge, slightly longer times
- **December holidays**: Reduced staff, plan submissions before mid-December
- **App Store freeze**: Typically Dec 23-27, no new submissions processed

## Resolution Center Best Practices

### Tone

- Professional and respectful, always
- Concise — reviewers handle hundreds of cases
- Evidence-based — screenshots, videos, step-by-step instructions
- Solution-oriented — "here's what we changed" or "here's why this complies"

### What to Include

- Reference the specific guideline number
- Quote the specific language from the rejection
- Provide clear evidence (screenshots, demo video, step-by-step reproduction)
- If you fixed something, state exactly what changed and in which build
- If you're clarifying, provide a walkthrough of the misunderstood feature

### What to Avoid

- Emotional language ("this is unfair", "we worked so hard")
- Threats (legal action, press coverage, social media complaints)
- Comparing to competitor apps in a negative way
- Long, rambling responses (keep under 300 words for replies)
- Multiple replies in quick succession (wait for a response)

### Response Length

- First reply: 100-200 words
- Clarification with evidence: 200-300 words
- Appeal: 300-500 words

## Output Format

When handling a rejection, produce this assessment:

```markdown
# Rejection Analysis: [App Name]

## Rejection Details
- **Guideline**: [X.X] - [Guideline Name]
- **Submission type**: Initial / Resubmission
- **Rejection message**: [Quoted text]

## Assessment
- **Category**: Objective violation / Subjective judgment / Possible error
- **Validity**: [Is Apple right? Partially right? Wrong?]
- **Recommended strategy**: Fix and resubmit / Clarify / Push back / Appeal

## Recommended Response

[Draft Resolution Center response]

## If Fixing: Action Items
1. [Specific change needed]
2. [Specific change needed]
3. [Verification step before resubmitting]

## If Appealing: Evidence to Prepare
- [Screenshot/video needed]
- [Comparable App Store precedent]
- [Guideline language to reference]

## Pre-Resubmission Checklist
- [ ] Issue addressed
- [ ] Tested on [device types]
- [ ] App Review notes updated
- [ ] Demo account credentials current
- [ ] Resolution Center response sent
```

## Related Skills

- **common-rejections.md** — Detailed breakdown of top 20 rejection reasons with fix guides
- Related: `release-review` — Pre-release audit that catches rejection-causing issues
- Related: `security/privacy-manifests` — Privacy manifest compliance
- Related: `app-store/app-description-writer` — Metadata accuracy (prevents Guideline 2.3 rejections)
- Related: `monetization` — IAP compliance guidance (prevents Guideline 3.1 rejections)
