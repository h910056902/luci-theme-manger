#!/bin/sh
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_details.htm
echo "===== 1. live/hero 全部字段赋值（200-260 行）====="
sed -n '200,260p' "$F"
echo
echo "===== 2. hero 区（460-545 行）====="
sed -n '460,545p' "$F"
echo
echo "===== 3. hero 卡片的 HTML 渲染（含 hero_ 变量的模板段）====="
grep -n 'hero_' "$F" | sed -n '10,40p'
