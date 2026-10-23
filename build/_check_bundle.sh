#!/bin/sh
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_term.htm
echo "== 组装后各 script 标签数量 =="
echo -n "<script 开: "; grep -o '<script' "$F" | wc -l
echo -n "</script> 闭: "; grep -o '</script>' "$F" | wc -l
echo
echo "== bundle 各行结尾（应为 </script>） =="
sed -n '/^<script>!function(t){if("object"==typeof exports/,/^$/p' "$F" 2>/dev/null | tail -c 60
echo
awk 'length($0)>10000 { printf "行%d 结尾: %s\n", NR, substr($0, length($0)-40) }' "$F"
echo
echo "== head/tail 衔接处 =="
grep -n 'id="kpt-term"' "$F" | head -2
grep -n 'var PORT' "$F" | head -2
