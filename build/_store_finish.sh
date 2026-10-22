#!/bin/sh
PKG=nradio-luci-8080
IPK=/www/pkgs/${PKG}_20261022-1_all.ipk

echo "== 1. 修复 opkg 记录 =="
ls -l /var/lock/opkg.lock 2>&1
opkg list-installed | grep $PKG || echo "db-missing"
if ! opkg list-installed | grep -q $PKG; then
    opkg install --force-reinstall "$IPK" 2>&1
fi
sleep 1
opkg list-installed | grep $PKG || echo "STILL-MISSING"

echo "== 2. 8080 探活 =="
curl -s -m 10 -o /dev/null -w "/ -> %{http_code}\n" http://192.168.66.1:8080/
curl -s -m 10 -o /dev/null -w "details -> %{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/details

echo "== 3. 商店 UI 是否支持本地安装 =="
V=/usr/lib/lua/luci/view/nradio_appcenter/appcenter.htm
ls -l "$V" 2>&1
grep -c "local" "$V" 2>/dev/null
grep -o "install[a-zA-Z_]*" "$V" 2>/dev/null | sort -u | head -12
grep -o "本地[^<\"]*\|上传[^<\"]*" "$V" 2>/dev/null | head -8

echo "== 4. 商店条目最终状态 =="
ubus call appcenter list 2>/dev/null | grep -A5 "\"$PKG\"" | grep -E '"status"|"type"|"name"' | head -8
echo "DONE"
