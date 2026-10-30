#!/bin/sh
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_details.htm
echo "===== 轮询端点触发条件（440-465 行）====="
sed -n '440,465p' "$F"
echo
echo "===== JS 里 fetch 的 URL（1040-1065 行）====="
sed -n '1040,1065p' "$F"
echo
echo "===== nrswitch 是不是双卡切换（方法签名再看一眼 + 调用方）====="
ubus -v list nrswitch 2>/dev/null
grep -rn 'nrswitch' /usr/lib/lua/luci/ /usr/sbin/ 2>/dev/null | grep -v Binary | head -5
