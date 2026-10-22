#!/bin/sh
echo "== cpestatus 里的流量字段 =="
ubus call infocd cpestatus '{"name":"cpe"}' 2>/dev/null | grep -E '"(traffic|device_traffic|upload|download|sim_flow|sim_mon|flow_dl|flow_ul|mon_flow|total_flow)"' | head -20

echo "== 代码里用的字段 =="
grep -n 'flow_dl\|flow_ul\|mon_flow\|total_flow' /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci | head -10
grep -n 'flow_dl\|flow_ul\|mon_flow\|total_flow' /overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm | head -10
