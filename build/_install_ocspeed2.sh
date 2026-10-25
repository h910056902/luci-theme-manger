#!/bin/sh
echo "== 解包安装 =="
cd /tmp || exit 1
rm -rf ocsx && mkdir ocsx && cd ocsx || exit 1
tar -xzf /tmp/ocspeed.ipk ./data.tar.gz 2>/dev/null || tar -xzf /tmp/ocspeed.ipk data.tar.gz 2>/dev/null
[ -f data.tar.gz ] || { echo "  内层 data.tar.gz 解出失败"; ls -la /tmp/ocsx; exit 1; }
tar -tzf data.tar.gz 2>/dev/null | head -10

# 保留用户已有 /etc/config/ocspeed，其余文件覆盖
tar -xzf data.tar.gz -C / \
	./usr/libexec/openclash-helper/speedswitch.sh \
	./usr/lib/lua/luci/controller/ocspeed.lua \
	./usr/lib/lua/luci/view/ocspeed.htm \
	./usr/lib/lua/luci/view/nodetest.htm \
	./usr/share/rpcd/acl.d/luci-app-ocspeed.json 2>&1 | head -3

chmod 755 /usr/libexec/openclash-helper/speedswitch.sh
chmod 644 /usr/lib/lua/luci/controller/ocspeed.lua \
          /usr/lib/lua/luci/view/ocspeed.htm \
          /usr/lib/lua/luci/view/nodetest.htm

echo "== 落盘校验 =="
for f in /usr/libexec/openclash-helper/speedswitch.sh \
         /usr/lib/lua/luci/controller/ocspeed.lua \
         /usr/lib/lua/luci/view/ocspeed.htm \
         /usr/lib/lua/luci/view/nodetest.htm \
         /usr/share/rpcd/acl.d/luci-app-ocspeed.json; do
	[ -f "$f" ] && printf "  OK   %8s  %s\n" "$(wc -c < "$f")" "$f" || printf "  MISS %s\n" "$f"
done

echo "== 语法检查 =="
lua -e "assert(loadfile('/usr/lib/lua/luci/controller/ocspeed.lua'))" && echo "  controller OK"
sh -n /usr/libexec/openclash-helper/speedswitch.sh && echo "  speedswitch OK"

echo "== 配置组 =="
uci set ocspeed.main.group='宝贝云'
uci commit ocspeed
uci -q get ocspeed.main.group

echo "== 启用定时任务 =="
/usr/libexec/openclash-helper/speedswitch.sh enable 2>&1 | tail -4
crontab -l 2>/dev/null | grep -i ocspeed

echo "== 清缓存 =="
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache /tmp/luci-indexcache-bootstrap
/etc/init.d/uhttpd restart >/dev/null 2>&1
/etc/init.d/cron restart >/dev/null 2>&1
sleep 2
echo -n "  页面: "
curl -s -o /dev/null -m 10 -w "%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/services/openclash/ocspeed
rm -rf /tmp/ocsx
