#!/bin/sh
echo "===== 1. 候选备份文件 ====="
find / -xdev \( -name '*.ipk' -o -name '*.tar.gz' -o -name '*.tgz' -o -name '*.tar' \) 2>/dev/null \
	| grep -vE '^/proc|^/sys' | while read -r f; do
	printf '%8s  %s\n' "$(du -k "$f" 2>/dev/null | cut -f1)K" "$f"
done

echo
echo "===== 2. 直接含 clash_meta 的 ====="
find / -xdev \( -name '*.ipk' -o -name '*.tar.gz' -o -name '*.tgz' \) 2>/dev/null \
	| grep -vE '^/proc|^/sys' | while read -r f; do
	if tar -tzf "$f" 2>/dev/null | grep -q 'clash_meta'; then
		echo "  HIT  $f"
	fi
done

echo
echo "===== 3. ipk 内层 data.tar.gz 再查 ====="
for f in $(ls /overlay/*.ipk /root/backup/*.ipk /root/pkgs/*.ipk /tmp/*.ipk 2>/dev/null); do
	rm -rf /tmp/sbx && mkdir -p /tmp/sbx
	if tar -xzf "$f" -C /tmp/sbx data.tar.gz 2>/dev/null; then
		if tar -tzf /tmp/sbx/data.tar.gz 2>/dev/null | grep -q 'clash_meta'; then
			echo "  HIT(inner)  $f"
			tar -tzvf /tmp/sbx/data.tar.gz 2>/dev/null | grep 'clash_meta'
		fi
	fi
done
rm -rf /tmp/sbx

echo
echo "===== 4. /root 下的备份目录 ====="
ls -lhR /root/backup 2>/dev/null | head -12
ls -lh /root/pkgs 2>/dev/null | head -8

echo
echo "===== 5. keep.d 是否保 /etc/openclash ====="
cat /lib/upgrade/keep.d/luci-app-openclash 2>/dev/null || echo "  无 keep.d"
