#!/bin/sh
# 验证商店的 local 安装入口，以及本机 https 是否可用
PKG=nradio-luci-8080
IPK=/www/pkgs/${PKG}_20261022-1_all.ipk

echo "== 0. 当前状态 =="
opkg list-installed | grep $PKG || echo "not-installed"

echo "== 1. 卸载后走 appcenter local =="
opkg remove $PKG >/dev/null 2>&1
echo "removed"
ubus call appcenter local "{\"file\":\"$IPK\"}" 2>&1
sleep 6
opkg list-installed | grep $PKG || echo "local-install-failed"

echo "== 2. https 探活 =="
curl -sk -m 8 -o /dev/null -w "https_root=%{http_code}\n" https://192.168.66.1/
curl -sk -m 8 -o /dev/null -w "https_ipk=%{http_code}\n" "https://192.168.66.1/pkgs/${PKG}_20261022-1_all.ipk"

echo "== 3. appcenter 日志 =="
logread 2>/dev/null | grep -i appcenter | tail -6

echo "== 4. 兜底恢复 =="
if ! opkg list-installed | grep -q $PKG; then
    echo "FALLBACK"
    opkg install $IPK 2>&1
fi
opkg list-installed | grep $PKG || echo "FINAL-FAIL"
curl -s -m 10 -o /dev/null -w "details=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/details
echo "DONE"
