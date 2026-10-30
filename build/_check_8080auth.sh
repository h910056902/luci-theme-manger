#!/bin/sh
H=192.168.66.1
echo "===== 8080 登录流程细节 ====="
rm -f /tmp/a8.ck
echo "-- 1) GET 登录页，看表单 --"
curl -s -c /tmp/a8.ck -m 10 -o /tmp/l8.html -w "  login page http=%{http_code}\n" "http://$H:8080/cgi-bin/luci/"
grep -o 'name="[a-z_]*"' /tmp/l8.html | sort -u | head -6
echo "-- 2) POST 登录 --"
curl -s -b /tmp/a8.ck -c /tmp/a8.ck -m 10 -o /dev/null -w "  post http=%{http_code} redirect=%{redirect_url}\n" -d 'luci_username=root&luci_password=admin' "http://$H:8080/cgi-bin/luci/"
echo "-- 3) cookie 内容 --"
cat /tmp/a8.ck | grep -v '^#' | head -5
echo "-- 4) 用 cookie 访问 8080 首页 --"
curl -s -b /tmp/a8.ck -m 10 -o /tmp/home8.html -w "  /cgi-bin/luci/ http=%{http_code} size=%{size_download}\n" "http://$H:8080/cgi-bin/luci/"
grep -c 'iStore' /tmp/home8.html
echo "-- 5) 同一 cookie 访问 8080 /admin/store/pages --"
curl -s -b /tmp/a8.ck -m 15 -o /tmp/sp8.html -w "  store/pages http=%{http_code} size=%{size_download}\n" "http://$H:8080/cgi-bin/luci/admin/store/pages"
grep -o 'Access denied\|无权\|Not Found\|device_id' /tmp/sp8.html | sort | uniq -c
echo "-- 6) 同一 cookie 访问 8080 其他 admin 页作对照 --"
curl -s -b /tmp/a8.ck -m 15 -o /dev/null -w "  /admin/status/overview http=%{http_code}\n" "http://$H:8080/cgi-bin/luci/admin/status/overview"
curl -s -b /tmp/a8.ck -m 15 -o /dev/null -w "  /admin/docker http=%{http_code}\n" "http://$H:8080/cgi-bin/luci/admin/docker"
echo
echo "===== 80 端口同一 cookie 是否被 8080 认可（会话共享验证）====="
rm -f /tmp/a80.ck
curl -s -c /tmp/a80.ck -o /dev/null -m 10 -d 'luci_username=root&luci_password=admin' "http://$H/cgi-bin/luci/"
curl -s -b /tmp/a80.ck -m 15 -o /dev/null -w "  80 登录后访问 80 store/pages http=%{http_code}\n" "http://$H/cgi-bin/luci/admin/store/pages"
curl -s -b /tmp/a80.ck -m 15 -o /dev/null -w "  80 登录后访问 8080 store/pages http=%{http_code}\n" "http://$H:8080/cgi-bin/luci/admin/store/pages"
curl -s -b /tmp/a80.ck -m 15 -o /dev/null -w "  80 登录后访问 8080 docker http=%{http_code}\n" "http://$H:8080/cgi-bin/luci/admin/docker"
