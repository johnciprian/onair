# Open items

What's left to do, and what was decided against, so nothing gets lost between work sessions.
Last updated 2026-11-05.

## To do

- [ ] **Homebrew cask (optional).** Possible now that downloads are notarized.
- [ ] **Renew the Developer ID certificate before it expires on 2027-12-06.** Released versions keep working, but
  new ones can't be signed without it.
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

Losing any of these makes releases harder, so they're backed up in 1Password, except where noted.

| What | Where it's used | Backup in 1Password |
| --- | --- | --- |
| Sparkle update key (EdDSA) | Login Keychain, account `onair`; signs each update in `scripts/release.sh` | "OnAir Sparkle update signing key (private)". Restore: `generate_keys --account onair -f <file>` |
| "Developer ID Application: Ciprian Technologies LLC" certificate | Login and System Keychains; signs every build in `scripts/build.sh` | None. Its key is only on this Mac; if it's lost, create a new certificate under the same team (Team ID `38WW6667W6`). Users aren't affected |
| GPG key for hello@johnciprian.dev | Signs commits in this repo (`git config user.signingkey`) | "GPG key: John Ciprian <hello@johnciprian.dev> (private, passphrase-protected)", plus its revocation certificate. Restore: `gpg --import <file>` |
