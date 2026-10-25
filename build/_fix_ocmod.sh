#!/bin/sh
cd /tmp || exit 1
rm -rf ocm2 && mkdir ocm2 && cd ocm2 || exit 1
tar -xzf /overlay/kp-restore-20261025-194209.ipk data.tar.gz 2>/dev/null

echo "== 包内 usr/lib/lua/luci 顶层模块 =="
tar -tzf data.tar.gz 2>/dev/null | grep -E '^\./usr/lib/lua/luci/[^/]+\.lua$'

echo "== 逐个补解（只补缺失的）=="
for f in $(tar -tzf data.tar.gz 2>/dev/null | grep -E '^\./usr/lib/lua/luci/[^/]+\.lua$'); do
	target="/${f#./}"
	if [ -f "$target" ]; then
		echo "  已存在 $target"
	else
		tar -xzf data.tar.gz -C / "$f" 2>/dev/null && echo "  已补 $target" || echo "  失败 $f"
	fi
done

echo "== 校验 =="
ls -l /usr/lib/lua/luci/openclash.lua 2>/dev/null

echo "== 语法检查 =="
lua -e "assert(loadfile('/usr/lib/lua/luci/openclash.lua'))" && echo "  openclash.lua OK"
lua -e "local ok,e=pcall(require,'luci.openclash'); print('  require luci.openclash ->', ok, e or '')"

echo "== 清理缓存并重启 8080 =="
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
curl -s -o /dev/null -m 8 -w "  panel=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci
curl -s -o /dev/null -m 8 -w "  openclash页=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/services/openclash
cd / && rm -rf /tmp/ocm2
