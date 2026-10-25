#!/bin/sh
BASE=https://downloads.openwrt.org/releases/21.02.7/packages/aarch64_cortex-a53/packages
cd /tmp || exit 1

echo "== 已装 libwebsockets =="
opkg list-installed 2>/dev/null | grep -i websockets || echo "  未装"

echo "== 下载 =="
curl -sL -m 60 -O "$BASE/libwebsockets-full_3.1.0-2_aarch64_cortex-a53.ipk" 2>/dev/null
curl -sL -m 60 -O "$BASE/ttyd_1.6.3-3_aarch64_cortex-a53.ipk" 2>/dev/null
ls -lh /tmp/*.ipk 2>/dev/null | tail -3

echo "== 安装依赖 =="
if ! opkg list-installed 2>/dev/null | grep -q libwebsockets; then
	opkg install /tmp/libwebsockets-full_3.1.0-2_aarch64_cortex-a53.ipk 2>&1 | tail -4
fi

echo "== 安装 ttyd =="
opkg install /tmp/ttyd_1.6.3-3_aarch64_cortex-a53.ipk 2>&1 | tail -4
command -v ttyd && ttyd --version 2>&1 | head -2

echo "== 配置 =="
uci -q get ttyd.@server[0] >/dev/null 2>&1 || uci add ttyd server >/dev/null 2>&1
uci set ttyd.@server[0].port='7681'
uci set ttyd.@server[0].interface='br-lan'
uci set ttyd.@server[0].check_origin='0'
uci set ttyd.@server[0].command='/bin/login -f root'
uci commit ttyd 2>/dev/null
uci show ttyd 2>/dev/null | head -10

echo "== 主题页 =="
ls -l /etc/ttyd/index.html 2>/dev/null || echo "  无自定义首页（用内置页）"

echo "== 启动 =="
/etc/init.d/ttyd enable 2>/dev/null
/etc/init.d/ttyd restart >/dev/null 2>&1
sleep 3
netstat -lnt 2>/dev/null | grep 7681
curl -s -o /dev/null -m 8 -w "  ttyd http: %{http_code}\n" http://192.168.66.1:7681/
