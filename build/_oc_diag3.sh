#!/bin/sh
echo "== /tmp/openclash.log（尾 30 行）=="
tail -30 /tmp/openclash.log 2>/dev/null

echo
echo "== controller 能否加载 =="
lua -e 'local ok,e=pcall(require,"luci.controller.openclash"); print("require:",ok,e)'
lua -e 'local ok,e=pcall(require,"luci.openclash"); print("module:",ok,e)'

echo
echo "== 索引缓存里有 openclash 吗 =="
ls -l /tmp/luci-indexcache* 2>/dev/null
grep -c 'openclash' /tmp/luci-indexcache* 2>/dev/null | head -2

echo
echo "== iptables 模块 =="
for m in xt_TPROXY xt_redir xt_socket iptable_nat iptable_mangle xt_connmark; do
	printf "  %-14s " "$m"
	lsmod 2>/dev/null | grep -q "^$m" && echo "已加载" || echo "-"
done
ls /lib/modules/$(uname -r)/ | grep -cE 'xt_TPROXY|xt_REDIRECT|xt_socket'
