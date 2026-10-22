#!/bin/sh
CGI=/overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci
C=$(sed -n 's/.*sysauth[[:space:]]*\([A-Za-z0-9]*\)$/\1/p' /tmp/kq.cookie 2>/dev/null | head -n 1)
echo "cookie_len=${#C}"

echo "== run devices =="
SERVER_PORT=8080 SCRIPT_FILENAME="$CGI" \
PATH_INFO=/admin/status/cellular QUERY_STRING=action=devices REQUEST_METHOD=GET \
  HTTP_COOKIE="sysauth=$C" CONTENT_LENGTH=0 \
  lua "$CGI" 2>&1 | head -n 30

echo "== logread tail =="
logread -e "lua" 2>/dev/null | tail -n 15
logread -e "cgi-bin" 2>/dev/null | tail -n 10
