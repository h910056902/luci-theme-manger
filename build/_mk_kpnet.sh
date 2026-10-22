#!/bin/sh
# 本固件的 uci 不能用 set 新建配置文件，必须手工落一份骨架
cat > /etc/config/kpnet <<'EOF'
config web 'web'
	option listen 'auto'
	option port '8080'
EOF

echo "== 文件 =="
cat /etc/config/kpnet
echo "== uci =="
uci show kpnet 2>&1

echo "== resolve（应为 LAN:8080） =="
/usr/bin/kp8080-listen resolve

echo "== 切 all =="
uci set kpnet.web.listen='all'
uci commit kpnet
/usr/bin/kp8080-listen apply
sleep 1
uci -q get uhttpd.openwrt8080.listen_http
netstat -lnt 2>/dev/null | grep 8080

echo "== 切回 auto =="
uci set kpnet.web.listen='auto'
uci commit kpnet
/usr/bin/kp8080-listen apply
sleep 1
uci -q get uhttpd.openwrt8080.listen_http
netstat -lnt 2>/dev/null | grep 8080
echo "DONE"
