#!/bin/sh
echo "== network.lan =="
uci show network.lan 2>&1
echo "== dhcp lan（地址池） =="
uci show dhcp.lan 2>&1
echo "== 谁还在引用 192.168.66 =="
grep -rl "192\.168\.66\." /etc/config 2>/dev/null
echo "-- 具体行 --"
grep -rn "192\.168\.66\." /etc/config 2>/dev/null | head -20
echo "== br-lan 地址 =="
ip -4 addr show br-lan | grep inet
echo "== 当前 8080 监听 =="
uci -q get uhttpd.openwrt8080.listen_http
echo "== kpnet.web =="
uci show kpnet 2>&1 | head -5
echo "== dhcp 租约数 =="
wc -l < /tmp/dhcp.leases 2>/dev/null || echo 0
