#!/bin/sh
echo "== 1. 备份里的包清单 =="
ls -l /etc/kp-restore/packages.txt 2>/dev/null || echo "  当前无 /etc/kp-restore/packages.txt"

rm -rf /tmp/px && mkdir -p /tmp/px && cd /tmp/px || exit 1
IPK=$(ls -t /overlay/kp-restore-*.ipk 2>/dev/null | head -1)
if [ -n "$IPK" ]; then
	tar -xzf "$IPK" data.tar.gz 2>/dev/null
	tar -xzf data.tar.gz ./etc/kp-restore/packages.txt -C /tmp/px 2>/dev/null
	BK=/tmp/px/etc/kp-restore/packages.txt
	[ -f "$BK" ] && echo "  备份清单: $(wc -l < "$BK") 个包"
else
	echo "  备份包不存在"
fi

echo "== 2. 与当前差异（缺失的包）=="
if [ -f "$BK" ]; then
	opkg list-installed 2>/dev/null | awk '{print $1}' | sort > /tmp/have.txt
	awk '{print $1}' "$BK" | sort > /tmp/want.txt
	awk 'NR==FNR{h[$1]=1;next} !($1 in h){print $1}' /tmp/have.txt /tmp/want.txt > /tmp/miss.txt
	echo "  缺失总数: $(wc -l < /tmp/miss.txt)"
	echo "  --- 用户级应用（前 40）---"
	grep -E 'ocspeed|ttyd|istore|app-|docker|1panel|homebox|frpc|ddns|natpierce|qiyou|shadowrt|systools|arpbind|kaiplus|clash' /tmp/miss.txt | head -40
fi

echo "== 3. ocspeed 是否在源里 =="
opkg list 2>/dev/null | grep -iE '^ocspeed|^app-ocspeed|ocspeed' | head -5 || echo "  源里没有 ocspeed"

echo "== 4. ttyd 状态 =="
opkg list-installed 2>/dev/null | grep ttyd || echo "  ttyd 未安装"
ls -l /usr/bin/ttyd 2>/dev/null

echo "== 5. ocspeed 配置与残留 =="
ls -l /etc/config/ocspeed /etc/init.d/ocspeed /usr/bin/ocspeed 2>/dev/null
find / -xdev -maxdepth 4 -name '*ocspeed*' 2>/dev/null | head -8
rm -rf /tmp/px
