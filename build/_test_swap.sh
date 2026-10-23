#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
C="Cookie: sysauth=$SID"

echo "== 1. 初始状态 =="
curl -s -m 15 -H "$C" "$B?action=swap"
echo
echo "== 2. 触发创建 512MB =="
curl -s -m 25 -H "$C" -d "op=on&confirm=1&size=512" "$B?action=swap"
echo
echo "== 3. 轮询生成进度 =="
i=0
while [ $i -lt 15 ]; do
	sleep 10
	i=$((i+1))
	R=$(curl -s -m 15 -H "$C" "$B?action=swap")
	echo "$i: $R"
	case "$R" in
		*'"on":true'*) echo "已启用，停止轮询"; break ;;
	esac
done

echo "== 4. /proc/swaps =="
cat /proc/swaps
echo "== 5. fstab =="
uci show fstab | grep -i swap
echo "== 6. 文件 =="
ls -lh /overlay/swapfile 2>/dev/null
echo "== 7. 空间 =="
df -m /overlay | tail -1
echo "== 8. 生成日志 =="
cat /tmp/kpswap.log 2>/dev/null | tail -3
echo DONE
