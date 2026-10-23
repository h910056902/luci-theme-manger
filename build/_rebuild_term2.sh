#!/bin/sh
# 同时产出两份，保证面板内页与 :7681 外观一致：
#   A. LuCI 模板  admin_status/nradio_term.htm（带页面 header）
#   B. 独立页      /etc/ttyd/index.html（ttyd --index，无 header）
set -e
SRC=/usr/lib/lua/luci/view/ttyd/overview.htm
D=/overlay/nradio-apps/openwrt-luci-8080
DST=$D/usr/lib/lua/luci/view/admin_status/nradio_term.htm
STANDALONE=/etc/ttyd/index.html
TS=$(date +%Y%m%d-%H%M%S)

for f in /tmp/_term_head.html /tmp/_term_body.html /tmp/_term_tail.html; do
	[ -f "$f" ] || { echo "缺少 $f"; exit 1; }
	tr -d '\r' < "$f" > "$f.lf" && mv "$f.lf" "$f"
done

[ -f "$DST" ] && cp "$DST" "/tmp/kpc-term-$TS.htm"
[ -f "$STANDALONE" ] && cp "$STANDALONE" "/tmp/kpc-ttyd-index-$TS.html"
echo "备份: /tmp/kpc-term-$TS.htm , /tmp/kpc-ttyd-index-$TS.html"

sed -n '3,5p' "$SRC" > /tmp/_kp_xterm.css
sed -n '17,22p' "$SRC" > /tmp/_kp_bundle.html
echo "xterm.css=$(wc -c < /tmp/_kp_xterm.css)  bundle=$(wc -c < /tmp/_kp_bundle.html)"

# ---------- A. LuCI 模板 ----------
{
	cat /tmp/_term_head.html
	echo '<style type="text/css">'
	cat /tmp/_kp_xterm.css
	echo '</style>'
	cat /tmp/_term_body.html
	cat /tmp/_kp_bundle.html
	cat /tmp/_term_tail.html
} > "$DST"
chmod 644 "$DST"

# ---------- B. 独立页 ----------
mkdir -p /etc/ttyd
{
	echo '<!DOCTYPE html>'
	echo '<html lang="zh-CN"><head>'
	echo '<meta charset="utf-8">'
	echo '<meta name="viewport" content="width=device-width,initial-scale=1">'
	echo '<meta name="apple-mobile-web-app-capable" content="yes">'
	echo '<title>终端 · NRadio</title>'
	echo '<style type="text/css">'
	cat /tmp/_kp_xterm.css
	echo '</style>'
	sed -e 's#<h2 name="content">终端</h2>##' -e 's#<%=port%>#7681#g' /tmp/_term_body.html
	echo '<style type="text/css">'
	echo 'html,body{margin:0;background:#0b1218}'
	echo 'body{padding:14px;box-sizing:border-box}'
	echo '@media (max-width:600px){body{padding:8px}}'
	echo '</style>'
	echo '</head><body>'
	echo '<script>window.KP_TERM_PORT="7681";</script>'
	cat /tmp/_kp_bundle.html
	sed -e 's#<%=port%>#7681#g' -e '/^<%+footer%>$/d' /tmp/_term_tail.html
	echo '</body></html>'
} > "$STANDALONE"
chmod 644 "$STANDALONE"

echo "== 校验 =="
echo "面板页: $(wc -c < "$DST") 字节"
echo "独立页: $(wc -c < "$STANDALONE") 字节"
echo -n "面板页 红黄绿: "; grep -c 'kpt-l-red' "$DST"
echo -n "独立页 红黄绿: "; grep -c 'kpt-l-red' "$STANDALONE"
echo -n "独立页 残留 Lua: "; grep -c '<%' "$STANDALONE" || true
echo -n "独立页 残留 <%=: "; grep -c '<%=' "$STANDALONE" || true

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/ttyd restart >/dev/null 2>&1 || true
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

echo "== ttyd 实际返回 =="
curl -s -m 8 http://192.168.66.1:7681/ | grep -c 'kpt-lights'
curl -s -o /dev/null -w "ttyd=%{http_code}\n" -m 8 http://192.168.66.1:7681/
echo DONE
