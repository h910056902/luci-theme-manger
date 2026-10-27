#!/bin/sh
LOG=/tmp/dm.log
ST=/tmp/dm.state
: > "$LOG"
say() { echo "== $* ==" >> "$LOG"; echo "$*" > "$ST"; }

W=/overlay/dockerpkg
rm -rf "$W"; mkdir -p "$W/x"
cd "$W" || exit 1

say fetch
df -h /tmp /overlay >> "$LOG" 2>&1
apk fetch --no-progress -o "$W" dockerd containerd runc docker containerd-ctr libseccomp libnetwork 2>>"$LOG"
say "fetched $(ls "$W"/*.apk 2>/dev/null | wc -l) apk"

say extract
cd "$W/x" || exit 1
for f in "$W"/*.apk; do
	[ -f "$f" ] || continue
	if tar -xzf "$f" 2>>"$LOG"; then :; else echo "TAR_FAIL $(basename "$f")" >> "$LOG"; fi
done
ls -la >> "$LOG" 2>&1

say copy
cp -a "$W"/x/. / 2>>"$LOG"
chmod 755 /usr/bin/dockerd /usr/bin/docker /usr/bin/containerd /usr/bin/runc /usr/bin/containerd-shim-runc-v2 2>/dev/null
chmod 755 /etc/init.d/dockerd 2>/dev/null

say verify
{ command -v dockerd; dockerd --version; docker --version; } >> "$LOG" 2>&1
say done
