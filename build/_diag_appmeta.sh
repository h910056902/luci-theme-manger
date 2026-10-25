#!/bin/sh
echo "== app-meta-homebox 安装报错 =="
opkg install app-meta-homebox 2>&1 | tail -8

echo "== 该包的 postinst 做了什么 =="
P=/usr/lib/opkg/info/app-meta-homebox.postinst
[ -f "$P" ] || P=/tmp/appmeta.postinst
gz=$(ls /var/opkg-lists/istore_meta 2>/dev/null)
echo "  索引: $gz"
grep -A3 -E '^Package: app-meta-homebox$' "$gz" 2>/dev/null | head -8

echo "== 已装 app-meta 的脚本示例 =="
ls /usr/lib/opkg/info/app-meta-*.postinst 2>/dev/null | head -3
[ -f /usr/lib/opkg/info/app-meta-dockermanager.postinst ] && head -12 /usr/lib/opkg/info/app-meta-dockermanager.postinst

echo "== is-opkg / istore 是否存在 =="
command -v is-opkg; command -v istore; ls /usr/bin/is-opkg /usr/libexec/is-opkg 2>/dev/null

echo "== 进度 =="
cat /tmp/istore-restore.state 2>/dev/null
