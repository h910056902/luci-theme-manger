#!/bin/sh
# 卸载 → 重启守护（清掉已安装缓存）→ 走商店安装
PKG=nradio-luci-8080
FILE=/www/pkgs/nradio-luci-8080_20261022-1_all.ipk

echo "== 1. 卸载 =="
opkg remove $PKG 2>&1
echo "== 2. 重启商店守护 =="
/etc/init.d/appcenter restart >/dev/null 2>&1
sleep 4
echo "== 3. 商店安装 =="
ubus call appcenter install "{\"name\":\"$PKG\"}" 2>&1
sleep 12
echo "== 4. 结果 =="
opkg list-installed | grep $PKG || echo "STORE-INSTALL-FAILED"
echo "== 5. 日志 =="
logread 2>/dev/null | grep -i "appcenter" | grep -iE "download|install|pkg" | tail -12
echo "== 6. 兜底 =="
if ! opkg list-installed | grep -q $PKG; then
    echo "FALLBACK"
    opkg install "$FILE" 2>&1
fi
opkg list-installed | grep $PKG || echo "FINAL-FAIL"
curl -s -m 10 -o /dev/null -w "details=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/details
echo "DONE"
