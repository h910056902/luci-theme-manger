#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-ov-$TS
mkdir -p "$BAK"

cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
cp "$D/usr/lib/lua/luci/view/admin_status/index.htm" "$BAK/index.htm" 2>/dev/null
echo "BAK=$BAK"

[ -f /tmp/_up_luci ] && cp /tmp/_up_luci "$D/www/cgi-bin/luci"
[ -f /tmp/_up_index.htm ] && cp /tmp/_up_index.htm "$D/usr/lib/lua/luci/view/admin_status/index.htm"
chmod 755 "$D/www/cgi-bin/luci"
chmod 644 "$D/usr/lib/lua/luci/view/admin_status/index.htm"

if ! lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" 2>/tmp/kpc-syntax.err; then
    cp "$BAK/luci" "$D/www/cgi-bin/luci"
    cp "$BAK/index.htm" "$D/usr/lib/lua/luci/view/admin_status/index.htm"
    echo "SYNTAX_FAIL"; cat /tmp/kpc-syntax.err; exit 1
fi
echo "SYNTAX_OK"
ls -l "$D/www/cgi-bin/luci" "$D/usr/lib/lua/luci/view/admin_status/index.htm"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache /tmp/kp-status.json
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
echo "== kp_status.cell =="
curl -s -m 20 -H "Cookie: sysauth=$SID" "http://192.168.66.1:8080/cgi-bin/luci/admin/status/overview?action=kp_status" \
    | tr ',' '\n' | grep -E '"(isp|operator|mode|band|pci|tac|cqi|rsrp|sinr|temp|mon|model|revision|imei|iccid|simno)"' | head -20
echo "DONE"
