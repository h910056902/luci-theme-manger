#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-menu-$TS
mkdir -p "$BAK"

cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
cp "$D/usr/lib/lua/luci/view/themes/bootstrap/header.htm" "$BAK/header.htm" 2>/dev/null
echo "BAK=$BAK"

[ -f /tmp/_up_luci ] && cp /tmp/_up_luci "$D/www/cgi-bin/luci"
[ -f /tmp/_up_header.htm ] && cp /tmp/_up_header.htm "$D/usr/lib/lua/luci/view/themes/bootstrap/header.htm"
chmod 755 "$D/www/cgi-bin/luci"
chmod 644 "$D/usr/lib/lua/luci/view/themes/bootstrap/header.htm"

if ! lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" 2>/tmp/kpc-syntax.err; then
    cp "$BAK/luci" "$D/www/cgi-bin/luci"
    cp "$BAK/header.htm" "$D/usr/lib/lua/luci/view/themes/bootstrap/header.htm"
    echo "SYNTAX_FAIL"; cat /tmp/kpc-syntax.err; exit 1
fi
echo "SYNTAX_OK"
ls -l "$D/www/cgi-bin/luci" "$D/usr/lib/lua/luci/view/themes/bootstrap/header.htm"

echo "== 菜单注入检查 =="
grep -c 'title = "概览"' "$D/www/cgi-bin/luci"
grep -c 'order = 2,' "$D/www/cgi-bin/luci"
grep -c 'cellLinks.push' "$D/usr/lib/lua/luci/view/themes/bootstrap/header.htm"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
curl -s -o /dev/null -w "overview=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/overview
echo "DONE"
