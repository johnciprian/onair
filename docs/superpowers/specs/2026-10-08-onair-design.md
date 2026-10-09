# OnAir — Design Spec

**Date:** 2026-10-08
**Status:** Draft for review

## 1. Purpose

A native macOS menu bar app that shows, at a glance, whether John's Zoom microphone is live, and owns the hotkey that mutes/unmutes it. It replaces the SwiftBar script `~/Development/scripts/swiftBar/zoom-avs-status.1s.scpt`.

**Success looks like:** one glance at the screen answers "can they hear me?" with no reading required; the hotkey feels instant; the app looks and moves like something Apple would ship.

### What the user asked for
- Graphical ON AIR / OFF AIR status in color, not text.
- Displays: menu bar pill, floating badge, screen-edge glow, toggle flash. All but the menu bar are optional, off by default, toggled from the menu.
- The app owns the hotkey: tap toggles, hold is momentary.
- Hotkey is recorded by pressing it, not hard-coded.
- Zoom only for v1.
- "Drop dead gorgeous", award-worthy visual quality.

### Assumptions (not stated by the user)
- English Zoom client (state is read from English menu titles).
- Single user, personal install; no App Store distribution.
- Target macOS 26+ so the UI can use Liquid Glass natively (machine runs macOS 27).

### Out of scope for v1
Teams/Meet/Slack support, camera status, sounds, "talking while muted" detection, smart lights.

## 2. Behavior

### States
| State | Meaning |
|---|---|
| `notRunning` | Zoom is not open |
| `noMeeting` | Zoom open, Meeting menu has no mute/unmute item (not in a call, or in a call with no audio joined) |
| `muted` | Meeting menu shows **Unmute audio** or **Unmute telephone** |
| `live` | Meeting menu shows **Mute audio** or **Mute telephone** |
| `noPermission` | Accessibility access not granted (app-level, overrides the above) |

The displayed state always comes from reading Zoom, never from assuming the result of a toggle.

### Hotkey
- **Key down:** if in a meeting, toggle Zoom immediately.
- **Key up:** if held ≥ 300 ms, toggle back.
- Result: tap = toggle; hold while muted = push-to-talk; hold while live = cough button (momentary mute).
- Outside a meeting the hotkey does nothing.
- The user must remove the same combo from Zoom's global shortcuts (noted on first run, see §5).

### Polling
- One 0.5 s timer (0.1 s tolerance). While Zoom is closed each tick is only a running-apps lookup — no Accessibility calls.
- After each hotkey toggle, re-read immediately and keep re-reading every 50 ms (up to 6 tries) until Zoom's menu reflects the change; the toggle flash shows the state that was read.
- Accessibility calls to Zoom time out after 0.25 s so a hung Zoom can't freeze OnAir.

## 3. Architecture

Swift + SwiftUI app with AppKit where SwiftUI can't do it (status item, overlay windows). `LSUIElement` (no Dock icon). No third-party dependencies.

| Unit | Responsibility | Depends on |
|---|---|---|
| `ZoomMenu` | Pure function: `[menu item title] → state`, and which item to press. | nothing |
| `PressLogic` | Pure function: press/release timestamps → `toggleBack: Bool`. | nothing |
| `ZoomController` | Reads Zoom's Meeting menu titles via `AXUIElement`; `toggle()` performs `AXPress` on the mute/unmute item. Only file that knows about Zoom. | `ZoomMenu` |
| `StatusMonitor` | `@Observable` current state; owns the 0.5 s timer and the post-toggle re-read. | `ZoomController` |
| `Hotkey` | Carbon `RegisterEventHotKey`; reports pressed/released; reports registration failure. | `PressLogic` |
| `HotkeyRecorder` | Small window that captures the next key combo (local `NSEvent` monitor) and saves it. | `Preferences` |
| `Preferences` | `UserDefaults`-backed: `showBadge`, `showGlow`, `showFlash`, hotkey (keyCode + modifiers), badge position. | nothing |
| `MenuBarController` | `NSStatusItem` with SwiftUI-rendered pill + `NSMenu` (see §4.1). | `StatusMonitor`, `Preferences` |
| `BadgeWindow`, `GlowWindow`, `FlashWindow` | Overlay `NSPanel`s hosting SwiftUI views. | `StatusMonitor`, `Preferences` |
| `LoginItem` | `SMAppService.mainApp` register/unregister. | nothing |

