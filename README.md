# blocker

Blocks distracting sites on macOS and iPhone Mon–Fri 09:00–17:00 and shows a random quote instead.

- `blocker.sh` rewrites `/etc/hosts` every minute (and whenever it's edited), so removing a line just puts it back.
- `quote.py` serves the quote page on :80/:443 using a cert from a one-off local CA whose private key is deleted after signing.
- Uninstall and site-list changes are refused during block hours.

## Install

```sh
sudo ./install.sh
```

Edit `SITES` in `blocker.sh` and re-run to change the list (outside block hours).

## Uninstall

```sh
sudo ./install.sh uninstall
```

The cert lasts 397 days; re-run install to renew.

## iPhone

`ios/` is a small app built on Apple's Screen Time API, with the same sites, hours and quotes.

- The sites in `ios/Shared/Blocker.swift` get blocked in Safari (Apple's "restricted" page).
- Apps and sites you choose in the app show a quote screen instead.
- The choice can't be changed during block hours. To stop it, delete the app.

Build it:

1. Open `ios/Blocker.xcodeproj` in Xcode 16+.
2. Under Project → Build Settings, set `APP_BUNDLE_ID` to something unique (e.g. `com.yourname.blocker`) and `DEVELOPMENT_TEAM` to your team.
3. Plug in your iPhone and Run. Allow Screen Time access when asked.

You'll need a paid Apple Developer account for the Family Controls capability. To publish on the App Store, Apple must [approve the entitlement](https://developer.apple.com/contact/request/family-controls-distribution).
