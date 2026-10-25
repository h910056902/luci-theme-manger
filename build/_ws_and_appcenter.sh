#!/bin/sh
echo "== 1. 跨源 WebSocket 握手（Origin 8080 → 7681）=="
printf 'GET /ws HTTP/1.1\r\nHost: 192.168.66.1:7681\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\nOrigin: http://192.168.66.1:8080\r\nSec-WebSocket-Protocol: tty\r\n\r\n' \
	| nc 192.168.66.1 7681 2>/dev/null | head -2

echo "== 2. 终端首页 =="
curl -s -o /dev/null -m 8 -w "  :7681 = %{http_code}\n" http://192.168.66.1:7681/
curl -s -m 8 http://192.168.66.1:7681/ | grep -o 'kpt-[a-z]*' | sort -u | head -5

echo "== 3. 面板终端页 =="
curl -s -o /dev/null -m 8 -w "  panel/terminal = %{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/terminal

echo "== 4. 厂商应用中心 =="
ps w | grep '[k]pcped' | head -2
ls -l /etc/init.d/kpcped 2>/dev/null
grep -ohE 'https?://[a-zA-Z0-9./_-]+' /usr/lib/lua/luci/view/nradio_appcenter/appcenter.htm 2>/dev/null | sort -u | head -5
grep -rhoE 'https?://[a-zA-Z0-9./_-]*(kunpeng|nradio|kpcpe)[a-zA-Z0-9./_-]*' /usr/lib/lua/luci/controller/ 2>/dev/null | sort -u | head -5
ls -l /usr/bin/kpcped 2>/dev/null && strings /usr/bin/kpcped 2>/dev/null | grep -oE 'https?://[a-zA-Z0-9./_-]+' | head -5
