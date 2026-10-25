#!/bin/sh
# v2：按 opkg 文件清单精确收集 OpenClash；面板排除历次备份目录
set -e

TS=$(date +%Y%m%d-%H%M%S)
VER=$(date +%Y.%m.%d-%H%M%S)
NAME="kp-restore-$TS"
W="/overlay/kpbuild/$NAME"
OUT="/overlay/$NAME.ipk"

rm -rf "$W"
mkdir -p "$W/control" "$W/data/etc/kp-restore"

echo "== 1. 8080 面板（排除 theme-backup / *.bak / *.kpbak）=="
mkdir -p "$W/data/overlay/nradio-apps"
tar -C /overlay/nradio-apps -cf - \
	--exclude='openwrt-luci-8080/theme-backup*' \
	--exclude='*.bak' --exclude='*.bak-*' --exclude='*.kpbak-*' \
	openwrt-luci-8080 2>/dev/null | tar -C "$W/data/overlay/nradio-apps" -xf - 2>/dev/null || true
echo "  面板体积: $(du -sm "$W/data/overlay/nradio-apps" | cut -f1) MB"

echo "== 2. OpenClash（严格按 opkg 清单）=="
LIST=/usr/lib/opkg/info/luci-app-openclash.list
[ -f "$LIST" ] || { echo "缺少 $LIST"; exit 1; }
n=0; miss=0
while read -r p; do
	[ -n "$p" ] || continue
	[ -e "$p" ] || { miss=$((miss+1)); continue; }
	d="$W/data$(dirname "$p")"
	mkdir -p "$d"
	cp -a "$p" "$d/" 2>/dev/null || true
	n=$((n+1))
done < "$LIST"
echo "  复制 $n 个，缺失 $miss 个"
echo "  openclash 体积: $(du -sm "$W/data/etc/openclash" "$W/data/usr/share/openclash" 2>/dev/null | awk '{s+=$1} END{print s+0}') MB"

echo "== 3. 全部 /etc/config =="
mkdir -p "$W/data/etc/config"
cp -a /etc/config/. "$W/data/etc/config/" 2>/dev/null || true
find "$W/data/etc/config" -name '*.bak*' -delete 2>/dev/null || true
find "$W/data/etc/config" -name '*.kpbak*' -delete 2>/dev/null || true
find "$W/data/etc/config" -name '*.old' -delete 2>/dev/null || true
echo "  配置数: $(ls "$W/data/etc/config" | wc -l)"

echo "== 4. 清单与恢复脚本 =="
opkg list-installed > "$W/data/etc/kp-restore/packages.txt" 2>/dev/null
NPKG=$(wc -l < "$W/data/etc/kp-restore/packages.txt")

cat > "$W/data/etc/kp-restore/restore-packages.sh" <<'EOS'
#!/bin/sh
# 装回「除固件自带之外」的插件，需要联网（opkg 源可达）
L=/etc/kp-restore/packages.txt
[ -f "$L" ] || { echo "缺少 $L"; exit 1; }
echo "[1/3] 更新软件源..."
opkg update >/dev/null 2>&1
echo "[2/3] 计算差异..."
opkg list-installed 2>/dev/null | awk '{print $1}' | sort > /tmp/kp-have.txt
awk '{print $1}' "$L" | sort > /tmp/kp-want.txt
awk 'NR==FNR{h[$1]=1;next} !($1 in h){print $1}' /tmp/kp-have.txt /tmp/kp-want.txt > /tmp/kp-miss.txt
echo "  待安装：$(wc -l < /tmp/kp-miss.txt) 个"
echo "[3/3] 安装..."
while read -r p; do
	[ -n "$p" ] || continue
	if opkg install "$p" >/dev/null 2>&1; then echo "  OK   $p"; else echo "  FAIL $p"; fi
done < /tmp/kp-miss.txt
echo "完成。装不上的多半是 iStore 应用，去应用商店重装。"
EOS
chmod 755 "$W/data/etc/kp-restore/restore-packages.sh"

{
	echo "NRadio 8080 完整恢复包"
	echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
	echo "设备型号: $(cat /tmp/sysinfo/model 2>/dev/null)"
	echo "固件版本: $(. /etc/openwrt_release 2>/dev/null; echo -n "$DISTRIB_DESCRIPTION")"
	echo "已装插件: $NPKG 个"
	echo
	echo "离线包含：8080 面板、OpenClash（程序/内核/规则/UI）、全部 /etc/config（含订阅）"
	echo "在线补装：其余插件执行 sh /etc/kp-restore/restore-packages.sh"
} > "$W/data/etc/kp-restore/MANIFEST.txt"

echo "== 5. control =="
cat > "$W/control/control" <<EOF
Package: kp-restore
Version: $VER
Architecture: all
Maintainer: NRadio 8080
Section: utils
Priority: optional
Description: NRadio 8080 full restore (panel + OpenClash + configs + package list)
EOF

cat > "$W/control/postinst" <<'EOS'
#!/bin/sh
chmod 755 /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci 2>/dev/null
chmod 755 /etc/kp-restore/restore-packages.sh 2>/dev/null
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache 2>/dev/null
/etc/init.d/uhttpd restart >/dev/null 2>&1
[ -x /etc/init.d/openclash ] && /etc/init.d/openclash restart >/dev/null 2>&1
[ -x /etc/init.d/kpsmsfwd ] && /etc/init.d/kpsmsfwd restart >/dev/null 2>&1
[ -x /etc/init.d/kpswap ] && /etc/init.d/kpswap start >/dev/null 2>&1
echo "kp-restore: 面板与 OpenClash 已恢复"
echo "kp-restore: 其余插件执行 sh /etc/kp-restore/restore-packages.sh"
exit 0
EOS

cat > "$W/control/postrm" <<'EOS'
#!/bin/sh
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache 2>/dev/null
exit 0
EOS
chmod 755 "$W/control/postinst" "$W/control/postrm"

echo "== 6. 打包 =="
(
	cd "$W" || exit 1
	echo 2.0 > debian-binary
	tar -C control -czf control.tar.gz .
	tar -C data -czf data.tar.gz .
	tar -czf "$OUT" debian-binary control.tar.gz data.tar.gz
)

echo "== 结果 =="
ls -lh "$OUT"
echo "原始体积: $(du -sm "$W/data" | cut -f1) MB"
rm -rf "$W"
echo "OUT=$OUT"
