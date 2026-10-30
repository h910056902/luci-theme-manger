#!/bin/sh
echo "===== luci.template 的 include 语义 ====="
grep -n -B2 -A8 "function render\|include" /usr/lib/lua/luci/template.lua 2>/dev/null | head -40
echo
echo "===== 模板解析器对 <%+ 的处理 ====="
grep -n -B2 -A6 'begin_concat\|%-\?+' /usr/lib/lua/luci/template/parser.lua 2>/dev/null | head -30
echo
echo "===== 仓库与设备的 nradio_details.htm 是否一致 ====="
md5sum /overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_details.htm 2>/dev/null
