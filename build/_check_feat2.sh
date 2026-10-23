#!/bin/sh
echo "== ttyd 服务 =="
ls -l /etc/init.d/ttyd 2>/dev/null || echo "  无 init 脚本"
ps w 2>/dev/null | grep "[t]tyd" || echo "  ttyd 未运行"
netstat -lnt 2>/dev/null | grep 7681 || echo "  7681 未监听"

echo "== hnat debugfs =="
ls /sys/kernel/debug/hnat/ 2>/dev/null
echo "-- 尝试读取统计 --"
for f in hnat_entry all_entry cpu_reason; do
    echo "  [$f] $(wc -c < /sys/kernel/debug/hnat/$f 2>/dev/null) bytes"
done

echo "== 软件 offload =="
uci -q show firewall.@defaults[0] 2>/dev/null

echo "== 现有 kpnet 配置 =="
uci -q show kpnet 2>/dev/null

echo "== AT 白名单（现有实现） =="
grep -n "KP_AT_ALLOW\|kp_at_allow" /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci | head -5

echo "== 卡槽相关 AT 能力 =="
ubus call atsdcpe at_cmd '{"cmd":"AT+QUIMSLOT?","wait":1200,"at_log_level":0,"block":1}' 2>&1 | head -c 300
echo
ubus call atsdcpe at_cmd '{"cmd":"AT^SIMSLOT?","wait":1200,"at_log_level":0,"block":1}' 2>&1 | head -c 300
echo
