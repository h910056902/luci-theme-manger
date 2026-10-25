#!/bin/sh
echo "== iStore 里 app-meta 含 oc / speed 的 =="
opkg list 2>/dev/null | grep '^app-meta-' | grep -iE 'oc|speed|测速' | head -10 || echo "  无"

echo "== 全部 app-meta（名字清单，用于人工比对）=="
opkg list 2>/dev/null | grep '^app-meta-' | awk '{print $1}' | sed 's/^app-meta-//' | tr '\n' ' '
echo

echo "== ttyd =="
opkg list 2>/dev/null | grep -iE 'ttyd' | head -5 || echo "  源里无 ttyd"

echo "== 应用中心（厂商）=="
ls /usr/lib/lua/luci/view/nradio_appcenter/ 2>/dev/null | head -5
ls /usr/lib/lua/luci/controller/nradio*.lua 2>/dev/null | head -3
ls /usr/bin/kpcped /etc/init.d/kpcped 2>/dev/null
