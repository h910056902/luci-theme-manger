#!/bin/sh
PKG=nradio-luci-8080
IPK=/www/pkgs/${PKG}_20261022-1_all.ipk

echo "== 1. 标记为本地应用 type=1 =="
i=0
while uci -q get appcenter.@package_list[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package_list[$i].name)
    if [ "$n" = "$PKG" ]; then
        uci set appcenter.@package_list[$i].type=1
        echo "set package_list[$i].type=1"
    fi
    i=$((i + 1))
done
i=0
while uci -q get appcenter.@package[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package[$i].name)
    if [ "$n" = "$PKG" ]; then
        uci set appcenter.@package[$i].status=1
        echo "set package[$i].status=1"
    fi
    i=$((i + 1))
done
uci commit appcenter
/etc/init.d/appcenter restart >/dev/null 2>&1
sleep 3

echo "== 2. 列表状态 =="
ubus call appcenter list 2>/dev/null | grep -A7 "\"$PKG\"" | grep -E '"status"|"type"' | head -6

echo "== 3. 卸载后走商店安装 =="
opkg remove $PKG >/dev/null 2>&1
echo "removed"
ubus call appcenter install "{\"name\":\"$PKG\"}" 2>&1
sleep 8
opkg list-installed | grep $PKG || echo "STORE-INSTALL-FAILED"

echo "== 4. 日志 =="
logread 2>/dev/null | grep -i appcenter | tail -8

echo "== 5. 兜底 =="
if ! opkg list-installed | grep -q $PKG; then
    echo "FALLBACK"
    opkg install "$IPK" 2>&1
fi
opkg list-installed | grep $PKG || echo "FINAL-FAIL"
curl -s -m 10 -o /dev/null -w "details=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/details
echo "DONE"
