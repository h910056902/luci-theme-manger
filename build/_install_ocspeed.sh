#!/bin/sh
echo "== 1. 移除临时实现 =="
[ -x /etc/init.d/ocspeed ] && /etc/init.d/ocspeed disable 2>/dev/null
pkill -f '/usr/bin/lua /usr/bin/ocspeed' 2>/dev/null
rm -f /etc/init.d/ocspeed /usr/bin/ocspeed
sed -i '/ocspeed/d' /etc/crontabs/root 2>/dev/null || true
echo "  已清理"

echo "== 2. 安装官方 ipk =="
opkg install --force-depends /tmp/ocspeed.ipk 2>&1 | tail -6

echo "== 3. 落盘校验 =="
ls -l /usr/libexec/openclash-helper/speedswitch.sh \
      /usr/lib/lua/luci/controller/ocspeed.lua \
      /usr/lib/lua/luci/view/ocspeed.htm \
      /usr/lib/lua/luci/view/nodetest.htm \
      /etc/config/ocspeed 2>/dev/null | awk '{print "  "$5" "$9}'

echo "== 4. 配置策略组 =="
uci set ocspeed.main.group='宝贝云'
uci set ocspeed.main.enabled='1'
uci commit ocspeed
uci show ocspeed | grep -E 'group|enabled|interval|threshold' | head -6

echo "== 5. 启用定时任务 =="
[ -x /usr/libexec/openclash-helper/speedswitch.sh ] && /usr/libexec/openclash-helper/speedswitch.sh enable 2>&1 | tail -3
crontab -l 2>/dev/null | grep -i ocspeed | head -5

echo "== 6. 清缓存并重启 =="
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
/etc/init.d/cron restart >/dev/null 2>&1
sleep 2

echo "== 7. 控制器是否进树 =="
grep -o 'admin/services/openclash/ocspeed' /tmp/luci-indexcache* 2>/dev/null | head -2
echo -n "  页面状态: "
curl -s -o /dev/null -m 8 -w "%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/services/openclash/ocspeed
