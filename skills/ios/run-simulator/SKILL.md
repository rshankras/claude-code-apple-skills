---
name: run-simulator
description: Build, install, launch, and screenshot an iOS app in the Simulator to verify a change visually. Use when the user wants to run the app, see a change live, screenshot the running app, or confirm a UI fix actually works (not just that it compiles).
allowed-tools: [Bash, Read, Glob]
last_verified: 2026-11-04
review_by: 2027-06-22
---

# Run in Simulator

Launches the **actual app** in the iOS Simulator and drives it far enough to see
what a user would see. Building proves the code compiles; this skill proves it
*runs*. The payoff is a screenshot of the live app that you read back to confirm
the change — a blank or crashed frame is a failure, not a pass.

> **The rule:** navigate with the accessibility tree; screenshots verify
> outcomes, never locate tap targets. Text is cheap and exact; every image you
> Read stays in context for the rest of the session.

This skill is generic. Nothing about a specific app is hardcoded — the scheme,
simulator, product path, and bundle id are all discovered at runtime.

## When This Skill Activates

Use this skill when the user:
- Asks to "run", "launch", or "open" the app in the simulator
- Wants to *see* a change working, not just compile it
- Asks for a screenshot of the running app
- Wants to verify a UI fix visually before committing or pushing
- Says "does this actually work?" about a view/flow they just changed

Do **not** use it for unit/UI test runs (`xcodebuild test`) — that's a different
goal. This is about meeting the app as a user would.

## Process

Run the steps in order. Each step's output feeds the next, so don't hardcode
values a previous step can discover.

### 1. Discover the project and scheme

Prefer a workspace over a bare project when both exist (CocoaPods/SPM setups
often require the workspace):

```bash
# Find the container
ls *.xcworkspace 2>/dev/null || ls *.xcodeproj 2>/dev/null

# List schemes (use -workspace X.xcworkspace OR -project X.xcodeproj)
xcodebuild -list -project <App>.xcodeproj 2>/dev/null
```

Pick the app scheme (usually matches the app name). If several schemes look
plausible and none clearly matches, **ask the user** which to run rather than
guessing.

### 2. Pick a simulator destination

**Never hardcode a device name** — the named device may not exist on this Mac
(e.g. assuming "iPhone 16" when only "iPhone 17 Pro" is installed fails with
*"Unable to find a device matching the provided destination specifier"*). List
what's actually available and prefer one already booted:

```bash
# Already-booted sim, if any (fastest — skip the boot wait)
xcrun simctl list devices booted

# Otherwise, available iPhones to choose from
xcrun simctl list devices available | grep -i iphone
```

Choose a booted device if present; otherwise pick a recent iPhone from the
available list and remember its name for the destination string.

### 3. Build for the simulator

```bash
xcodebuild build \
  -project <App>.xcodeproj \
  -scheme <Scheme> \
  -destination 'platform=iOS Simulator,name=<SimName>' \
  2>&1 | tail -5
```

- Read the tail for `** BUILD SUCCEEDED **`. Note that `-quiet` *suppresses*
  that success line, so either drop `-quiet` for the confirming run or grep for
  `error:` explicitly.
- On failure, surface the `error:` lines — don't proceed to install a stale or
  nonexistent build.

### 4. Resolve the built `.app` and its bundle id

Don't guess the DerivedData path — ask the build system for it:

```bash
# Product directory + name from the resolved build settings
eval $(xcodebuild -project <App>.xcodeproj -scheme <Scheme> \
  -destination 'platform=iOS Simulator,name=<SimName>' \
  -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ TARGET_BUILD_DIR =/{print "DIR=\""$2"\""} / FULL_PRODUCT_NAME =/{print "NAME=\""$2"\""}')
APP="$DIR/$NAME"
echo "APP: $APP"

# Bundle id straight from the built Info.plist
BID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist")
echo "Bundle id: $BID"
```

### 5. Boot, install, launch

```bash
SIM="<SimName>"
xcrun simctl boot "$SIM" 2>/dev/null   # no-op if already booted
open -a Simulator                      # bring the window forward
xcrun simctl bootstatus "$SIM" -b      # block until fully booted

xcrun simctl install "$SIM" "$APP"
xcrun simctl launch "$SIM" "$BID"
```

`simctl launch` prints `<bundleid>: <pid>` on success. A non-zero exit or an
error string here means the app failed to start — investigate before
screenshotting.

### 6. Navigate to the screen (if the change is behind navigation)

`xcrun simctl` **cannot tap** — `simctl io` has no tap operation (only
`enumerate`, `poll`, `recordVideo`, `screenshot`). Navigation needs a tool that
reads the accessibility tree. Pick the first that works:

**a. Deep link** — if the app has a URL route to the screen, it's the cheapest
path: `xcrun simctl openurl "$SIM" "<scheme>://<path>"`.

**b. AXe** (`command -v axe`; install: `brew install cameroncooke/axe/axe`).
AXe needs the simulator's UDID:

