# blocker

Blocks distracting sites on macOS Mon–Fri 09:00–17:00 and shows a random quote instead.

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
