---
name: flow-walkthrough
description: Verify UI *workflow* correctness that a task list, code review, and static screenshots miss. Drives end-to-end user flows in the Simulator via XCUITest with per-step screenshots, statically audits the navigation graph for dead-ends and missing edit paths, and emits a human discoverability checklist. Use after building any phase/slice that adds or changes UI, or when a user reports "I could only figure out the flow by running it."
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# Flow Walkthrough Skill

Task lists, compilers, and code review verify that *screens exist and compile*. They are structurally blind to whether the **flow between screens actually works for a human with a goal** — the transitions, the return paths, the dead-ends, the discoverability. This skill closes that gap.

## Why this exists (the three failure classes)

Real UX bugs fail at three different layers, and **no single mechanism catches all three** — so this skill uses three:

| Failure class | Example | Caught by |
|---|---|---|
| **Dead-end / missing path** | A saved record can only be *viewed*, never reopened to edit; `Done` calls `popToRoot()` and orphans an in-progress entity | **Layer 1** — static nav-graph audit (no build) |
| **Reachability regression** | "Run round" no longer reaches the capture screen after a refactor; a `Done` lands on the wrong screen | **Layer 2** — automated flow driving (XCUITest) |
| **Discoverability** | "How do I even select a contestant?" — the only affordance is a bare row tap | **Layer 3** — human checklist (a UI test taps the row and *passes*) |

> The trap: a UI test happily taps a hidden control and reports PASS. Automation proves a path *works*; only a human judges whether it is *findable*. That residue is why Layer 3 is mandatory, not optional.

## Input: the `<flows>` from PLAN.md

`/apple:plan` emits a `<flows>` block — end-to-end journeys, each a testable script. If `PLAN.md` has no `<flows>`, derive them from the phase's `<mvp-features>`/views and **write them back into PLAN.md first** (a flow that isn't written down can't be checked). A good flow names, for every persisted entity created: the step that **reopens it editable**, and the single **least-discoverable action**.

## The method

### Layer 1 — Static navigation-graph audit (no build required)

Grep the navigation surface and reason over it. Do this first; it's free and catches the highest-severity class.

1. **Build the graph.** Find entry points and edges:
   - `Grep`: `NavigationStack`, `navigationDestination`, `NavigationLink`, `\.sheet`, `\.fullScreenCover`, `router.push`, `enum Route`, `dismiss()`, `popToRoot`, `@Query`.
2. **Assert reachability & return paths.** For every screen: how do you get in, and does every `Done`/`Back`/`dismiss` land somewhere intentional? Flag any `popToRoot()` that discards an in-progress or just-saved entity.
3. **CRUD-completeness.** For every `@Model` with a **Create** path, is there a **Read** *and* an **Update/reopen** path from the persistence surface (a list/history)? A list that only opens a read-only detail is a dead-end for editing — flag it.
4. **Entry-point sanity.** Does "New X" always create a *fresh* entity with no way back to the previous one except an incomplete list? Flag create-only loops.
5. **Nested navigation containers.** For every `NavigationLink`/`navigationDestination` destination, check whether the destination view declares its own `NavigationView`/`NavigationStack` — a pushed view must never wrap one. This renders a second nav bar under the parent's and its leading bar items displace the back button. It's a cross-file bug: each file looks correct alone (and previews fine in isolation), so single-file review never catches it — only this pairwise check does.

Output each finding as `DEAD-END` / `NO-EDIT-PATH` / `ORPHANS-ENTITY` / `NESTED-NAV` with the file:line and the missing arrow.

### Layer 2 — Automated flow driving (XCUITest + per-step screenshots)

Turn each `<flow>` into a UI test that taps through it and screenshots every step, so the agent can *see* the transitions and assert the destinations.

1. **Ensure a UITest target exists.** If none, add one (xcodegen: a `type: bundle.ui-testing` target; or `xcodebuild`). Keep the generated tests — they become the Phase 5 regression suite.
2. **Generate one test method per flow** from `<steps>`. After each step, attach a screenshot:
   ```swift
   func snap(_ name: String) {
       let s = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
       s.name = name; s.lifetime = .keepAlways; add(s)
   }
   ```
   Launch with any needed args (e.g. a `-uiTestSeed` launch argument that seeds SwiftData and, in DEBUG, flips entitlement flags so gated flows are reachable without a real purchase). Assert the **destination** of each step (`XCTAssert(app.staticTexts["Results"].waitForExistence(timeout: 2))`), especially after `Done`/`Back` — that is what catches wrong-destination bugs.
