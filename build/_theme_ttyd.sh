#!/bin/sh
# 给 ttyd 套上与 8080 面板一致的深色主题
TS=$(date +%Y%m%d-%H%M%S)
cp /etc/config/ttyd /tmp/ttyd.bak-$TS 2>/dev/null
echo "备份: /tmp/ttyd.bak-$TS"

uci -q delete ttyd.@server[0].client_option 2>/dev/null

uci add_list ttyd.@server[0].client_option='theme={"background":"#0f1720","foreground":"#e6edf3","cursor":"#34d399","cursorAccent":"#0f1720","selectionBackground":"rgba(52,211,153,0.30)","black":"#1c2430","red":"#f87171","green":"#34d399","yellow":"#fbbf24","blue":"#60a5fa","magenta":"#c084fc","cyan":"#22d3ee","white":"#cbd5e1","brightBlack":"#64748b","brightRed":"#fca5a5","brightGreen":"#6ee7b7","brightYellow":"#fde68a","brightBlue":"#93c5fd","brightMagenta":"#d8b4fe","brightCyan":"#67e8f9","brightWhite":"#f1f5f9"}'
uci add_list ttyd.@server[0].client_option='fontSize=14'
uci add_list ttyd.@server[0].client_option='fontFamily=JetBrains Mono, Menlo, Consolas, monospace'
uci add_list ttyd.@server[0].client_option='titleFixed=终端 · NRadio 8080'
uci add_list ttyd.@server[0].client_option='cursorBlink=true'
uci commit ttyd

/etc/init.d/ttyd restart >/dev/null 2>&1
sleep 2

echo "== 生效参数 =="
ps w | grep '[t]tyd' | head -2
echo "== 监听 =="
netstat -lnt 2>/dev/null | grep 7681
echo "== 页面可达 =="
curl -s -o /dev/null -w "http=%{http_code}\n" -m 8 http://192.168.66.1:7681/
echo DONE
