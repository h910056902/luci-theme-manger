#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"
D=/overlay/nradio-apps/openwrt-luci-8080
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
[ -n "$SID" ] || { echo "登录失败"; exit 1; }
C="Cookie: sysauth=$SID"

echo "== AT+CSQ（正确编码 + 号） =="
curl -s -m 20 -H "$C" --data-urlencode "cmd=AT+CSQ" -d "confirm=1" "$B?action=at_raw"
echo
echo "== AT^HCSQ? =="
curl -s -m 20 -H "$C" --data-urlencode "cmd=AT^HCSQ?" -d "confirm=1" "$B?action=at_raw"
echo
echo "== 模板关键串（设备端文件） =="
grep -c "网页终端" "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"
grep -c "硬件加速" "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"
grep -c "AT 高级命令" "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"
echo "== hnat debugfs 可读性 =="
head -c 40 /sys/kernel/debug/hnat/hook_toggle 2>&1; echo
head -c 60 /sys/kernel/debug/hnat/hnat_version 2>&1; echo
echo "DONE"
