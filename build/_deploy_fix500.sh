#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)
mkdir -p /tmp/kpc-fix500-$TS
cp "$V/nradio_device.htm" "/tmp/kpc-fix500-$TS/device.htm" 2>/dev/null
cp "$V/nradio_cellular.htm" "/tmp/kpc-fix500-$TS/cellular.htm" 2>/dev/null
echo "备份: /tmp/kpc-fix500-$TS/"

for f in nradio_device nradio_cellular; do
	[ -f "/tmp/_up_$f.htm" ] || { echo "缺少 /tmp/_up_$f.htm"; exit 1; }
	tr -d '\r' < "/tmp/_up_$f.htm" > "/tmp/_up_$f.htm.lf" && mv "/tmp/_up_$f.htm.lf" "/tmp/_up_$f.htm"
	cp "/tmp/_up_$f.htm" "$V/$f.htm"
	chmod 644 "$V/$f.htm"
	echo "$f: $(wc -c < "$V/$f.htm") B  floor=$(grep -c 'math.floor(tonumber(sec)' "$V/$f.htm")"
done

echo "== 本机运行时间（判断是否会走短时分支）=="
cat /proc/uptime

echo "== Lua 表达式自检（模拟短时分支）=="
lua -e '
local function fmt_dur(sec)
	local s = math.floor(tonumber(sec) or 0)
	if s <= 0 then return "-" end
	local d = math.floor(s / 86400)
	local h = math.floor((s % 86400) / 3600)
	local m = math.floor((s % 3600) / 60)
	if d > 0 then return string.format("%d 天 %d 小时 %d 分", d, h, m) end
	if h > 0 then return string.format("%d 小时 %d 分", h, m) end
	return string.format("%d 分 %d 秒", m, s % 60)
end
print("900s   ->", fmt_dur(900.75))
print("59s    ->", fmt_dur(59.99))
print("93500s ->", fmt_dur(93500.5))
'

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
for p in device cellular; do
	curl -s -o /tmp/p.html -w "$p=%{http_code} " -m 15 "http://192.168.66.1:8080/cgi-bin/luci/admin/status/$p"
	echo -n "500页="; grep -c 'Failed to execute template' /tmp/p.html
done
echo DONE
