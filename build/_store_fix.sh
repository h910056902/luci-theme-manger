#!/bin/sh
# 合并重复条目：只保留一条 name/pkg_name 都是 nradio-luci-8080 的记录，
# 下载源改成本机 file://（商店守护用的是 libcurl，支持 file 协议）
PKG=nradio-luci-8080
VER=20261022-1
IPK=/www/pkgs/${PKG}_${VER}_all.ipk
MD5=$(md5sum "$IPK" | cut -d' ' -f1)
BYTES=$(wc -c < "$IPK")

echo "== 1. 删除所有同名条目 =="
i=0
while uci -q get appcenter.@package_list[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package_list[$i].name)
    if [ "$n" = "$PKG" ]; then
        uci delete appcenter.@package_list[$i]
        echo "del package_list[$i]"
        continue
    fi
    i=$((i + 1))
done
i=0
while uci -q get appcenter.@package[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package[$i].name)
    if [ "$n" = "$PKG" ]; then
        uci delete appcenter.@package[$i]
        echo "del package[$i]"
        continue
    fi
    i=$((i + 1))
done

echo "== 2. 写入单一条目 =="
uci add appcenter package >/dev/null
uci set appcenter.@package[-1].name="$PKG"
uci set appcenter.@package[-1].version="$VER"
uci set appcenter.@package[-1].des="8080 端口独立 LuCI：蜂窝网优 / 锁频 / 限速 / 主题定制"
uci set appcenter.@package[-1].size="$BYTES"
uci set appcenter.@package[-1].status="0"
uci set appcenter.@package[-1].has_luci="1"
uci set appcenter.@package[-1].open="0"

uci add appcenter package_list >/dev/null
uci set appcenter.@package_list[-1].name="$PKG"
uci set appcenter.@package_list[-1].pkg_name="$PKG"
uci set appcenter.@package_list[-1].parent="$PKG"
uci set appcenter.@package_list[-1].size="$BYTES"
uci set appcenter.@package_list[-1].version="$VER"
uci set appcenter.@package_list[-1].url="file://$IPK"
uci set appcenter.@package_list[-1].md5="$MD5"
uci set appcenter.@package_list[-1].has_luci="1"
uci set appcenter.@package_list[-1].type="0"
uci commit appcenter
echo "url=file://$IPK"

/etc/init.d/appcenter restart >/dev/null 2>&1
sleep 3

echo "== 3. ubus 结果 =="
ubus call appcenter list 2>/dev/null | grep -c "$PKG"
ubus call appcenter list 2>/dev/null | grep -A8 "\"$PKG\"" | head -30

echo "== 4. 当前安装状态 =="
opkg list-installed | grep $PKG || echo "not-installed"
echo "DONE"
