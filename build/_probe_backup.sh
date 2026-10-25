#!/bin/sh
echo "== /etc/sysupgrade.conf =="
cat /etc/sysupgrade.conf 2>/dev/null || echo "(不存在)"

echo "== /lib/upgrade/keep.d =="
ls -l /lib/upgrade/keep.d/ 2>/dev/null | head -20

echo "== 其中与本面板相关的条目 =="
grep -rn 'nradio\|8080\|kpnet\|kaiplus' /lib/upgrade/keep.d/ /etc/sysupgrade.conf 2>/dev/null | head -10

echo "== 当前备份会包含多少文件 =="
sysupgrade -l 2>/dev/null | wc -l
echo "== 是否已含 kpnet / 8080 =="
sysupgrade -l 2>/dev/null | grep -c 'kpnet\|nradio-apps' || true

echo "== 本面板相关配置体量 =="
du -sh /etc/config/kpnet /etc/config/kpsmsfwd /etc/kpsmsfwd.body /etc/config/kaiplus 2>/dev/null
echo "== 实例目录体量（不建议整体备份）=="
du -sh /overlay/nradio-apps/openwrt-luci-8080 2>/dev/null
echo "== 备份页面是否存在 =="
ls -l /usr/lib/lua/luci/view/admin_system/backupfiles.htm 2>/dev/null | head -2
