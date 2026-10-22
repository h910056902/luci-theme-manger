#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080

echo "== 1. 包状态 =="
opkg list-installed | grep nradio-luci-8080 || echo "未安装"

echo "== 2. www 内容 =="
ls -la "$D/www"
echo "-- index.html 是否还在 --"
ls -l "$D/www/index.html" 2>/dev/null || echo "无 index.html"

echo "== 3. 悬空符号链接 =="
find "$D" -xtype l 2>/dev/null | head -20
echo "(以上为空表示无悬空链接)"

echo "== 4. 8080 监听与进程 =="
netstat -lntp 2>/dev/null | grep 8080
ps w 2>/dev/null | grep "uhttpd" | grep -v grep

echo "== 5. uhttpd 配置 =="
uci show uhttpd.openwrt8080 2>/dev/null

echo "== 6. 商店残留 =="
ubus call appcenter list 2>/dev/null | grep -c "nradio-luci-8080"

echo "== 7. 根路径实际返回 =="
curl -s -m 8 http://192.168.66.1:8080/ -o /tmp/root.html -w "code=%{http_code} size=%{size_download}\n"
head -c 300 /tmp/root.html
echo
rm -f /tmp/root.html
echo "DONE"
