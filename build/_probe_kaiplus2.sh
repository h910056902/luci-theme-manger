#!/bin/sh
echo "== /etc/config 里有没有 kaiplus =="
ls -l /etc/config/kaiplus 2>/dev/null || echo "缺失（这就是页面未注册的直接原因）"

echo "== 安装状态 =="
opkg list-installed 2>/dev/null | grep -i kai
echo "== 包内是否应带配置 =="
ls -l /usr/lib/opkg/info/luci-app-kaiplus* 2>/dev/null | head -5
grep -n 'sysupgrade\|/etc/config' /usr/lib/opkg/info/luci-app-kaiplus.conffiles 2>/dev/null

echo "== CBI 模型 =="
cat /usr/lib/lua/luci/model/cbi/kaiplus.lua 2>/dev/null

echo "== 相关服务 =="
ls -l /etc/init.d/kaiplus /usr/bin/kaiplus 2>/dev/null || echo "无 kaiplus 服务/程序"
echo "== 应用商店里的登记 =="
grep -o '"kaiplus"[^,]*' /etc/config/appcenter 2>/dev/null | head -3
