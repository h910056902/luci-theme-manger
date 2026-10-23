#!/bin/sh
# 组装内嵌终端页：
#   head(Lua+header) → 参考页 xterm.css(第3-5行) → body(面板样式+结构) → xterm bundle(第17-22行) → tail(连接逻辑)
set -e
SRC=/usr/lib/lua/luci/view/ttyd/overview.htm
D=/overlay/nradio-apps/openwrt-luci-8080
DST=$D/usr/lib/lua/luci/view/admin_status/nradio_term.htm
TS=$(date +%Y%m%d-%H%M%S)

for f in /tmp/_term_head.html /tmp/_term_body.html /tmp/_term_tail.html; do
	[ -f "$f" ] || { echo "缺少 $f"; exit 1; }
	tr -d '\r' < "$f" > "$f.lf" && mv "$f.lf" "$f"
done

cp "$DST" "/tmp/kpc-term-$TS.htm" 2>/dev/null || true
echo "备份: /tmp/kpc-term-$TS.htm"

# 参考页的 xterm.css（第 3-5 行，约 28 KB）
sed -n '3,5p' "$SRC" > /tmp/_kp_xterm.css
CSS=$(wc -c < /tmp/_kp_xterm.css)
echo "xterm.css: $CSS 字节"
[ "$CSS" -gt 10000 ] || { echo "CSS 抽取失败"; exit 1; }

# xterm bundle（第 17-22 行）
sed -n '17,22p' "$SRC" > /tmp/_kp_bundle.html
echo "bundle: $(wc -c < /tmp/_kp_bundle.html) 字节"

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

echo "== 校验 =="
echo -n "总大小: "; wc -c < "$DST"
echo -n ".xterm 规则数: "; grep -o '\.xterm' "$DST" | wc -l
echo -n "容器: "; grep -c 'id="kpt-term"' "$DST"
echo -n "script 配对: "; echo -n "$(grep -o '<script' "$DST" | wc -l)/$(grep -o '</script>' "$DST" | wc -l)"
echo
echo -n "<% 配对: "; echo -n "$(grep -o '<%' "$DST" | wc -l)/$(grep -o '%>' "$DST" | wc -l)"
echo
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
echo DONE
