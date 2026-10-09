# OnAir

**Always know if they can hear you.** OnAir is a small native macOS menu bar app that shows whether your Zoom
microphone is live — and gives you one hotkey to mute, unmute, push-to-talk, and cough.

<p align="center">
  <img src="docs/images/menu-bar-live.png" alt="The menu bar sign reading ON AIR in red" height="44">
  &nbsp;&nbsp;
  <img src="docs/images/menu-bar-muted.png" alt="The menu bar sign reading OFF AIR in outline" height="44">
</p>

## Features

- **Menu bar sign.** A red **● ON AIR** sign while your mic is live, an outlined **OFF AIR** sign while you're
  muted, and a plain mic icon when you're not in a meeting.
- **One hotkey, three gestures.**
  - **Tap** to mute or unmute.
  - **Hold while muted** to talk (push-to-talk); let go to mute again.
  - **Hold while live** to cough (momentary mute); let go to go live again.
- **Optional on-screen cues**, all off by default and switched on from the menu:
  - **Floating badge** — a small ON AIR / OFF AIR badge you can drag anywhere; it snaps to screen edges.
  - **Screen-edge glow** — a thin red rim that slowly pulses around every display while you're live.
  - **Toggle flash** — a volume-HUD-style confirmation in the middle of the screen on every mute change,
    whether you used OnAir or Zoom itself.
- **Instant feedback.** Zoom takes up to ~1.3 s to update after a mute; OnAir shows the new state immediately and
  then confirms it with Zoom.
- **Native and private.** Built with SwiftUI and AppKit, no dependencies, no network access, no analytics.

## Requirements

- macOS 26 (Tahoe) or later, Apple silicon or Intel
- The Zoom desktop app (`zoom.us`), set to **English** — see [Limitations](#limitations)

## Install

### Build from source

You need Xcode 26 (or its command line tools).

```bash
git clone https://github.com/johnciprian/onair.git
cd onair
scripts/build.sh install
```

This builds a universal `OnAir.app`, copies it to `/Applications`, and launches it.

### First launch

A short setup window walks you through three steps:

1. **Allow Accessibility access.** OnAir reads and presses Zoom's **Meeting → Mute audio / Unmute audio** menu
   item; macOS requires Accessibility permission for that.
2. **Record your hotkey.** Press the combination you want. It must include ⌃ or ⌘, or be one of F13–F20 on its own.
3. **Free the key in Zoom.** If Zoom has a global shortcut on the same keys, Zoom gets the key press first and
   OnAir never sees it. Turn it off in **Zoom → Settings → Keyboard Shortcuts** ("Mute/Unmute My Audio").
   OnAir detects the clash and ticks this step off by itself once it's resolved.

If you use a menu bar manager (Bartender, Ice, Hidden Bar), ⌘-drag OnAir into the always-visible section — new
menu bar items often start out hidden.

## Usage

Click the menu bar sign to open the menu:

| Item | What it does |
| --- | --- |
| Status row | The current state in words, e.g. "Microphone Live — Zoom". |
| **Mute / Unmute** | Toggles Zoom's mic. Shows your hotkey; disabled outside a meeting. |
| **Show On Screen** | Turns the floating badge, screen-edge glow, and toggle flash on or off. |
| **Settings…** (⌘,) | Change the hotkey, launch at login, and check Accessibility access. |
| **Quit OnAir** (⌘Q) | Quits. |

## How it works

Zoom has no public API for its mute state, so OnAir reads it the way a person would: from Zoom's own **Meeting**
menu, through the macOS Accessibility API. Zoom labels the item **Mute audio** while you're live and
**Unmute audio** while you're muted (or **Mute/Unmute telephone** when dialled in by phone). OnAir checks it
twice a second, and presses it when you use the hotkey.

The hotkey is registered with the system (`RegisterEventHotKey`), so it works no matter which app is in front.

More detail, including the design decisions behind the code, is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Privacy

OnAir never listens to your microphone. It only reads the title of one menu item in Zoom. It makes no network
connections and stores nothing but your preferences (in `UserDefaults`). The badge, glow and flash are excluded
from screen sharing and screenshots where macOS allows it.

## Limitations

- **Zoom in English only.** OnAir finds Zoom's menu items by their English titles. With Zoom set to another
  language it will always show "Not in a Meeting". Support for other languages is planned.
- **Zoom desktop only.** Zoom in a web browser, Microsoft Teams, Google Meet, and other apps aren't supported.
- **Not on the Mac App Store.** App Store apps must run in a sandbox, which doesn't allow controlling another app
  through Accessibility.

## Troubleshooting

**Accessibility is switched on for OnAir, but it still asks for access.** macOS ties the permission to the app's
code signature, so a rebuilt or re-signed copy can be treated as a different app. Reset it and allow it again:

```bash
tccutil reset Accessibility com.johnciprian.OnAir
```

**The hotkey does nothing.** Open **Settings…**. A red note under the shortcut tells you if another app or Zoom
already uses the same keys.

**The menu bar sign doesn't appear.** It's probably hidden by a menu bar manager, or behind the notch on a
crowded menu bar. ⌘-drag it into view.

## Development

```bash
swift test                                   # unit tests for OnAirCore
scripts/build.sh                             # build build/OnAir.app
scripts/build.sh install                     # build, copy to /Applications, relaunch
scripts/build.sh release                     # build and zip build/OnAir-<version>.zip
open --env ONAIR_DEMO=1 build/OnAir.app      # demo mode: cycles states every 3 s, no Zoom needed
swift scripts/make-icon.swift                # re-render the icon's layers
```

- **`Sources/OnAirCore`** — pure logic with no UI or system calls (state parsing, hotkey press timing, optimistic
  display, badge snapping, shortcut validation). Everything here is unit tested.
- **`Sources/OnAir`** — the app: Zoom access, the status item and menu, windows, and overlays.

**Demo mode** runs OnAir as a regular app (with a Dock icon) and leaves its overlays capturable, so screenshot
tools can see everything.

### Signing

Accessibility permission is tied to the code signature. `scripts/build.sh` signs with your **Apple Development**
certificate if you have one (Xcode → Settings → Accounts → Manage Certificates → + → Apple Development; it's
free), so the permission survives rebuilds. Without one, builds are ad-hoc signed and you'll have to allow
Accessibility again after every build.

### Sharing a build

`scripts/build.sh release` produces a zip, but a build signed with a development certificate is blocked by
Gatekeeper on other Macs (they can still open it via **System Settings → Privacy & Security → Open Anyway**).
To ship a build that opens normally, sign it with a **Developer ID Application** certificate (Apple Developer
Program) and notarize it with `xcrun notarytool`. The build already uses the hardened runtime that
notarization requires.
