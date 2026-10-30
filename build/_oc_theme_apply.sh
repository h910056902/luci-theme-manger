#!/bin/sh
# 把仓库里的「固件对齐版」测速页写回设备（kp-ocspeed.sh 从 GitHub 重装后会被覆盖回原版，
# 重装完跑一次本脚本即可恢复主题）。
# 用法（设备侧）：sh /tmp/_oc_theme_apply.sh   （需先把 build/ocspeed/ocspeed.htm 传到 /tmp/_up_ocspeed.htm）
[ -f /tmp/_up_ocspeed.htm ] || { echo "MISS /tmp/_up_ocspeed.htm"; exit 1; }
cp -f /usr/lib/lua/luci/view/ocspeed.htm /tmp/ocspeed.htm.bak 2>/dev/null
tr -d '\r' < /tmp/_up_ocspeed.htm > /usr/lib/lua/luci/view/ocspeed.htm
chmod 644 /usr/lib/lua/luci/view/ocspeed.htm
grep -c 'KP-THEME v2' /usr/lib/lua/luci/view/ocspeed.htm
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
curl -s -o /dev/null -w "ocspeed page -> %{http_code}\n" "http://127.0.0.1/cgi-bin/luci/admin/services/openclash/ocspeed"
echo DONE
