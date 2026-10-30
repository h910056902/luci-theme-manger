#!/bin/sh
echo "== 1. 五件套在位 =="
ls -l /usr/libexec/openclash-helper/speedswitch.sh /usr/lib/lua/luci/controller/ocspeed.lua \
      /usr/lib/lua/luci/view/ocspeed.htm /usr/lib/lua/luci/view/nodetest.htm /etc/config/ocspeed 2>&1
echo
echo "== 2. speedswitch status =="
/usr/libexec/openclash-helper/speedswitch.sh status 2>&1 | head -c 600
echo
echo "== 3. cron =="
crontab -l 2>/dev/null | grep -n 'ocspeed'
echo "  auto 数: $(crontab -l 2>/dev/null | grep -c '#ocspeed-auto')"
echo
echo "== 4. 页面可达（80 端口） =="
curl -s -o /dev/null -w "  80  /admin/services/openclash/ocspeed -> %{http_code}\n" "http://127.0.0.1/cgi-bin/luci/admin/services/openclash/ocspeed"
curl -s -o /dev/null -w "  8080 同路径 -> %{http_code}\n" "http://127.0.0.1:8080/cgi-bin/luci/admin/services/openclash/ocspeed"
echo
echo "== 5. 8080 驾驶舱 easter egg 指向 =="
grep -o 'ocspeed[^"]*\|openclash[^"]*' /overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_details.htm 2>/dev/null | sort -u | head -8
echo
echo "== 6. 菜单图标 =="
ls -l /www/luci-static/nradio/images/icon/ocspeed.png 2>/dev/null || echo "  icon 缺失"
grep -o 'icon/[a-z]*\.png' /usr/lib/lua/luci/controller/ocspeed.lua 2>/dev/null | head -3
echo
echo "== 7. uci 配置 =="
uci show ocspeed 2>/dev/null | head -20
echo
echo "== 8. 引擎自检：全量测速（不切组，取前 8 个节点结果） =="
/usr/libexec/openclash-helper/speedswitch.sh test >/tmp/_oc_test.out 2>&1
echo "  rc=$?"
tail -6 /var/log/ocspeed.log 2>/dev/null
echo
echo "== 9. nodes.json 是否刷新 =="
ls -l /etc/openclash-helper/nodes.json /etc/openclash-helper/status.json 2>/dev/null
head -c 200 /etc/openclash-helper/status.json 2>/dev/null; echo