```bash
UDID=$(xcrun simctl list devices booted -j \
  | jq -r --arg n "$SIM" '.devices[][] | select(.name==$n or .udid==$n) | .udid' | head -1)

# Compact element list: type, label, id, centre point. ~2 KB per screen.
# NEVER Read raw `axe describe-ui` output — it is ~280 KB (≈70k tokens) for
# one screen, far more than a screenshot.
UI_FILTER='[.. | objects | select(has("type") and (.AXLabel // .AXUniqueId // "") != ""
  and .type != "Application" and .type != "Group")
  | {t: .type, l: .AXLabel, id: .AXUniqueId, v: .AXValue,
     xy: [(.frame.x + .frame.width/2 | floor), (.frame.y + .frame.height/2 | floor)]}
  | with_entries(select(.value != null))]'
axe describe-ui --udid "$UDID" | jq -c "$UI_FILTER" | jq -c '.[]'
```

Tap the target, most specific first:

```bash
axe tap --id "<AXUniqueId>" --udid "$UDID"                              # 1. accessibilityIdentifier
axe tap --label "<AXLabel>" --element-type Button --wait-timeout 5 --udid "$UDID"  # 2. label (+ type)
axe tap -x <x> -y <y> --udid "$UDID"                                    # 3. the xy from the list above
```

- AXe **refuses to tap** (exit 1, "Multiple (N) accessibility elements
  matched") when a label or id is ambiguous — common in system and nested
  views. Fall back to step 3 with the `xy` from the list: still exact, not
  guessed.
- `--wait-timeout` polls until the element appears — use it right after a
  navigation instead of `sleep`.
- Back buttons usually have `--id BackButton`.
- **After each tap, confirm where you landed by re-listing (text), not by
  screenshot** — check the `Heading` / `Button` labels of the new screen.
- An element you need with **no label and no id** is an accessibility bug
  (VoiceOver can't name it either) — report it, don't work around it.

**c. Neither available** — screenshot the landing screen (step 7) and tell the
user the exact taps to reach the target view.

### 7. Screenshot and verify — as a thumbnail

Screenshot **once**, at the destination, and Read a downscaled copy:

```bash
xcrun simctl io "$SIM" screenshot /tmp/sim-shot.png       # full size, kept on disk
sips -Z 600 /tmp/sim-shot.png --out /tmp/sim-shot-thumb.png >/dev/null
```

Then **Read `/tmp/sim-shot-thumb.png`** (≈276×600 — a fraction of a
full-size frame's tokens) and actually look at it:
- Blank/white frame, a crash dialog, or the launch screen stuck → failure.
- The expected screen → success; describe what confirms the change.

The thumbnail is enough to judge blank / crashed / wrong screen / gross layout.
Read the full-size PNG only when fine detail is the question (text clipping,
alignment, color) — that is `/apple:visual-qa`'s job.

## Output Format

Report, concisely:
1. **What ran** — scheme, simulator name/OS, bundle id.
2. **Build result** — succeeded / failed (with the error tail if failed).
3. **Launch result** — pid on success, or the failure reason.
4. **How you navigated** — deep link / AXe taps (by id, label, or xy) / none.
5. **What the screenshot shows** — the screen reached and whether it confirms
   the change. Give the full-size path so the user can open it.
6. **Anything the user must do** — e.g. taps needed to reach a gated screen,
   or unlabeled controls that blocked navigation.

## Reliability Notes (common failure modes)

- **Wrong device name** → "Unable to find a device matching the destination."
  Always list available sims (step 2) instead of assuming a model number.
- **Stale install** → if behavior looks unchanged, `xcrun simctl uninstall
  "$SIM" "$BID"` then reinstall; or `xcrun simctl shutdown "$SIM" && xcrun
  simctl erase "$SIM"` for a clean slate (destroys sim data — confirm first).
- **Workspace vs project** → if the build complains about missing packages/pods,
  re-run with `-workspace <App>.xcworkspace` instead of `-project`.
- **First boot is slow** → `simctl bootstatus -b` blocks correctly; a fixed
  `sleep` does not and races the install.
- **Launch screen "stuck"** → on a cold sim the app may still be initializing;
  re-screenshot after a short wait before declaring failure.
- **`simctl io … tap` errors** → it doesn't exist; use AXe (step 6b).
- **AXe "Multiple … matched", no tap performed** → the label/id isn't unique;
  tap the `xy` from the filtered list.
- **AXe "No accessibility element matched"** → you're not on the screen you
  think; re-list before retrying. `describe-ui` takes ~1–2 s per call.

## References

- `xcrun simctl help` — full simulator control surface (boot, install, launch,
  io, openurl, spawn).
- AXe — https://github.com/cameroncooke/AXe (`axe --help`, `axe tap --help`);
  verified against AXe 1.8.0 / Xcode 26.3.
- `man xcodebuild` — `build`, `-list`, `-showBuildSettings`, `-destination`.
- Apple: Running your app in Simulator —
  https://developer.apple.com/documentation/xcode/running-your-app-in-the-simulator-or-on-a-device
