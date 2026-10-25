#!/bin/sh
# 生成「重装固件后一键恢复」的 ipk：
#   离线内容：8080 面板本体 + OpenClash（含内核/GeoSite/订阅配置）+ 全部 /etc/config
#   在线补装：其余后装插件（清单 + 脚本，联网执行）
# 产物：/overlay/kp-restore-<时间戳>_all.ipk
set -e

TS=$(date +%Y%m%d-%H%M%S)
VER=$(date +%Y.%m.%d-%H%M%S)
NAME="kp-restore-$TS"
W="/overlay/kpbuild/$NAME"
OUT="/overlay/$NAME.ipk"

rm -rf "$W"
mkdir -p "$W/control" "$W/data/etc/kp-restore"

echo "== 1. 收集：8080 面板 =="
mkdir -p "$W/data/overlay/nradio-apps"
cp -a /overlay/nradio-apps/openwrt-luci-8080 "$W/data/overlay/nradio-apps/" 2>/dev/null || true

echo "== 2. 收集：OpenClash（程序 + 内核 + 规则）=="
mkdir -p "$W/data/etc"
cp -a /etc/openclash "$W/data/etc/" 2>/dev/null || true
for f in /etc/init.d/openclash /usr/lib/lua/luci/controller/openclash.lua; do
	[ -f "$f" ] || continue
	mkdir -p "$W/data$(dirname "$f")"
	cp -a "$f" "$W/data$f"
done
if [ -d /www/luci-static/resources/view/openclash ]; then
	mkdir -p "$W/data/www/luci-static/resources/view"
	cp -a /www/luci-static/resources/view/openclash "$W/data/www/luci-static/resources/view/"
fi

echo "== 3. 收集：全部 /etc/config =="
mkdir -p "$W/data/etc/config"
cp -a /etc/config/. "$W/data/etc/config/" 2>/dev/null || true
# 去掉早期部署留下的备份文件，避免把垃圾一起恢复
find "$W/data/etc/config" -name '*.bak*' -delete 2>/dev/null || true

echo "== 4. 清单与恢复脚本 =="
opkg list-installed > "$W/data/etc/kp-restore/packages.txt" 2>/dev/null
NPKG=$(wc -l < "$W/data/etc/kp-restore/packages.txt")

cat > "$W/data/etc/kp-restore/restore-packages.sh" <<'EOS'
#!/bin/sh
# 装回「除固件自带之外」的插件。需要能访问 opkg 源（联网）。
# 用法：sh /etc/kp-restore/restore-packages.sh
L=/etc/kp-restore/packages.txt
[ -f "$L" ] || { echo "缺少 $L"; exit 1; }

echo "[1/3] 更新软件源..."
opkg update >/dev/null 2>&1

echo "[2/3] 计算差异..."
opkg list-installed 2>/dev/null | awk '{print $1}' | sort > /tmp/kp-have.txt
awk '{print $1}' "$L" | sort > /tmp/kp-want.txt
comm -13 /tmp/kp-have.txt /tmp/kp-want.txt > /tmp/kp-miss.txt
echo "  待安装：$(wc -l < /tmp/kp-miss.txt) 个"

echo "[3/3] 安装..."
while read -r p; do
	[ -n "$p" ] || continue
	if opkg install "$p" >/dev/null 2>&1; then
		echo "  OK   $p"
	else
		echo "  FAIL $p"
	fi
done < /tmp/kp-miss.txt

echo "完成。剩下装不上的多半是 iStore 应用，去应用商店重装即可。"
EOS
chmod 755 "$W/data/etc/kp-restore/restore-packages.sh"

MANI="$W/data/etc/kp-restore/MANIFEST.txt"
{
	echo "NRadio 8080 完整恢复包"
	echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
	echo "设备型号: $(cat /tmp/sysinfo/model 2>/dev/null)"
	echo "固件版本: $(. /etc/openwrt_release 2>/dev/null; echo -n "$DISTRIB_DESCRIPTION")"
	echo "已装插件: $NPKG 个"
	echo
	echo "离线包含：8080 面板、OpenClash（含内核与规则）、全部 /etc/config（含 OpenClash 订阅）"
	echo "在线补装：其余插件执行 /etc/kp-restore/restore-packages.sh"
} > "$MANI"

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
echo "kp-restore: 其余插件请执行 sh /etc/kp-restore/restore-packages.sh"
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
echo "文件数: $(find "$W/data" -type f | wc -l)"
echo "原始体积: $(du -sm "$W/data" | cut -f1) MB"
rm -rf "$W"
echo "OUT=$OUT"
