#!/bin/sh
LOG=/overlay/di.log
: > "$LOG"
W=/overlay/apkdl

echo "== 1. apk 本地安装 ==" >> "$LOG"
apk add --allow-untrusted --no-progress "$W"/runc-*.apk "$W"/containerd-*.apk "$W"/dockerd-*.apk >> "$LOG" 2>&1
rc=$?
echo "   rc=$rc" >> "$LOG"

if [ ! -x /usr/bin/dockerd ]; then
	echo "== 2. 回退：手动解包 ==" >> "$LOG"
	mkdir -p /overlay/apkx
	for f in "$W"/runc-*.apk "$W"/containerd-*.apk "$W"/dockerd-*.apk; do
		tar -xzf "$f" -C /overlay/apkx 2>>"$LOG" && echo "   tar OK $(basename "$f")" >> "$LOG" || echo "   tar FAIL $(basename "$f")" >> "$LOG"
	done
	cp -a /overlay/apkx/. / 2>>"$LOG"
	chmod 755 /usr/bin/dockerd /usr/bin/containerd /usr/bin/runc 2>/dev/null
	chmod 755 /etc/init.d/dockerd 2>/dev/null
fi

echo "== 3. 校验 ==" >> "$LOG"
{ command -v dockerd; dockerd --version 2>&1 | head -1; command -v containerd; command -v runc; } >> "$LOG" 2>&1
echo done > /overlay/di.state
