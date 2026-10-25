#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)
cp "$V/nradio_device.htm" "/tmp/kpc-device-$TS.htm" 2>/dev/null
echo "备份: /tmp/kpc-device-$TS.htm"

[ -f /tmp/_up_device.htm ] || { echo "缺少上传文件"; exit 1; }
tr -d '\r' < /tmp/_up_device.htm > /tmp/_up_device.htm.lf && mv /tmp/_up_device.htm.lf /tmp/_up_device.htm
cp /tmp/_up_device.htm "$V/nradio_device.htm"
chmod 644 "$V/nradio_device.htm"

echo "== 落盘校验 =="
echo "size=$(wc -c < "$V/nradio_device.htm")"
echo -n "kpd-kpi 出现: "; grep -c 'kpd-kpi' "$V/nradio_device.htm"
echo -n "旧 kpc-cell 概览残留: "; grep -c 'kpc-hd' "$V/nradio_device.htm" || true
echo -n "Lua 标签配对: "; echo "$(grep -o '<%' "$V/nradio_device.htm" | wc -l)/$(grep -o '%>' "$V/nradio_device.htm" | wc -l)"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
curl -s -o /dev/null -w "device_page=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/device
echo DONE
