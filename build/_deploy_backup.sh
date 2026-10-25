#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)
mkdir -p /tmp/kpc-bak-$TS
cp "$D/www/cgi-bin/luci" "/tmp/kpc-bak-$TS/luci" 2>/dev/null
cp "$V/nradio_cellular.htm" "/tmp/kpc-bak-$TS/cellular.htm" 2>/dev/null
echo "备份: /tmp/kpc-bak-$TS/"

for f in /tmp/_up_luci /tmp/_up_cellular.htm; do
	[ -f "$f" ] || { echo "缺少 $f"; exit 1; }
	tr -d '\r' < "$f" > "$f.lf" && mv "$f.lf" "$f"
done

cp /tmp/_up_luci "$D/www/cgi-bin/luci"
chmod 755 "$D/www/cgi-bin/luci"
cp /tmp/_up_cellular.htm "$V/nradio_cellular.htm"
chmod 644 "$V/nradio_cellular.htm"

echo "== 语法 =="
lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" && echo SYNTAX_OK
echo "cgi=$(wc -c < "$D/www/cgi-bin/luci") cellular=$(wc -c < "$V/nradio_cellular.htm")"
echo -n "备份 action 注册: "; grep -c 'backup_full = true' "$D/www/cgi-bin/luci"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
echo DONE
