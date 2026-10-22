#!/bin/sh
# 假设：商店守护按 /nradio-appstore/<arch>/<app>/<version>/<file>.ipk 解析 URL
PKG=nradio-luci-8080
VER=20261022-1
FILE=${PKG}_${VER}_all.ipk
D=/www/nradio-appstore/all/${PKG}/${VER}
URL="http://192.168.66.1/nradio-appstore/all/${PKG}/${VER}/${FILE}"

echo "== 1. 按厂商目录结构托管 =="
mkdir -p "$D"
cp /root/pkgs/${FILE} "$D/${FILE}"
chmod 644 "$D/${FILE}"
ls -l "$D/${FILE}"
curl -s -m 8 -o /dev/null -w "url_check=%{http_code}\n" "$URL"

echo "== 2. 更新 url =="
MD5=$(md5sum "$D/${FILE}" | cut -d' ' -f1)
BYTES=$(wc -c < "$D/${FILE}")
i=0
while uci -q get appcenter.@package_list[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package_list[$i].name)
    if [ "$n" = "$PKG" ]; then
        uci set appcenter.@package_list[$i].url="$URL"
        uci set appcenter.@package_list[$i].md5="$MD5"
        uci set appcenter.@package_list[$i].size="$BYTES"
        uci set appcenter.@package_list[$i].type=0
        echo "url set at package_list[$i]"
    fi
    i=$((i + 1))
done
uci commit appcenter
/etc/init.d/appcenter restart >/dev/null 2>&1
sleep 3

echo "== 3. 卸载后走商店安装 =="
opkg remove $PKG >/dev/null 2>&1
echo "removed"
ubus call appcenter install "{\"name\":\"$PKG\"}" 2>&1
sleep 10
opkg list-installed | grep $PKG || echo "STORE-INSTALL-FAILED"

echo "== 4. 日志 =="
logread 2>/dev/null | grep -i "appcenter" | tail -10

echo "== 5. 兜底 =="
if ! opkg list-installed | grep -q $PKG; then
    echo "FALLBACK"
    opkg install "/www/pkgs/${FILE}" 2>&1
fi
opkg list-installed | grep $PKG || echo "FINAL-FAIL"
curl -s -m 10 -o /dev/null -w "details=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/details
echo "DONE"
