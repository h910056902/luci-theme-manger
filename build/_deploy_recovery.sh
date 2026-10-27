#!/bin/sh
echo "== 1. 落盘 =="
tr -d '\r' < /tmp/_up_kprec > /usr/bin/kp-recovery
chmod 755 /usr/bin/kp-recovery

mkdir -p /usr/lib/lua/luci/controller /usr/lib/lua/luci/view/kp_recovery
tr -d '\r' < /tmp/_up_kprec_ctrl > /usr/lib/lua/luci/controller/kp_recovery.lua
chmod 644 /usr/lib/lua/luci/controller/kp_recovery.lua
tr -d '\r' < /tmp/_up_kprec_view > /usr/lib/lua/luci/view/kp_recovery/main.htm
chmod 644 /usr/lib/lua/luci/view/kp_recovery/main.htm

for f in /usr/bin/kp-recovery /usr/lib/lua/luci/controller/kp_recovery.lua \
         /usr/lib/lua/luci/view/kp_recovery/main.htm; do
	printf "  %7s  %s\n" "$(wc -c < "$f")" "$f"
done

echo "== 2. 语法 =="
sh -n /usr/bin/kp-recovery && echo "  kp-recovery OK"
lua -e "assert(loadfile('/usr/lib/lua/luci/controller/kp_recovery.lua'))" && echo "  controller OK"

echo "== 3. 命令自检 =="
/usr/bin/kp-recovery list | head -3
/usr/bin/kp-recovery status

echo "== 4. 清缓存重启 =="
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

echo "== 5. 路由 =="
curl -s -o /dev/null -m 8 -w "  /admin/system/recovery = %{http_code}\n" \
	http://192.168.66.1/cgi-bin/luci/admin/system/recovery
