#!/bin/sh
PKG=$(ls -t /tmp/kp-backup-*.ipk 2>/dev/null | head -1)
[ -n "$PKG" ] || { echo "没有 ipk"; exit 1; }
echo "== 安装 $PKG =="

BEFORE_CGI=$(wc -c < /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci 2>/dev/null)
echo "安装前 CGI 大小: $BEFORE_CGI"

opkg install "$PKG" 2>&1 | tail -12

echo "== 安装后 =="
echo -n "包是否登记: "; opkg list-installed 2>/dev/null | grep -c '^kp-backup'
echo -n "kp-backup 目录: "; ls /etc/kp-backup/ 2>/dev/null | tr '\n' ' '
echo
echo -n "CGI 大小: "; wc -c < /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci 2>/dev/null
echo -n "配置抽查 kpnet: "; uci -q get kpnet.web.listen
echo -n "页面状态: "; curl -s -o /dev/null -w '%{http_code}\n' -m 10 http://192.168.66.1:8080/cgi-bin/luci/admin/status/overview

echo "== 卸载恢复包（清理）=="
opkg remove kp-backup 2>&1 | tail -3
echo -n "移除后目录: "; ls /etc/kp-backup/ 2>/dev/null | wc -l

echo "== 恢复本次部署的最新面板文件 =="
sh /tmp/_deploy_backup.sh 2>&1 | tail -4
echo DONE
