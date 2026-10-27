#!/bin/sh
IPK=/overlay/kp-restore-20261025-194209.ipk
W=/tmp/ocx

echo "== 0. 源里有没有现成内核包 =="
apk search -x mihomo 2>/dev/null | head -3
apk search -x clash 2>/dev/null | head -3

echo "== 1. 解出 data.tar.gz =="
rm -rf "$W"; mkdir -p "$W"
tar -xzf "$IPK" -C "$W" ./data.tar.gz 2>/dev/null || tar -xzf "$IPK" -C "$W" data.tar.gz 2>/dev/null
ls -l "$W/data.tar.gz" 2>/dev/null || { echo "  解包失败"; exit 1; }

echo "== 2. 清单里 openclash 相关条目 =="
tar -tzf "$W/data.tar.gz" 2>/dev/null | grep -iE 'openclash' | head -20
echo "  openclash 条目总数: $(tar -tzf "$W/data.tar.gz" 2>/dev/null | grep -ciE 'openclash')"

echo "== 3. 只解 openclash 相关路径 =="
LIST=$W/list.txt
tar -tzf "$W/data.tar.gz" 2>/dev/null | grep -iE 'openclash' > "$LIST"
[ -s "$LIST" ] || { echo "  清单为空"; exit 1; }
tar -xzf "$W/data.tar.gz" -C / -T "$LIST" 2>&1 | head -5

echo "== 4. 补目录（空目录 tar 不会带过来）=="
mkdir -p /etc/openclash/config /etc/openclash/history /etc/openclash/core /etc/openclash/rule_provider
chmod 755 /etc/openclash /etc/openclash/config /etc/openclash/history /etc/openclash/core

echo "== 5. 校验 =="
for f in /etc/init.d/openclash /usr/share/openclash/openclash.sh \
         /usr/lib/lua/luci/controller/openclash.lua /usr/lib/lua/luci/openclash.lua \
         /etc/config/openclash; do
	[ -f "$f" ] && printf "  OK   %8s  %s\n" "$(wc -c < "$f")" "$f" || printf "  MISS %s\n" "$f"
done
du -sm /etc/openclash /usr/share/openclash 2>/dev/null
chmod 755 /etc/init.d/openclash 2>/dev/null
ls -l /etc/openclash/core/ 2>/dev/null || echo "  core 仍为空（需下载）"
