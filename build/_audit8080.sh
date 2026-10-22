#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080

echo "== opkg 状态 =="
opkg list-installed | grep nradio || echo "无 nradio 包（已卸载）"

echo "== 剩余目录 =="
find "$D" -maxdepth 3 -type d 2>/dev/null | head -20

echo "== 悬空符号链接 =="
find "$D" -xtype l 2>/dev/null || true

echo "== 剩余文件（排除历史备份） =="
find "$D" -type f ! -name '*.bak*' ! -name '*.kpbak*' ! -path '*theme-backup*' 2>/dev/null | head -30

echo "== 8080 监听 =="
netstat -lntp 2>/dev/null | grep 8080

echo "== uhttpd 进程 =="
ps w 2>/dev/null | grep uhttpd | grep -v grep

echo "== uhttpd.openwrt8080 =="
uci show uhttpd.openwrt8080 2>/dev/null

echo "== 商店残留 =="
ubus call appcenter list 2>/dev/null | grep -c nradio

echo "== /tmp 残留 =="
ls -l /tmp 2>/dev/null | grep -i kpc || echo "无"

echo "== 根路径行为 =="
curl -s -m 8 -o /dev/null -w "root=%{http_code}\n" http://192.168.66.1:8080/
curl -s -m 8 http://192.168.66.1:8080/ | head -c 140
echo
echo "== 最近日志错误 =="
logread 2>/dev/null | grep -iE "uhttpd|luci" | tail -8
echo "DONE"
