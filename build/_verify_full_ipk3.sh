#!/bin/sh
F=$(ls -t /overlay/kp-restore-*.ipk | head -1)
echo "包: $F"
T=/tmp/kpv3
rm -rf "$T"; mkdir -p "$T"
tar -xzf "$F" -C "$T"

L="$T/data.tar.gz"
echo "== 各类文件计数 =="
printf "  面板          %s\n" "$(tar -tzf "$L" | grep -c 'openwrt-luci-8080/')"
printf "  openclash/etc %s\n" "$(tar -tzf "$L" | grep -c '^\./etc/openclash/')"
printf "  openclash/usr %s\n" "$(tar -tzf "$L" | grep -c '^\./usr/share/openclash/')"
printf "  view/openclash %s\n" "$(tar -tzf "$L" | grep -c '^\./usr/lib/lua/luci/view/openclash/')"
printf "  cbi/openclash  %s\n" "$(tar -tzf "$L" | grep -c '^\./usr/lib/lua/luci/model/cbi/openclash/')"
printf "  www/resources  %s\n" "$(tar -tzf "$L" | grep -c '^\./www/luci-static/resources/openclash/')"
printf "  theme-backup   %s（应为 0）\n" "$(tar -tzf "$L" | grep -c 'theme-backup')"

echo "== 关键文件 =="
for p in ./etc/config/openclash ./etc/init.d/openclash ./usr/lib/lua/luci/controller/openclash.lua \
         ./overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci ./etc/kp-restore/restore-packages.sh; do
	if tar -tzf "$L" | grep -qx "$p"; then echo "  OK   $p"; else echo "  MISS $p"; fi
done

echo "== 订阅相关键（只看键名）=="
tar -xzOf "$L" ./etc/config/openclash 2>/dev/null | grep -oE "option [a-z_]+" | sort -u | head -12

echo "== 主题备份残留 =="
tar -tzf "$L" | grep -E '\.bak|\.kpbak' | head -3 || echo "  无"
rm -rf "$T"
echo DONE
