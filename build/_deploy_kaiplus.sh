#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
TS=$(date +%Y%m%d-%H%M%S)
cp "$D/www/cgi-bin/luci" "/tmp/kpc-kaiplus-$TS.luci" 2>/dev/null
echo "备份: /tmp/kpc-kaiplus-$TS.luci"

tr -d '\r' < /tmp/_up_luci > /tmp/_up_luci.lf && mv /tmp/_up_luci.lf /tmp/_up_luci
cp /tmp/_up_luci "$D/www/cgi-bin/luci"
chmod 755 "$D/www/cgi-bin/luci"

echo "== 语法 =="
lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" || { echo CGI_FAIL; exit 1; }
echo SYNTAX_OK

echo "== 模拟「装了新插件」：把控制器目录 mtime 推新 =="
ls -l /tmp/luci-indexcache-bootstrap 2>/dev/null
touch /usr/lib/lua/luci/controller/_kptest.lua 2>/dev/null
rm -f /usr/lib/lua/luci/controller/_kptest.lua
sleep 1

echo "== 触发请求（应自动删缓存并重建）=="
curl -s -o /dev/null -m 12 "http://192.168.66.1:8080/cgi-bin/luci/admin/status/overview"
sleep 1
ls -l /tmp/luci-indexcache-bootstrap 2>/dev/null
echo -n "缓存内 kaiplus 命中: "; grep -o kaiplus /tmp/luci-indexcache-bootstrap 2>/dev/null | wc -l

echo "== kaiplus 页面 =="
curl -s -o /tmp/kp2.html -w "code=%{http_code} size=%{size_download}\n" -m 12 \
	"http://192.168.66.1:8080/cgi-bin/luci/admin/services/kaiplus"
echo -n "未注册提示: "; grep -c 'no page is registered\|未注册' /tmp/kp2.html
echo DONE
