#!/bin/sh
LOG=/overlay/apkdl.log
ST=/overlay/apkdl.state
: > "$LOG"
B=https://mirror.sjtu.edu.cn/openwrt/releases/25.12-SNAPSHOT/packages/aarch64_cortex-a53/packages
W=/overlay/apkdl
mkdir -p "$W"

echo "start" > "$ST"
for f in dockerd-29.6.1-r1.apk containerd-2.2.5-r1.apk runc-1.3.6-r1.apk; do
	echo "== $f ==" >> "$LOG"
	n=0
	while [ $n -lt 8 ]; do
		n=$((n+1))
		curl -sL -C - -m 120 -o "$W/$f" "$B/$f" 2>>"$LOG"
		sz=$(wc -c < "$W/$f" 2>/dev/null || echo 0)
		echo "   try$n size=$sz" >> "$LOG"
		echo "downloading $f $sz" > "$ST"
		# 认为 >1MB 且两次增长停滞时跳出
		[ "$sz" -gt 1000000 ] && break
	done
done
echo done > "$ST"
ls -l "$W" >> "$LOG" 2>&1
