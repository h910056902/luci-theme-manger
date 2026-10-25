#!/bin/sh
B=http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
H="Cookie: sysauth=$SID"

echo "== 1. 生成备份 =="
R=$(curl -s -m 240 -X POST -H "$H" "$B?action=backup_full")
echo "$R"
NAME=$(printf '%s' "$R" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
[ -n "$NAME" ] || { echo "没拿到文件名，终止"; exit 1; }

echo "== 2. 列表 =="
curl -s -m 30 -H "$H" "$B?action=backup_list"
echo

echo "== 3. 本地文件 =="
ls -lh "/tmp/$NAME"
echo "== 4. 包内结构 =="
tar -tzf "/tmp/$NAME" | head -12

echo "== 5. 通过接口下载 =="
curl -s -m 180 -o /tmp/kp-dl.tar.gz -H "$H" "$B?action=backup_get&name=$NAME"
ls -lh /tmp/kp-dl.tar.gz
echo -n "下载文件可解包: "; tar -tzf /tmp/kp-dl.tar.gz >/dev/null 2>&1 && echo yes || echo no
echo -n "大小一致: "; [ "$(wc -c < /tmp/kp-dl.tar.gz)" = "$(wc -c < /tmp/$NAME)" ] && echo yes || echo no

echo "== 6. 内容抽检 =="
tar -xzOf "/tmp/$NAME" ./MANIFEST.txt 2>/dev/null | head -8
echo "--- restore.sh ---"
tar -xzOf "/tmp/$NAME" ./restore.sh 2>/dev/null | head -6
rm -f /tmp/kp-dl.tar.gz
echo DONE
