#!/bin/sh
echo "== 二进制 =="
for b in ttyd sendat webuiserver cu microcom; do
    p=$(which $b 2>/dev/null)
    echo "  $b: ${p:-无}"
done

echo "== turboacc =="
ls -l /etc/config/turboacc /etc/init.d/turboacc 2>/dev/null || echo "  无 turboacc"
uci -q show turboacc 2>&1 | head -12

echo "== HNAT =="
lsmod 2>/dev/null | grep -i hnat || echo "  无 hnat 模块"
ls /sys/kernel/debug/hnat 2>/dev/null | head -5 || echo "  无 hnat debugfs"
ls /proc/mtk_hnat 2>/dev/null || echo "  无 /proc/mtk_hnat"

echo "== qmodem =="
ls -l /etc/config/qmodem 2>/dev/null || echo "  无 qmodem 配置"
uci -q show qmodem 2>&1 | head -10

echo "== AT 相关 ubus =="
ubus list 2>/dev/null | grep -iE 'at|modem|sms' | head -15

echo "== ttyd 配置 =="
uci -q show ttyd 2>&1 | head -8

echo "== 串口 =="
ls -l /dev/ttyUSB* 2>/dev/null | head -5
