#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-term-$TS
mkdir -p "$BAK"
cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
echo "BAK=$BAK"

[ -f /tmp/_up_term.htm ] || { echo "缺少 /tmp/_up_term.htm"; exit 1; }
tr -d '\r' < /tmp/_up_term.htm > /tmp/_up_term.htm.lf && mv /tmp/_up_term.htm.lf /tmp/_up_term.htm

cp /tmp/_up_term.htm "$D/usr/lib/lua/luci/view/admin_status/nradio_term.htm"
chmod 644 "$D/usr/lib/lua/luci/view/admin_status/nradio_term.htm"
cp /tmp/_up_luci "$D/www/cgi-bin/luci"
chmod 755 "$D/www/cgi-bin/luci"

echo "== 语法 =="
lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" || { echo CGI_FAIL; exit 1; }
echo SYNTAX_OK

echo "== 关闭 ttyd 的 check_origin（内嵌前提） =="
uci set ttyd.@server[0].check_origin='0'
uci commit ttyd
/etc/init.d/ttyd restart >/dev/null 2>&1
sleep 2
uci get ttyd.@server[0].check_origin
ps w | grep '/usr/bin/ttyd' | head -1 | cut -c1-140

echo "== 跨端口 WS 握手复测（应 101） =="
curl -s -i -m 6 \
	-H 'Connection: Upgrade' -H 'Upgrade: websocket' \
	-H 'Sec-WebSocket-Version: 13' \
	-H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
	-H 'Sec-WebSocket-Protocol: tty' \
	-H 'Origin: http://192.168.66.1:8080' \
	"http://192.168.66.1:7681/ws" 2>&1 | head -2

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
curl -s -o /dev/null -w "term_page=%{http_code}\n" \
	http://192.168.66.1:8080/cgi-bin/luci/admin/status/terminal
echo DONE