3. **Run and extract:**
   ```bash
   xcodebuild test -project <App>.xcodeproj -scheme <App> \
     -destination 'platform=iOS Simulator,name=<device>' \
     -resultBundlePath .planning/walkthrough/<flowId>.xcresult
   # export per-step screenshots for the agent to read:
   xcrun xcresulttool export attachments \
     --path .planning/walkthrough/<flowId>.xcresult \
     --output-path .planning/walkthrough/<flowId>/   # adapt flag to installed Xcode
   ```
   (The `xcresulttool` attachment-export subcommand name shifts across Xcode versions — check `xcrun xcresulttool --help` and adapt.)
4. **Read the screenshots** in order → a "filmstrip." Confirm each step lands where the flow says it should. A failed assertion or a wrong screen = a flow bug with visual proof.
5. **One unseeded pass (fresh-install reality).** Every seeded run hides zero states — run at least one pass with NO seed argument that visits each top-level screen and screenshots it, in light mode. Assert each zero state renders something intentional (an empty-state view, a hint), not a blank expanse. A user's first launch is unseeded; if every automated capture is seeded, blank first-run screens ship unseen.

### Layer 3 — Human discoverability pass (the irreducible residue)

For each flow, emit a short script the human runs and rates — this is the only thing that catches "I couldn't find how to do X":

```
Flow F1 — Run a contest (as a host)
  1. Tap "Start a Contest"        → were you sure what to tap? (1–5)
  2. Add two contestants          → was adding the *second* obvious? (1–5)
  3. Run each contestant's round  → did you know rows were tappable? (1–5)
  4. Done on results              → did you land back where you expected? (Y/N)
  Where did you hesitate? ______
```

Keep it to the 2–4 flows that matter; ask for a hesitation note, not just scores — the note is where the real bug hides.

## Output: `.planning/WALKTHROUGH.md`

```markdown
# Flow Walkthrough — Phase [N]

## Layer 1 — Navigation graph (static)
- 🔴 NO-EDIT-PATH: ContestHistoryView:19 opens read-only ResultsView; a saved Contest can't be reopened to edit. → route to editable setup.
- 🔴 ORPHANS-ENTITY: ResultsView "Done" calls router.popToRoot() → dumps user home, loses the contest. → dismiss() one level.

## Layer 2 — Driven flows (filmstrips in ./walkthrough/)
| Flow | Result | Note |
|------|--------|------|
| F1 create→run→results→reopen | ❌ DEAD-END at step 6 | reopen lands on read-only results |
| F2 add second contestant | ✅ reaches capture | |

## Layer 3 — Human discoverability checklist
[the per-flow scripts above, for the user to fill in]

## Verdict
[N] dead-ends (fix before phase-complete), [N] reachability failures, discoverability pending human pass.
```

Store screenshots under `.planning/walkthrough/<flowId>/`. Fix all Layer-1 dead-ends and Layer-2 failures before the phase is marked complete (same gate discipline as visual-qa).

## Honest limits
- **Tests can't judge feel or findability.** A green Layer-2 run with an unrated Layer-3 checklist is *not* a pass.
- **Seeding is required for gated/late-state flows.** Provide a DEBUG `-uiTestSeed` path (insert sample models, set entitlement flags) so reopen/edit/results flows are reachable without manually rebuilding state each run. Remove or guard it behind the launch arg so it never affects release.
- **Discoverability findings are design changes,** not bugs to "fix in code" blindly — surface them, let the human decide.

## Cadence & integration
- **Run per flow-slice, not per-phase.** Right after you build the create→edit→results loop, walk *that* loop — don't wait for the whole phase. Bugs are cheapest the minute they're introduced.
- **Complements, doesn't replace, `visual-qa`** (which is static/code-level: colors, touch targets, view states). This skill is about *flow*, that one is about *screens*.
- **Feeds Phase 5.** The generated XCUITests are kept as the regression suite; hand them to `testing/tdd-feature`/`test-spec` rather than re-writing.
- **Pairs with a nav-graph review lens.** If `/apple:review` gains a flow/dead-end agent, Layer 1 can run there too; this skill is the runnable, screenshot-producing counterpart.
```
