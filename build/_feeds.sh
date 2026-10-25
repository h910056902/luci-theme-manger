#!/bin/sh
echo "== distfeeds =="
cat /etc/opkg/distfeeds.conf 2>/dev/null

echo "== customfeeds =="
cat /etc/opkg/customfeeds.conf 2>/dev/null || echo "  无"

echo "== iStore 配置 =="
uci show istore 2>/dev/null | head -12
cat /etc/config/istore 2>/dev/null | head -20

echo "== opkg update =="
opkg update 2>&1 | tail -6

echo "== 找 ocspeed / app-meta =="
opkg list 2>/dev/null | grep -iE 'ocspeed' | head -5 || echo "  无 ocspeed"
opkg list 2>/dev/null | grep -c '^app-meta' 
opkg list 2>/dev/null | grep -iE '^ttyd ' | head -3

echo "== 已有 app-meta 记录 =="
ls /usr/lib/opkg/info/app-meta*.list 2>/dev/null | head -5