Overlay panels: borderless, non-activating, `.statusBar` level, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`. Glow and flash ignore mouse events; badge is draggable and saves its position. All overlays set `sharingType = .none` so they are excluded from screen sharing where macOS honors it.

## 4. Visual Design

**Concept:** a broadcast studio's lit "ON AIR" sign, rebuilt in Liquid Glass. Off air, it's a quiet piece of smoked glass. On air, the glass lights from inside with warm signal red. Every surface uses the same three ingredients: glass, light, type.

### Design tokens
- **Signal red (live):** a warm red slightly richer than `systemRed`, e.g. `#FF3B30` → `#E0251B` vertical gradient, with a bloom (`shadow` in the same hue, radius ~12, opacity ~0.6).
- **Off air:** smoked glass; text in `.secondary`; tally dot unlit (dark red ring, no bloom).
- **Type:** SF Pro, `.fontWidth(.expanded)`, `.black` weight, all caps, tracking +0.12 em. This is the "sign" voice; used for ON AIR / OFF AIR only. All other UI text is the system default.
- **Tally dot:** small circle left of "ON AIR". Live: lit with bloom and a slow breathing glow (2.4 s cycle, opacity 0.75 → 1). Off: unlit ring.
- **Motion:** spring animations (`.snappy` for state changes, `.bouncy` for the flash entrance). SF Symbol changes use `.contentTransition(.symbolEffect(.replace))`.
- **Accessibility:** Reduce Motion → no breathing, crossfades instead of springs. Reduce Transparency → solid fills instead of glass. Increase Contrast → 1 pt border on pills. Colors are never the only signal: text always says ON AIR / OFF AIR. VoiceOver labels on the status item and badge.
- Correct in both light and dark menu bars.

### 4.1 Menu bar pill
- **Live:** filled red capsule, ~18 pt tall, top-edge inner highlight (1 pt white @ 25%) so it reads as lit glass; white "● ON AIR" in the sign font at menu bar size.
- **Muted:** hairline capsule outline in label color, "OFF AIR" in secondary color, unlit dot.
- **No meeting / Zoom closed:** template `mic` SF Symbol, dimmed.
- **No permission:** `exclamationmark.triangle.fill` in system yellow.
- Each state is a plain image in the standard status-item button (template image for the monochrome states, so macOS tints it for light/dark menu bars); macOS sizes the item. No animation in the menu bar.

**Menu:**
```
● ON AIR                     (status, disabled)
─────────────
  Floating Badge             (checkmark toggle)
  Screen-Edge Glow           (checkmark toggle)
  Toggle Flash               (checkmark toggle)
─────────────
  Hotkey: ⌃⌥M  Change…
  Launch at Login            (checkmark toggle)
  Grant Accessibility Access…  (only when missing)
─────────────
  Quit OnAir
```
No hotkey recorded yet → "Hotkey: Not Set — Record…". Registration failure → "Hotkey Unavailable — Choose Another…".

### 4.2 Floating badge (optional, off by default)
- Visible only in `muted` and `live`.
- Liquid Glass capsule (`.glassEffect(.regular, in: .capsule)`), ~160 × 44 pt.
- **Live:** glass tinted signal red (`.glassEffect(.regular.tint(signalRed))`), letters lit white with a red bloom, breathing tally dot.
- **Muted:** clear smoked glass, "OFF AIR" in secondary, unlit dot.
- Appears/disappears with scale 0.9 → 1 + fade. Live ↔ muted crossfades the tint.
- Draggable anywhere; snaps gently to the nearest screen edge margin (16 pt) on release; position saved.

