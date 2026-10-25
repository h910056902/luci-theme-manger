#!/bin/sh
echo "===== 1. 基本连通 ====="
ping -c 2 -W 3 223.5.5.5 >/dev/null 2>&1 && echo "  ICMP 223.5.5.5: 通" || echo "  ICMP 223.5.5.5: 不通"
nslookup www.baidu.com >/dev/null 2>&1 && echo "  DNS 解析: 通" || echo "  DNS 解析: 失败"
curl -s -o /dev/null -m 8 -w "  HTTP 百度: %{http_code}\n" http://www.baidu.com 2>/dev/null || echo "  HTTP 百度: 失败"

echo "===== 2. 路由 / 接口 ====="
ip -4 route 2>/dev/null | head -6
echo "--- 接口地址 ---"
ip -4 addr 2>/dev/null | grep -E '^[0-9]+:|inet ' | head -20

echo "===== 3. WAN 状态 ====="
ubus call network.interface.wan status 2>/dev/null | head -c 500
echo
echo "===== 4. 5G 数据接口 ====="
uci -q get network.wan.proto
uci -q get network.wan.device
ubus list 2>/dev/null | grep -iE 'cellular|5g|wwan|modem' | head -6

echo "===== 5. 蜂窝数据 ====="
ubus call infocd cpestatus '{"name":"cpe"}' 2>/dev/null | tr ',' '\n' | grep -E '"(isp|mode|status|ipv4|wan_ip|sim_state|sim_name)"' | head -10

echo "===== 6. 存储与面板 ====="
df -h /overlay | tail -1
ls -d /overlay/nradio-apps/openwrt-luci-8080 2>/dev/null || echo "  面板目录不存在"
ls -l /root/pkgs/*.ipk 2>/dev/null | tail -3
