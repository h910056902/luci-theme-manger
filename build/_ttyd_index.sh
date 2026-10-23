#!/bin/sh
echo "== 默认 index.html =="
curl -s -m 8 http://192.168.66.1:7681/ | head -40
echo
echo "== 静态资源探测 =="
for p in /css/xterm.css /js/xterm.js /js/ttyd.js /js/addons.js /favicon.ico; do
	code=$(curl -s -o /dev/null -w '%{http_code}' -m 5 "http://192.168.66.1:7681$p")
	echo "$p -> $code"
done
