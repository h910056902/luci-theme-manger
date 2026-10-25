#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-anim-$TS
mkdir -p "$BAK"
for f in nradio_cellular nradio_details nradio_sms index nradio_8080_sysauth; do
	[ -f "$V/$f.htm" ] && cp "$V/$f.htm" "$BAK/$f.htm"
done
echo "BAK=$BAK"

for f in nradio_cellular nradio_details index nradio_8080_sysauth; do
	[ -f "/tmp/_up_$f.htm" ] || { echo "缺少 /tmp/_up_$f.htm"; exit 1; }
	tr -d '\r' < "/tmp/_up_$f.htm" > "/tmp/_up_$f.htm.lf" && mv "/tmp/_up_$f.htm.lf" "/tmp/_up_$f.htm"
	cp "/tmp/_up_$f.htm" "$V/$f.htm"
	chmod 644 "$V/$f.htm"
done

echo "== 落盘校验 =="
for f in nradio_cellular nradio_details index nradio_8080_sysauth; do
	echo -n "$f: size=$(wc -c < "$V/$f.htm") reduced=$(grep -c 'prefers-reduced-motion' "$V/$f.htm") "
	echo "focus=$(grep -c 'focus-visible' "$V/$f.htm")"
done

echo "== 重建终端页（body 里也带同样的动效规范）=="
[ -f /tmp/_rebuild_term2.sh ] && sh /tmp/_rebuild_term2.sh 2>&1 | tail -8

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
curl -s -o /dev/null -w "overview=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/overview
echo DONE
