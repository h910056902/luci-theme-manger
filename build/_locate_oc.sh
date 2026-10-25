#!/bin/sh
echo "== openclash 包文件清单（前 20）=="
head -20 /usr/lib/opkg/info/luci-app-openclash.list 2>/dev/null
echo "== 其中 www / view 相关 =="
grep -E '^/www|^/usr/lib/lua/luci/view' /usr/lib/opkg/info/luci-app-openclash.list 2>/dev/null | head -15
echo "== 面板目录垃圾统计 =="
du -sm /overlay/nradio-apps/openwrt-luci-8080/theme-backup* 2>/dev/null | tail -3
find /overlay/nradio-apps/openwrt-luci-8080 -maxdepth 2 -name '*.kpbak-*' -o -maxdepth 2 -name '*.bak*' 2>/dev/null | head -5
echo -n "theme-backup 目录数: "; ls -d /overlay/nradio-apps/openwrt-luci-8080/theme-backup* 2>/dev/null | wc -l
