#!/bin/sh
# 只读诊断：无线为什么不可用。不修改任何配置。
echo "=== uptime ==="
uptime
echo "=== release ==="
head -4 /etc/openwrt_release

echo "=== uci wireless (已隐藏密钥) ==="
uci show wireless 2>/dev/null | grep -vE "key|psk|sae|password|wep" || echo "uci show wireless 为空"

echo "=== wifi status ==="
wifi status 2>&1 | head -40

echo "=== ubus network.wireless ==="
ubus call network.wireless status 2>/dev/null | head -80

echo "=== 无线接口 iwinfo ==="
for d in /sys/class/net/*; do
    n=$(basename "$d")
    if [ -d "$d/wireless" ]; then
        echo "--- $n ---"
        iwinfo "$n" info 2>&1 | head -8
    fi
done

echo "=== 无线类型接口（含未创建成功的） ==="
ls /sys/class/ieee80211 2>/dev/null || echo "no ieee80211"

echo "=== hostapd / wpa_supplicant ==="
ps w 2>/dev/null | grep -E "hostapd|wpa_supplicant|wpa_supp" | grep -v grep || echo "未运行"

echo "=== 网桥 ==="
brctl show 2>/dev/null || bridge link 2>/dev/null || echo "no brctl"

echo "=== 无线内核/驱动日志 ==="
logread 2>/dev/null | grep -iE "wifi|hostapd|wlan|80211|ra[0-9]|rai|ath|mt76|wpa|dfs" | tail -50

echo "=== dmesg 尾部 ==="
dmesg 2>/dev/null | tail -25

echo "=== 无线进程/文件检查 ==="
ls -l /var/run/hostapd* 2>/dev/null || echo "无 hostapd 运行时文件"
uci -q get wireless.@wifi-device[0].disabled; echo "(上行为 radio0.disabled)"
uci -q get wireless.@wifi-iface[0].disabled; echo "(上行为 iface0.disabled)"
uci -q get wireless.@wifi-iface[0].network; echo "(上行为 iface0.network)"
