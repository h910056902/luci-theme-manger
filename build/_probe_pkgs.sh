#!/bin/sh
echo "== 已有的 ipk 文件 =="
find / -xdev -name '*.ipk' 2>/dev/null | grep -v '^/proc' | head -20
echo "总数: $(find / -xdev -name '*.ipk' 2>/dev/null | grep -vc '^/proc')"

echo "== opkg 缓存/下载能力 =="
opkg --help 2>&1 | grep -iE 'download|cache' || echo "无 download 选项"
ls -d /var/opkg-lists 2>/dev/null && ls /var/opkg-lists | head -3

echo "== 已安装包数 =="
opkg list-installed 2>/dev/null | wc -l

echo "== 落在 overlay 的包（即用户后装）=="
n=0
for f in /usr/lib/opkg/info/*.list; do
	[ -f "$f" ] || continue
	pkg=$(basename "$f" .list)
	# 取该包第一个文件，看它是否存在于 /rom（存在=固件自带）
	first=$(head -1 "$f" 2>/dev/null)
	[ -n "$first" ] || continue
	if [ ! -e "/rom$first" ] && [ -e "$first" ]; then
		n=$((n+1))
		[ $n -le 25 ] && echo "  $pkg"
	fi
done
echo "后装包数: $n"

echo "== OpenClash 体积构成 =="
du -sm /etc/openclash/* 2>/dev/null | sort -nr | head -6
du -sm /usr/lib/lua/luci/controller/openclash.lua /www/luci-static/resources/view/openclash /etc/init.d/openclash 2>/dev/null
echo "== openclash 包文件数 =="
wc -l < /usr/lib/opkg/info/luci-app-openclash.list 2>/dev/null
