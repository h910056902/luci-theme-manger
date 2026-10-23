#!/bin/sh
echo "== 模拟 8080 页面发起的 WS 握手（Origin: :8080） =="
curl -s -i -m 6 \
	-H 'Connection: Upgrade' \
	-H 'Upgrade: websocket' \
	-H 'Sec-WebSocket-Version: 13' \
	-H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
	-H 'Sec-WebSocket-Protocol: tty' \
	-H 'Origin: http://192.168.66.1:8080' \
	"http://192.168.66.1:7681/ws" 2>&1 | head -6

echo
echo "== 对照：Origin 与 ttyd 同源（:7681） =="
curl -s -i -m 6 \
	-H 'Connection: Upgrade' \
	-H 'Upgrade: websocket' \
	-H 'Sec-WebSocket-Version: 13' \
	-H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
	-H 'Sec-WebSocket-Protocol: tty' \
	-H 'Origin: http://192.168.66.1:7681' \
	"http://192.168.66.1:7681/ws" 2>&1 | head -4
