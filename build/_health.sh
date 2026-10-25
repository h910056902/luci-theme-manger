#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080

echo "===== 1. 系统 ====="
echo "型号: $(cat /tmp/sysinfo/model 2>/dev/null)"
echo "主机名: $(cat /proc/sys/kernel/hostname)"
echo "固件: $(. /etc/openwrt_release 2>/dev/null; echo -n "$DISTRIB_DESCRIPTION")"
echo "内核: $(uname -r)  架构: $(uname -m)"
echo "运行: $(awk '{printf "%d 天 %d 小时 %d 分", $1/86400, ($1%86400)/3600, ($1%3600)/60}' /proc/uptime)"
echo "负载: $(cat /proc/loadavg | cut -d' ' -f1-3)"
echo "CPU: $(grep -c ^processor /proc/cpuinfo) 核"

echo
echo "===== 2. 内存 / 存储 ====="
awk '/MemTotal|MemAvailable|SwapTotal|SwapFree/{printf "%-14s %8.1f MB\n", $1, $2/1024}' /proc/meminfo
echo "--- 挂载 ---"
df -h | awk 'NR==1 || /overlay|mnt|tmpfs/'

echo
echo "===== 3. swap ====="
if [ -s /proc/swaps ] && [ "$(wc -l < /proc/swaps)" -gt 1 ]; then
	cat /proc/swaps
else
	echo "无 swap"
fi
echo "swappiness: $(cat /proc/sys/vm/swappiness)"
ls -l /overlay/swapfile 2>/dev/null || echo "swap 文件不存在"
[ -f /tmp/kpswap.busy ] && echo "⚠ swap 生成任务进行中" || true

echo
echo "===== 4. 网络 ====="
echo "LAN: $(uci -q get network.lan.ipaddr)"
echo "WAN: $(uci -q get network.wan.proto)  地址: $(ip -4 addr show br-lan 2>/dev/null | grep -o 'inet [0-9.]*' | head -1 | cut -d' ' -f2)"
ip -4 route 2>/dev/null | grep default | head -2
echo "DNS: $(uci -q get network.wan.dns | head -c 60)"
echo "--- 接口 ---"
ip -o link 2>/dev/null | awk '{print $2, $9}' | grep -E '^(br-lan|eth|wlan|apcli|wwan)' | head -10

echo
echo "===== 5. 蜂窝 ====="
ubus call infocd cpestatus '{"name":"cpe"}' 2>/dev/null | tr ',' '\n' | grep -E '"(isp|mode|band|rsrp|rsrq|sinr|status|sim_name|sim_mon|model_temp)"' | head -12

echo
echo "===== 6. 服务 ====="
for s in uhttpd ttyd openclash kpsmsfwd dockerd clash; do
	pid=$(pidof $s 2>/dev/null | cut -d' ' -f1)
	[ -n "$pid" ] && echo "  $s: PID $pid" || echo "  $s: 未运行"
done
echo "--- 监听端口 ---"
netstat -lnt 2>/dev/null | awk '/LISTEN/{print "  " $4}' | sort -u | head -12

echo
echo "===== 7. 8080 面板 ====="
echo "CGI: $(wc -c < "$D/www/cgi-bin/luci" 2>/dev/null) B   $(ls -l "$D/www/cgi-bin/luci" 2>/dev/null | awk '{print $6,$7,$8}')"
for f in nradio_details nradio_cellular nradio_device nradio_term index; do
	p="$D/usr/lib/lua/luci/view/admin_status/$f.htm"
	[ -f "$p" ] && echo "  $f: $(wc -c < "$p") B"
done
echo "实例目录: $(du -sm "$D" 2>/dev/null | cut -f1) MB"
echo "备份文件数: $(ls -d "$D"/theme-backup* 2>/dev/null | wc -l)"

echo
echo "===== 8. ttyd 终端 ====="
uci -q get ttyd.@server[0].port 2>/dev/null | sed 's/^/  端口: /'
echo "  check_origin: $(uci -q get ttyd.@server[0].check_origin 2>/dev/null)"
echo "  主题页: $(ls -l /etc/ttyd/index.html 2>/dev/null | awk '{print $5" B"}')"

echo
echo "===== 9. 插件 / 备份 ====="
echo "已装包: $(opkg list-installed 2>/dev/null | wc -l)"
echo "kp-backup (备份恢复包): $(opkg list-installed 2>/dev/null | grep -c '^kp-backup')"
echo "kp-restore 清单: $([ -f /etc/kp-restore/packages.txt ] && wc -l < /etc/kp-restore/packages.txt || echo 未安装)"
echo "/tmp 备份文件: $(ls /tmp/kp-backup-* 2>/dev/null | wc -l) 个"
echo "keep.d 条目: $(cat /lib/upgrade/keep.d/nradio-luci-8080 2>/dev/null | grep -c '^/')"

echo
echo "===== 10. 温度 ====="
for z in /sys/class/thermal/thermal_zone*/temp; do
	[ -f "$z" ] || continue
	t=$(cat "$z" 2>/dev/null)
	echo "  $(dirname $z | xargs basename): $((t/1000)) °C"
done 2>/dev/null | head -5

echo
echo "===== 11. 最近错误日志 ====="
logread 2>/dev/null | grep -iE 'error|fail|crash|segfault' | tail -5 || echo "  无"
