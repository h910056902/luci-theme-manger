#!/bin/sh
# 把 nradio-luci-8080 注册进鲲鹏应用商店（/etc/config/appcenter + ubus appcenter）
# 幂等：先删同名旧条目，再追加；ipk 托管在本机 /www/pkgs/
PKG=nradio-luci-8080
VER=20261022-1
APP="LuCI 8080 面板"
IPK=/tmp/${PKG}_${VER}_all.ipk
WWWPKG=/www/pkgs
URL="http://192.168.66.1/pkgs/${PKG}_${VER}_all.ipk"
MD5=$(md5sum "$IPK" | cut -d' ' -f1)
BYTES=$(wc -c < "$IPK")

echo "== 1. 托管 ipk =="
mkdir -p "$WWWPKG"
cp "$IPK" "$WWWPKG/"
chmod 644 "$WWWPKG/${PKG}_${VER}_all.ipk"
ls -l "$WWWPKG/${PKG}_${VER}_all.ipk"
echo "URL=$URL"
echo "MD5=$MD5"
echo "BYTES=$BYTES"

echo "== 2. 备份 appcenter 配置 =="
cp /etc/config/appcenter /etc/config/appcenter.bak-kp8080-$(date +%Y%m%d-%H%M%S)
ls -l /etc/config/appcenter.bak-kp8080-* | tail -2

echo "== 3. 清理同名旧条目 =="
i=0
while uci -q get appcenter.@package_list[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package_list[$i].name)
    if [ "$n" = "$PKG" ]; then
        uci delete appcenter.@package_list[$i]
        echo "deleted package_list[$i] $n"
        continue
    fi
    i=$((i + 1))
done
i=0
while uci -q get appcenter.@package[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package[$i].name)
    if [ "$n" = "$APP" ]; then
        uci delete appcenter.@package[$i]
        echo "deleted package[$i] $n"
        continue
    fi
    i=$((i + 1))
done

echo "== 4. 写入商店条目 =="
uci add appcenter package >/dev/null
uci set appcenter.@package[-1].name="$APP"
uci set appcenter.@package[-1].version="$VER"
uci set appcenter.@package[-1].des="8080 端口独立 LuCI：蜂窝网优 / 锁频 / 限速 / 主题定制"
uci set appcenter.@package[-1].size="$BYTES"
uci set appcenter.@package[-1].status="0"
uci set appcenter.@package[-1].has_luci="0"
uci set appcenter.@package[-1].open="0"

uci add appcenter package_list >/dev/null
uci set appcenter.@package_list[-1].name="$PKG"
uci set appcenter.@package_list[-1].parent="$APP"
uci set appcenter.@package_list[-1].size="$BYTES"
uci set appcenter.@package_list[-1].version="$VER"
uci set appcenter.@package_list[-1].url="$URL"
uci set appcenter.@package_list[-1].md5="$MD5"
uci set appcenter.@package_list[-1].has_luci="0"
uci set appcenter.@package_list[-1].type="0"

uci commit appcenter
echo "committed"

echo "== 5. 重启商店守护 =="
/etc/init.d/appcenter restart >/dev/null 2>&1
sleep 2
pidof appcenter || echo "appcenter not running"

echo "== 6. ubus 校验 =="
ubus call appcenter list 2>/dev/null | grep -c "$PKG"
ubus call appcenter list 2>/dev/null | grep -A3 -B3 "$PKG" | head -30

echo "== 7. 模拟商店下载路径 =="
code=$(curl -s -m 15 -o /tmp/kp-dl.ipk -w '%{http_code}' "$URL")
echo "download HTTP=$code"
md5sum /tmp/kp-dl.ipk
rm -f /tmp/kp-dl.ipk
echo "DONE"
