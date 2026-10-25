#!/bin/sh
B=http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
H="Cookie: sysauth=$SID"

echo "== 1. 生成 ipk 恢复包 =="
R=$(curl -s -m 300 -X POST -H "$H" "$B?action=backup_ipk")
echo "$R"
NAME=$(printf '%s' "$R" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
[ -n "$NAME" ] || { echo "未拿到文件名"; exit 1; }

echo "== 2. 文件 =="
ls -lh "/tmp/$NAME"

echo "== 3. ipk 结构（应为 debian-binary + control.tar.gz + data.tar.gz）=="
tar -tzf "/tmp/$NAME" 2>/dev/null

echo "== 4. control 内容 =="
rm -rf /tmp/kpchk && mkdir -p /tmp/kpchk
tar -xzf "/tmp/$NAME" -C /tmp/kpchk 2>/dev/null
tar -xzOf /tmp/kpchk/control.tar.gz ./control 2>/dev/null

echo "== 5. data 内文件 =="
tar -tzf /tmp/kpchk/data.tar.gz 2>/dev/null | grep kp-backup | head -8

echo "== 6. 列表接口 =="
curl -s -m 30 -H "$H" "$B?action=backup_list"
echo

echo "== 7. opkg 能否识别（只做 info 校验，不安装）=="
opkg info /tmp/$NAME 2>&1 | head -6
rm -rf /tmp/kpchk
echo DONE
