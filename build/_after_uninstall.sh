#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
echo "--- www 目录 ---"
ls -la "$D/www"
echo "--- 根路径返回 ---"
curl -s -m 8 http://192.168.66.1:8080/ | head -c 200
echo
echo "--- 详情页 ---"
curl -s -m 8 -o /dev/null -w "details=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/details
echo "--- 备份与 ipk ---"
ls -lh /root/backup
ls -lh /root/pkgs
echo "--- uhttpd 8080 段 ---"
uci -q get uhttpd.openwrt8080.home
