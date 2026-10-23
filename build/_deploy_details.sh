#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-details-$TS.tgz

tar -czf "$BAK" -C "$D" nradio_details.htm 2>/dev/null
echo "BAK=$BAK"

[ -f /tmp/_up_details.htm ] || { echo "缺少 /tmp/_up_details.htm"; exit 1; }
cp /tmp/_up_details.htm "$D/nradio_details.htm"
chmod 644 "$D/nradio_details.htm"
ls -l "$D/nradio_details.htm"
grep -c "本月" "$D/nradio_details.htm"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/details"
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
echo "== refresh 接口里的流量字段 =="
curl -s -m 20 -H "Cookie: sysauth=$SID" "$B?refresh=1" | head -c 700
echo
echo "DONE"
