# Architecture

OnAir is a Swift package with two targets and one third-party dependency, [Sparkle](https://sparkle-project.org)
for updates:

- **`OnAirCore`** (library): pure logic, with no AppKit, no Accessibility, no timers. Fully unit tested in
  `Tests/OnAirCoreTests`.
- **`OnAir`** (executable): the app. It talks to Zoom and the system, and draws everything.

`scripts/build.sh` wraps the executable in an `.app` bundle (Info.plist, icon compiled with `actool`, Sparkle in
`Contents/Frameworks`), signs it, and optionally installs or zips it. `scripts/release.sh` publishes a version.

## The state

Everything starts from one value, `MicState`:

| State | Meaning |
| --- | --- |
| `notRunning` | Zoom isn't open. |
| `noMeeting` | Zoom is open, but its Meeting menu has no mute item (not in a call, or audio not joined). |
| `muted` | The Meeting menu shows **Unmute audio** or **Unmute telephone**. |
| `live` | The Meeting menu shows **Mute audio** or **Mute telephone**. |
| `noPermission` | OnAir hasn't been allowed Accessibility access. |

`StatusMonitor` owns the current state and is the single source of truth: every display reads
`monitor.state`, and `AppModel` re-renders when it calls `onChange(old, new)`.

## Data flow

```
                 every 0.5 s
ZoomController ───────────────► StatusMonitor ──onChange──► AppModel.render()
 (Accessibility)   reading        │ StickyState                ├─ MenuBarController (status item + menu)
      ▲                           │ OptimisticState            ├─ BadgeWindow
      │ AXPress                   ▼                            ├─ GlowWindows
      │                       state                            └─ FlashWindow (on muted ↔ live)
AppModel.setZoom(muted:) ◄── Hotkey (Carbon) ◄── PressLogic (tap vs hold)
                         ◄── menu "Mute / Unmute"
```

### Reading Zoom: `Zoom/ZoomController.swift`

The only file that knows about Zoom. Zoom has no API for its mute state, so OnAir reads the title of the
mute item in Zoom's **Meeting** menu through the Accessibility API, and presses that item to change it.
`OnAirCore/ZoomMenu.swift` turns the menu's titles into a `MicState` and picks the item to press.

- While Zoom isn't running, a poll is only a running-apps lookup, with no Accessibility calls.
- Accessibility calls time out after 0.25 s, so a hung Zoom can't freeze OnAir.
- `readState()` returns `nil` when Zoom couldn't be read; see `StickyState` below.

### Smoothing the readings: `OnAirCore`

- **`StickyState`** keeps the last good state through up to four failed reads in a row. An Accessibility call
  to Zoom occasionally fails or times out; without this one bad read would flicker the sign to "Not in a
  Meeting".
- **`OptimisticState`** makes the hotkey feel instant. Zoom's menu takes 0.2–1.3 s (measured) to reflect a
  press, so after a press that Zoom accepts, OnAir shows the requested state right away and ignores the stale
  readings. If Zoom hasn't confirmed within 2.5 s, OnAir shows whatever Zoom reports, so a press that silently
  failed can't leave the display wrong.

### The hotkey: `Hotkey/`, `OnAirCore/PressLogic.swift`, `OnAirCore/KeyCombo.swift`

- `Hotkey` registers the combo with Carbon's `RegisterEventHotKey`, which delivers both press and release
  system-wide without needing Input Monitoring permission.
- `PressLogic` decides what a press means: a press toggles Zoom; a release after ≥ 0.3 s puts Zoom back. That
  single rule gives tap = toggle, hold while muted = push-to-talk, and hold while live = mute for a moment.
- `AppModel` remembers the state at key-down and returns Zoom to exactly that state on a long release, rather
  than toggling again, so a slow or failed press can never leave the mic live after push-to-talk.
- `KeyCombo` validates recorded shortcuts (⌃ or ⌘ required, except F13–F20) and renders them as keycaps, a
  display string, and a native menu key equivalent.
- `ZoomShortcut` reads Zoom's own hotkey preferences to warn when Zoom's global Mute shortcut uses the same
  keys. In that case Zoom gets the key first and OnAir never sees it.

### Displays

| File | What it is |
| --- | --- |
| `MenuBar/MenuBarIcon.swift` | The status item's image for each state. A rendered image in the standard status bar button, so macOS sizes, highlights, and tints it. Monochrome states are template images. |
| `MenuBar/MenuBarController.swift` | The standard `NSMenu`. Only the status row at the top is a custom view. |
| `Settings/SettingsWindow.swift` | A standard window with a grouped SwiftUI `Form`. |
| `Onboarding/OnboardingWindow.swift` | The three-step first-run window. |
| `Overlays/BadgeWindow.swift` | The draggable floating badge (`OnAirCore/BadgeSnap` snaps it to screen edges). |
| `Overlays/GlowWindows.swift` | One click-through panel per display with a pulsing red rim. |
| `Overlays/FlashWindow.swift` | The center-screen confirmation on each muted ↔ live change. |
| `Overlays/OverlayPanel.swift` | The shared panel setup for all three overlays. |

### Updates: `Updates/Updater.swift`

Sparkle's standard updater checks once a day for `appcast.xml`, the feed attached to the latest GitHub release
(`SUFeedURL` in `Info.plist`). Every update zip is signed with an EdDSA key; the public half is `SUPublicEDKey`
in `Info.plist`, so a copy of OnAir only installs updates signed with the project's private key.

OnAir has no Dock icon, so an update window from a background check opens behind other apps. Following Sparkle's
"gentle reminders" guidance, `Updater` also changes the menu's **Check for Updates…** item to
**Update Available…** until the user has looked at the update.

## Design decisions

- **Standard components wherever possible.** The status item uses a plain image, the menu is a real `NSMenu`,
  and the windows are standard titled windows. Earlier versions drew a custom glass window and a SwiftUI menu
  bar view; both needed hand-tuned workarounds and broke in subtle ways (for example, `NSGlassEffectView`
  draws a window-sized tint layer while the window is key, which shows as a box around a custom-shaped
  window). Standard components get the system's look, highlighting, keyboard navigation, and VoiceOver
  for free.
- **Overlays never take focus.** Badge, glow, and flash are borderless, non-activating `NSPanel`s that join
  every Space and float over full-screen apps. They set `sharingType = .none`, so screen sharing and
  screenshots leave them out where macOS honors it.
- **Poll, don't guess.** Zoom doesn't announce mute changes, so OnAir polls. The displayed state always comes
  from Zoom, except for the short, bounded optimistic window after OnAir's own press.
- **No sandbox, no App Store.** The App Sandbox doesn't allow controlling another app through Accessibility,
  which is the core of how OnAir works.
- **Signing matters for Accessibility.** macOS ties the permission to the code signature, so every build is
  signed with the same identity, and the permission survives updates. Releases use a self-signed certificate,
  "OnAir Release Signing", rather than an Apple Development certificate, whose name contains its owner's email
  and would be readable from every download. A self-signed certificate has no Team ID, so library validation
  would refuse to load Sparkle. `Resources/OnAir.entitlements` turns that one check off; the rest of the
  hardened runtime stays on.

## Demo mode

`ONAIR_DEMO=1` replaces the Zoom reader with a fake that cycles `noMeeting → muted → live` every 3 s, runs
OnAir as a regular app, and leaves overlays capturable. Use it to check the displays without a Zoom call.

## Design history

`docs/superpowers/` holds the original design spec and implementation plan. They record the reasoning at the
time; where they differ from this document, the code and this document are current.
