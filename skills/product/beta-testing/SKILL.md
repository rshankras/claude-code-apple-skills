---
name: beta-testing
description: Beta testing strategy for iOS/macOS apps. Covers TestFlight program setup, beta tester recruitment, feedback collection methodology, user interviews, signal-vs-noise interpretation, and go/no-go launch readiness decisions. Use when planning a beta, setting up TestFlight, collecting user feedback, or deciding if ready to launch.
allowed-tools: [Read, Write, Glob, Grep, AskUserQuestion]
---

# Beta Testing Strategy

End-to-end beta testing workflow for Apple platform apps — from TestFlight setup through feedback collection to launch readiness decision.

## When This Skill Activates

Use this skill when the user:
- Wants to run a beta test or plan a beta program
- Needs to set up TestFlight for internal or external testing
- Asks how to collect user feedback during beta
- Wants to know if their app is ready to launch
- Needs help designing a beta feedback survey
- Asks "how many beta testers do I need?"
- Mentions "TestFlight", "beta testers", "soft launch", or "launch readiness"
- Wants to plan a structured beta rollout
- Needs a go/no-go framework for shipping

## Process

### Phase 1: TestFlight Program Strategy

Before recruiting testers, understand Apple's two-tier beta system.

#### Internal Testing

| Attribute | Details |
|-----------|---------|
| Max testers | 100 |
| App Review required | No |
| Build availability | Immediate after upload |
| Tester requirement | Must be App Store Connect users |
| Best for | Team, close collaborators, developer friends |
| Expiration | 90 days from build upload |

**Use internal testing for:**
- Catching crashes and obvious bugs before anyone else sees the app
- Validating core flows work end-to-end
- Getting feedback from people who will be honest (friends, fellow devs)

#### External Testing

| Attribute | Details |
|-----------|---------|
| Max testers | 10,000 |
| App Review required | Yes (Beta App Review — usually 24-48 hours) |
| Build availability | After Beta App Review approval |
| Tester requirement | Anyone with an email address and iOS/macOS device |
| Best for | Real users, broader audience, validating product-market fit |
| Expiration | 90 days from build upload |

**Use external testing for:**
- Validating with real users who have no context about your app
- Stress-testing with diverse devices, OS versions, and usage patterns
- Gathering signal on whether the value proposition resonates

#### Group Management

Create tester cohorts for targeted feedback:

| Cohort | Size | Purpose | What to Ask |
|--------|------|---------|-------------|
| Power Users | 10-20 | Deep feature testing, edge cases | Does this handle your advanced workflows? |
| Casual Users | 20-50 | First-impression and onboarding quality | Was anything confusing in the first 5 minutes? |
| Accessibility Testers | 5-10 | VoiceOver, Dynamic Type, color contrast | Can you complete core tasks with accessibility features? |
| Domain Experts | 5-10 | Validate domain-specific correctness | Is the [domain] logic accurate and trustworthy? |

**TestFlight group tips:**
- Name groups clearly (e.g., "Wave 1 - Power Users", "Wave 2 - General")
- Use different "What to Test" descriptions per group
- Stagger group invitations — don't invite everyone at once

### Phase 2: Beta Tester Recruitment

#### How Many Testers Per Stage

| Stage | Testers | Duration | Goal |
|-------|---------|----------|------|
| Internal alpha | 10-20 | 1-2 weeks | Crash-free, core flows work |
| External wave 1 | 50-200 | 2 weeks | Validate UX, find confusion points |
| External wave 2 | 200-1,000 | 2 weeks | Stress-test, validate at scale |
| Open beta (optional) | 1,000+ | 1-2 weeks | Final validation, build buzz |

**Rule of thumb:** You need at least 50 external testers to get meaningful signal. Below 50, individual preferences dominate.

#### Where to Find Beta Testers

**High-quality sources (engaged, will give feedback):**
- **Indie dev communities** — Indie Dev Monday, iOS Dev Weekly Slack, Mastodon #iosdev
- **Reddit communities** — r/iOSBeta, r/apple, domain-specific subreddits (r/productivity, r/fitness, etc.)
- **Twitter/X** — Post "Looking for beta testers for [one-line pitch]" with a screenshot
- **ProductHunt Upcoming** — List your app, collect emails before launch
- **Friends and family** — Honest if you tell them honesty matters more than kindness

**Medium-quality sources (volume, less feedback):**
- **BetaList** — Submit for free listing
- **Beta testing communities** — BetaFamily, ErliBird
- **Discord servers** — App development and domain-specific servers

