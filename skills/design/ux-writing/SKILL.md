---
name: ux-writing
description: Interface copy that works — voice/tone, the PACE framework, alert anatomy, naming features, empty states, error messages, and the small-word edits that measurably improve UX. Distilled from Apple's writing sessions (2017–2026). Use when writing or reviewing any user-facing text — labels, alerts, onboarding, notifications, empty states, paywalls — or naming a feature.
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# UX Writing

Interface text is interface design. This skill covers writing it: the frameworks Apple's
writers use, the anatomy of the hardest components (alerts, errors, empty states, names), and
the mechanical edits that improve any screen's copy in minutes.

## When This Skill Activates

- Writing or reviewing user-facing copy: labels, buttons, alerts, onboarding, notifications
- Naming a new feature, tier, or setting
- Error messages that frustrate, empty states that dead-end, permission prompts that get denied
- Localization prep (copy that survives translation)

## The PACE framework (Writing for Interfaces)

Run every screen's copy through four questions:

- **Purpose** — what must this screen communicate? Headers and buttons should carry the screen
  alone; know what to leave out. Hierarchy in words mirrors hierarchy in layout.
- **Anticipation** — what will the user ask or do next? Write for that ("What comes next?").
- **Context** — where is the user right now (quiet home vs. busy airport, mid-task vs. idle)?
  That decides how much to say.
- **Empathy** — write for a person having a problem, not for the system reporting one.

## Voice vs. tone

- **Voice is constant** — derive it from what the app does and who it's for. Exercise: describe
  the app as a person, cluster the personality adjectives, keep 2–3 as your voice attributes.
- **Tone modulates by moment** — turn up clarity and directness for important information
  (health alerts: specific numbers, no softening); allow warmth in celebrations — sparingly.
- The test that recurs in every Apple session: **read it aloud**. Does it sound like the best
  version of your app talking?
- ❌ Jargon ("it can make people feel left out"); ❌ personality at the cost of usefulness.

## The four small edits (biggest impact per minute)

1. **Cut filler**: "easily," "quickly," "simply," "just" — ✅ "Enter your license plate to pay
   for parking" ❌ "Simply enter your license plate number to quickly pay for parking."
2. **Kill repetition** — merge redundant sentences: ❌ "We're running late. Your driver won't
   make it on time. They'll be there in 10 minutes." ✅ "Delivery delayed 10 minutes."
3. **Lead with the why** — benefit before action: ✅ "To get reservation updates, enter your
   phone number." Notifications too: ✅ "Keep your streak going by solving today's crossword."
4. **Keep a word list** — three columns: approved term · alternatives to avoid · definition
   (e.g. "alias — not handle/username/title — the player's in-game name, shown to others").
   Reuse identical button labels ("Next") everywhere; consistency builds trust.

## Alert anatomy (Writing Great Alerts)

First: should this be an alert at all? Alerts interrupt by design — reserve them for things
the user must know *now*.

- **Title**: the main point, one sentence or less.
- **Message**: only if needed — the cause or the reason for the request.
- **Buttons**: specific verbs for the action taken — never Yes/No/OK when a verb exists.
- **The scannability test**: title + buttons alone must convey the situation.
- A good alert answers: **What happened? Why am I seeing this? How do I proceed?**
- ❌ Interjections in errors ("Oops!", "Uh-oh") — they signal you're not taking it seriously.
- ❌ Vague hedging ("You may need to…") — name the file, name the fix.
- If the fix lives elsewhere (Settings, another screen), the button takes them there — "do not
  leave this job to the Back button."

## Naming features (Craft Clear Names, WWDC26)

Judge every candidate on three criteria: it **belongs** (fits the app and its location), it
**sets expectations** (readers predict what they'll get), it **works everywhere** (languages,
markets, platforms).

- Process: **Think / Feel / Do** — what should the audience think, feel, and do? Group the
  answers into themes; name from the themes; test candidates in natural sentences ("just
  search for ___").
- ✅ Verbs for features users *perform*: "Enhance Dialogue," not "Vocal Isolation."
- ✅ Industry-standard words in high-stakes domains: "Balance," not "Spending Power."
- ✅ Clarity over cleverness in tiers: "Basic Access / All Access," not "Lightweight/Heavyweight."
- ✅ Compounds are fine when the parts self-explain ("AutoMix"); emotional names win where the
  moment is emotional ("Memories").
- ❌ Implementation jargon — describe the outcome, not the mechanism.

## Empty states, permissions, localization

- **Empty states** never dead-end: say what will appear here and how to make it appear —
  ideally with example input (the blank-page rule: never leave an empty state without a next action).
- **Permission prompts**: explain value first, ask at the contextually right moment — never at
  first launch (mechanics in `generators/permission-priming`).
- **Localization**: plain language survives translation; idioms and humor don't. Words grow in
  translation — leave layout room; every element needs accessibility text conveying intention.

## Output Format

Copy review table:

```
Location | Current | Problem (PACE / filler / vague button / jargon) | Rewrite
```

ordered by frequency-of-exposure (navigation labels before deep-screen prose).

## References

- https://developer.apple.com/videos/play/wwdc2022/10037/ (Writing for interfaces)
- https://developer.apple.com/videos/play/wwdc2024/10140/ (Add personality through UX writing)
- https://developer.apple.com/videos/play/wwdc2025/404/ (Small writing changes)
- https://developer.apple.com/videos/play/wwdc2026/290/ (Craft clear names)
- https://developer.apple.com/videos/play/wwdc2017/813/ (Writing Great Alerts)
- Related skills: `generators/permission-priming`, `generators/push-notifications` (notification copy), `app-store/app-description-writer` (store copy)
