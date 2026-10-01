#!/bin/sh
# sudo ./install.sh            install / update site list
# sudo ./install.sh uninstall  remove (refused during block hours)
set -e
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
SRC=$(cd "$(dirname "$0")" && pwd)
BIN=/usr/local/sbin/blocker
QBIN=/usr/local/sbin/blocker-quote.py
ETC=/usr/local/etc/blocker
PLIST=/Library/LaunchDaemons/local.blocker.plist
QPLIST=/Library/LaunchDaemons/local.blocker.quote.plist
KC=/Library/Keychains/System.keychain
CA="Blocker Local CA"

if [ -x "$BIN" ] && "$BIN" active; then
  echo "Blocked hours (Mon-Fri 9-17). Changes allowed after 17:00."; exit 1
fi

launchctl bootout system "$PLIST" 2>/dev/null || true
launchctl bootout system "$QPLIST" 2>/dev/null || true
while security delete-certificate -c "$CA" "$KC" >/dev/null 2>&1; do :; done

if [ "$1" = "uninstall" ]; then
  rm -rf "$BIN" "$QBIN" "$ETC" "$PLIST" "$QPLIST"
  sed -i '' '/# blocker/d' /etc/hosts
  echo "Removed."; exit 0
fi

mkdir -p /usr/local/sbin "$ETC"
install -o root -g wheel -m 755 "$SRC/blocker.sh" "$BIN"
install -o root -g wheel -m 644 "$SRC/quote.py" "$QBIN"

# One-off CA signs a cert for the blocked sites, gets trusted, then its key is deleted
# so it can never sign anything else. ponytail: cert lasts 397 days (Apple's max), re-run install to renew.
SITES=$(sed -n 's/^SITES="\(.*\)"/\1/p' "$SRC/blocker.sh")
SAN=$(for s in $SITES; do printf 'DNS:%s,DNS:*.%s,' "$s" "$s"; done)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT; cd "$tmp"
printf 'basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign\n' > ca.ext
printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\nbasicConstraints=CA:FALSE\n' "${SAN%,}" > leaf.ext
openssl req -new -newkey rsa:2048 -nodes -keyout ca.key -subj "/CN=$CA" -out ca.csr 2>/dev/null
openssl x509 -req -in ca.csr -signkey ca.key -days 397 -extfile ca.ext -out ca.pem 2>/dev/null
openssl req -new -newkey rsa:2048 -nodes -keyout key.pem -subj "/CN=blocker" -out leaf.csr 2>/dev/null
openssl x509 -req -in leaf.csr -CA ca.pem -CAkey ca.key -CAcreateserial -days 397 -extfile leaf.ext -out cert.pem 2>/dev/null
security add-trusted-cert -d -r trustRoot -k "$KC" ca.pem
install -o root -g wheel -m 600 cert.pem key.pem "$ETC/"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>local.blocker</string>
  <key>ProgramArguments</key><array><string>$BIN</string></array>
  <key>StartInterval</key><integer>60</integer>
  <key>WatchPaths</key><array><string>/etc/hosts</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
EOF
cat > "$QPLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>local.blocker.quote</string>
  <key>ProgramArguments</key><array><string>/usr/bin/python3</string><string>$QBIN</string></array>
  <key>KeepAlive</key><true/>
  <key>RunAtLoad</key><true/>
</dict></plist>
EOF
chown root:wheel "$PLIST" "$QPLIST"; chmod 644 "$PLIST" "$QPLIST"
launchctl bootstrap system "$PLIST"
launchctl bootstrap system "$QPLIST"
echo "Installed."