**Low-quality sources (avoid for signal):**
- Random giveaway sites (testers who just want free stuff)
- Paid beta testers (financially motivated, not genuine users)

#### Incentive Strategies

| Incentive | Best For | Notes |
|-----------|----------|-------|
| Early access | All testers | The default — being first is often enough |
| Lifetime free / pro unlock | Power users | Strong motivator, limited cost to you |
| Credit in app (About screen) | Engaged testers | Recognition matters to some users |
| Direct access to developer | Power users | They feel heard, you get deep feedback |
| Discount at launch | Wave 2+ testers | Good for larger cohorts |

**What NOT to offer:** Cash payment for testing. It attracts the wrong people and biases feedback.

### Phase 3: Feedback Collection Methodology

Collect feedback through multiple channels — different methods catch different signals.

#### Channel 1: In-App Feedback Form

Build a simple feedback mechanism directly in the app. Three fields are enough:

```
1. What's broken? (bugs, crashes, errors)
2. What's confusing? (UX that doesn't make sense)
3. What's missing? (features you expected but didn't find)
```

**Implementation tips:**
- Add a "Send Feedback" button in Settings (always visible during beta)
- Include device info, OS version, and app version automatically
- Attach a screenshot option (but don't require it)
- Send to a dedicated email or use a simple form service
- Timestamp and tag by tester cohort

#### Channel 2: TestFlight Built-In Feedback

TestFlight's native feedback is surprisingly useful:
- Users take a screenshot, annotate it, and add text
- Feedback arrives in App Store Connect with device/OS metadata
- Crash reports are automatic
- No extra infrastructure needed

**Tip:** In your TestFlight "What to Test" field, be specific:
```
This week, please test:
1. Creating a new [item] from scratch
2. Editing an existing [item]
3. Sharing [item] with someone

Report anything confusing or broken via TestFlight feedback (screenshot + description).
```

#### Channel 3: Short Surveys (Max 5 Questions)

Send a survey at the end of each beta wave. Use AskUserQuestion to help design survey questions tailored to the app.

**Template survey (adapt per app):**

1. **How would you rate the overall experience?** (1-5 stars)
2. **What was the most confusing part?** (free text)
3. **What feature would make you use this daily?** (free text)
4. **Would you pay for this app?** (Yes / No / Maybe — if Yes, how much?)
5. **How likely are you to recommend this to a friend?** (0-10 NPS scale)

**Survey rules:**
- Maximum 5 questions — completion rate drops 20% per additional question
- Always include one open-ended question (the best insights come from free text)
- Send via email, not in-app (don't interrupt usage)
- Send 5-7 days after they start testing (enough time to form opinions)

#### Channel 4: 1-on-1 User Interviews

The highest-signal feedback channel. Do 5-8 interviews per beta wave.

**Who to interview:**
- 2-3 testers who used the app heavily (understand power user needs)
- 2-3 testers who tried it once and stopped (understand drop-off reasons)
- 1-2 testers from the accessibility cohort

**Logistics:**
- 20-30 minutes via video call or phone
- Record with permission (for your notes, not public)
- Take written notes even if recording

### Phase 4: User Interview Guide

#### The 5 Key Questions

Ask these in order. Each builds on the previous:

1. **"What were you trying to do when you opened the app?"**
   - Reveals their mental model and expectations
   - Listen for: Does their goal match your intended use case?

2. **"Walk me through what happened."**
   - Have them narrate their experience step by step
   - Listen for: Where did they pause, backtrack, or get stuck?

3. **"What did you expect to happen at [specific moment]?"**
   - Reveals UX gaps between expectation and reality
   - Listen for: Mismatches between your design and their mental model

4. **"What was the most confusing part?"**
   - Direct question about pain points
   - Listen for: Recurring themes across multiple interviews

5. **"If this app cost $X/month, what would make it worth paying for?"**
   - Reveals perceived value and priority features
   - Listen for: What they mention first (that's the hero feature)

#### How to Listen (Interview Discipline)

**Do:**
- Nod and say "Tell me more about that"
- Ask "Why?" at least twice to get past surface answers
- Take notes on exact phrases they use (their words, not your interpretation)
- Let silence sit — people fill silence with valuable thoughts
- Ask "What else?" after they finish answering

**Don't:**
- Defend your design decisions ("Well, the reason it works that way is...")
- Explain how to use the feature ("Oh, you just need to swipe left")
- Lead the witness ("Don't you think the onboarding was clear?")
- Dismiss feedback ("That's an edge case" or "Nobody else reported that")
- Promise to fix things in the interview ("We'll definitely add that")

**The golden rule:** Your job is to understand their experience, not to educate them about your app. If they're confused, the app is confusing — full stop.

### Phase 5: Interpreting Beta Feedback

#### Signal vs. Noise Framework

Not all feedback is equal. Use frequency to determine priority:

| Frequency | Classification | Action |
|-----------|---------------|--------|
| 1 person mentions it | Anecdote | Note it, don't act yet |
| 3 people mention it | Pattern | Investigate, consider fixing |
| 5+ people mention it | Must-fix | Fix before launch |
| 10+ people mention it | Showstopper | Fix immediately, send new build |

**Important:** Weight feedback by tester quality. One thoughtful power user's detailed report is worth more than ten casual testers saying "looks good."

#### Categorization Framework

Assign every piece of feedback to a priority level:

| Priority | Category | Examples | Action |
|----------|----------|----------|--------|
| P0 — Critical | Crash / data loss | App crashes on launch, saved data disappears, sync destroys content | Fix immediately, push new build within 24 hours |
| P1 — High | Broken flow | Cannot complete core task, flow dead-ends, save doesn't work | Fix before next beta wave |
| P2 — Medium | UX confusion | Users don't find feature, misunderstand UI, take wrong path | Fix before launch |
| P3 — Low | Nice-to-have | Feature requests, polish suggestions, "it would be cool if..." | Add to backlog, consider for v1.1 |

#### Distinguishing Problem Types

Two types of negative feedback require different solutions:

**"I don't understand how to do X"** = UX problem
- The feature exists but is hard to find or use
- Solution: Redesign the flow, add onboarding hints, improve labels
- Usually cheaper and faster to fix

**"I don't need X"** = Feature/product problem
- The feature exists but doesn't match user needs
- Solution: Rethink whether this feature belongs in v1, or pivot the approach
- More expensive to fix — may require cutting or rebuilding

**How to tell the difference:** Ask "If this feature were easier to use, would you use it?" If yes, it's UX. If no, it's a product problem.

### Phase 6: Go/No-Go Launch Decision

#### The Decision Framework

After completing beta testing, evaluate across three categories:

#### Green Light (Ship It)

All of these must be true:

- [ ] Crash-free rate > 99.5% (measured over at least 1,000 sessions)
- [ ] Core flow completion rate > 80% (users can accomplish the primary task)
- [ ] NPS > 30 (more promoters than detractors)
- [ ] Zero P0 bugs open
- [ ] Zero P1 bugs open
- [ ] No data loss or privacy issues
- [ ] App Store Review Guidelines compliance verified
- [ ] Performance acceptable on oldest supported device

#### Yellow Light (Ship with Caution)

Acceptable to launch, but address soon:

- Minor UX confusion that doesn't block core flow
- Missing nice-to-have features that testers requested
- P2 bugs that affect < 10% of users
- NPS between 20-30 (decent but not enthusiastic)
- Polish issues (animations, visual alignment, copy)
- Crash-free rate 99.0-99.5%

**Decision:** Launch, but fix yellow items in v1.0.1 within 1-2 weeks.

#### Red Light (Do Not Ship)

If any of these are true, delay launch:

- Crash-free rate < 99% (app is unstable)
- Core flow completion rate < 60% (users can't do the main thing)
- Any P0 bugs open (crashes, data loss)
- Data loss or corruption bugs exist
- Privacy issues (data leaking, missing privacy labels, no consent flow)
- NPS < 0 (more detractors than promoters)
- App rejected in Beta App Review (signals App Store Review will also reject)
- Core flow broken on common device/OS combinations

**Decision:** Go back to development. Fix all red items. Run another beta wave. Re-evaluate.

#### Making the Call

Use this checklist format to present the decision:

```markdown
# Go/No-Go Decision: [App Name] v[X.Y]

## Date: [Date]
## Beta Duration: [X weeks]
## Total Testers: [N]
## Sessions Analyzed: [N]

### Green Criteria
- [ ] Crash-free rate: [XX.X%] (target: >99.5%)
- [ ] Core flow completion: [XX%] (target: >80%)
- [ ] NPS score: [XX] (target: >30)
- [ ] P0 bugs: [0/N] open
- [ ] P1 bugs: [0/N] open
- [ ] Data loss issues: [None/Describe]
- [ ] Privacy compliance: [Pass/Fail]
- [ ] Oldest device performance: [Pass/Fail]

### Yellow Items (Ship but fix in v1.0.1)
- [Item 1]
- [Item 2]

### Red Items (Must fix before launch)
- [Item 1 — or "None"]

### Decision: [GO / NO-GO / CONDITIONAL GO]
### Reasoning: [1-2 sentences]
### Next Steps:
1. [Action item]
2. [Action item]
3. [Action item]
```

### Phase 7: Beta Timeline

#### Recommended 7-Week Schedule

| Week | Phase | Activities | Deliverables |
|------|-------|------------|-------------|
| 1 | Setup | Configure TestFlight groups, write "What to Test" descriptions, prepare feedback form | TestFlight ready, feedback channels set up |
| 2 | Internal Alpha | Invite 10-20 internal testers, fix crash-level bugs daily | Crash-free build, core flows validated |
| 3 | External Wave 1 | Invite 50-200 external testers, monitor crash reports | First external feedback collected |
| 4 | Wave 1 Analysis | Send survey, conduct 5-8 user interviews, categorize feedback | Feedback report, prioritized bug/UX list |
| 5 | External Wave 2 | Fix P0/P1 issues, push new build, invite 200-1,000 testers | Improved build validated at scale |
| 6 | Wave 2 Analysis | Send final survey, conduct 3-5 follow-up interviews | Final feedback report, NPS score |
| 7 | Go/No-Go | Evaluate all data against decision framework, make launch call | Go/No-Go decision document |

**Compressed schedule (4 weeks):** Combine weeks 1-2, skip wave 2, use wave 1 data for go/no-go. Only recommended if the app is simple (< 5 screens) and developer has shipped before.

**Extended schedule (10 weeks):** Add a third external wave for large or complex apps (health apps, financial apps, apps with sync/collaboration). Extra time catches rare bugs and edge cases.

## Output Format

Present the beta testing plan as:

```markdown
# Beta Testing Plan: [App Name]

## TestFlight Configuration

### Internal Group
- **Testers**: [List or count]
- **Focus**: [What they're testing]
- **Duration**: [X days]

### External Group 1: [Name]
- **Size**: [N testers]
- **Cohort**: [Power users / casual / accessibility / domain]
- **What to Test**: [Specific tasks and flows]

### External Group 2: [Name]
- **Size**: [N testers]
- **Cohort**: [...]
- **What to Test**: [...]

## Recruitment Plan
- **Sources**: [Where to find testers]
- **Incentive**: [What to offer]
- **Outreach message**: [Draft]

## Feedback Channels
1. In-app feedback form: [Yes/No, what fields]
2. TestFlight feedback: [What to Test description]
3. Survey: [Questions]
4. User interviews: [How many, who to target]

## Timeline
| Week | Phase | Key Activities |
|------|-------|----------------|
| ... | ... | ... |

## Go/No-Go Criteria
- Crash-free rate target: >99.5%
- Core flow completion target: >80%
- NPS target: >30
- P0/P1 bugs: Must be zero

## Next Steps
1. [First action item]
2. [Second action item]
3. [Third action item]
```

## Integration with Other Skills

This skill fits in the product development pipeline after implementation and before App Store submission:

```
1. product-agent discover    --> Validate the idea
2. prd-generator             --> Define features
3. architecture-spec         --> Technical design
4. implementation-guide      --> Build it
5. test-spec                 --> Automated tests
6. beta-testing (THIS SKILL) --> Validate with real users
7. release-review            --> Pre-submission audit
8. app-store                 --> App Store listing and submission
```

**Inputs from other skills:**
- `test-spec` provides automated test coverage (should be solid before beta)
- `implementation-guide` provides the feature list to test against
- `prd-generator` provides the user stories to validate

**Outputs to other skills:**
- Feedback data informs `release-review` checklist
- NPS and user quotes feed into `app-store` description and marketing
- Go/no-go decision determines if `release-review` proceeds

## Common Mistakes to Avoid

### Inviting too many testers too early
```
Bad:  Invite 500 external testers on day 1
Good: Start with 15 internal testers, fix crashes, THEN go external
```

### Not giving testers direction
```
Bad:  "Please test the app and let me know what you think"
Good: "Please try creating a new project, adding 3 tasks, and marking one
      complete. Report anything confusing or broken."
```

### Ignoring negative feedback
```
Bad:  "That tester just doesn't get it"
Good: "If 3 testers don't get it, my onboarding doesn't get it"
```

### Running beta too short
```
Bad:  3 days of testing, then ship
Good: Minimum 2 weeks external testing with at least 50 testers
```

### Not acting on feedback
```
Bad:  Collect feedback, file it away, ship unchanged
Good: Fix P0/P1 between waves, push new build, re-test
```

---

**A beta test isn't a checkbox — it's your last chance to learn before the whole world sees your app. Treat tester feedback as a gift, even when it hurts.**
