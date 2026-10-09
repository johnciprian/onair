# OnAir

**Always know if they can hear you.** OnAir is a small native macOS menu bar app that shows whether your Zoom
microphone is live, and gives you one hotkey to mute, unmute, and push-to-talk.

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
  - **Hold while live** to mute for a moment; let go to go live again.
- **Optional on-screen cues**, all off by default and switched on from the menu:
  - **Floating badge:** a small ON AIR / OFF AIR badge you can drag anywhere; it snaps to screen edges.
  - **Screen-edge glow:** a thin red rim that slowly pulses around every display while you're live.
  - **Toggle flash:** a volume-HUD-style confirmation in the middle of the screen on every mute change,
    whether you used OnAir or Zoom itself.
- **Instant feedback.** Zoom takes up to ~1.3 s to update after a mute; OnAir shows the new state immediately and
  then confirms it with Zoom.
- **Updates itself.** OnAir checks for new versions once a day and installs them with one click.
- **Native and private.** Built with SwiftUI and AppKit. No analytics, and the only network request is the
  daily update check.

## Requirements

- macOS 26 (Tahoe) or later on a Mac with Apple silicon
- The Zoom desktop app (`zoom.us`), set to **English** (see [Limitations](#limitations))

## Install

### Download

1. Download `OnAir-<version>.zip` from the [latest release](https://github.com/johnciprian/onair/releases/latest)
   and double-click it to unzip.
2. Drag **OnAir** into your **Applications** folder.
3. Open it. macOS will say it can't check OnAir for malware and offer only **Done** or **Move to Trash**: click
   **Done**. (OnAir isn't notarized by Apple; that needs a paid developer membership.)
4. Open **System Settings → Privacy & Security**, scroll down to **Security**, and click **Open Anyway** next to
   "OnAir was blocked". Confirm with your password, then click **Open**.

You only do this once. Later versions arrive through OnAir's own updater and open normally.

### Build from source

You need Xcode 26.

```bash
git clone https://github.com/johnciprian/onair.git
cd onair
scripts/build.sh install
```

This builds `OnAir.app`, copies it to `/Applications`, and launches it.

### First launch

A short setup window walks you through three steps:

1. **Allow Accessibility access.** OnAir reads and presses Zoom's **Meeting → Mute audio / Unmute audio** menu
   item; macOS requires Accessibility permission for that.
2. **Record your hotkey.** Press the combination you want. It must include ⌃ or ⌘, or be one of F13–F20 on its own.
3. **Free the key in Zoom.** If Zoom has a global shortcut on the same keys, Zoom gets the key press first and
   OnAir never sees it. Turn it off in **Zoom → Settings → Keyboard Shortcuts** ("Mute/Unmute My Audio").
   OnAir detects the clash and ticks this step off by itself once it's resolved.

If you use a menu bar manager (Bartender, Ice, Hidden Bar), ⌘-drag OnAir into the always-visible section, because new
menu bar items often start out hidden.

## Usage

Click the menu bar sign to open the menu:

| Item | What it does |
| --- | --- |
| Status row | The current state in words, e.g. "Microphone Live" with "Zoom" underneath. |
| **Mute / Unmute** | Toggles Zoom's mic. Shows your hotkey; disabled outside a meeting. |
| **Show On Screen** | Turns the floating badge, screen-edge glow, and toggle flash on or off. |
| **Settings…** (⌘,) | Change the hotkey, launch at login, and check Accessibility access. |
| **Check for Updates…** | Looks for a new version now. Reads **Update Available…** when a daily check found one. |
| **Quit OnAir** (⌘Q) | Quits. |

## How it works

Zoom has no public API for its mute state, so OnAir reads it the way a person would: from Zoom's own **Meeting**
menu, through the macOS Accessibility API. Zoom labels the item **Mute audio** while you're live and
**Unmute audio** while you're muted (or **Mute/Unmute telephone** when dialled in by phone). OnAir checks it
twice a second, and presses it when you use the hotkey.

The hotkey is registered with the system (`RegisterEventHotKey`), so it works no matter which app is in front.

More detail, including the design decisions behind the code, is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Privacy

OnAir never listens to your microphone. It only reads the title of one menu item in Zoom, and stores nothing but
your preferences (in `UserDefaults`). The badge, glow and flash are excluded from screen sharing and screenshots
where macOS allows it.

Its only network request is the update check: once a day it downloads the list of releases (`appcast.xml`)
from this repository's GitHub releases. Updates are made with [Sparkle](https://sparkle-project.org), and each
one is cryptographically signed, so OnAir only installs updates that come from this project.

## Limitations

- **Zoom in English only.** OnAir finds Zoom's menu items by their English titles. With Zoom set to another
  language it will always show "Not in a Meeting".
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
scripts/release.sh                           # publish a new version (see Releasing)
open --env ONAIR_DEMO=1 build/OnAir.app      # demo mode: cycles states every 3 s, no Zoom needed
swift scripts/make-icon.swift                # re-render the icon's layers
```

- **`Sources/OnAirCore`:** pure logic with no UI or system calls (state parsing, hotkey press timing, optimistic
  display, badge snapping, shortcut validation). Everything here is unit tested.
- **`Sources/OnAir`:** the app: Zoom access, the status item and menu, windows, and overlays.

**Demo mode** runs OnAir as a regular app (with a Dock icon) and leaves its overlays capturable, so screenshot
tools can see everything.

### Signing

Accessibility permission is tied to the app's code signature, so `scripts/build.sh` signs every build with the
same identity, letting the permission survive rebuilds and updates. It uses the first of these it finds:

1. **OnAir Release Signing**, the project's self-signed certificate for releases (only the maintainer has it).
2. Your **Apple Development** certificate (Xcode → Settings → Accounts → Manage Certificates → + → Apple
   Development; it's free).
3. Ad-hoc signing. You'll have to allow Accessibility again after every build.

### Releasing

1. Raise `CFBundleShortVersionString` (e.g. `1.1`) and `CFBundleVersion` (a whole number that only goes up) in
   `Resources/Info.plist`, then commit and push.
2. Run `scripts/release.sh`. It builds and zips the app, signs the zip with the Sparkle update key, writes
   `appcast.xml`, and publishes both as a GitHub release. Installed copies find it on their next check.

The update key lives in the maintainer's login Keychain, with a backup in 1Password. Without it, existing
installs can't be sent updates.

## Roadmap

Open items and decisions are tracked in [docs/OPEN_ITEMS.md](docs/OPEN_ITEMS.md).

## License

Free to use, including at work and in businesses, and free to modify and share. You may not sell OnAir, or a
product or service whose value comes substantially from it. See [LICENSE](LICENSE): the MIT License with the
[Commons Clause](https://commonsclause.com) condition.

Because of that condition, OnAir is *source-available* rather than open source in the OSI sense.

OnAir includes [Sparkle](https://github.com/sparkle-project/Sparkle), which is under the MIT License; its license
ships inside the app as `Sparkle-LICENSE.txt`.
