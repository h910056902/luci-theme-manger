#!/bin/sh
pkill -f _oc_core_dl.sh 2>/dev/null
pkill -f 'curl.*mihomo' 2>/dev/null

echo "== 1. 全盘找现成内核（>3MB 且名字含 clash/mihomo）=="
find / -xdev -type f -size +3M \( -name '*clash*' -o -name '*mihomo*' \) 2>/dev/null | head -8
echo "-- overlay 单独找（分区独立，-xdev 会跳过）--"
find /overlay -type f -size +3M \( -name '*clash*' -o -name '*mihomo*' \) 2>/dev/null | head -8

echo "== 2. 备份包里有没有 core =="
tar -tzf /overlay/kp-restore-20261025-194209.ipk 2>/dev/null >/dev/null && echo "  包可读"
tar -xzf /overlay/kp-restore-20261025-194209.ipk -O ./data.tar.gz 2>/dev/null | tar -tzf - 2>/dev/null | grep -c 'core/' 

echo "== 3. 镜像测速（各取 2MB 计时）=="
REL=https://github.com/MetaCubeX/mihomo/releases/download/v1.19.33/mihomo-linux-arm64-v1.19.33.gz
for p in https://ghproxy.net/ https://gh-proxy.com/ https://ghfast.top/ https://mirror.ghproxy.com/; do
	t=$( { curl -s -o /dev/null -m 20 -r 0-2097151 -w '%{size_download} %{time_total}' "$p$REL"; } 2>/dev/null )
	echo "  $p -> ${t:-fail}"
done
