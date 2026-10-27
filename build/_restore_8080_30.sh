#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
LAN=$(uci -q get network.lan.ipaddr); [ -n "$LAN" ] || LAN=192.168.66.1

echo "== 1. kpnet 配置 =="
if [ ! -f /etc/config/kpnet ]; then
	printf "config web 'web'\n\toption listen 'auto'\n\toption port '8080'\n" > /etc/config/kpnet
	echo "  已创建 /etc/config/kpnet"
else
	echo "  已存在"
fi
uci show kpnet 2>/dev/null

echo "== 2. 部署 kp8080-listen =="
tr -d '\r' < /tmp/_up_kp8080_listen > /usr/bin/kp8080-listen
tr -d '\r' < /tmp/_up_kp8080_init   > /etc/init.d/kp8080-listen
chmod 755 /usr/bin/kp8080-listen /etc/init.d/kp8080-listen
ls -l /usr/bin/kp8080-listen /etc/init.d/kp8080-listen

echo "== 3. uhttpd 8080 实例 =="
if ! uci -q get uhttpd.openwrt8080 >/dev/null 2>&1; then
	uci set uhttpd.openwrt8080=uhttpd
	uci set uhttpd.openwrt8080.enabled=1
	uci set uhttpd.openwrt8080.listen_http="$LAN:8080"
	uci set uhttpd.openwrt8080.rfc1918_filter=1
	uci set uhttpd.openwrt8080.max_connections=20
	uci set uhttpd.openwrt8080.network_timeout=30
	uci set uhttpd.openwrt8080.http_keepalive=20
	uci set uhttpd.openwrt8080.tcp_keepalive=1
	uci set uhttpd.openwrt8080.max_requests=10
	uci set uhttpd.openwrt8080.script_timeout=3600
	uci set uhttpd.openwrt8080.home="$D/www"
	uci set uhttpd.openwrt8080.cgi_prefix=/cgi-bin
	uci commit uhttpd
	echo "  已创建实例"
else
	echo "  已存在"
fi
uci show uhttpd.openwrt8080 | head -14

echo "== 4. 重启 uhttpd =="
/etc/init.d/uhttpd restart >/dev/null 2>&1
/etc/init.d/kp8080-listen enable 2>/dev/null
/etc/init.d/kp8080-listen start >/dev/null 2>&1
sleep 2
netstat -lnt 2>/dev/null | grep -E ':80 |:8080'

echo "== 5. 探测面板 =="
curl -s -o /dev/null -m 8 -w "  /  = %{http_code}\n" "http://$LAN:8080/"
curl -s -o /dev/null -m 8 -w "  cgi= %{http_code}\n" "http://$LAN:8080/cgi-bin/luci"
curl -s -m 8 "http://$LAN:8080/cgi-bin/luci" | grep -c 'luci_password'
