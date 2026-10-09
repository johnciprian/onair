# OnAir

A menu bar light that tells you, at a glance, whether your Zoom mic is live — and the hotkey that flips it.

- **Menu bar:** red **● ON AIR** when live, grey **OFF AIR** when muted, a dim mic outside meetings.
- **Hotkey:** tap to mute/unmute. Hold while muted to talk; hold while live to cough.
- **Optional (menu):** floating glass badge, red screen-edge glow while live, center-screen flash on every toggle.

## Install

```bash
scripts/build.sh install
```

First launch walks you through:
1. Allowing Accessibility access (OnAir reads and presses Zoom's Meeting → Mute/Unmute menu item).
2. Recording your hotkey.
3. Turning off the same shortcut in Zoom → Settings → Keyboard Shortcuts (“Enable Global Shortcut” for Mute/Unmute My Audio).

Then switch off the old SwiftBar `zoom-avs-status` plugin. If you use a menu bar manager (Hidden Bar, Bartender, Ice),
⌘-drag OnAir into the always-visible section — new items start out hidden.

## Signing

Accessibility permission is tied to the app's code signature. `scripts/build.sh` uses your Apple Development
certificate if one exists (Xcode → Settings → Accounts → Manage Certificates → + Apple Development — it's free).
Without one, builds are ad-hoc signed and you'll need to re-grant Accessibility after every rebuild.

## Development

```bash
swift test                                         # unit tests (OnAirCore)
scripts/build.sh                                   # build/OnAir.app
open --env ONAIR_DEMO=1 build/OnAir.app            # cycle states every 3 s without Zoom
swift scripts/make-icon.swift                      # re-render the icon layers
```

Demo mode runs as a regular app (Dock icon) with overlays left capturable, so screenshot tools can see everything.
