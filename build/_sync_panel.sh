#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)
mkdir -p /tmp/kpc-sync-$TS
cp "$D/www/cgi-bin/luci" "/tmp/kpc-sync-$TS/luci" 2>/dev/null
cp "$V/nradio_cellular.htm" "/tmp/kpc-sync-$TS/cellular.htm" 2>/dev/null
echo "备份: /tmp/kpc-sync-$TS/"

for f in /tmp/_up_luci /tmp/_up_cellular.htm; do
	[ -f "$f" ] || { echo "缺少 $f"; exit 1; }
	tr -d '\r' < "$f" > "$f.lf" && mv "$f.lf" "$f"
done

cp /tmp/_up_luci "$D/www/cgi-bin/luci"
chmod 755 "$D/www/cgi-bin/luci"
cp /tmp/_up_cellular.htm "$V/nradio_cellular.htm"
chmod 644 "$V/nradio_cellular.htm"

echo "== 校验 =="
echo "cgi=$(wc -c < "$D/www/cgi-bin/luci")  cellular=$(wc -c < "$V/nradio_cellular.htm")"
echo -n "pkg_restore 动作: "; grep -c 'pkg_restore = true' "$D/www/cgi-bin/luci"
echo -n "在线恢复卡片: "; grep -c 'kp-pr-start' "$V/nradio_cellular.htm"
lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" && echo "LUA_SYNTAX_OK"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
curl -s -o /dev/null -w "8080=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci --max-time 8
