#!/bin/sh
echo "===== 1. 真实代理端口测试（config 是 mixed-port 7893）====="
for p in 7893 7890; do
  curl -s -m 8 -x "http://127.0.0.1:$p" -o /dev/null -w "  127.0.0.1:$p -> %{http_code} (%{time_total}s)\n" https://www.gstatic.com/generate_204 2>&1
done
echo "-- 本机代理开关 --"
uci get openclash.config.router_self_proxy 2>/dev/null || echo "(未设置)"
uci get openclash.config.en_mode 2>/dev/null
uci get openclash.config.proxy_port 2>/dev/null
echo "-- netstat 全量 78xx/90xx --"
netstat -lnp 2>/dev/null | grep -E ':(78[0-9]{2}|909[01])' | awk '{print $4}' | sort -u
echo
echo "===== 2. 谁在管时间（ntp 被关了但时间是准的）====="
grep -rn 'date\|ntp\|timesync' /etc/rc.local 2>/dev/null | head -3
pgrep -af 'combo|report_proactively' 2>/dev/null | head -3
strings /usr/sbin/combo 2>/dev/null | grep -iE 'ntp|time\.baidu|aliyun.*time|ntp.*aliyun' | head -5
echo "-- 当前时钟源偏差参考 --"
echo "  uptime: $(cut -d. -f1 /proc/uptime)s"
echo "  boot 时间戳: $(date -d @$(awk '{print $1}' /proc/uptime | cut -d. -f1) 2>/dev/null || echo '-')"
echo
echo "===== 3. OpenClash 配置一致性（避免下次重启变样）===="
uci show openclash 2>/dev/null | grep -E 'config_path|core_version|enable_redirect_dns|dns_port|en_mode|proxy_mode|stack_type' | head -8
ls -l /etc/openclash/*.yaml 2>/dev/null | head -4
echo "-- 当前运行配置是 --"
ps w | grep '[c]lash -d' | grep -o '\-f [^ ]*'
echo
echo "===== 4. 内存压力测试（swap 真实可用性）===="
free -m | tail -1
echo "  /proc/swaps:"
cat /proc/swaps
echo "  最近一次 swap 相关内核告警:"
dmesg 2>/dev/null | grep -i swap | tail -3
echo
echo "===== 5. 8080 面板主题管理器备份源（根治 theme-backup 堆积）===="
grep -rln 'theme-backup' /overlay/nradio-apps/openwrt-luci-8080/ 2>/dev/null | head -5
grep -rln 'theme-backup' /usr/lib/lua/luci/ 2>/dev/null | head -5
