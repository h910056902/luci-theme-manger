#!/bin/sh
# 生成自定义 ttyd 首页：抓它自带的内联页 + 追加主题层
set -e
mkdir -p /etc/ttyd

[ -f /tmp/_ttyd_chunk.html ] || { echo "缺少 /tmp/_ttyd_chunk.html"; exit 1; }
tr -d '\r' < /tmp/_ttyd_chunk.html > /tmp/_ttyd_chunk.html.lf
mv /tmp/_ttyd_chunk.html.lf /tmp/_ttyd_chunk.html

# 抓默认页（ttyd 内联 bundle，静态路径全是 404，只能整页抓）
# 注意：ttyd 用 --interface br-lan 绑定在 192.168.66.1，127.0.0.1 不通
curl -s -m 10 http://192.168.66.1:7681/ -o /etc/ttyd/index.html
SIZE=$(wc -c < /etc/ttyd/index.html)
echo "默认页大小: $SIZE"
[ "$SIZE" -gt 100000 ] || { echo "抓取失败，放弃"; rm -f /etc/ttyd/index.html; exit 1; }

# 追加主题层（放在 </html> 之后，浏览器会并入 body 并生效）
cat /tmp/_ttyd_chunk.html >> /etc/ttyd/index.html
echo "合并后: $(wc -c < /etc/ttyd/index.html)"

uci -q delete ttyd.@server[0].index 2>/dev/null || true
uci set ttyd.@server[0].index='/etc/ttyd/index.html'
uci commit ttyd
/etc/init.d/ttyd restart >/dev/null 2>&1 || true
sleep 2

echo "== 生效检查 =="
curl -s -m 8 http://192.168.66.1:7681/ | grep -c 'kp-term-theme'
curl -s -o /dev/null -w "http=%{http_code}\n" -m 8 http://192.168.66.1:7681/
ps w | grep '[t]tyd' | head -1
echo DONE
