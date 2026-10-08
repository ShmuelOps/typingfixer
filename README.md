# LayoutFix

Menu-bar app for macOS 13+. When you finish a word typed in the wrong keyboard
layout (`ביקבל` → `check`, `akuo` → `שלום`), it retypes the word in the right
layout and switches the input source. Hebrew ↔ English (US QWERTY / macOS "Hebrew").

A word is fixed only when what you typed is not a word in its own language and
the converted text is, according to the macOS spell-checker dictionaries.

Written from scratch; no code from any other app.

## Privacy

- **No networking.** `scripts/build.sh` fails the build if the binary links
  Network.framework or CFNetwork, imports any socket/DNS/URL-loading symbol, or
  contains a URL. There is no update check, no telemetry, no crash reporter.
- Keystrokes are held in memory only for the current word. Nothing is logged
  or written to disk.
- Password fields: macOS Secure Input hides keystrokes from the app, and it also
  stops processing while Secure Input is on.

## Install

Download the DMG from Releases and drag LayoutFix to Applications. The build is
ad-hoc signed, not notarized, so the first launch needs **right-click → Open**
(or `xattr -dr com.apple.quarantine /Applications/LayoutFix.app`).

Grant **Accessibility** in System Settings → Privacy & Security. The menu-bar
arrows icon shows a `!` until it's granted. Ad-hoc builds change identity on every
release, so re-grant Accessibility after each update (remove the old entry first).

## Build

```sh
scripts/build.sh 0.1.0   # → build/LayoutFix.app, build/LayoutFix-0.1.0.dmg
```

Needs the Xcode command-line tools. The script runs `LayoutFix --selftest` and
the no-network check.

## Release

Push a `v*` tag. The `release` workflow builds the DMG and attaches it to a
GitHub release.

```sh
git tag v0.1.0 && git push origin v0.1.0
```
