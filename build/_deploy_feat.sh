#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-feat-$TS
mkdir -p "$BAK"

echo "uptime: $(uptime 2>/dev/null | sed 's/.*up //')"

cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
cp "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm" "$BAK/cellular.htm" 2>/dev/null
echo "BAK=$BAK"

[ -f /tmp/_up_luci ] || { echo "缺少 /tmp/_up_luci"; exit 1; }
[ -f /tmp/_up_cellular.htm ] || { echo "缺少 /tmp/_up_cellular.htm"; exit 1; }

cp /tmp/_up_luci "$D/www/cgi-bin/luci"
cp /tmp/_up_cellular.htm "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"
chmod 755 "$D/www/cgi-bin/luci"
chmod 644 "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"

if ! lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" 2>/tmp/kpc-syntax.err; then
    cp "$BAK/luci" "$D/www/cgi-bin/luci"
    cp "$BAK/cellular.htm" "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"
    echo "SYNTAX_FAIL"; cat /tmp/kpc-syntax.err; exit 1
fi
echo "SYNTAX_OK"
ls -l "$D/www/cgi-bin/luci" "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
echo "DONE"
