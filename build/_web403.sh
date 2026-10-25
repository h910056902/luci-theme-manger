#!/bin/sh
echo "== CGI 包装器 =="
cat /www/cgi-bin/luci
echo "== /www/index.html =="
head -30 /www/index.html 2>/dev/null
echo "== 本地请求 /cgi-bin/luci =="
curl -s -i http://127.0.0.1/cgi-bin/luci 2>/dev/null | head -14
echo "== 本地请求 /cgi-bin/luci/ =="
curl -s -o /dev/null -w "code=%{http_code} size=%{size_download}\n" http://127.0.0.1/cgi-bin/luci/
echo "== uhttpd 配置 =="
uci show uhttpd 2>/dev/null | head -25
echo "== 日志 =="
logread 2>/dev/null | grep -iE 'uhttpd|luci|forbidden|403' | tail -10
echo "== 关键文件 =="
ls -l /usr/lib/lua/luci/sgi/cgi.lua /usr/share/ucode/luci/*.uc 2>/dev/null | head -5
