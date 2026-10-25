#!/bin/sh
F=/overlay/kp-restore-20261025-193457.ipk
T=/tmp/kpv2
rm -rf "$T"; mkdir -p "$T"
tar -xzf "$F" -C "$T"

echo "== control.tar.gz 条目 =="
tar -tzf "$T/control.tar.gz"
echo "== control 正文 =="
tar -xzOf "$T/control.tar.gz" ./control

echo "== www 资源条目数 =="
tar -tzf "$T/data.tar.gz" | grep -c 'luci-static/resources/view/openclash'
echo "== 面板 cgi 是否在包内 =="
tar -tzf "$T/data.tar.gz" | grep -c 'openwrt-luci-8080/www/cgi-bin/luci'
echo "== 面板关键页面 =="
tar -tzf "$T/data.tar.gz" | grep -E 'nradio_(details|cellular|term)\.htm' | head -5
echo "== openclash 入口文件 =="
tar -tzf "$T/data.tar.gz" | grep -E 'controller/openclash\.lua|init\.d/openclash|openclash/core' | head -5
rm -rf "$T"
echo DONE
