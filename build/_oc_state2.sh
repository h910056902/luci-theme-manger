#!/bin/sh
echo "== 1. 程序文件 =="
for f in /etc/init.d/openclash /usr/share/openclash/openclash.sh \
         /usr/lib/lua/luci/controller/openclash.lua /usr/lib/lua/luci/openclash.lua; do
	[ -f "$f" ] && printf "  OK   %8s  %s\n" "$(wc -c < "$f")" "$f" || printf "  MISS %s\n" "$f"
done

echo "== 2. 目录体积 =="
du -sm /etc/openclash /usr/share/openclash 2>/dev/null

echo "== 3. 内核 =="
ls -l /etc/openclash/core/ 2>/dev/null || echo "  无 core 目录"

echo "== 4. 配置 / 订阅 =="
ls -l /etc/openclash/config/ 2>/dev/null || echo "  无 config 目录"
uci -q get openclash.config.enable 2>/dev/null || echo "  无 uci openclash"

echo "== 5. 进程与端口 =="
ps w | grep '[c]lash' | head -3 || echo "  无 clash 进程"
netstat -lnt 2>/dev/null | grep -E '7890|7891|9090|7874' || echo "  端口未监听"

echo "== 6. overlay 里是否有可复用的备份 =="
ls -lh /overlay/*.ipk 2>/dev/null
find /overlay -maxdepth 3 -name 'clash_meta*' -o -maxdepth 3 -name 'mihomo*' 2>/dev/null | head -5
ls -d /overlay/kp-fw-backup/* 2>/dev/null | head -3
