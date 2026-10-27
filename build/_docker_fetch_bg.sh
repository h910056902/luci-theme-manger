#!/bin/sh
LOG=/tmp/df.log
ST=/tmp/df.state
: > "$LOG"
say() { echo "== $* ==" >> "$LOG"; echo "$*" > "$ST"; }

W=/overlay/dockerpkg
rm -rf "$W"; mkdir -p "$W/x"
cd "$W" || exit 1

say fetch
apk fetch --no-progress dockerd containerd runc >> "$LOG" 2>&1
say "apk files: $(ls "$W"/*.apk 2>/dev/null | wc -l)"

say extract
for f in "$W"/*.apk; do
	[ -f "$f" ] || continue
	tar -xzf "$f" -C "$W/x" 2>>"$LOG" && echo "OK $(basename "$f")" >> "$LOG" || echo "FAIL $(basename "$f")" >> "$LOG"
done
ls -la "$W/x" >> "$LOG" 2>&1

say copy
if [ -f "$W/x/usr/bin/dockerd" ]; then
	cp -a "$W/x"/. / 2>>"$LOG"
	chmod 755 /usr/bin/dockerd /usr/bin/containerd /usr/bin/runc /usr/bin/containerd-shim* 2>/dev/null
	chmod 755 /etc/init.d/dockerd 2>/dev/null
	say copied
else
	say "no dockerd in extracted tree"
fi

say verify
{ command -v dockerd; dockerd --version; ldd /usr/bin/dockerd 2>/dev/null | grep -c 'not found'; } >> "$LOG" 2>&1
say done
