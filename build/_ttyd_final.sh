#!/bin/sh
killall ttyd 2>/dev/null
sleep 2
/etc/init.d/ttyd8080 restart >/dev/null 2>&1
sleep 3

echo "== 进程 =="
ps w | grep '[/]usr/bin/ttyd' | head -3
echo "== 监听 =="
netstat -lnt 2>/dev/null | grep 7681
echo "== HTTP =="
curl -s -o /dev/null -m 8 -w "  http=%{http_code}\n" http://192.168.66.1:7681/
echo -n "  首页含终端样式: "
curl -s -m 8 http://192.168.66.1:7681/ | grep -c 'xterm'
echo "== 跨源 WS 握手（模拟 8080 页面）=="
printf 'GET /ws HTTP/1.1\r\nHost: 192.168.66.1:7681\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\nOrigin: http://192.168.66.1:8080\r\nSec-WebSocket-Protocol: tty\r\n\r\n' \
	| nc 192.168.66.1 7681 2>/dev/null | head -2
