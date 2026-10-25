#!/bin/sh
echo "== 当前备份清单里与面板相关的行 =="
sysupgrade -l 2>/dev/null | grep -E 'kpnet|nradio|8080|kpmsfwd|kpsmsfwd|ttyd' || echo "（没有）"

echo "== 逐项确认 =="
for p in /etc/config/kpnet /etc/config/kpsmsfwd /etc/kpsmsfwd.body /etc/config/ttyd /etc/config/kaiplus; do
	[ -e "$p" ] || { echo "  缺 $p"; continue; }
	if sysupgrade -l 2>/dev/null | grep -qx "$p"; then echo "  已含 $p"; else echo "  未含 $p"; fi
done

echo "== 现有 keep.d 内容示例 =="
head -3 /lib/upgrade/keep.d/luci-app-kaiplus /lib/upgrade/keep.d/uhttpd 2>/dev/null
