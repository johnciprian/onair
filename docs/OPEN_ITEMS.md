# Open items

What's left to do, and what was decided against, so nothing gets lost between work sessions.
Last updated 2026-10-09.

## To do

- [ ] **Notarized downloads (optional, $99/year).** Today the first launch of a download needs
  System Settings → Privacy & Security → Open Anyway; updates through Sparkle don't. Notarizing would remove that
  step and make a Homebrew cask possible. It needs the paid Apple Developer Program, then: sign with a
  **Developer ID Application** certificate in `scripts/build.sh` (Developer ID shares a Team ID with Sparkle, so
  `Resources/OnAir.entitlements` can go), `xcrun notarytool submit --wait`, and `xcrun stapler staple`.
  Switching certificates changes the signature, so users would allow Accessibility once more after that update.
- [ ] **Add hello@johnciprian.dev to GitHub** (Settings → Emails) and the GPG key
  `9E549D553F9959C4B2D7F869497D592D7BA4729C` (Settings → SSH and GPG keys), so commits show as Verified.
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
- **Other meeting apps** (Teams, Meet, Slack huddles, Zoom in a browser). Zoom desktop only.

## Keys and certificates

Losing any of these makes releases harder, so each one is backed up in 1Password.

| What | Where it's used | Backup in 1Password |
| --- | --- | --- |
| Sparkle update key (EdDSA) | Login Keychain, account `onair`; signs each update in `scripts/release.sh` | "OnAir Sparkle update signing key (private)". Restore: `generate_keys --account onair -f <file>` |
| "OnAir Release Signing" certificate | Login Keychain; signs every build in `scripts/build.sh` | "OnAir release code-signing certificate (private)", a PEM with key and certificate. Restore: convert to .p12 with `openssl pkcs12 -export` and import it |
| GPG key for hello@johnciprian.dev | Signs commits in this repo (`git config user.signingkey`) | Not backed up yet |
