#!/bin/sh
# Blocks SITES Mon-Fri 09:00-17:00 via /etc/hosts. Run as root by launchd.
SITES="youtube.com reddit.com twitter.com x.com instagram.com facebook.com"
HOSTS=${HOSTS:-/etc/hosts}
TAG="# blocker"

active() { [ "$(date +%u)" -le 5 ] && [ "$(date +%H)" -ge 9 ] && [ "$(date +%H)" -lt 17 ]; }
[ "$1" = "active" ] && { active; exit; }

tmp=$(mktemp)
grep -v "$TAG" "$HOSTS" > "$tmp"
if active; then
  for s in $SITES; do
    for h in "$s" "www.$s" "m.$s"; do
      echo "127.0.0.1 $h $TAG"
      echo "::1 $h $TAG"
    done
  done >> "$tmp"
fi
if ! cmp -s "$tmp" "$HOSTS"; then
  cat "$tmp" > "$HOSTS"
  dscacheutil -flushcache 2>/dev/null; killall -HUP mDNSResponder 2>/dev/null
fi
rm -f "$tmp"
