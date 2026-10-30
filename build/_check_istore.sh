#!/bin/sh
echo "===== 1. 80 端口：登录 + 取商店页 ====="
rm -f /tmp/c80.ck
curl -s -c /tmp/c80.ck -o /dev/null -d 'luci_username=root&luci_password=admin' http://127.0.0.1/cgi-bin/luci/
curl -s -b /tmp/c80.ck -m 20 -o /tmp/s80.html -w "  /admin/store/pages http=%{http_code} size=%{size_download}\n" http://127.0.0.1/cgi-bin/luci/admin/store/pages
grep -o 'window.device_id *= *{[^}]*}' /tmp/s80.html | head -1
echo "  页面是否含 vue 挂载点: $(grep -c 'id="app"' /tmp/s80.html)"
echo "  商店 API 连通性:"
curl -s -b /tmp/c80.ck -m 20 -o /tmp/api.json -w "    /admin/store/data http=%{http_code} size=%{size_download}\n" "http://127.0.0.1/cgi-bin/luci/admin/store/data?page=1&size=5&keyword=" 2>&1
head -c 300 /tmp/api.json 2>/dev/null; echo

echo
echo "===== 2. 8080 端口：登录 + 取商店页 ====="
rm -f /tmp/c8080.ck
curl -s -c /tmp/c8080.ck -o /dev/null -d 'luci_username=root&luci_password=admin' http://192.168.66.1:8080/cgi-bin/luci/
curl -s -b /tmp/c8080.ck -m 20 -o /tmp/s8080.html -w "  /admin/store/pages http=%{http_code} size=%{size_download}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/store/pages
grep -o 'window.device_id *= *{[^}]*}' /tmp/s8080.html | head -1
echo "  页面是否含 vue 挂载点: $(grep -c 'id="app"' /tmp/s8080.html)"
curl -s -b /tmp/c8080.ck -m 20 -o /tmp/api2.json -w "    /admin/store/data http=%{http_code} size=%{size_download}\n" "http://192.168.66.1:8080/cgi-bin/luci/admin/store/data?page=1&size=5&keyword=" 2>&1
head -c 300 /tmp/api2.json 2>/dev/null; echo

echo
echo "===== 3. 8080 侧栏菜单来源 ====="
grep -rl 'iStore' /usr/share/luci/menu.d/ /usr/lib/lua/luci/controller/store.lua 2>/dev/null | head -5
echo "-- store.lua 里的 entry --"
grep -n 'entry(' /usr/lib/lua/luci/controller/store.lua 2>/dev/null | head -5

echo
echo "===== 4. 80 端口商店前端真实数据源 ====="
grep -o 'istore.istoreos.com[^"'\'' ]*' /tmp/s80.html 2>/dev/null | head -3
echo "-- device_id 内容 --"
cat /etc/.app_store.id 2>/dev/null; echo
