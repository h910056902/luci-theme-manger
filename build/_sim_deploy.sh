#!/bin/sh
# KP-SIM-CARD v1 部署：kp_sim_card.htm(新) + nradio_details.htm + mwrt-home-custom.css + www/cgi-bin/luci
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
W=$D/www/luci-static/bootstrap/css
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-sim-$TS
mkdir -p "$BAK"
cp "$V/nradio_details.htm" "$BAK/" 2>/dev/null
cp "$V/kp_sim_card.htm" "$BAK/" 2>/dev/null
cp "$W/mwrt-home-custom.css" "$BAK/" 2>/dev/null
cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
echo "BAK=$BAK"

[ -f /tmp/_up_sim_card.htm ] || { echo "MISS /tmp/_up_sim_card.htm"; exit 1; }
[ -f /tmp/_up_details.htm ] || { echo "MISS /tmp/_up_details.htm"; exit 1; }
[ -f /tmp/_up_home.css ] || { echo "MISS /tmp/_up_home.css"; exit 1; }
[ -f /tmp/_up_luci ] || { echo "MISS /tmp/_up_luci"; exit 1; }

tr -d '\r' < /tmp/_up_sim_card.htm > "$V/kp_sim_card.htm"
tr -d '\r' < /tmp/_up_details.htm > "$V/nradio_details.htm"
tr -d '\r' < /tmp/_up_home.css > "$W/mwrt-home-custom.css"
tr -d '\r' < /tmp/_up_luci > "$D/www/cgi-bin/luci"
chmod 644 "$V/kp_sim_card.htm" "$V/nradio_details.htm" "$W/mwrt-home-custom.css"
chmod 755 "$D/www/cgi-bin/luci"

echo "== 指纹 =="
md5sum "$V/kp_sim_card.htm" "$V/nradio_details.htm" "$W/mwrt-home-custom.css" "$D/www/cgi-bin/luci" | sed 's/  */ /'
wc -c "$V/kp_sim_card.htm" "$V/nradio_details.htm" "$W/mwrt-home-custom.css" "$D/www/cgi-bin/luci"

echo "== 语法 =="
if ! lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" 2>/tmp/kpc-syntax.err; then
	echo CGI_FAIL; cat /tmp/kpc-syntax.err
	cp "$BAK/luci" "$D/www/cgi-bin/luci"; chmod 755 "$D/www/cgi-bin/luci"
	exit 1
fi
echo CGI_SYNTAX_OK

echo "== 模板块语法 =="
lua /tmp/_sim_tpl_check.lua || TPL_BAD=1

echo "== 白名单/引用 =="
echo "cgi 白名单: $(grep -c 'kp_sim_card' "$D/www/cgi-bin/luci")"
echo "details include: $(grep -c 'kp_sim_card' "$V/nradio_details.htm")"
echo "css 新类: $(grep -c 'KP-SIM-CARD' "$W/mwrt-home-custom.css")"
echo "css v=2: $(grep -c 'mwrt-home-custom.css?v=2' "$V/nradio_details.htm")"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
[ -n "$TPL_BAD" ] && { echo TPL_CHECK_FAIL; exit 1; }
echo DONE
