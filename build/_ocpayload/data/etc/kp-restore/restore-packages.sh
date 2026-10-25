#!/bin/sh
# 装回「除固件自带之外」的插件，需要联网（opkg 源可达）
L=/etc/kp-restore/packages.txt
[ -f "$L" ] || { echo "缺少 $L"; exit 1; }
echo "[1/3] 更新软件源..."
opkg update >/dev/null 2>&1
echo "[2/3] 计算差异..."
opkg list-installed 2>/dev/null | awk '{print $1}' | sort > /tmp/kp-have.txt
awk '{print $1}' "$L" | sort > /tmp/kp-want.txt
awk 'NR==FNR{h[$1]=1;next} !($1 in h){print $1}' /tmp/kp-have.txt /tmp/kp-want.txt > /tmp/kp-miss.txt
echo "  待安装：$(wc -l < /tmp/kp-miss.txt) 个"
echo "[3/3] 安装..."
while read -r p; do
	[ -n "$p" ] || continue
	if opkg install "$p" >/dev/null 2>&1; then echo "  OK   $p"; else echo "  FAIL $p"; fi
done < /tmp/kp-miss.txt
echo "完成。装不上的多半是 iStore 应用，去应用商店重装。"
