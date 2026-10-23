#!/bin/sh
# 重新组装内嵌终端页：
#   head（自建界面） + luci-app-ttyd 内联 bundle（xterm/fit/UTF8/overlay） + tail（连接逻辑）
set -e
SRC=/usr/lib/lua/luci/view/ttyd/overview.htm
D=/overlay/nradio-apps/openwrt-luci-8080
DST=$D/usr/lib/lua/luci/view/admin_status/nradio_term.htm
TS=$(date +%Y%m%d-%H%M%S)

[ -f /tmp/_term_head.html ] || { echo "缺少 head"; exit 1; }
[ -f /tmp/_term_tail.html ] || { echo "缺少 tail"; exit 1; }

cp "$DST" "/tmp/kpc-term-$TS.htm" 2>/dev/null || true
echo "备份: /tmp/kpc-term-$TS.htm"

# 去掉 Windows 换行
for f in /tmp/_term_head.html /tmp/_term_tail.html; do
	tr -d '\r' < "$f" > "$f.lf" && mv "$f.lf" "$f"
done

# 只取 xterm 相关的 4 段 bundle（第 17-22 行）
sed -n '17,22p' "$SRC" > /tmp/_kp_bundle.html
echo -n "bundle 行数: "; wc -l < /tmp/_kp_bundle.html
echo -n "bundle 字节: "; wc -c < /tmp/_kp_bundle.html

cat /tmp/_term_head.html /tmp/_kp_bundle.html /tmp/_term_tail.html > "$DST"
chmod 644 "$DST"

echo "== 校验 =="
echo -n "总大小: "; wc -c < "$DST"
echo -n "容器 id: "; grep -c 'id="kpt-term"' "$DST"
echo -n "xterm 全局: "; grep -c 'Terminal.prototype' "$DST"
echo -n "WS 连接: "; grep -c 'new WebSocket' "$DST"
echo -n "footer: "; grep -c '<%+footer%>' "$DST"
echo -n "<% 数量: "; grep -o '<%' "$DST" | wc -l
echo -n "%> 数量: "; grep -o '%>' "$DST" | wc -l

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
echo -n "页面: "; curl -s -o /dev/null -w '%{http_code}\n' http://192.168.66.1:8080/cgi-bin/luci/admin/status/terminal
echo DONE
