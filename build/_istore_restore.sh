#!/bin/sh
# 后台按 /etc/kp-restore/packages.txt 补装缺失包
L=/etc/kp-restore/packages.txt
ST=/tmp/istore-restore.state
LOG=/tmp/istore-restore.log
: > "$LOG"

[ -f "$L" ] || { echo "缺清单" > "$ST"; exit 1; }

echo "stage=update i=0 ok=0 fail=0 total=0" > "$ST"
opkg update > /tmp/istore-update.log 2>&1

opkg list-installed 2>/dev/null | awk '{print $1}' | sort > /tmp/have.txt
awk '{print $1}' "$L" | sort > /tmp/want.txt
awk 'NR==FNR{h[$1]=1;next} !($1 in h){print $1}' /tmp/have.txt /tmp/want.txt > /tmp/miss.txt

total=$(wc -l < /tmp/miss.txt)
i=0; ok=0; fail=0
echo "stage=install i=0 ok=0 fail=0 total=$total" > "$ST"
echo "待装 $total 个" >> "$LOG"

while read -r p; do
	[ -n "$p" ] || continue
	i=$((i+1))
	if opkg install "$p" > /dev/null 2>&1; then
		ok=$((ok+1)); echo "OK   $p" >> "$LOG"
	else
		fail=$((fail+1)); echo "FAIL $p" >> "$LOG"
	fi
	echo "stage=install i=$i ok=$ok fail=$fail total=$total cur=$p" > "$ST"
done < /tmp/miss.txt

echo "stage=done i=$i ok=$ok fail=$fail total=$total" > "$ST"
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart > /dev/null 2>&1
