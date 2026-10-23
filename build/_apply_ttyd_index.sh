#!/bin/sh
# 生成 1:1 复刻 iStoreOS 的 ttyd 首页：
#   1) 先恢复内置页（否则会把旧的主题层再抓一遍，越抓越厚）
#   2) 清掉自定义 client_option（回到默认黑底白字 / 15px courier）
#   3) 抓内置页 + 追加主题层 → /etc/ttyd/index.html
#   4) 启用 --index

set -e
PORT=$(uci -q get ttyd.@server[0].port); [ -n "$PORT" ] || PORT=7681
LAN=$(uci -q get network.lan.ipaddr); [ -n "$LAN" ] || LAN=192.168.66.1
BASE="http://$LAN:$PORT"

mkdir -p /etc/ttyd
[ -f /tmp/_ttyd_chunk.html ] || { echo "缺少 /tmp/_ttyd_chunk.html"; exit 1; }
tr -d '\r' < /tmp/_ttyd_chunk.html > /tmp/_ttyd_chunk.lf && mv /tmp/_ttyd_chunk.lf /tmp/_ttyd_chunk.html

echo "== 1. 先回到内置页 =="
uci -q delete ttyd.@server[0].index 2>/dev/null || true
uci -q delete ttyd.@server[0].client_option 2>/dev/null || true
uci commit ttyd
/etc/init.d/ttyd restart >/dev/null 2>&1 || true
sleep 2

echo "== 2. 抓内置页 =="
curl -s -m 12 "$BASE/" -o /etc/ttyd/index.html || { echo "抓取失败"; exit 1; }
SIZE=$(wc -c < /etc/ttyd/index.html)
echo "内置页大小: $SIZE"
[ "$SIZE" -gt 100000 ] || { echo "抓取内容异常，放弃"; rm -f /etc/ttyd/index.html; exit 1; }
grep -q 'kp-term-theme' /etc/ttyd/index.html && { echo "抓到的页面已含主题层，异常"; exit 1; }

echo "== 3. 追加主题层 =="
cat /tmp/_ttyd_chunk.html >> /etc/ttyd/index.html
echo "合并后: $(wc -c < /etc/ttyd/index.html)"

echo "== 4. 启用 --index =="
uci set ttyd.@server[0].index='/etc/ttyd/index.html'
uci commit ttyd
/etc/init.d/ttyd restart >/dev/null 2>&1 || true
sleep 2

echo "== 校验 =="
echo -n "主题层: "; curl -s -m 8 "$BASE/" | grep -c 'kp-term-theme'
curl -s -o /dev/null -w "http=%{http_code}\n" -m 8 "$BASE/"
echo -n "client_option 数量: "; uci -q get ttyd.@server[0].client_option 2>/dev/null | wc -l
ps w | grep '/usr/bin/ttyd' | head -1 | cut -c1-120
echo DONE
