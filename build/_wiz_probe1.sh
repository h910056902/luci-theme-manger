#!/bin/sh
echo "== 1. infocd ubus 方法（找 SIM/线路切换 API） =="
ubus -v list infocd 2>/dev/null | grep -E '^\s+"' | head -30
echo
echo "== 2. nrswitch / 相关可执行 =="
which nrswitch 2>/dev/null; ls /usr/bin/ /usr/sbin/ 2>/dev/null | grep -iE 'nrswitch|sim|cpe|switch' | head -10
echo
echo "== 3. mwrt-wifi 是否已部署 8080 =="
ls -la /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/ 2>/dev/null
echo
echo "== 4. OpenClash 版本与脚本 =="
ls /usr/share/openclash/*.sh 2>/dev/null | head -12
opkg list-installed 2>/dev/null | grep -i openclash || apk list --installed 2>/dev/null | grep -i openclash | head -3
echo
echo "== 5. OpenClash 订阅相关 uci =="
uci show openclash 2>/dev/null | grep -iE 'subscribe|config_update|auto_update' | head -15
echo
echo "== 6. OpenClash 配置文件目录 =="
ls /etc/openclash/config/ 2>/dev/null | head -8
echo
echo "== 7. wireless 配置结构 =="
uci show wireless 2>/dev/null | grep -E 'wifi-(device|iface)|\.ssid|\.device=|\.encryption|\.key|\.disabled|\.mode' | head -30
