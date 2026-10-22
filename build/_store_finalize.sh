#!/bin/sh
# 收尾：只保留一条商店记录（type=1、status=1 表示本地已安装），并做最终校验
PKG=nradio-luci-8080
VER=20261022-1
FILE=${PKG}_${VER}_all.ipk
HOSTIP=192.168.66.1
SRC=/root/pkgs/${FILE}
URL="http://${HOSTIP}/nradio-appstore/all/${PKG}/${VER}/${FILE}"
MD5=$(md5sum "$SRC" | cut -d' ' -f1)
BYTES=$(wc -c < "$SRC")

echo "== 1. 确保托管文件 =="
mkdir -p "/www/nradio-appstore/all/${PKG}/${VER}"
cp "$SRC" "/www/nradio-appstore/all/${PKG}/${VER}/${FILE}"
cp "$SRC" "/www/pkgs/${FILE}"
curl -s -m 8 -o /dev/null -w "url=%{http_code}\n" "$URL"

echo "== 2. 清空同名条目 =="
i=0
while uci -q get appcenter.@package_list[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package_list[$i].name)
    if [ "$n" = "$PKG" ]; then uci delete appcenter.@package_list[$i]; echo "del list[$i]"; continue; fi
    i=$((i + 1))
done
i=0
while uci -q get appcenter.@package[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package[$i].name)
    if [ "$n" = "$PKG" ]; then uci delete appcenter.@package[$i]; echo "del pkg[$i]"; continue; fi
    i=$((i + 1))
done

echo "== 3. 写入单条已安装记录 =="
uci add appcenter package >/dev/null
uci set appcenter.@package[-1].name="$PKG"
uci set appcenter.@package[-1].version="$VER"
uci set appcenter.@package[-1].des="8080 端口独立 LuCI：蜂窝网优 / 锁频 / 限速 / 主题定制"
uci set appcenter.@package[-1].size="$BYTES"
uci set appcenter.@package[-1].status="1"
uci set appcenter.@package[-1].has_luci="1"
uci set appcenter.@package[-1].open="0"

uci add appcenter package_list >/dev/null
uci set appcenter.@package_list[-1].name="$PKG"
uci set appcenter.@package_list[-1].pkg_name="$PKG"
uci set appcenter.@package_list[-1].parent="$PKG"
uci set appcenter.@package_list[-1].size="$BYTES"
uci set appcenter.@package_list[-1].version="$VER"
uci set appcenter.@package_list[-1].url="$URL"
uci set appcenter.@package_list[-1].md5="$MD5"
uci set appcenter.@package_list[-1].has_luci="1"
uci set appcenter.@package_list[-1].type="1"
uci commit appcenter
/etc/init.d/appcenter restart >/dev/null 2>&1
sleep 3

echo "== 4. 最终校验 =="
echo "-- opkg --"
opkg list-installed | grep $PKG || echo "NOT-INSTALLED"
echo "-- 商店条目数 --"
ubus call appcenter list 2>/dev/null | grep -c "$PKG"
echo "-- 状态 --"
ubus call appcenter list 2>/dev/null | grep -A6 "\"$PKG\"" | grep -E '"name"|"status"|"type"' | head -6
echo "-- 8080 --"
curl -s -m 10 -o /dev/null -w "root=%{http_code}\n" "http://${HOSTIP}:8080/"
curl -s -m 10 -o /dev/null -w "login=%{http_code}\n" "http://${HOSTIP}:8080/cgi-bin/luci"
curl -s -m 10 -o /dev/null -w "details=%{http_code}\n" "http://${HOSTIP}:8080/cgi-bin/luci/admin/status/details"
curl -s -m 10 -o /dev/null -w "cellular=%{http_code}\n" "http://${HOSTIP}:8080/cgi-bin/luci/admin/status/cellular"
echo "-- 文件 --"
ls -l "/www/nradio-appstore/all/${PKG}/${VER}/${FILE}"
md5sum "$SRC"
echo "MD5=$MD5"
echo "DONE"
