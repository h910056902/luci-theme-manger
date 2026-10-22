#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"

echo "== 1. 文件指纹 =="
md5sum "$D/www/cgi-bin/luci"
md5sum "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"

echo "== 2. cgi-bin 内容 =="
ls -l "$D/www/cgi-bin"

echo "== 3. 页面关键串 =="
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
if [ -z "$SID" ]; then echo "登录失败"; exit 1; fi
curl -s -m 15 -H "Cookie: sysauth=$SID" -o /tmp/p.html -w "page=%{http_code} size=%{size_download}\n" "$B"
echo "质量分布=$(grep -c '质量分布' /tmp/p.html)"
echo "距离估=$(grep -c '距离(估)' /tmp/p.html)"
echo "NCI=$(grep -c '小区标识 NCI' /tmp/p.html)"
echo "TA格=$(grep -c '时间提前量 TA' /tmp/p.html)"

echo "== 4. 接口 =="
curl -s -m 20 -H "Cookie: sysauth=$SID" "$B?action=cell" | head -c 260
echo
curl -s -m 20 -H "Cookie: sysauth=$SID" "$B?action=stats" | head -c 200
echo
curl -s -m 30 -H "Cookie: sysauth=$SID" "$B?action=neighbor" | head -c 260
echo

echo "== 5. 冲突检查 =="
echo -n "8080 监听数: "; netstat -lntp 2>/dev/null | grep -c ":8080"
echo -n "uhttpd 实例数: "; ps w 2>/dev/null | grep -c "[u]httpd"
echo -n "商店条目行数: "; ubus call appcenter list 2>/dev/null | grep -c nradio-luci-8080
echo -n "opkg 重复安装: "; opkg list-installed | grep -c "^nradio-luci-8080"
echo "DONE"
