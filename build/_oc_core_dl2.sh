#!/bin/sh
# 用实测最快的 gh-proxy.com 下载 mihomo 内核，断点续传直到 gzip 完整
LOG=/overlay/oc-core.log
ST=/overlay/oc-core.state
GZ=/tmp/mihomo.gz
DST=/etc/openclash/core/clash_meta
URL=https://gh-proxy.com/https://github.com/MetaCubeX/mihomo/releases/download/v1.19.33/mihomo-linux-arm64-v1.19.33.gz
EXPECT=20824326

: > "$LOG"
rm -f "$GZ"
echo "start expect=$EXPECT" > "$ST"

n=0
while [ $n -lt 20 ]; do
	n=$((n+1))
	curl -sL -C - -m 90 -o "$GZ" "$URL" 2>>"$LOG"
	sz=$(wc -c < "$GZ" 2>/dev/null || echo 0)
	echo "  attempt$n size=$sz" >> "$LOG"
	echo "downloading $sz/$EXPECT" > "$ST"
	if [ "$sz" -ge "$EXPECT" ]; then
		echo "  size reached" >> "$LOG"
		break
	fi
done

if ! gunzip -t "$GZ" 2>/dev/null; then
	echo "stage=fail size=$(wc -c < "$GZ" 2>/dev/null)" > "$ST"
	echo "gzip FAIL" >> "$LOG"
	exit 0
fi

mkdir -p /etc/openclash/core
gunzip -c "$GZ" > "$DST"
chmod 755 "$DST"
echo "installed=$(wc -c < "$DST")" >> "$LOG"
"$DST" -v >> "$LOG" 2>&1
echo "stage=done size=$(wc -c < "$DST")" > "$ST"