### 4.3 Screen-edge glow (optional, off by default)
- Visible only in `live`, on every display.
- A crisp 2 pt signal-red line hugging the display edge, plus a soft inner falloff (~48 pt gradient to clear).
- Follows the display's rounded corners: built-in displays with a notch (`safeAreaInsets.top > 0`) use a 10 pt corner radius; all other displays use square corners. (macOS has no public API for display corner radius.)
- Fades in over 250 ms, out over 400 ms. No pulsing.
- Never intercepts clicks.

### 4.4 Toggle flash (optional, off by default)
- On every hotkey toggle, a 200 × 200 pt Liquid Glass squircle appears centered on the display under the mouse pointer.
- Contents: large SF Symbol (`mic.fill` live / `mic.slash.fill` muted) with a `.bounce` symbol effect, and ON AIR / OFF AIR in the sign font underneath. Live variant uses the red tint.
- Entrance: scale 0.85 → 1 with `.bouncy`; holds 0.6 s; exits with fade + scale to 0.95.
- A new toggle while visible updates it in place (symbol `.replace` transition) and restarts the timer.

### 4.5 Hotkey recorder window
- Small standard window (~360 × 180 pt) with a hidden title bar, centered, headed "Set Hotkey". macOS draws its corners, shadow and active/inactive look (chosen over custom borderless glass panels, which drew a rectangular box while active).
- Shows the current combo as glass keycaps (one cap per modifier and key, e.g. ⌃ ⌥ M).
- "Press your shortcut…" placeholder; caps animate in as keys are pressed; Esc cancels; Save / Cancel buttons.
- Requires ⌃ or ⌘ (bare keys, ⇧+key and ⌥+key would hijack typing) unless the key is F13–F20.

### 4.6 App icon
A macOS-style squircle: a dark smoked-glass tile holding a lit red "ON AIR" sign plate with the sign typography and a soft bloom. Built in Icon Composer (layers: background, sign plate, lit text) so macOS can render its light/dark/tinted variants.

### 4.7 First run
A single onboarding window (same standard hidden-title-bar style as the recorder) with three steps, each with a checkmark when done:
1. Grant Accessibility access (button opens the System Settings pane; updates live once granted).
2. Record your hotkey.
3. "Remove this shortcut from Zoom → Settings → Keyboard Shortcuts so it isn't triggered twice." (instruction only)

## 5. Error Handling
- **No Accessibility permission:** state `noPermission`; menu shows "Grant Accessibility Access…"; the app re-checks `AXIsProcessTrusted()` every poll tick and recovers on its own.
- **Hotkey registration fails** (combo taken): menu row changes as in §4.1; recorder opens on click.
- **Zoom menu not found / AX error:** treated as `noMeeting`; no alerts.
- **Toggle didn't take effect:** next read shows the true state; no special handling.

## 6. Testing
- **Unit tests (XCTest):** `ZoomState` for every title combination (including telephone variants and empty menu); `PressLogic` for tap (< 300 ms), hold (≥ 300 ms) and the boundary.
- **Manual checklist** against a real Zoom test meeting (zoom.us/test): tap toggle; push-to-talk; cough button; hotkey with Zoom in background; Zoom quit mid-call; revoke and re-grant permission; each optional display on/off; two displays; full-screen app; light and dark mode; Reduce Motion and Reduce Transparency.

## 7. Build & Install
- Swift Package (`OnAirCore` library + `OnAir` executable + tests), deployment target macOS 26. `scripts/build.sh` builds release, assembles `OnAir.app` (Info.plist with `LSUIElement`), compiles the Icon Composer icon with `actool`, and code-signs. Chosen over an Xcode project so everything builds from the command line without a hand-maintained `.pbxproj`.
- `ONAIR_DEMO=1` cycles noMeeting → muted → live every 3 s so displays can be checked without a Zoom call.
- **Signing:** this Mac currently has no code-signing identity. Accessibility permission is tied to the app's signature, so with ad-hoc signing macOS forgets the permission after every rebuild. Fix: add an Apple ID in Xcode → Settings → Accounts (free personal team) to get an Apple Development certificate. Until then, builds are ad-hoc signed and permission must be re-granted after each rebuild.
- Installs to `/Applications/OnAir.app`.
