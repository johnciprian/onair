# Open items

What's left to do, and what was decided against, so nothing gets lost between work sessions.
Last updated 2026-10-09.

## To do

- [ ] **Signed, notarized downloads.** Today a shared build is blocked by Gatekeeper on other Macs (they can
  still open it via System Settings → Privacy & Security → Open Anyway). Needs a paid Apple Developer Program
  membership. Then: sign with a **Developer ID Application** certificate in `scripts/build.sh`, submit with
  `xcrun notarytool submit --wait`, `xcrun stapler staple` the app, and publish the zip as a GitHub release.
  The build already uses the hardened runtime that notarization requires.
- [ ] **Make the repository public.** README, architecture doc, and license are in place. Before flipping it,
  re-read the docs and check the git history for anything you don't want published.
- [ ] **Confirm the short push-to-talk fix in a real meeting.** While muted, hold the hotkey well under a second
  and let go: Zoom should end up muted. (Fixed in code on 2026-10-09; not yet tested in Zoom.)
- [ ] **Confirm Launch at Login when macOS asks for approval.** Ticking the box should stay ticked and open
  System Settings → Login Items. (Fixed in code on 2026-10-09; hard to reproduce on demand.)

## Decided against (for now)

- **Zoom in languages other than English.** OnAir matches Zoom's English menu titles ("Meeting",
  "Mute audio", "Unmute audio"). Supporting other languages would mean collecting the localized titles from
  Zoom for each language. English only for now.
- **Intel Macs.** Builds are Apple silicon only (`--arch arm64` in `scripts/build.sh`).
- **Mac App Store.** Not possible: the App Sandbox doesn't allow controlling another app through
  Accessibility, which is how OnAir reads and presses Zoom's mute.
- **Automatic updates.** Would need a third-party framework (Sparkle). New versions are shared by hand.
- **Other meeting apps** (Teams, Meet, Slack huddles, Zoom in a browser). Zoom desktop only.
