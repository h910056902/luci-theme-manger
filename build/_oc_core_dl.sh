#!/bin/sh
# 下载 mihomo 内核（断点续传 + gzip 校验 + 安装）
LOG=/overlay/oc-core.log
ST=/overlay/oc-core.state
: > "$LOG"
GZ=/tmp/mihomo.gz
DST=/etc/openclash/core/clash_meta

VER=v1.19.33
REL=https://github.com/MetaCubeX/mihomo/releases/download/$VER/mihomo-linux-arm64-$VER.gz
MIRRORS="https://ghproxy.net/ https://gh-proxy.com/ https://ghfast.top/"

echo "start" > "$ST"
rm -f "$GZ"

for prefix in $MIRRORS; do
	echo "== try mirror $prefix ==" >> "$LOG"
	rm -f "$GZ"          # 换镜像时丢弃上一份，避免续传拼坏文件
	n=0
	while [ $n -lt 12 ]; do
		n=$((n+1))
		curl -sL -C - -m 120 -o "$GZ" "$prefix$REL" 2>>"$LOG"
		sz=$(wc -c < "$GZ" 2>/dev/null || echo 0)
		echo "   attempt$n size=$sz" >> "$LOG"
		echo "downloading $sz" > "$ST"
		if [ "$sz" -gt 5000000 ]; then
			if gunzip -t "$GZ" 2>/dev/null; then
				echo "   gzip OK at $sz" >> "$LOG"
				break 2
			fi
		fi
	done
done

if ! gunzip -t "$GZ" 2>/dev/null; then
	echo "stage=fail" > "$ST"
	echo "gzip FAIL (size=$(wc -c < "$GZ" 2>/dev/null))" >> "$LOG"
	exit 0
fi

mkdir -p /etc/openclash/core
gunzip -c "$GZ" > "$DST" 2>>"$LOG"
chmod 755 "$DST"
echo "installed=$(wc -c < "$DST")" >> "$LOG"
"$DST" -v >> "$LOG" 2>&1
echo "stage=done size=$(wc -c < "$DST")" > "$ST"
